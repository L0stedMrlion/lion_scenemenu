local activeZones = {}
local config = require 'config'

local function canSeeRadius()
    local hasESX, ESX = pcall(function() return exports['es_extended']:getSharedObject() end)
    if hasESX and ESX and ESX.GetPlayerData then
        local playerData = ESX.GetPlayerData()
        local job = playerData and playerData.job and playerData.job.name
        if job then
            for i = 1, #config.scenemenu.allowedJobs do
                if config.scenemenu.allowedJobs[i] == job then
                    return true
                end
            end
        end
    end

    local hasQBCore, QBCore = pcall(function() return exports['qb-core']:GetCoreObject() end)
    if hasQBCore and QBCore and QBCore.Functions and QBCore.Functions.GetPlayerData then
        local playerData = QBCore.Functions.GetPlayerData()
        local job = playerData and playerData.job and playerData.job.name
        if job then
            for i = 1, #config.scenemenu.allowedJobs do
                if config.scenemenu.allowedJobs[i] == job then
                    return true
                end
            end
        end
    end

    return false
end

local function createLocalSpeedZone(zoneId, coords, radius, speed, creatorSource, creatorName)
    if activeZones[zoneId] then
        RemoveRoadNodeSpeedZone(activeZones[zoneId].nativeId)
        if activeZones[zoneId].radiusBlip and DoesBlipExist(activeZones[zoneId].radiusBlip) then
            RemoveBlip(activeZones
                [zoneId].radiusBlip)
        end
        if activeZones[zoneId].centerBlip and DoesBlipExist(activeZones[zoneId].centerBlip) then
            RemoveBlip(activeZones
                [zoneId].centerBlip)
        end
    end

    local radiusFloat = radius + 0.0
    local nativeId = AddRoadNodeSpeedZone(coords.x, coords.y, coords.z, radiusFloat, speed / 3.6, false)

    local blipColor = config.scenemenu.blips.colors.moderate
    if speed <= 0 then
        blipColor = config.scenemenu.blips.colors.stop
    elseif speed <= 20 then
        blipColor = config.scenemenu.blips.colors.verySlow
    elseif speed <= 40 then
        blipColor = config.scenemenu.blips.colors.moderate
    else
        blipColor = config.scenemenu.blips.colors.fast
    end

    local radiusBlip = nil
    if canSeeRadius() then
        radiusBlip = AddBlipForRadius(coords.x, coords.y, coords.z, radiusFloat)
        SetBlipRotation(radiusBlip, 0)
        SetBlipHighDetail(radiusBlip, true)
        SetBlipColour(radiusBlip, blipColor)
        SetBlipAlpha(radiusBlip, config.scenemenu.blips.radiusAlpha)
    end

    local centerBlip = nil
    if canSeeRadius() then
        centerBlip = AddBlipForCoord(coords.x, coords.y, coords.z)
        SetBlipSprite(centerBlip, config.scenemenu.blips.centerSprite)
        SetBlipColour(centerBlip, blipColor)
        SetBlipScale(centerBlip, config.scenemenu.blips.centerScale)
        SetBlipAsShortRange(centerBlip, config.scenemenu.blips.shortRange)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString((creatorName or "Unknown") .. " - Zone " .. math.floor(speed) .. " mp/h")
        EndTextCommandSetBlipName(centerBlip)
    end

    local isCreator = (creatorSource == GetPlayerServerId(PlayerId()))

    activeZones[zoneId] = {
        id = zoneId,
        nativeId = nativeId,
        coords = coords,
        radius = radius,
        speed = speed,
        radiusBlip = radiusBlip,
        centerBlip = centerBlip,
        creatorSource = creatorSource,
        creatorName = creatorName,
        isCreator = isCreator
    }
end

local function removeLocalSpeedZone(zoneId)
    local zone = activeZones[zoneId]
    if not zone then return end

    RemoveRoadNodeSpeedZone(zone.nativeId)
    if zone.radiusBlip and DoesBlipExist(zone.radiusBlip) then RemoveBlip(zone.radiusBlip) end
    if zone.centerBlip and DoesBlipExist(zone.centerBlip) then RemoveBlip(zone.centerBlip) end

    activeZones[zoneId] = nil
end

local function clearLocalSpeedZones()
    for zoneId, zone in pairs(activeZones) do
        RemoveRoadNodeSpeedZone(zone.nativeId)
        if zone.radiusBlip and DoesBlipExist(zone.radiusBlip) then RemoveBlip(zone.radiusBlip) end
        if zone.centerBlip and DoesBlipExist(zone.centerBlip) then RemoveBlip(zone.centerBlip) end
    end
    activeZones = {}
end

RegisterNetEvent('lion_scenemenu:client:createSpeedZone',
    function(zoneId, coords, radius, speed, creatorSource, creatorName)
        createLocalSpeedZone(zoneId, coords, radius, speed, creatorSource, creatorName)
    end)

RegisterNetEvent('lion_scenemenu:client:removeSpeedZone', function(zoneId)
    removeLocalSpeedZone(zoneId)
end)

RegisterNetEvent('lion_scenemenu:client:clearAllSpeedZones', function()
    clearLocalSpeedZones()
end)

RegisterNetEvent('lion_scenemenu:client:syncSpeedZones', function(serverZones)
    clearLocalSpeedZones()
    for zoneId, zone in pairs(serverZones) do
        createLocalSpeedZone(zoneId, zone.coords, zone.radius, zone.speed, zone.creatorSource, zone.creatorName)
    end
end)

RegisterNetEvent('esx:playerLoaded', function()
    TriggerServerEvent('lion_scenemenu:server:requestSpeedZones')
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    TriggerServerEvent('lion_scenemenu:server:requestSpeedZones')
end)

AddEventHandler('onClientResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        TriggerServerEvent('lion_scenemenu:server:requestSpeedZones')
    end
end)

local function openManageZonesMenu(manageAll)
    local options = {}
    local hasZones = false

    for zoneId, zone in pairs(activeZones) do
        if manageAll or zone.isCreator then
            hasZones = true
            local streetHash = GetStreetNameAtCoord(zone.coords.x, zone.coords.y, zone.coords.z)
            local streetName = GetStreetNameFromHashKey(streetHash)
            local zoneLabel = GetLabelText(GetNameOfZone(zone.coords.x, zone.coords.y, zone.coords.z))
            local locationText = (zoneLabel ~= "NULL" and zoneLabel ~= "") and ("%s, %s"):format(streetName, zoneLabel) or
                streetName

            table.insert(options, {
                title = ('Zone #%d - %d mp/h'):format(zoneId, zone.speed),
                description = ('Creator: %s | Radius: %dm | %s'):format(zone.creatorName or "Unknown", zone.radius,
                    locationText),
                icon = 'fa-solid fa-circle-minus',
                onSelect = function()
                    removeLocalSpeedZone(zoneId)
                    TriggerServerEvent('lion_scenemenu:server:removeSpeedZone', zoneId)
                    lib.notify({
                        title = config.scenemenu.locales.menuTitle,
                        description = (config.scenemenu.locales.zoneRemoved):format(zoneId, zone.speed),
                        type = 'success',
                        icon = 'fa-solid fa-circle-minus'
                    })
                    openManageZonesMenu(manageAll)
                end
            })
        end
    end

    if not hasZones then
        table.insert(options, {
            title = 'No Active Zones',
            description = 'Create a speed zone first',
            icon = 'fa-solid fa-circle-exclamation',
            disabled = true
        })
    end

    lib.registerContext({
        id = 'scene_manage_zones_menu',
        title = manageAll and 'Manage All Zones (Supervisor)' or 'Manage Active Zones',
        menu = 'scene_menu_main',
        headerIcon = 'fa-solid fa-trash',
        subtitle = "Select a zone to delete",
        options = options
    })

    lib.showContext('scene_manage_zones_menu')
end

local function registerTrafficMenu(isSupervisor)
    local options = {
        {
            title = 'Create Speed Zone',
            description = 'Setup speed limits for vehicles in a radius',
            icon = 'fa-solid fa-plus',
            onSelect = function()
                local input = lib.inputDialog(config.scenemenu.locales.menuTitle, {
                    { type = 'number', label = 'Radius (meters)', default = config.scenemenu.zones.defaultRadius, min = config.scenemenu.zones.minRadius, max = config.scenemenu.zones.maxRadius, icon = 'fa-solid fa-expand', description = 'Set a radius in meters (max ' .. config.scenemenu.zones.maxRadius .. ')' },
                    {
                        type = 'select',
                        label = 'Speed Limit',
                        description = 'Select a speed limit',
                        icon = 'fa-solid fa-gauge-high',
                        options = config.scenemenu.speedOptions,
                        default = config.scenemenu.defaultSpeed
                    }
                })

                if input and input[1] and input[2] then
                    local radius = tonumber(input[1])
                    local speed = tonumber(input[2])
                    if radius and speed then
                        local coords = GetEntityCoords(PlayerPedId())
                        local insideExistingZone = false
                        for _, zone in pairs(activeZones) do
                            local dist = #(coords - zone.coords)
                            if dist < zone.radius then
                                insideExistingZone = true
                                break
                            end
                        end

                        if config.scenemenu.zones.preventZoneinZone and insideExistingZone then
                            lib.notify({
                                title = config.scenemenu.locales.menuTitle,
                                description = config.scenemenu.locales.preventZoneinZoneError,
                                type = 'error',
                                icon = 'fa-solid fa-circle-exclamation'
                            })
                            return
                        end

                        if config.scenemenu.zones.maxZonesPerPlayer > 0 then
                            local playerZoneCount = 0
                            for _, zone in pairs(activeZones) do
                                if zone.isCreator then
                                    playerZoneCount = playerZoneCount + 1
                                end
                            end
                            if playerZoneCount >= config.scenemenu.zones.maxZonesPerPlayer then
                                lib.notify({
                                    title = config.scenemenu.locales.menuTitle,
                                    description = config.scenemenu.locales.maxZonesReached,
                                    type = 'error',
                                    icon = 'fa-solid fa-circle-exclamation'
                                })
                                return
                            end
                        end

                        TriggerServerEvent('lion_scenemenu:server:createSpeedZone', coords, radius, speed)
                        lib.notify({
                            title = config.scenemenu.locales.menuTitle,
                            description = (config.scenemenu.locales.zoneCreated):format(radius, speed),
                            type = 'success',
                            icon = 'fa-solid fa-circle-check',
                            iconColor = '#078F26'
                        })
                    end
                end
            end
        },
        {
            title = 'Manage Active Zones',
            description = 'View or delete existing speed zones',
            icon = 'fa-solid fa-list',
            onSelect = function()
                openManageZonesMenu(false)
            end
        }
    }

    if isSupervisor then
        table.insert(options, {
            title = 'Manage All Zones (Supervisor)',
            description = 'View and delete any active speed zone',
            icon = 'fa-solid fa-users-gear',
            onSelect = function()
                openManageZonesMenu(true)
            end
        })
    end

    table.insert(options, {
        title = 'Clear All My Zones',
        description = 'Remove all speed restrictions',
        icon = 'fa-solid fa-trash',
        onSelect = function()
            local hasOwnZones = false
            for _, zone in pairs(activeZones) do
                if zone.isCreator then
                    hasOwnZones = true
                    break
                end
            end

            if not hasOwnZones then
                lib.notify({
                    title = config.scenemenu.locales.menuTitle,
                    description = config.scenemenu.locales.noZonesToClear,
                    type = 'error',
                    icon = 'fa-solid fa-circle-exclamation'
                })
                return
            end

            lib.notify({
                title = config.scenemenu.locales.menuTitle,
                description = config.scenemenu.locales.clearedOwnZones,
                type = 'success',
                icon = 'fa-solid fa-trash'
            })
            TriggerServerEvent('lion_scenemenu:server:clearMySpeedZones')
        end
    })

    lib.registerContext({
        id = 'scene_menu_main',
        title = config.scenemenu.locales.menuTitle,
        headerIcon = 'fa-solid fa-traffic-light',
        subtitle = config.scenemenu.locales.menuSubtitle,
        options = options
    })
end

RegisterCommand(config.scenemenu.command, function()
    local allowed = lib.callback.await('lion_scenemenu:server:checkScenePermission')
    if not allowed then
        lib.notify({
            title = config.scenemenu.locales.menuTitle,
            description = config.scenemenu.locales.noPermission,
            icon = "fa-solid fa-xmark",
            iconColor = "red",
            type = 'error'
        })
        return
    end

    local isSupervisor = lib.callback.await('lion_scenemenu:server:checkSupervisorPermission')
    registerTrafficMenu(isSupervisor)
    lib.showContext('scene_menu_main')
end, false)

if config.scenemenu.enableKeybind then
    RegisterKeyMapping(config.scenemenu.command, config.scenemenu.locales.menuTitle, 'keyboard',
        config.scenemenu.defaultKeybind)
end

CreateThread(function()
    registerTrafficMenu(false)
end)
