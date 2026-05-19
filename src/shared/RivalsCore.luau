--[[
    ROBLOX RIVALS CLONE - COMPLETE CORE
    Copy this into a Roblox Place as a ModuleScript in ReplicatedStorage
    Then require it from ServerScriptService and StarterPlayer
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")

--=============================================================================
-- CONFIGURATION
--=============================================================================

local CONFIG = {
    Game = {
        MaxPlayersPerTeam = 5,
        RoundsPerMatch = 9,
        RoundTime = 120,
        RespawnTime = 3,
        WarmupTime = 10,
        LevelRequirement = 50,
        RankedAgeRequirement = 14,
    },
    Movement = {
        WalkSpeed = 16,
        SprintSpeed = 20,
        SlideSpeed = 26,
        JumpPower = 20,
        Gravity = 196.2,
        AirAcceleration = 100,
        GroundAcceleration = 80,
        WallSlideSpeed = 8,
        WallRunSpeed = 22,
        DoubleJumpPower = 24,
    },
    Combat = {
        HeadshotMultiplier = 2.0,
        BaseDamage = 10,
        FallDamageEnabled = false,
        MaxHealth = 100,
        MaxArmor = 50,
        ArmorDamageReduction = 0.5,
    },
    Weapons = {
        QuickSwitchMax = 2,
    },
    Ranks = {
        { Name = "Bronze", Min = 0, Max = 599 },
        { Name = "Silver", Min = 600, Max = 1199 },
        { Name = "Gold", Min = 1200, Max = 1799 },
        { Name = "Platinum", Min = 1800, Max = 2399 },
        { Name = "Diamond", Min = 2400, Max = 2999 },
        { Name = "Onyx", Min = 3000, Max = 3599 },
        { Name = "Nemesis", Min = 3600, Max = 99999 },
    },
}

--=============================================================================
-- WEAPON DEFINITIONS
--=============================================================================

local WEAPONS = {
    -- PRIMARY WEAPONS
    AssaultRifle = {
        Category = "Primary",
        Rarity = "Standard",
        Damage = 15,
        FireRate = 0.1,
        Magazine = 30,
        Reserve = 90,
        ADS = true,
        Automatic = true,
        Recoil = 0.3,
        Range = 100,
        HipSpread = 0.15,
        ADSSpread = 0.02,
        ReloadTime = 2.5,
        BulletType = "Hitscan",
        Speed = 1000,
    },
    Shotgun = {
        Category = "Primary",
        Rarity = "Standard",
        Damage = 8,
        Pellets = 8,
        FireRate = 0.8,
        Magazine = 6,
        Reserve = 24,
        ADS = true,
        Automatic = false,
        Recoil = 0.8,
        Range = 20,
        HipSpread = 0.4,
        ADSSpread = 0.15,
        ReloadTime = 3.5,
        BulletType = "Hitscan",
        Speed = 1000,
    },
    Sniper = {
        Category = "Primary",
        Rarity = "Standard",
        Damage = 100,
        FireRate = 1.5,
        Magazine = 5,
        Reserve = 15,
        ADS = true,
        Automatic = false,
        Recoil = 1.2,
        Range = 500,
        HipSpread = 0.5,
        ADSSpread = 0.001,
        ReloadTime = 4.0,
        BulletType = "Projectile",
        Speed = 3000,
    },
    BurstRifle = {
        Category = "Primary",
        Rarity = "Standard",
        Damage = 12,
        FireRate = 0.05,
        BurstCount = 3,
        BurstDelay = 0.15,
        Magazine = 24,
        Reserve = 72,
        ADS = true,
        Automatic = true,
        Recoil = 0.35,
        Range = 80,
        HipSpread = 0.12,
        ADSSpread = 0.03,
        ReloadTime = 2.8,
        BulletType = "Hitscan",
        Speed = 1000,
    },
    Bow = {
        Category = "Primary",
        Rarity = "Standard",
        Damage = 50,
        FireRate = 1.2,
        Magazine = 1,
        Reserve = 12,
        ADS = true,
        Automatic = false,
        Recoil = 0.6,
        Range = 150,
        HipSpread = 0.2,
        ADSSpread = 0.01,
        ReloadTime = 2.0,
        BulletType = "Projectile",
        Speed = 250,
        HasDoubleJump = true,
    },
    Crossbow = {
        Category = "Primary",
        Rarity = "Standard",
        Damage = 70,
        FireRate = 1.5,
        Magazine = 1,
        Reserve = 8,
        ADS = true,
        Automatic = false,
        Recoil = 0.8,
        Range = 200,
        HipSpread = 0.15,
        ADSSpread = 0.005,
        ReloadTime = 2.5,
        BulletType = "Projectile",
        Speed = 400,
    },
    Gunblade = {
        Category = "Primary",
        Rarity = "Standard",
        Damage = 35,
        FireRate = 0.3,
        Magazine = 20,
        Reserve = 60,
        ADS = true,
        Automatic = true,
        Recoil = 0.4,
        Range = 60,
        HipSpread = 0.2,
        ADSSpread = 0.05,
        ReloadTime = 2.2,
        BulletType = "Hitscan",
        Speed = 1000,
        MeleeDamage = 75,
    },
    RPG = {
        Category = "Primary",
        Rarity = "Standard",
        Damage = 100,
        FireRate = 1.0,
        Magazine = 1,
        Reserve = 5,
        ADS = false,
        Automatic = false,
        Recoil = 1.0,
        Range = 200,
        HipSpread = 0.3,
        ReloadTime = 3.0,
        BulletType = "Projectile",
        Speed = 80,
        ExplosionRadius = 15,
        CanExplosiveJump = true,
    },
    EnergyRifle = {
        Category = "Primary",
        Rarity = "Prime",
        Damage = 20,
        FireRate = 0.08,
        Magazine = 40,
        Reserve = 120,
        ADS = true,
        Automatic = true,
        Recoil = 0.25,
        Range = 120,
        HipSpread = 0.1,
        ADSSpread = 0.015,
        ReloadTime = 2.0,
        BulletType = "Hitscan",
        Speed = 1500,
        EnergyColor = Color3.fromRGB(0, 255, 255),
    },
    Flamethrower = {
        Category = "Primary",
        Rarity = "Prime",
        Damage = 8,
        FireRate = 0.05,
        Magazine = 100,
        Reserve = 200,
        ADS = false,
        Automatic = true,
        Recoil = 0.1,
        Range = 25,
        HipSpread = 0.5,
        ReloadTime = 4.0,
        BulletType = "Instant",
        DoT = 5,
        DoTDuration = 2,
    },
    GrenadeLauncher = {
        Category = "Primary",
        Rarity = "Prime",
        Damage = 80,
        FireRate = 0.8,
        Magazine = 6,
        Reserve = 18,
        ADS = true,
        Automatic = false,
        Recoil = 0.9,
        Range = 80,
        HipSpread = 0.25,
        ADSSpread = 0.1,
        ReloadTime = 3.0,
        BulletType = "Projectile",
        Speed = 60,
        ExplosionRadius = 20,
        CanExplosiveJump = true,
    },
    Minigun = {
        Category = "Primary",
        Rarity = "Prime",
        Damage = 8,
        FireRate = 0.05,
        Magazine = 200,
        Reserve = 400,
        ADS = false,
        Automatic = true,
        Recoil = 0.5,
        Range = 80,
        HipSpread = 0.35,
        ADSSpread = 0.2,
        ReloadTime = 6.0,
        SpinUpTime = 1.5,
        BulletType = "Hitscan",
        Speed = 1200,
    },
    PaintballGun = {
        Category = "Primary",
        Rarity = "Prime",
        Damage = 12,
        FireRate = 0.15,
        Magazine = 15,
        Reserve = 45,
        ADS = true,
        Automatic = true,
        Recoil = 0.3,
        Range = 60,
        HipSpread = 0.18,
        ADSSpread = 0.04,
        ReloadTime = 2.0,
        BulletType = "Projectile",
        Speed = 200,
        PaintSplash = true,
    },
    Distortion = {
        Category = "Primary",
        Rarity = "Contraband",
        Damage = 25,
        FireRate = 0.12,
        Magazine = 25,
        Reserve = 75,
        ADS = true,
        Automatic = true,
        Recoil = 0.2,
        Range = 100,
        HipSpread = 0.08,
        ADSSpread = 0.01,
        ReloadTime = 2.2,
        BulletType = "Hitscan",
        Speed = 2000,
        Disorient = true,
    },
    Scepter = {
        Category = "Primary",
        Rarity = "Contraband",
        Damage = 40,
        FireRate = 0.6,
        Magazine = 8,
        Reserve = 24,
        ADS = true,
        Automatic = false,
        Recoil = 0.5,
        Range = 150,
        HipSpread = 0.1,
        ADSSpread = 0.02,
        ReloadTime = 2.5,
        BulletType = "Projectile",
        Speed = 300,
        ChainLightning = true,
    },

    -- SECONDARY WEAPONS
    Handgun = {
        Category = "Secondary",
        Rarity = "Standard",
        Damage = 20,
        FireRate = 0.2,
        Magazine = 12,
        Reserve = 48,
        ADS = true,
        Automatic = false,
        Recoil = 0.4,
        Range = 50,
        HipSpread = 0.2,
        ADSSpread = 0.05,
        ReloadTime = 1.8,
        BulletType = "Hitscan",
        Speed = 1000,
    },
    Revolver = {
        Category = "Secondary",
        Rarity = "Standard",
        Damage = 45,
        FireRate = 0.5,
        Magazine = 6,
        Reserve = 30,
        ADS = true,
        Automatic = false,
        Recoil = 0.7,
        Range = 80,
        HipSpread = 0.15,
        ADSSpread = 0.03,
        ReloadTime = 3.5,
        BulletType = "Hitscan",
        Speed = 1200,
    },
    Shorty = {
        Category = "Secondary",
        Rarity = "Standard",
        Damage = 10,
        Pellets = 6,
        FireRate = 0.6,
        Magazine = 2,
        Reserve = 16,
        ADS = true,
        Automatic = false,
        Recoil = 0.6,
        Range = 15,
        HipSpread = 0.5,
        ADSSpread = 0.2,
        ReloadTime = 1.5,
        BulletType = "Hitscan",
        Speed = 800,
    },
    Spray = {
        Category = "Secondary",
        Rarity = "Standard",
        Damage = 12,
        FireRate = 0.08,
        Magazine = 50,
        Reserve = 150,
        ADS = true,
        Automatic = true,
        Recoil = 0.35,
        Range = 40,
        HipSpread = 0.25,
        ADSSpread = 0.08,
        ReloadTime = 2.2,
        BulletType = "Hitscan",
        Speed = 900,
    },
    Uzi = {
        Category = "Secondary",
        Rarity = "Standard",
        Damage = 14,
        FireRate = 0.08,
        Magazine = 25,
        Reserve = 75,
        ADS = true,
        Automatic = true,
        Recoil = 0.35,
        Range = 35,
        HipSpread = 0.25,
        ADSSpread = 0.1,
        ReloadTime = 2.0,
        BulletType = "Hitscan",
        Speed = 900,
    },
    FlareGun = {
        Category = "Secondary",
        Rarity = "Standard",
        Damage = 30,
        FireRate = 1.0,
        Magazine = 1,
        Reserve = 8,
        ADS = true,
        Automatic = false,
        Recoil = 0.5,
        Range = 100,
        HipSpread = 0.2,
        ADSSpread = 0.05,
        ReloadTime = 1.5,
        BulletType = "Projectile",
        Speed = 150,
        Ignites = true,
    },
    Daggers = {
        Category = "Secondary",
        Rarity = "Standard",
        Damage = 25,
        FireRate = 0.3,
        Magazine = 999,
        Reserve = 999,
        ADS = false,
        Automatic = false,
        Recoil = 0.1,
        Range = 8,
        HipSpread = 0.1,
        ReloadTime = 0,
        MeleeDamage = 40,
        MovementSpeedBoost = 1.3,
        Melee = true,
    },
    Exogun = {
        Category = "Secondary",
        Rarity = "Prime",
        Damage = 35,
        FireRate = 0.15,
        Magazine = 20,
        Reserve = 60,
        ADS = true,
        Automatic = true,
        Recoil = 0.3,
        Range = 70,
        HipSpread = 0.12,
        ADSSpread = 0.03,
        ReloadTime = 2.0,
        BulletType = "Hitscan",
        Speed = 1500,
        Explosive = true,
    },
    Slingshot = {
        Category = "Secondary",
        Rarity = "Prime",
        Damage = 30,
        FireRate = 0.8,
        Magazine = 1,
        Reserve = 20,
        ADS = true,
        Automatic = false,
        Recoil = 0.4,
        Range = 80,
        HipSpread = 0.15,
        ADSSpread = 0.02,
        ReloadTime = 1.2,
        BulletType = "Projectile",
        Speed = 200,
    },
    EnergyPistols = {
        Category = "Secondary",
        Rarity = "Prime",
        Damage = 18,
        FireRate = 0.1,
        Magazine = 30,
        Reserve = 90,
        ADS = true,
        Automatic = true,
        Recoil = 0.2,
        Range = 55,
        HipSpread = 0.15,
        ADSSpread = 0.04,
        ReloadTime = 1.8,
        BulletType = "Hitscan",
        Speed = 1400,
    },
    Warper = {
        Category = "Secondary",
        Rarity = "Contraband",
        Damage = 25,
        FireRate = 0.25,
        Magazine = 15,
        Reserve = 45,
        ADS = true,
        Automatic = false,
        Recoil = 0.3,
        Range = 60,
        HipSpread = 0.15,
        ADSSpread = 0.03,
        ReloadTime = 2.0,
        BulletType = "Hitscan",
        Speed = 1200,
        TeleportBehind = true,
    },

    -- MELEE WEAPONS
    Fists = {
        Category = "Melee",
        Rarity = "Standard",
        Damage = 25,
        FireRate = 0.5,
        Magazine = 999,
        Reserve = 999,
        ADS = false,
        Automatic = false,
        Recoil = 0,
        Range = 6,
        HipSpread = 0,
        ReloadTime = 0,
        MeleeDamage = 25,
        HasDoubleJump = true,
        Melee = true,
    },
    Knife = {
        Category = "Melee",
        Rarity = "Standard",
        Damage = 35,
        FireRate = 0.4,
        Magazine = 999,
        Reserve = 999,
        ADS = false,
        Automatic = false,
        Recoil = 0.1,
        Range = 8,
        HipSpread = 0,
        ReloadTime = 0,
        MeleeDamage = 35,
        Melee = true,
    },
    Katana = {
        Category = "Melee",
        Rarity = "Standard",
        Damage = 50,
        FireRate = 0.6,
        Magazine = 999,
        Reserve = 999,
        ADS = false,
        Automatic = false,
        Recoil = 0.15,
        Range = 10,
        HipSpread = 0,
        ReloadTime = 0,
        MeleeDamage = 50,
        Melee = true,
    },
    Chainsaw = {
        Category = "Melee",
        Rarity = "Standard",
        Damage = 15,
        FireRate = 0.1,
        Magazine = 999,
        Reserve = 999,
        ADS = false,
        Automatic = true,
        Recoil = 0.2,
        Range = 8,
        HipSpread = 0.1,
        ReloadTime = 0,
        MeleeDamage = 15,
        DoT = 5,
        DoTDuration = 1,
        Melee = true,
    },
    BattleAxe = {
        Category = "Melee",
        Rarity = "Standard",
        Damage = 60,
        FireRate = 0.8,
        Magazine = 999,
        Reserve = 999,
        ADS = false,
        Automatic = false,
        Recoil = 0.3,
        Range = 10,
        HipSpread = 0,
        ReloadTime = 0,
        MeleeDamage = 60,
        Melee = true,
    },
    Scythe = {
        Category = "Melee",
        Rarity = "Standard",
        Damage = 55,
        FireRate = 0.7,
        Magazine = 999,
        Reserve = 999,
        ADS = false,
        Automatic = false,
        Recoil = 0.25,
        Range = 12,
        HipSpread = 0,
        ReloadTime = 0,
        MeleeDamage = 55,
        Melee = true,
    },
    RiotShield = {
        Category = "Melee",
        Rarity = "Standard",
        Damage = 20,
        FireRate = 1.0,
        Magazine = 999,
        Reserve = 999,
        ADS = false,
        Automatic = false,
        Recoil = 0,
        Range = 6,
        HipSpread = 0,
        ReloadTime = 0,
        MeleeDamage = 20,
        HasShield = true,
        ShieldHealth = 150,
        Melee = true,
    },
    Trowel = {
        Category = "Melee",
        Rarity = "Prime",
        Damage = 40,
        FireRate = 0.5,
        Magazine = 999,
        Reserve = 999,
        ADS = false,
        Automatic = false,
        Recoil = 0.1,
        Range = 8,
        HipSpread = 0,
        ReloadTime = 0,
        MeleeDamage = 40,
        BuildsStructure = true,
        Melee = true,
    },

    -- UTILITY WEAPONS
    Grenade = {
        Category = "Utility",
        Rarity = "Standard",
        Damage = 80,
        Magazine = 2,
        Reserve = 6,
        FuseTime = 3,
        ExplosionRadius = 15,
        Throwable = true,
    },
    Flashbang = {
        Category = "Utility",
        Rarity = "Standard",
        Magazine = 2,
        Reserve = 6,
        FuseTime = 1,
        ExplosionRadius = 20,
        FlashDuration = 3,
        Throwable = true,
    },
    SmokeGrenade = {
        Category = "Utility",
        Rarity = "Standard",
        Magazine = 2,
        Reserve = 6,
        FuseTime = 1,
        ExplosionRadius = 15,
        SmokeDuration = 15,
        Throwable = true,
    },
    Molotov = {
        Category = "Utility",
        Rarity = "Standard",
        Damage = 10,
        Magazine = 1,
        Reserve = 4,
        FuseTime = 1,
        ExplosionRadius = 10,
        FireDuration = 8,
        DoT = 5,
        Throwable = true,
    },
    Satchel = {
        Category = "Utility",
        Rarity = "Standard",
        Damage = 100,
        Magazine = 2,
        Reserve = 6,
        FuseTime = 0.1,
        ExplosionRadius = 18,
        Detonatable = true,
        Throwable = true,
    },
    Medkit = {
        Category = "Utility",
        Rarity = "Standard",
        HealAmount = 50,
        Magazine = 1,
        Reserve = 3,
        UseTime = 3,
    },
    JumpPad = {
        Category = "Utility",
        Rarity = "Standard",
        Magazine = 1,
        Reserve = 2,
        JumpForce = 80,
        Placeable = true,
    },
    FreezeRay = {
        Category = "Utility",
        Rarity = "Standard",
        Magazine = 30,
        Reserve = 60,
        FreezeDuration = 3,
        ADS = true,
        Automatic = true,
        FireRate = 0.05,
    },
    WarHorn = {
        Category = "Utility",
        Rarity = "Standard",
        Magazine = 1,
        Reserve = 3,
        BuffDuration = 10,
        SpeedBuff = 1.5,
        DamageBuff = 1.25,
        UseTime = 1,
    },
    SubspaceTripmine = {
        Category = "Utility",
        Rarity = "Prime",
        Damage = 75,
        Magazine = 2,
        Reserve = 4,
        ExplosionRadius = 12,
        Detonatable = true,
        Placeable = true,
    },
    Warpstone = {
        Category = "Utility",
        Rarity = "Prime",
        Magazine = 1,
        Reserve = 3,
        TeleportDistance = 50,
    },
    Elixir = {
        Category = "Utility",
        Rarity = "Contraband",
        HealAmount = 100,
        Magazine = 1,
        Reserve = 2,
        UseTime = 0.5,
        FullHeal = true,
    },
    RNGDice = {
        Category = "Utility",
        Rarity = "Contraband",
        Magazine = 1,
        Reserve = 3,
        RandomEffect = true,
    },
}

--=============================================================================
-- PLAYER DATA MANAGER
--=============================================================================

local PlayerDataManager = {}
PlayerDataManager.__index = PlayerDataManager

function PlayerDataManager.new()
    local self = setmetatable({}, PlayerDataManager)
    self.Data = {}
    return self
end

function PlayerDataManager:GetData(Player)
    if not self.Data[Player.UserId] then
        self.Data[Player.UserId] = {
            Level = 1,
            XP = 0,
            Keys = 0,
            Glory = 0,
            ELO = 1000,
            Rank = "Bronze",
            RankedWins = 0,
            RankedLosses = 0,
            CasualWins = 0,
            CasualLosses = 0,
            Kills = 0,
            Deaths = 0,
            Headshots = 0,
            WeaponsOwned = { "AssaultRifle", "Handgun", "Fists", "Grenade" },
            Cosmetics = {},
            TasksCompleted = 0,
            PlacementMatches = 0,
        }
    end
    return self.Data[Player.UserId]
end

function PlayerDataManager:AddXP(Player, Amount)
    local Data = self:GetData(Player)
    Data.XP = Data.XP + Amount
    local XPToLevel = Data.Level * 100
    while Data.XP >= XPToLevel do
        Data.XP = Data.XP - XPToLevel
        Data.Level = Data.Level + 1
        XPToLevel = Data.Level * 100
    end
    return Data.Level
end

function PlayerDataManager:GetRank(ELO)
    for _, Rank in ipairs(CONFIG.Ranks) do
        if ELO >= Rank.Min and ELO <= Rank.Max then
            return Rank.Name
        end
    end
    return "Bronze"
end

function PlayerDataManager:CanPlayRanked(Player)
    local Data = self:GetData(Player)
    local AccountAge = os.time() - Player.AccountAge * 86400
    return Data.Level >= CONFIG.Game.LevelRequirement
        and AccountAge >= CONFIG.Game.RankedAgeRequirement * 86400
        and Data.TasksCompleted >= 30
end

--=============================================================================
-- MOVEMENT SYSTEM
--=============================================================================

local MovementSystem = {}
MovementSystem.__index = MovementSystem

function MovementSystem.new(Character)
    local self = setmetatable({}, MovementSystem)
    self.Character = Character
    self.Humanoid = Character:FindFirstChild("Humanoid")
    self.RootPart = Character:FindFirstChild("HumanoidRootPart")
    self.State = {
        IsSprinting = false,
        IsSliding = false,
        IsWallRunning = false,
        IsWallSliding = false,
        CanDoubleJump = true,
        HasWeaponDoubleJump = false,
        SlideCooldown = 0,
        WallRunDirection = Vector3.new(),
        CurrentSpeed = CONFIG.Movement.WalkSpeed,
        StrafeJumpMultiplier = 1.0,
        IsGrounded = true,
    }
    self.Velocity = Vector3.new()
    return self
end

function MovementSystem:Slide()
    if self.State.SlideCooldown > 0 or not self.State.IsGrounded then
        return false
    end

    self.State.IsSliding = true
    self.State.CurrentSpeed = CONFIG.Movement.SlideSpeed
    self.State.SlideCooldown = 0.5

    task.delay(0.5, function()
        if self.State.IsSliding then
            self:StopSlide()
        end
    end)

    return true
end

function MovementSystem:StopSlide()
    self.State.IsSliding = false
    self.State.CurrentSpeed = self.State.IsSprinting and CONFIG.Movement.SprintSpeed or CONFIG.Movement.WalkSpeed
end

function MovementSystem:Jump()
    if not self.State.IsGrounded then
        if self.State.CanDoubleJump then
            self.State.CanDoubleJump = false
            self:applyVerticalVelocity(CONFIG.Movement.DoubleJumpPower)
            return true
        end
        return false
    end

    self:applyVerticalVelocity(CONFIG.Movement.JumpPower)
    self.State.CanDoubleJump = true

    if self.State.HasWeaponDoubleJump then
        self.State.CanDoubleJump = true
    end

    return true
end

function MovementSystem:applyVerticalVelocity(Power)
    if self.RootPart and self.Humanoid then
        self.Velocity = Vector3.new(self.Velocity.X, Power, self.Velocity.Z)
    end
end

function MovementSystem:Sprint(Enabled)
    self.State.IsSprinting = Enabled
    if not self.State.IsSliding then
        self.State.CurrentSpeed = Enabled and CONFIG.Movement.SprintSpeed or CONFIG.Movement.WalkSpeed
    end
end

function MovementSystem:StrafeJump()
    if not self.State.IsGrounded then
        self.State.StrafeJumpMultiplier = math.min(self.State.StrafeJumpMultiplier + 0.05, 1.5)
    end
end

function MovementSystem:Update(DeltaTime)
    if self.Humanoid and self.RootPart then
        self.State.IsGrounded = self.Humanoid:GetState() == Enum.HumanoidStateType.Freefall and false
            or self.Humanoid:GetState() == Enum.HumanoidStateType.Jumping and false
            or true

        if self.State.SlideCooldown > 0 then
            self.State.SlideCooldown = self.State.SlideCooldown - DeltaTime
        end

        local Velocity = self.RootPart.Velocity
        local HorizontalSpeed = Vector2.new(Velocity.X, Velocity.Z).Magnitude
        local MaxSpeed = self.State.CurrentSpeed * self.State.StrafeJumpMultiplier

        if HorizontalSpeed > MaxSpeed and self.State.IsGrounded then
            local Ratio = MaxSpeed / HorizontalSpeed
            self.RootPart.Velocity = Vector3.new(Velocity.X * Ratio, Velocity.Y, Velocity.Z * Ratio)
        end

        if self.State.IsWallSliding then
            local WallSlideMax = CONFIG.Movement.WallSlideSpeed
            if Velocity.Y < -WallSlideMax then
                self.RootPart.Velocity = Vector3.new(Velocity.X, -WallSlideMax, Velocity.Z)
            end
        end

        if not self.State.IsGrounded then
            self.State.StrafeJumpMultiplier = math.max(1.0, self.State.StrafeJumpMultiplier - DeltaTime * 0.1)
        else
            self.State.StrafeJumpMultiplier = 1.0
        end
    end
end

function MovementSystem:SetWeaponDoubleJump(Enabled)
    self.State.HasWeaponDoubleJump = Enabled
end

--=============================================================================
-- WEAPON SYSTEM
--=============================================================================

local WeaponSystem = {}
WeaponSystem.__index = WeaponSystem

function WeaponSystem.new(Character, WeaponName)
    local self = setmetatable({}, WeaponSystem)
    self.Character = Character
    self.WeaponName = WeaponName
    self.WeaponData = WEAPONS[WeaponName] or WEAPONS.AssaultRifle
    self.State = {
        Magazine = self.WeaponData.Magazine or 999,
        Reserve = self.WeaponData.Reserve or 999,
        IsReloading = false,
        IsADS = false,
        IsFiring = false,
        LastFireTime = 0,
        BurstCount = 0,
        BurstCooldown = 0,
        SpinUpTime = 0,
        IsSpunUp = false,
    }
    self.RecoilOffset = Vector2.new()
    self.SpreadOffset = Vector2.new()
    return self
end

function WeaponSystem:CanFire()
    if self.State.IsReloading then
        return false
    end
    if self.State.Magazine <= 0 then
        return false
    end
    if self.WeaponData.SpinUpTime and not self.State.IsSpunUp then
        return false
    end
    return true
end

function WeaponSystem:Fire()
    if not self:CanFire() then
        return false
    end

    local Now = tick()
    local FireInterval = self.WeaponData.FireRate

    if self.WeaponData.BurstCount and self.State.BurstCount > 0 then
        FireInterval = self.WeaponData.BurstDelay
    end

    if Now - self.State.LastFireTime < FireInterval then
        return false
    end

    if self.WeaponData.SpinUpTime then
        self.State.SpinUpTime = self.State.SpinUpTime + 0.05
        if self.State.SpinUpTime >= self.WeaponData.SpinUpTime then
            self.State.IsSpunUp = true
        else
            return false
        end
    end

    self.State.LastFireTime = Now

    if self.WeaponData.BurstCount then
        if self.State.BurstCount == 0 then
            self.State.BurstCount = self.WeaponData.BurstCount
        end
        self.State.BurstCount = self.State.BurstCount - 1
    else
        self.State.Magazine = self.State.Magazine - 1
    end

    self:ApplyRecoil()
    self:UpdateSpread()

    return true
end

function WeaponSystem:ApplyRecoil()
    local RecoilX = (math.random() - 0.5) * self.WeaponData.Recoil * 2
    local RecoilY = self.WeaponData.Recoil * math.random()
    self.RecoilOffset = self.RecoilOffset + Vector2.new(RecoilX, RecoilY)
end

function WeaponSystem:UpdateSpread()
    local BaseSpread = self.State.IsADS and self.WeaponData.ADSSpread or self.WeaponData.HipSpread
    local CurrentSpread = BaseSpread + (self.SpreadOffset.Magnitude * 0.1)
    local AngleX = (math.random() - 0.5) * CurrentSpread * 360
    local AngleY = (math.random() - 0.5) * CurrentSpread * 360
    self.SpreadOffset = Vector2.new(AngleX, AngleY)
end

function WeaponSystem:Reload()
    if self.State.IsReloading or self.State.Magazine == self.WeaponData.Magazine or self.State.Reserve <= 0 then
        return false
    end

    self.State.IsReloading = true
    local ReloadTime = self.WeaponData.ReloadTime or 2.0

    task.delay(ReloadTime, function()
        if self.State.IsReloading then
            local Needed = self.WeaponData.Magazine - self.State.Magazine
            local Available = math.min(Needed, self.State.Reserve)
            self.State.Magazine = self.State.Magazine + Available
            self.State.Reserve = self.State.Reserve - Available
            self.State.IsReloading = false
        end
    end)

    return true
end

function WeaponSystem:SetADS(Enabled)
    self.State.IsADS = Enabled
    if Enabled then
        self.SpreadOffset = Vector2.new()
    end
end

function WeaponSystem:GetSpread()
    return self.SpreadOffset
end

function WeaponSystem:GetRecoil()
    local Recoil = self.RecoilOffset
    self.RecoilOffset = Vector2.new(self.RecoilOffset.X * 0.8, self.RecoilOffset.Y * 0.8)
    return Recoil
end

function WeaponSystem:HasDoubleJump()
    return self.WeaponData.HasDoubleJump or false
end

function WeaponSystem:IsMelee()
    return self.WeaponData.Melee or false
end

function WeaponSystem:GetAimDirection(CameraCFrame)
    local Spread = self.SpreadOffset
    local Recoil = self:GetRecoil()
    local Direction = CameraCFrame.LookVector
    local Right = CameraCFrame.RightVector
    local Up = CameraCFrame.UpVector

    Direction = Direction + Right * (math.rad(Spread.X + Recoil.X) / 10)
    Direction = Direction + Up * (math.rad(Spread.Y + Recoil.Y) / 10)

    return Direction.Unit
end

--=============================================================================
-- COMBAT SYSTEM
--=============================================================================

local CombatSystem = {}
CombatSystem.__index = CombatSystem

function CombatSystem.new(Character)
    local self = setmetatable({}, CombatSystem)
    self.Character = Character
    self.Humanoid = Character:FindFirstChild("Humanoid")
    self.Health = CONFIG.Combat.MaxHealth
    self.Armor = 0
    self.IsDead = false
    self.LastDamageTime = 0
    self.KnockbackVelocity = Vector3.new()
    return self
end

function CombatSystem:TakeDamage(Damage, Attacker, HitPart)
    if self.IsDead then
        return 0
    end

    local ActualDamage = Damage
    local IsHeadshot = HitPart and HitPart.Name:lower():find("head")

    if IsHeadshot then
        ActualDamage = ActualDamage * CONFIG.Combat.HeadshotMultiplier
    end

    if self.Armor > 0 then
        local ArmorDamage = math.min(ActualDamage * CONFIG.Combat.ArmorDamageReduction, self.Armor)
        self.Armor = self.Armor - ArmorDamage
        ActualDamage = ActualDamage - ArmorDamage
    end

    self.Health = math.max(0, self.Health - ActualDamage)
    self.LastDamageTime = tick()

    if self.Health <= 0 then
        self:Die(Attacker)
    end

    return ActualDamage, IsHeadshot
end

function CombatSystem:Heal(Amount, IsFullHeal)
    if self.IsDead then
        return false
    end

    if IsFullHeal then
        self.Health = CONFIG.Combat.MaxHealth
        self.Armor = CONFIG.Combat.MaxArmor
    else
        self.Health = math.min(CONFIG.Combat.MaxHealth, self.Health + Amount)
    end

    return true
end

function CombatSystem:AddArmor(Amount)
    self.Armor = math.min(CONFIG.Combat.MaxArmor, self.Armor + Amount)
end

function CombatSystem:Die(Attacker)
    self.IsDead = true
    if self.Humanoid then
        self.Humanoid.Health = 0
    end

    local Player = Players:GetPlayerFromCharacter(self.Character)
    if Player and Attacker then
        local AttackerPlayer = Players:GetPlayerFromCharacter(Attacker)
        if AttackerPlayer then
            local DataManager = PlayerDataManager.new()
            local AttackerData = DataManager:GetData(AttackerPlayer)
            AttackerData.Kills = AttackerData.Kills + 1

            local VictimData = DataManager:GetData(Player)
            VictimData.Deaths = VictimData.Deaths + 1
        end
    end

    task.delay(CONFIG.Game.RespawnTime, function()
        self:Respawn()
    end)
end

function CombatSystem:Respawn()
    self.IsDead = false
    self.Health = CONFIG.Combat.MaxHealth
    self.Armor = 0
end

function CombatSystem:ApplyKnockback(Velocity)
    self.KnockbackVelocity = Velocity
end

function CombatSystem:Update(DeltaTime)
    if self.KnockbackVelocity.Magnitude > 0 then
        self.KnockbackVelocity = self.KnockbackVelocity * (1 - DeltaTime * 5)
        if self.KnockbackVelocity.Magnitude < 0.1 then
            self.KnockbackVelocity = Vector3.new()
        end
    end
end

function CombatSystem:GetHealthPercent()
    return self.Health / CONFIG.Combat.MaxHealth
end

function CombatSystem:GetArmorPercent()
    return self.Armor / CONFIG.Combat.MaxArmor
end

--=============================================================================
-- GAME MODE MANAGER
--=============================================================================

local GameModeManager = {}
GameModeManager.__index = GameModeManager

function GameModeManager.new()
    local self = setmetatable({}, GameModeManager)
    self.State = {
        Phase = "Lobby",
        CurrentRound = 0,
        Team1Score = 0,
        Team2Score = 0,
        TimeRemaining = 0,
        Players = {},
        Teams = { Team1 = {}, Team2 = {} },
        WinningTeam = nil,
        MapVoting = false,
    }
    self.EventCallbacks = {}
    return self
end

function GameModeManager:StartMatch(Team1Players, Team2Players, MapName)
    self.State.Phase = "Warmup"
    self.State.Team1Score = 0
    self.State.Team2Score = 0
    self.State.CurrentRound = 0
    self.State.Teams.Team1 = Team1Players
    self.State.Teams.Team2 = Team2Players
    self.State.MapName = MapName
    self.State.TimeRemaining = CONFIG.Game.WarmupTime

    self:StartRound()
end

function GameModeManager:StartRound()
    self.State.CurrentRound = self.State.CurrentRound + 1
    self.State.Phase = "Playing"
    self.State.TimeRemaining = CONFIG.Game.RoundTime

    for _, Player in ipairs(self.State.Teams.Team1) do
        self:SpawnPlayer(Player, "Team1")
    end
    for _, Player in ipairs(self.State.Teams.Team2) do
        self:SpawnPlayer(Player, "Team2")
    end

    self:FireEvent("RoundStart", self.State.CurrentRound)
end

function GameModeManager:SpawnPlayer(Player, Team)
    local Character = Player.Character
    if Character and Character:FindFirstChild("Humanoid") then
        Character.Humanoid.Health = CONFIG.Combat.MaxHealth
        Character.HumanoidRootPart.CFrame = self:GetSpawnCFrame(Team)
    end
end

function GameModeManager:SetSpawns(SpawnsByTeam)
    -- SpawnsByTeam: { Team1 = {CFrame, ...}, Team2 = {CFrame, ...} }
    self.Spawns = SpawnsByTeam
    self.SpawnCursor = { Team1 = 0, Team2 = 0 }
end

function GameModeManager:GetSpawnCFrame(Team)
    -- If a map's Spawns table is registered via :SetSpawns, round-robin through it.
    -- Otherwise fall back to the hardcoded ±50 spawn so tests + bare arenas still work.
    if self.Spawns and self.Spawns[Team] and #self.Spawns[Team] > 0 then
        local cursor = (self.SpawnCursor[Team] or 0) + 1
        if cursor > #self.Spawns[Team] then
            cursor = 1
        end
        self.SpawnCursor[Team] = cursor
        return self.Spawns[Team][cursor]
    end
    return CFrame.new(Team == "Team1" and -50 or 50, 10, 0)
end

function GameModeManager:EndRound(WinnerTeam)
    self.State.Phase = "RoundEnd"

    if WinnerTeam == "Team1" then
        self.State.Team1Score = self.State.Team1Score + 1
    else
        self.State.Team2Score = self.State.Team2Score + 1
    end

    self:FireEvent("RoundEnd", WinnerTeam, self.State.Team1Score, self.State.Team2Score)

    if self.State.Team1Score >= 5 or self.State.Team2Score >= 5 then
        self:EndMatch(WinnerTeam)
    else
        task.delay(5, function()
            self:StartRound()
        end)
    end
end

function GameModeManager:EndMatch(WinnerTeam)
    self.State.Phase = "MatchEnd"
    self.State.WinningTeam = WinnerTeam
    self.State.TimeRemaining = 0

    self:FireEvent("MatchEnd", WinnerTeam, self.State.Team1Score, self.State.Team2Score)

    task.delay(10, function()
        self:ReturnToLobby()
    end)
end

function GameModeManager:ReturnToLobby()
    self.State.Phase = "Lobby"
    self.State.CurrentRound = 0
    self.State.Team1Score = 0
    self.State.Team2Score = 0
end

function GameModeManager:Update(DeltaTime)
    if self.State.Phase == "Playing" then
        self.State.TimeRemaining = self.State.TimeRemaining - DeltaTime

        if self.State.TimeRemaining <= 0 then
            local Team1Alive = self:GetAliveCount("Team1")
            local Team2Alive = self:GetAliveCount("Team2")

            if Team1Alive > Team2Alive then
                self:EndRound("Team1")
            elseif Team2Alive > Team1Alive then
                self:EndRound("Team2")
            else
                self:EndRound("Draw")
            end
        end
    end
end

function GameModeManager:GetAliveCount(Team)
    local Count = 0
    for _, Player in ipairs(self.State.Teams[Team]) do
        if Player.Character and Player.Character:FindFirstChild("Humanoid") then
            if Player.Character.Humanoid.Health > 0 then
                Count = Count + 1
            end
        end
    end
    return Count
end

function GameModeManager:OnEvent(EventName, Callback)
    if not self.EventCallbacks[EventName] then
        self.EventCallbacks[EventName] = {}
    end
    table.insert(self.EventCallbacks[EventName], Callback)
end

function GameModeManager:FireEvent(EventName, ...)
    if self.EventCallbacks[EventName] then
        for _, Callback in ipairs(self.EventCallbacks[EventName]) do
            Callback(...)
        end
    end
end

--=============================================================================
-- LOBBY SYSTEM
--=============================================================================

local LobbySystem = {}
LobbySystem.__index = LobbySystem

function LobbySystem.new()
    local self = setmetatable({}, LobbySystem)
    self.Queues = {
        OneVOne = {},
        TwoVTwo = {},
        FiveVFive = {},
        Special = {},
    }
    self.Settings = {
        OneVOne = { MinPlayers = 2, MaxPlayers = 2, TeamSize = 1 },
        TwoVTwo = { MinPlayers = 4, MaxPlayers = 4, TeamSize = 2 },
        FiveVFive = { MinPlayers = 10, MaxPlayers = 10, TeamSize = 5 },
        Special = { MinPlayers = 4, MaxPlayers = 10, TeamSize = 4 },
    }
    self.MapPool = { "Arena", "Warehouse", "Downtown", "Construction", "Docks", "Bridge" }
    self.CurrentMap = "Arena"
    self.SpecialMode = "Normal"
    return self
end

function LobbySystem:JoinQueue(Player, QueueType)
    local Queue = self.Queues[QueueType]
    if not table.find(Queue, Player) then
        table.insert(Queue, Player)

        if #Queue >= self.Settings[QueueType].MaxPlayers then
            self:StartMatch(QueueType)
        end
    end
end

function LobbySystem:LeaveQueue(Player)
    for _QueueType, Queue in pairs(self.Queues) do
        local Index = table.find(Queue, Player)
        if Index then
            table.remove(Queue, Index)
        end
    end
end

function LobbySystem:StartMatch(QueueType)
    local Settings = self.Settings[QueueType]
    local MatchPlayers = {}

    for _ = 1, Settings.MaxPlayers do
        table.insert(MatchPlayers, table.remove(self.Queues[QueueType], 1))
    end

    local Team1 = {}
    local Team2 = {}

    for i, Player in ipairs(MatchPlayers) do
        if i % 2 == 1 then
            table.insert(Team1, Player)
        else
            table.insert(Team2, Player)
        end
    end

    local MapIndex = math.random(1, #self.MapPool)
    local SelectedMap = self.MapPool[MapIndex]

    local GameMode = GameModeManager.new()
    GameMode:StartMatch(Team1, Team2, SelectedMap)

    return GameMode
end

function LobbySystem:RotateSpecialMode()
    local Modes = { "BunnySniping", "MirrorMatchup", "Juggernaut", "ZombieTower" }
    local Index = math.random(1, #Modes)
    self.SpecialMode = Modes[Index]
end

--=============================================================================
-- UI SYSTEM
--=============================================================================

local UISystem = {}
UISystem.__index = UISystem

function UISystem.new(Player)
    local self = setmetatable({}, UISystem)
    self.Player = Player
    self.GUI = nil
    self.HUD = nil
    self.Crosshair = nil
    return self
end

function UISystem:CreateGUI()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "RivalsHUD"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.IgnoreGuiInset = true
    ScreenGui.Parent = self.Player:FindFirstChild("PlayerGui") or StarterGui

    self.GUI = ScreenGui
    self:CreateCrosshair(ScreenGui)
    self:CreateHealthBar(ScreenGui)
    self:CreateWeaponInfo(ScreenGui)
    self:CreateKillFeed(ScreenGui)
    self:CreateScoreboard(ScreenGui)
    self:CreateMinimap(ScreenGui)

    return ScreenGui
end

function UISystem:CreateCrosshair(Parent)
    local Crosshair = Instance.new("Frame")
    Crosshair.Size = UDim2.fromOffset(20, 20)
    Crosshair.BackgroundTransparency = 1
    Crosshair.Position = UDim2.fromScale(0.5, 0.5)
    Crosshair.AnchorPoint = Vector2.new(0.5, 0.5)
    Crosshair.Parent = Parent

    local Dot = Instance.new("Frame")
    Dot.Size = UDim2.fromOffset(4, 4)
    Dot.BackgroundColor3 = Color3.new(1, 1, 1)
    Dot.BorderSizePixel = 0
    Dot.Position = UDim2.fromScale(0.5, 0.5)
    Dot.AnchorPoint = Vector2.new(0.5, 0.5)
    Dot.Parent = Crosshair

    local Top = Instance.new("Frame")
    Top.Size = UDim2.fromOffset(2, 8)
    Top.BackgroundColor3 = Color3.new(1, 1, 1)
    Top.BorderSizePixel = 0
    Top.Position = UDim2.new(0.5, 0, 0.5, -10)
    Top.AnchorPoint = Vector2.new(0.5, 1)
    Top.Parent = Crosshair

    local Bottom = Top:Clone()
    Bottom.Position = UDim2.new(0.5, 0, 0.5, 10)
    Bottom.AnchorPoint = Vector2.new(0.5, 0)
    Bottom.Parent = Crosshair

    local Left = Instance.new("Frame")
    Left.Size = UDim2.fromOffset(8, 2)
    Left.BackgroundColor3 = Color3.new(1, 1, 1)
    Left.BorderSizePixel = 0
    Left.Position = UDim2.new(0.5, -10, 0.5, 0)
    Left.AnchorPoint = Vector2.new(1, 0.5)
    Left.Parent = Crosshair

    local Right = Left:Clone()
    Right.Position = UDim2.new(0.5, 10, 0.5, 0)
    Right.AnchorPoint = Vector2.new(0, 0.5)
    Right.Parent = Crosshair

    self.Crosshair = Crosshair
end

function UISystem:CreateHealthBar(Parent)
    local Container = Instance.new("Frame")
    Container.Size = UDim2.fromOffset(300, 60)
    Container.Position = UDim2.new(0, 20, 1, -80)
    Container.BackgroundTransparency = 1
    Container.Parent = Parent

    local HealthBar = Instance.new("Frame")
    HealthBar.Size = UDim2.new(1, 0, 0, 20)
    HealthBar.BackgroundColor3 = Color3.new(0.2, 0.8, 0.2)
    HealthBar.BorderSizePixel = 0
    HealthBar.Parent = Container

    local HealthText = Instance.new("TextLabel")
    HealthText.Size = UDim2.new(1, 0, 0, 20)
    HealthText.BackgroundTransparency = 1
    HealthText.Text = "100"
    HealthText.TextColor3 = Color3.new(1, 1, 1)
    HealthText.TextXAlignment = Enum.TextXAlignment.Center
    HealthText.Font = Enum.Font.GothamBold
    HealthText.TextSize = 16
    HealthText.Parent = HealthBar

    local ArmorBar = Instance.new("Frame")
    ArmorBar.Size = UDim2.new(0.5, 0, 0, 10)
    ArmorBar.Position = UDim2.new(0, 0, 1, 5)
    ArmorBar.BackgroundColor3 = Color3.new(0.3, 0.5, 0.8)
    ArmorBar.BorderSizePixel = 0
    ArmorBar.Parent = Container

    self.HealthBar = HealthBar
    self.HealthText = HealthText
    self.ArmorBar = ArmorBar
end

function UISystem:CreateWeaponInfo(Parent)
    local Container = Instance.new("Frame")
    Container.Size = UDim2.fromOffset(200, 80)
    Container.Position = UDim2.new(1, -220, 1, -100)
    Container.BackgroundTransparency = 1
    Container.Parent = Parent

    local WeaponName = Instance.new("TextLabel")
    WeaponName.Size = UDim2.new(1, 0, 0, 24)
    WeaponName.BackgroundTransparency = 1
    WeaponName.Text = "Assault Rifle"
    WeaponName.TextColor3 = Color3.new(1, 1, 1)
    WeaponName.TextXAlignment = Enum.TextXAlignment.Right
    WeaponName.Font = Enum.Font.GothamBold
    WeaponName.TextSize = 20
    WeaponName.Parent = Container

    local AmmoInfo = Instance.new("TextLabel")
    AmmoInfo.Size = UDim2.new(1, 0, 0, 40)
    AmmoInfo.Position = UDim2.fromOffset(0, 24)
    AmmoInfo.BackgroundTransparency = 1
    AmmoInfo.Text = "30 / 90"
    AmmoInfo.TextColor3 = Color3.new(0.8, 0.8, 0.8)
    AmmoInfo.TextXAlignment = Enum.TextXAlignment.Right
    AmmoInfo.Font = Enum.Font.Gotham
    AmmoInfo.TextSize = 32
    AmmoInfo.Parent = Container

    self.WeaponName = WeaponName
    self.AmmoInfo = AmmoInfo
end

function UISystem:CreateKillFeed(Parent)
    local Container = Instance.new("Frame")
    Container.Size = UDim2.fromOffset(350, 300)
    Container.Position = UDim2.new(1, -370, 0, 20)
    Container.BackgroundTransparency = 1
    Container.Parent = Parent

    self.KillFeedContainer = Container
    self.KillFeedEntries = {}
end

function UISystem:AddKillFeedEntry(Killer, Victim, Weapon)
    local Entry = Instance.new("Frame")
    Entry.Size = UDim2.new(1, 0, 0, 30)
    Entry.BackgroundColor3 = Color3.new(0, 0, 0)
    Entry.BackgroundTransparency = 0.5
    Entry.BorderSizePixel = 0
    Entry.Parent = self.KillFeedContainer

    local KillerName = Instance.new("TextLabel")
    KillerName.Size = UDim2.fromScale(0.45, 1)
    KillerName.BackgroundTransparency = 1
    KillerName.Text = Killer.Name
    KillerName.TextColor3 = Color3.new(0.3, 0.8, 1)
    KillerName.TextXAlignment = Enum.TextXAlignment.Right
    KillerName.Font = Enum.Font.Gotham
    KillerName.TextSize = 14
    KillerName.Parent = Entry

    local WeaponName = Instance.new("TextLabel")
    WeaponName.Size = UDim2.fromScale(0.1, 1)
    WeaponName.Position = UDim2.fromScale(0.45, 0)
    WeaponName.BackgroundTransparency = 1
    WeaponName.Text = Weapon
    WeaponName.TextColor3 = Color3.new(0.7, 0.7, 0.7)
    WeaponName.Font = Enum.Font.Gotham
    WeaponName.TextSize = 12
    WeaponName.Parent = Entry

    local VictimName = Instance.new("TextLabel")
    VictimName.Size = UDim2.fromScale(0.45, 1)
    VictimName.Position = UDim2.fromScale(0.55, 0)
    VictimName.BackgroundTransparency = 1
    VictimName.Text = Victim.Name
    VictimName.TextColor3 = Color3.new(1, 0.3, 0.3)
    VictimName.TextXAlignment = Enum.TextXAlignment.Left
    VictimName.Font = Enum.Font.Gotham
    VictimName.TextSize = 14
    VictimName.Parent = Entry

    local Index = #self.KillFeedEntries + 1
    self.KillFeedEntries[Index] = Entry

    for i = Index + 1, #self.KillFeedEntries do
        self.KillFeedEntries[i].Position = UDim2.fromOffset(0, 30 * (i - Index))
    end

    task.delay(5, function()
        if self.KillFeedEntries[Index] then
            self.KillFeedEntries[Index]:Destroy()
            table.remove(self.KillFeedEntries, Index)
        end
    end)
end

function UISystem:CreateScoreboard(Parent)
    local Container = Instance.new("Frame")
    Container.Size = UDim2.fromOffset(400, 300)
    Container.Position = UDim2.fromScale(0.5, 0.5)
    Container.AnchorPoint = Vector2.new(0.5, 0.5)
    Container.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
    Container.BackgroundTransparency = 0.3
    Container.BorderSizePixel = 0
    Container.Visible = false
    Container.Parent = Parent

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, 0, 0, 40)
    Title.BackgroundColor3 = Color3.new(0.15, 0.15, 0.15)
    Title.BorderSizePixel = 0
    Title.Text = "SCOREBOARD"
    Title.TextColor3 = Color3.new(1, 1, 1)
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 24
    Title.Parent = Container

    local Team1Score = Instance.new("TextLabel")
    Team1Score.Size = UDim2.new(0.4, 0, 0, 30)
    Team1Score.Position = UDim2.fromScale(0.05, 0.15)
    Team1Score.BackgroundTransparency = 1
    Team1Score.Text = "Team 1: 0"
    Team1Score.TextColor3 = Color3.new(0.3, 0.8, 1)
    Team1Score.Font = Enum.Font.GothamBold
    Team1Score.TextSize = 18
    Team1Score.Parent = Container

    local Team2Score = Instance.new("TextLabel")
    Team2Score.Size = UDim2.new(0.4, 0, 0, 30)
    Team2Score.Position = UDim2.fromScale(0.55, 0.15)
    Team2Score.BackgroundTransparency = 1
    Team2Score.Text = "Team 2: 0"
    Team2Score.TextColor3 = Color3.new(1, 0.3, 0.3)
    Team2Score.Font = Enum.Font.GothamBold
    Team2Score.TextSize = 18
    Team2Score.Parent = Container

    self.Scoreboard = Container
    self.Team1ScoreLabel = Team1Score
    self.Team2ScoreLabel = Team2Score
end

function UISystem:CreateMinimap(Parent)
    local Container = Instance.new("Frame")
    Container.Size = UDim2.fromOffset(150, 150)
    Container.Position = UDim2.new(1, -170, 0, 20)
    Container.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
    Container.BackgroundTransparency = 0.5
    Container.BorderSizePixel = 0
    Container.Parent = Parent

    self.Minimap = Container
end

function UISystem:UpdateHealth(Health, MaxHealth)
    local Percent = Health / MaxHealth
    self.HealthBar.Size = UDim2.new(Percent, 0, 0, 20)
    self.HealthText.Text = tostring(math.ceil(Health))

    if Percent > 0.5 then
        self.HealthBar.BackgroundColor3 = Color3.new(0.2, 0.8, 0.2)
    elseif Percent > 0.25 then
        self.HealthBar.BackgroundColor3 = Color3.new(0.8, 0.8, 0.2)
    else
        self.HealthBar.BackgroundColor3 = Color3.new(0.8, 0.2, 0.2)
    end
end

function UISystem:UpdateArmor(Armor, MaxArmor)
    local Percent = Armor / MaxArmor
    self.ArmorBar.Size = UDim2.new(Percent, 0, 0, 10)
end

function UISystem:UpdateWeapon(WeaponName, Magazine, Reserve)
    self.WeaponName.Text = WeaponName
    self.AmmoInfo.Text = string.format("%d / %d", Magazine, Reserve)
end

function UISystem:UpdateScores(Team1Score, Team2Score)
    self.Team1ScoreLabel.Text = string.format("Team 1: %d", Team1Score)
    self.Team2ScoreLabel.Text = string.format("Team 2: %d", Team2Score)
end

function UISystem:ShowScoreboard(Visible)
    self.Scoreboard.Visible = Visible
end

--=============================================================================
-- CLIENT CONTROLLER
--=============================================================================

local ClientController = {}
ClientController.__index = ClientController

function ClientController.new(Player)
    local self = setmetatable({}, ClientController)
    self.Player = Player
    self.Character = Player.Character
    self.Camera = workspace.CurrentCamera
    self.Movement = nil
    self.Weapon = nil
    self.Combat = nil
    self.UI = nil
    self.Input = {
        Forward = false,
        Backward = false,
        Left = false,
        Right = false,
        Sprint = false,
        Jump = false,
        Slide = false,
        ADS = false,
        Fire = false,
        Reload = false,
        Weapon1 = false,
        Weapon2 = false,
        Utility = false,
    }
    self.Settings = {
        MouseSensitivity = 1.0,
        ADSSensitivityMultiplier = 0.7,
        FOV = 70,
        RawInput = true,
        CrosshairSize = 1.0,
    }
    return self
end

function ClientController:Initialize()
    if self.Character then
        self.Movement = MovementSystem.new(self.Character)
        self.Combat = CombatSystem.new(self.Character)
    end

    self.UI = UISystem.new(self.Player)
    self.UI:CreateGUI()

    self:SetupInput()
    self:SetupCamera()
end

function ClientController:SetupInput()
    local ContextActionService = game:GetService("ContextActionService")

    ContextActionService:BindAction("MoveForward", function(_, _, InputState)
        self.Input.Forward = InputState == Enum.UserInputState.Begin
    end, false, Enum.KeyCode.W)

    ContextActionService:BindAction("MoveBackward", function(_, _, InputState)
        self.Input.Backward = InputState == Enum.UserInputState.Begin
    end, false, Enum.KeyCode.S)

    ContextActionService:BindAction("MoveLeft", function(_, _, InputState)
        self.Input.Left = InputState == Enum.UserInputState.Begin
    end, false, Enum.KeyCode.A)

    ContextActionService:BindAction("MoveRight", function(_, _, InputState)
        self.Input.Right = InputState == Enum.UserInputState.Begin
    end, false, Enum.KeyCode.D)

    ContextActionService:BindAction("Jump", function(_, _, InputState)
        if InputState == Enum.UserInputState.Begin then
            self.Input.Jump = true
            if self.Movement then
                self.Movement:Jump()
            end
        else
            self.Input.Jump = false
        end
    end, false, Enum.KeyCode.Space)

    ContextActionService:BindAction("Sprint", function(_, _, InputState)
        self.Input.Sprint = InputState == Enum.UserInputState.Begin
        if self.Movement then
            self.Movement:Sprint(self.Input.Sprint)
        end
    end, false, Enum.KeyCode.LeftShift)

    ContextActionService:BindAction("Slide", function(_, _, InputState)
        if InputState == Enum.UserInputState.Begin then
            self.Input.Slide = true
            if self.Movement then
                self.Movement:Slide()
            end
        else
            self.Input.Slide = false
        end
    end, false, Enum.KeyCode.LeftControl)

    ContextActionService:BindAction("ADS", function(_, _, InputState)
        self.Input.ADS = InputState == Enum.UserInputState.Begin
        if self.Weapon then
            self.Weapon:SetADS(self.Input.ADS)
        end
    end, false, Enum.UserInputType.MouseButton2)

    ContextActionService:BindAction("Fire", function(_, _, InputState)
        self.Input.Fire = InputState == Enum.UserInputState.Begin
    end, false, Enum.UserInputType.MouseButton1)

    ContextActionService:BindAction("Reload", function(_, _, InputState)
        if InputState == Enum.UserInputState.Begin and self.Weapon then
            self.Weapon:Reload()
        end
    end, false, Enum.KeyCode.R)

    ContextActionService:BindAction("Weapon1", function(_, _, InputState)
        if InputState == Enum.UserInputState.Begin then
            self:EquipWeapon(1)
        end
    end, false, Enum.KeyCode.One)

    ContextActionService:BindAction("Weapon2", function(_, _, InputState)
        if InputState == Enum.UserInputState.Begin then
            self:EquipWeapon(2)
        end
    end, false, Enum.KeyCode.Two)

    -- G = utility ability (grenade/flashbang), F = quick-melee.
    -- Both fire UseAbility:FireServer; server validates cooldown via AbilitySystem.
    local UseAbility = ReplicatedStorage:WaitForChild("UseAbility")
    ContextActionService:BindAction("Utility", function(_, _, InputState)
        if InputState == Enum.UserInputState.Begin then
            UseAbility:FireServer("Grenade")
        end
    end, false, Enum.KeyCode.G)

    ContextActionService:BindAction("QuickMelee", function(_, _, InputState)
        if InputState == Enum.UserInputState.Begin then
            UseAbility:FireServer("QuickMelee")
        end
    end, false, Enum.KeyCode.F)

    UserInputService.InputChanged:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseMovement then
            self:OnMouseMove(Input.Position)
        end
    end)
end

function ClientController:SetupCamera()
    self.Camera.CameraType = Enum.CameraType.Scriptable
    self.Camera.FieldOfView = self.Settings.FOV
end

function ClientController:OnMouseMove(Delta)
    if self.Player.Character and self.Player.Character:FindFirstChild("Humanoid") then
        local _CameraOffset = self.Player.Character:FindFirstChild("Humanoid").CameraOffset
        local Sensitivity = self.Settings.MouseSensitivity

        if self.Input.ADS then
            Sensitivity = Sensitivity * self.Settings.ADSSensitivityMultiplier
        end

        self.Camera.CFrame = self.Camera.CFrame
            * CFrame.Angles(0, math.rad(Delta.X * Sensitivity * 0.1), 0)
            * CFrame.Angles(math.rad(Delta.Y * Sensitivity * 0.1), 0, 0)
    end
end

function ClientController:EquipWeapon(Slot)
    local DataManager = PlayerDataManager.new()
    local Data = DataManager:GetData(self.Player)
    local WeaponName = Data.WeaponsOwned[Slot]

    if WeaponName and self.Character then
        self.Weapon = WeaponSystem.new(self.Character, WeaponName)

        if self.Movement then
            self.Movement:SetWeaponDoubleJump(self.Weapon:HasDoubleJump())
        end
    end
end

function ClientController:Update(DeltaTime)
    if self.Movement then
        self.Movement:Update(DeltaTime)
    end

    if self.Combat then
        self.Combat:Update(DeltaTime)
        self.UI:UpdateHealth(self.Combat.Health, CONFIG.Combat.MaxHealth)
        self.UI:UpdateArmor(self.Combat.Armor, CONFIG.Combat.MaxArmor)
    end

    if self.Weapon then
        if self.Input.Fire and self.Weapon:Fire() then
            self:ProcessShot()
        end

        self.UI:UpdateWeapon(self.Weapon.WeaponName, self.Weapon.State.Magazine, self.Weapon.State.Reserve)
    end

    self:UpdateCamera()
end

function ClientController:ProcessShot()
    -- Server-authoritative damage: client sends aim direction + weapon name,
    -- server re-raycasts from the shooter's HumanoidRootPart and validates.
    -- Client-side raycast here is only for visuals (tracer/muzzle flash) —
    -- never apply damage from this side.
    if not (self.Weapon and self.Camera) then
        return
    end

    local AimDirection = self.Weapon:GetAimDirection(self.Camera.CFrame)
    local FireWeapon = ReplicatedStorage:FindFirstChild("FireWeapon")
    if FireWeapon then
        FireWeapon:FireServer(self.Weapon.WeaponName, AimDirection)
    end

    -- Optional: client-side visual raycast (tracer line) — kept around for the
    -- HUD/cosmetics layer to consume; does not touch any state.
    local Params = RaycastParams.new()
    Params.FilterDescendantInstances = { self.Character }
    Params.FilterType = Enum.RaycastFilterType.Exclude
    local Result = workspace:Raycast(self.Camera.CFrame.Position, AimDirection * self.Weapon.WeaponData.Range, Params)
    self.LastShotResult = Result -- HUD can read this to draw a tracer or hit marker.
end

function ClientController:UpdateCamera()
    if self.Player.Character and self.Camera then
        local Character = self.Player.Character
        local Head = Character:FindFirstChild("Head")

        if Head then
            local DesiredCFrame = CFrame.new(Head.Position)

            if self.Weapon and self.Input.ADS then
                local ADSOffset = Vector3.new(0.5, -0.3, -1)
                DesiredCFrame = DesiredCFrame * CFrame.new(ADSOffset)
            end

            self.Camera.CFrame = DesiredCFrame
        end
    end
end

--=============================================================================
-- MAIN MODULE EXPORTS
--=============================================================================

--=============================================================================
-- ABILITY SYSTEM (skeleton)
--=============================================================================
-- Minimal AbilitySystem so UseAbility RemoteEvent has a real consumer + cooldown
-- enforcement. Per-player cooldown table is server-owned. Effects are stubs
-- the gameplay code can replace per-ability.

local AbilitySystem = {}
AbilitySystem.__index = AbilitySystem

AbilitySystem.Cooldowns = {
    Grenade = 8,
    Flashbang = 12,
    QuickMelee = 0.6,
}

function AbilitySystem.new()
    local self = setmetatable({}, AbilitySystem)
    self.LastUse = {} -- [Player][AbilityName] = tick()
    return self
end

function AbilitySystem:CanUse(Player, AbilityName)
    local cooldown = AbilitySystem.Cooldowns[AbilityName]
    if not cooldown then
        return false, "unknown ability"
    end
    self.LastUse[Player] = self.LastUse[Player] or {}
    local last = self.LastUse[Player][AbilityName]
    if last and (tick() - last) < cooldown then
        return false, "cooldown"
    end
    return true
end

function AbilitySystem:Use(Player, AbilityName)
    local ok, reason = self:CanUse(Player, AbilityName)
    if not ok then
        return false, reason
    end
    self.LastUse[Player][AbilityName] = tick()
    -- Hook: gameplay code wires actual VFX/damage in :Effect for now this is just bookkeeping.
    return true
end

function AbilitySystem:ClearPlayer(Player)
    self.LastUse[Player] = nil
end

local RivalsCore = {
    CONFIG = CONFIG,
    WEAPONS = WEAPONS,
    PlayerDataManager = PlayerDataManager,
    MovementSystem = MovementSystem,
    WeaponSystem = WeaponSystem,
    CombatSystem = CombatSystem,
    AbilitySystem = AbilitySystem,
    GameModeManager = GameModeManager,
    LobbySystem = LobbySystem,
    UISystem = UISystem,
    ClientController = ClientController,
}

return RivalsCore
