--[[
    R.7 PlayerDataManager.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RivalsCore = require(ReplicatedStorage:WaitForChild("RivalsCore"))
local TestRunner = require(script.Parent.Parent:WaitForChild("TestRunner"))

return TestRunner.describe("PlayerDataManager", function(it)
    it("new() returns object with empty profile cache", function(expect)
        local pdm = RivalsCore.PlayerDataManager.new()
        expect.truthy(pdm)
        expect.equal(type(pdm.GetData), "function")
    end)

    it("GetRank(0) returns Bronze", function(expect)
        local pdm = RivalsCore.PlayerDataManager.new()
        local rank = pdm:GetRank(0)
        expect.equal(rank, "Bronze")
    end)

    it("GetRank(800) returns Silver", function(expect)
        local pdm = RivalsCore.PlayerDataManager.new()
        local rank = pdm:GetRank(800)
        expect.equal(rank, "Silver")
    end)

    it("GetRank for top-band returns highest rank", function(expect)
        local pdm = RivalsCore.PlayerDataManager.new()
        local topRank = RivalsCore.CONFIG.Ranks[#RivalsCore.CONFIG.Ranks]
        local rank = pdm:GetRank(topRank.Min + 100)
        expect.equal(rank, topRank.Name)
    end)
end)
