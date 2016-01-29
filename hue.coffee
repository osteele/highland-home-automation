assert = require 'assert'
fs = require 'fs'
yaml = require 'js-yaml'
{HueApi} = Hue = require 'node-hue-api'
subscription = require './subscribe'

config = yaml.load fs.readFileSync './config.yml'

username = process.env.HUE_USERNAME

hostnameP =
  Hue.nupnpSearch()
  .then ([bridge]) -> bridge.ipaddress

createUser = ->
  hostnameP.then (hostname) ->
    hue = new HueApi()
    hue.registerUser(hostname, 'rpi').then(console.info)

# TODO make this a command-line option, or move to a separate script
# createUser(…).fail(console.error).done()

clientP =
  hostnameP.then (hostname) ->
    assert username, 'username is null'
    assert hostname, 'hostname is null'
    new HueApi(hostname, username)

subscription.on 'message', (topic, payload) ->
  payload = JSON.parse payload.toString()
  console.info 'central', topic#, payload

  return unless payload.event is 'motion'
  return if payload.isStateChange is false
  return unless payload.value is 'active'

  rooms = (room for room in config.rooms when payload.deviceName in room.motion)
  for room in rooms
    console.info 'room', room.name
    lights = room.hues or []
    for lightNumber in lights
      console.info 'turning on', lightNumber
      clientP.then (client) ->
        state = Hue.lightState.create().bri(255).transitiontime(1000)
        client.setLightState lightNumber, state
      .fail console.error

# TODO schedule the light to turn off again
# TODO light adjacent rooms
# TODO turn on SmartThings switches too
