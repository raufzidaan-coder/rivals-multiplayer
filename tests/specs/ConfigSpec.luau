--[[
    R.* config + WEAPONS spec — verifies CONFIG values + WEAPONS table.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RivalsCore = require(ReplicatedStorage:WaitForChild("RivalsCore"))
local TestRunner = require(script.Parent.Parent:WaitForChild("TestRunner"))

return TestRunner.describe("CONFIG + WEAPONS", function(it)
    it("CONFIG.Movement values match docs", function(expect)
        expect.equal(RivalsCore.CONFIG.Movement.WalkSpeed, 16)
        expect.equal(RivalsCore.CONFIG.Movement.SprintSpeed, 20)
        expect.equal(RivalsCore.CONFIG.Movement.SlideSpeed, 26)
        expect.equal(RivalsCore.CONFIG.Movement.JumpPower, 20)
        expect.equal(RivalsCore.CONFIG.Movement.DoubleJumpPower, 24)
        expect.equal(RivalsCore.CONFIG.Movement.WallRunSpeed, 22)
        expect.equal(RivalsCore.CONFIG.Movement.WallSlideSpeed, 8)
    end)

    it("CONFIG.Combat values match docs", function(expect)
        expect.equal(RivalsCore.CONFIG.Combat.HeadshotMultiplier, 2.0)
        expect.equal(RivalsCore.CONFIG.Combat.MaxHealth, 100)
        expect.equal(RivalsCore.CONFIG.Combat.MaxArmor, 50)
        expect.equal(RivalsCore.CONFIG.Combat.ArmorDamageReduction, 0.5)
        expect.falsy(RivalsCore.CONFIG.Combat.FallDamageEnabled)
    end)

    it("CONFIG.Game values match docs", function(expect)
        expect.equal(RivalsCore.CONFIG.Game.RoundTime, 120)
        expect.equal(RivalsCore.CONFIG.Game.RespawnTime, 3)
        expect.equal(RivalsCore.CONFIG.Game.MaxPlayersPerTeam, 5)
        expect.equal(RivalsCore.CONFIG.Game.LevelRequirement, 50)
        expect.equal(RivalsCore.CONFIG.Game.RankedAgeRequirement, 14)
    end)

    it("CONFIG.Weapons.QuickSwitchMax == 2", function(expect)
        expect.equal(RivalsCore.CONFIG.Weapons.QuickSwitchMax, 2)
    end)

    it("CONFIG.Ranks defines tiered ELO bands", function(expect)
        expect.truthy(RivalsCore.CONFIG.Ranks)
        expect.ge(#RivalsCore.CONFIG.Ranks, 4)
        expect.equal(RivalsCore.CONFIG.Ranks[1].Name, "Bronze")
        expect.equal(RivalsCore.CONFIG.Ranks[1].Min, 0)
    end)

    it("WEAPONS table has primary weapons", function(expect)
        expect.truthy(RivalsCore.WEAPONS.AssaultRifle)
        expect.truthy(RivalsCore.WEAPONS.Shotgun)
        expect.truthy(RivalsCore.WEAPONS.Sniper)
        expect.truthy(RivalsCore.WEAPONS.Bow)
    end)

    it("AssaultRifle has expected stats", function(expect)
        local ar = RivalsCore.WEAPONS.AssaultRifle
        expect.equal(ar.Damage, 15)
        expect.equal(ar.FireRate, 0.1)
        expect.equal(ar.Magazine, 30)
        expect.equal(ar.Reserve, 90)
        expect.equal(ar.ReloadTime, 2.5)
        expect.equal(ar.Category, "Primary")
        expect.equal(ar.BulletType, "Hitscan")
    end)

    it("Sniper one-shots full-HP target via headshot", function(expect)
        local sniper = RivalsCore.WEAPONS.Sniper
        local headshotDmg = sniper.Damage * RivalsCore.CONFIG.Combat.HeadshotMultiplier
        expect.ge(headshotDmg, RivalsCore.CONFIG.Combat.MaxHealth)
    end)

    it("Bow has HasDoubleJump perk", function(expect)
        expect.truthy(RivalsCore.WEAPONS.Bow.HasDoubleJump)
    end)
end)
