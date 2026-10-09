class GenerateCyclingRouteTool < RubyLLM::Tool
  description "Map drawing tool. Call this to plot a route. Accepts JSON keys: 'start_destination' (required), 'end_destination' (required), 'outbound_landmark' (optional), 'return_landmark' (optional), 'group_size' (integer), and 'kids' (yes/no)."

  def execute(start_destination: nil, end_destination: nil, outbound_landmark: nil, return_landmark: nil, group_size: nil, kids: nil, profile: "cycling-regular", **kwargs)
    actual_start = start_destination || kwargs[:start_destination] || kwargs["start_destination"]
    actual_end   = end_destination   || kwargs[:end_destination]   || kwargs["end_destination"]
    actual_out   = outbound_landmark || kwargs[:outbound_landmark] || kwargs["outbound_landmark"]
    actual_ret   = return_landmark   || kwargs[:return_landmark]   || kwargs["return_landmark"]
    actual_prof  = profile           || kwargs[:profile]           || kwargs["profile"]

    final_group_size = group_size || kwargs[:group_size] || kwargs["group_size"]
    final_kids       = kids       || kwargs[:kids]       || kwargs["kids"]

    Rails.logger.info "\n🚀 TOOL TRIGGERED BY AI!"
    Rails.logger.info "   -> Start: #{actual_start}"
    Rails.logger.info "   -> Outbound: #{actual_out || 'None'}"
    Rails.logger.info "   -> Return: #{actual_ret || 'None'}"
    Rails.logger.info "   -> End: #{actual_end}\n"

    unless actual_start && actual_end
      return { status: "error", message: "Missing start or end locations." }
    end

    start_coords = geocode(actual_start)
    end_coords = geocode(actual_end, focus_coords: start_coords)

    return { status: "error", message: "Could not find start or end coordinates." } unless start_coords && end_coords

    # Build the coordinates array dynamically based on what the AI provided
    route_coords = [start_coords]

    if actual_out
      out_coords = geocode(actual_out, focus_coords: start_coords)
      return { status: "error", message: "Could not find outbound landmark." } unless out_coords
      route_coords << out_coords
    end

    if actual_ret
      ret_coords = geocode(actual_ret, focus_coords: start_coords)
      return { status: "error", message: "Could not find return landmark." } unless ret_coords
      route_coords << ret_coords
    end

    route_coords << end_coords

    conn = Faraday.new(url: "https://api.openrouteservice.org")
    response = conn.post("/v2/directions/#{actual_prof}/geojson") do |req|
      req.headers['Authorization'] = ENV['ORS_API_KEY']
      req.headers['Content-Type'] = 'application/json'
      req.body = { coordinates: route_coords }.to_json
    end

    if response.success?
      Rails.logger.info "\n✅ ORS ROUTE FETCHED SUCCESSFULLY!\n"
      parsed_json = JSON.parse(response.body)
      distance_meters = parsed_json.dig("features", 0, "properties", "summary", "distance") || 0
      distance_miles = (distance_meters / 1609.34).round(1)

      Thread.current[:ors_route_data] = {
        geojson: parsed_json,
        distance: distance_miles,
        start_destination: actual_start,
        end_destination: actual_end,
        bike_type: actual_prof,
        group_size: final_group_size,
        kids: final_kids
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
      req.params['boundary.country'] = 'GB'

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
