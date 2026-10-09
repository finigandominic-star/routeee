class EditCyclingRouteTool < RubyLLM::Tool
  description "Edits an existing cycling itinerary. Call this whenever the user asks to modify or update an existing route's start location, end location, or bike profile."

  def execute(itinerary_id:, start_destination: nil, end_destination: nil, profile: "cycling-regular", **kwargs)
    itinerary = Itinerary.find_by(id: itinerary_id)
    return { status: "error", message: "Itinerary not found" } unless itinerary

    actual_start = start_destination || kwargs["start_destination"] || itinerary.start_destination
    actual_end   = end_destination   || kwargs["end_destination"]   || itinerary.end_destination
    actual_prof  = profile           || kwargs["profile"]           || itinerary.bike_type || "cycling-regular"

    start_coords = geocode(actual_start)
    end_coords   = geocode(actual_end, focus_coords: start_coords)

    return { status: "error", message: "Could not find coordinates for those locations" } unless start_coords && end_coords

    conn = Faraday.new(url: "https://api.openrouteservice.org")
    response = conn.post("/v2/directions/#{actual_prof}/geojson") do |req|
      req.headers['Authorization'] = ENV['ORS_API_KEY']
      req.headers['Content-Type'] = 'application/json'
      req.body = { coordinates: [start_coords, end_coords] }.to_json
    end

    if response.success?
      parsed_json = JSON.parse(response.body)
      distance_meters = parsed_json.dig("features", 0, "properties", "summary", "distance") || 0
      distance_miles = (distance_meters / 1609.34).round(1)

      # Persist updates to the database
      itinerary.update!(
        geojson: parsed_json,
        distance: distance_miles,
        start_destination: actual_start,
        end_destination: actual_end,
        bike_type: actual_prof
      )

      { status: "success", message: "Itinerary updated successfully." }
    else
      { status: "error", message: "Failed to recalculate route from ORS" }
    end
  end

  private

  def geocode(city_name, focus_coords: nil)
    conn = Faraday.new(url: "https://api.openrouteservice.org")
    response = conn.get("/geocode/search") do |req|
      req.headers['Authorization'] = ENV['ORS_API_KEY']
      req.params['text'] = city_name
      req.params['size'] = 1

      if focus_coords
        req.params['boundary.circle.lon'] = focus_coords[0]
        req.params['boundary.circle.lat'] = focus_coords[1]
        req.params['boundary.circle.radius'] = 50
      end
    end

    if response.success?
      data = JSON.parse(response.body)
      data.dig("features", 0, "geometry", "coordinates")
    else
      nil
    end
  end
end
