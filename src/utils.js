export function setMapLayerSource(map, layerId, source) {
  const oldLayers = map.getStyle().layers
  const layerIndex = oldLayers.findIndex((l) => l.id === layerId)
  if (layerIndex < 0) return
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
    let value = formData.getAll(name).join(",")
    if (form.elements[name].type === "checkbox") {
      value = !!value
    }
    formObj[name] = value
  })
  return formObj
}

export function formToSearchParams(form) {
  const params = new URLSearchParams({
    ...Object.fromEntries(new URLSearchParams(window.location.search)),
    ...Object.fromEntries(Object.entries(formToObj(form))),
  })
  window.history.replaceState(
    {},
    window.document.title,
    `${window.location.protocol}//${window.location.host}${
      window.location.pathname
    }${params.toString() === `` ? `` : `?${params}`}${window.location.hash}`
  )
}

export function searchParamsToForm(form) {
  const searchParams = new URLSearchParams(window.location.search)

  for (let [key, value] of searchParams.entries()) {
    if (!(key in form.elements)) return
    const input = form.elements[key]
    if (input.length > 1) {
      value = value.split(",")
      input.forEach((inputEl) => {
        inputEl.checked = value.includes(inputEl.value)
      })
    } else if (input.type === "checkbox") {
      input.checked = !!value
    } else {
      input.value = value
    }
  }
}
