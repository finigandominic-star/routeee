class ChatsController < ApplicationController
  def create
  @itinerary = Itinerary.find(params[:itinerary_id])

  @chat = Chat.new(title: "Untitled")
  @chat.itinerary = @itinerary
  @chat.user = current_user

    if @chat.save
      redirect_to chat_path(@chat)
    else
      @chats = @itinerary.chats.where(user: current_user)
      render "itineraries/show"
    end
  end

  def show
    @chat    = current_user.chats.find(params[:id])
    @message = Message.new
  end

  def new
    @chat = Chat.new(params[:id])
  end

  # def generate_title_from_first_message
  #   return unless title == DEFAULT_TITLE

  #   first_user_message = messages.where(role: "user").order(:created_at).first
  #   return if first_user_message.nil?

  #   response = RubyLLM.chat.with_instructions(TITLE_PROMPT).ask(first_user_message.content)
  #   update(title: response.content)
  # end
end
