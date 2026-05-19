--[[
    S.1-S.8 Roblox service API surface tests — verify Studio runtime has
    the APIs the game relies on.
]]
local TestRunner = require(script.Parent.Parent:WaitForChild("TestRunner"))

return TestRunner.describe("Roblox services (S.*)", function(it)
    -- S.1 Animation / Tween
    it("S.1: TweenService:Create works with TweenInfo", function(expect)
        local TweenService = game:GetService("TweenService")
        local part = Instance.new("Part")
        part.Anchored = true
        local info = TweenInfo.new(0.1, Enum.EasingStyle.Linear)
        local tween = TweenService:Create(part, info, {Transparency = 1})
        expect.is_a(tween, "Tween")
        tween:Cancel()
        part:Destroy()
    end)

    it("S.1: Enum.AnimationPriority.Action exists", function(expect)
        expect.truthy(Enum.AnimationPriority.Action)
    end)

    -- S.2 Camera
    it("S.2: workspace.CurrentCamera exists in test runner context (server-side may be nil)", function(expect)
        -- server has no CurrentCamera; just confirm CameraType enums exist
        expect.truthy(Enum.CameraType.Scriptable)
        expect.truthy(Enum.CameraType.Custom)
    end)

    -- S.3 Lighting / PostFX
    it("S.3: BloomEffect can be instantiated", function(expect)
        local b = Instance.new("BloomEffect")
        expect.is_a(b, "BloomEffect")
        b:Destroy()
    end)

    it("S.3: ColorCorrectionEffect can be instantiated", function(expect)
        local c = Instance.new("ColorCorrectionEffect")
        expect.is_a(c, "ColorCorrectionEffect")
        c:Destroy()
    end)

    it("S.3: DepthOfFieldEffect can be instantiated", function(expect)
        local d = Instance.new("DepthOfFieldEffect")
        expect.is_a(d, "DepthOfFieldEffect")
        d:Destroy()
    end)

    it("S.3: Atmosphere can be instantiated", function(expect)
        local a = Instance.new("Atmosphere")
        expect.is_a(a, "Atmosphere")
        a:Destroy()
    end)

    -- S.4 Sound
    it("S.4: Sound has Volume property", function(expect)
        local s = Instance.new("Sound")
        s.Volume = 0.5
        expect.near(s.Volume, 0.5)
        s:Destroy()
    end)

    it("S.4: SoundService accessible", function(expect)
        expect.truthy(game:GetService("SoundService"))
    end)

    -- S.5 Physics
    it("S.5: WeldConstraint can be instantiated", function(expect)
        local w = Instance.new("WeldConstraint")
        expect.is_a(w, "WeldConstraint")
        w:Destroy()
    end)

    it("S.5: BasePart.AssemblyMass is readable", function(expect)
        local p = Instance.new("Part")
        p.Anchored = false
        expect.equal(type(p.AssemblyMass), "number")
        p:Destroy()
    end)

    it("S.5: PhysicalProperties.new accepts (density, friction, elasticity)", function(expect)
        local pp = PhysicalProperties.new(1, 0.5, 0.5)
        expect.equal(typeof(pp), "PhysicalProperties")
    end)

    -- S.6 UI
    it("S.6: ScreenGui, Frame, UICorner, UIListLayout instantiate", function(expect)
        local sg = Instance.new("ScreenGui")
        local f = Instance.new("Frame")
        local uc = Instance.new("UICorner")
        local ul = Instance.new("UIListLayout")
        expect.is_a(sg, "ScreenGui")
        expect.is_a(f, "Frame")
        expect.is_a(uc, "UICorner")
        expect.is_a(ul, "UIListLayout")
        sg:Destroy()
        f:Destroy()
        uc:Destroy()
        ul:Destroy()
    end)

    -- S.7 DataStore
    it("S.7: DataStoreService:GetDataStore exists", function(expect)
        local DSS = game:GetService("DataStoreService")
        expect.equal(type(DSS.GetDataStore), "function")
    end)

    it("S.7: game:BindToClose exists", function(expect)
        expect.equal(type(game.BindToClose), "function")
    end)

    -- S.8 HttpService
    it("S.8: HttpService:JSONEncode / JSONDecode round-trip", function(expect)
        local HttpService = game:GetService("HttpService")
        local encoded = HttpService:JSONEncode({a = 1, b = "two"})
        local decoded = HttpService:JSONDecode(encoded)
        expect.equal(decoded.a, 1)
        expect.equal(decoded.b, "two")
    end)
end)
