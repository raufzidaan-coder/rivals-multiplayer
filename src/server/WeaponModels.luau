--[[
    WeaponModels — procedural weapon Tool factory (server-only).

    Each weapon is a function returning a `Tool` instance with a `Handle` part
    + welded cosmetic parts. The Tool is attached to the character via
    ClientController:EquipWeapon (RivalsCore.luau) — this module only supplies
    the model.

    Style: every cosmetic part is `Massless=true`, `CanCollide=false`,
    `CanQuery=false`, welded to Handle via WeldConstraint. Anchored=false
    (Tools require unanchored parts to follow the avatar).

    Fists has no entry — bare hands is correct per research T-A7.
]]

local WeaponModels = {}

local STEEL = BrickColor.new("Dark stone grey")
local BLACK = BrickColor.new("Really black")
local WOOD = BrickColor.new("Reddish brown")
local TAN = BrickColor.new("Brown")
local BRASS = BrickColor.new("Cool yellow")

-- Welds child to base via WeldConstraint. Caller sets child.CFrame BEFORE call.
local function weld(base, child)
    local wc = Instance.new("WeldConstraint")
    wc.Part0 = base
    wc.Part1 = child
    wc.Parent = base
end

local function cosmetic(name, size, color, material, shape)
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.BrickColor = color or STEEL
    p.Material = material or Enum.Material.Metal
    p.Shape = shape or Enum.PartType.Block
    p.Massless = true
    p.CanCollide = false
    p.CanQuery = false
    p.CanTouch = false
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    return p
end

local function makeTool(weaponName, handleSize, handleColor, handleMaterial, builder)
    local tool = Instance.new("Tool")
    tool.Name = weaponName
    tool.RequiresHandle = true
    tool.CanBeDropped = false
    tool.ManualActivationOnly = false

    local handle = Instance.new("Part")
    handle.Name = "Handle"
    handle.Size = handleSize
    handle.BrickColor = handleColor or STEEL
    handle.Material = handleMaterial or Enum.Material.Metal
    handle.Massless = false
    handle.CanCollide = false
    handle.TopSurface = Enum.SurfaceType.Smooth
    handle.BottomSurface = Enum.SurfaceType.Smooth
    handle.Parent = tool

    -- MuzzlePoint attachment: ClientController:SpawnShotVisuals reads this
    -- for tracer/flash origin instead of HRP.
    local muzzle = Instance.new("Attachment")
    muzzle.Name = "MuzzlePoint"
    muzzle.Parent = handle

    builder(tool, handle, muzzle)
    return tool
end

-- =========================================================================
-- AssaultRifle
-- =========================================================================
function WeaponModels.BuildAssaultRifle()
    return makeTool(
        "AssaultRifle",
        Vector3.new(2.4, 0.5, 0.4),
        STEEL,
        Enum.Material.Metal,
        function(tool, handle, muzzle)
            local barrel =
                cosmetic("Barrel", Vector3.new(1.6, 0.25, 0.25), BLACK, Enum.Material.Metal, Enum.PartType.Cylinder)
            barrel.CFrame = handle.CFrame * CFrame.new(2, 0, 0) * CFrame.Angles(0, 0, math.rad(90))
            weld(handle, barrel)
            barrel.Parent = tool

            local stock = cosmetic("Stock", Vector3.new(1, 0.45, 0.3), WOOD, Enum.Material.Wood)
            stock.CFrame = handle.CFrame * CFrame.new(-1.7, 0, 0)
            weld(handle, stock)
            stock.Parent = tool

            local mag = cosmetic("Magazine", Vector3.new(0.4, 0.8, 0.3), BLACK, Enum.Material.Metal)
            mag.CFrame = handle.CFrame * CFrame.new(0.2, -0.55, 0)
            weld(handle, mag)
            mag.Parent = tool

            local sight = cosmetic("Sight", Vector3.new(0.2, 0.25, 0.3), STEEL, Enum.Material.Metal)
            sight.CFrame = handle.CFrame * CFrame.new(0, 0.4, 0)
            weld(handle, sight)
            sight.Parent = tool

            muzzle.Position = Vector3.new(2.8, 0, 0)
            tool.Grip = CFrame.new(0, -0.5, 0) * CFrame.Angles(0, math.rad(90), 0)
        end
    )
end

-- =========================================================================
-- Shotgun
-- =========================================================================
function WeaponModels.BuildShotgun()
    return makeTool("Shotgun", Vector3.new(2.2, 0.5, 0.4), WOOD, Enum.Material.Wood, function(tool, handle, muzzle)
        local receiver = cosmetic("Receiver", Vector3.new(0.9, 0.55, 0.45), STEEL, Enum.Material.Metal)
        receiver.CFrame = handle.CFrame * CFrame.new(-0.2, 0, 0)
        weld(handle, receiver)
        receiver.Parent = tool

        local barrel =
            cosmetic("Barrel", Vector3.new(2.2, 0.3, 0.3), BLACK, Enum.Material.Metal, Enum.PartType.Cylinder)
        barrel.CFrame = handle.CFrame * CFrame.new(2, 0, 0) * CFrame.Angles(0, 0, math.rad(90))
        weld(handle, barrel)
        barrel.Parent = tool

        local pump = cosmetic("Pump", Vector3.new(0.7, 0.3, 0.3), WOOD, Enum.Material.Wood)
        pump.CFrame = handle.CFrame * CFrame.new(1.2, -0.35, 0)
        weld(handle, pump)
        pump.Parent = tool

        muzzle.Position = Vector3.new(3.1, 0, 0)
        tool.Grip = CFrame.new(0, -0.5, 0) * CFrame.Angles(0, math.rad(90), 0)
    end)
end

-- =========================================================================
-- Sniper
-- =========================================================================
function WeaponModels.BuildSniper()
    return makeTool("Sniper", Vector3.new(3, 0.5, 0.4), WOOD, Enum.Material.Wood, function(tool, handle, muzzle)
        local receiver = cosmetic("Receiver", Vector3.new(1.4, 0.6, 0.5), STEEL, Enum.Material.Metal)
        receiver.CFrame = handle.CFrame * CFrame.new(-0.3, 0.05, 0)
        weld(handle, receiver)
        receiver.Parent = tool

        local barrel =
            cosmetic("Barrel", Vector3.new(4, 0.28, 0.28), BLACK, Enum.Material.Metal, Enum.PartType.Cylinder)
        barrel.CFrame = handle.CFrame * CFrame.new(2.8, 0.05, 0) * CFrame.Angles(0, 0, math.rad(90))
        weld(handle, barrel)
        barrel.Parent = tool

        local scope = cosmetic("Scope", Vector3.new(1.6, 0.5, 0.5), BLACK, Enum.Material.Metal, Enum.PartType.Cylinder)
        scope.CFrame = handle.CFrame * CFrame.new(-0.3, 0.55, 0) * CFrame.Angles(0, 0, math.rad(90))
        weld(handle, scope)
        scope.Parent = tool

        local bipodL = cosmetic("BipodL", Vector3.new(0.1, 1.4, 0.1), STEEL)
        bipodL.CFrame = handle.CFrame * CFrame.new(2.5, -0.7, 0.25) * CFrame.Angles(0, 0, math.rad(15))
        weld(handle, bipodL)
        bipodL.Parent = tool

        local bipodR = cosmetic("BipodR", Vector3.new(0.1, 1.4, 0.1), STEEL)
        bipodR.CFrame = handle.CFrame * CFrame.new(2.5, -0.7, -0.25) * CFrame.Angles(0, 0, math.rad(-15))
        weld(handle, bipodR)
        bipodR.Parent = tool

        muzzle.Position = Vector3.new(4.8, 0.05, 0)
        tool.Grip = CFrame.new(0, -0.5, 0) * CFrame.Angles(0, math.rad(90), 0)
    end)
end

-- =========================================================================
-- BurstRifle (SMG silhouette)
-- =========================================================================
function WeaponModels.BuildBurstRifle()
    return makeTool(
        "BurstRifle",
        Vector3.new(1.6, 0.45, 0.35),
        STEEL,
        Enum.Material.Metal,
        function(tool, handle, muzzle)
            local barrel =
                cosmetic("Barrel", Vector3.new(1.2, 0.22, 0.22), BLACK, Enum.Material.Metal, Enum.PartType.Cylinder)
            barrel.CFrame = handle.CFrame * CFrame.new(1.4, 0, 0) * CFrame.Angles(0, 0, math.rad(90))
            weld(handle, barrel)
            barrel.Parent = tool

            local mag = cosmetic("Magazine", Vector3.new(0.35, 1, 0.28), BLACK)
            mag.CFrame = handle.CFrame * CFrame.new(0.1, -0.65, 0)
            weld(handle, mag)
            mag.Parent = tool

            local foregrip = cosmetic("Foregrip", Vector3.new(0.25, 0.45, 0.25), BLACK)
            foregrip.CFrame = handle.CFrame * CFrame.new(0.9, -0.35, 0)
            weld(handle, foregrip)
            foregrip.Parent = tool

            muzzle.Position = Vector3.new(2, 0, 0)
            tool.Grip = CFrame.new(0, -0.45, 0) * CFrame.Angles(0, math.rad(90), 0)
        end
    )
end

-- =========================================================================
-- Handgun
-- =========================================================================
function WeaponModels.BuildHandgun()
    return makeTool("Handgun", Vector3.new(0.9, 0.3, 0.25), BLACK, Enum.Material.Metal, function(tool, handle, muzzle)
        local slide = cosmetic("Slide", Vector3.new(0.9, 0.18, 0.25), STEEL)
        slide.CFrame = handle.CFrame * CFrame.new(0, 0.22, 0)
        weld(handle, slide)
        slide.Parent = tool

        local barrel =
            cosmetic("Barrel", Vector3.new(0.4, 0.12, 0.12), BLACK, Enum.Material.Metal, Enum.PartType.Cylinder)
        barrel.CFrame = handle.CFrame * CFrame.new(0.65, 0.05, 0) * CFrame.Angles(0, 0, math.rad(90))
        weld(handle, barrel)
        barrel.Parent = tool

        local grip = cosmetic("Grip", Vector3.new(0.3, 0.7, 0.4), BLACK)
        grip.CFrame = handle.CFrame * CFrame.new(-0.2, -0.4, 0) * CFrame.Angles(0, 0, math.rad(-12))
        weld(handle, grip)
        grip.Parent = tool

        muzzle.Position = Vector3.new(0.9, 0.05, 0)
        tool.Grip = CFrame.new(0, -0.4, 0) * CFrame.Angles(0, math.rad(90), 0)
    end)
end

-- =========================================================================
-- Bow
-- =========================================================================
function WeaponModels.BuildBow()
    return makeTool("Bow", Vector3.new(0.3, 0.4, 0.2), WOOD, Enum.Material.Wood, function(tool, handle, muzzle)
        local upper = cosmetic("UpperArm", Vector3.new(0.25, 1.6, 0.25), WOOD, Enum.Material.Wood)
        upper.CFrame = handle.CFrame * CFrame.new(0, 1, -0.05) * CFrame.Angles(math.rad(15), 0, 0)
        weld(handle, upper)
        upper.Parent = tool

        local lower = cosmetic("LowerArm", Vector3.new(0.25, 1.6, 0.25), WOOD, Enum.Material.Wood)
        lower.CFrame = handle.CFrame * CFrame.new(0, -1, -0.05) * CFrame.Angles(math.rad(-15), 0, 0)
        weld(handle, lower)
        lower.Parent = tool

        local str =
            cosmetic("String", Vector3.new(0.04, 3, 0.04), BrickColor.new("Institutional white"), Enum.Material.Plastic)
        str.CFrame = handle.CFrame * CFrame.new(0, 0, 0.15)
        weld(handle, str)
        str.Parent = tool

        local arrow = cosmetic("Arrow", Vector3.new(0.08, 0.08, 2.2), TAN, Enum.Material.Wood)
        arrow.CFrame = handle.CFrame * CFrame.new(0.3, 0, 0) * CFrame.Angles(math.rad(90), 0, 0)
        weld(handle, arrow)
        arrow.Parent = tool

        local tip = cosmetic("Tip", Vector3.new(0.12, 0.12, 0.25), BRASS, Enum.Material.Metal)
        tip.CFrame = arrow.CFrame * CFrame.new(0, -1.15, 0)
        weld(handle, tip)
        tip.Parent = tool

        muzzle.Position = Vector3.new(1.5, 0, 0)
        tool.Grip = CFrame.new(0, 0, 0) * CFrame.Angles(0, math.rad(90), math.rad(90))
    end)
end

-- Dispatch table.
local BUILDERS = {
    AssaultRifle = WeaponModels.BuildAssaultRifle,
    Shotgun = WeaponModels.BuildShotgun,
    Sniper = WeaponModels.BuildSniper,
    BurstRifle = WeaponModels.BuildBurstRifle,
    Handgun = WeaponModels.BuildHandgun,
    Bow = WeaponModels.BuildBow,
}

-- Returns a Tool or nil (nil for weapons with no model, e.g. Fists).
function WeaponModels.Build(weaponName)
    local fn = BUILDERS[weaponName]
    if fn then
        return fn()
    end
    return nil
end

return WeaponModels
