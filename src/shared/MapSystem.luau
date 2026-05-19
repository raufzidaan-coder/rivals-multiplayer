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
    local Arena = {}
    Arena.Name = "Arena"
    Arena.Spawns = {
        Team1 = {
            CFrame.new(-40, 5, 0),
            CFrame.new(-45, 5, 15),
            CFrame.new(-45, 5, -15),
        },
        Team2 = {
            CFrame.new(40, 5, 0),
            CFrame.new(45, 5, 15),
            CFrame.new(45, 5, -15),
        },
    }

    local Folder = Instance.new("Folder")
    Folder.Name = "Arena"
    Folder.Parent = workspace

    local Floor = Instance.new("Part")
    Floor.Name = "Floor"
    Floor.Size = Vector3.new(100, 1, 60)
    Floor.Position = Vector3.new(0, -0.5, 0)
    Floor.Anchored = true
    Floor.BrickColor = BrickColor.new("Dark stone gray")
    Floor.Parent = Folder

    local Walls = {
        { Size = Vector3.new(100, 20, 1), Position = Vector3.new(0, 10, 30) },
        { Size = Vector3.new(100, 20, 1), Position = Vector3.new(0, 10, -30) },
        { Size = Vector3.new(1, 20, 60), Position = Vector3.new(-50, 10, 0) },
        { Size = Vector3.new(1, 20, 60), Position = Vector3.new(50, 10, 0) },
    }

    for _, Wall in ipairs(Walls) do
        local Part = Instance.new("Part")
        Part.Size = Wall.Size
        Part.Position = Wall.Position
        Part.Anchored = true
        Part.BrickColor = BrickColor.new("Dark stone gray")
        Part.CanCollide = true
        Part.Parent = Folder
    end

    local CoverPositions = {
        Vector3.new(-20, 3, 0),
        Vector3.new(20, 3, 0),
        Vector3.new(0, 3, 20),
        Vector3.new(0, 3, -20),
        Vector3.new(-15, 3, 15),
        Vector3.new(15, 3, -15),
        Vector3.new(-15, 3, -15),
        Vector3.new(15, 3, 15),
    }

    for _, Pos in ipairs(CoverPositions) do
        local Cover = Instance.new("Part")
        Cover.Size = Vector3.new(8, 6, 8)
        Cover.Position = Pos
        Cover.Anchored = true
        Cover.BrickColor = BrickColor.new("Medium stone gray")
        Cover.CanCollide = true
        Cover.Parent = Folder
    end

    local Platforms = {
        { Size = Vector3.new(20, 1, 20), Position = Vector3.new(0, 12, 0) },
        { Size = Vector3.new(10, 1, 10), Position = Vector3.new(-25, 8, 0) },
        { Size = Vector3.new(10, 1, 10), Position = Vector3.new(25, 8, 0) },
    }

    for _, Plat in ipairs(Platforms) do
        local Platform = Instance.new("Part")
        Platform.Size = Plat.Size
        Platform.Position = Plat.Position
        Platform.Anchored = true
        Platform.BrickColor = BrickColor.new("Dark stone gray")
        Platform.CanCollide = true
        Platform.Transparency = 0.3
        Platform.Parent = Folder
    end

    local Ramp = Instance.new("Part")
    Ramp.Name = "WallRunRamp"
    Ramp.Size = Vector3.new(15, 1, 30)
    Ramp.Position = Vector3.new(35, 3, 0)
    Ramp.Anchored = true
    Ramp.BrickColor = BrickColor.new("Dark stone gray")
    Ramp.CanCollide = true
    Ramp.Parent = Folder

    local LobbySpawn = Instance.new("Part")
    LobbySpawn.Name = "LobbySpawn"
    LobbySpawn.Size = Vector3.new(4, 1, 4)
    LobbySpawn.Position = Vector3.new(0, 5, -50)
    LobbySpawn.Anchored = true
    LobbySpawn.Transparency = 1
    LobbySpawn.Parent = Folder

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
