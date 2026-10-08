class AddGeojsonToItineraries < ActiveRecord::Migration[8.1]
  def change
    add_column :itineraries, :geojson, :json
  end
end
