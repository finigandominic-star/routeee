import { Controller } from "@hotwired/stimulus"
import L from "leaflet"

export default class extends Controller {
  static values = { geojson: Object }

  connect() {
    // 1. Initialize map on the exact DOM element this controller is attached to (No ID needed!)
this.map = L.map(this.element, {
      zoomControl: false,       // Hides the +/- buttons
      scrollWheelZoom: false,   // Disables zooming with the mouse wheel
      doubleClickZoom: false,   // Disables zooming by double-clicking
      touchZoom: false,         // Disables pinch-to-zoom on mobile
      boxZoom: false,           // Disables shift-drag zooming
      keyboard: false,          // Disables keyboard navigation
      dragging: false           // Disables panning/dragging the map around
    })

    // 2. Add the OpenStreetMap tiles
    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      attribution: '&copy; OpenStreetMap'
    }).addTo(this.map)

    // 3. Draw the route if we have GeoJSON data
    if (this.hasGeojsonValue && Object.keys(this.geojsonValue).length > 0) {
      const routeLayer = L.geoJSON(this.geojsonValue, {
        style: {
          color: '#0d6efd', // Bootstrap primary blue
          weight: 4,
          opacity: 0.8
        }
      }).addTo(this.map)

      // 4. Automatically zoom the map so the whole route fits nicely in the box
      this.map.fitBounds(routeLayer.getBounds(), { padding: [10, 10] })

    } else {
      // Fallback view (Reading, UK) if something goes wrong
      this.map.setView([51.4543, -0.9781], 13)
    }
  }

  disconnect() {
    // Clean up the map when navigating away so it doesn't cause memory leaks
    if (this.map) {
      this.map.remove()
    }
  }
}
