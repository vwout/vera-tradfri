# Vera-tradfri

A plugin for the Vera home automation controller to manage IKEA Tradfri devices via a Tradfri Gateway.
The following devices are supported:
- Light bulb
- Outlet (power plug)

Due to technical limitations of the Tradfri system, it is not possible to capture events of a remote control, motion sensor or dimmer.
These directly control linked devices, so only the effect of an action on a remote can be observed when a light or outlet state changes. 

## Installation
- Copy or upload `D_TradfriGW.json`, `D_TradfriGW.xml`, `I_TradfriGW.xml` and `L_TradfriGW.lua`.
- Get `D_DimmableLight1.xml`, `D_DimmableRGBLight1.xml` and `D_BinaryLight1.xml` files plus the `.json` variants from your Vera and copy or upload these when you use `openLuup`.
- Add a new device by clicking *Create* on the *Devices* page. Use `D_TradfriGW.xml` as the *definition* filename and `I_TradfriGW.xml` as the *implementation* filename.
- Wait for the new device to appear.
- Configure the IP of your Tradfri Gateway in the `ip` attribute.
- Lookup the SecurityCode on the bottom for your Tradfri Gateway and enter the code in the corresponding variable of the created device 
- Restart Luup and your devices should appear after a short while. The `SecurityCode` attribute will be cleared after successful authentication to the gateway.

## Limitations
This plugin relies on [CoAP](https://en.wikipedia.org/wiki/Constrained_Application_Protocol), the protocol that the IKEA Tradfri gateway uses.
The Lua configuration that ships with Vera does not include support for this.
For now, this plugin is supported for use with openLuup with AltUI as available as the Docker image [vwout/openluup](https://hub.docker.com/r/vwout/openluup).
To use this plugin on a random Linux system, install the Lua library [libcoap](https://github.com/vwout/luacoap) as Debian package: [luacoap-lua5.x-0.2.0-Linux.deb](https://github.com/vwout/luacoap/blob/master/downloads/).

## Known issues
- Device state changes may no longer be updated after a certain amount of time (the CoAP observer internally disconnects). Sending commands to the device will still work.
