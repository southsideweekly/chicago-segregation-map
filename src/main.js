import mapboxgl from "mapbox-gl"
import Sidechain from "@nprapps/sidechain"

import {
  formToObj,
  formToSearchParams,
  searchParamsToForm,
  setMapLayerSource,
} from "./utils"

import "mapbox-gl/dist/mapbox-gl.css"
import "./css/style.css"

const MAP_LAYERS = ["redlining", "school-closures"]

const mapContainer = document.getElementById("map")
const form = document.getElementById("controls")
const yearInput = document.getElementById("year")

const map = new mapboxgl.Map({
  container: mapContainer,
  style: "style-dark.json",
  center: [-87.6597, 41.83],
  minZoom: 9,
  maxZoom: 15,
  zoom: 9.25,
  hash: true,
  dragRotate: false,
  attributionControl: true, // TODO: replace with custom control
})

function updateMapYear(year) {
  setMapLayerSource(map, "tract-points", `tracts-${yearInput.value}`)
  document.getElementById("year-value").innerText = year

  document.querySelectorAll(".legend-race .race").forEach((el) => {
    el.classList.toggle(
      "hidden",
      !(+year >= +el.dataset.minYear && +year <= +el.dataset.maxYear)
    )
  })
}

function onMapUpdate() {
  const formObj = formToObj(form)

  updateMapYear(year.value)

  const layers = formObj.layer.split(",")
  MAP_LAYERS.forEach((layer) => {
    map.setLayoutProperty(
      layer,
      "visibility",
      layers.includes(layer) ? "visible" : "none"
    )
  })
  formToSearchParams(form)
}

map.once("styledata", () => {
  searchParamsToForm(form)
  onMapUpdate()

  document.querySelectorAll("#controls input").forEach((el) => {
    el.addEventListener("input", onMapUpdate)
  })

  Sidechain.registerGuest()
})
