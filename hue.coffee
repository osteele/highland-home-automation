assert = require 'assert'
fs = require 'fs'
yaml = require 'js-yaml'
{HueApi} = Hue = require 'node-hue-api'

config = yaml.load fs.readFileSync './config.yml'

username = process.env.HUE_USERNAME

hostnameP =
  Hue.nupnpSearch()
  .then ([bridge]) -> bridge?.ipaddress

createUser = ->
  hostnameP.then (hostname) ->
    hue = new HueApi()
    hue.registerUser(hostname, 'rpi').then(console.info)

clientP =
  hostnameP.then (hostname) ->
    assert username, 'username is null'
    assert hostname, 'hostname is null'
    new HueApi(hostname, username)

exports.clientP = clientP
exports.username = username

exports.getBridgeLocaltimeP = ->
  clientP
  .then (client) -> client.config()
  .then ({localtime}) -> new Date localtime

exports.setLightState = (lightNumber, state) ->
  clientP.then (client) ->
    client.setLightState lightNumber, state

exports.scheduleEvent = (lightNumber, event) ->
  clientP.then (client) ->
    client.scheduleEvent lightNumber, event
