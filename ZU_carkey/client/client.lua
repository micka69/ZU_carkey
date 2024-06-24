ESX = nil
ESX = exports["es_extended"]:getSharedObject()

local lastActionTime = 0  -- Variable pour stocker le dernier moment d'action
local searchRadius = 5.0  

function GetVehicleInDirection(coordFrom, coordTo)
    local rayHandle = StartShapeTestRay(coordFrom.x, coordFrom.y, coordFrom.z, coordTo.x, coordTo.y, coordFrom.z, 10, PlayerPedId(), 0)
    local _, hit, _, _, vehicle = GetShapeTestResult(rayHandle)
    return hit and vehicle or nil
end

local function PlayLockAnimation(vehicle)
    local playerPed = PlayerPedId()
    RequestAnimDict("anim@mp_player_intmenu@key_fob@")
    while not HasAnimDictLoaded("anim@mp_player_intmenu@key_fob@") do
        Wait(0)
    end
    TaskPlayAnim(playerPed, "anim@mp_player_intmenu@key_fob@", "fob_click", 8.0, 8.0, -1, 48, 1, false, false, false)
    Wait(500)
    
    local vehicle_pos = GetEntityCoords(vehicle)
    local player_pos = GetEntityCoords(playerPed)
    local distance = #(vehicle_pos - player_pos)
    
    if distance <= 10 then
        StartVehicleHorn(vehicle, 50, false)
        SetVehicleLights(vehicle, 2)
        Wait(200)
        SetVehicleLights(vehicle, 0)
        StartVehicleHorn(vehicle, 50, false)
        SetVehicleLights(vehicle, 2)
        Wait(200)
        SetVehicleLights(vehicle, 0)
    end
end

function ToggleVehicleLock(vehicle)
    if DoesEntityExist(vehicle) then
        local lockStatus = GetVehicleDoorLockStatus(vehicle)
        local currentTime = GetGameTimer()

        -- Vérifier si assez de temps s'est écoulé depuis la dernière action
        if currentTime - lastActionTime < 5000 then  -- Attendre 5 secondes entre chaque action
            ESX.ShowNotification("Attendez quelques secondes avant de verrouiller à nouveau le véhicule.", "error", Config.NotificationDuration)
            return
        end

        -- Mettre à jour le temps de la dernière action
        lastActionTime = currentTime

        -- Jouer une animation ou effectuer d'autres actions visuelles si nécessaire
        PlayLockAnimation(vehicle)

        -- Modifier l'état de verrouillage en fonction de l'état actuel
        if lockStatus == 1 or lockStatus == 0 then
            SetVehicleDoorsLocked(vehicle, 2)  -- Verrouiller le véhicule
            ESX.ShowNotification("Véhicule verrouillé", "info", Config.NotificationDuration)
        else
            SetVehicleDoorsLocked(vehicle, 1)  -- Déverrouiller le véhicule
            ESX.ShowNotification("Véhicule déverrouillé", "info", Config.NotificationDuration)
        end

        -- Envoyer un événement au serveur pour mettre à jour le statut de verrouillage
        TriggerServerEvent('locksmith:updateLockStatus', NetworkGetNetworkIdFromEntity(vehicle), lockStatus == 1 or lockStatus == 0)
    else
        ESX.ShowNotification("Aucun véhicule à proximité", "error", Config.NotificationDuration)
    end
end

local function ToggleVehicleLockCommand()
    local playerPed = PlayerPedId()
    if IsPedInAnyVehicle(playerPed, false) then
        local vehicle = GetVehiclePedIsIn(playerPed, false)
        if vehicle then
            ToggleVehicleLock(vehicle)
        else
            ESX.ShowNotification("Impossible de trouver le véhicule", "error", Config.NotificationDuration)
        end
    else
        local coords = GetEntityCoords(playerPed)
        local forwardVector = GetEntityForwardVector(playerPed)
        local targetCoords = coords + forwardVector * 5.0
        local vehicle = GetVehicleInDirection(coords, targetCoords)

        if vehicle then
            ToggleVehicleLock(vehicle)
        else
            ESX.ShowNotification("Aucun véhicule à proximité", "error", Config.NotificationDuration)
        end
    end
end

-- Utilisation de Citizen.CreateThread pour surveiller l'appui de la touche
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if IsControlJustReleased(0, 303) then -- 303 est l'ID de la touche "U"
            ToggleVehicleLockCommand()
        end
    end
end)

RegisterNetEvent('locksmith:setVehicleLock')
AddEventHandler('locksmith:setVehicleLock', function(netId, lock)
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    if DoesEntityExist(vehicle) then
        SetVehicleDoorsLocked(vehicle, lock and 2 or 1)
    end
end)

function GetVehicleInDirection(playerPos, forwardVector)
    local numVehicles = 0
    local vehicleArray = {}
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    local radius = 5.0  -- Rayon de recherche autour du joueur
    
    local directionCoords = playerPos + (forwardVector * radius)
    local sphereHandle = StartShapeTestCapsule(coords.x, coords.y, coords.z, directionCoords.x, directionCoords.y, directionCoords.z, 2.0, 10, playerPed, 7)
    local _, hit, endCoords, surfaceNormal, vehicle = GetShapeTestResult(sphereHandle)

    if hit then
        if IsEntityAVehicle(vehicle) then
            return vehicle
        end
    end

    return nil
end


-- Ajout de la fonctionnalité ox_target
exports.ox_target:addGlobalVehicle({
    {
        name = 'toggle_vehicle_lock',
        icon = 'fas fa-key',
        label = 'Verrouiller/Déverrouiller',
        canInteract = function(entity, distance, coords, name)
            return distance <= 2.0
        end,
        onSelect = function(data)
            ToggleVehicleLock(data.entity)
        end
    }
})
