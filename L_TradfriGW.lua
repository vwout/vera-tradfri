--  This program is free software: you can redistribute it and/or modify
--  it under the terms of the GNU General Public License as published by
--  the Free Software Foundation, either version 3 of the License, or
--  (at your option) any later version.
--
--  This program is distributed in the hope that it will be useful,
--  but WITHOUT ANY WARRANTY; without even the implied warranty of
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--  GNU General Public License for more details.
--
--  You should have received a copy of the GNU General Public License
--  along with this program.  If not, see <https://www.gnu.org/licenses/>.
ABOUT = {
  NAME        = "TradfriGW",
  VERSION     = "0.4.0",
  DESCRIPTION = "A plugin for Vera to control IKEA Tradfri devices via a Tradfri gateway",
  AUTHOR      = "@vwout",
  REPOSITORY  = "https://github.com/vwout/vera-tradfri",
}

local json = require("dkjson")
local coap = require("coap")
local socket = require("socket")

------------------------------------------------------------------------------------
-- Tradfri constants
-- Source: com/ikea/tradfri/lighting/ipso/IPSOObjects
------------------------------------------------------------------------------------
local GW = {}
GW.METHOD_GET = 1
GW.METHOD_POST = 2
GW.METHOD_PUT = 3
GW.METHOD_OBSERVE = 4


GW.ROOT_DEVICES = "15001"
GW.ROOT_GATEWAY = "15011"
GW.ROOT_GROUPS = "15004"
GW.ROOT_MOODS = "15005"
GW.ROOT_NOTIFICATION = "15006"
GW.ROOT_REMOTE_CONTROL = "15009"
GW.ROOT_SIGNAL_REPEATER = "15014"
GW.ROOT_SMART_TASKS = "15010"
GW.ROOT_START_ACTION = "15013"  -- found under ATTR_START_ACTION

GW.ATTR_BLINDS_CONTROL = "15015"

GW.ATTR_ALEXA_PAIR_STATUS = "9093"
GW.ATTR_AUTH = "9063"
GW.ATTR_APPLICATION_TYPE = "5750"
GW.APPLICATION_TYPE = {}
GW.APPLICATION_TYPE.REMOTE = 0
-- GW.APPLICATION_TYPE.REMOTE = 1  -- type for remotes is 0 on recent firmwares
GW.APPLICATION_TYPE.LIGHT = 2
GW.APPLICATION_TYPE.OUTLET = 3
GW.APPLICATION_TYPE.MOTION = 4
GW.APPLICATION_TYPE.BLIND = 7
GW.APPLICATION_TYPE.SOUND_CONTROLLER = 8

GW.ATTR_BLIND_CURRENT_POSITION = "5536"
GW.ATTR_BLIND_TRIGGER = "5523"

GW.ATTR_CERTIFICATE_PEM = "9096"
GW.ATTR_CERTIFICATE_PROV = "9092"
GW.ATTR_CLIENT_IDENTITY_PROPOSED = "9090"
GW.ATTR_CREATED_AT = "9002"
GW.ATTR_COGNITO_ID = "9101"
GW.ATTR_COMMISSIONING_MODE = "9061"
GW.ATTR_CURRENT_TIME_UNIX = "9059"
GW.ATTR_CURRENT_TIME_ISO8601 = "9060"

GW.ATTR_DEVICE_INFO = "3"
GW.DEVICE_INFO = {}
GW.DEVICE_INFO.BRAND = "0"
GW.DEVICE_INFO.NAME = "1"
GW.DEVICE_INFO.SERIAL = "2"
GW.DEVICE_INFO.FIRMWARE_VERSION = "3"
GW.DEVICE_INFO.POWER_SOURCES = "6"
GW.DEVICE_INFO.POWER_SOURCE = {}
GW.DEVICE_INFO.POWER_SOURCE.UNKNOWN = 0
GW.DEVICE_INFO.POWER_SOURCE.INTERNAL_BATTERY = 1
GW.DEVICE_INFO.POWER_SOURCE.EXTERNAL_BATTERY = 2
GW.DEVICE_INFO.POWER_SOURCE.BATTERY = 3
GW.DEVICE_INFO.POWER_SOURCE.POE = 4  -- Power over Ethernet
GW.DEVICE_INFO.POWER_SOURCE.USB = 5
GW.DEVICE_INFO.POWER_SOURCE.MAINS = 6
GW.DEVICE_INFO.POWER_SOURCE.SOLAR = 7
GW.DEVICE_INFO.BATTERY_LEVEL = "9"

GW.ATTR_GATEWAY_ID_2 = "9100"  -- stored in IKEA app code as gateway id
GW.ATTR_GATEWAY_TIME_SOURCE = "9071"
GW.ATTR_GATEWAY_UPDATE_PROGRESS = "9055"

GW.ATTR_GROUP_MEMBERS = "9018"

GW.ATTR_HOMEKIT_ID = "9083"
GW.ATTR_HS_LINK = "15002"

GW.ATTR_ID = "9003"
GW.ATTR_IDENTITY = "9090"
GW.ATTR_IOT_ENDPOINT = "9103"

GW.ATTR_KEY_PAIR = "9097"

GW.ATTR_LAST_SEEN = "9020"
GW.ATTR_LIGHT_CONTROL = "3311"

GW.ATTR_MASTER_TOKEN_TAG = "9036"
GW.ATTR_MOOD = "9039"

GW.ATTR_NAME = "9001"
GW.ATTR_NAME_DEFAULTS = {
  [GW.APPLICATION_TYPE.REMOTE] = "Remote",
  [GW.APPLICATION_TYPE.LIGHT] = "Light",
  [GW.APPLICATION_TYPE.OUTLET] = "Outlet",
  [GW.APPLICATION_TYPE.MOTION] = "Motion",
  [GW.APPLICATION_TYPE.BLIND] = "Blind",
  [GW.APPLICATION_TYPE.SOUND_CONTROLLER] = "Sound Controller",
  [GW.ROOT_GROUPS] = "Group"
}

GW.ATTR_NTP = "9023"
GW.ATTR_FIRMWARE_VERSION = "9029"
GW.ATTR_FIRST_SETUP = "9069"

GW.ATTR_GATEWAY_INFO = "15012"
GW.ATTR_GATEWAY_ID = "9081"
GW.ATTR_GATEWAY_REBOOT = "9030"
GW.ATTR_GATEWAY_FACTORY_DEFAULTS = "9031"
GW.ATTR_GATEWAY_FACTORY_DEFAULTS_MIN_MAX_MSR = "5605"
GW.ATTR_GOOGLE_HOME_PAIR_STATUS = "9105"

GW.ATTR_DEVICE_STATE = "5850"
GW.ATTR_LIGHT_DIMMER = "5851"  -- Dimmer, not following spec: 0..254
GW.ATTR_LIGHT_COLOR_HEX = "5706"  -- string representing a value in hex
GW.LIGHT_COLORS = {
    ["4a418a"] = "Blue",
    ["6c83ba"] = "Light Blue",
    ["8f2686"] = "Saturated Purple",
    ["a9d62b"] = "Lime",
    ["c984bb"] = "Light Purple",
    ["d6e44b"] = "Yellow",
    ["d9337c"] = "Saturated Pink",
    ["da5d41"] = "Dark Peach",
    ["dc4b31"] = "Saturated Red",
    ["dcf0f8"] = "Cold sky",
    ["e491af"] = "Pink",
    ["e57345"] = "Peach",
    ["e78834"] = "Warm Amber",
    ["e8bedd"] = "Light Pink",
    ["eaf6fb"] = "Cool daylight",
    ["ebb63e"] = "Candlelight",
    ["efd275"] = "Warm glow",
    ["f1e0b5"] = "Warm white",
    ["f2eccf"] = "Sunrise",
    ["f5faf6"] = "Cool white",
}
GW.ATTR_LIGHT_COLOR_X = "5709"
GW.ATTR_LIGHT_COLOR_Y = "5710"
GW.ATTR_LIGHT_COLOR_HUE = "5707"
GW.ATTR_LIGHT_COLOR_SATURATION = "5708"
GW.ATTR_LIGHT_MIREDS = "5711"
GW.ATTR_LIGHT_MIRED_RANGE = {250, 454}  -- 2200 - 4000  Kelvin

GW.ATTR_NOTIFICATION_EVENT = "9015"
GW.ATTR_NOTIFICATION_NVPAIR = "9017"
GW.ATTR_NOTIFICATION_STATE = "9014"

GW.ATTR_OTA_TYPE = "9066"
GW.ATTR_OTA_UPDATE_STATE = "9054"
GW.ATTR_OTA_UPDATE = "9037"

GW.ATTR_PUBLIC_KEY = "9098"
GW.ATTR_PRIVATE_KEY = "9099"
GW.ATTR_PSK = "9091"

GW.ATTR_REACHABLE_STATE = "9019"
GW.ATTR_REPEAT_DAYS = "9041"

GW.ATTR_SEND_CERT_TO_GATEWAY = "9094"
GW.ATTR_SEND_COGNITO_ID_TO_GATEWAY = "9095"
GW.ATTR_SEND_GH_COGNITO_ID_TO_GATEWAY = "9104"
GW.ATTR_SENSOR = "3300"
GW.ATTR_SENSOR_MAX_RANGE_VALUE = "5604"
GW.ATTR_SENSOR_MAX_MEASURED_VALUE = "5602"
GW.ATTR_SENSOR_MIN_RANGE_VALUE = "5603"
GW.ATTR_SENSOR_MIN_MEASURED_VALUE = "5601"
GW.ATTR_SENSOR_TYPE = "5751"
GW.ATTR_SENSOR_UNIT = "5701"
GW.ATTR_SENSOR_VALUE = "5700"
GW.ATTR_START_ACTION = "9042"
GW.ATTR_SMART_TASK_TYPE = "9040"  -- 4 = transition | 1 = not home | 2 = on/off
GW.ATTR_SMART_TASK_NOT_AT_HOME = 1
GW.ATTR_SMART_TASK_LIGHTS_OFF = 2
GW.ATTR_SMART_TASK_WAKE_UP = 4
GW.ATTR_SMART_TASK_TRIGGER_TIME_INTERVAL = "9044"
GW.ATTR_SMART_TASK_TRIGGER_TIME_START_HOUR = "9046"
GW.ATTR_SMART_TASK_TRIGGER_TIME_START_MIN = "9047"

GW.ATTR_SWITCH_CUM_ACTIVE_POWER = "5805"
GW.ATTR_SWITCH_ON_TIME = "5852"
GW.ATTR_SWITCH_PLUG = "3312"
GW.ATTR_SWITCH_POWER_FACTOR = "5820"

GW.ATTR_TIME_END_TIME_HOUR = "9048"
GW.ATTR_TIME_END_TIME_MINUTE = "9049"
GW.ATTR_TIME_START_TIME_HOUR = "9046"
GW.ATTR_TIME_START_TIME_MINUTE = "9047"

GW.ATTR_TRANSITION_TIME = "5712"

GW.ATTR_USE_CURRENT_LIGHT_SETTINGS = "9070"

GW.ATTR_SOUND_CONTROLLER = "15018"
GW.ATTR_PLAYER_SETTING = "15017"
GW.ATTR_VOLUME = "9117"


---
-- ServiceId strings for the different sensors
local GWDeviceSID         = "urn:upnp-org:serviceId:tradfri-gw1"             -- Main device serviceId
local GWHaDeviceSID       = "urn:upnp-org:serviceId:HaDevice1"
local GWSwitchPowerSID    = "urn:upnp-org:serviceId:SwitchPower1"
local GWDimmingSID        = "urn:upnp-org:serviceId:Dimming1"
local GWColorSID          = "urn:micasaverde-com:serviceId:Color1"
local GWSecuritySensorSID = "urn:micasaverde-com:serviceId:SecuritySensor1"
local GWBlindSID          = "urn:upnp-org:serviceId:WindowCovering1"

local GWDeviceType        = "urn:schemas-upnp-org:device:tradfri-gw:1"


---
-- 'global' program variables assigned in init()
local GWDeviceID   -- Luup device ID
local Config = {
  GW_Ip           = "",
  GW_Port         = 5684,
  GW_Identity     = "",
  GW_Psk          = "",
  GW_DebugMode    = false,
  GW_ObserveMode  = 0,
  GW_PollInterval = 30,
  GW_AddRooms     = false,
  GW_Devices      = {},
  --
  -- Internal state variables
  --
  GroupsUpdatePending   = false,
  GroupsUpdateTriggered = 0,
  PollCoroutine         = nil,
}


------------------------------------------------------------------------------------
-- Utility functions
------------------------------------------------------------------------------------

local function log(message)
  luup.log(ABOUT.NAME .. " #" .. (GWDeviceID or "?") .. ": " .. (tostring(message) or ""))
end

local function debug(message)
  if Config.GW_DebugMode then
    luup.log(ABOUT.NAME .. " #" .. (GWDeviceID or "?") .. " DEBUG: " .. (tostring(message) or ""))
  end
end

local function is_empty(s)
  return (s == nil) or (s == "")
end

local function is_array(t)
  local i = 0
  for _ in pairs(t) do
      i = i + 1
      if t[i] == nil then return false end
  end
  return true
end

local function setLuupAttr(name, value, deviceId)
  local old = luup.attr_get(name, deviceId)
  if ((value ~= old) or (old == nil)) then
	  luup.attr_set(name, value or "", deviceId)
  end
end

local function getLuupVar(name, service, device)
  service = service or GWDeviceSID
  device = device or GWDeviceID

  local v = luup.variable_get(service, name, device)
  return v
end

local function setLuupVar(name, value, service, device)
  service = service or GWDeviceSID
  device = device or GWDeviceID

  local old = getLuupVar(name, service, device)
  local changed = tostring(value) ~= old
  if changed then
    luup.variable_set(service, name, value, device)
  end
  return changed
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

  if value ~= nil then value = tostring(value) else value = "" end
  if value ~= oldvalue then  -- default or limits may have modified value
    setLuupVar(name, value, service, device)
  end
	return value
end

local function findChild(lul_parent, deviceid)
  for k,v in pairs(luup.devices) do
    if (v.device_num_parent == lul_parent) then
	    if (v.id == deviceid) then
		    return k, v
	    end
	  end
  end
  return nil, nil
end

local function getParent(lul_device)
  return luup.devices[lul_device].device_num_parent
end

local function getRoot(lul_device)
  while (getParent(lul_device) > 0) do
    lul_device = getParent(lul_device)
  end
  return lul_device
end

------------------------------------------------------------------------------------
-- Main logic
------------------------------------------------------------------------------------

local function protect_callback(callback)
  return function(payload)
      local ok, err = pcall(callback, payload)
      if not ok then
        log("CoAP callback failed: " .. (err or "<Unknown>"))
      end
    end
end

local function tradfriCommand(method, path, payload, identity, psk)
  identity = identity or Config.GW_Identity
  psk = psk or Config.GW_Psk

  local coapResult
  local coapClient = coap.Client()
  local path_str = table.concat(path, "/")
  local url = string.format("coaps://%s:%s@%s:%d/%s", identity, psk, Config.GW_Ip, Config.GW_Port, path_str)

  if method == GW.METHOD_OBSERVE then
    local callback
    if path[1] == GW.ROOT_DEVICES or path[1] == GW.ROOT_GROUPS then
      callback = protect_callback(function(payload) tradfriDevicesObserveCallback(path[1], payload) end)
    else
      log(string.format("Unable to process observe command to %d, unknown callback.", path[1]))
      return
    end

    debug("OBSERVE => " .. path_str)
    local ok, coapResult_or_err = pcall(function() return coapClient:observe(coap.CON, url, callback) end)
    if ok then
      if type(coapResult_or_err) ~= 'userdata' then
        log("CoAP call to gateway failed with error: " .. tostring(coapResult_or_err))
      else
        local coap_observer = {
          client = coapClient,
          listener = coapResult_or_err
        }
        coapResult = coap_observer
      end
    else
      log(string.format("CoAP observe call to %s failed: %s", path_str, coapResult_or_err or "<unknown CoAP result"))
    end
  else
    local callback
    if path[1] == GW.ROOT_GATEWAY then
      callback = protect_callback(tradfriGatewayCallback)
    elseif path[1] == GW.ROOT_DEVICES or path[1] == GW.ROOT_GROUPS then
      callback = protect_callback(function(payload) tradfriDevicesCallback(path[1], payload) end)
    else
      log(string.format("Unable to process command to %d, unknown callback.", path[1]))
      return
    end

    if method == GW.METHOD_GET then
      debug("GET => " .. path_str)
      local ok, coapResult_or_err = pcall(function() return coapClient:get(coap.CON, url, callback) end)
      if ok then
        coapResult = coapResult_or_err
      else
        log(string.format("CoAP get call to %s failed: %s", path_str, coapResult_or_err or "<unknown CoAP result"))
      end
    elseif method == GW.METHOD_POST then
      local payload_str = payload
      if type(payload) == 'table' then
        payload_str = json.encode(payload)
      end

      debug("POST " .. payload_str .. " => " .. path_str)
      local ok, coapResult_or_err = pcall(function() return coapClient:post(coap.CON, url, 0, payload_str, callback) end)
      if ok then
        coapResult = coapResult_or_err
      else
        log(string.format("CoAP post call to %s failed: %s", path_str, coapResult_or_err or "<unknown CoAP result"))
      end
    elseif method == GW.METHOD_PUT then
      local payload_str = payload
      if type(payload) == 'table' then
        payload_str = json.encode(payload)
      end

      debug("PUT " .. payload_str .. " => " .. path_str)
      local ok, coapResult_or_err = pcall(function() return coapClient:put(coap.CON, url, 0, payload_str, callback) end)
      if ok then
        coapResult = coapResult_or_err
      else
        log(string.format("CoAP post call to %s failed: %s", path_str, coapResult_or_err or "<unknown CoAP result"))
      end
    else
      log("Unable to process command, method '" .. method .. "' is unknown")
    end

    if coapResult ~= nil then
      log(string.format("CoAP call to gateway failed with error: %d", coapResult))
    end

    -- Explicitly close CoAP client
    coapClient = nil
  end

  return coapResult
end

local function trafdri_get_name(appl_type, payload)
  local tradfri_name = payload[GW.ATTR_NAME] or ""
  if tradfri_name == "" then
    local tradfri_device_info = payload[GW.ATTR_DEVICE_INFO] or {}
    tradfri_name = tradfri_device_info[GW.DEVICE_INFO.NAME] or ""
  end
  if tradfri_name == "" then
    tradfri_name = "Tradfri " .. (GW.ATTR_NAME_DEFAULTS[appl_type] or "Device")
  end
  return tradfri_name
end

local function createTradfriRemoteDevice(payload)
  log("Remote devices are not supported")
  return false
end

local function createTradfriLightDevice(payload)
  local tradfri_id = tostring(payload[GW.ATTR_ID])
  local tradfri_name = trafdri_get_name(GW.APPLICATION_TYPE.LIGHT, payload)

  if tradfri_id and tradfri_name then
    local device_attrs = payload[GW.ATTR_LIGHT_CONTROL] or {{}}
    local device_state = device_attrs[1][GW.ATTR_DEVICE_STATE] or 0
    local device_dimming = math.ceil(100 * (device_attrs[1][GW.ATTR_LIGHT_DIMMER] or 0) / 254)
    local mireds = device_attrs[1][GW.ATTR_LIGHT_MIREDS]
    local color_hex = device_attrs[1][GW.ATTR_LIGHT_COLOR_HEX]

    local variables = {
        "urn:upnp-org:serviceId:SwitchPower1,Status=" .. tostring(device_state),
        "urn:upnp-org:serviceId:SwitchPower1,Target=" .. tostring(device_state),
        "urn:upnp-org:serviceId:Dimming1,LoadLevelStatus=" .. tostring(device_dimming),
        "urn:upnp-org:serviceId:Dimming1,LoadLevelTarget=" .. tostring(device_dimming),
        "urn:micasaverde-com:serviceId:Color1,SupportedColors=" .. (color_hex and "W,D,R,G,B" or mireds and "W" or "")
    }

    local data = {
      tradfri_id = tradfri_id,
      tradfri_appl_type = GW.APPLICATION_TYPE.LIGHT,
      tradfri_attr_group = GW.ATTR_LIGHT_CONTROL,
      tradfri_name = tradfri_name,
      known_name = "",
      sid = GWDimmingSID,
      device_type = (color_hex or mireds) and "urn:schemas-upnp-org:device:DimmableRGBLight:1" or "urn:schemas-upnp-org:device:DimmableLight:1",
      d_xml = (color_hex or mireds) and "D_DimmableRGBLight1.xml" or "D_DimmableLight1.xml",
      variables = variables,
      subcategory = 1,
      coap_observer = nil
    }

    Config.GW_Devices[tradfri_id] = data
  end
end

local function createTradfriOutletDevice(payload)
  local tradfri_id = tostring(payload[GW.ATTR_ID])
  local tradfri_name = trafdri_get_name(GW.APPLICATION_TYPE.OUTLET, payload)

  if tradfri_id and tradfri_name then
    local device_attrs = payload[GW.ATTR_SWITCH_PLUG] or {{}}
    local device_state = device_attrs[1][GW.ATTR_DEVICE_STATE] or 0

    local data = {
      tradfri_id = tradfri_id,
      tradfri_appl_type = GW.APPLICATION_TYPE.OUTLET,
      tradfri_attr_group = GW.ATTR_SWITCH_PLUG,
      tradfri_name = tradfri_name,
      known_name = "",
      sid = GWSwitchPowerSID,
      device_type = "urn:schemas-upnp-org:device:BinaryLight:1",
      d_xml = "D_BinaryLight1.xml",
      variables = {
        "urn:upnp-org:serviceId:SwitchPower1,Status=" .. tostring(device_state),
        "urn:upnp-org:serviceId:SwitchPower1,Target=" .. tostring(device_state),
      },
      subcategory = 1,
      coap_observer = nil
    }

    Config.GW_Devices[tradfri_id] = data
  end
end

local function createTradfriMotionDevice(payload)
  log("Motion devices are not supported")
  return false
end

local function createTradfriBlindsDevice(payload)
  local tradfri_id = tostring(payload[GW.ATTR_ID])
  local tradfri_name = trafdri_get_name(GW.APPLICATION_TYPE.BLIND, payload)

  if tradfri_id and tradfri_name then
    local device_attrs = payload[GW.ATTR_BLINDS_CONTROL] or {{}}
    local position = tonumber(device_attrs[1][GW.ATTR_BLIND_CURRENT_POSITION]) or 0
    position = math.min(math.max(position, 0), 100)

    local data = {
      tradfri_id = tradfri_id,
      tradfri_appl_type = GW.APPLICATION_TYPE.BLIND,
      tradfri_attr_group = GW.ATTR_BLINDS_CONTROL,
      tradfri_name = tradfri_name,
      known_name = "",
      sid = GWBlindSID,
      device_type = "urn:schemas-micasaverde-com:device:WindowCovering:1",
      d_xml = "D_WindowCovering1.xml",
      variables = {
        "urn:upnp-org:serviceId:Dimming1,LoadLevelStatus=" .. tostring(position),
        "urn:upnp-org:serviceId:Dimming1,LoadLevelTarget=" .. tostring(position),
      },
      subcategory = 1,
      coap_observer = nil
    }

    Config.GW_Devices[tradfri_id] = data
  end
end

local function createTradfriSoundControllerDevice(payload)
  log("Sound Controller device are not supported")
  return false
end

local function createTradfriGroup(payload)
  local tradfri_id = tostring(payload[GW.ATTR_ID])
  local tradfri_name = trafdri_get_name(GW.ROOT_GROUPS, payload)

  if tradfri_id and tradfri_name then
    local device_state = payload[GW.ATTR_DEVICE_STATE] or 0
    local device_dimming = math.ceil(100 * (payload[GW.ATTR_LIGHT_DIMMER] or 0) / 254)
    local attr_group_members = payload[GW.ATTR_GROUP_MEMBERS] or {{} }
    local attr_hs_link = attr_group_members[GW.ATTR_HS_LINK] or {{} }
    local group_members = attr_hs_link[GW.ATTR_ID] or {}

    local data = {
      tradfri_id = tradfri_id,
      root_device = GW.ROOT_GROUPS,
      tradfri_appl_type = GW.APPLICATION_TYPE.LIGHT,
      tradfri_attr_group = GW.ATTR_LIGHT_CONTROL,
      tradfri_name = tradfri_name,
      known_name = "",
      sid = GWDimmingSID,
      device_type = "urn:schemas-upnp-org:device:DimmableRGBLight:1",
      d_xml = "D_DimmableRGBLight1.xml",
      variables = {
        "urn:upnp-org:serviceId:SwitchPower1,Status=" .. tostring(device_state),
        "urn:upnp-org:serviceId:SwitchPower1,Target=" .. tostring(device_state),
        "urn:upnp-org:serviceId:Dimming1,LoadLevelStatus=" .. tostring(device_dimming),
        "urn:upnp-org:serviceId:Dimming1,LoadLevelTarget=" .. tostring(device_dimming),
        "urn:micasaverde-com:serviceId:Color1,SupportedColors=",
        "urn:micasaverde-com:serviceId:HaDevice1,Children=" .. table.concat(group_members, ",")
      },
      members = group_members,
      subcategory = 1,
      coap_observer = nil
    }

    Config.GW_Devices[tradfri_id] = data
  end
end

function updateTradfriDeviceName(tradfri_id)
  local childId,_ = findChild(GWDeviceID, tradfri_id)
  local d = Config.GW_Devices[tradfri_id]
  if ((childId ~= nil) and (d ~= nil)) then
    local payload = {}
    payload[GW.ATTR_NAME] = d.known_name
    tradfriCommand(GW.METHOD_PUT, {d.root_device or GW.ROOT_DEVICES, tradfri_id}, payload)
  end
end

local function setTradfriDeviceAttrs(payload, lul_device)
  local tradfri_id = tostring(payload[GW.ATTR_ID])
  if tradfri_id then
    local appl_type = payload[GW.ATTR_APPLICATION_TYPE]
    local tradfri_name = trafdri_get_name(appl_type, payload)

    local d = Config.GW_Devices[tradfri_id]
    if (d ~= nil) then
      d.tradfri_name = tradfri_name
      if (d.known_name == "") or (d.known_name ~= d.tradfri_name) then
        d.known_name = d.tradfri_name
      else
        local luup_name = luup.attr_get("name", lul_device)
        if d.known_name ~= luup_name then
          d.known_name = luup_name

          -- Call action to start asynchronic name update job
          local args = {
            newName = luup_name
          }
          luup.call_action("urn:upnp-org:serviceId:tradfri-gw1", "SetDeviceName", args, lul_device)
        end
      end
      setLuupAttr("name", d.known_name, lul_device)
    end
  end

  local tradfri_device_info = payload[GW.ATTR_DEVICE_INFO] or {}
  local manufacturer = tradfri_device_info[GW.DEVICE_INFO.BRAND]
  if manufacturer then
    setLuupAttr("manufacturer", manufacturer, lul_device)
  end
  local model = tradfri_device_info[GW.DEVICE_INFO.NAME]
  if model then
    setLuupAttr("model", model, lul_device)
  end
end

local function setTradfriDeviceVars(payload, lul_device)
  local last_seen_time = payload[GW.ATTR_LAST_SEEN]
  if last_seen_time then
    setLuupVar("LastTimeCheck", last_seen_time, GWHaDeviceSID, lul_device)
  end

  local tradfri_device_info = payload[GW.ATTR_DEVICE_INFO] or {}
  local firmware_version = tradfri_device_info[GW.DEVICE_INFO.FIRMWARE_VERSION]
  if firmware_version then
    setLuupVar("Tradfri_Firmware_Version", firmware_version, GWDeviceSID, lul_device)
  end

  local power_source = tradfri_device_info[GW.DEVICE_INFO.POWER_SOURCES]
  -- GW.DEVICE_INFO.POWER_SOURCE.INTERNAL_BATTERY and GW.DEVICE_INFO.POWER_SOURCE.EXTERNAL_BATTERY are used for mains-connected outlet
  if power_source == GW.DEVICE_INFO.POWER_SOURCE.BATTERY then
    setLuupVar("BatteryLevel", tradfri_device_info[GW.DEVICE_INFO.BATTERY_LEVEL], GWHaDeviceSID, lul_device)
    if last_seen_time then
      setLuupVar("BatteryDate", last_seen_time, GWHaDeviceSID, lul_device)
    end
  end
end

local function calculateTradfriGroupStatus()
  if Config.GW_AddRooms then
    if not Config.GroupsUpdatePending then
      Config.GroupsUpdatePending = true
      luup.call_delay("calculateTradfriGroupStatus_internal", 1, "")
    end

    Config.GroupsUpdateTriggered = socket.gettime()*1000
  end
end

function calculateTradfriGroupStatus_internal()
  -- Verify that that last device update is at least 750ms ago
  if socket.gettime()*1000 - Config.GroupsUpdateTriggered > 750 then
    for _, d in pairs(Config.GW_Devices) do
      if d.root_device == GW.ROOT_GROUPS then
        if d.luup_id ~= nil then
          local device_state = nil
          local device_dimming = nil
          local dimming_devices = 0

          for _, child_id in pairs(d.members) do
            local child = Config.GW_Devices[tostring(child_id)]
            if child ~= nil then
              if child.luup_id ~= nil then
                device_state = device_state or getLuupVar("Status", GWSwitchPowerSID, child.luup_id) == "1"
                local dimming = getLuupVar("LoadLevelStatus", GWDimmingSID, child.luup_id)
                if dimming ~= nil then
                  device_dimming = device_dimming or 0 + dimming
                  dimming_devices = dimming_devices + 1
                end
              end
            end
          end

          if device_dimming ~= nil then
            setLuupVar("LoadLevelTarget", math.floor(device_dimming / dimming_devices), GWDimmingSID, d.luup_id)
            setLuupVar("LoadLevelStatus", math.floor(device_dimming / dimming_devices), GWDimmingSID, d.luup_id)
          end
          if device_state ~= nil then
            setLuupVar("Target", device_state and 1 or 0, GWSwitchPowerSID, d.luup_id)
            setLuupVar("Status", device_state and 1 or 0, GWSwitchPowerSID, d.luup_id)
          end
        end
      end
    end

    Config.GroupsUpdatePending = false
  else
    -- Reschedule execution of the status update calculation
    luup.call_delay("calculateTradfriGroupStatus_internal", 1, "")
  end
end

local function updateTradfriGroup(payload, lul_device)
  local tradfri_id = tostring(payload[GW.ATTR_ID])
  local d = Config.GW_Devices[tradfri_id]
  if tradfri_id and d ~= nil then
    local attr_group_members = payload[GW.ATTR_GROUP_MEMBERS] or {{} }
    local attr_hs_link = attr_group_members[GW.ATTR_HS_LINK] or {{} }
    local group_members = attr_hs_link[GW.ATTR_ID] or {}
    d.members = group_members

    local changed = setLuupVar("Children", table.concat(group_members, ","), "urn:micasaverde-com:serviceId:HaDevice1", lul_device)

    -- The following attributes are valid for the Tradfri Group objects.
    -- The values however are not properly updated for the devices in the group
    -- and the dimming value is zero in all cases.
    -- The group status therefore is aggregated and updated upon device state change in calculateTradfriGroupStatus
    --
    -- local device_state = payload[GW.ATTR_DEVICE_STATE] or 0
    -- local device_dimming = math.ceil(100 * (payload[GW.ATTR_LIGHT_DIMMER] or 0) / 254)
    -- if setLuupVar("LoadLevelTarget", device_dimming, GWDimmingSID, lul_device) then changed = true end
    -- if setLuupVar("LoadLevelStatus", device_dimming, GWDimmingSID, lul_device) then changed = true end
    -- if setLuupVar("Target", device_state, GWSwitchPowerSID, lul_device) then changed = true end
    -- if setLuupVar("Status", device_state, GWSwitchPowerSID, lul_device) then changed = true end

    if changed then
      calculateTradfriGroupStatus()
    end
  end

  setTradfriDeviceVars(payload, lul_device)
  setTradfriDeviceAttrs(payload, lul_device)
end

local function updateTradfriLightDevice(payload, lul_device)
  local device_attrs = payload[GW.ATTR_LIGHT_CONTROL] or {{}}
  local device_state = device_attrs[1][GW.ATTR_DEVICE_STATE] or 0
  local device_dimming = math.ceil(100 * (device_attrs[1][GW.ATTR_LIGHT_DIMMER] or 0) / 254)

  local changed = false
  if setLuupVar("LoadLevelStatus", device_dimming, GWDimmingSID, lul_device) then changed = true end
  if setLuupVar("LoadLevelTarget", device_dimming, GWDimmingSID, lul_device) then changed = true end
  if setLuupVar("Status", device_state, GWSwitchPowerSID, lul_device) then changed = true end
  if setLuupVar("Target", device_state, GWSwitchPowerSID, lul_device) then changed = true end

  local mireds = device_attrs[1][GW.ATTR_LIGHT_MIREDS]
  local color_hex = device_attrs[1][GW.ATTR_LIGHT_COLOR_HEX]

  if mireds ~= nil then
    local w, d = 0, 0
    -- Source: https://nl.wikipedia.org/wiki/Mired
    -- Convert Mired to Kelvin
    local kelvin = math.floor(1000000/mireds)
    if kelvin < 5450 then
      w = (math.floor((kelvin-2000) / (3500/255)) + 1) or 0
    else
      d = (math.floor((kelvin-5500) / (3500/255)) + 1) or 0
    end

    if setLuupVar("CurrentColor", string.format("0=%d,1=%d", w, d), GWColorSID, lul_device) then changed = true end
    if setLuupVar("TargetColor", string.format("0=%d,1=%d", w, d), GWColorSID, lul_device) then changed = true end
  elseif color_hex ~= nil then
    local w, d, r, g, b = 0, 0, 255, 255, 255
    r = tonumber(string.sub("f1e0b5", -6, -5), 16) or 0
    g = tonumber(string.sub("f1e0b5", -4, -3), 16) or 0
    b = tonumber(string.sub("f1e0b5", -2), 16) or 0
    if setLuupVar("CurrentColor", string.format("0=%d,1=%d,2=%d,3=%d,4=%d", w, d, r, g, b), GWColorSID, lul_device) then changed = true end
    if setLuupVar("TargetColor", string.format("0=%d,1=%d,2=%d,3=%d,4=%d", w, d, r, g, b), GWColorSID, lul_device) then changed = true end

    -- local supported_colors = {}
    -- for hex,_ in pairs(GW.LIGHT_COLORS) do
    --   supported_colors[#supported_colors + 1] = "#" .. hex
    -- end
    -- setLuupVar("SupportedColors", table.concat(supported_colors, ","), GWColorSID, lul_device)
  end

  if changed then
    calculateTradfriGroupStatus()
  end

  setTradfriDeviceVars(payload, lul_device)
  setTradfriDeviceAttrs(payload, lul_device)
end

local function updateTradfriOutletDevice(payload, lul_device)
  local device_attrs = payload[GW.ATTR_SWITCH_PLUG] or {{}}
  local device_state = tostring(device_attrs[1][GW.ATTR_DEVICE_STATE] or 0)
  local changed = false

  if setLuupVar("Status", device_state, GWSwitchPowerSID, lul_device) then changed = true end
  if setLuupVar("Target", device_state, GWSwitchPowerSID, lul_device) then changed = true end

  if changed then
    calculateTradfriGroupStatus()
  end

  setTradfriDeviceVars(payload, lul_device)
  setTradfriDeviceAttrs(payload, lul_device)
end

local function updateTradfriBlindsDevice(payload, lul_device)
  local device_attrs = payload[GW.ATTR_BLINDS_CONTROL] or {{}}
  local position = tonumber(device_attrs[1][GW.ATTR_BLIND_CURRENT_POSITION]) or 0
  position = math.min(math.max(position, 0), 100)
  local changed = false

  if setLuupVar("LoadLevelStatus", position, GWDimmingSID, lul_device) then changed = true end
  if setLuupVar("LoadLevelTarget", position, GWDimmingSID, lul_device) then changed = true end

  if changed then
    calculateTradfriGroupStatus()
  end

  setTradfriDeviceVars(payload, lul_device)
  setTradfriDeviceAttrs(payload, lul_device)
end

function tradfriStartObserveDevice(tradfri_id)
  local d = Config.GW_Devices[tradfri_id]
  if tradfri_id and d ~= nil then
    d.coap_observer = tradfriCommand(GW.METHOD_OBSERVE, {d.root_device or GW.ROOT_DEVICES, tradfri_id})
    if (d.coap_observer ~= nil) and (d.coap_observer.listener ~= nil) then
      local ok, err = pcall(function() d.coap_observer.listener:listen() end)
      if not ok then
        log(string.format("CoAP observer listen call failed for device %s: %s", tradfri_id, err or "<unknown CoAP result"))
      end
    end
  end
end

local function tradfriStopObserveDevice(tradfri_id)
  local d = Config.GW_Devices[tradfri_id]
  if tradfri_id and d ~= nil then
    if (d.coap_observer ~= nil) and (d.coap_observer.listener ~= nil) then
      pcall(function() d.coap_observer.listener:stop() end)
      d.coap_observer.listener = nil
      d.coap_observer.client = nil
    end
    d.coap_observer = nil
  end
end

function _tradfriPollDevicesInternalCo()
  if Config.PollCoroutine ~= nil then
    if coroutine.resume(Config.PollCoroutine) then
      luup.call_delay("_tradfriPollDevicesInternalCo", 0, "")
    else
      Config.PollCoroutine = nil
    end
  end
end

function tradfriPollDevices()
  if Config.GW_ObserveMode == 0 then
    if Config.GW_PollInterval > 0 then
      luup.call_delay("tradfriPollDevices", Config.GW_PollInterval, "")
    end

    if Config.PollCoroutine == nil then
      Config.PollCoroutine = coroutine.create(function()
        for _, d in pairs(Config.GW_Devices) do
          tradfriCommand(GW.METHOD_GET, {d.root_device or GW.ROOT_DEVICES, d.tradfri_id})
          coroutine.yield()
        end
      end)
      luup.call_delay("_tradfriPollDevicesInternalCo", 0, "")
    end
  end
end

local function tradfriStartStopObservations()
  local cnt = 1
  for k, d in pairs(Config.GW_Devices) do
    if Config.GW_ObserveMode == 1 then
      local observeDelay = cnt
      debug(string.format("Start observing tradfri device %s in %d seconds", d.tradfri_id, observeDelay))
      luup.call_delay("tradfriStartObserveDevice", observeDelay, d.tradfri_id)

      cnt = cnt + 1
    else
      tradfriStopObserveDevice(d.tradfri_id)
    end
  end

  if Config.GW_ObserveMode == 0 then
    luup.call_delay("tradfriPollDevices", 3, "")
  end
end

local function createOrUpdateTradfriDevice(payload)
  local success = true
  local tradfri_id = tostring(payload[GW.ATTR_ID])
  local d = Config.GW_Devices[tradfri_id]
  if tradfri_id and d ~= nil then
    local childId,_ = findChild(GWDeviceID, d.tradfri_id)
    if (childId ~= nil) then
      success = true
      local device_attrs = payload[d.tradfri_attr_group] or {{}}
      if d.tradfri_appl_type == GW.APPLICATION_TYPE.LIGHT then
        updateTradfriLightDevice(payload, childId)
      elseif d.tradfri_appl_type == GW.APPLICATION_TYPE.OUTLET then
        updateTradfriOutletDevice(payload, childId)
      elseif d.tradfri_appl_type == GW.APPLICATION_TYPE.BLIND then
        updateTradfriBlindsDevice(payload, childId)
      else
        log(string.format("Unknown application type received: %s", tostring(d.tradfri_appl_type) or "null"))
        success = false
      end
    end
  else
    success = true
    local appl_type = payload[GW.ATTR_APPLICATION_TYPE]
    if appl_type == GW.APPLICATION_TYPE.REMOTE then
      createTradfriRemoteDevice(payload)
    elseif appl_type == GW.APPLICATION_TYPE.LIGHT then
      createTradfriLightDevice(payload)
    elseif appl_type == GW.APPLICATION_TYPE.OUTLET then
      createTradfriOutletDevice(payload)
    elseif appl_type == GW.APPLICATION_TYPE.MOTION then
      createTradfriMotionDevice(payload)
    elseif appl_type == GW.APPLICATION_TYPE.BLIND then
      createTradfriBlindsDevice(payload)
    elseif appl_type == GW.APPLICATION_TYPE.SOUND_CONTROLLER then
      createTradfriSoundControllerDevice(payload)
    else
      log(string.format("Unknown device type received: %s", tostring(appl_type) or "null"))
      success = false
    end
  end

  return success
end

local function createOrUpdateTradfriGroup(payload)
  local tradfri_id = tostring(payload[GW.ATTR_ID])
  local d = Config.GW_Devices[tradfri_id]
  if tradfri_id and d ~= nil then
    local childId,_ = findChild(GWDeviceID, d.tradfri_id)
    if (childId ~= nil) then
      updateTradfriGroup(payload, childId)
    end
  else
    createTradfriGroup(payload)
  end
end

function tradfriDevicesObserveCallback(root_device, payload_str)
  debug("tradfri Devices Observe Callback " .. payload_str)
  local payload, pos, err = json.decode(payload_str)
  if err then
    log(string.format("Parsing observed device data '%s' failed at %d with error: %s", payload_str, pos, err or "<Unknown>"))
    return
  end

  if not createOrUpdateTradfriDevice(payload) then
    log(string.format("Creating or updating device failed: %s", payload_str))
  end
end

function tradfriDevicesCallback(root_device, payload_str)
  debug("tradfri Devices Callback " .. payload_str)
  local payload, pos, err = json.decode(payload_str)
  if err then
    log(string.format("Parsing device data '%s' failed at %d with error: %s", payload_str, pos, err or "<Unknown>"))
    return
  end

  if is_array(payload) then
    -- Devicelist received, query all individual devices
    for _, v in pairs(payload) do
      tradfriCommand(GW.METHOD_GET, {root_device, v})
    end
  else
    if root_device == GW.ROOT_DEVICES then
      if not createOrUpdateTradfriDevice(payload) then
        log(string.format("Creating or updating device failed: %s", payload_str))
      end
    elseif root_device == GW.ROOT_GROUPS then
      createOrUpdateTradfriGroup(payload)
    end
  end
end

function tradfriGatewayCallback(payload_str)
  debug("tradfri Gateway Callback " .. payload_str)
  local payload, pos, err = json.decode(payload_str)
  if err then
    log(string.format("Parsing gateway data '%s' failed at %d with error: %s", payload_str, pos, err or "<Unknown>"))
    return
  end

  setLuupVar("Connected", 1)
  for k, v in pairs(payload) do
    if k == GW.ATTR_PSK then
      Config.GW_Psk = v
      setLuupVar("Psk", v)
    elseif k == GW.ATTR_COMMISSIONING_MODE then
      setLuupVar("Tradfri_Commissioning_Mode", v)
    end
  end

  -- Set common attributes and variables
  setTradfriDeviceAttrs(payload, GWDeviceID)
  setTradfriDeviceVars(payload, GWDeviceID)
end

function deviceVariableUpdate(lul_device, lul_service, lul_variable, lul_value_old, lul_value_new)
  if GWDeviceID == lul_device then
    if lul_variable == "Debug" then
      SetDebugMode(lul_device, lul_value_new)
    elseif lul_variable == "ObserveMode" then
      SetObserveMode(lul_device, lul_value_new)
    elseif lul_variable == "PollInterval" then
      Config.GW_PollInterval = tonumber(lul_value_new) or Config.GW_PollInterval
    end
  end
end

local function syncLuupDevices()
  local cnt = 0
  for _ in pairs(Config.GW_Devices) do
    cnt = cnt + 1
  end

  if cnt > 0 then
    local child_devices = luup.chdev.start(GWDeviceID)
    for _, d in pairs(Config.GW_Devices) do
      luup.chdev.append(
        GWDeviceID,
        child_devices,
        d.tradfri_id,                     -- child id (is altid)
        d.tradfri_name,                   -- child device description
        d.device_type,                    -- child device type
        d.d_xml,                          -- child D-xml file
        "",                               -- child I-xml file
        table.concat(d.variables, "\n"),  -- child variables
        false,                            -- not embedded, child is standalone device
        false                             -- invisible
      )
    end

    luup.chdev.sync(GWDeviceID, child_devices)

    for k, d in pairs(Config.GW_Devices) do
      local childId,_ = findChild(GWDeviceID, d.tradfri_id)
      if (childId ~= nil) then
          d.luup_id = childId
          setLuupAttr("subcategory_num", d.subcategory or 0, childId)
      end
    end
  end
end

function initTradfri()
  local initDelay = 10 + math.random(10)  -- Start initialization after 10 .. 20 seconds

  if (is_empty(Config.GW_Identity)) or (is_empty(Config.GW_Psk)) then
      -- Obtain Identity/Psk
      local securityCode = getDeviceVar("SecurityCode")

      if (not is_empty(securityCode)) then
        if (is_empty(Config.GW_Identity)) then
          Config.GW_Identity = string.format("Vera-%s-%s", luup.pk_accesspoint, GWDeviceID)
          setLuupVar("Identity", Config.GW_Identity)
        end

        log("Attempt to create an identity for " .. Config.GW_Identity)

        local payload = {}
        payload[GW.ATTR_CLIENT_IDENTITY_PROPOSED] = Config.GW_Identity
        tradfriCommand(GW.METHOD_POST, {GW.ROOT_GATEWAY, GW.ATTR_AUTH}, payload, "Client_identity", securityCode)
      else
        log("Unable to create an authentication entity for Tradfri plugin. Set the SecurityCode attribute.")
      end

      luup.call_delay("initTradfri", initDelay, "")  -- Try again or continue initialization
  else
    -- Clear SecurityCode when an Identity/Psk is available
    setLuupVar("SecurityCode", "")

    -- Load gateway information
    tradfriCommand(GW.METHOD_GET, {GW.ROOT_GATEWAY, GW.ATTR_GATEWAY_INFO})
    -- Load devices
    tradfriCommand(GW.METHOD_GET, {GW.ROOT_DEVICES})

    if Config.GW_AddRooms then
      -- Load Rooms
      tradfriCommand(GW.METHOD_GET, {GW.ROOT_GROUPS})
    end

    syncLuupDevices()
    tradfriStartStopObservations()
  end
end

-- init() called on startup as specified in I_TradfriGW.xml
function init(lul_device)
  GWDeviceID = lul_device

  log(string.format("Starting up device %s with ID %s", GWDeviceID, luup.devices[GWDeviceID].id))
  setLuupVar("Connected", 0)
  setLuupVar("Version", ABOUT.VERSION)

  Config.GW_Ip                 = luup.devices[GWDeviceID].ip
  Config.GW_Port               = tonumber(getDeviceVar("Port", Config.GW_Port, 1025, 65535))
  Config.GW_Identity           = getLuupVar("Identity")
  Config.GW_Psk                = getDeviceVar("Psk", "")
  Config.GW_DebugMode          = getDeviceVar("Debug", 0) == "1"
  Config.GW_ObserveMode        = tonumber(getDeviceVar("ObserveMode", Config.GW_ObserveMode))
  Config.GW_PollInterval       = tonumber(getDeviceVar("PollInterval", Config.GW_PollInterval))
  Config.GW_AddRooms           = getDeviceVar("AddRooms", 0) == "1"
  getDeviceVar("SecurityCode")  -- Make sure the variable is created

  luup.variable_watch("deviceVariableUpdate", GWDeviceSID, nil, GWDeviceID)

  local ok = false
  local message = ""

  if (not is_empty(Config.GW_Ip)) and (not is_empty(Config.GW_Port)) then
    local initDelay = 5 + math.random(10)
    luup.call_delay("initTradfri", initDelay, "")

    ok = true
    message = string.format("Connecting to Tradfri gateway in %d seconds.", initDelay)
  else
    message = "Unable to start the Tradfri plugin. Set the IP(address) attribute and reload Luup."
  end

  log(message)
  return ok, message, ABOUT.NAME
end


------------------------------------------------------------------------------------
-- Implementation UPnP actions
------------------------------------------------------------------------------------

-- ServiceId: urn:upnp-org:serviceId:tradfri-gw1
-- Action: Reboot
function Reboot(lul_device)
  if GWDeviceID == lul_device then
    tradfriCommand(GW.METHOD_POST, {GW.ROOT_GATEWAY, GW.ATTR_GATEWAY_REBOOT})
  end
end

-- ServiceId: urn:upnp-org:serviceId:tradfri-gw1
-- Action: FactoryReset
function FactoryReset(lul_device)
  if GWDeviceID == lul_device then
    tradfriCommand(GW.METHOD_POST, {GW.ROOT_GATEWAY, GW.ATTR_GATEWAY_FACTORY_DEFAULTS})
  end
end

-- ServiceId: urn:upnp-org:serviceId:tradfri-gw1
-- Action: SetCommissioningMode
function SetCommissioningMode(lul_device, CommissioningTimeout)
  if GWDeviceID == lul_device then
    local payload = {}
    payload[GW.ATTR_COMMISSIONING_MODE] = tonumber(CommissioningTimeout) or 60
    tradfriCommand(GW.METHOD_PUT, {GW.ROOT_GATEWAY, GW.ATTR_GATEWAY_INFO}, payload)
  end
end

-- ServiceId: urn:upnp-org:serviceId:tradfri-gw1
-- Action: SetDebugMode
function SetAddRooms(lul_device, newAddRooms)
  if GWDeviceID == lul_device then
    local addRooms = tonumber(newAddRooms) or 0

    if (addRooms == 1) then
	    Config.GW_AddRooms = true
    else
	    Config.GW_AddRooms = false
    end
    setLuupVar("AddRooms", addRooms)
  end
end

-- ServiceId: urn:upnp-org:serviceId:tradfri-gw1
-- Action: SetObserveMode
function SetObserveMode(lul_device, newObserveMode)
  if GWDeviceID == lul_device then
    local observeMode = tonumber(newObserveMode) or 0

    Config.GW_ObserveMode = observeMode
    setLuupVar("ObserveMode", observeMode)
    tradfriStartStopObservations()
  end
end

-- ServiceId: urn:upnp-org:serviceId:tradfri-gw1
-- Action: SetDebugMode
function SetDebugMode(lul_device, newDebugMode)
  if GWDeviceID == lul_device then
    local debugMode = tonumber(newDebugMode) or 0

    if (debugMode == 1) then
	    Config.GW_DebugMode = true
    else
	    Config.GW_DebugMode = false
    end
    setLuupVar("Debug", debugMode)
  end
end

-- ServiceId: urn:upnp-org:serviceId:tradfri-gw1
-- Action: SetDeviceName
function SetDeviceName(lul_device, newName)
  if luup.devices[lul_device] then
    local tradfri_id = luup.devices[lul_device].id
    if tradfri_id and newName then
      local d = Config.GW_Devices[tradfri_id]
      if (d ~= nil) then
        d.tradfri_name = newName
      end
      setLuupAttr("name", d.known_name, lul_device)
    end
  else
    log(string.format("Error setting name, device %s is not available.", tostring(lul_device)))
  end
end

-- ServiceId: urn:upnp-org:serviceId:SwitchPower1
-- Action: SetTarget
function SwitchPower_SetTarget(lul_device, newTargetValue)
  newTargetValue = tonumber(newTargetValue) or 0

  if luup.devices[lul_device] then
    local tradfri_id = luup.devices[lul_device].id
    local d = Config.GW_Devices[tradfri_id]
    if tradfri_id and d ~= nil and d.tradfri_attr_group then
      local attrs = {}
      attrs[GW.ATTR_DEVICE_STATE] = newTargetValue
      local payload = {}
      if d.root_device == GW.ROOT_GROUPS then
        payload = attrs
        updateTradfriGroup(payload, lul_device)
      else
        payload[d.tradfri_attr_group] = {attrs}
        updateTradfriOutletDevice(payload, lul_device)
      end
      tradfriCommand(GW.METHOD_PUT, {d.root_device or GW.ROOT_DEVICES, tradfri_id}, payload)
    end
  else
    log(string.format("Error setting SwitchPower target, device %s is not available.", tostring(lul_device)))
  end
end

-- ServiceId: urn:upnp-org:serviceId:Dimming1
-- Action: SetLoadLevelTarget
function Dimming_SetLoadLevelTarget(lul_device, newLoadlevelTarget)
  newLoadlevelTarget = tonumber(newLoadlevelTarget) or 0
  newLoadlevelTarget = math.min(math.max(newLoadlevelTarget, 0), 100)

  local tradfri_id = luup.devices[lul_device].id
  local d = Config.GW_Devices[tradfri_id]
  if tradfri_id and d then
    local tradfri_attr_group = d.tradfri_attr_group
    if tradfri_attr_group == GW.ATTR_LIGHT_CONTROL then
      local attrs = {}
      attrs[GW.ATTR_DEVICE_STATE] = (newLoadlevelTarget ~= 0) and 1 or 0
      attrs[GW.ATTR_LIGHT_DIMMER] = math.floor(254*newLoadlevelTarget/100)
      local payload = {}
      if d.root_device == GW.ROOT_GROUPS then
        payload = attrs
        updateTradfriGroup(payload, lul_device)
      else
        payload[tradfri_attr_group] = {attrs}
        updateTradfriLightDevice(payload, lul_device)
      end
      tradfriCommand(GW.METHOD_PUT, {d.root_device or GW.ROOT_DEVICES, tradfri_id}, payload)
    elseif tradfri_attr_group == GW.ATTR_BLINDS_CONTROL then
      local attrs = {}
      attrs[GW.ATTR_BLIND_CURRENT_POSITION] = newLoadlevelTarget
      local payload = {}
      payload[tradfri_attr_group] = {attrs}
      tradfriCommand(GW.METHOD_PUT, {d.root_device or GW.ROOT_DEVICES, tradfri_id}, payload)
      updateTradfriBlindsDevice(payload, lul_device)
    else
      log(string.format("SetLoadLevelTarget not supported for attribute %s for tradfri device %s", tradfri_attr_group, tradfri_id))
    end
  end
end

-- ServiceId: urn:upnp-org:serviceId:HaDevice1
-- Action: ToggleState
function HaDevice_ToggleState(lul_device)
  if luup.devices[lul_device] then
    local tradfri_id = luup.devices[lul_device].id
    local d = Config.GW_Devices[tradfri_id]
    local tradfri_attr_group = d.tradfri_attr_group
    if tradfri_id and d and tradfri_attr_group then
      if tradfri_attr_group == GW.ATTR_LIGHT_CONTROL or tradfri_attr_group == GW.ATTR_SWITCH_PLUG then
        local device_state = getLuupVar("Status", GWSwitchPowerSID, d.luup_id) == "1"
        local attrs = {}
        attrs[GW.ATTR_DEVICE_STATE] = device_state and 0 or 1
        local payload = {}
        if d.root_device == GW.ROOT_GROUPS then
          payload = attrs
          updateTradfriGroup(payload, lul_device)
        else
          payload[tradfri_attr_group] = {attrs}
          updateTradfriOutletDevice(payload, lul_device)
        end
        tradfriCommand(GW.METHOD_PUT, {d.root_device or GW.ROOT_DEVICES, tradfri_id}, payload)
      else
        log(string.format("ToggleState not supported for attribute %s for tradfri device %s", tradfri_attr_group, tradfri_id))
      end
    end
  else
    log(string.format("Error toggling state for HaDevice target, device %s is not available.", tostring(lul_device)))
  end
end

-- ServiceId: urn:upnp-org:serviceId:Color1
-- Action: SetColorRGB
function Color_SetColorRGB(lul_device, newColorRGBTarget)
  log(string.format("TODO Color_SetColorRGB: newColorRGBTarget %s for device %d", newColorRGBTarget, lul_device))
end

-- ServiceId: urn:upnp-org:serviceId:Color1
-- Action: SetColor
-- Sets color temperature
-- Warm White: Wx
-- Cool White: Dx
-- W0     <--> W255  =  D0     <--> D255
-- 2000K <--> 5500K = 5500K <--> 9000K
-- mired range: 250 - 454  -- 2200 - 4000  Kelvin
function Color_SetColor(lul_device, newColorTarget)
  local colortemp_mode = string.sub(newColorTarget, 1, 1)
	local value = tonumber(string.sub(newColorTarget, 2))
	local kelvin = 0
  if colortemp_mode == "W" then
    kelvin = 2000 + math.floor((value * 3500/255))
  elseif colortemp_mode == "D" then
    kelvin = 5500 + math.floor((value * 3500/255))
  end

  if kelvin > 0 then
	  local mireds = math.floor(1000000/kelvin)
    mireds = math.max(mireds, GW.ATTR_LIGHT_MIRED_RANGE[1])
    mireds = math.min(mireds, GW.ATTR_LIGHT_MIRED_RANGE[2])

    local tradfri_id = luup.devices[lul_device].id
    local d = Config.GW_Devices[tradfri_id]
    local tradfri_attr_group = d.tradfri_attr_group
    if tradfri_id and d and tradfri_attr_group then
      local attrs = {}
      attrs[GW.ATTR_LIGHT_MIREDS] = mireds
      local payload = {}
      payload[tradfri_attr_group] = {attrs}
      tradfriCommand(GW.METHOD_PUT, {d.root_device or GW.ROOT_DEVICES, tradfri_id}, payload)
      updateTradfriLightDevice(payload, lul_device)
    end
  end
end

-- ServiceId: urn:upnp-org:serviceId:SecuritySensor1
-- Action: SetArmed
function SecuritySensor_SetArmed(lul_device, newArmedValue)
  log(string.format("TODO SecuritySensor_SetArmed: newArmedValue %s for device %d", newArmedValue, lul_device))
end
