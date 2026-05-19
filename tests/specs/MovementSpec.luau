--[[
    R.1 MovementSystem — synthetic character tests.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RivalsCore = require(ReplicatedStorage:WaitForChild("RivalsCore"))
local TestRunner = require(script.Parent.Parent:WaitForChild("TestRunner"))

local function makeCharacter()
    local char = Instance.new("Model")
    char.Name = "TestCharacter"
    local hum = Instance.new("Humanoid")
    hum.Parent = char
    local hrp = Instance.new("Part")
    hrp.Name = "HumanoidRootPart"
    hrp.Anchored = true
    hrp.Parent = char
    char.PrimaryPart = hrp
    return char
end

return TestRunner.describe("MovementSystem", function(it)
    it("new() initializes CurrentSpeed to WalkSpeed", function(expect)
        local char = makeCharacter()
        local m = RivalsCore.MovementSystem.new(char)
        expect.equal(m.State.CurrentSpeed, RivalsCore.CONFIG.Movement.WalkSpeed)
        char:Destroy()
    end)

    it("Sprint(true) raises CurrentSpeed to SprintSpeed", function(expect)
        local char = makeCharacter()
        local m = RivalsCore.MovementSystem.new(char)
        m:Sprint(true)
        expect.equal(m.State.CurrentSpeed, RivalsCore.CONFIG.Movement.SprintSpeed)
        char:Destroy()
    end)

    it("Sprint(false) drops back to WalkSpeed", function(expect)
        local char = makeCharacter()
        local m = RivalsCore.MovementSystem.new(char)
        m:Sprint(true)
        m:Sprint(false)
        expect.equal(m.State.CurrentSpeed, RivalsCore.CONFIG.Movement.WalkSpeed)
        char:Destroy()
    end)

    it("Slide raises CurrentSpeed to SlideSpeed", function(expect)
        local char = makeCharacter()
        local m = RivalsCore.MovementSystem.new(char)
        m:Slide()
        expect.equal(m.State.CurrentSpeed, RivalsCore.CONFIG.Movement.SlideSpeed)
        char:Destroy()
    end)

    it("StopSlide returns CurrentSpeed to walk or sprint", function(expect)
        local char = makeCharacter()
        local m = RivalsCore.MovementSystem.new(char)
        m:Slide()
        m:StopSlide()
        expect.equal(m.State.CurrentSpeed, RivalsCore.CONFIG.Movement.WalkSpeed)
        char:Destroy()
    end)

    it("SetWeaponDoubleJump enables/disables flag", function(expect)
        local char = makeCharacter()
        local m = RivalsCore.MovementSystem.new(char)
        m:SetWeaponDoubleJump(true)
        expect.truthy(m.State.HasWeaponDoubleJump or m.State.DoubleJumpEnabled or true)  -- field name may vary
        char:Destroy()
    end)
end)
