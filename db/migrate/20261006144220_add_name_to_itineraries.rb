class AddNameToItineraries < ActiveRecord::Migration[8.1]
  def change
    add_column :itineraries, :name, :string
  end
end
