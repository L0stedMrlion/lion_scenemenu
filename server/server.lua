local config = require 'config'

local activeZones = {}
local zoneCounter = 0

local function hasPermission(source)
    local hasESX, ESX = pcall(function() return exports['es_extended']:getSharedObject() end)
    if hasESX and ESX then
        local xPlayer = ESX.GetPlayerFromId(source)
        if xPlayer and xPlayer.job then
            for i = 1, #config.scenemenu.allowedJobs do
                if config.scenemenu.allowedJobs[i] == xPlayer.job.name then
                    return true
                end
            end
        end
    end

    return false
end

local function getPlayerICName(source)
    local hasESX, ESX = pcall(function() return exports['es_extended']:getSharedObject() end)
    if hasESX and ESX then
        local xPlayer = ESX.GetPlayerFromId(source)
        if xPlayer then
            if xPlayer.getName then
                return xPlayer.getName()
            elseif xPlayer.variables and xPlayer.variables.firstName then
                return xPlayer.variables.firstName .. " " .. xPlayer.variables.lastName
            end
        end
    end
    return GetPlayerName(source) or "Unknown"
end

local function hasSupervisorPermission(source)
    local hasESX, ESX = pcall(function() return exports['es_extended']:getSharedObject() end)
    if hasESX and ESX then
        local xPlayer = ESX.GetPlayerFromId(source)
        if xPlayer and xPlayer.job then
            local jobName = xPlayer.job.name
            local grade = xPlayer.job.grade
            local requiredGrade = config.scenemenu.supervisorGrades[jobName]
            if requiredGrade and grade >= requiredGrade then
                return true
            end
        end
    end
    return false
end

lib.callback.register('lion_scenemenu:server:checkScenePermission', function(source)
    return hasPermission(source)
end)

lib.callback.register('lion_scenemenu:server:checkSupervisorPermission', function(source)
    return hasSupervisorPermission(source)
end)

RegisterNetEvent('lion_scenemenu:server:requestSpeedZones', function()
    local src = source
    TriggerClientEvent('lion_scenemenu:client:syncSpeedZones', src, activeZones)
end)

RegisterNetEvent('lion_scenemenu:server:createSpeedZone', function(coords, radius, speed)
    local src = source
    if not hasPermission(src) then return end

    zoneCounter = zoneCounter + 1
    local zoneId = zoneCounter
    local creatorName = getPlayerICName(src)

    activeZones[zoneId] = {
        id = zoneId,
        coords = coords,
        radius = radius,
        speed = speed,
        creatorSource = src,
        creatorName = creatorName
    }

    TriggerClientEvent('lion_scenemenu:client:createSpeedZone', -1, zoneId, coords, radius, speed, src, creatorName)
end)

RegisterNetEvent('lion_scenemenu:server:removeSpeedZone', function(zoneId)
    local src = source
    if not hasPermission(src) then return end

    local zone = activeZones[zoneId]
    if zone then
        if zone.creatorSource == src or hasSupervisorPermission(src) then
            activeZones[zoneId] = nil
            TriggerClientEvent('lion_scenemenu:client:removeSpeedZone', -1, zoneId)
        end
    end
end)

RegisterNetEvent('lion_scenemenu:server:clearMySpeedZones', function()
    local src = source
    if not hasPermission(src) then return end

    local toRemove = {}
    for zoneId, zone in pairs(activeZones) do
        if zone.creatorSource == src then
            table.insert(toRemove, zoneId)
        end
    end

    for _, zoneId in ipairs(toRemove) do
        activeZones[zoneId] = nil
        TriggerClientEvent('lion_scenemenu:client:removeSpeedZone', -1, zoneId)
    end
end)

RegisterNetEvent('lion_scenemenu:server:clearAllSpeedZones', function()
    local src = source
    if not hasPermission(src) then return end

    activeZones = {}
    TriggerClientEvent('lion_scenemenu:client:clearAllSpeedZones', -1)
end)

AddEventHandler('playerDropped', function(reason)
    local src = source
    local toRemove = {}
    for zoneId, zone in pairs(activeZones) do
        if zone.creatorSource == src then
            table.insert(toRemove, zoneId)
        end
    end

    for _, zoneId in ipairs(toRemove) do
        activeZones[zoneId] = nil
        TriggerClientEvent('lion_scenemenu:client:removeSpeedZone', -1, zoneId)
    end
end)

local function CheckVersion()
    PerformHttpRequest('https://raw.githubusercontent.com/L0stedMrlion/lion_scripts_versions/main/versions.json',
        function(err, responseData, headers)
            local currentVersion = GetResourceMetadata(GetCurrentResourceName(), 'version')
            local resourcename = "lion_scenemenu"

            if not responseData or responseData == "" then
                print("^1[" .. resourcename .. "] Unable to run version check.^7")
                return
            end

            local ok, versions = pcall(json.decode, responseData)
            if not ok or not versions or not versions[resourcename] then
                print("^1[" .. resourcename .. "] Failed to parse versions.json^7")
                return
            end

            local data = versions[resourcename]
            local newest = type(data) == "table" and tostring(data.version or "") or tostring(data)

            if newest == "" then return end

            local current = currentVersion:gsub("%s+", "")
            local latest  = newest:gsub("%s+", "")

            if current ~= latest then
                print("^3An update is available for " .. resourcename .. "^7")
                print("^3Your Version: ^1" .. current .. "^3 | Latest Version: ^2" .. latest .. "^7")
                print(
                    "^3Download the latest release from ^4https://github.com/L0stedMrlion/lion_scenemenu/releases")
            end
        end)
end

if config.versioncheck then
    CheckVersion()
end
