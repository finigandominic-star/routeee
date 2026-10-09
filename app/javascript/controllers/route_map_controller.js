import { Controller } from "@hotwired/stimulus"
import L from "leaflet"

export default class extends Controller {
  static values = { geojson: Object }

  connect() {
    // Determine container element (target or controller root)
    const container = this.hasContainerTarget ? this.containerTarget : this.element

    // 1. Initialize NAVIGABLE Leaflet map
    this.map = L.map(container, {
      zoomControl: true,       // Enable +/- zoom controls
      scrollWheelZoom: true,  // Enable mouse wheel zoom
      doubleClickZoom: true,  // Enable double click zoom
      touchZoom: true,        // Enable touch zoom
      boxZoom: true,          // Enable box drag zoom
      keyboard: true,         // Enable keyboard navigation
      dragging: true          // Enable map dragging/panning
    })

    // 2. Add OpenStreetMap tiles
    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      attribution: '&copy; OpenStreetMap'
    }).addTo(this.map)

    // 3. Render initial route
    this.renderRoute()
  }

  // Automatically fires whenever data-route-map-geojson-value changes via Turbo Stream
  geojsonValueChanged() {
    if (this.map) {
      this.renderRoute()
    }
  }

  renderRoute() {
    // Clear existing layer
    if (this.routeLayer) {
      this.map.removeLayer(this.routeLayer)
    }

    if (this.hasGeojsonValue && Object.keys(this.geojsonValue).length > 0) {
      this.routeLayer = L.geoJSON(this.geojsonValue, {
        style: {
          color: '#0d6efd',
          weight: 4,
          opacity: 0.8
        }
      }).addTo(this.map)

      // Ensure map recalculates size and fits bounds to full route
      this.map.invalidateSize()
      this.map.fitBounds(this.routeLayer.getBounds(), { padding: [20, 20] })
    } else {
      // Fallback center
      this.map.setView([51.4543, -0.9781], 13)
    }
  }

  disconnect() {
    if (this.map) {
      this.map.remove()
    }
  }
}
