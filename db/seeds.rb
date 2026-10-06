# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

puts "Cleaning database..."
Message.destroy_all
Chat.destroy_all
Itinerary.destroy_all
User.destroy_all

puts "Creating users..."
sarah = User.create!(email: "sarah@sarah.com", password: "123456")
toni = User.create!(email: "toni@toni.com", password: "123456")
mark = User.create!(email: "mark@mark.com", password: "123456")
emily = User.create!(email: "emily@emily.com", password: "123456")
john = User.create!(email: "john@john.com", password: "123456")
puts "Created 5 users."

puts "Creating itineraries..."
itinerary_1 = Itinerary.create!(bike_type: "mountain", distance: 7, start_destination: "10 baker street, London", end_destination: "10 baker street, London", group_size: 2, kids: "no", system_prompt: "test test test")
puts "Created itinerary #1"

itinerary_2 = Itinerary.create!(bike_type: "road", distance: 3, start_destination: "Pangbourne, Berkshire", end_destination: "", group_size: 1, kids: "yes", system_prompt: "test test test")
puts "Created itinerary #2"

itinerary_3 = Itinerary.create!(bike_type: "hybrid", distance: 15, start_destination: "Reading Station", end_destination: "Windsor Castle", group_size: 4, kids: "yes", system_prompt: "Provide a scenic, family-friendly route.")
puts "Created itinerary #3"

itinerary_4 = Itinerary.create!(bike_type: "gravel", distance: 40, start_destination: "Richmond Park", end_destination: "Box Hill", group_size: 1, kids: "no", system_prompt: "Focus on challenging climbs and off-road trails.")
puts "Created itinerary #4"

itinerary_5 = Itinerary.create!(bike_type: "e-bike", distance: 20, start_destination: "Oxford", end_destination: "Blenheim Palace", group_size: 2, kids: "no", system_prompt: "Smooth paved roads for easy cruising.")
puts "Created itinerary #5"

puts "Creating chats..."
chat_1 = Chat.create!(user: sarah, itinerary: itinerary_3)
chat_2 = Chat.create!(user: mark, itinerary: itinerary_4)
chat_3 = Chat.create!(user: emily, itinerary: itinerary_5)
puts "Created 3 chats."

puts "Creating messages..."

# Chat 1 Messages (4 messages)
Message.create!(chat: chat_1, role: "user", content: "I'm looking for a safe route for my family from Reading to Windsor.")
Message.create!(chat: chat_1, role: "assistant", content: "I can help with that! A hybrid bike is perfect. Do you want to stick to the Thames Path?")
Message.create!(chat: chat_1, role: "user", content: "Yes, the Thames Path sounds lovely. Are there any good pub stops?")
Message.create!(chat: chat_1, role: "assistant", content: "Absolutely. I've plotted a 15-mile route with a recommended stop at The George in Wargrave.")

# Chat 2 Messages (6 messages)
Message.create!(chat: chat_2, role: "user", content: "I want a tough 40-mile gravel ride starting at Richmond Park.")
Message.create!(chat: chat_2, role: "assistant", content: "Great! Heading out to Box Hill will give you some excellent climbs. Ready for the route?")
Message.create!(chat: chat_2, role: "user", content: "Yes, but keep it mostly off-road if possible.")
Message.create!(chat: chat_2, role: "assistant", content: "Understood. I am routing you through the Surrey Hills AONB via bridleways.")
Message.create!(chat: chat_2, role: "user", content: "Perfect, thanks.")
Message.create!(chat: chat_2, role: "assistant", content: "Your route is saved. Have a great ride!")

# Chat 3 Messages (3 messages)
Message.create!(chat: chat_3, role: "user", content: "My partner and I want an easy 20-mile e-bike ride to Blenheim Palace.")
Message.create!(chat: chat_3, role: "assistant", content: "Oxford to Blenheim Palace is a beautiful ride. I recommend the route through Woodstock.")
Message.create!(chat: chat_3, role: "user", content: "Sounds great, send me the map.")

puts "Database seeded successfully!"
