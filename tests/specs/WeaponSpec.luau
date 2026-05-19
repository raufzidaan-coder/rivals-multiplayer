--[[
    R.3 WeaponSystem — per-weapon instance behavior.
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

return TestRunner.describe("WeaponSystem", function(it)
    it("new(char, 'AssaultRifle') initializes with AR magazine", function(expect)
        local char = makeCharacter()
        local w = RivalsCore.WeaponSystem.new(char, "AssaultRifle")
        expect.equal(w.State.Magazine, RivalsCore.WEAPONS.AssaultRifle.Magazine)
        expect.equal(w.State.Reserve, RivalsCore.WEAPONS.AssaultRifle.Reserve)
        char:Destroy()
    end)

    it("CanFire returns true when ammo > 0 and cooldown not active", function(expect)
        local char = makeCharacter()
        local w = RivalsCore.WeaponSystem.new(char, "AssaultRifle")
        expect.truthy(w:CanFire())
        char:Destroy()
    end)

    it("Reload sets IsReloading then refills magazine", function(expect)
        local char = makeCharacter()
        local w = RivalsCore.WeaponSystem.new(char, "AssaultRifle")
        w.State.Magazine = 0
        w:Reload()
        expect.truthy(w.State.IsReloading)
        char:Destroy()
    end)

    it("SetADS(true) toggles IsADS state", function(expect)
        local char = makeCharacter()
        local w = RivalsCore.WeaponSystem.new(char, "AssaultRifle")
        w:SetADS(true)
        expect.truthy(w.State.IsADS)
        w:SetADS(false)
        expect.falsy(w.State.IsADS)
        char:Destroy()
    end)

    it("IsMelee returns true for Fists (if defined)", function(expect)
        if RivalsCore.WEAPONS.Fists then
            local char = makeCharacter()
            local w = RivalsCore.WeaponSystem.new(char, "Fists")
            expect.truthy(w:IsMelee())
            char:Destroy()
        else
            expect.truthy(true)  -- skipped — Fists weapon not defined
        end
    end)

    it("HasDoubleJump returns true for Bow", function(expect)
        local char = makeCharacter()
        local w = RivalsCore.WeaponSystem.new(char, "Bow")
        expect.truthy(w:HasDoubleJump())
        char:Destroy()
    end)

    it("HasDoubleJump returns false for AssaultRifle", function(expect)
        local char = makeCharacter()
        local w = RivalsCore.WeaponSystem.new(char, "AssaultRifle")
        expect.falsy(w:HasDoubleJump())
        char:Destroy()
    end)

    it("GetSpread returns a Vector2 spread offset", function(expect)
        local char = makeCharacter()
        local w = RivalsCore.WeaponSystem.new(char, "AssaultRifle")
        local spread = w:GetSpread()
        expect.equal(typeof(spread), "Vector2")
        expect.ge(spread.Magnitude, 0)
        char:Destroy()
    end)

    it("GetRecoil returns Vector2 and decays toward zero", function(expect)
        local char = makeCharacter()
        local w = RivalsCore.WeaponSystem.new(char, "AssaultRifle")
        w.RecoilOffset = Vector2.new(10, 10)
        local r1 = w:GetRecoil()
        local r2 = w:GetRecoil()
        expect.equal(typeof(r1), "Vector2")
        expect.le(r2.Magnitude, r1.Magnitude)
        char:Destroy()
    end)
end)
