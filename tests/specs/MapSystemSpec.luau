--[[
    R.8 MapSystem.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MapSystem = require(ReplicatedStorage:WaitForChild("MapSystem"))
local TestRunner = require(script.Parent.Parent:WaitForChild("TestRunner"))

return TestRunner.describe("MapSystem", function(it)
    it("new() returns object with builders", function(expect)
        local m = MapSystem.new()
        expect.truthy(m)
        expect.equal(type(m.CreateArena), "function")
        expect.equal(type(m.CreateWarehouse), "function")
        expect.equal(type(m.CreateDowntown), "function")
        expect.equal(type(m.LoadMap), "function")
        expect.equal(type(m.DeleteMap), "function")
    end)

    it("CreateArena creates a Folder named 'Arena' in workspace", function(expect)
        local m = MapSystem.new()
        m:CreateArena()
        local f = workspace:FindFirstChild("Arena")
        expect.is_a(f, "Folder")
        expect.truthy(f:FindFirstChild("Floor"))
        if f then
            f:Destroy()
        end
    end)

    it("CreateWarehouse creates a 'Warehouse' folder", function(expect)
        local m = MapSystem.new()
        m:CreateWarehouse()
        local f = workspace:FindFirstChild("Warehouse")
        expect.is_a(f, "Folder")
        if f then
            f:Destroy()
        end
    end)

    it("LoadMap returns false for unregistered map (preserves current)", function(expect)
        local m = MapSystem.new()
        local ok = m:LoadMap("NonexistentMap")
        expect.falsy(ok)
    end)

    it("DeleteMap is safe on non-existent map", function(expect)
        local m = MapSystem.new()
        local ok = pcall(function()
            m:DeleteMap("NonexistentMap")
        end)
        expect.truthy(ok)
    end)
end)
