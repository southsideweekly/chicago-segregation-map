import mapboxgl from "mapbox-gl"

import "mapbox-gl/dist/mapbox-gl.css"
import "./css/style.css"

const mapContainer = document.getElementById("map")

const map = new mapboxgl.Map({
  container: mapContainer,
  style: "style.json",
  center: [-87.6597, 41.83],
  minZoom: 9,
  maxZoom: 17,
  zoom: 9.25,
  hash: true,
  dragRotate: false,
  attributionControl: true, // TODO: replace with custom control
})
