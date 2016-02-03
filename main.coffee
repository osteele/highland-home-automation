assert = require 'assert'
fs = require 'fs'
yaml = require 'js-yaml'
Hue = require 'node-hue-api'
subscriber = require './subscribe'
hue = require './hue'

config = yaml.load fs.readFileSync './config.yml'

removeRoomTimers = (room) ->
  lights = room.hues or []
  hue.clientP
  .then (client) -> client.getSchedules()
  .then (schedules) ->
    schedules.filter ({autodelete, localtime, command}) ->
      return false unless autodelete
      return false unless m = command?.address?.match /^\/api\/.+\/lights\/(\d+)\//
      # TODO only remove added schedules
      return m[1] in lights.map(String)
  .then (schedules) ->
    for schedule in schedules
      console.info "deleting schedule ##{schedule.id}"
      hue.clientP
      .then (client) -> client.deleteSchedule schedule.id
      .done()

scheduleLightOff = (lightNumber, timeString) ->
  # console.info "schedule #{lightNumber} off at #{timeString}"
  hue.scheduleLightEvent lightNumber,
    # TODO use the light's name in the schedule name
    name: "Switch off light ##{lightNumber}"
    description: "creator=ha;light=#{lightNumber}"
    localtime: timeString
    state:
      on: false
      'transition time': 300 # 30 s
  .then (id) -> console.info "created schedule ##{id}: light ##{lightNumber} off at #{timeString}"
  .fail console.error

roomLightsOn = (room) ->
  lights = room.hues or []
  for lightNumber in lights
    console.info "turning on hue ##{lightNumber}"
    hue.setLightState lightNumber, on: true, bri: 254, transitiontime: 5 # 0.5 s
    .fail console.error

scheduleRoomLightsOff = (room) ->
  hue.getBridgeLocaltimeP().then (currentBridgeTime) ->
    t0 = +currentBridgeTime
    t1 = t0 + 10 * 60 * 1000
    futureTimeString = (new Date t1).toISOString().replace(/\..*/, '')
    lights = room.hues or []
    for lightNumber in lights
      # console.info "scheduling hue ##{lightNumber} off"
      scheduleLightOff lightNumber, futureTimeString

handleMessage = (topic, payload) ->
  return if payload.isStateChange is false

  rooms = config.rooms.filter ({motion}) -> payload.deviceName in motion
  for room in rooms
    switch "#{payload.event}:#{payload.value}"
      when 'motion:active'
        removeRoomTimers room
        .then -> roomLightsOn room
        .done()
      when 'motion:inactive'
        # TODO remove only when *all* a room's sensors are inactive
        removeRoomTimers room
        .then -> scheduleRoomLightsOff room
        .done()

subscriber.handleMessage = (message, done) ->
  console.info 'message', message.topic
  try
    handleMessage message.topic, JSON.parse message.payload.toString()
  finally
    done()

console.info "Starting at #{new Date}"

# TODO choose color temperature according to time of day
# TODO light adjacent rooms
# TODO turn on SmartThings switches too
# TODO real logging
