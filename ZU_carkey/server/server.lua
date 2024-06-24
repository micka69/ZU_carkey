ESX = nil
ESX = exports["es_extended"]:getSharedObject()

ESX.RegisterServerCallback('locksmith:getVehicleOwner', function(source, cb, plate)
    MySQL.Async.fetchAll('SELECT owner, job FROM owned_vehicles WHERE plate = @plate', {
        ['@plate'] = plate
    }, function(result)
        if result and result[1] then
            cb(result[1].owner, result[1].job)
        else
            cb(nil, nil)
        end
    end)
end)

RegisterServerEvent('locksmith:updateLockStatus')
AddEventHandler('locksmith:updateLockStatus', function(netId, lock)
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    if DoesEntityExist(vehicle) then
        TriggerClientEvent('locksmith:setVehicleLock', -1, netId, lock)
    end
end)
