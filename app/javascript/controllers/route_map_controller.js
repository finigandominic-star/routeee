import { Controller } from "@hotwired/stimulus"
import L from "leaflet"

export default class extends Controller {
  static values = {
    geojson: Object,
    interactive: { type: Boolean, default: true }
  }

  connect() {
    // 1. Parse geojson safely if it arrived as an escaped string
    let geojsonData = this.geojsonValue
    if (typeof geojsonData === "string") {
      try {
        geojsonData = JSON.parse(geojsonData)
      } catch (e) {
        console.error("Failed to parse geojsonValue", e)
        geojsonData = null
      }
    }

    // 2. Initialize Leaflet map on this container element
    this.map = L.map(this.element, {
      zoomControl: this.interactiveValue,
      scrollWheelZoom: this.interactiveValue,
      touchZoom: this.interactiveValue,
      doubleClickZoom: this.interactiveValue,
      dragging: this.interactiveValue,
      boxZoom: this.interactiveValue,
      keyboard: this.interactiveValue
    })

    L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
      attribution: "&copy; OpenStreetMap"
    }).addTo(this.map)

    // 3. Render route layer and fix routeLayer reference error
    if (geojsonData && (geojsonData.features || geojsonData.type)) {
      const routeLayer = L.geoJSON(geojsonData, {
        style: {
          color: "#0d6efd",
          weight: 4,
          opacity: 0.8
        }
      }).addTo(this.map)

      this.routeLayer = routeLayer

      const bounds = routeLayer.getBounds()
      if (bounds.isValid()) {
        this.map.fitBounds(bounds, { padding: [15, 15] })
      }
    } else {
      this.map.setView([51.4543, -0.9781], 13) // Fallback coordinates
    }

    // 4. Force Leaflet to recalculate dimensions once the DOM layout settles
    setTimeout(() => {
      if (this.map) {
        this.map.invalidateSize()
        if (this.routeLayer && this.routeLayer.getBounds().isValid()) {
          this.map.fitBounds(this.routeLayer.getBounds(), { padding: [15, 15] })
        }
      }
    }, 150)
  }

  disconnect() {
    if (this.map) {
      this.map.remove()
      this.map = null
    }
  }
}
