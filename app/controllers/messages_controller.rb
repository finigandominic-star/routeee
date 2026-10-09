class MessagesController < ApplicationController
  SYSTEM_PROMPT = <<~PROMPT
    You are an expert cycling route assistant. Your goal is to plan the perfect cycle route.

    CRITICAL MAP TOOL INSTRUCTIONS:
    CRITICAL MAP TOOL INSTRUCTIONS:
    - The tool REQUIRES a distinct `start_destination` and `end_destination`.
    - TOOL ARGUMENTS: You must pass data to the tool using ONLY these exact keys: `start_destination`, `end_destination`, `outbound_landmark`, `return_landmark`, `group_size`, and `kids`.
    - If the user provides a short answer (e.g., "scenic" or "mountain bike"), look back at the [CONVERSATION HISTORY] to find their locations.
    - ALWAYS format the destinations to include the town, city, AND country to prevent geocoding errors (e.g., "Richmond Station, London, UK").
    - Extract the `group_size` (as an integer) and whether there are `kids` ("yes" or "no") if mentioned.
    - Do not call the tool if you are just summarizing an ALREADY plotted route.

    CIRCULAR ROUTES & LOOPS:
    - The map tool calculates the shortest path between points. If you only provide one halfway point, it will route the exact same roads out-and-back.
    - To force a TRUE scenic circular loop, you MUST select TWO DISTINCT halfway landmarks in different areas of the park or region.
    - If the user wants a circular route but doesn't know halfway points, YOU MUST ACT AS THE EXPERT.
    - Autonomously select a specific `outbound_landmark` (e.g., Isabella Plantation, London, UK) and a COMPLETELY DIFFERENT `return_landmark` (e.g., Roehampton Gate, London, UK).
    - IMMEDIATELY call the map tool. You MUST pass their start point as the `start_destination`, your first location as `outbound_landmark`, your second location as `return_landmark`, and their start point again as the `end_destination`.
    - CRITICAL: Do NOT output conversational text like "I will plan this" or "Please hold on". You must trigger the map tool FIRST.

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
          group_size: route_data[:group_size], # <-- NOW GRABBING THIS
          kids: route_data[:kids],             # <-- NOW GRABBING THIS
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
