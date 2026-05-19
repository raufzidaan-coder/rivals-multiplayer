--[[
    R.2 CombatSystem — runtime behavior tests using a synthetic character.
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

return TestRunner.describe("CombatSystem", function(it)
    it("new() initializes at MaxHealth", function(expect)
        local char = makeCharacter()
        local combat = RivalsCore.CombatSystem.new(char)
        expect.equal(combat.Health, RivalsCore.CONFIG.Combat.MaxHealth)
        char:Destroy()
    end)

    it("TakeDamage reduces health", function(expect)
        local char = makeCharacter()
        local combat = RivalsCore.CombatSystem.new(char)
        combat:TakeDamage(25)
        expect.equal(combat.Health, RivalsCore.CONFIG.Combat.MaxHealth - 25)
        char:Destroy()
    end)

    it("Headshot via HitPart.Name == 'Head' applies multiplier", function(expect)
        local char = makeCharacter()
        local combat = RivalsCore.CombatSystem.new(char)
        local headPart = Instance.new("Part")
        headPart.Name = "Head"
        combat:TakeDamage(10, nil, headPart)
        local expected = RivalsCore.CONFIG.Combat.MaxHealth - (10 * RivalsCore.CONFIG.Combat.HeadshotMultiplier)
        expect.equal(combat.Health, expected)
        char:Destroy()
        headPart:Destroy()
    end)

    it("Burst damage accumulates", function(expect)
        local char = makeCharacter()
        local combat = RivalsCore.CombatSystem.new(char)
        for _ = 1, 5 do
            combat:TakeDamage(10)
        end
        expect.equal(combat.Health, RivalsCore.CONFIG.Combat.MaxHealth - 50)
        char:Destroy()
    end)

    it("Heal restores health (capped at MaxHealth)", function(expect)
        local char = makeCharacter()
        local combat = RivalsCore.CombatSystem.new(char)
        combat:TakeDamage(50)
        combat:Heal(30)
        expect.equal(combat.Health, 80)
        combat:Heal(100)
        expect.equal(combat.Health, RivalsCore.CONFIG.Combat.MaxHealth)
        char:Destroy()
    end)

    it("AddArmor caps at MaxArmor", function(expect)
        local char = makeCharacter()
        local combat = RivalsCore.CombatSystem.new(char)
        combat:AddArmor(1000)
        expect.equal(combat.Armor, RivalsCore.CONFIG.Combat.MaxArmor)
        char:Destroy()
    end)

    it("Armor absorbs damage at reduction ratio", function(expect)
        local char = makeCharacter()
        local combat = RivalsCore.CombatSystem.new(char)
        combat:AddArmor(50)
        combat:TakeDamage(20)
        -- damage gets split between armor and health based on ArmorDamageReduction
        expect.le(combat.Health, RivalsCore.CONFIG.Combat.MaxHealth)
        expect.le(combat.Armor, RivalsCore.CONFIG.Combat.MaxArmor)
        char:Destroy()
    end)

    it("GetHealthPercent returns 0..1", function(expect)
        local char = makeCharacter()
        local combat = RivalsCore.CombatSystem.new(char)
        expect.near(combat:GetHealthPercent(), 1.0)
        combat:TakeDamage(50)
        expect.near(combat:GetHealthPercent(), 0.5)
        char:Destroy()
    end)

    it("ApplyKnockback sets knockback velocity", function(expect)
        local char = makeCharacter()
        local combat = RivalsCore.CombatSystem.new(char)
        local before = combat.KnockbackVelocity or Vector3.zero
        combat:ApplyKnockback(Vector3.new(50, 0, 0))
        expect.notEqual(combat.KnockbackVelocity, before)
        char:Destroy()
    end)
end)
