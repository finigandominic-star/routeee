class GenerateCyclingRouteTool < RubyLLM::Tool
  description "Map drawing tool. Call this to plot a NEW route. You MUST provide start_destination and end_destination. If the newest message is short, pull the locations from the conversation history. NEVER call with empty parameters."

  def execute(start_destination: nil, end_destination: nil, profile: "cycling-regular", **kwargs)
    # These are the variables it was complaining were missing!
    actual_start = start_destination || kwargs["start_destination"] || kwargs[:start_city] || kwargs["start_city"]
    actual_end   = end_destination   || kwargs["end_destination"]   || kwargs[:end_city]   || kwargs["end_city"]
    actual_prof  = kwargs["profile"] || profile

    # 🚨 LOG 1: See if the tool was triggered and what the LLM sent
    Rails.logger.info "\n🚀 TOOL TRIGGERED BY AI!"
    Rails.logger.info "   -> Start: #{actual_start}"
    Rails.logger.info "   -> End: #{actual_end}"
    Rails.logger.info "   -> Profile: #{actual_prof}\n"

    unless actual_start && actual_end
      return { status: "error", message: "Missing locations." }
    end

    # 1. Geocode the start location first
    start_coords = geocode(actual_start)

    # 2. Geocode the end location, passing the start_coords as a "focus point"
    end_coords = geocode(actual_end, focus_coords: start_coords)

    # 🚨 LOG 2: See if the Geocoder failed
    Rails.logger.info "\n🌍 GEOCODER RESULTS:"
    Rails.logger.info "   -> #{actual_start} = #{start_coords.inspect}"
    Rails.logger.info "   -> #{actual_end} = #{end_coords.inspect}\n"

    return { status: "error", message: "Could not find coordinates for those locations" } unless start_coords && end_coords

    conn = Faraday.new(url: "https://api.openrouteservice.org")
    response = conn.post("/v2/directions/#{actual_prof}/geojson") do |req|
      req.headers['Authorization'] = ENV['ORS_API_KEY']
      req.headers['Content-Type'] = 'application/json'
      req.body = { coordinates: [start_coords, end_coords] }.to_json
    end

    if response.success?
      Rails.logger.info "\n✅ ORS ROUTE FETCHED SUCCESSFULLY!\n"

      parsed_json = JSON.parse(response.body)

      # Extract distance in meters and convert to miles
      distance_meters = parsed_json.dig("features", 0, "properties", "summary", "distance") || 0
      distance_miles = (distance_meters / 1609.34).round(1)

      # 🚨 THE FIX: Send a full package of data through the tunnel using the correct variables
      Thread.current[:ors_route_data] = {
        geojson: parsed_json,
        distance: distance_miles,
        start_destination: actual_start,
        end_destination: actual_end,
        bike_type: actual_prof
      }

      { status: "success", geojson: "GeoJSON saved to memory." }
    else
      Rails.logger.error "\n❌ ORS API ERROR: #{response.body}\n"
      { status: "error", message: "Failed to fetch route from ORS" }
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
        # 🌍 STRICT BOUNDARY: Force the API to only search within a 50km radius of the start point
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
