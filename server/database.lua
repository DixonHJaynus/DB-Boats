-- DB-Boats Server Database Functions

DB = {}

function DB.Init()
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `db_boats` (
            `id` INT(11) NOT NULL AUTO_INCREMENT,
            `citizenid` VARCHAR(50) NOT NULL,
            `owner_name` VARCHAR(100) NOT NULL,
            `boat_model` VARCHAR(50) NOT NULL,
            `boat_label` VARCHAR(100) NOT NULL,
            `registration_number` VARCHAR(20) NOT NULL UNIQUE,
            `purchase_location` VARCHAR(100) NOT NULL,
            `marina_id` VARCHAR(50) NOT NULL,
            `stored` TINYINT(1) NOT NULL DEFAULT 1,
            `fuel` FLOAT NOT NULL DEFAULT 100.0,
            `durability_current` FLOAT NOT NULL DEFAULT 100.0,
            `upgrade_speed` INT(11) NOT NULL DEFAULT 0,
            `upgrade_durability` INT(11) NOT NULL DEFAULT 0,
            `upgrade_fuel` INT(11) NOT NULL DEFAULT 0,
            `purchase_date` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            `last_used` TIMESTAMP NULL DEFAULT NULL,
            PRIMARY KEY (`id`),
            INDEX `idx_citizenid` (`citizenid`),
            INDEX `idx_registration` (`registration_number`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
end

function DB.GenerateRegistration()
    local chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
    local reg = 'BT-'

    for i = 1, 4 do
        local idx = math.random(1, #chars)
        reg = reg .. string.sub(chars, idx, idx)
    end
    reg = reg .. '-'
    for i = 1, 4 do
        local idx = math.random(1, #chars)
        reg = reg .. string.sub(chars, idx, idx)
    end

    local exists = MySQL.scalar.await('SELECT COUNT(*) FROM db_boats WHERE registration_number = ?', { reg })
    if exists and exists > 0 then
        return DB.GenerateRegistration()
    end

    return reg
end

function DB.CreateBoat(citizenid, ownerName, boatModel, boatLabel, registration, purchaseLocation, marinaId, fuel)
    local id = MySQL.insert.await([[
        INSERT INTO db_boats (citizenid, owner_name, boat_model, boat_label, registration_number, purchase_location, marina_id, stored, fuel, durability_current)
        VALUES (?, ?, ?, ?, ?, ?, ?, 1, ?, 100.0)
    ]], {
        citizenid, ownerName, boatModel, boatLabel, registration, purchaseLocation, marinaId, fuel or Config.DefaultFuel
    })
    return id
end

function DB.GetPlayerBoats(citizenid)
    local boats = MySQL.query.await('SELECT * FROM db_boats WHERE citizenid = ?', { citizenid })
    return boats or {}
end

function DB.GetBoat(boatId)
    local boat = MySQL.single.await('SELECT * FROM db_boats WHERE id = ?', { boatId })
    return boat
end

function DB.GetBoatByRegistration(registration)
    local boat = MySQL.single.await('SELECT * FROM db_boats WHERE registration_number = ?', { registration })
    return boat
end

function DB.GetStoredBoats(citizenid, marinaId)
    local boats = MySQL.query.await(
        'SELECT * FROM db_boats WHERE citizenid = ? AND marina_id = ? AND stored = 1',
        { citizenid, marinaId }
    )
    return boats or {}
end

function DB.GetAllStoredBoats(citizenid)
    local boats = MySQL.query.await(
        'SELECT * FROM db_boats WHERE citizenid = ? AND stored = 1',
        { citizenid }
    )
    return boats or {}
end

function DB.SetBoatSpawned(boatId)
    MySQL.update.await('UPDATE db_boats SET stored = 0, last_used = NOW() WHERE id = ?', { boatId })
end

function DB.SetBoatStored(boatId, marinaId)
    MySQL.update.await('UPDATE db_boats SET stored = 1, marina_id = ? WHERE id = ?', { marinaId, boatId })
end

function DB.UpdateFuel(boatId, fuel)
    MySQL.update.await('UPDATE db_boats SET fuel = ? WHERE id = ?', { fuel, boatId })
end

function DB.UpdateDurability(boatId, durability)
    MySQL.update.await('UPDATE db_boats SET durability_current = ? WHERE id = ?', { durability, boatId })
end

function DB.UpgradeBoat(boatId, upgradeType, level)
    local column = 'upgrade_' .. upgradeType
    local validColumns = {
        upgrade_speed = true,
        upgrade_durability = true,
        upgrade_fuel = true,
    }
    if not validColumns[column] then
        return false
    end
    MySQL.update.await('UPDATE db_boats SET ' .. column .. ' = ? WHERE id = ?', { level, boatId })
    return true
end

function DB.DeleteBoat(boatId)
    MySQL.query.await('DELETE FROM db_boats WHERE id = ?', { boatId })
end

function DB.TransferBoat(boatId, newCitizenId, newOwnerName)
    MySQL.update.await(
        'UPDATE db_boats SET citizenid = ?, owner_name = ? WHERE id = ?',
        { newCitizenId, newOwnerName, boatId }
    )
end

function DB.CountPlayerBoats(citizenid)
    local count = MySQL.scalar.await('SELECT COUNT(*) FROM db_boats WHERE citizenid = ?', { citizenid })
    return count or 0
end
