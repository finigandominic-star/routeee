class MessagesController < ApplicationController
SYSTEM_PROMPT = <<~PROMPT
    You are an expert cycling route assistant. Your goal is to plan the perfect cycle route.

    CRITICAL MAP TOOL INSTRUCTIONS:
    - The tool REQUIRES a `start_destination` and `end_destination`.
    - If the user provides a short answer (e.g., "scenic" or "mountain bike") in the [NEW MESSAGE], you MUST look back at the [CONVERSATION HISTORY] to find their previously stated start and end locations.
    - NEVER call the tool with empty locations. If you don't know the locations, ask the user.
    - ALWAYS format the destinations to include the town or city (e.g., "Armour Road, Tilehurst").
    - If the user asks for a summary, distance, or details about a route you ALREADY plotted, provide text only. Do not call the tool again.

    CONVERSATION FLOW:
    - If missing basic parameters (start, end, bike type), ask natural follow-up questions.
    - Map the user's bike type to: 'cycling-regular', 'cycling-road', 'cycling-mountain', or 'cycling-electric'.
    - After the tool successfully returns the route data, present a short conversational summary.
  PROMPT

  def create
    @chat = current_user.chats.find(params[:chat_id])
    @message = Message.new(message_params)
    @message.chat = @chat
    @message.role = "user"

    if @message.save
      # 1. Format the history (excluding the message the user just sent)
      history = @chat.messages.where.not(id: @message.id).order(:created_at).map do |msg|
        "#{msg.role.capitalize}: #{msg.content}"
      end.join("\n\n")

      # 2. Clearly separate the history from the new command
      final_prompt = <<~TEXT
        [CONVERSATION HISTORY]
        #{history.presence || "No history yet."}

        [NEW MESSAGE FROM USER]
        #{@message.content}
      TEXT

      map_tool = GenerateCyclingRouteTool.new

      ruby_llm_chat = RubyLLM.chat
                             .with_instructions(SYSTEM_PROMPT)
                             .with_tools(GenerateCyclingRouteTool.new)

      llm_response = ruby_llm_chat.ask(final_prompt)

      @assistant_message = Message.create!(role: "assistant", content: llm_response.content, chat: @chat)

 if Thread.current[:ors_route_data].present?
        route_data = Thread.current[:ors_route_data]
        @geojson = route_data[:geojson]

        @chat.itinerary.update(
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
