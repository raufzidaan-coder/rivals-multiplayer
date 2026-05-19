--[[
    RIVALS - Weapon Configuration Module
    Type: ModuleScript
    Location: ReplicatedStorage

    Shared weapon data used by both client and server.
    All weapons from the original RIVALS game are included.
]]

local WeaponConfig = {}

WeaponConfig.Weapons = {
    -- === PRIMARY WEAPONS ===
    AssaultRifle = {
        name = "Assault Rifle", type = "primary",
        damage = 15, fireRate = 0.08, maxAmmo = 30,
        speed = 200, color = Color3.fromRGB(99, 102, 241),
        auto = true, spread = 0.02
    },
    Shotgun = {
        name = "Shotgun", type = "primary",
        damage = 12, fireRate = 0.7, maxAmmo = 8,
        speed = 120, color = Color3.fromRGB(245, 158, 11),
        auto = false, pellets = 6, spread = 0.08
    },
    Sniper = {
        name = "Sniper", type = "primary",
        damage = 120, fireRate = 1.2, maxAmmo = 5,
        speed = 350, color = Color3.fromRGB(239, 68, 68),
        auto = false, spread = 0.001, scope = true
    },
    SMG = {
        name = "SMG", type = "primary",
        damage = 10, fireRate = 0.05, maxAmmo = 40,
        speed = 220, color = Color3.fromRGB(34, 197, 94),
        auto = true, spread = 0.03
    },
    Bow = {
        name = "Bow", type = "primary",
        damage = 50, fireRate = 1.0, maxAmmo = 1,
        speed = 150, color = Color3.fromRGB(168, 85, 247),
        auto = false, spread = 0.005, special = "doublejump"
    },
    BurstRifle = {
        name = "Burst Rifle", type = "primary",
        damage = 18, fireRate = 0.6, maxAmmo = 15,
        speed = 220, color = Color3.fromRGB(59, 130, 246),
        auto = false, burst = 3, spread = 0.015
    },
    Crossbow = {
        name = "Crossbow", type = "primary",
        damage = 75, fireRate = 1.0, maxAmmo = 1,
        speed = 180, color = Color3.fromRGB(146, 64, 14),
        auto = false, spread = 0.003
    },
    RPG = {
        name = "RPG", type = "primary",
        damage = 100, fireRate = 1.5, maxAmmo = 1,
        speed = 100, color = Color3.fromRGB(220, 38, 38),
        auto = false, explosive = true, splashRadius = 20
    },
    Minigun = {
        name = "Minigun", type = "primary",
        damage = 8, fireRate = 0.05, maxAmmo = 300,
        speed = 180, color = Color3.fromRGB(115, 115, 115),
        auto = true, spread = 0.04, spinupTime = 0.8
    },
    Flamethrower = {
        name = "Flamethrower", type = "primary",
        damage = 5, fireRate = 0.03, maxAmmo = 100,
        speed = 80, color = Color3.fromRGB(249, 115, 22),
        auto = true, burn = true, range = 30
    },
    GrenadeLauncher = {
        name = "Grenade Launcher", type = "primary",
        damage = 80, fireRate = 0.6, maxAmmo = 6,
        speed = 120, color = Color3.fromRGB(133, 77, 14),
        auto = false, explosive = true, splashRadius = 15
    },
    EnergyRifle = {
        name = "Energy Rifle", type = "primary",
        damage = 20, fireRate = 0.3, maxAmmo = 999,
        speed = 250, color = Color3.fromRGB(6, 182, 212),
        auto = true, bounces = 2, spread = 0.01
    },
    Gunblade = {
        name = "Gunblade", type = "primary",
        damage = 45, fireRate = 0.75, maxAmmo = 12,
        speed = 140, color = Color3.fromRGB(225, 29, 72),
        auto = false, meleeDamage = 35, spread = 0.02
    },
    PaintballGun = {
        name = "Paintball Gun", type = "primary",
        damage = 18, fireRate = 0.15, maxAmmo = 16,
        speed = 160, color = Color3.fromRGB(217, 70, 239),
        auto = true, blind = true, spread = 0.03
    },

    -- === SECONDARY WEAPONS ===
    Handgun = {
        name = "Handgun", type = "secondary",
        damage = 20, fireRate = 0.25, maxAmmo = 12,
        speed = 180, color = Color3.fromRGB(170, 170, 170),
        auto = false, spread = 0.02
    },
    Exogun = {
        name = "Exogun", type = "secondary",
        damage = 25, fireRate = 0.3, maxAmmo = 10,
        speed = 160, color = Color3.fromRGB(168, 85, 247),
        auto = false, spread = 0.02
    },
    Revolver = {
        name = "Revolver", type = "secondary",
        damage = 40, fireRate = 0.4, maxAmmo = 6,
        speed = 200, color = Color3.fromRGB(180, 83, 9),
        auto = false, spread = 0.01
    },
    Shorty = {
        name = "Shorty", type = "secondary",
        damage = 12, fireRate = 0.12, maxAmmo = 2,
        speed = 100, color = Color3.fromRGB(120, 113, 108),
        auto = false, pellets = 10, spread = 0.1
    },
    Uzi = {
        name = "Uzi", type = "secondary",
        damage = 9, fireRate = 0.06, maxAmmo = 25,
        speed = 200, color = Color3.fromRGB(82, 82, 82),
        auto = true, spread = 0.035
    },
    FlareGun = {
        name = "Flare Gun", type = "secondary",
        damage = 15, fireRate = 0.8, maxAmmo = 2,
        speed = 140, color = Color3.fromRGB(251, 146, 60),
        auto = false, burn = true
    },
    Slingshot = {
        name = "Slingshot", type = "secondary",
        damage = 30, fireRate = 0.5, maxAmmo = 1,
        speed = 220, color = Color3.fromRGB(161, 98, 7),
        auto = false, spread = 0.01
    },

    -- === MELEE WEAPONS ===
    Fists = {
        name = "Fists", type = "melee",
        damage = 25, fireRate = 0.5, range = 6,
        color = Color3.fromRGB(34, 197, 94),
        special = "doublejump"
    },
    Knife = {
        name = "Knife", type = "melee",
        damage = 35, fireRate = 0.4, range = 7,
        color = Color3.fromRGB(170, 170, 170)
    },
    Daggers = {
        name = "Daggers", type = "melee",
        damage = 20, fireRate = 0.3, range = 6,
        color = Color3.fromRGB(34, 211, 238),
        speedBoost = 1.3
    },
    Katana = {
        name = "Katana", type = "melee",
        damage = 45, fireRate = 0.5, range = 9,
        color = Color3.fromRGB(244, 63, 94),
        reflect = true
    },
    BattleAxe = {
        name = "Battle Axe", type = "melee",
        damage = 60, fireRate = 0.8, range = 8,
        color = Color3.fromRGB(124, 45, 18)
    },
    Chainsaw = {
        name = "Chainsaw", type = "melee",
        damage = 15, fireRate = 0.1, range = 6,
        color = Color3.fromRGB(250, 204, 21),
        speedBoost = 1.2
    },
    Scythe = {
        name = "Scythe", type = "melee",
        damage = 55, fireRate = 0.7, range = 10,
        color = Color3.fromRGB(124, 58, 237)
    },
    RiotShield = {
        name = "Riot Shield", type = "melee",
        damage = 20, fireRate = 0.6, range = 5,
        color = Color3.fromRGB(37, 99, 235),
        block = true
    },
    Trowel = {
        name = "Trowel", type = "melee",
        damage = 30, fireRate = 0.45, range = 6,
        color = Color3.fromRGB(101, 163, 13),
        build = true
    },

    -- === UTILITY ===
    Grenade = {
        name = "Grenade", type = "utility",
        damage = 80, fireRate = 1.5, maxAmmo = 2,
        speed = 120, color = Color3.fromRGB(239, 68, 68),
        explosive = true, splashRadius = 20
    },
    Medkit = {
        name = "Medkit", type = "utility",
        heal = 50, fireRate = 3.0, maxAmmo = 2,
        color = Color3.fromRGB(74, 222, 128)
    },
    Flashbang = {
        name = "Flashbang", type = "utility",
        damage = 0, fireRate = 2.0, maxAmmo = 2,
        speed = 140, color = Color3.fromRGB(254, 240, 138),
        blind = true, blindDuration = 3
    },
    FreezeRay = {
        name = "Freeze Ray", type = "utility",
        damage = 10, fireRate = 0.2, maxAmmo = 50,
        speed = 100, color = Color3.fromRGB(125, 211, 252),
        slow = 0.5
    },
    JumpPad = {
        name = "Jump Pad", type = "utility",
        damage = 0, fireRate = 5.0, maxAmmo = 3,
        color = Color3.fromRGB(52, 211, 153),
        launch = true
    },
    Molotov = {
        name = "Molotov", type = "utility",
        damage = 15, fireRate = 2.0, maxAmmo = 1,
        speed = 120, color = Color3.fromRGB(234, 88, 12),
        burn = true, zone = true, zoneDuration = 5
    }
}

-- Shop prices and level requirements
WeaponConfig.Shop = {
    -- Free defaults
    AssaultRifle = { price = 0, levelReq = 1 },
    Handgun = { price = 0, levelReq = 1 },
    Fists = { price = 0, levelReq = 1 },
    Grenade = { price = 0, levelReq = 1 },
    -- Cheap (5 keys)
    SMG = { price = 5, levelReq = 1 },
    Knife = { price = 5, levelReq = 1 },
    Medkit = { price = 5, levelReq = 1 },
    Shorty = { price = 5, levelReq = 1 },
    Uzi = { price = 5, levelReq = 1 },
    Slingshot = { price = 5, levelReq = 1 },
    Daggers = { price = 5, levelReq = 1 },
    Trowel = { price = 5, levelReq = 1 },
    -- Medium (15 keys, level 3)
    Shotgun = { price = 15, levelReq = 3 },
    Bow = { price = 15, levelReq = 3 },
    BurstRifle = { price = 15, levelReq = 3 },
    Revolver = { price = 15, levelReq = 3 },
    FlareGun = { price = 15, levelReq = 3 },
    Katana = { price = 15, levelReq = 3 },
    BattleAxe = { price = 15, levelReq = 3 },
    Flashbang = { price = 15, levelReq = 3 },
    FreezeRay = { price = 15, levelReq = 3 },
    -- Expensive (30 keys, level 5)
    Sniper = { price = 30, levelReq = 5 },
    Crossbow = { price = 30, levelReq = 5 },
    RPG = { price = 30, levelReq = 5 },
    Minigun = { price = 30, levelReq = 5 },
    EnergyRifle = { price = 30, levelReq = 5 },
    Gunblade = { price = 30, levelReq = 5 },
    Chainsaw = { price = 30, levelReq = 5 },
    Scythe = { price = 30, levelReq = 5 },
    RiotShield = { price = 30, levelReq = 5 },
    Molotov = { price = 30, levelReq = 5 },
    -- Premium (50 keys, level 8)
    Flamethrower = { price = 50, levelReq = 8 },
    GrenadeLauncher = { price = 50, levelReq = 8 },
    PaintballGun = { price = 50, levelReq = 8 },
    Exogun = { price = 50, levelReq = 8 },
    JumpPad = { price = 50, levelReq = 8 },
}

-- Default loadout for new players
WeaponConfig.DefaultLoadout = {
    primary = "AssaultRifle",
    secondary = "Handgun",
    melee = "Fists",
    utility = "Grenade"
}

WeaponConfig.DefaultInventory = {"AssaultRifle", "Handgun", "Fists", "Grenade"}

-- XP needed per level
function WeaponConfig.XPForLevel(level)
    return level * 100
end

return WeaponConfig
