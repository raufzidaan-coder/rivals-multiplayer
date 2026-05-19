--[[
    R.10 Settings module.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Settings = require(ReplicatedStorage:WaitForChild("Settings"))
local TestRunner = require(script.Parent.Parent:WaitForChild("TestRunner"))

return TestRunner.describe("Settings", function(it)
    it("Settings module exports a single table", function(expect)
        expect.equal(type(Settings), "table")
    end)

    it("Settings exposes UI builder under .UI", function(expect)
        expect.equal(type(Settings.UI), "table")
        expect.equal(type(Settings.UI.new), "function")
    end)

    it("Settings.UI:CreateMenu/Slider/Toggle exist", function(expect)
        expect.equal(type(Settings.UI.CreateMenu), "function")
        expect.equal(type(Settings.UI.CreateSlider), "function")
        expect.equal(type(Settings.UI.CreateToggle), "function")
    end)
end)
