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
    @chat = Chat.new
  end

  def destroy
    @chat = current_user.chats.find(params[:id])
    @itinerary = @chat.itinerary

    @chat.destroy

    redirect_to itinerary_path(@itinerary), status: :see_other, notice: "Chat deleted."
  end
end
