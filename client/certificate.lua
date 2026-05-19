-- DB-Boats Certificate of Ownership NUI

RegisterNetEvent('db-boats:client:showCertificate', function(certData)
    if not certData then return end

    local upgradeText = {
        speed = certData.upgrades.speed or 0,
        durability = certData.upgrades.durability or 0,
        fuelConsumption = certData.upgrades.fuelConsumption or 0,
    }

    SendNUIMessage({
        action = 'showCertificate',
        data = {
            title = Config.Certificate.title,
            subtitle = Config.Certificate.subtitle,
            ownerName = certData.ownerName,
            registration = certData.registration,
            boatLabel = certData.boatLabel,
            purchaseLocation = certData.purchaseLocation,
            purchaseDate = certData.purchaseDate or 'Unknown',
            upgrades = {
                speed = {
                    level = upgradeText.speed,
                    maxLevel = Config.MaxUpgradeLevel,
                },
                durability = {
                    level = upgradeText.durability,
                    maxLevel = Config.MaxUpgradeLevel,
                },
                fuelEfficiency = {
                    level = upgradeText.fuelConsumption,
                    maxLevel = Config.MaxUpgradeLevel,
                },
            },
            fuel = certData.fuel,
            durabilityPercent = certData.durability,
        },
    })

    SetNuiFocus(true, true)
end)

RegisterNUICallback('closeCertificate', function(data, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)
