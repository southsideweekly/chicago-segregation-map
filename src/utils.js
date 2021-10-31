export function setMapLayerSource(map, layerId, source) {
  const oldLayers = map.getStyle().layers
  const layerIndex = oldLayers.findIndex((l) => l.id === layerId)
  const layerDef = oldLayers[layerIndex]
  const before = oldLayers[layerIndex + 1] && oldLayers[layerIndex + 1].id
  layerDef.source = source
  map.removeLayer(layerId)
  map.addLayer(layerDef, before)
}

export function formToObj(form) {
  const formObj = {}
  const formNames = [
    ...new Set(
      Object.values(form.elements)
        .map(
          (input) =>
            (input instanceof NodeList || input instanceof HTMLCollection
              ? input[0]
              : input
            ).name
        )
        .filter((name) => !!name)
    ),
  ]
  const formData = new FormData(form)

  formNames.map((name) => {
    let value = formData.get(name)
    if (form.elements[name].type === "checkbox") {
      value = !!value
    }
    formObj[name] = value
  })
  return formObj
}

export function formObjToSearchParams(formObj) {
  const params = new URLSearchParams({
    ...Object.fromEntries(new URLSearchParams(window.location.search)),
    ...Object.fromEntries(Object.entries(formObj).filter((entry) => entry[1])),
  })
  window.history.replaceState(
    {},
    window.document.title,
    `${window.location.protocol}//${window.location.host}${
      window.location.pathname
    }${params.toString() === `` ? `` : `?${params}`}${window.location.hash}`
  )
}
