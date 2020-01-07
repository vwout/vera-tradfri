local json = require("dkjson")
local coap = require("coap")

---
-- ServiceId strings for the different sensors
local GWDeviceSID         = "urn:upnp-org:serviceId:tradfri-gw1"             -- Main device serviceId
local GWSwitchPowerSID    = "urn:upnp-org:serviceId:SwitchPower1"
local GWDimmingSID        = "urn:upnp-org:serviceId:Dimming1"
local GWColorSID          = "urn:micasaverde-com:serviceId:Color1"
local GWSecuritySensorSID = "urn:micasaverde-com:serviceId:SecuritySensor1"

local GWDeviceType        = "urn:schemas-upnp-org:device:tradfri-gw:1"


---
-- 'global' program variables assigned in init()
local GWDeviceID   -- Luup device ID
local Config = {
  GW_Ip               = "",
  GW_Port             = 5684,
  GW_Identity         = "",
  GW_Psk              = ""
}
local DeviceData = {}

local function log(message)
  luup.log("TradfriGW #" .. GWDeviceID .. ": " .. (message or ""))
end

local function isempty(s)
  return s == nil or s == ""
end

local function getLuupVar(name, service, device)
  service = service or GWDeviceSID
  device = device or GWDeviceID

  local x = luup.variable_get(service, name, device)
  return x
end

local function setLuupVar(name, value, service, device)
  service = service or GWDeviceSID
  device = device or GWDeviceID

  local old = getLuupVar(name, service, device)
  if tostring(value) ~= old then
    luup.variable_set(service, name, value, device)
  end
end

-- get and check UI variables
local function getDeviceVar(name, default, lower, upper, service, device)
  service = service or GWDeviceSID
  device = device or GWDeviceID
  local oldvalue = getLuupVar(name, service, device)
  local value = oldvalue or default

  if value and (value ~= "") then						-- bounds check if required
    if lower and (tonumber(value) < lower) then value = lower end
    if upper and (tonumber(value) > upper) then value = upper end
  end

  value = tostring(value)
  if value ~= oldvalue then  -- default or limits may have modified value
    setLuupVar(name, value, service, device)
  end
	return value
end



-- init() called on startup as specified in I_TradfriGW.xml
function init(lul_device)
  GWDeviceID = lul_device

  log("Starting up with ID " .. luup.devices[GWDeviceID].id)
  setLuupVar("Connected", 0)

  Config.GW_Ip                 = luup.devices[GWDeviceID].ip
  Config.GW_Port               = tonumber(getDeviceVar("Port",    Config.GW_Port, 1025, 65535))
  Config.GW_Identity           = getDeviceVar("Identity")
  Config.GW_Psk                = getDeviceVar("Psk")

  if (isempty(Config.GW_Identity)) or (isempty(Config.GW_Psk)) then
    -- TODO: Obtain Identity/Psk
  else
    -- TODO: Load devices
  end
end


------------------------------------------------------------------------------------
-- Implementation UPnP actions
------------------------------------------------------------------------------------

-- ServiceId: urn:upnp-org:serviceId:tradfri-gw1
-- Action: Reboot
function Reboot(lul_device)
    log(string.format("TODO Reboot: %s for device %d", newArmedValue, lul_device))
end

-- ServiceId: urn:upnp-org:serviceId:tradfri-gw1
-- Action: FactoryReset
function FactoryReset(lul_device)
    log(string.format("TODO FactoryReset: %s for device %d", newArmedValue, lul_device))
end

-- ServiceId: urn:upnp-org:serviceId:tradfri-gw1
-- Action: SetCommissioningMode
function SetCommissioningMode(lul_device, timeout)
    log(string.format("TODO SetCommissioningMode: timeout %d for device %d", timeout, lul_device))
end

-- ServiceId: urn:upnp-org:serviceId:SwitchPower1
-- Action: SetTarget
function SwitchPower_SetTarget(lul_device, newTargetValue)
    log(string.format("TODO SwitchPower_SetTarget: newTargetValue %d for device %d", newTargetValue, lul_device))
end

-- ServiceId: urn:upnp-org:serviceId:Dimming1
-- Action: SetLoadLevelTarget
function Dimming_SetLoadLevelTarget(lul_device, newLoadlevelTarget)
    log(string.format("TODO Dimming_SetLoadLevelTarget: newLoadlevelTarget %d for device %d", newLoadlevelTarget, lul_device))
end

-- ServiceId: urn:upnp-org:serviceId:HaDevice1
-- Action: ToggleState
function HaDevice_ToggleState(lul_device)
    log(string.format("TODO HaDevice_ToggleState: for device %d", lul_device))
end

-- ServiceId: urn:upnp-org:serviceId:Color1
-- Action: SetColorRGB
function Color_SetColorRGB(lul_device, newColorRGBTarget)
    log(string.format("TODO Color_SetColorRGB: newColorRGBTarget %s for device %d", newColorRGBTarget, lul_device))
end

-- ServiceId: urn:upnp-org:serviceId:Color1
-- Action: SetColor
function Color_SetColor(lul_device, newColorTarget)
    log(string.format("TODO Color_SetColor: newColorTarget %s for device %d", newColorTarget, lul_device))
end

-- ServiceId: urn:upnp-org:serviceId:SecuritySensor1
-- Action: SetArmed
function SecuritySensor_SetArmed(lul_device, newArmedValue)
    log(string.format("TODO SecuritySensor_SetArmed: newArmedValue %s for device %d", newArmedValue, lul_device))
end
