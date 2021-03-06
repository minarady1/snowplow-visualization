snowAPI = "http://dev.hel.fi/aura/v1/snowplow/"
activePolylines = []
map = null

initializeGoogleMaps = (callback, time)->
  helsinkiCenter = new google.maps.LatLng(60.193084, 24.940338)

  mapOptions =
    center: helsinkiCenter
    zoom: 13
    disableDefaultUI: true
    zoomControl: true
    zoomControlOptions:
      style: google.maps.ZoomControlStyle.SMALL
      position: google.maps.ControlPosition.RIGHT_BOTTOM

  styles = [
    "stylers": [
      { "invert_lightness": true }
      { "hue": "#00bbff" }
      { "weight": 0.4 }
      { "saturation": 80 }
    ]
  ,
    "featureType": "road.arterial"
    "stylers": [
      { "color": "#00bbff" }
      { "weight": 0.1 }
    ]
  ,
    "elementType": "labels"
    "stylers": [ "visibility": "off" ]
  ,
    "featureType": "road.local"
    "elementType": "labels.text.fill"
    "stylers": [
      { "visibility": "on" }
      { "color": "#2b8aa9" }
    ]
  ,
    "featureType": "administrative.locality"
    "stylers": [ "visibility": "on" ]
  ,
    "featureType": "administrative.neighborhood"
    "stylers": [ "visibility": "on" ]
  ,
    "featureType": "administrative.land_parcel"
    "stylers": [ "visibility": "on" ]
  ]

  map = new google.maps.Map(document.getElementById("map-canvas"), mapOptions)
  map.setOptions({styles: styles})

  callback(time)

getPlowJobColor = (job)->
  switch job
    when "kv" then "#84ff00"
    when "au" then "#f2c12e"
    when "su" then "#d93425"
    when "hi" then "#ffffff"
    when "hn" then "#00a59b"
    when "hs" then "#910202"
    when "ps" then "#970899"
    when "pe" then "#132bbe"
    else "#6c00ff"

addMapLine = (plowData, plowJobId)->
  plowTrailColor = getPlowJobColor(plowJobId)
  polylinePath = _.reduce(plowData, ((accu, x)->
    accu.push(new google.maps.LatLng(x.coords[1], x.coords[0]))
    accu), [])

  polyline = new google.maps.Polyline(
    path: polylinePath
    geodesic: true
    strokeColor: plowTrailColor
    strokeWeight: 1.5
    strokeOpacity: 0.6
  )

  activePolylines.push(polyline)
  polyline.setMap map

clearMap = ->
  _.map(activePolylines, (polyline)-> polyline.setMap(null))

displayNotification = (notificationText)->
  $notification = $("#notification")
  $notification.empty().text(notificationText).slideDown(800).delay(5000).slideUp(800)

getActivePlows = (time, callback)->
  $("#load-spinner").fadeIn(400)
  $.getJSON("#{snowAPI}?since=#{time}&location_history=1")
    .done((json)->
      if json.length isnt 0
        callback(time, json)
      else
        displayNotification("Ei näytettävää valitulla ajalla")
      $("#load-spinner").fadeOut(800)
    )
    .fail((error)-> console.error("Failed to fetch active snowplows: #{JSON.stringify(error)}"))


createIndividualPlowTrail = (time, plowId, historyData)->
  $("#load-spinner").fadeIn(800)
  $.getJSON("#{snowAPI}#{plowId}?since=#{time}&temporal_resolution=4")
    .done((json)->
      if json.length isnt 0
        _.map(json, (oneJobOfThisPlow)->
          plowHasLastGoodEvent = oneJobOfThisPlow? and oneJobOfThisPlow[0]? and oneJobOfThisPlow[0].events? and oneJobOfThisPlow[0].events[0]?
          if plowHasLastGoodEvent
            addMapLine(oneJobOfThisPlow, oneJobOfThisPlow[0].events[0]))
        $("#load-spinner").fadeOut(800)
    )
    .fail((error)-> console.error("Failed to create snowplow trail for plow #{plowId}: #{JSON.stringify(error)}"))

createPlowsOnMap = (time, json)->
  _.each(json, (x)->
    createIndividualPlowTrail(time, x.id, json)
  )

populateMap = (time)->
  clearMap()
  getActivePlows("#{time}hours+ago", (time, json)-> createPlowsOnMap(time, json))


$(document).ready ->
  clearUI = ->
    $("#notification").stop(true, false).slideUp(200)
    $("#load-spinner").stop(true, false).fadeOut(200)

  $("#info").addClass("off") if localStorage["auratkartalla.userHasClosedInfo"]

  initializeGoogleMaps(populateMap, 8)

  $("#time-filters li").on("click", (e)->
    e.preventDefault()
    clearUI()

    $("#time-filters li").removeClass("active")
    $(e.currentTarget).addClass("active")
    $("#visualization").removeClass("on")

    populateMap($(e.currentTarget).data("hours"))
  )

  $("#info-close, #info-button").on("click", (e)->
    e.preventDefault()
    $("#info").toggleClass("off")
    localStorage["auratkartalla.userHasClosedInfo"] = true
  )
  $("#visualization-close, #visualization-button").on("click", (e)->
    e.preventDefault()
    $("#visualization").toggleClass("on")
  )






console.log("
.................................................................................\n
.                                                                               .\n
.      _________                            .__                                 .\n
.     /   _____/ ____   ______  _  ________ |  |   ______  _  ________          .\n
.     \\_____  \\ /    \\ /  _ \\ \\/ \\/ /\\____ \\|  |  /  _ \\ \\/ \\/ /  ___/          .\n
.     /        \\   |  (  <_> )     / |  |_> >  |_(  <_> )     /\\___ \\           .\n
.    /_______  /___|  /\\____/ \\/\\_/  |   __/|____/\\____/ \\/\\_//____  >          .\n
.            \\/     \\/ .__           |__|     .__  .__             \\/   .___    .\n
.                ___  _|__| ________ _______  |  | |__|_______ ____   __| _/    .\n
.        Sampsa  \\  \\/ /  |/  ___/  |  \\__  \\ |  | |  \\___   // __ \\ / __ |     .\n
.        Kuronen  \\   /|  |\\___ \\|  |  // __ \\|  |_|  |/    /\\  ___// /_/ |     .\n
.            2014  \\_/ |__/____  >____/(____  /____/__/_____ \\\\___  >____ |     .\n
.                              \\/           \\/              \\/    \\/     \\/     .\n
.                  https://github.com/sampsakuronen/snowplow-visualization      .\n
.                                                                               .\n
.................................................................................\n")
console.log("It is nice to see that you want to know how something is made. We are looking for guys like you: http://reaktor.fi/careers/")
