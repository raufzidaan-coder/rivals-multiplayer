--[[
    R.6 GameModeManager.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RivalsCore = require(ReplicatedStorage:WaitForChild("RivalsCore"))
local TestRunner = require(script.Parent.Parent:WaitForChild("TestRunner"))

return TestRunner.describe("GameModeManager", function(it)
    it("new() returns object with State table", function(expect)
        local gm = RivalsCore.GameModeManager.new()
        expect.truthy(gm)
        expect.equal(type(gm.State), "table")
    end)

    it("GetSpawnCFrame returns a CFrame for Team1", function(expect)
        local gm = RivalsCore.GameModeManager.new()
        local cf = gm:GetSpawnCFrame("Team1")
        expect.equal(typeof(cf), "CFrame")
    end)

    it("GetSpawnCFrame returns a CFrame for Team2", function(expect)
        local gm = RivalsCore.GameModeManager.new()
        local cf = gm:GetSpawnCFrame("Team2")
        expect.equal(typeof(cf), "CFrame")
    end)

    it("GetAliveCount returns 0 for empty team", function(expect)
        local gm = RivalsCore.GameModeManager.new()
        local count = gm:GetAliveCount("Team1")
        expect.equal(count, 0)
    end)

    it("OnEvent + FireEvent dispatch works", function(expect)
        local gm = RivalsCore.GameModeManager.new()
        local hit = false
        gm:OnEvent("TestPing", function() hit = true end)
        gm:FireEvent("TestPing")
        expect.truthy(hit)
    end)
end)
