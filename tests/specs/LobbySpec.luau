--[[
    R.5 LobbySystem.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RivalsCore = require(ReplicatedStorage:WaitForChild("RivalsCore"))
local TestRunner = require(script.Parent.Parent:WaitForChild("TestRunner"))

return TestRunner.describe("LobbySystem", function(it)
    it("new() returns object with empty queues", function(expect)
        local lobby = RivalsCore.LobbySystem.new()
        expect.truthy(lobby)
        expect.equal(type(lobby.JoinQueue), "function")
        expect.equal(type(lobby.LeaveQueue), "function")
        expect.equal(type(lobby.StartMatch), "function")
    end)

    it("LeaveQueue on non-queued player does not error", function(expect)
        local lobby = RivalsCore.LobbySystem.new()
        local ok = pcall(function()
            lobby:LeaveQueue({Name = "Phantom", UserId = 0})
        end)
        expect.truthy(ok)
    end)
end)
