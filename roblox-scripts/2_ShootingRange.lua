--[[
    RIVALS - Shooting Range
    Type: Script (Server Script)
    Location: ServerScriptService

    Builds a shooting range area where players can test all weapons.
    Includes target dummies, distance markers, and a weapon selection board.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- ============== CONFIG ==============
local RANGE_ORIGIN = Vector3.new(500, 5, 0) -- Away from main map
local LANE_WIDTH = 12
local LANE_LENGTH = 150
local NUM_LANES = 4
local TARGET_DISTANCES = {15, 30, 50, 75, 100, 130}

-- ============== BUILD THE RANGE ==============
local rangeFolder = Instance.new("Folder")
rangeFolder.Name = "ShootingRange"
rangeFolder.Parent = workspace

-- Floor
local floor = Instance.new("Part")
floor.Name = "RangeFloor"
floor.Size = Vector3.new(NUM_LANES * LANE_WIDTH + 20, 1, LANE_LENGTH + 40)
floor.Position = RANGE_ORIGIN + Vector3.new(0, -0.5, LANE_LENGTH / 2 - 10)
floor.Anchored = true
floor.Color = Color3.fromRGB(40, 40, 50)
floor.Material = Enum.Material.Concrete
floor.Parent = rangeFolder

-- Ceiling with lights
local ceiling = Instance.new("Part")
ceiling.Name = "Ceiling"
ceiling.Size = Vector3.new(floor.Size.X, 1, floor.Size.Z)
ceiling.Position = RANGE_ORIGIN + Vector3.new(0, 20, LANE_LENGTH / 2 - 10)
ceiling.Anchored = true
ceiling.Color = Color3.fromRGB(30, 30, 35)
ceiling.Material = Enum.Material.Metal
ceiling.Transparency = 0.1
ceiling.Parent = rangeFolder

-- Walls
for _, side in ipairs({-1, 1}) do
    local wall = Instance.new("Part")
    wall.Name = "Wall_" .. (side == -1 and "Left" or "Right")
    wall.Size = Vector3.new(1, 21, floor.Size.Z)
    wall.Position = RANGE_ORIGIN + Vector3.new(side * (floor.Size.X / 2), 10, LANE_LENGTH / 2 - 10)
    wall.Anchored = true
    wall.Color = Color3.fromRGB(25, 25, 35)
    wall.Material = Enum.Material.Concrete
    wall.Parent = rangeFolder
end

-- Back wall (behind targets)
local backWall = Instance.new("Part")
backWall.Name = "BackWall"
backWall.Size = Vector3.new(floor.Size.X, 21, 2)
backWall.Position = RANGE_ORIGIN + Vector3.new(0, 10, LANE_LENGTH + 10)
backWall.Anchored = true
backWall.Color = Color3.fromRGB(20, 20, 25)
backWall.Material = Enum.Material.Concrete
backWall.Parent = rangeFolder

-- ============== BUILD LANES ==============
for lane = 1, NUM_LANES do
    local laneX = RANGE_ORIGIN.X + (lane - (NUM_LANES + 1) / 2) * LANE_WIDTH

    -- Lane dividers
    if lane < NUM_LANES then
        local divider = Instance.new("Part")
        divider.Name = "Divider_" .. lane
        divider.Size = Vector3.new(0.3, 8, LANE_LENGTH)
        divider.Position = Vector3.new(laneX + LANE_WIDTH / 2, RANGE_ORIGIN.Y + 4, RANGE_ORIGIN.Z + LANE_LENGTH / 2)
        divider.Anchored = true
        divider.Color = Color3.fromRGB(50, 50, 60)
        divider.Material = Enum.Material.Metal
        divider.Transparency = 0.5
        divider.Parent = rangeFolder
    end

    -- Lane number sign
    local laneSign = Instance.new("Part")
    laneSign.Name = "LaneSign_" .. lane
    laneSign.Size = Vector3.new(4, 2, 0.2)
    laneSign.Position = Vector3.new(laneX, RANGE_ORIGIN.Y + 8, RANGE_ORIGIN.Z - 5)
    laneSign.Anchored = true
    laneSign.Color = Color3.fromRGB(99, 102, 241)
    laneSign.Material = Enum.Material.Neon
    laneSign.Parent = rangeFolder

    local signGui = Instance.new("SurfaceGui")
    signGui.Face = Enum.NormalId.Front
    signGui.Parent = laneSign

    local signLabel = Instance.new("TextLabel")
    signLabel.Size = UDim2.new(1, 0, 1, 0)
    signLabel.BackgroundTransparency = 1
    signLabel.Text = "LANE " .. lane
    signLabel.TextColor3 = Color3.new(1, 1, 1)
    signLabel.TextScaled = true
    signLabel.Font = Enum.Font.GothamBold
    signLabel.Parent = signGui

    -- Shooting platform
    local platform = Instance.new("Part")
    platform.Name = "Platform_" .. lane
    platform.Size = Vector3.new(LANE_WIDTH - 2, 0.5, 6)
    platform.Position = Vector3.new(laneX, RANGE_ORIGIN.Y + 0.25, RANGE_ORIGIN.Z)
    platform.Anchored = true
    platform.Color = Color3.fromRGB(60, 60, 80)
    platform.Material = Enum.Material.SmoothPlastic
    platform.Parent = rangeFolder

    -- ============== TARGETS ==============
    for _, dist in ipairs(TARGET_DISTANCES) do
        -- Target dummy (humanoid-shaped)
        local targetModel = Instance.new("Model")
        targetModel.Name = "Target_" .. dist .. "m_Lane" .. lane
        targetModel.Parent = rangeFolder

        -- Torso
        local torso = Instance.new("Part")
        torso.Name = "Torso"
        torso.Size = Vector3.new(2, 2.5, 1)
        torso.Position = Vector3.new(laneX, RANGE_ORIGIN.Y + 3.25, RANGE_ORIGIN.Z + dist)
        torso.Anchored = true
        torso.Color = Color3.fromRGB(200, 60, 60)
        torso.Material = Enum.Material.SmoothPlastic
        torso.Parent = targetModel

        -- Head
        local head = Instance.new("Part")
        head.Name = "Head"
        head.Shape = Enum.PartType.Ball
        head.Size = Vector3.new(1.5, 1.5, 1.5)
        head.Position = torso.Position + Vector3.new(0, 2, 0)
        head.Anchored = true
        head.Color = Color3.fromRGB(255, 80, 80)
        head.Material = Enum.Material.SmoothPlastic
        head.Parent = targetModel

        -- Arms
        for _, armSide in ipairs({-1, 1}) do
            local arm = Instance.new("Part")
            arm.Name = armSide == -1 and "LeftArm" or "RightArm"
            arm.Size = Vector3.new(0.8, 2.5, 0.8)
            arm.Position = torso.Position + Vector3.new(armSide * 1.4, 0, 0)
            arm.Anchored = true
            arm.Color = Color3.fromRGB(180, 50, 50)
            arm.Material = Enum.Material.SmoothPlastic
            arm.Parent = targetModel
        end

        -- Legs
        for _, legSide in ipairs({-1, 1}) do
            local leg = Instance.new("Part")
            leg.Name = legSide == -1 and "LeftLeg" or "RightLeg"
            leg.Size = Vector3.new(0.9, 2.5, 0.9)
            leg.Position = torso.Position + Vector3.new(legSide * 0.55, -2.5, 0)
            leg.Anchored = true
            leg.Color = Color3.fromRGB(160, 40, 40)
            leg.Material = Enum.Material.SmoothPlastic
            leg.Parent = targetModel
        end

        -- Stand/pole
        local stand = Instance.new("Part")
        stand.Name = "Stand"
        stand.Size = Vector3.new(0.3, 2, 0.3)
        stand.Position = Vector3.new(laneX, RANGE_ORIGIN.Y + 1, RANGE_ORIGIN.Z + dist)
        stand.Anchored = true
        stand.Color = Color3.fromRGB(80, 80, 80)
        stand.Material = Enum.Material.Metal
        stand.Parent = targetModel

        -- Distance marker
        local marker = Instance.new("Part")
        marker.Name = "DistanceMarker"
        marker.Size = Vector3.new(3, 1.5, 0.1)
        marker.Position = Vector3.new(laneX, RANGE_ORIGIN.Y + 7, RANGE_ORIGIN.Z + dist)
        marker.Anchored = true
        marker.Transparency = 0.3
        marker.Color = Color3.fromRGB(50, 50, 70)
        marker.Parent = rangeFolder

        local markerGui = Instance.new("SurfaceGui")
        markerGui.Face = Enum.NormalId.Back
        markerGui.Parent = marker

        local markerLabel = Instance.new("TextLabel")
        markerLabel.Size = UDim2.new(1, 0, 1, 0)
        markerLabel.BackgroundTransparency = 1
        markerLabel.Text = dist .. "m"
        markerLabel.TextColor3 = Color3.fromRGB(200, 200, 255)
        markerLabel.TextScaled = true
        markerLabel.Font = Enum.Font.GothamBold
        markerLabel.Parent = markerGui

        -- Humanoid for damage detection
        local humanoid = Instance.new("Humanoid")
        humanoid.MaxHealth = 100
        humanoid.Health = 100
        humanoid.Parent = targetModel
        targetModel.PrimaryPart = torso

        -- Auto-respawn target when killed
        humanoid.Died:Connect(function()
            task.wait(2)
            humanoid.Health = humanoid.MaxHealth
            -- Flash green on reset
            for _, part in ipairs(targetModel:GetChildren()) do
                if part:IsA("BasePart") and part.Name ~= "Stand" then
                    local origColor = part.Color
                    part.Color = Color3.fromRGB(0, 255, 0)
                    task.wait(0.3)
                    part.Color = origColor
                end
            end
        end)
    end
end

-- ============== ENTRANCE SIGN ==============
local entranceSign = Instance.new("Part")
entranceSign.Name = "EntranceSign"
entranceSign.Size = Vector3.new(20, 5, 0.5)
entranceSign.Position = RANGE_ORIGIN + Vector3.new(0, 12, -8)
entranceSign.Anchored = true
entranceSign.Color = Color3.fromRGB(99, 102, 241)
entranceSign.Material = Enum.Material.Neon
entranceSign.Parent = rangeFolder

local entranceGui = Instance.new("SurfaceGui")
entranceGui.Face = Enum.NormalId.Front
entranceGui.Parent = entranceSign

local entranceLabel = Instance.new("TextLabel")
entranceLabel.Size = UDim2.new(1, 0, 1, 0)
entranceLabel.BackgroundTransparency = 1
entranceLabel.Text = "SHOOTING RANGE"
entranceLabel.TextColor3 = Color3.new(1, 1, 1)
entranceLabel.TextScaled = true
entranceLabel.Font = Enum.Font.GothamBold
entranceLabel.Parent = entranceGui

-- ============== LIGHTS ==============
for i = 1, 6 do
    local light = Instance.new("Part")
    light.Name = "Light_" .. i
    light.Size = Vector3.new(2, 0.5, 2)
    light.Position = RANGE_ORIGIN + Vector3.new(
        (i - 3.5) * 12,
        19,
        LANE_LENGTH / 2
    )
    light.Anchored = true
    light.Color = Color3.fromRGB(255, 255, 240)
    light.Material = Enum.Material.Neon
    light.Parent = rangeFolder

    local pointLight = Instance.new("PointLight")
    pointLight.Brightness = 2
    pointLight.Range = 30
    pointLight.Color = Color3.fromRGB(255, 255, 240)
    pointLight.Parent = light
end

-- ============== TELEPORT PAD (to get to range) ==============
local teleportPad = Instance.new("Part")
teleportPad.Name = "ShootingRangeTeleport"
teleportPad.Size = Vector3.new(6, 0.5, 6)
teleportPad.Position = Vector3.new(0, 1, 0) -- Place near spawn
teleportPad.Anchored = true
teleportPad.Color = Color3.fromRGB(99, 102, 241)
teleportPad.Material = Enum.Material.Neon
teleportPad.Parent = workspace

local padGui = Instance.new("SurfaceGui")
padGui.Face = Enum.NormalId.Top
padGui.Parent = teleportPad

local padLabel = Instance.new("TextLabel")
padLabel.Size = UDim2.new(1, 0, 1, 0)
padLabel.BackgroundTransparency = 1
padLabel.Text = "SHOOTING\nRANGE"
padLabel.TextColor3 = Color3.new(1, 1, 1)
padLabel.TextScaled = true
padLabel.Font = Enum.Font.GothamBold
padLabel.Parent = padGui

-- Billboard above pad
local billboard = Instance.new("BillboardGui")
billboard.Size = UDim2.new(8, 0, 3, 0)
billboard.StudsOffset = Vector3.new(0, 5, 0)
billboard.AlwaysOnTop = true
billboard.Parent = teleportPad

local bbLabel = Instance.new("TextLabel")
bbLabel.Size = UDim2.new(1, 0, 1, 0)
bbLabel.BackgroundTransparency = 1
bbLabel.Text = "Step here to enter\nSHOOTING RANGE"
bbLabel.TextColor3 = Color3.fromRGB(99, 102, 241)
bbLabel.TextScaled = true
bbLabel.Font = Enum.Font.GothamBold
bbLabel.Parent = billboard

local bbStroke = Instance.new("UIStroke")
bbStroke.Color = Color3.new(0, 0, 0)
bbStroke.Thickness = 2
bbStroke.Parent = bbLabel

-- Return pad inside range
local returnPad = Instance.new("Part")
returnPad.Name = "ReturnTeleport"
returnPad.Size = Vector3.new(6, 0.5, 6)
returnPad.Position = RANGE_ORIGIN + Vector3.new(0, 0.25, -12)
returnPad.Anchored = true
returnPad.Color = Color3.fromRGB(34, 197, 94)
returnPad.Material = Enum.Material.Neon
returnPad.Parent = rangeFolder

local returnGui = Instance.new("SurfaceGui")
returnGui.Face = Enum.NormalId.Top
returnGui.Parent = returnPad

local returnLabel = Instance.new("TextLabel")
returnLabel.Size = UDim2.new(1, 0, 1, 0)
returnLabel.BackgroundTransparency = 1
returnLabel.Text = "RETURN TO\nLOBBY"
returnLabel.TextColor3 = Color3.new(1, 1, 1)
returnLabel.TextScaled = true
returnLabel.Font = Enum.Font.GothamBold
returnLabel.Parent = returnGui

-- Teleport logic
teleportPad.Touched:Connect(function(hit)
    local character = hit.Parent
    local humanoid = character:FindFirstChild("Humanoid")
    if humanoid and humanoid.Health > 0 then
        local player = Players:GetPlayerFromCharacter(character)
        if player then
            -- Teleport to shooting range
            character:SetPrimaryPartCFrame(CFrame.new(RANGE_ORIGIN + Vector3.new(0, 3, 0)))
        end
    end
end)

returnPad.Touched:Connect(function(hit)
    local character = hit.Parent
    local humanoid = character:FindFirstChild("Humanoid")
    if humanoid and humanoid.Health > 0 then
        local player = Players:GetPlayerFromCharacter(character)
        if player then
            -- Teleport back to spawn
            character:SetPrimaryPartCFrame(CFrame.new(Vector3.new(0, 5, 0)))
        end
    end
end)

print("[RIVALS] Shooting Range built successfully!")
