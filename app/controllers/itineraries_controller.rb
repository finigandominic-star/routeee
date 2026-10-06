class ItinerariesController < ApplicationController
  before_action :set_itinerary, only: [:show]
def index
  @itineraries = Itinerary.all
end
private

  def set_itinerary
    # Grabs the ID from the URL (e.g., /itineraries/1) and finds it in the database
    @itinerary = Itinerary.find(params[:id])
  end
  
end
