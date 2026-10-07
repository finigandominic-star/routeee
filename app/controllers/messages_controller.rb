class MessagesController < ApplicationController
SYSTEM_PROMPT = "You are an expert, friendly cycling route assistant. Your goal is to help the user plan the perfect cycle route.\n\n
To finalize a route, you must understand the user's preferences across three parameters:\n\n
1. Start and end points (or if they just want a circular loop from a starting point).\n\n
2. Approximate distance or duration.\n\n
3. The type of cycling (e.g., paved road cycling, mixed-surface commuting, or off-road mountain biking).\n\n
INSTRUCTIONS:\n\n
- If the user's initial message is missing any of these details, ask natural, conversational follow-up questions to gather them.\n\n
- Do not list the missing parameters like a robot; weave them into a friendly chat.\n\n
- Because we are currently in a testing environment without live map data, once you have gathered all the information, you must INVENT a plausible route that fits their criteria. \n\n
- Present a conversational, step-by-step summary of this fictional route. For example, if they ask for a 20km road loop starting in Reading, you could invent a scenic ride out towards Sonning and Henley, mentioning a couple of fictional turns or landmarks. \n\n
- Always conclude your fictional route proposal by asking: 'Does this route sound good to you, or would you like to adjust the distance before we save it?'"

  def create
    @chat = current_user.chats.find(params[:chat_id])
    @challenge = @chat.itinerary

    @message = Message.new(message_params)
    @message.chat = @chat
    @message.role = "user"

    if @message.save
      ruby_llm_chat = RubyLLM.chat
      response = ruby_llm_chat.with_instructions(SYSTEM_PROMPT).ask(@message.content)
      Message.create(role: "assistant", content: response.content, chat: @chat)

      @chat.generate_title_from_first_message
      
      redirect_to chat_path(@chat)
      else
        render "chats/show", status: :unprocessable_entity
    end
  end

  private
    def message_params
    params.require(:message).permit(:content)
  end

end
