-- DB-Boats Client Menus

local RSGCore = exports['rsg-core']:GetCoreObject()

-- ============================================================
-- MAIN MARINA MENU
-- ============================================================

function OpenMarinaMenu(marinaId)
    local marina = Config.Marinas[marinaId]
    if not marina then return end

    local currentBoat = exports[GetCurrentResourceName()]:GetCurrentBoat()

    local options = {
        {
            title = '🛒 Purchase a Boat',
            description = 'Browse boats available for purchase',
            icon = 'fa-solid fa-cart-shopping',
            onSelect = function() OpenPurchaseMenu(marinaId) end,
        },
        {
            title = '⬆️ Upgrade Boat',
            description = 'Improve your boat\'s performance',
            icon = 'fa-solid fa-wrench',
            onSelect = function() OpenUpgradeSelectMenu(marinaId) end,
        },
        {
            title = '🔧 Repair Boat',
            description = 'Repair hull damage on a stored boat',
            icon = 'fa-solid fa-hammer',
            onSelect = function() OpenRepairMenu(marinaId) end,
        },
        {
            title = '💰 Sell Boat',
            description = 'Sell one of your stored boats',
            icon = 'fa-solid fa-dollar-sign',
            onSelect = function() OpenSellMenu(marinaId) end,
        },
        {
            title = '📤 Retrieve / Recover Boat',
            description = 'Take a boat out from the slip',
            icon = 'fa-solid fa-ship',
            onSelect = function() OpenRetrieveMenu(marinaId) end,
        },
        {
            title = '📋 View My Boats',
            description = 'View all your registered boats',
            icon = 'fa-solid fa-list',
            onSelect = function() OpenMyBoatsMenu() end,
        },
    }

    if currentBoat then
        options[#options + 1] = {
            title = '📥 Store Current Boat',
            description = 'Store ' .. currentBoat.label .. ' at this marina',
            icon = 'fa-solid fa-warehouse',
            onSelect = function() StoreCurrentBoat(marinaId) end,
        }

        if currentBoat.usesFuel then
            options[#options + 1] = {
                title = '⛽ Refuel Boat',
                description = ('Current fuel: %.1f%% — Add coal to refuel'):format(currentBoat.fuel),
                icon = 'fa-solid fa-fire',
                onSelect = function() OpenRefuelMenu(currentBoat.boatId) end,
            }
        end
    end

    lib.registerContext({
        id = 'db_boats_main_menu',
        title = '⚓ ' .. marina.label,
        options = options,
    })

    lib.showContext('db_boats_main_menu')
end

-- ============================================================
-- PURCHASE MENU
-- ============================================================

function OpenPurchaseMenu(marinaId)
    local marina = Config.Marinas[marinaId]

    RSGCore.Functions.TriggerCallback('db-boats:server:getAvailableBoats', function(boats)
        if not boats or #boats == 0 then
            lib.notify({ title = 'DB-Boats', description = 'No boats available here.', type = 'info' })
            return
        end

        local options = {}

        for _, boat in ipairs(boats) do
            options[#options + 1] = {
                title = boat.label .. '  —  $' .. boat.price,
                description = boat.description,
                icon = 'fa-solid fa-ship',
                metadata = {
                    { label = 'Category',   value = boat.category:gsub('^%l', string.upper) },
                    { label = 'Speed',      value = tostring(boat.baseStats.speed) },
                    { label = 'Durability', value = tostring(boat.baseStats.durability) },
                    { label = 'Fuel',       value = boat.usesFuel and 'Coal Powered' or 'Manual' },
                },
                onSelect = function()
                    ConfirmPurchase(marinaId, boat)
                end,
            }
        end

        lib.registerContext({
            id = 'db_boats_purchase',
            title = '🛒 Purchase a Boat — ' .. marina.label,
            menu = 'db_boats_main_menu',
            options = options,
        })

        lib.showContext('db_boats_purchase')
    end, marinaId)
end

function ConfirmPurchase(marinaId, boat)
    local alert = lib.alertDialog({
        header = 'Confirm Purchase',
        content = ('Purchase a **%s** for **$%d**?\n\n— Speed: %d\n— Durability: %d\n— Fuel: %s'):format(
            boat.label, boat.price, boat.baseStats.speed, boat.baseStats.durability,
            boat.usesFuel and 'Coal Powered' or 'Manual'
        ),
        centered = true,
        cancel = true,
    })

    if alert == 'confirm' then
        TriggerServerEvent('db-boats:server:purchaseBoat', marinaId, boat.model)
    end
end

-- ============================================================
-- SELL MENU
-- ============================================================

function OpenSellMenu(marinaId)
    RSGCore.Functions.TriggerCallback('db-boats:server:getStoredBoats', function(boats)
        if not boats or #boats == 0 then
            lib.notify({ title = 'DB-Boats', description = 'No stored boats to sell at this marina.', type = 'info' })
            return
        end

        local options = {}

        for _, boat in ipairs(boats) do
            local sellPrice = CalculateSellPrice(boat)

            options[#options + 1] = {
                title = boat.boat_label .. '  —  Sell for $' .. sellPrice,
                description = 'Reg: ' .. boat.registration_number,
                icon = 'fa-solid fa-dollar-sign',
                metadata = {
                    { label = 'Registration',       value = boat.registration_number },
                    { label = 'Speed Upgrade',      value = boat.upgrade_speed .. '/' .. Config.MaxUpgradeLevel },
                    { label = 'Durability Upgrade', value = boat.upgrade_durability .. '/' .. Config.MaxUpgradeLevel },
                },
                onSelect = function()
                    ConfirmSell(boat, sellPrice)
                end,
            }
        end

        lib.registerContext({
            id = 'db_boats_sell',
            title = '💰 Sell a Boat',
            menu = 'db_boats_main_menu',
            options = options,
        })

        lib.showContext('db_boats_sell')
    end, marinaId)
end

function CalculateSellPrice(boat)
    local modelData = Config.BoatModels[boat.boat_model]
    local price = modelData and modelData.sellPrice or 0

    for upgradeType, upgradeData in pairs(Config.Upgrades) do
        local level = 0
        if upgradeType == 'speed' then level = boat.upgrade_speed
        elseif upgradeType == 'durability' then level = boat.upgrade_durability
        elseif upgradeType == 'fuelConsumption' then level = boat.upgrade_fuel
        end

        for i = 1, level do
            if upgradeData.levels[i] then
                price = price + math.floor(upgradeData.levels[i].cost * 0.5)
            end
        end
    end

    return price
end

function ConfirmSell(boat, sellPrice)
    local alert = lib.alertDialog({
        header = 'Confirm Sale',
        content = ('Sell your **%s** (Reg: %s) for **$%d**?\n\nThis cannot be undone!'):format(
            boat.boat_label, boat.registration_number, sellPrice
        ),
        centered = true,
        cancel = true,
    })

    if alert == 'confirm' then
        TriggerServerEvent('db-boats:server:sellBoat', boat.id)
    end
end

-- ============================================================
-- REPAIR MENU
-- ============================================================

function OpenRepairMenu(marinaId)
    RSGCore.Functions.TriggerCallback('db-boats:server:getStoredBoats', function(boats)
        if not boats or #boats == 0 then
            lib.notify({ title = 'DB-Boats', description = 'No stored boats to repair.', type = 'info' })
            return
        end

        local options = {}

        for _, boat in ipairs(boats) do
            local durability = boat.durability_current or 100
            local damagePoints = 100 - durability
            local repairCost = math.ceil(damagePoints * Config.Damage.repairCostPerPoint)

            local statusText = ''
            local iconText = 'fa-solid fa-ship'

            if durability >= 100 then
                statusText = '✅ No damage'
            elseif durability > Config.Damage.thresholds.warning then
                statusText = 'Minor scratches'
            elseif durability > Config.Damage.thresholds.caution then
                statusText = '⚠️ Moderate damage'
                iconText = 'fa-solid fa-triangle-exclamation'
            elseif durability > Config.Damage.thresholds.critical then
                statusText = '⚠️ Heavy damage'
                iconText = 'fa-solid fa-triangle-exclamation'
            elseif durability > Config.Damage.thresholds.disabled then
                statusText = '🚨 Critical damage'
                iconText = 'fa-solid fa-circle-exclamation'
            else
                statusText = '🚨 DISABLED — Cannot sail'
                iconText = 'fa-solid fa-circle-xmark'
            end

            options[#options + 1] = {
                title = boat.boat_label,
                description = statusText .. (repairCost > 0 and ('  —  Repair: $' .. repairCost) or ''),
                icon = iconText,
                disabled = durability >= 100,
                metadata = {
                    { label = 'Registration', value = boat.registration_number },
                    { label = 'Hull',         value = ('%.0f%%'):format(durability) },
                    { label = 'Repair Cost',  value = repairCost > 0 and ('$' .. repairCost) or 'None' },
                },
                onSelect = function()
                    if durability < 100 then
                        ConfirmRepair(boat, repairCost)
                    end
                end,
            }
        end

        lib.registerContext({
            id = 'db_boats_repair',
            title = '🔧 Repair Boat',
            menu = 'db_boats_main_menu',
            options = options,
        })

        lib.showContext('db_boats_repair')
    end, marinaId)
end

function ConfirmRepair(boat, repairCost)
    local alert = lib.alertDialog({
        header = 'Confirm Repair',
        content = ('Repair **%s** to full hull integrity for **$%d**?\n\nCurrent hull: %.0f%%'):format(
            boat.boat_label,
            repairCost,
            boat.durability_current or 100
        ),
        centered = true,
        cancel = true,
    })

    if alert == 'confirm' then
        TriggerServerEvent('db-boats:server:repairBoat', boat.id)
    end
end

-- ============================================================
-- RETRIEVE / RECOVER MENU
-- ============================================================

function OpenRetrieveMenu(marinaId)
    local currentBoat = exports[GetCurrentResourceName()]:GetCurrentBoat()
    if currentBoat then
        lib.notify({ title = 'DB-Boats', description = 'Store your current boat first.', type = 'warning' })
        return
    end

    RSGCore.Functions.TriggerCallback('db-boats:server:getPlayerBoats', function(boats)
        if not boats or #boats == 0 then
            lib.notify({ title = 'DB-Boats', description = 'No boats found.', type = 'info' })
            return
        end

        local options = {}

        for _, boat in ipairs(boats) do
            if boat.marina_id == marinaId then
                local modelData = Config.BoatModels[boat.boat_model]
                local fuelText = ''
                if modelData and modelData.usesFuel then
                    fuelText = ('Fuel: %.1f%%'):format(boat.fuel)
                end

                local isStored = boat.stored == 1 or boat.stored == true
                local titleText = boat.boat_label
                local iconText = 'fa-solid fa-ship'

                if not isStored then
                    titleText = '⚠️ Recover ' .. boat.boat_label
                    iconText = 'fa-solid fa-life-ring'
                end

                -- Show hull status in description
                local hullText = ''
                local durability = boat.durability_current or 100
                if durability < 100 then
                    hullText = ('  |  Hull: %.0f%%'):format(durability)
                end

                options[#options + 1] = {
                    title = titleText,
                    description = 'Reg: ' .. boat.registration_number .. (fuelText ~= '' and ('  |  ' .. fuelText) or '') .. hullText,
                    icon = iconText,
                    metadata = {
                        { label = 'Status',       value = isStored and 'Stored' or 'Needs Recovery' },
                        { label = 'Registration', value = boat.registration_number },
                        { label = 'Hull',         value = ('%.0f%%'):format(durability) },
                        { label = 'Speed Lvl',    value = boat.upgrade_speed .. '/' .. Config.MaxUpgradeLevel },
                        { label = 'Dura. Lvl',    value = boat.upgrade_durability .. '/' .. Config.MaxUpgradeLevel },
                    },
                    onSelect = function()
                        if not isStored then
                            TriggerServerEvent('db-boats:server:recoverBoat', boat.id)
                        else
                            TriggerServerEvent('db-boats:server:spawnBoat', boat.id, marinaId)
                        end
                    end,
                }
            end
        end

        if #options == 0 then
            lib.notify({ title = 'DB-Boats', description = 'No boats at this marina.', type = 'info' })
            return
        end

        lib.registerContext({
            id = 'db_boats_retrieve',
            title = '📤 Retrieve Boat',
            menu = 'db_boats_main_menu',
            options = options,
        })

        lib.showContext('db_boats_retrieve')
    end)
end

-- ============================================================
-- UPGRADE MENUS
-- ============================================================

function OpenUpgradeSelectMenu(marinaId)
    RSGCore.Functions.TriggerCallback('db-boats:server:getStoredBoats', function(boats)
        if not boats or #boats == 0 then
            lib.notify({ title = 'DB-Boats', description = 'No stored boats to upgrade.', type = 'info' })
            return
        end

        local options = {}

        for _, boat in ipairs(boats) do
            options[#options + 1] = {
                title = boat.boat_label,
                description = 'Reg: ' .. boat.registration_number,
                icon = 'fa-solid fa-ship',
                onSelect = function()
                    OpenUpgradeMenu(boat.id, marinaId)
                end,
            }
        end

        lib.registerContext({
            id = 'db_boats_upgrade_select',
            title = '⬆️ Select Boat to Upgrade',
            menu = 'db_boats_main_menu',
            options = options,
        })

        lib.showContext('db_boats_upgrade_select')
    end, marinaId)
end

function OpenUpgradeMenu(boatId, marinaId)
    RSGCore.Functions.TriggerCallback('db-boats:server:getUpgradeInfo', function(info)
        if not info then
            lib.notify({ title = 'DB-Boats', description = 'Could not load upgrade info.', type = 'error' })
            return
        end

        local options = {}

        for upgradeType, data in pairs(info.availableUpgrades) do
            local maxed = data.nextLevel == nil

            local desc = data.description .. '\n'
            if maxed then
                desc = desc .. '✅ MAX LEVEL'
            else
                desc = desc .. ('Level %d → %d  |  Cost: $%d'):format(data.currentLevel, data.nextLevel, data.cost)
            end

            options[#options + 1] = {
                title = data.label,
                description = desc,
                icon = data.icon,
                disabled = maxed,
                metadata = {
                    { label = 'Current', value = data.currentLevel .. '/' .. data.maxLevel },
                    { label = 'Next',    value = maxed and 'MAXED' or data.levelLabel },
                    { label = 'Cost',    value = maxed and '—' or ('$' .. data.cost) },
                },
                onSelect = function()
                    if not maxed then
                        ConfirmUpgrade(boatId, upgradeType, data, marinaId)
                    end
                end,
            }
        end

        lib.registerContext({
            id = 'db_boats_upgrade',
            title = '⬆️ Upgrades — ' .. info.boatLabel,
            menu = 'db_boats_upgrade_select',
            options = options,
        })

        lib.showContext('db_boats_upgrade')
    end, boatId)
end

function ConfirmUpgrade(boatId, upgradeType, data, marinaId)
    local alert = lib.alertDialog({
        header = 'Confirm Upgrade',
        content = ('Upgrade **%s** to **%s** for **$%d**?'):format(data.label, data.levelLabel, data.cost),
        centered = true,
        cancel = true,
    })

    if alert == 'confirm' then
        TriggerServerEvent('db-boats:server:upgradeBoat', boatId, upgradeType)
        Wait(500)
        OpenUpgradeMenu(boatId, marinaId)
    end
end

-- ============================================================
-- MY BOATS MENU
-- ============================================================

function OpenMyBoatsMenu()
    RSGCore.Functions.TriggerCallback('db-boats:server:getPlayerBoats', function(boats)
        if not boats or #boats == 0 then
            lib.notify({ title = 'DB-Boats', description = 'You don\'t own any boats.', type = 'info' })
            return
        end

        local options = {}

        for _, boat in ipairs(boats) do
            local isStored = boat.stored == 1 or boat.stored == true
            local status = isStored and '📥 Stored' or '🌊 On Water'
            local loc = Config.Marinas[boat.marina_id] and Config.Marinas[boat.marina_id].label or 'Unknown'

            options[#options + 1] = {
                title = boat.boat_label .. '  ' .. status,
                description = 'Reg: ' .. boat.registration_number,
                icon = 'fa-solid fa-ship',
                metadata = {
                    { label = 'Registration', value = boat.registration_number },
                    { label = 'Status',       value = isStored and 'Stored' or 'On Water' },
                    { label = 'Location',     value = loc },
                    { label = 'Hull',         value = ('%.0f%%'):format(boat.durability_current or 100) },
                    { label = 'Purchased',    value = boat.purchase_location },
                    { label = 'Speed Lvl',    value = boat.upgrade_speed .. '/' .. Config.MaxUpgradeLevel },
                    { label = 'Dura. Lvl',    value = boat.upgrade_durability .. '/' .. Config.MaxUpgradeLevel },
                    { label = 'Fuel Lvl',     value = boat.upgrade_fuel .. '/' .. Config.MaxUpgradeLevel },
                },
                onSelect = function()
                    TriggerServerEvent('db-boats:server:viewCertificate', boat.id)
                end,
            }
        end

        lib.registerContext({
            id = 'db_boats_myboats',
            title = '📋 My Boats',
            menu = 'db_boats_main_menu',
            options = options,
        })

        lib.showContext('db_boats_myboats')
    end)
end

-- ============================================================
-- REFUEL MENU (Marina)
-- ============================================================

function OpenRefuelMenu(boatId)
    local currentBoat = exports[GetCurrentResourceName()]:GetCurrentBoat()

    if not currentBoat or not currentBoat.usesFuel then
        lib.notify({ title = 'DB-Boats', description = 'This boat doesn\'t use fuel.', type = 'info' })
        return
    end

    RSGCore.Functions.TriggerCallback('db-boats:server:getCoalCount', function(coalCount)
        if coalCount <= 0 then
            lib.notify({ title = 'DB-Boats', description = 'You don\'t have any coal.', type = 'error' })
            return
        end

        local fuelNeeded = Config.MaxFuel - currentBoat.fuel
        if fuelNeeded <= 0 then
            lib.notify({ title = 'DB-Boats', description = 'Fuel tank is already full.', type = 'info' })
            return
        end

        local maxCoal = math.ceil(fuelNeeded / Config.BoatRefuel.coalPerFuel)
        local useAmount = math.min(coalCount, maxCoal)

        local input = lib.inputDialog('⛽ Refuel Boat', {
            {
                type = 'number',
                label = ('Coal to use  (Have: %d  |  Can use: %d)'):format(coalCount, useAmount),
                description = ('Each coal = %.0f fuel'):format(Config.BoatRefuel.coalPerFuel),
                default = useAmount,
                min = 1,
                max = useAmount,
                required = true,
            },
        })

        if input and input[1] then
            TriggerServerEvent('db-boats:server:refuelBoat', boatId, tonumber(input[1]))
        end
    end)
end
