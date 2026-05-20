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

    return { Name = "Downtown", Folder = Folder }
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
