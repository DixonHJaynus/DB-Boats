-- DB-Boats Server Main

local RSGCore = exports['rsg-core']:GetCoreObject()

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    DB.Init()
end)

-- ============================================================
-- HELPERS
-- ============================================================

local function GetPlayerMoney(Player, amount)
    return Player.Functions.GetMoney('cash') >= amount
end

local function RemovePlayerMoney(Player, amount)
    return Player.Functions.RemoveMoney('cash', amount, 'db-boats-purchase')
end

local function AddPlayerMoney(Player, amount)
    return Player.Functions.AddMoney('cash', amount, 'db-boats-sale')
end

local function GetFullName(Player)
    local charInfo = Player.PlayerData.charinfo
    return charInfo.firstname .. ' ' .. charInfo.lastname
end

local function CalculateBoatStats(boatModel, upgrades)
    local modelData = Config.BoatModels[boatModel]
    if not modelData then return nil end

    local stats = {
        speed = modelData.baseStats.speed,
        durability = modelData.baseStats.durability,
        fuelConsumption = modelData.baseStats.fuelConsumption,
    }

    if upgrades.speed and upgrades.speed > 0 then
        local upgradeData = Config.Upgrades.speed.levels[upgrades.speed]
        if upgradeData then
            stats.speed = stats.speed + upgradeData.bonus
        end
    end

    if upgrades.durability and upgrades.durability > 0 then
        local upgradeData = Config.Upgrades.durability.levels[upgrades.durability]
        if upgradeData then
            stats.durability = stats.durability + upgradeData.bonus
        end
    end

    if upgrades.fuelConsumption and upgrades.fuelConsumption > 0 then
        local upgradeData = Config.Upgrades.fuelConsumption.levels[upgrades.fuelConsumption]
        if upgradeData then
            stats.fuelConsumption = math.max(0.1, stats.fuelConsumption + upgradeData.bonus)
        end
    end

    return stats
end

-- ============================================================
-- CALLBACKS
-- ============================================================

RSGCore.Functions.CreateCallback('db-boats:server:getAvailableBoats', function(source, cb, marinaId)
    local marina = Config.Marinas[marinaId]
    if not marina then cb({}) return end

    local boats = {}
    for _, modelKey in ipairs(marina.availableBoats) do
        local modelData = Config.BoatModels[modelKey]
        if modelData then
            boats[#boats + 1] = {
                model = modelKey,
                label = modelData.label,
                price = modelData.price,
                category = modelData.category,
                usesFuel = modelData.usesFuel,
                baseStats = modelData.baseStats,
                description = modelData.description,
            }
        end
    end

    cb(boats)
end)

RSGCore.Functions.CreateCallback('db-boats:server:getPlayerBoats', function(source, cb)
    local Player = RSGCore.Functions.GetPlayer(source)
    if not Player then cb({}) return end

    local boats = DB.GetPlayerBoats(Player.PlayerData.citizenid)
    for i, boat in ipairs(boats) do
        local modelData = Config.BoatModels[boat.boat_model]
        if modelData then
            boats[i].modelData = modelData
            boats[i].calculatedStats = CalculateBoatStats(boat.boat_model, {
                speed = boat.upgrade_speed,
                durability = boat.upgrade_durability,
                fuelConsumption = boat.upgrade_fuel,
            })
        end
    end

    cb(boats)
end)

RSGCore.Functions.CreateCallback('db-boats:server:getStoredBoats', function(source, cb, marinaId)
    local Player = RSGCore.Functions.GetPlayer(source)
    if not Player then cb({}) return end

    local boats = DB.GetStoredBoats(Player.PlayerData.citizenid, marinaId)
    for i, boat in ipairs(boats) do
        local modelData = Config.BoatModels[boat.boat_model]
        if modelData then
            boats[i].modelData = modelData
            boats[i].calculatedStats = CalculateBoatStats(boat.boat_model, {
                speed = boat.upgrade_speed,
                durability = boat.upgrade_durability,
                fuelConsumption = boat.upgrade_fuel,
            })
        end
    end

    cb(boats)
end)

RSGCore.Functions.CreateCallback('db-boats:server:getBoatDetails', function(source, cb, boatId)
    local Player = RSGCore.Functions.GetPlayer(source)
    if not Player then cb(nil) return end

    local boat = DB.GetBoat(boatId)
    if not boat or boat.citizenid ~= Player.PlayerData.citizenid then
        cb(nil)
        return
    end

    local modelData = Config.BoatModels[boat.boat_model]
    if modelData then
        boat.modelData = modelData
        boat.calculatedStats = CalculateBoatStats(boat.boat_model, {
            speed = boat.upgrade_speed,
            durability = boat.upgrade_durability,
            fuelConsumption = boat.upgrade_fuel,
        })
    end

    cb(boat)
end)

RSGCore.Functions.CreateCallback('db-boats:server:getUpgradeInfo', function(source, cb, boatId)
    local Player = RSGCore.Functions.GetPlayer(source)
    if not Player then cb(nil) return end

    local boat = DB.GetBoat(boatId)
    if not boat or boat.citizenid ~= Player.PlayerData.citizenid then
        cb(nil)
        return
    end

    local upgradeInfo = {
        boatId = boat.id,
        boatLabel = boat.boat_label,
        boatModel = boat.boat_model,
        currentUpgrades = {
            speed = boat.upgrade_speed,
            durability = boat.upgrade_durability,
            fuelConsumption = boat.upgrade_fuel,
        },
        usesFuel = Config.BoatModels[boat.boat_model] and Config.BoatModels[boat.boat_model].usesFuel or false,
        availableUpgrades = {},
    }

    for upgradeType, upgradeData in pairs(Config.Upgrades) do
        if upgradeType == 'fuelConsumption' and not upgradeInfo.usesFuel then
            goto continue
        end

        local currentLevel = 0
        if upgradeType == 'speed' then
            currentLevel = boat.upgrade_speed
        elseif upgradeType == 'durability' then
            currentLevel = boat.upgrade_durability
        elseif upgradeType == 'fuelConsumption' then
            currentLevel = boat.upgrade_fuel
        end

        local nextLevel = currentLevel + 1
        if nextLevel <= Config.MaxUpgradeLevel then
            upgradeInfo.availableUpgrades[upgradeType] = {
                label = upgradeData.label,
                icon = upgradeData.icon,
                description = upgradeData.description,
                currentLevel = currentLevel,
                nextLevel = nextLevel,
                maxLevel = Config.MaxUpgradeLevel,
                cost = upgradeData.levels[nextLevel].cost,
                bonus = upgradeData.levels[nextLevel].bonus,
                levelLabel = upgradeData.levels[nextLevel].label,
            }
        else
            upgradeInfo.availableUpgrades[upgradeType] = {
                label = upgradeData.label,
                icon = upgradeData.icon,
                description = upgradeData.description,
                currentLevel = currentLevel,
                nextLevel = nil,
                maxLevel = Config.MaxUpgradeLevel,
                cost = nil,
                bonus = nil,
                levelLabel = 'MAX LEVEL',
            }
        end

        ::continue::
    end

    cb(upgradeInfo)
end)

RSGCore.Functions.CreateCallback('db-boats:server:getCoalCount', function(source, cb)
    local Player = RSGCore.Functions.GetPlayer(source)
    if not Player then cb(0) return end

    local coalItem = Player.Functions.GetItemByName(Config.CoalItem)
    cb(coalItem and coalItem.amount or 0)
end)

RSGCore.Functions.CreateCallback('db-boats:server:openBoatStorage', function(source, cb, boatId)
    local Player = RSGCore.Functions.GetPlayer(source)
    if not Player then cb(false) return end

    local boat = DB.GetBoat(boatId)
    if not boat or boat.citizenid ~= Player.PlayerData.citizenid then
        cb(false)
        return
    end

    local modelData = Config.BoatModels[boat.boat_model]
    local category = modelData and modelData.category or 'small'
    local slots = Config.BoatStorage.slots[category] or 5
    local maxWeight = Config.BoatStorage.maxWeight[category] or 50000
    local storageId = 'boat_' .. boat.registration_number

    exports['rsg-inventory']:OpenInventory(source, storageId, {
        maxweight = maxWeight,
        slots = slots,
        label = boat.boat_label .. ' Storage (' .. boat.registration_number .. ')',
    })

    cb(true)
end)

-- ============================================================
-- EVENTS
-- ============================================================

RegisterNetEvent('db-boats:server:purchaseBoat', function(marinaId, boatModel)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    local marina = Config.Marinas[marinaId]
    if not marina then
        TriggerClientEvent('ox_lib:notify', src, { title = 'DB-Boats', description = 'Invalid marina.', type = 'error' })
        return
    end

    local modelAvailable = false
    for _, model in ipairs(marina.availableBoats) do
        if model == boatModel then
            modelAvailable = true
            break
        end
    end

    if not modelAvailable then
        TriggerClientEvent('ox_lib:notify', src, { title = 'DB-Boats', description = 'This boat is not available here.', type = 'error' })
        return
    end

    local modelData = Config.BoatModels[boatModel]
    if not modelData then return end

    if not GetPlayerMoney(Player, modelData.price) then
        TriggerClientEvent('ox_lib:notify', src, { title = 'DB-Boats', description = 'Not enough money. Need $' .. modelData.price, type = 'error' })
        return
    end

    if not RemovePlayerMoney(Player, modelData.price) then
        TriggerClientEvent('ox_lib:notify', src, { title = 'DB-Boats', description = 'Transaction failed.', type = 'error' })
        return
    end

    local registration = DB.GenerateRegistration()
    local ownerName = GetFullName(Player)
    local fuel = modelData.usesFuel and Config.DefaultFuel or 0.0

    local boatId = DB.CreateBoat(
        Player.PlayerData.citizenid, ownerName, boatModel, modelData.label,
        registration, marina.location, marinaId, fuel
    )

    if boatId then
        local certInfo = {
            boatId = boatId,
            registration = registration,
            boatLabel = modelData.label,
            owner = ownerName,
            purchaseLocation = marina.location,
        }

        exports['rsg-inventory']:AddItem(src, 'boat_certificate', 1, nil, certInfo)
        TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items['boat_certificate'], 'add')

        TriggerClientEvent('ox_lib:notify', src, {
            title = 'DB-Boats',
            description = 'Purchased ' .. modelData.label .. '! Reg: ' .. registration,
            type = 'success',
        })
    else
        AddPlayerMoney(Player, modelData.price)
        TriggerClientEvent('ox_lib:notify', src, { title = 'DB-Boats', description = 'Registration failed. Money refunded.', type = 'error' })
    end
end)

RegisterNetEvent('db-boats:server:sellBoat', function(boatId)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    local boat = DB.GetBoat(boatId)
    if not boat then
        TriggerClientEvent('ox_lib:notify', src, { title = 'DB-Boats', description = 'Boat not found.', type = 'error' })
        return
    end

    if boat.citizenid ~= Player.PlayerData.citizenid then
        TriggerClientEvent('ox_lib:notify', src, { title = 'DB-Boats', description = 'You don\'t own this boat.', type = 'error' })
        return
    end

    local isStored = boat.stored == 1 or boat.stored == true
    if not isStored then
        TriggerClientEvent('ox_lib:notify', src, { title = 'DB-Boats', description = 'Boat must be stored to sell.', type = 'error' })
        return
    end

    local modelData = Config.BoatModels[boat.boat_model]
    if not modelData then return end

    local sellPrice = modelData.sellPrice
    local upgradeRefundPercent = 0.5

    for upgradeType, upgradeData in pairs(Config.Upgrades) do
        local level = 0
        if upgradeType == 'speed' then level = boat.upgrade_speed
        elseif upgradeType == 'durability' then level = boat.upgrade_durability
        elseif upgradeType == 'fuelConsumption' then level = boat.upgrade_fuel
        end

        for i = 1, level do
            if upgradeData.levels[i] then
                sellPrice = sellPrice + math.floor(upgradeData.levels[i].cost * upgradeRefundPercent)
            end
        end
    end

    AddPlayerMoney(Player, sellPrice)

    local items = Player.Functions.GetItemsByName('boat_certificate')
    if items then
        for _, item in pairs(items) do
            if item.info and item.info.boatId == boatId then
                exports['rsg-inventory']:RemoveItem(src, 'boat_certificate', 1, item.slot)
                break
            end
        end
    end

    DB.DeleteBoat(boatId)

    TriggerClientEvent('ox_lib:notify', src, {
        title = 'DB-Boats',
        description = 'Sold ' .. boat.boat_label .. ' for $' .. sellPrice,
        type = 'success',
    })
end)

RegisterNetEvent('db-boats:server:spawnBoat', function(boatId, marinaId)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    local boat = DB.GetBoat(boatId)
    if not boat then
        TriggerClientEvent('ox_lib:notify', src, { title = 'DB-Boats', description = 'Boat not found.', type = 'error' })
        return
    end

    if boat.citizenid ~= Player.PlayerData.citizenid then
        TriggerClientEvent('ox_lib:notify', src, { title = 'DB-Boats', description = 'You don\'t own this boat.', type = 'error' })
        return
    end

    local isStored = boat.stored == 1 or boat.stored == true
    if not isStored then
        TriggerClientEvent('ox_lib:notify', src, { title = 'DB-Boats', description = 'This boat is already out on the water.', type = 'error' })
        return
    end

    DB.SetBoatSpawned(boatId)

    local stats = CalculateBoatStats(boat.boat_model, {
        speed = boat.upgrade_speed,
        durability = boat.upgrade_durability,
        fuelConsumption = boat.upgrade_fuel,
    })

    TriggerClientEvent('db-boats:client:spawnBoat', src, {
        boatId = boatId,
        model = boat.boat_model,
        label = boat.boat_label,
        registration = boat.registration_number,
        fuel = boat.fuel,
        durability = boat.durability_current,
        stats = stats,
        marinaId = marinaId,
        usesFuel = Config.BoatModels[boat.boat_model] and Config.BoatModels[boat.boat_model].usesFuel or false,
    })
end)

RegisterNetEvent('db-boats:server:storeBoat', function(boatId, marinaId, fuel, durability)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    local boat = DB.GetBoat(boatId)
    if not boat or boat.citizenid ~= Player.PlayerData.citizenid then return end

    DB.UpdateFuel(boatId, fuel or boat.fuel)
    DB.UpdateDurability(boatId, durability or boat.durability_current)
    DB.SetBoatStored(boatId, marinaId)

    TriggerClientEvent('ox_lib:notify', src, {
        title = 'DB-Boats',
        description = boat.boat_label .. ' stored at the marina.',
        type = 'success',
    })
end)

RegisterNetEvent('db-boats:server:upgradeBoat', function(boatId, upgradeType)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    local boat = DB.GetBoat(boatId)
    if not boat or boat.citizenid ~= Player.PlayerData.citizenid then return end

    local isStored = boat.stored == 1 or boat.stored == true
    if not isStored then
        TriggerClientEvent('ox_lib:notify', src, { title = 'DB-Boats', description = 'Boat must be stored to upgrade.', type = 'error' })
        return
    end

    local upgradeConfig = Config.Upgrades[upgradeType]
    if not upgradeConfig then return end

    local modelData = Config.BoatModels[boat.boat_model]
    if upgradeType == 'fuelConsumption' and modelData and not modelData.usesFuel then
        TriggerClientEvent('ox_lib:notify', src, { title = 'DB-Boats', description = 'This boat doesn\'t use fuel.', type = 'error' })
        return
    end

    local currentLevel = 0
    local dbField = upgradeType
    if upgradeType == 'speed' then
        currentLevel = boat.upgrade_speed
    elseif upgradeType == 'durability' then
        currentLevel = boat.upgrade_durability
    elseif upgradeType == 'fuelConsumption' then
        currentLevel = boat.upgrade_fuel
        dbField = 'fuel'
    end

    local nextLevel = currentLevel + 1
    if nextLevel > Config.MaxUpgradeLevel then
        TriggerClientEvent('ox_lib:notify', src, { title = 'DB-Boats', description = upgradeConfig.label .. ' is already maxed.', type = 'error' })
        return
    end

    local levelData = upgradeConfig.levels[nextLevel]
    if not levelData then return end

    if not GetPlayerMoney(Player, levelData.cost) then
        TriggerClientEvent('ox_lib:notify', src, { title = 'DB-Boats', description = 'Not enough money. Need $' .. levelData.cost, type = 'error' })
        return
    end

    if not RemovePlayerMoney(Player, levelData.cost) then
        TriggerClientEvent('ox_lib:notify', src, { title = 'DB-Boats', description = 'Transaction failed.', type = 'error' })
        return
    end

    if DB.UpgradeBoat(boatId, dbField, nextLevel) then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'DB-Boats',
            description = upgradeConfig.label .. ' upgraded to ' .. levelData.label,
            type = 'success',
        })
    else
        AddPlayerMoney(Player, levelData.cost)
        TriggerClientEvent('ox_lib:notify', src, { title = 'DB-Boats', description = 'Upgrade failed. Money refunded.', type = 'error' })
    end
end)

RegisterNetEvent('db-boats:server:refuelBoat', function(boatId, coalAmount)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    local boat = DB.GetBoat(boatId)
    if not boat or boat.citizenid ~= Player.PlayerData.citizenid then return end

    local modelData = Config.BoatModels[boat.boat_model]
    if not modelData or not modelData.usesFuel then
        TriggerClientEvent('ox_lib:notify', src, { title = 'DB-Boats', description = 'This boat doesn\'t use fuel.', type = 'error' })
        return
    end

    local coalItem = Player.Functions.GetItemByName(Config.CoalItem)
    local playerCoal = coalItem and coalItem.amount or 0

    if playerCoal <= 0 then
        TriggerClientEvent('ox_lib:notify', src, { title = 'DB-Boats', description = 'You don\'t have any coal.', type = 'error' })
        return
    end

    local fuelNeeded = Config.MaxFuel - boat.fuel
    if fuelNeeded <= 0 then
        TriggerClientEvent('ox_lib:notify', src, { title = 'DB-Boats', description = 'Fuel tank is full.', type = 'info' })
        return
    end

    local fuelPerCoal = Config.BoatRefuel.coalPerFuel
    local coalToUse = math.min(coalAmount or playerCoal, playerCoal)
    local fuelToAdd = math.min(coalToUse * fuelPerCoal, fuelNeeded)
    local actualCoalUsed = math.ceil(fuelToAdd / fuelPerCoal)

    exports['rsg-inventory']:RemoveItem(src, Config.CoalItem, actualCoalUsed)
    TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items[Config.CoalItem], 'remove')

    local newFuel = math.min(boat.fuel + fuelToAdd, Config.MaxFuel)
    DB.UpdateFuel(boatId, newFuel)

    TriggerClientEvent('ox_lib:notify', src, {
        title = 'DB-Boats',
        description = ('Used %d coal. Fuel: %.1f%%'):format(actualCoalUsed, newFuel),
        type = 'success',
    })

    TriggerClientEvent('db-boats:client:updateFuel', src, boatId, newFuel)
end)

RegisterNetEvent('db-boats:server:updateFuel', function(boatId, fuel)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    local boat = DB.GetBoat(boatId)
    if not boat or boat.citizenid ~= Player.PlayerData.citizenid then return end

    DB.UpdateFuel(boatId, math.max(0, fuel))
end)

RegisterNetEvent('db-boats:server:updateDurability', function(boatId, durability)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    local boat = DB.GetBoat(boatId)
    if not boat or boat.citizenid ~= Player.PlayerData.citizenid then return end

    DB.UpdateDurability(boatId, math.max(0, durability))
end)

RegisterNetEvent('db-boats:server:recoverBoat', function(boatId)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    local boat = DB.GetBoat(boatId)
    if not boat or boat.citizenid ~= Player.PlayerData.citizenid then return end

    DB.SetBoatStored(boatId, boat.marina_id)

    TriggerClientEvent('ox_lib:notify', src, {
        title = 'DB-Boats',
        description = boat.boat_label .. ' recovered to the slip.',
        type = 'success',
    })
end)

RegisterNetEvent('db-boats:server:viewCertificate', function(boatId)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    local boat = DB.GetBoat(boatId)
    if not boat then return end

    TriggerClientEvent('db-boats:client:showCertificate', src, {
        ownerName = boat.owner_name,
        registration = boat.registration_number,
        boatLabel = boat.boat_label,
        purchaseLocation = boat.purchase_location,
        upgrades = {
            speed = boat.upgrade_speed,
            durability = boat.upgrade_durability,
            fuelConsumption = boat.upgrade_fuel,
        },
        purchaseDate = boat.purchase_date,
        fuel = boat.fuel,
        durability = boat.durability_current,
    })
end)

-- Repair a boat
RegisterNetEvent('db-boats:server:repairBoat', function(boatId)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    local boat = DB.GetBoat(boatId)
    if not boat or boat.citizenid ~= Player.PlayerData.citizenid then return end

    local isStored = boat.stored == 1 or boat.stored == true
    if not isStored then
        TriggerClientEvent('ox_lib:notify', src, { title = 'DB-Boats', description = 'Boat must be stored to repair.', type = 'error' })
        return
    end

    local durability = boat.durability_current or 100
    if durability >= 100 then
        TriggerClientEvent('ox_lib:notify', src, { title = 'DB-Boats', description = 'This boat has no damage.', type = 'info' })
        return
    end

    -- Calculate repair cost
    local damagePoints = 100 - durability
    local repairCost = math.ceil(damagePoints * Config.Damage.repairCostPerPoint)

    if not GetPlayerMoney(Player, repairCost) then
        TriggerClientEvent('ox_lib:notify', src, { title = 'DB-Boats', description = 'Not enough money. Need $' .. repairCost, type = 'error' })
        return
    end

    if not RemovePlayerMoney(Player, repairCost) then
        TriggerClientEvent('ox_lib:notify', src, { title = 'DB-Boats', description = 'Transaction failed.', type = 'error' })
        return
    end

    -- Repair to full
    DB.UpdateDurability(boatId, 100.0)

    TriggerClientEvent('ox_lib:notify', src, {
        title = 'DB-Boats',
        description = boat.boat_label .. ' fully repaired for $' .. repairCost,
        type = 'success',
    })

    -- Update client if boat is currently spawned
    TriggerClientEvent('db-boats:client:updateDurability', src, boatId, 100.0)
end)

    -- Get repair kit count
RSGCore.Functions.CreateCallback('db-boats:server:getRepairKitCount', function(source, cb)
    local Player = RSGCore.Functions.GetPlayer(source)
    if not Player then cb(0) return end

    local item = Player.Functions.GetItemByName(Config.BoatRepair.repairItem)
    cb(item and item.amount or 0)
end)

-- On-boat repair with repair kits
RegisterNetEvent('db-boats:server:onBoatRepair', function(boatId, kitsUsed)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    local boat = DB.GetBoat(boatId)
    if not boat or boat.citizenid ~= Player.PlayerData.citizenid then return end

    -- Verify player has enough kits
    local item = Player.Functions.GetItemByName(Config.BoatRepair.repairItem)
    local playerKits = item and item.amount or 0

    if playerKits < kitsUsed then
        TriggerClientEvent('ox_lib:notify', src, { title = 'DB-Boats', description = 'Not enough repair kits.', type = 'error' })
        return
    end

    -- Calculate new durability
    local repairAmount = kitsUsed * Config.BoatRepair.repairAmount
    local newDurability = math.min(100.0, boat.durability_current + repairAmount)

    -- Remove repair kits
    exports['rsg-inventory']:RemoveItem(src, Config.BoatRepair.repairItem, kitsUsed)
    TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items[Config.BoatRepair.repairItem], 'remove')

    -- Update database
    DB.UpdateDurability(boatId, newDurability)

    -- Update client
    TriggerClientEvent('db-boats:client:updateDurability', src, boatId, newDurability)

    TriggerClientEvent('ox_lib:notify', src, {
        title = 'DB-Boats',
        description = ('Hull repaired to %.0f%% using %d repair kit%s'):format(newDurability, kitsUsed, kitsUsed > 1 and 's' or ''),
        type = 'success',
    })
end)

-- ============================================================
-- USEABLE ITEM
-- ============================================================

RSGCore.Functions.CreateUseableItem('boat_certificate', function(source, item)
    local Player = RSGCore.Functions.GetPlayer(source)
    if not Player then return end

    if item.info and item.info.boatId then
        TriggerEvent('db-boats:server:viewCertificate', item.info.boatId)
    end
end)

-- ============================================================
-- ADMIN COMMANDS
-- ============================================================

RegisterCommand('giveboat', function(source, args, rawCommand)
    local src = source
    if src ~= 0 then
        local Player = RSGCore.Functions.GetPlayer(src)
        if not Player or not RSGCore.Functions.HasPermission(src, 'admin') then return end
    end

    local targetId = tonumber(args[1])
    local boatModel = args[2]
    local marinaId = args[3] or 'blackwater_marina'

    if not targetId or not boatModel then
        if src == 0 then print('Usage: giveboat [playerID] [boatModel] [marinaId]') end
        return
    end

    local Target = RSGCore.Functions.GetPlayer(targetId)
    if not Target then return end

    local modelData = Config.BoatModels[boatModel]
    local marina = Config.Marinas[marinaId]
    if not modelData or not marina then return end

    local registration = DB.GenerateRegistration()
    local ownerName = GetFullName(Target)
    local fuel = modelData.usesFuel and Config.DefaultFuel or 0.0

    local boatId = DB.CreateBoat(
        Target.PlayerData.citizenid, ownerName, boatModel, modelData.label,
        registration, marina.location, marinaId, fuel
    )

    if boatId then
        local certInfo = {
            boatId = boatId,
            registration = registration,
            boatLabel = modelData.label,
            owner = ownerName,
            purchaseLocation = marina.location,
        }
        exports['rsg-inventory']:AddItem(targetId, 'boat_certificate', 1, nil, certInfo)
        TriggerClientEvent('rsg-inventory:client:ItemBox', targetId, RSGCore.Shared.Items['boat_certificate'], 'add')

        TriggerClientEvent('ox_lib:notify', targetId, {
            title = 'DB-Boats',
            description = 'You received a ' .. modelData.label .. '!',
            type = 'success',
        })
    end
end, false)
