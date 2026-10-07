class Itinerary < ApplicationRecord
  has_many :chats, dependent: :destroy
  has_many :messages, through: :chat
end
