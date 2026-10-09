class MessagesController < ApplicationController
  SYSTEM_PROMPT = <<~PROMPT
    You are an expert cycling route assistant. Your goal is to plan the perfect cycle route.

    CRITICAL MAP TOOL INSTRUCTIONS:
    - The tool REQUIRES a distinct `start_destination` and `end_destination`.
    - TOOL ARGUMENTS: Pass data to the tool using ONLY these exact keys: `start_destination`, `end_destination`, `outbound_landmark`, `return_landmark`, `group_size`, and `kids`.
    - If the user provides a short answer (e.g., "scenic" or "mountain bike"), look back at the [CONVERSATION HISTORY] to identify their location and route details.
    - ALWAYS format destinations with town/landmark, city, AND country to prevent geocoding errors (e.g., "Richmond Station, London, UK").
    - Extract `group_size` (as an integer) and `kids` ("yes" or "no") if mentioned.
    - Do not call the tool if you are merely summarizing an ALREADY plotted route.

    ROUTE PLANNING RULES (A-to-B vs LOOPS):
    - ONLY create a circular loop if the user explicitly asks for a "loop", "circular route", or to return to their starting point.
    - For point-to-point journeys, keep them as distinct A-to-B routes.

    MODIFYING / SHORTENING / EXTENDING EXISTING ROUTES:
    - ANCHOR THE START: Unless the user explicitly asks to "change the start point" or "start somewhere else", ALWAYS KEEP `start_destination` UNCHANGED.
    - SHORTENING AN A-TO-B ROUTE:
      * Keep the same `start_destination`.
      * Move `end_destination` closer to the start along the intended route to proportionally match the requested distance reduction.
      * Example: For a 22-mile route from Lisbon to Cascais shortened by half (~11 miles), keep Lisbon as `start_destination` and set `end_destination` to an intermediate point like "Oeiras, Portugal" or "Carcavelos, Portugal". Never pick a point adjacent to the original end point.
    - EXTENDING AN A-TO-B ROUTE:
      * Keep the same `start_destination` and select a destination farther out, or specify an `outbound_landmark` detour.
    - MANDATORY TOOL RE-EXECUTION: When modifying, shortening, or extending an existing route, YOU MUST RE-INVOKE THE MAP TOOL with the updated points. Never reply with text confirmations without triggering the tool.

    CIRCULAR LOOPS (WHEN REQUESTED):
    - The map tool calculates the shortest path between points. If you only provide one halfway point, it routes out-and-back along identical roads.
    - To create a TRUE scenic loop, you MUST provide TWO DISTINCT halfway landmarks in different quadrants of the area.
    - If the user asks for a loop without specific intermediate stops, select an `outbound_landmark` and a completely distinct `return_landmark` automatically.
    - Pass their start point as `start_destination`, the first waypoint as `outbound_landmark`, the second waypoint as `return_landmark`, and their start point as `end_destination`.
    - Trigger the map tool silently and first—do not emit conversational filler before calling the tool.

    CONVERSATION FLOW:
    - If missing basic parameters (start, end, bike type), ask concise follow-up questions.
    - Map the user's bike type to: 'cycling-regular', 'cycling-road', 'cycling-mountain', or 'cycling-electric'.
    - After the tool returns route data, present a brief summary of the route and distance.
  PROMPT

  def create
    @chat = current_user.chats.find(params[:chat_id])
    @message = Message.new(message_params)
    @message.chat = @chat
    @message.role = "user"

    if @message.save
      history = @chat.messages.where.not(id: @message.id).order(:created_at).map do |msg|
        "#{msg.role.capitalize}: #{msg.content}"
      end.join("\n\n")

      final_prompt = <<~TEXT
        [CONVERSATION HISTORY]
        #{history.presence || "No history yet."}

        [NEW MESSAGE FROM USER]
        #{@message.content}
      TEXT

      ruby_llm_chat = RubyLLM.chat
                             .with_instructions(SYSTEM_PROMPT)
                             .with_tools(GenerateCyclingRouteTool.new)

      begin
        llm_response = ruby_llm_chat.ask(final_prompt)
      rescue Faraday::ConnectionFailed, EOFError => e
        Rails.logger.error "[API Connection Error]: #{e.class} - #{e.message}"
        flash.now[:alert] = "The mapping service timed out. Please try sending your message again."
        render "chats/show", status: :service_unavailable and return
      end

      @assistant_message = Message.create!(role: "assistant", content: llm_response.content, chat: @chat)

      if Thread.current[:ors_route_data].present?
        route_data = Thread.current[:ors_route_data]
        @geojson = route_data[:geojson]

        @chat.itinerary.update(
          start_destination: route_data[:start_destination],
          end_destination: route_data[:end_destination],
          distance: route_data[:distance],
          bike_type: route_data[:bike_type],
          group_size: route_data[:group_size],
          kids: route_data[:kids],
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
