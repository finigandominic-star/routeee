class ItinerariesController < ApplicationController
  before_action :set_list, only: [:show, :destroy]
  # index displaying all the itineraries
  def index
    @itineraries = Itinerary.all
  end

   # the page showing one itinerary by id
  def show
    @itinerary = Itinerary.find(params[:id])
  end


  private

  def set_itineraries
    @itinerary = Itinerary.find(params[:id])
  end

  def itinerary_params
    params.require(:itinerary).permit(:name)
  end

end
