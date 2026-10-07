class ItinerariesController < ApplicationController
  before_action :set_itinerary, only: [:show, :destroy]
  # index displaying all the itineraries
  def index
    @itineraries = Itinerary.all
  end

   # the page showing one itinerary by id
  def show
    @itinerary = Itinerary.find(params[:id])
  end


  private

   def itinerary_params
    params.require(:itinerary).permit(:name)
  end

  def set_itinerary
    # Grabs the ID from the URL (e.g., /itineraries/1) and finds it in the database
    @itinerary = Itinerary.find(params[:id])
  end

end
