Config = {}

-- ============================================================
-- GENERAL SETTINGS
-- ============================================================

Config.Debug = false
Config.UseCoalFuel = true
Config.CoalItem = 'coal'
Config.CoalPerUnit = 1
Config.FuelCheckInterval = 30000
Config.DefaultFuel = 100.0
Config.MaxFuel = 100.0
Config.MoneyType = 'cash'

-- ============================================================
-- NOTIFICATIONS
-- ============================================================

Config.Notifications = {
    duration = 5000,
    position = 'top-right',
}

-- ============================================================
-- CERTIFICATE OF OWNERSHIP
-- ============================================================

Config.Certificate = {
    title = 'Certificate of Boat Ownership',
    subtitle = 'Official Maritime Registration',
}

-- ============================================================
-- ANCHOR SYSTEM
-- ============================================================

Config.Anchor = {
    autoAnchorOnExit = false,
}

-- ============================================================
-- BOAT STORAGE (Inventory)
-- ============================================================

Config.BoatStorage = {
    enabled = true,
    slots = {
        small  = 5,
        medium = 10,
        large  = 15,
    },
    maxWeight = {
        small  = 50000,
        medium = 100000,
        large  = 150000,
    },
}

-- ============================================================
-- ON-BOAT REFUEL
-- ============================================================

Config.BoatRefuel = {
    enabled = true,
    coalPerFuel = 10.0,
    requireAnchored = true,
}

-- ============================================================
-- BOAT MODELS
-- ============================================================

Config.BoatModels = {
    ['canoeTreeTrunk'] = {
        label = 'Tree Trunk Canoe',
        model = 'canoeTreeTrunk',
        price = 150,
        sellPrice = 20,
        category = 'small',
        usesFuel = false,
        baseStats = {
            speed = 40,
            durability = 40,
            fuelConsumption = 0,
        },
        description = 'A lightweight canoe, fast but fragile.',
    },
    ['canoe'] = {
        label = 'Canoe',
        model = 'canoe',
        price = 250,
        sellPrice = 20,
        category = 'small',
        usesFuel = false,
        baseStats = {
            speed = 40,
            durability = 40,
            fuelConsumption = 0,
        },
        description = 'A lightweight canoe, fast but fragile.',
    },
    ['pirogue'] = {
        label = 'Pirogue',
        model = 'pirogue',
        price = 45,
        sellPrice = 22,
        category = 'small',
        usesFuel = false,
        baseStats = {
            speed = 38,
            durability = 45,
            fuelConsumption = 0,
        },
        description = 'A traditional pirogue for bayou navigation.',
    },
    ['pirogue2'] = {
        label = 'Pirogue #2',
        model = 'pirogue2',
        price = 45,
        sellPrice = 22,
        category = 'small',
        usesFuel = false,
        baseStats = {
            speed = 38,
            durability = 45,
            fuelConsumption = 0,
        },
        description = 'A traditional pirogue for bayou navigation.',
    },
    ['rowboat'] = {
        label = 'Rowboat',
        model = 'rowboat',
        price = 50,
        sellPrice = 25,
        category = 'small',
        usesFuel = false,
        baseStats = {
            speed = 30,
            durability = 60,
            fuelConsumption = 0,
        },
        description = 'A simple wooden rowboat. No engine required.',
    },
    ['rowboatSwamp'] = {
        label = 'Swamp Rowboat',
        model = 'rowboatSwamp',
        price = 50,
        sellPrice = 25,
        category = 'small',
        usesFuel = false,
        baseStats = {
            speed = 30,
            durability = 60,
            fuelConsumption = 0,
        },
        description = 'A swampy rowboat. I wonder what that smell is...',
    },
    ['rowboatSwamp02'] = {
        label = 'Swamp Rowboat #2',
        model = 'rowboatSwamp',
        price = 50,
        sellPrice = 25,
        category = 'small',
        usesFuel = false,
        baseStats = {
            speed = 30,
            durability = 60,
            fuelConsumption = 0,
        },
        description = 'A swampy rowboat. Is that gator guts I see on the deck??',
    },
    ['skiff'] = {
        label = 'Skiff',
        model = 'skiff',
        price = 100,
        sellPrice = 50,
        category = 'small',
        usesFuel = false,
        baseStats = {
            speed = 35,
            durability = 65,
            fuelConsumption = 0,
        },
        description = 'A flat-bottomed skiff, great for shallow waters.',
    },
    ['boatsteam02x'] = {
        label = 'Steamboat',
        model = 'boatsteam02x',
        price = 500,
        sellPrice = 250,
        category = 'large',
        usesFuel = true,
        baseStats = {
            speed = 55,
            durability = 80,
            fuelConsumption = 2.0,
        },
        description = 'A coal-powered steamboat. Fast and durable.',
    },
    ['keelboat'] = {
        label = 'Keelboat',
        model = 'keelboat',
        price = 350,
        sellPrice = 175,
        category = 'medium',
        usesFuel = true,
        baseStats = {
            speed = 50,
            durability = 75,
            fuelConsumption = 1.5,
        },
        description = 'A sturdy keelboat suitable for river travel.',
    },
}

-- ============================================================
-- UPGRADE CONFIGURATION
-- ============================================================

Config.MaxUpgradeLevel = 5

Config.Upgrades = {
    speed = {
        label = 'Speed',
        icon = 'fa-solid fa-gauge-high',
        description = 'Improve the top speed of your boat.',
        levels = {
            [1] = { cost = 75,  bonus = 5,  label = 'Level 1 - Polished Hull' },
            [2] = { cost = 150, bonus = 10, label = 'Level 2 - Streamlined Keel' },
            [3] = { cost = 300, bonus = 15, label = 'Level 3 - Reinforced Rudder' },
            [4] = { cost = 500, bonus = 20, label = 'Level 4 - Advanced Rigging' },
            [5] = { cost = 800, bonus = 25, label = 'Level 5 - Master Craftwork' },
        },
    },
    durability = {
        label = 'Durability',
        icon = 'fa-solid fa-shield',
        description = 'Reinforce your boat to withstand more damage.',
        levels = {
            [1] = { cost = 60,  bonus = 10, label = 'Level 1 - Patched Hull' },
            [2] = { cost = 120, bonus = 20, label = 'Level 2 - Iron Plating' },
            [3] = { cost = 250, bonus = 30, label = 'Level 3 - Steel Reinforcement' },
            [4] = { cost = 400, bonus = 40, label = 'Level 4 - Double Hull' },
            [5] = { cost = 700, bonus = 50, label = 'Level 5 - Ironclad' },
        },
    },
    fuelConsumption = {
        label = 'Fuel Efficiency',
        icon = 'fa-solid fa-fire',
        description = 'Reduce coal consumption for fuel-powered boats.',
        levels = {
            [1] = { cost = 50,  bonus = -0.2, label = 'Level 1 - Tuned Boiler' },
            [2] = { cost = 100, bonus = -0.4, label = 'Level 2 - Efficient Firebox' },
            [3] = { cost = 200, bonus = -0.6, label = 'Level 3 - Advanced Steam System' },
            [4] = { cost = 350, bonus = -0.8, label = 'Level 4 - Precision Engineering' },
            [5] = { cost = 600, bonus = -1.0, label = 'Level 5 - Master Steam Works' },
        },
    },
}

-- ============================================================
-- MARINA LOCATIONS
-- ============================================================
-- All coordinates are PLACEHOLDERS — replace with real in-game coords.
-- Spawn points MUST be in water deep enough for boats.

Config.Marinas = {

    ['blackwater_marina'] = {
        label    = 'Blackwater Marina',
        location = 'Blackwater',

        clerk = {
            coords   = vector4(-722.3185, -1274.0746, 43.5769, 91.0929),
            model    = 'A_M_M_FAMILYTRAVELERS_COOL_01',
            scenario = 'WORLD_HUMAN_STAND_IMPATIENT',
        },

        spawn = {
            coords = vector4(-713.0495, -1273.4550, 40.1853, 183.2831),
        },

        blip = {
            coords = vector3(-722.3185, -1274.0746, 43.5769),
            sprite = 0xB04FF40A,
            scale  = 0.22,
            label  = 'Blackwater Marina',
        },

        availableBoats = {
            'canoeTreeTrunk', 'canoe', 'pirogue', 'pirogue2', 'rowboat', 'rowboatSwamp', 'rowboatSwamp02', 'skiff', 'keelboat', 'boatsteam02x'
        },
    },

    -- ['rhodes_marina'] = {
    --     label    = 'Rhodes Dock',
    --     location = 'Rhodes',
    -- 
    --     clerk = {
    --         coords   = vector4(1330.0, -1275.0, 43.0, 270.0),
    --         model    = 'A_M_M_FAMILYTRAVELERS_COOL_01',
    --         scenario = 'WORLD_HUMAN_STAND_IMPATIENT',
    --     },

    --     spawn = {
    --         coords = vector4(1345.0, -1285.0, 41.0, 180.0),
    --     },
    -- 
    --     blip = {
    --         coords = vector3(1330.0, -1275.0, 43.0),
    --         sprite = 0xB04FF40A,
    --         scale  = 0.22,
    --         label  = 'Rhodes Dock',
    --     },

    --     availableBoats = {
    --         'rowboat', 'skiff', 'pirogue', 'canoe', 'keelboat'
    --     },
    -- },

    -- ['lagras_marina'] = {
    --     label    = 'Lagras Landing',
    --     location = 'Lagras',
    -- 
    --     clerk = {
    --         coords   = vector4(2120.0, -580.0, 42.0, 90.0),
    --         model    = 'A_M_M_FAMILYTRAVELERS_COOL_01',
    --         scenario = 'WORLD_HUMAN_STAND_IMPATIENT',
    --     },
    -- 
    --     spawn = {
    --         coords = vector4(2130.0, -590.0, 40.0, 180.0),
    --     },
    -- 
    --     blip = {
    --         coords = vector3(2120.0, -580.0, 42.0),
    --         sprite = 0xB04FF40A,
    --         scale  = 0.22,
    --         label  = 'Lagras Landing',
    --     },
    -- 
    --     availableBoats = {
    --         'rowboat', 'pirogue', 'canoe', 'skiff'
    --     },
    -- },

    -- ['annesburg_marina'] = {
    --     label    = 'Annesburg Docks',
    --     location = 'Annesburg',
    -- 
    --     clerk = {
    --         coords   = vector4(2925.0, 1280.0, 43.0, 0.0),
    --         model    = 'A_M_M_FAMILYTRAVELERS_COOL_01',
    --         scenario = 'WORLD_HUMAN_STAND_IMPATIENT',
    --     },
    --     spawn = {
    --         coords = vector4(2935.0, 1290.0, 41.0, 90.0),
    --     },
    -- 
    --     blip = {
    --         coords = vector3(2925.0, 1280.0, 43.0),
    --         sprite = 0xB04FF40A,
    --         scale  = 0.22,
    --         label  = 'Annesburg Docks',
    --     },
    -- 
    --     availableBoats = {
    --         'rowboat', 'skiff', 'keelboat', 'steamboat', 'tugboat'
    --     },
    -- },

}

-- ============================================================
-- DAMAGE SYSTEM
-- ============================================================

Config.Damage = {
    enabled = true,

    -- Speed reduction based on durability
    -- At 100% durability = full speed
    -- At 0% durability = speed reduced by this percentage
    maxSpeedReduction = 0.50,           -- 50% slower at 0 durability

    -- Durability thresholds and effects
    thresholds = {
        warning    = 75.0,              -- First warning notification
        caution    = 50.0,              -- Second warning, minor speed loss
        critical   = 25.0,              -- Severe warning, major speed loss
        disabled   = 0.0,               -- Boat cannot move
    },

    -- How much damage reduction each durability upgrade level gives (percentage)
    -- Level 1 = 10% less damage taken, Level 5 = 50% less damage taken
    upgradeReduction = {
        [1] = 0.10,
        [2] = 0.20,
        [3] = 0.30,
        [4] = 0.40,
        [5] = 0.50,
    },

    -- Repair costs at marina (per percentage point restored)
    repairCostPerPoint = 2,             -- $2 per durability point restored

    -- Minimum durability after repair (always full repair)
    repairToFull = true,
}

-- ============================================================
-- ON-BOAT REPAIR
-- ============================================================

Config.BoatRepair = {
    enabled = true,
    requireAnchored = true,
    repairItem = 'boat_repair_kit',     -- Item consumed for repair
    repairAmount = 25.0,                -- Durability restored per kit
}
