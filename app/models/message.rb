class Message < ApplicationRecord
  belongs_to :chat
  has_one :itinerary, through: :chat
end
