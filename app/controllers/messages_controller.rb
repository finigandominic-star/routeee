class MessagesController < ApplicationController
  def create
    @chat = current_user.chats.find(params[:chat_id])
    @itinerary = @chat.itinerary
    @message = Message.new(message_params)
    @message.chat = @chat
    @message.role = "user"

    if @message.save
      # 1. Format conversation history
      history = @chat.messages.where.not(id: @message.id).order(:created_at).map do |msg|
        "#{msg.role.capitalize}: #{msg.content}"
      end.join("\n\n")

      # 2. Dynamic prompt containing current itinerary state
      dynamic_system_prompt = <<~PROMPT
        You are an expert cycling route assistant. Your goal is to plan or EDIT an existing cycle route.

        CURRENT ITINERARY STATE:
        - Start Location: #{@itinerary.start_destination.presence || 'Not set'}
        - End Location: #{@itinerary.end_destination.presence || 'Not set'}
        - Bike Type: #{@itinerary.bike_type.presence || 'cycling-regular'}

        CRITICAL MAP TOOL INSTRUCTIONS:
        - Call `GenerateCyclingRouteTool` whenever the user asks to plan a new route OR edit the existing route (e.g., change start, end, or bike profile).
        - The tool REQUIRES a `start_destination` and `end_destination`.
        - If the user provides a partial edit (e.g., "Change end to Oxford" or "Switch to mountain bike"), pull missing locations from CURRENT ITINERARY STATE or CONVERSATION HISTORY.
        - NEVER call the tool with empty locations. If you don't know the locations, ask the user.
        - Map the user's bike type to: 'cycling-regular', 'cycling-road', 'cycling-mountain', or 'cycling-electric'.
        - If the user asks for a summary or details without requesting edits, provide text only. Do not call the tool.
      PROMPT

      final_prompt = <<~TEXT
        [CONVERSATION HISTORY]
        #{history.presence || "No history yet."}

        [NEW MESSAGE FROM USER]
        #{@message.content}
      TEXT

      ruby_llm_chat = RubyLLM.chat
                             .with_instructions(dynamic_system_prompt)
                             .with_tools(GenerateCyclingRouteTool.new)

      llm_response = ruby_llm_chat.ask(final_prompt)

      @assistant_message = Message.create!(role: "assistant", content: llm_response.content, chat: @chat)

      if Thread.current[:ors_route_data].present?
        route_data = Thread.current[:ors_route_data]
        @geojson = route_data[:geojson]

        @itinerary.update!(
          start_destination: route_data[:start_destination],
          end_destination: route_data[:end_destination],
          distance: route_data[:distance],
          bike_type: route_data[:bike_type],
          geojson: @geojson
        )

        Thread.current[:ors_route_data] = nil
        Rails.logger.info "\n✅ ITINERARY UPDATED & MAP READY!\n"
      end

      respond_to do |format|
        format.turbo_stream
      end
    else
      render "chats/show", status: :unprocessable_entity
    end
  end

  private

  def message_params
    params.require(:message).permit(:content)
  end
end
