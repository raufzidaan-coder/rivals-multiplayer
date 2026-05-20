--[[
    RIVALS CLONE - MAP SYSTEM
    Run this in a LocalScript to generate maps in Studio
]]

local MapSystem = {}
MapSystem.__index = MapSystem

function MapSystem.new()
    local self = setmetatable({}, MapSystem)
    self.Maps = {}
    return self
end

function MapSystem:CreateArena()
    -- Arena 2.0 — de_dust2-inspired three-lane layout per research T1-M7.
    -- Lane dividers split the map into A-lane / Mid / B-lane.
    -- Asymmetric per-lane cover. Lowered center platform with two ramps.
    -- Flanking catwalks. L-shaped spawn screens block direct cross-map AWPs.

    local Arena = {}
    Arena.Name = "Arena"
    Arena.Spawns = {
        Team1 = {
            CFrame.new(-42, 5, 0),
            CFrame.new(-42, 5, 18),
            CFrame.new(-42, 5, -18),
        },
        Team2 = {
            CFrame.new(42, 5, 0),
            CFrame.new(42, 5, 18),
            CFrame.new(42, 5, -18),
        },
    }

    local Folder = Instance.new("Folder")
    Folder.Name = "Arena"
    Folder.Parent = workspace

    local function part(name, size, pos, color, material, parent, transparency)
        local p = Instance.new("Part")
        p.Name = name
        p.Size = size
        p.Position = pos
        p.Anchored = true
        p.CanCollide = true
        p.BrickColor = BrickColor.new(color or "Medium stone grey")
        p.Material = material or Enum.Material.Concrete
        p.TopSurface = Enum.SurfaceType.Smooth
        p.BottomSurface = Enum.SurfaceType.Smooth
        if transparency then
            p.Transparency = transparency
        end
        p.Parent = parent or Folder
        return p
    end

    -- Floor (slate for texture/motion reference per T2-M6)
    part("Floor", Vector3.new(100, 1, 60), Vector3.new(0, -0.5, 0), "Dark stone grey", Enum.Material.Slate)

    -- Outer walls
    part("WallNorth", Vector3.new(100, 20, 1), Vector3.new(0, 10, 30), "Dark stone grey", Enum.Material.Concrete)
    part("WallSouth", Vector3.new(100, 20, 1), Vector3.new(0, 10, -30), "Dark stone grey", Enum.Material.Concrete)
    part("WallEast", Vector3.new(1, 20, 60), Vector3.new(50, 10, 0), "Dark stone grey", Enum.Material.Concrete)
    part("WallWest", Vector3.new(1, 20, 60), Vector3.new(-50, 10, 0), "Dark stone grey", Enum.Material.Concrete)

    -- Lane dividers: split into A (z>10), Mid (-10..10), B (z<-10) with 8-stud gaps at x=±10
    part("LaneA_Left", Vector3.new(20, 12, 2), Vector3.new(-25, 6, 10), "Medium stone grey", Enum.Material.Concrete)
    part("LaneA_Right", Vector3.new(20, 12, 2), Vector3.new(25, 6, 10), "Medium stone grey", Enum.Material.Concrete)
    part("LaneB_Left", Vector3.new(20, 12, 2), Vector3.new(-25, 6, -10), "Medium stone grey", Enum.Material.Concrete)
    part("LaneB_Right", Vector3.new(20, 12, 2), Vector3.new(25, 6, -10), "Medium stone grey", Enum.Material.Concrete)

    -- A-lane: low crouch cover (peek-able)
    part("ALane_Cover_L", Vector3.new(10, 4, 3), Vector3.new(-15, 2, 22), "Brick yellow", Enum.Material.Concrete)
    part("ALane_Cover_R", Vector3.new(10, 4, 3), Vector3.new(15, 2, 22), "Brick yellow", Enum.Material.Concrete)

    -- B-lane: tall crates (full-body cover, no peek over)
    part("BLane_Crate_L", Vector3.new(6, 8, 6), Vector3.new(-15, 4, -22), "Reddish brown", Enum.Material.Wood)
    part("BLane_Crate_R", Vector3.new(6, 8, 6), Vector3.new(15, 4, -22), "Reddish brown", Enum.Material.Wood)

    -- Mid: central pillar sightline breaker (no elevation grant)
    part("Mid_Pillar", Vector3.new(4, 14, 4), Vector3.new(0, 7, 0), "Dark stone grey", Enum.Material.Metal)

    -- Center platform (lowered to y=8, smaller 14x14)
    part(
        "CenterPlatform",
        Vector3.new(14, 1, 14),
        Vector3.new(0, 8, 0),
        "Dark stone grey",
        Enum.Material.Metal,
        nil,
        0.2
    )

    -- Two ramps up to the platform (one from each team's side, contestable)
    part("Ramp_North", Vector3.new(4, 1, 12), Vector3.new(0, 4, 7), "Dark stone grey", Enum.Material.Metal)
    part("Ramp_South", Vector3.new(4, 1, 12), Vector3.new(0, 4, -7), "Dark stone grey", Enum.Material.Metal)

    -- Flanking catwalks (diagonal flanks force checking two angles)
    part("Catwalk_NE", Vector3.new(20, 1, 4), Vector3.new(-30, 6, 25), "Dark stone grey", Enum.Material.Metal)
    part("Catwalk_SW", Vector3.new(20, 1, 4), Vector3.new(30, 6, -25), "Dark stone grey", Enum.Material.Metal)

    -- L-shaped spawn screens (block direct cross-map AWP sightlines)
    part("SpawnScreen_W1", Vector3.new(12, 8, 1), Vector3.new(-42, 4, 4), "Medium stone grey", Enum.Material.Concrete)
    part("SpawnScreen_W2", Vector3.new(1, 8, 8), Vector3.new(-37, 4, 0), "Medium stone grey", Enum.Material.Concrete)
    part("SpawnScreen_E1", Vector3.new(12, 8, 1), Vector3.new(42, 4, -4), "Medium stone grey", Enum.Material.Concrete)
    part("SpawnScreen_E2", Vector3.new(1, 8, 8), Vector3.new(37, 4, 0), "Medium stone grey", Enum.Material.Concrete)

    -- Lobby spawn (preserved from original layout for compatibility)
    local LobbySpawn =
        part("LobbySpawn", Vector3.new(4, 1, 4), Vector3.new(0, 5, -50), "Lime green", Enum.Material.Neon)
    LobbySpawn.Transparency = 1
    LobbySpawn.CanCollide = false

    self.Maps.Arena = Arena
    return Arena
end

function MapSystem:CreateWarehouse()
    local Folder = Instance.new("Folder")
    Folder.Name = "Warehouse"
    Folder.Parent = workspace

    local Floor = Instance.new("Part")
    Floor.Size = Vector3.new(120, 1, 80)
    Floor.Position = Vector3.new(0, -0.5, 0)
    Floor.Anchored = true
    Floor.BrickColor = BrickColor.new("Dark stone gray")
    Floor.Parent = Folder

    local Pillars = {
        Vector3.new(-30, 10, -20),
        Vector3.new(-30, 10, 20),
        Vector3.new(30, 10, -20),
        Vector3.new(30, 10, 20),
        Vector3.new(0, 10, 0),
    }

    for _, Pos in ipairs(Pillars) do
        local Pillar = Instance.new("Part")
        Pillar.Size = Vector3.new(4, 20, 4)
        Pillar.Position = Pos
        Pillar.Anchored = true
        Pillar.BrickColor = BrickColor.new("Medium stone gray")
        Pillar.CanCollide = true
        Pillar.Parent = Folder
    end

    local HighPlatforms = {
        Vector3.new(-40, 15, 0),
        Vector3.new(40, 15, 0),
        Vector3.new(0, 18, -30),
    }

    for _, Pos in ipairs(HighPlatforms) do
        local Plat = Instance.new("Part")
        Plat.Size = Vector3.new(15, 1, 15)
        Plat.Position = Pos
        Plat.Anchored = true
        Plat.BrickColor = BrickColor.new("Dark stone gray")
        Plat.CanCollide = true
        Plat.Transparency = 0.3
        Plat.Parent = Folder
    end

    return { Name = "Warehouse", Folder = Folder }
end

function MapSystem:CreateDowntown()
    local Folder = Instance.new("Folder")
    Folder.Name = "Downtown"
    Folder.Parent = workspace

    local Floor = Instance.new("Part")
    Floor.Size = Vector3.new(100, 1, 100)
    Floor.Position = Vector3.new(0, -0.5, 0)
    Floor.Anchored = true
    Floor.BrickColor = BrickColor.new("Dark stone gray")
    Floor.Parent = Folder

    local Buildings = {
        { Size = Vector3.new(20, 30, 20), Pos = Vector3.new(-25, 15, -25) },
        { Size = Vector3.new(15, 25, 15), Pos = Vector3.new(25, 12.5, -25) },
        { Size = Vector3.new(20, 20, 20), Pos = Vector3.new(-25, 10, 25) },
        { Size = Vector3.new(25, 35, 25), Pos = Vector3.new(25, 17.5, 25) },
    }

    for _, Building in ipairs(Buildings) do
        local Part = Instance.new("Part")
        Part.Size = Building.Size
        Part.Position = Building.Pos
        Part.Anchored = true
        Part.BrickColor = BrickColor.new("Medium stone gray")
        Part.CanCollide = true
        Part.Parent = Folder
    end

    local Ledges = {
        Vector3.new(-25, 18, -15),
        Vector3.new(25, 15, -15),
        Vector3.new(-25, 13, 15),
        Vector3.new(25, 22, 15),
    }

    for _, Pos in ipairs(Ledges) do
        local Ledge = Instance.new("Part")
        Ledge.Size = Vector3.new(8, 1, 8)
        Ledge.Position = Pos
        Ledge.Anchored = true
        Ledge.BrickColor = BrickColor.new("Dark stone gray")
        Ledge.CanCollide = true
        Ledge.Parent = Folder
    end

    -- Street lamps: warm sodium SpotLights on each building corner, pointing down.
    -- Sodium-vapor temperature ~2200K maps roughly to (255, 180, 95).
    local LampAnchors = {
        Vector3.new(-25, 24, -25),
        Vector3.new(25, 22, -25),
        Vector3.new(-25, 18, 25),
        Vector3.new(25, 27, 25),
    }
    for i, Pos in ipairs(LampAnchors) do
        local Lamp = Instance.new("Part")
        Lamp.Name = string.format("StreetLamp_%d", i)
        Lamp.Size = Vector3.new(1.5, 0.5, 1.5)
        Lamp.Position = Pos
        Lamp.Anchored = true
        Lamp.CanCollide = false
        Lamp.Material = Enum.Material.Neon
        Lamp.Color = Color3.fromRGB(255, 200, 120)
        Lamp.Parent = Folder

        local Spot = Instance.new("SpotLight")
        Spot.Brightness = 4
        Spot.Range = 28
        Spot.Angle = 110
        Spot.Color = Color3.fromRGB(255, 180, 95)
        Spot.Face = Enum.NormalId.Bottom
        Spot.Shadows = true
        Spot.Parent = Lamp
    end

    -- Neon signs: cyan / magenta / red / violet PointLights as accent fill on building faces.
    local NeonAccents = {
        { Pos = Vector3.new(-15, 12, -25), Color = Color3.fromRGB(60, 230, 255) },
        { Pos = Vector3.new(15, 18, -25), Color = Color3.fromRGB(255, 60, 200) },
        { Pos = Vector3.new(-15, 8, 25), Color = Color3.fromRGB(255, 80, 80) },
        { Pos = Vector3.new(15, 22, 25), Color = Color3.fromRGB(120, 80, 255) },
    }
    for i, Sign in ipairs(NeonAccents) do
        local Strip = Instance.new("Part")
        Strip.Name = string.format("NeonSign_%d", i)
        Strip.Size = Vector3.new(6, 1, 0.5)
        Strip.Position = Sign.Pos
        Strip.Anchored = true
        Strip.CanCollide = false
        Strip.Material = Enum.Material.Neon
        Strip.Color = Sign.Color
        Strip.Parent = Folder

        local Glow = Instance.new("PointLight")
        Glow.Brightness = 2
        Glow.Range = 20
        Glow.Color = Sign.Color
        Glow.Shadows = false -- accent fill, no shadow cost
        Glow.Parent = Strip
    end

    self:ApplyDowntownLighting()

    return { Name = "Downtown", Folder = Folder }
end

-- Urban dusk preset: low sun, cool blue-violet ambient, dense haze for city smog,
-- warm-tinted color grade so sodium lamps + neon accents read against the cool base.
-- Call standalone if you want the look without rebuilding geometry.
function MapSystem:ApplyDowntownLighting()
    local Lighting = game:GetService("Lighting")

    Lighting.Technology = Enum.Technology.ShadowMap
    Lighting.ClockTime = 19.25 -- ~7:15 PM, sun just below skyline
    Lighting.GeographicLatitude = 41 -- NYC-ish sun azimuth
    Lighting.Brightness = 1.4 -- dimmer than midday Arena (2.0)
    Lighting.Ambient = Color3.fromRGB(35, 38, 55) -- deep blue-violet shadows
    Lighting.OutdoorAmbient = Color3.fromRGB(60, 70, 95) -- cool dusk sky bounce
    Lighting.GlobalShadows = true
    Lighting.ShadowSoftness = 0.35 -- softer urban overcast feel
    Lighting.EnvironmentDiffuseScale = 0.6 -- lift dark corners so geometry reads
    Lighting.EnvironmentSpecularScale = 0.4 -- wet-asphalt highlights
    Lighting.FogStart = 80
    Lighting.FogEnd = 600 -- tighter than Arena's 1200 — city haze
    Lighting.FogColor = Color3.fromRGB(80, 90, 115) -- cool smog matches ambient

    local function ensure(className, props)
        local existing = Lighting:FindFirstChildOfClass(className)
        if not existing then
            existing = Instance.new(className)
            existing.Parent = Lighting
        end
        for k, v in pairs(props) do
            existing[k] = v
        end
        return existing
    end

    -- Atmosphere: heavier density + warm-leaning haze sells the dusk smog;
    -- low glare keeps the very-low sun from blowing out skyline silhouettes.
    ensure("Atmosphere", {
        Density = 0.42,
        Offset = 0.25,
        Color = Color3.fromRGB(180, 170, 165),
        Decay = Color3.fromRGB(95, 80, 110),
        Glare = 0.15,
        Haze = 2.4,
    })

    -- Bloom: stronger + lower threshold so neon strips and lamp filaments bleed visibly.
    ensure("BloomEffect", {
        Intensity = 0.55,
        Size = 18,
        Threshold = 0.9,
    })

    -- ColorCorrection: cool shadows, warm midtone tint, mild contrast bump.
    -- TintColor pulls toward amber so sodium lamps feel anchored, not isolated.
    ensure("ColorCorrectionEffect", {
        Saturation = 0.22,
        Contrast = 0.18,
        Brightness = -0.04,
        TintColor = Color3.fromRGB(245, 225, 210),
    })

    -- SunRays kept subtle: a hint of god-rays through skyline gaps, not the whole frame.
    ensure("SunRaysEffect", {
        Intensity = 0.08,
        Spread = 0.6,
    })

    -- DepthOfField intentionally omitted — same reason as Arena preset: distance blur kills FPS reads.
end

-- Procedural crate/box prop generator (wood + metal variants, any size).
-- Returns a Model with a banded slat/plate aesthetic so cover reads at a glance.
-- size     : Vector3   (stud dimensions; clamped to >= 1)
-- position : Vector3   (world-space center)
-- material : "wood" | "metal" (case-insensitive; defaults to "wood")
function MapSystem:BuildCrate(size, position, material)
    size = size or Vector3.new(6, 6, 6)
    position = position or Vector3.new(0, size.Y / 2, 0)
    local matKey = string.lower(tostring(material or "wood"))

    -- Material palette: wood = warm reddish-brown slats; metal = cold grey plates with rivet hint
    local Palette = {
        wood = {
            Body = BrickColor.new("Reddish brown"),
            Trim = BrickColor.new("Dirt brown"),
            Material = Enum.Material.WoodPlanks,
            TrimMaterial = Enum.Material.Wood,
            Reflectance = 0,
        },
        metal = {
            Body = BrickColor.new("Dark stone grey"),
            Trim = BrickColor.new("Fossil"),
            Material = Enum.Material.DiamondPlate,
            TrimMaterial = Enum.Material.Metal,
            Reflectance = 0.15,
        },
    }
    local pal = Palette[matKey] or Palette.wood

    -- Clamp pathologically tiny sizes so trim parts don't have non-positive dimensions
    local sx = math.max(size.X, 1)
    local sy = math.max(size.Y, 1)
    local sz = math.max(size.Z, 1)
    size = Vector3.new(sx, sy, sz)

    local Crate = Instance.new("Model")
    Crate.Name = string.format("Crate_%s_%dx%dx%d", matKey, sx, sy, sz)

    local function makePart(name, partSize, partPos, isTrim)
        local p = Instance.new("Part")
        p.Name = name
        p.Size = partSize
        p.Position = partPos
        p.Anchored = true
        p.CanCollide = true
        p.TopSurface = Enum.SurfaceType.Smooth
        p.BottomSurface = Enum.SurfaceType.Smooth
        p.BrickColor = isTrim and pal.Trim or pal.Body
        p.Material = isTrim and pal.TrimMaterial or pal.Material
        p.Reflectance = pal.Reflectance
        p.Parent = Crate
        return p
    end

    -- Main body (slightly inset so trim reads as a frame around it)
    local trimThickness = math.min(0.4, math.min(sx, sy, sz) * 0.1)
    local body =
        makePart("Body", size - Vector3.new(trimThickness, trimThickness, trimThickness) * 0.5, position, false)
    Crate.PrimaryPart = body

    -- Vertical corner trim (4 edges) — gives wood crates plank framing and metal crates rivet posts
    local halfX = sx / 2 - trimThickness / 2
    local halfZ = sz / 2 - trimThickness / 2
    local cornerOffsets = {
        Vector3.new(halfX, 0, halfZ),
        Vector3.new(-halfX, 0, halfZ),
        Vector3.new(halfX, 0, -halfZ),
        Vector3.new(-halfX, 0, -halfZ),
    }
    for i, off in ipairs(cornerOffsets) do
        makePart("Corner_" .. i, Vector3.new(trimThickness, sy, trimThickness), position + off, true)
    end

    -- Top + bottom horizontal bands (the lid / base plates)
    local bandY = math.min(0.5, sy * 0.12)
    makePart("LidBand", Vector3.new(sx, bandY, sz), position + Vector3.new(0, sy / 2 - bandY / 2, 0), true)
    makePart("BaseBand", Vector3.new(sx, bandY, sz), position + Vector3.new(0, -sy / 2 + bandY / 2, 0), true)

    Crate.Parent = workspace
    return Crate
end

-- Convenience: scatter a procedural pile of mixed crates around an anchor point.
-- presets: small (3x3x3), medium (5x5x5), large (7x8x7)
function MapSystem:BuildCratePile(anchorPos, count, materialMix)
    local sizes = {
        Vector3.new(3, 3, 3),
        Vector3.new(5, 5, 5),
        Vector3.new(4, 6, 4),
        Vector3.new(7, 4, 5),
    }
    local mats = materialMix or { "wood", "wood", "metal" }
    local crates = {}
    for i = 1, (count or 4) do
        local s = sizes[((i - 1) % #sizes) + 1]
        local m = mats[((i - 1) % #mats) + 1]
        local jitterX = ((i * 37) % 7) - 3
        local jitterZ = ((i * 53) % 7) - 3
        local pos = anchorPos + Vector3.new(jitterX, s.Y / 2, jitterZ)
        table.insert(crates, self:BuildCrate(s, pos, m))
    end
    return crates
end

-- Procedural vertical industrial pipe with bracket clamps + optional valve handle.
-- Reads as wall-mounted utility cover and slight sightline-breaker.
-- height     : number    (stud height; clamped to >= 4)
-- position   : Vector3   (world-space base center; pipe extends upward)
-- diameter   : number    (default 2; clamped to >= 1)
-- withValve  : boolean   (default true; adds a red wheel-valve assembly midway up)
function MapSystem:BuildPipe(height, position, diameter, withValve)
    height = math.max(height or 16, 4)
    diameter = math.max(diameter or 2, 1)
    position = position or Vector3.new(0, 0, 0)
    if withValve == nil then
        withValve = true
    end

    local Pipe = Instance.new("Model")
    Pipe.Name = string.format("Pipe_h%d_d%d", math.floor(height), math.floor(diameter))

    local function makePart(name, size, pos, color, material, shape, reflectance)
        local p = Instance.new("Part")
        p.Name = name
        p.Size = size
        p.Position = pos
        p.Anchored = true
        p.CanCollide = true
        p.TopSurface = Enum.SurfaceType.Smooth
        p.BottomSurface = Enum.SurfaceType.Smooth
        p.BrickColor = BrickColor.new(color)
        p.Material = material or Enum.Material.Metal
        p.Reflectance = reflectance or 0.1
        if shape then
            p.Shape = shape
        end
        p.Parent = Pipe
        return p
    end

    -- Main shaft (cylinder). Roblox cylinder default axis is X — rotate so it extends vertically.
    local shaft = makePart(
        "Shaft",
        Vector3.new(height, diameter, diameter),
        position + Vector3.new(0, height / 2, 0),
        "Fossil",
        Enum.Material.Metal,
        Enum.PartType.Cylinder,
        0.2
    )
    shaft.CFrame = CFrame.new(position + Vector3.new(0, height / 2, 0)) * CFrame.Angles(0, 0, math.rad(90))
    Pipe.PrimaryPart = shaft

    -- End caps (slightly fatter flanges)
    local capSize = Vector3.new(diameter * 0.4, diameter * 1.25, diameter * 1.25)
    local capBottom = makePart(
        "FlangeBottom",
        capSize,
        position + Vector3.new(0, 0.2, 0),
        "Dark stone grey",
        Enum.Material.DiamondPlate,
        Enum.PartType.Cylinder,
        0.15
    )
    capBottom.CFrame = CFrame.new(position + Vector3.new(0, 0.2, 0)) * CFrame.Angles(0, 0, math.rad(90))
    local capTop = makePart(
        "FlangeTop",
        capSize,
        position + Vector3.new(0, height - 0.2, 0),
        "Dark stone grey",
        Enum.Material.DiamondPlate,
        Enum.PartType.Cylinder,
        0.15
    )
    capTop.CFrame = CFrame.new(position + Vector3.new(0, height - 0.2, 0)) * CFrame.Angles(0, 0, math.rad(90))

    -- Wall-mount bracket clamps every ~6 studs
    local clampCount = math.max(2, math.floor(height / 6))
    for i = 1, clampCount do
        local t = (i - 0.5) / clampCount
        local y = position.Y + t * height
        local clamp = makePart(
            "Clamp_" .. i,
            Vector3.new(0.8, diameter * 1.6, diameter * 1.6),
            Vector3.new(position.X, y, position.Z),
            "Really black",
            Enum.Material.Metal,
            Enum.PartType.Cylinder,
            0.05
        )
        clamp.CFrame = CFrame.new(position.X, y, position.Z) * CFrame.Angles(0, 0, math.rad(90))
    end

    -- Optional valve handle (red wheel + stem)
    if withValve then
        local valveY = position.Y + height * 0.55
        local _stem = makePart(
            "ValveStem",
            Vector3.new(diameter * 1.4, 0.5, 0.5),
            Vector3.new(position.X + diameter * 0.9, valveY, position.Z),
            "Really black",
            Enum.Material.Metal,
            nil,
            0.05
        )
        local wheel = makePart(
            "ValveWheel",
            Vector3.new(0.4, diameter * 2.2, diameter * 2.2),
            Vector3.new(position.X + diameter * 1.8, valveY, position.Z),
            "Bright red",
            Enum.Material.Metal,
            Enum.PartType.Cylinder,
            0.1
        )
        wheel.CFrame = CFrame.new(position.X + diameter * 1.8, valveY, position.Z) * CFrame.Angles(0, 0, math.rad(90))
        -- Wheel spokes (4)
        for i = 0, 3 do
            local spoke = makePart(
                "Spoke_" .. i,
                Vector3.new(0.3, diameter * 2, 0.3),
                Vector3.new(position.X + diameter * 1.8, valveY, position.Z),
                "Bright red",
                Enum.Material.Metal,
                nil,
                0.1
            )
            spoke.CFrame = CFrame.new(position.X + diameter * 1.8, valveY, position.Z)
                * CFrame.Angles(math.rad(i * 45), 0, 0)
        end
    end

    Pipe.Parent = workspace
    return Pipe
end

-- Procedural wall decal: graffiti / signage rendered as a thin colored panel
-- with optional contrast trim, faking spray paint or stencil work on walls.
-- Lightweight (no Decal asset IDs — pure parts) so it ships with the place.
-- size      : Vector2   (width X height in studs)
-- cframe    : CFrame    (world placement; +X face points outward)
-- style     : "graffiti" | "warning" | "stencil"   (default "graffiti")
function MapSystem:BuildWallDecal(size, cframe, style)
    size = size or Vector2.new(8, 4)
    cframe = cframe or CFrame.new(0, 6, 0)
    style = string.lower(tostring(style or "graffiti"))

    local Styles = {
        graffiti = {
            Body = BrickColor.new("Magenta"),
            Trim = BrickColor.new("New Yeller"),
            Material = Enum.Material.Neon,
            Transparency = 0.1,
        },
        warning = {
            Body = BrickColor.new("New Yeller"),
            Trim = BrickColor.new("Really black"),
            Material = Enum.Material.SmoothPlastic,
            Transparency = 0,
        },
        stencil = {
            Body = BrickColor.new("White"),
            Trim = BrickColor.new("Really black"),
            Material = Enum.Material.SmoothPlastic,
            Transparency = 0.2,
        },
    }
    local s = Styles[style] or Styles.graffiti

    local Decal = Instance.new("Model")
    Decal.Name = "WallDecal_" .. style

    local w = math.max(size.X, 1)
    local h = math.max(size.Y, 1)
    local thickness = 0.2

    local function makePanel(name, panelSize, offset, color, material, transparency)
        local p = Instance.new("Part")
        p.Name = name
        p.Size = panelSize
        p.CFrame = cframe * CFrame.new(offset)
        p.Anchored = true
        p.CanCollide = false -- decals are visual only, no collision interference
        p.TopSurface = Enum.SurfaceType.Smooth
        p.BottomSurface = Enum.SurfaceType.Smooth
        p.BrickColor = color
        p.Material = material
        p.Transparency = transparency or 0
        p.Parent = Decal
        return p
    end

    -- Backing splash (the "paint")
    local body = makePanel(
        "Body",
        Vector3.new(thickness, h, w),
        Vector3.new(thickness / 2, 0, 0),
        s.Body,
        s.Material,
        s.Transparency
    )
    Decal.PrimaryPart = body

    -- Trim accents (top + bottom stripes) to read as stencil/marker borders
    local stripeH = math.min(0.6, h * 0.15)
    makePanel(
        "TrimTop",
        Vector3.new(thickness + 0.05, stripeH, w),
        Vector3.new(thickness / 2 + 0.025, h / 2 - stripeH / 2, 0),
        s.Trim,
        s.Material,
        s.Transparency
    )
    makePanel(
        "TrimBottom",
        Vector3.new(thickness + 0.05, stripeH, w),
        Vector3.new(thickness / 2 + 0.025, -h / 2 + stripeH / 2, 0),
        s.Trim,
        s.Material,
        s.Transparency
    )

    -- Style-specific accent: graffiti gets a diagonal slash; warning gets vertical hazard bar
    if style == "graffiti" then
        local slash = makePanel(
            "Slash",
            Vector3.new(thickness + 0.1, h * 0.9, w * 0.15),
            Vector3.new(thickness / 2 + 0.05, 0, 0),
            s.Trim,
            Enum.Material.Neon,
            0
        )
        slash.CFrame = cframe * CFrame.new(thickness / 2 + 0.05, 0, 0) * CFrame.Angles(math.rad(20), 0, 0)
    elseif style == "warning" then
        local bars = 3
        for i = 1, bars do
            local barX = (i - (bars + 1) / 2) * (w / (bars + 1))
            makePanel(
                "Bar_" .. i,
                Vector3.new(thickness + 0.05, h * 0.7, w * 0.08),
                Vector3.new(thickness / 2 + 0.025, 0, barX),
                s.Trim,
                s.Material,
                0
            )
        end
    end

    Decal.Parent = workspace
    return Decal
end

-- Convenience: line of pipes along a wall (e.g., warehouse back wall).
-- wallCFrame : CFrame at one end of the wall, +X normal facing outward
-- count      : number of pipes
-- spacing    : studs between pipes (default 8)
function MapSystem:BuildPipeRun(wallCFrame, count, spacing, height)
    spacing = spacing or 8
    count = count or 4
    local pipes = {}
    for i = 0, count - 1 do
        local offset = wallCFrame * CFrame.new(0, 0, i * spacing)
        -- Alternate valve presence so it doesn't read as repetitive
        local withValve = (i % 2) == 0
        local p = self:BuildPipe(height or 16, offset.Position, 2, withValve)
        table.insert(pipes, p)
    end
    return pipes
end

function MapSystem:DeleteMap(MapName)
    if workspace:FindFirstChild(MapName) then
        workspace[MapName]:Destroy()
    end
end

function MapSystem:LoadMap(MapName)
    local Map = self.Maps[MapName]
    if not (Map and Map.Folder) then
        warn(string.format("[MapSystem] Cannot load '%s' — not registered. Current map preserved.", MapName))
        return false
    end

    self:DeleteMap("CurrentMap")
    Map.Folder.Name = "CurrentMap"
    return true
end

return MapSystem
