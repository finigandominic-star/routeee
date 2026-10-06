class CreateItineraries < ActiveRecord::Migration[8.1]
  def change
    create_table :itineraries do |t|
      t.string :bike_type
      t.integer :distance
      t.string :start_destination
      t.string :end_destination
      t.integer :group_size
      t.string :kids
      t.text :system_prompt

      t.timestamps
    end
  end
end
