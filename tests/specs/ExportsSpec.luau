--[[
    R.* exports spec — every documented class is exported and constructible.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RivalsCore = require(ReplicatedStorage:WaitForChild("RivalsCore"))
local TestRunner = require(script.Parent.Parent:WaitForChild("TestRunner"))

return TestRunner.describe("RivalsCore exports", function(it)
    it("CONFIG + WEAPONS exported as tables", function(expect)
        expect.equal(type(RivalsCore.CONFIG), "table")
        expect.equal(type(RivalsCore.WEAPONS), "table")
    end)

    it("All 9 system classes exported", function(expect)
        expect.equal(type(RivalsCore.PlayerDataManager), "table")
        expect.equal(type(RivalsCore.MovementSystem), "table")
        expect.equal(type(RivalsCore.WeaponSystem), "table")
        expect.equal(type(RivalsCore.CombatSystem), "table")
        expect.equal(type(RivalsCore.AbilitySystem), "table")
        expect.equal(type(RivalsCore.GameModeManager), "table")
        expect.equal(type(RivalsCore.LobbySystem), "table")
        expect.equal(type(RivalsCore.UISystem), "table")
        expect.equal(type(RivalsCore.ClientController), "table")
    end)

    it("AbilitySystem has Use/CanUse/ClearPlayer methods", function(expect)
        local A = RivalsCore.AbilitySystem
        expect.equal(type(A.new), "function")
        expect.equal(type(A.Use), "function")
        expect.equal(type(A.CanUse), "function")
        expect.equal(type(A.ClearPlayer), "function")
        expect.equal(type(A.Cooldowns), "table")
    end)

    it("PlayerDataManager.new() returns object with GetData", function(expect)
        local pdm = RivalsCore.PlayerDataManager.new()
        expect.truthy(pdm)
        expect.equal(type(pdm.GetData), "function")
        expect.equal(type(pdm.AddXP), "function")
        expect.equal(type(pdm.CanPlayRanked), "function")
        expect.equal(type(pdm.GetRank), "function")
    end)

    it("MovementSystem has expected methods", function(expect)
        local m = RivalsCore.MovementSystem
        expect.equal(type(m.new), "function")
        expect.equal(type(m.Slide), "function")
        expect.equal(type(m.StopSlide), "function")
        expect.equal(type(m.Jump), "function")
        expect.equal(type(m.Sprint), "function")
        expect.equal(type(m.Update), "function")
        expect.equal(type(m.SetWeaponDoubleJump), "function")
    end)

    it("WeaponSystem has expected methods", function(expect)
        local w = RivalsCore.WeaponSystem
        expect.equal(type(w.new), "function")
        expect.equal(type(w.CanFire), "function")
        expect.equal(type(w.Fire), "function")
        expect.equal(type(w.Reload), "function")
        expect.equal(type(w.SetADS), "function")
        expect.equal(type(w.IsMelee), "function")
        expect.equal(type(w.HasDoubleJump), "function")
    end)

    it("CombatSystem has expected methods", function(expect)
        local c = RivalsCore.CombatSystem
        expect.equal(type(c.new), "function")
        expect.equal(type(c.TakeDamage), "function")
        expect.equal(type(c.Heal), "function")
        expect.equal(type(c.AddArmor), "function")
        expect.equal(type(c.Die), "function")
        expect.equal(type(c.ApplyKnockback), "function")
        expect.equal(type(c.GetHealthPercent), "function")
    end)

    it("GameModeManager has expected methods", function(expect)
        local g = RivalsCore.GameModeManager
        expect.equal(type(g.new), "function")
        expect.equal(type(g.StartMatch), "function")
        expect.equal(type(g.StartRound), "function")
        expect.equal(type(g.EndRound), "function")
        expect.equal(type(g.GetSpawnCFrame), "function")
        expect.equal(type(g.GetAliveCount), "function")
    end)

    it("LobbySystem has expected methods", function(expect)
        local l = RivalsCore.LobbySystem
        expect.equal(type(l.new), "function")
        expect.equal(type(l.JoinQueue), "function")
        expect.equal(type(l.LeaveQueue), "function")
        expect.equal(type(l.StartMatch), "function")
    end)
end)
