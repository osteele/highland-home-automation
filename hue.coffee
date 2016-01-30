assert = require 'assert'
fs = require 'fs'
yaml = require 'js-yaml'
{HueApi} = Hue = require 'node-hue-api'

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

exports.setLightState = (lightNumber, state) ->
  clientP.then (client) ->
    client.setLightState lightNumber, state
