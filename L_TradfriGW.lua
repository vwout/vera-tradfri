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

------------------------------------------------------------------------------------
-- Tradfri constants
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

GW.ATTR_START_BLINDS = "15015"

GW.ATTR_ALEXA_PAIR_STATUS = "9093"
GW.ATTR_AUTH = "9063"
GW.ATTR_APPLICATION_TYPE = "5750"
GW.ATTR_APPLICATION_TYPE_BLIND = 7

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
GW.ATTR_LIGHT_DIMMER = "5851"  -- Dimmer, not following spec: 0..255
GW.ATTR_LIGHT_COLOR_HEX = "5706"  -- string representing a value in hex
GW.ATTR_LIGHT_COLOR_X = "5709"
GW.ATTR_LIGHT_COLOR_Y = "5710"
GW.ATTR_LIGHT_COLOR_HUE = "5707"
GW.ATTR_LIGHT_COLOR_SATURATION = "5708"
GW.ATTR_LIGHT_MIREDS = "5711"

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


------------------------------------------------------------------------------------
-- Utility functions
------------------------------------------------------------------------------------

local function log(message)
  luup.log("TradfriGW #" .. GWDeviceID .. ": " .. (message or ""))
end

local function is_empty(s)
  return (s == nil) or (s == "")
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

  if value ~= nil then value = tostring(value) else value = "" end
  if value ~= oldvalue then  -- default or limits may have modified value
    setLuupVar(name, value, service, device)
  end
	return value
end

function tradfriCallback(payload_str)
  log("DEBUG: tradfriCallback " .. payload_str)

  setLuupVar("Connected", 1)
  local payload = json.decode(payload_str)

  for k, v in pairs(payload) do
    if k == GW.ATTR_FIRMWARE_VERSION then
      setLuupVar("Tradfri_Firmare_Version", v)
    elseif k == GW.ATTR_PSK then
      Config.GW_Psk = v
      setLuupVar("Psk", v)
    elseif k == GW.ATTR_COMMISSIONING_MODE then
      setLuupVar("Tradfri_Commissioning_Mode", v)
    end
  end
end

function tradfriCommand(method, path, payload, identity, psk)
  identity = identity or Config.GW_Identity
  psk = psk or Config.GW_Psk

  local coapResult
  local coapClient = coap.Client()
  local path_str = table.concat(path, "/")
  local url = string.format("coaps://%s:%s@%s:%d/%s", identity, psk, Config.GW_Ip, Config.GW_Port, path_str)

  if method == GW.METHOD_GET then
    log("GET => " .. path_str)
    coapResult = coapClient:get(coap.CON, url, tradfriCallback)
  elseif method == GW.METHOD_POST then
    local payload_str = payload
    if type(payload) == 'table' then
      payload_str = json.encode(payload)
    end

    log("POST " .. payload_str .. " => " .. path_str)
    coapResult = coapClient:post(coap.CON, url, 0, payload_str, tradfriCallback)
  elseif method == GW.METHOD_PUT then
    --TODO
    log("TODO put " .. path_str)
  elseif method == GW.METHOD_OBSERVE then
    --TODO
    log("TODO observe " .. path_str)
  else
    log("Unable to process command, method '" .. method .. "' is unknown")
  end

  if coapResult ~= nil then
    log(string.format("CoAP call to gateway failed with error: %d", coapResult))
  end
end

function initTradfri()
  local initDelay = 10 + math.random(10)  -- Start initialization after 10 .. 20 seconds

  if (is_empty(Config.GW_Identity)) or (is_empty(Config.GW_Psk)) then
      -- Obtain Identity/Psk
      local securityCode = getDeviceVar("SecurityCode")

      if (not is_empty(securityCode)) then
        if (is_empty(Config.GW_Identity)) then
          Config.GW_Identity = string.format("Vera-%s", luup.pk_accesspoint)
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
    -- Load gateway information
    tradfriCommand(GW.METHOD_GET, {GW.ROOT_GATEWAY, GW.ATTR_GATEWAY_INFO})
    -- TODO: Load devices
    tradfriCommand(GW.METHOD_GET, {GW.ROOT_DEVICES})
  end
end


-- init() called on startup as specified in I_TradfriGW.xml
function init(lul_device)
  GWDeviceID = lul_device

  log("Starting up with ID " .. luup.devices[GWDeviceID].id)
  setLuupVar("Connected", 0)

  Config.GW_Ip                 = luup.devices[GWDeviceID].ip
  Config.GW_Port               = tonumber(getDeviceVar("Port", Config.GW_Port, 1025, 65535))
  Config.GW_Identity           = getLuupVar("Identity")
  Config.GW_Psk                = getLuupVar("Psk")
  getDeviceVar("SecurityCode")  -- Make sure the variable is created

  if (not is_empty(Config.GW_Ip)) and (not is_empty(Config.GW_Port)) then
    luup.call_delay("initTradfri", 10 + math.random(10), "")
  else
    log("Unable to start the Tradfri plugin. Set the IP(address) attribute.")
  end
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
function SetCommissioningMode(lul_device, timeout)
  if GWDeviceID == lul_device then
    local payload = {}
    payload[GW.ATTR_COMMISSIONING_MODE] = timeout
    tradfriCommand(GW.METHOD_PUT, {GW.ROOT_GATEWAY, GW.ATTR_GATEWAY_INFO}, payload)
  end
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
