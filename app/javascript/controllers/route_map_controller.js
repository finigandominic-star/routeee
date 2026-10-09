import { Controller } from "@hotwired/stimulus"
import L from "leaflet"

export default class extends Controller {
  static values = {
    geojson: Object,
    interactive: { type: Boolean, default: true } // Defaults to true for show pages
  }

  connect() {
    // Pass the interactive value to the Leaflet map options
    this.map = L.map(this.element, {
      zoomControl: this.interactiveValue,
      scrollWheelZoom: this.interactiveValue,
      touchZoom: this.interactiveValue,
      doubleClickZoom: this.interactiveValue,
      dragging: this.interactiveValue,
      boxZoom: this.interactiveValue,
      keyboard: this.interactiveValue
    })

    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      attribution: '&copy; OpenStreetMap'
    }).addTo(this.map)

    if (this.hasGeojsonValue && Object.keys(this.geojsonValue).length > 0) {
      const routeLayer = L.geoJSON(this.geojsonValue, {
        style: {
          color: '#0d6efd',
          weight: 4,
          opacity: 0.8
        }
      }).addTo(this.map)

      this.map.fitBounds(routeLayer.getBounds(), { padding: [10, 10] })
    } else {
      this.map.setView([51.4543, -0.9781], 13) // Reading fallback
    }
  }

  disconnect() {
    if (this.map) {
      this.map.remove()
    }
  }
}
