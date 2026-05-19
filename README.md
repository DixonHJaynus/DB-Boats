# DB-Boats

Boat ownership, storage, and upgrade system for RedM servers running the RSG Framework.

## Features

### Marina System
- Multiple marina locations with NPC clerks
- Single blip per marina on the map
- All interactions through ox_target on the NPC

### Boat Ownership
- Purchase boats from marina clerks
- Each boat receives a unique registration number (format: BT-XXXX-XXXX)
- Certificate of Ownership given on purchase (usable inventory item)
- Certificate displays owner name, registration, purchase location, and upgrade levels
- Sell boats back at any marina (50% refund on upgrades)

### Boat Management
- Store boats at marina boat slips
- Retrieve boats from storage
- Recover stuck boats (marked "On Water" but physically gone)
- View all owned boats and their status

### Upgrade System
Three upgradeable stats, each with 5 levels:
- **Speed** — Improves top speed
- **Durability** — Increases damage resistance (10% per level, up to 50%)
- **Fuel Efficiency** — Reduces coal consumption (fuel boats only)

Boats must be stored at a marina to upgrade.

### Damage System
- Hull durability decreases when the boat takes damage
- Durability upgrades reduce incoming damage (Level 1 = 10%, Level 5 = 50% reduction)
- Speed progressively reduces as durability drops (up to 50% slower at 0%)
- Warning notifications at key thresholds:

| Hull % |                  Effect                      |
|--------|----------------------------------------------|
|  75%   | Minor damage notification                    |
|  50%   | Speed reduction begins, warning notification |
|  25%   | Severe speed reduction, critical warning     |
|   0%   | Boat disabled — cannot move until repaired   |

- Two ways to repair:
  - **Marina repair** — Pay cash at the clerk ($2 per durability point)
  - **On-boat repair** — Use repair kits from inventory (each kit restores 25%)
- Hull status visible in Retrieve menu, My Boats menu, and on spawn

### Fuel System
- Coal-powered boats consume fuel while driving
- Fuel consumption scales with speed
- Low fuel warning at 15%
- Boat freezes briefly when fuel hits 0%
- Two ways to refuel:
  - **Marina refuel** — Through the clerk menu
  - **On-boat refuel** — Through ox_target on the boat (requires anchor)

### Anchor System
- Drop and raise anchor through ox_target on the boat
- Anchor freezes the boat in place
- ox_target label dynamically shows current anchor state:
  - `⚓ Drop Anchor` when not anchored
  - `⚓ Raise Anchor [Anchored]` when anchored
- Optional auto-anchor when exiting the boat (disabled by default)
- Refueling and repairing on water requires the boat to be anchored

### Boat Storage (Inventory)
- Each boat has its own persistent inventory stash
- Storage size depends on boat category:
- Items persist through storing and retrieving the boat
- Access through ox_target on the boat

### Certificate of Ownership
- Beautiful NUI document styled as aged parchment
- Displays: owner name, registration number, vessel type, purchase location, purchase date
- Visual upgrade level bars for all three stats
- Opens from inventory (usable item) or from "View My Boats" menu
- Close with button or Escape key

## Dependencies

| Resource      |                      Link                         |
|---------------|---------------------------------------------------|
| rsg-core      | https://github.com/Rexshack-RedM/rsg-core         |
| rsg-inventory | https://github.com/Rexshack-RedM/rsg-inventory    |
| ox_lib        | https://github.com/overextended/ox_lib            |
| ox_target     | https://github.com/overextended/ox_target         |
| oxmysql       | https://github.com/overextended/oxmysql           |

## Installation

### Step 1: Add the resource
Place the `DB-Boats` folder in your server's `resources` directory.

### Step 2: Add required items
Add the following items to your `rsg-core/shared/items.lua`:

```lua
-- Certificate of Ownership (given when purchasing a boat)
['boat_certificate'] = {
    name = 'boat_certificate',
    label = 'Certificate of Ownership',
    weight = 0,
    type = 'item',
    image = 'boat_certificate.png',
    unique = true,
    useable = true,
    shouldClose = true,
    description = 'An official certificate of boat ownership.',
},

-- Boat Repair Kit (used to repair hull damage on the water)
['boat_repair_kit'] = {
    name = 'boat_repair_kit',
    label = 'Boat Repair Kit',
    weight = 500,
    type = 'item',
    image = 'boat_repair_kit.png',
    unique = false,
    useable = false,
    shouldClose = false,
    description = 'A kit containing materials to repair boat hull damage.',
},

-- Coal (used as fuel for steam-powered boats)
-- Skip if your server already has coal as an item
['coal'] = {
    name = 'coal',
    label = 'Coal',
    weight = 200,
    type = 'item',
    image = 'coal.png',
    unique = false,
    useable = false,
    shouldClose = false,
    description = 'A lump of coal. Can be used to fuel steam-powered boats.',
},
