-- DB-Boats Client Features (Anchor, Storage, On-Boat Refuel, On-Boat Repair)

local RSGCore = exports['rsg-core']:GetCoreObject()

local isAnchored = false
local boatTargetAdded = false

-- ============================================================
-- OX_TARGET ON BOAT
-- ============================================================

function SetupBoatTarget(entity, boatData)
    if boatTargetAdded then return end
    boatTargetAdded = true

    local options = {
        -- Drop Anchor
        {
            name = 'db_boats_anchor_drop',
            icon = 'fa-solid fa-anchor',
            label = '⚓ Drop Anchor',
            distance = 5.0,
            canInteract = function()
                return not isAnchored
            end,
            onSelect = function()
                ToggleAnchor()
            end,
        },
        -- Raise Anchor
        {
            name = 'db_boats_anchor_raise',
            icon = 'fa-solid fa-anchor',
            label = '⚓ Raise Anchor  [Anchored]',
            distance = 5.0,
            canInteract = function()
                return isAnchored
            end,
            onSelect = function()
                ToggleAnchor()
            end,
        },
        -- Boat Storage
        {
            name = 'db_boats_storage',
            icon = 'fa-solid fa-box-open',
            label = 'Boat Storage',
            distance = 5.0,
            onSelect = function()
                OpenBoatStorage()
            end,
        },
        -- On-Boat Repair
        {
            name = 'db_boats_repair',
            icon = 'fa-solid fa-hammer',
            label = 'Repair Hull',
            distance = 5.0,
            canInteract = function()
                if Config.BoatRepair.requireAnchored and not isAnchored then
                    return false
                end
                local currentBoat = exports[GetCurrentResourceName()]:GetCurrentBoat()
                if currentBoat and currentBoat.durability < 100 then
                    return true
                end
                return false
            end,
            onSelect = function()
                OnBoatRepair()
            end,
        },
    }

    -- Refuel option (fuel boats only)
    if boatData.usesFuel then
        options[#options + 1] = {
            name = 'db_boats_refuel',
            icon = 'fa-solid fa-fire',
            label = 'Refuel (Coal)',
            distance = 5.0,
            canInteract = function()
                return isAnchored
            end,
            onSelect = function()
                OnBoatRefuel()
            end,
        }
    end

    exports.ox_target:addLocalEntity(entity, options)
end

function RemoveBoatTarget(entity)
    if not boatTargetAdded then return end

    if entity and DoesEntityExist(entity) then
        exports.ox_target:removeLocalEntity(entity, {
            'db_boats_anchor_drop',
            'db_boats_anchor_raise',
            'db_boats_storage',
            'db_boats_repair',
            'db_boats_refuel',
        })
    end

    boatTargetAdded = false
end

-- ============================================================
-- ANCHOR SYSTEM
-- ============================================================

function ToggleAnchor()
    local currentBoat = exports[GetCurrentResourceName()]:GetCurrentBoat()
    local currentBoatEntity = exports[GetCurrentResourceName()]:GetCurrentBoatEntity()

    if not currentBoat or not currentBoatEntity or not DoesEntityExist(currentBoatEntity) then
        lib.notify({ title = 'DB-Boats', description = 'No active boat.', type = 'error' })
        return
    end

    if isAnchored then
        RaiseAnchor(currentBoatEntity)
    else
        DropAnchor(currentBoatEntity)
    end
end

function DropAnchor(entity)
    if isAnchored then return end
    isAnchored = true
    FreezeEntityPosition(entity, true)
    lib.notify({ title = 'DB-Boats', description = '⚓ Anchor dropped.', type = 'info' })
end

function RaiseAnchor(entity)
    if not isAnchored then return end
    isAnchored = false
    FreezeEntityPosition(entity, false)
    lib.notify({ title = 'DB-Boats', description = '⚓ Anchor raised.', type = 'info' })
end

function IsBoatAnchored()
    return isAnchored
end

function ResetAnchor()
    isAnchored = false
end

-- ============================================================
-- AUTO-ANCHOR ON EXIT (optional)
-- ============================================================

if Config.Anchor.autoAnchorOnExit then
    CreateThread(function()
        local wasInBoat = false

        while true do
            Wait(500)

            local currentBoat = exports[GetCurrentResourceName()]:GetCurrentBoat()
            local currentBoatEntity = exports[GetCurrentResourceName()]:GetCurrentBoatEntity()

            if currentBoat and currentBoatEntity and DoesEntityExist(currentBoatEntity) then
                local ped = PlayerPedId()
                local inBoat = IsPedInVehicle(ped, currentBoatEntity, false)

                if wasInBoat and not inBoat and not isAnchored then
                    DropAnchor(currentBoatEntity)
                end

                wasInBoat = inBoat
            else
                wasInBoat = false
                if isAnchored then
                    isAnchored = false
                end
            end
        end
    end)
end

-- ============================================================
-- BOAT STORAGE
-- ============================================================

function OpenBoatStorage()
    if not Config.BoatStorage.enabled then return end

    local currentBoat = exports[GetCurrentResourceName()]:GetCurrentBoat()
    local currentBoatEntity = exports[GetCurrentResourceName()]:GetCurrentBoatEntity()

    if not currentBoat or not currentBoatEntity or not DoesEntityExist(currentBoatEntity) then
        lib.notify({ title = 'DB-Boats', description = 'No active boat.', type = 'error' })
        return
    end

    local ped = PlayerPedId()
    local pedCoords = GetEntityCoords(ped)
    local boatCoords = GetEntityCoords(currentBoatEntity)
    local dist = #(pedCoords - boatCoords)

    if not IsPedInVehicle(ped, currentBoatEntity, false) and dist > 5.0 then
        lib.notify({ title = 'DB-Boats', description = 'You must be in or near your boat.', type = 'error' })
        return
    end

    RSGCore.Functions.TriggerCallback('db-boats:server:openBoatStorage', function(success)
        if not success then
            lib.notify({ title = 'DB-Boats', description = 'Unable to access boat storage.', type = 'error' })
        end
    end, currentBoat.boatId)
end

-- ============================================================
-- ON-BOAT REFUEL
-- ============================================================

function OnBoatRefuel()
    if not Config.BoatRefuel.enabled then return end

    local currentBoat = exports[GetCurrentResourceName()]:GetCurrentBoat()
    local currentBoatEntity = exports[GetCurrentResourceName()]:GetCurrentBoatEntity()

    if not currentBoat or not currentBoatEntity or not DoesEntityExist(currentBoatEntity) then
        lib.notify({ title = 'DB-Boats', description = 'No active boat.', type = 'error' })
        return
    end

    if not currentBoat.usesFuel then
        lib.notify({ title = 'DB-Boats', description = 'This boat doesn\'t use fuel.', type = 'info' })
        return
    end

    if Config.BoatRefuel.requireAnchored and not isAnchored then
        lib.notify({ title = 'DB-Boats', description = 'Drop anchor first before refueling.', type = 'warning' })
        return
    end

    if currentBoat.fuel >= Config.MaxFuel then
        lib.notify({ title = 'DB-Boats', description = 'Fuel tank is already full.', type = 'info' })
        return
    end

    RSGCore.Functions.TriggerCallback('db-boats:server:getCoalCount', function(coalCount)
        if coalCount <= 0 then
            lib.notify({ title = 'DB-Boats', description = 'You don\'t have any coal.', type = 'error' })
            return
        end

        local fuelNeeded = Config.MaxFuel - currentBoat.fuel
        local maxCoal = math.ceil(fuelNeeded / Config.BoatRefuel.coalPerFuel)
        local useAmount = math.min(coalCount, maxCoal)

        local input = lib.inputDialog('⛽ Refuel Boat', {
            {
                type = 'number',
                label = ('Coal to use  (Have: %d  |  Can use: %d)'):format(coalCount, useAmount),
                description = ('Each coal = %.0f fuel  |  Current: %.1f%%'):format(Config.BoatRefuel.coalPerFuel, currentBoat.fuel),
                default = useAmount,
                min = 1,
                max = useAmount,
                required = true,
            },
        })

        if input and input[1] then
            TriggerServerEvent('db-boats:server:refuelBoat', currentBoat.boatId, tonumber(input[1]))
        end
    end)
end

-- ============================================================
-- ON-BOAT REPAIR
-- ============================================================

function OnBoatRepair()
    if not Config.BoatRepair.enabled then return end

    local currentBoat = exports[GetCurrentResourceName()]:GetCurrentBoat()
    local currentBoatEntity = exports[GetCurrentResourceName()]:GetCurrentBoatEntity()

    if not currentBoat or not currentBoatEntity or not DoesEntityExist(currentBoatEntity) then
        lib.notify({ title = 'DB-Boats', description = 'No active boat.', type = 'error' })
        return
    end

    if Config.BoatRepair.requireAnchored and not isAnchored then
        lib.notify({ title = 'DB-Boats', description = 'Drop anchor first before repairing.', type = 'warning' })
        return
    end

    if currentBoat.durability >= 100 then
        lib.notify({ title = 'DB-Boats', description = 'Hull is already in perfect condition.', type = 'info' })
        return
    end

    -- Check how many repair kits the player has
    RSGCore.Functions.TriggerCallback('db-boats:server:getRepairKitCount', function(kitCount)
        if kitCount <= 0 then
            lib.notify({ title = 'DB-Boats', description = 'You don\'t have any repair kits.', type = 'error' })
            return
        end

        local durabilityNeeded = 100 - currentBoat.durability
        local kitsNeeded = math.ceil(durabilityNeeded / Config.BoatRepair.repairAmount)
        local maxKits = math.min(kitCount, kitsNeeded)

        local input = lib.inputDialog('🔧 Repair Hull', {
            {
                type = 'number',
                label = ('Repair kits to use  (Have: %d  |  Can use: %d)'):format(kitCount, maxKits),
                description = ('Each kit restores %.0f%% hull  |  Current hull: %.1f%%'):format(Config.BoatRepair.repairAmount, currentBoat.durability),
                default = maxKits,
                min = 1,
                max = maxKits,
                required = true,
            },
        })

        if input and input[1] then
            local kitsToUse = tonumber(input[1])

            -- Progress bar for repair
            local success = lib.progressBar({
                duration = kitsToUse * 3000,
                label = 'Repairing hull...',
                useWhileDead = false,
                canCancel = true,
                disable = {
                    move = true,
                    car = true,
                    combat = true,
                },
            })

            if success then
                TriggerServerEvent('db-boats:server:onBoatRepair', currentBoat.boatId, kitsToUse)
            else
                lib.notify({ title = 'DB-Boats', description = 'Repair cancelled.', type = 'error' })
            end
        end
    end)
end

-- ============================================================
-- EXPORTS
-- ============================================================

exports('IsBoatAnchored', IsBoatAnchored)
exports('ToggleAnchor', ToggleAnchor)
exports('ResetAnchor', ResetAnchor)
exports('SetupBoatTarget', SetupBoatTarget)
exports('RemoveBoatTarget', RemoveBoatTarget)
