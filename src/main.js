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

const MAP_LAYERS = ["redlining", "cha", "highways", "school-closures"]
const TOOLTIP_LAYERS = ["cha", "school-closures"]
const MAP_LAYERS_MIN_YEARS = {
  cha: 1930,
  highways: 1950,
  "school-closures": 2010,
}

const mapContainer = document.getElementById("map")
const form = document.getElementById("controls")
const yearInput = document.getElementById("year")
const redliningCategories = document.getElementById("redlining-categories")

const map = new mapboxgl.Map({
  container: mapContainer,
  style: "style-light.json",
  center: [-87.6597, 41.83],
  minZoom: 9,
  maxZoom: 15,
  zoom: 9.25,
  hash: true,
  dragRotate: false,
  attributionControl: true,
})

const isMobile = () => window.innerWidth <= 600

const shouldShowMapLayer = (layers, layer, year) =>
  layers.includes(layer) &&
  (!MAP_LAYERS_MIN_YEARS[layer] || year >= MAP_LAYERS_MIN_YEARS[layer])

function updateMapYear(year) {
  setMapLayerSource(map, "tract-points", `tracts-${yearInput.value}`)
  document.getElementById("year-value").innerText = year

  map.setFilter("cha", ["<", ["get", "constructed"], ["+", 10, +year]])

  document.querySelectorAll(".legend-race .race").forEach((el) => {
    el.classList.toggle(
      "hidden",
      !(+year >= +el.dataset.minYear && +year <= +el.dataset.maxYear)
    )
  })
  document.querySelectorAll(".layer-options label").forEach((el) => {
    el.classList.toggle(
      "hidden",
      !!el.dataset.minYear && +year < +el.dataset.minYear
    )
  })
}

function onMapUpdate() {
  const formObj = formToObj(form)

  updateMapYear(year.value)

  const layers = formObj.layer.split(",")

  redliningCategories.classList.toggle(
    "hidden",
    !shouldShowMapLayer(layers, "redlining", +year.value)
  )

  MAP_LAYERS.forEach((layer) => {
    map.setLayoutProperty(
      layer,
      "visibility",
      shouldShowMapLayer(layers, layer, +year.value) ? "visible" : "none"
    )
  })
  formToSearchParams(form)
}

const hoverPopup = new mapboxgl.Popup({
  closeButton: false,
  closeOnClick: false,
})

const clickPopup = new mapboxgl.Popup({
  closeButton: true,
  closeOnClick: true,
})

// TODO: Wentworth gardens, stateway gardens

const popupContent = (features) =>
  features
    .map(({ layer: { id: layerId }, properties: { name, ...properties } }) =>
      layerId === "cha"
        ? `
        <p class="title">${name}</p>
        <p><span class="label">Built</span> ${properties.built}</p>
        <p><span class="label">Demolished</span> ${properties.demolished}</p>
        <p><span class="label">Units</span> ${properties.units}</p>
        ${
          (properties.notes || "").trim() &&
          `<p class="label">Notes</p><p>${properties.notes}</p>`
        }`
        : `
        <p class="title">${name}</p>
        <p><span class="label">Address</span> ${properties.address}</p>
        `
    )
    .join("")

const removePopup = (popup) => {
  map.getCanvas().style.cursor = ""
  popup.remove()
}

const onMouseEnter = (e) => {
  const features = map.queryRenderedFeatures(e.point, {
    layers: TOOLTIP_LAYERS,
  })
  if (features.length > 0 && !clickPopup.isOpen()) {
    map.getCanvas().style.cursor = "pointer"
    if (!isMobile()) {
      hoverPopup
        .setLngLat(e.lngLat)
        .setHTML(`<div class="popup hover">${popupContent(features)}</div>`)
        .addTo(map)
    }
  } else {
    removePopup(hoverPopup)
  }
}

const onMouseLeave = () => {
  removePopup(hoverPopup)
}

const onMapClick = (e) => {
  const features = map.queryRenderedFeatures(e.point, {
    layers: TOOLTIP_LAYERS,
  })
  if (features.length > 0) {
    map.getCanvas().style.cursor = "pointer"
    removePopup(hoverPopup)
    clickPopup
      .setLngLat(e.lngLat)
      .setHTML(`<div class="popup click">${popupContent(features)}</div>`)
      .addTo(map)
  }
}

TOOLTIP_LAYERS.forEach((layer) => {
  map.on("mouseenter", layer, onMouseEnter)
  map.on("mouseleave", layer, onMouseLeave)
  map.on("click", layer, onMapClick)
})

map.once("styledata", () => {
  searchParamsToForm(form)
  onMapUpdate()

  document.querySelectorAll("#controls input").forEach((el) => {
    el.addEventListener("input", onMapUpdate)
  })

  Sidechain.registerGuest()
})
