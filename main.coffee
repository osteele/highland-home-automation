assert = require 'assert'
fs = require 'fs'
yaml = require 'js-yaml'
Hue = require 'node-hue-api'
subscription = require './subscribe'
hue = require './hue'

config = yaml.load fs.readFileSync './config.yml'

roomOn = (room) ->
  lights = room.hues or []
  for lightNumber in lights
    console.info 'turning on hue #', lightNumber
    state = Hue.lightState.create().bri(254).transitiontime(1000)
    hue.setLightState lightNumber, state
    .fail console.error

subscription.on 'message', (topic, payload) ->
  payload = JSON.parse payload.toString()
  console.info 'message', topic
  return if payload.isStateChange is false

  rooms = (room for room in config.rooms when payload.deviceName in room.motion)
  for room in rooms
    console.info 'room', room.name, payload.event, payload.value
    switch "#{payload.event}:#{payload.value}"
      when 'motion:active'
        roomOn room

# TODO schedule the light to turn off again
# TODO choose color temperature according to time of day
# TODO light adjacent rooms
# TODO turn on SmartThings switches too
