# Vera-tradfri

A plugin for the Vera home automation controller to manage IKEA Tradfri devices via Tradfri Gateway.

## Installation
- Create a new device
- Configure the IP of your Tradfri Gateway
- Lookup the SecurityCode on the bottom for your Tradfri Gateway and enter the code in the corresponding attributed of the created device 
- Restart Luup and your device will appear after a short while

## Limitations
This plugin relies on [CoAP](https://en.wikipedia.org/wiki/Constrained_Application_Protocol), the protocol that the IKEA Tradfri gateway uses.
The Lua configuration that ships with Vera does not include support for this.
This plugin is supported for use with openLuup with AltUI as available as the Docker image [vwout/openluup](https://hub.docker.com/r/vwout/openluup).
To use this plugin on a random Linux system, install the Lua library [libcoap](https://github.com/vwout/luacoap) as Debian package: [luacoap-lua5.x-0.2.0-Linux.deb](https://github.com/vwout/luacoap/blob/master/downloads/).
