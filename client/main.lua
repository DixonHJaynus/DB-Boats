-- DB-Boats Client Main

local RSGCore = exports['rsg-core']:GetCoreObject()

local currentBoat = nil
local currentBoatEntity = nil
local spawnedNPCs = {}
local marinaBlips = {}
local isInBoat = false
local fuelThread = false
local damageThread = false
local lastDamageNotification = 0

-- ============================================================
-- MODEL LOADER
-- ============================================================

function LoadModel(model)
    local hash = type(model) == 'string' and joaat(model) or model
    if not IsModelValid(hash) then
        return false
    end
    RequestModel(hash)
    local timeout = 0
    while not HasModelLoaded(hash) do
        Wait(100)
        timeout = timeout + 100
        if timeout > 10000 then
            return false
        end
    end
    return true, hash
end

-- ============================================================
-- INITIALIZATION
-- ============================================================

CreateThread(function()
    for marinaId, marina in pairs(Config.Marinas) do
        if marina.blip then
            local b = marina.blip
            local blip = Citizen.InvokeNative(0x554D9D53F696D002, 1664425300, b.coords.x, b.coords.y, b.coords.z)
            SetBlipSprite(blip, b.sprite, true)
            SetBlipScale(blip, b.scale or 0.22)
            Citizen.InvokeNative(0x9CB1A1623062F402, blip, b.label)
            marinaBlips[marinaId] = blip
        end

        SpawnMarinaClerk(marinaId, marina)
    end
end)

-- ============================================================
-- NPC CLERK SPAWN
-- ============================================================

function SpawnMarinaClerk(marinaId, marina)
    local clerk = marina.clerk

    local loaded, hash = LoadModel(clerk.model)
    if not loaded then return end

    local ped = CreatePed(
        hash,
        clerk.coords.x,
        clerk.coords.y,
        clerk.coords.z,
        clerk.coords.w,
        false, true, true, true
    )

    Wait(500)

    if not ped or ped == 0 or not DoesEntityExist(ped) then
        SetModelAsNoLongerNeeded(hash)
        return
    end

    SetEntityAsMissionEntity(ped, true, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    FreezeEntityPosition(ped, true)
    SetEntityVisible(ped, true)
    SetEntityAlpha(ped, 255, false)

    Citizen.InvokeNative(0x283978A15512B2FE, ped, true)
    Citizen.InvokeNative(0xAAB86462966168CE, ped, true)

    Wait(500)

    if clerk.scenario and clerk.scenario ~= '' then
        ClearPedTasksImmediately(ped)
        Wait(100)
        TaskStartScenarioInPlace(ped, joaat(clerk.scenario), -1, true, false, false, false)
    end

    spawnedNPCs[marinaId] = ped

    exports.ox_target:addLocalEntity(ped, {
        {
            name = 'db_boats_marina_' .. marinaId,
            icon = 'fa-solid fa-anchor',
            label = marina.label,
            distance = 3.0,
            onSelect = function()
                OpenMarinaMenu(marinaId)
            end,
        },
    })

    SetModelAsNoLongerNeeded(hash)
end

-- ============================================================
-- BOAT SPAWNING
-- ============================================================

RegisterNetEvent('db-boats:client:spawnBoat', function(boatData)
    local marina = Config.Marinas[boatData.marinaId]
    if not marina then return end

    local spawn = marina.spawn.coords

    local loaded, hash = LoadModel(boatData.model)
    if not loaded then
        lib.notify({ title = 'DB-Boats', description = 'Failed to load boat model.', type = 'error' })
        return
    end

    if currentBoatEntity and DoesEntityExist(currentBoatEntity) then
        DeleteEntity(currentBoatEntity)
    end

    local boat = CreateVehicle(hash, spawn.x, spawn.y, spawn.z, spawn.w, true, true)

    Wait(100)

    if not boat or boat == 0 or not DoesEntityExist(boat) then
        lib.notify({ title = 'DB-Boats', description = 'Failed to spawn boat.', type = 'error' })
        SetModelAsNoLongerNeeded(hash)
        return
    end

    SetModelAsNoLongerNeeded(hash)

    local health = math.floor(1000 * ((boatData.durability or 100) / 100))
    SetEntityHealth(boat, health, 0)

    currentBoatEntity = boat
    currentBoat = {
        boatId       = boatData.boatId,
        entity       = boat,
        model        = boatData.model,
        label        = boatData.label,
        registration = boatData.registration,
        fuel         = boatData.fuel or Config.DefaultFuel,
        durability   = boatData.durability or 100.0,
        stats        = boatData.stats,
        usesFuel     = boatData.usesFuel,
        marinaId     = boatData.marinaId,
    }

    -- Reset damage notification tracker
    lastDamageNotification = 0

    SetupBoatTarget(boat, boatData)

    TaskWarpPedIntoVehicle(PlayerPedId(), boat, -1)

    -- Show spawn notification with durability status
    local durMsg = ''
    if currentBoat.durability < 100 then
        durMsg = ('  |  Hull: %.0f%%'):format(currentBoat.durability)
    end

    lib.notify({
        title = 'DB-Boats',
        description = ('%s spawned! Fuel: %.1f%%%s'):format(boatData.label, currentBoat.fuel, durMsg),
        type = 'success',
    })

    -- Check if boat is already damaged on spawn
    if Config.Damage.enabled and currentBoat.durability <= Config.Damage.thresholds.disabled then
        lib.notify({
            title = 'DB-Boats',
            description = '⚠️ This boat is disabled! Visit a marina to repair.',
            type = 'error',
        })
    end

    if boatData.usesFuel then
        StartFuelThread()
    end
    StartBoatMonitor()
    if Config.Damage.enabled then
        StartDamageEffects()
    end
end)

-- ============================================================
-- FUEL SYSTEM
-- ============================================================

function StartFuelThread()
    if fuelThread then return end
    fuelThread = true

    CreateThread(function()
        while fuelThread and currentBoat and currentBoat.usesFuel do
            Wait(Config.FuelCheckInterval)

            if not currentBoat or not currentBoatEntity or not DoesEntityExist(currentBoatEntity) then
                fuelThread = false
                break
            end

            local ped = PlayerPedId()
            if IsPedInVehicle(ped, currentBoatEntity, false) then
                local speed = GetEntitySpeed(currentBoatEntity)

                if speed > 0.5 then
                    local consumption = (currentBoat.stats.fuelConsumption or 1.0)
                        * (speed / 10.0)
                        * (Config.FuelCheckInterval / 60000)

                    currentBoat.fuel = math.max(0, currentBoat.fuel - consumption)
                    TriggerServerEvent('db-boats:server:updateFuel', currentBoat.boatId, currentBoat.fuel)

                    if currentBoat.fuel <= 0 then
                        lib.notify({ title = 'DB-Boats', description = 'Out of fuel! Add coal to continue.', type = 'error' })
                        FreezeEntityPosition(currentBoatEntity, true)
                        Wait(3000)
                        FreezeEntityPosition(currentBoatEntity, false)
                    elseif currentBoat.fuel <= 15 then
                        lib.notify({ title = 'DB-Boats', description = ('Low fuel: %.1f%% remaining'):format(currentBoat.fuel), type = 'warning' })
                    end
                end
            end
        end
    end)
end

RegisterNetEvent('db-boats:client:updateFuel', function(boatId, newFuel)
    if currentBoat and currentBoat.boatId == boatId then
        currentBoat.fuel = newFuel
    end
end)

-- ============================================================
-- BOAT MONITOR (health tracking)
-- ============================================================

function StartBoatMonitor()
    CreateThread(function()
        local lastHealth = nil

        while currentBoat and currentBoatEntity and DoesEntityExist(currentBoatEntity) do
            Wait(1000)
            if not currentBoat or not currentBoatEntity then break end

            local health = GetEntityHealth(currentBoatEntity)

            if lastHealth and health < lastHealth then
                local rawDamage = (lastHealth - health) / 10.0

                -- Apply durability upgrade damage reduction
                local reduction = GetDamageReduction()
                local actualDamage = rawDamage * (1.0 - reduction)

                currentBoat.durability = math.max(0, currentBoat.durability - actualDamage)

                -- Save to server periodically
                TriggerServerEvent('db-boats:server:updateDurability', currentBoat.boatId, currentBoat.durability)

                -- Damage threshold notifications
                CheckDamageThresholds()
            end
            lastHealth = health

            isInBoat = IsPedInVehicle(PlayerPedId(), currentBoatEntity, false)
        end
    end)
end

-- ============================================================
-- DAMAGE REDUCTION FROM UPGRADES
-- ============================================================

function GetDamageReduction()
    if not currentBoat or not currentBoat.stats then return 0 end

    -- Find current durability upgrade level from the boat stats
    -- The upgrade bonus in config adds to the base durability stat
    -- We need the actual upgrade level, which we can derive
    local modelData = Config.BoatModels[currentBoat.model]
    if not modelData then return 0 end

    local baseDurability = modelData.baseStats.durability
    local currentDurabilityStat = currentBoat.stats.durability or baseDurability
    local bonusFromUpgrades = currentDurabilityStat - baseDurability

    -- Find which level this corresponds to
    local upgradeLevel = 0
    for level, data in pairs(Config.Upgrades.durability.levels) do
        if data.bonus == bonusFromUpgrades then
            upgradeLevel = level
            break
        end
    end

    -- Get damage reduction percentage
    if upgradeLevel > 0 and Config.Damage.upgradeReduction[upgradeLevel] then
        return Config.Damage.upgradeReduction[upgradeLevel]
    end

    return 0
end

-- ============================================================
-- DAMAGE THRESHOLD NOTIFICATIONS
-- ============================================================

function CheckDamageThresholds()
    if not currentBoat then return end

    local durability = currentBoat.durability
    local now = GetGameTimer()

    -- Only notify once per threshold (10 second cooldown)
    if now - lastDamageNotification < 10000 then return end

    if durability <= Config.Damage.thresholds.disabled then
        lastDamageNotification = now
        lib.notify({
            title = '🚨 BOAT DISABLED',
            description = 'Hull integrity critical! Boat cannot move. Visit a marina to repair.',
            type = 'error',
        })
    elseif durability <= Config.Damage.thresholds.critical then
        lastDamageNotification = now
        lib.notify({
            title = '⚠️ Critical Damage',
            description = ('Hull integrity: %.0f%% — Severe speed reduction. Repair soon!'):format(durability),
            type = 'error',
        })
    elseif durability <= Config.Damage.thresholds.caution then
        lastDamageNotification = now
        lib.notify({
            title = '⚠️ Hull Damage',
            description = ('Hull integrity: %.0f%% — Speed is reduced.'):format(durability),
            type = 'warning',
        })
    elseif durability <= Config.Damage.thresholds.warning then
        lastDamageNotification = now
        lib.notify({
            title = 'Hull Damage',
            description = ('Hull integrity: %.0f%% — Minor damage detected.'):format(durability),
            type = 'info',
        })
    end
end

-- ============================================================
-- DAMAGE EFFECTS (Speed Reduction & Disable)
-- ============================================================

function StartDamageEffects()
    if damageThread then return end
    damageThread = true

    CreateThread(function()
        while damageThread and currentBoat and currentBoatEntity and DoesEntityExist(currentBoatEntity) do
            Wait(500)

            if not currentBoat or not currentBoatEntity or not DoesEntityExist(currentBoatEntity) then
                damageThread = false
                break
            end

            local durability = currentBoat.durability
            local ped = PlayerPedId()
            local inBoat = IsPedInVehicle(ped, currentBoatEntity, false)
            local isCurrentlyAnchored = exports[GetCurrentResourceName()]:IsBoatAnchored()

            if inBoat and not isCurrentlyAnchored then
                if durability <= Config.Damage.thresholds.disabled then
                    -- Boat is disabled — cannot move
                    FreezeEntityPosition(currentBoatEntity, true)
                else
                    -- Calculate speed modifier based on durability
                    local speedMod = GetSpeedModifier(durability)

                    if speedMod < 1.0 then
                        -- Apply speed reduction by limiting velocity
                        local velocity = GetEntityVelocity(currentBoatEntity)
                        local speed = GetEntitySpeed(currentBoatEntity)

                        -- Get base max speed and calculate reduced max
                        local baseSpeed = (currentBoat.stats.speed or 50) / 10.0
                        local maxAllowedSpeed = baseSpeed * speedMod

                        if speed > maxAllowedSpeed and speed > 0.5 then
                            local scale = maxAllowedSpeed / speed
                            SetEntityVelocity(currentBoatEntity, velocity.x * scale, velocity.y * scale, velocity.z)
                        end
                    end
                end
            end
        end
    end)
end

function GetSpeedModifier(durability)
    if durability >= 100 then
        return 1.0
    end

    -- Linear interpolation from full speed to reduced speed
    -- 100% durability = 1.0 (full speed)
    -- 0% durability = 1.0 - maxSpeedReduction
    local minModifier = 1.0 - Config.Damage.maxSpeedReduction
    local modifier = minModifier + ((durability / 100.0) * Config.Damage.maxSpeedReduction)

    return math.max(minModifier, math.min(1.0, modifier))
end

-- ============================================================
-- DURABILITY UPDATE FROM SERVER (after repair)
-- ============================================================

RegisterNetEvent('db-boats:client:updateDurability', function(boatId, newDurability)
    if currentBoat and currentBoat.boatId == boatId then
        currentBoat.durability = newDurability
        lastDamageNotification = 0

        -- Unfreeze if was disabled and now repaired
        if newDurability > Config.Damage.thresholds.disabled then
            if currentBoatEntity and DoesEntityExist(currentBoatEntity) then
                local isCurrentlyAnchored = exports[GetCurrentResourceName()]:IsBoatAnchored()
                if not isCurrentlyAnchored then
                    FreezeEntityPosition(currentBoatEntity, false)
                end
            end
        end

        -- Restore entity health
        if currentBoatEntity and DoesEntityExist(currentBoatEntity) then
            local health = math.floor(1000 * (newDurability / 100))
            SetEntityHealth(currentBoatEntity, health, 0)
        end
    end
end)

-- ============================================================
-- STORE BOAT
-- ============================================================

function StoreCurrentBoat(marinaId)
    if not currentBoat then
        lib.notify({ title = 'DB-Boats', description = 'No boat to store.', type = 'error' })
        return
    end

    ResetAnchor()
    RemoveBoatTarget(currentBoatEntity)

    local ped = PlayerPedId()
    if IsPedInVehicle(ped, currentBoatEntity, false) then
        TaskLeaveVehicle(ped, currentBoatEntity, 0)
        Wait(1500)
    end

    TriggerServerEvent('db-boats:server:storeBoat',
        currentBoat.boatId, marinaId, currentBoat.fuel, currentBoat.durability
    )

    if currentBoatEntity and DoesEntityExist(currentBoatEntity) then
        DeleteEntity(currentBoatEntity)
    end

    fuelThread              = false
    damageThread            = false
    lastDamageNotification  = 0
    currentBoat             = nil
    currentBoatEntity       = nil
    isInBoat                = false
end

-- ============================================================
-- CLEANUP
-- ============================================================

local function Cleanup()
    if currentBoat and currentBoatEntity and DoesEntityExist(currentBoatEntity) then
        ResetAnchor()
        RemoveBoatTarget(currentBoatEntity)
        TriggerServerEvent('db-boats:server:storeBoat',
            currentBoat.boatId, currentBoat.marinaId, currentBoat.fuel, currentBoat.durability
        )
        DeleteEntity(currentBoatEntity)
    end

    for _, ped in pairs(spawnedNPCs) do
        if DoesEntityExist(ped) then DeleteEntity(ped) end
    end

    for _, blip in pairs(marinaBlips) do
        RemoveBlip(blip)
    end

    spawnedNPCs             = {}
    marinaBlips             = {}
    fuelThread              = false
    damageThread            = false
    lastDamageNotification  = 0
    currentBoat             = nil
    currentBoatEntity       = nil
    isInBoat                = false
end

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() then Cleanup() end
end)

RegisterNetEvent('RSGCore:Client:OnPlayerUnload', Cleanup)

-- ============================================================
-- EXPORTS
-- ============================================================

exports('GetCurrentBoat', function() return currentBoat end)
exports('GetCurrentBoatEntity', function() return currentBoatEntity end)
exports('IsPlayerInOwnedBoat', function() return isInBoat and currentBoat ~= nil end)
