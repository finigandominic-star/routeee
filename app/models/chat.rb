class Chat < ApplicationRecord
  belongs_to :user
  belongs_to :itinerary
  has_many :messages
end
