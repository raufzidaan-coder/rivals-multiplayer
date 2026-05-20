--[[
    TrainingRange — corner of the lobby where players can practice aim.

    Per the research spec (T4 — shooting range):
    - Zone A: 5 static dummies at 10/20/30/40/50 studs
    - Zone B: 3 strafing dummies ping-ponging between two anchors
    - InfiniteAmmo attribute on players in the range (gates WeaponSystem:CanFire/Reload)
    - IsDummy attribute on bot rigs so they respawn on death instead of dropping into K/D

    Triggered when a player touches the "Shooting Range" pad in LobbyPads.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local TrainingRange = {}

-- Where the range lives in the world (away from the lobby spawn).
local RANGE_ORIGIN = Vector3.new(0, 5, -80)
local DUMMY_DISTANCES = { 10, 20, 30, 40, 50 }

local rangeFolder = workspace:FindFirstChild("TrainingRange")

local function buildDummy(name, position)
    local rig = Instance.new("Model")
    rig.Name = name

    local torso = Instance.new("Part")
    torso.Name = "Torso"
    torso.Size = Vector3.new(2, 2, 1)
    torso.Position = position + Vector3.new(0, 1, 0)
    torso.Anchored = true
    torso.BrickColor = BrickColor.new("Bright orange")
    torso.Material = Enum.Material.Metal
    torso.Parent = rig

    local head = Instance.new("Part")
    head.Name = "Head"
    head.Size = Vector3.new(1.2, 1.2, 1.2)
    head.Shape = Enum.PartType.Ball
    head.Position = position + Vector3.new(0, 2.6, 0)
    head.Anchored = true
    head.BrickColor = BrickColor.new("Really red")
    head.Material = Enum.Material.Metal
    head.Parent = rig

    rig:SetAttribute("IsDummy", true)
    rig:SetAttribute("MaxHealth", 100)
    rig:SetAttribute("Health", 100)
    rig.PrimaryPart = torso
    rig.Parent = rangeFolder
    return rig
end

function TrainingRange.Build()
    -- Idempotent — wipe + rebuild if called twice (e.g. after server restart).
    if rangeFolder then
        rangeFolder:Destroy()
    end
    rangeFolder = Instance.new("Folder")
    rangeFolder.Name = "TrainingRange"
    rangeFolder.Parent = workspace

    -- Floor
    local floor = Instance.new("Part")
    floor.Name = "Floor"
    floor.Size = Vector3.new(80, 1, 60)
    floor.Position = RANGE_ORIGIN
    floor.Anchored = true
    floor.BrickColor = BrickColor.new("Dark stone grey")
    floor.Material = Enum.Material.Concrete
    floor.Parent = rangeFolder

    -- Wall markers (back wall to catch errant shots)
    local backWall = Instance.new("Part")
    backWall.Name = "BackWall"
    backWall.Size = Vector3.new(80, 12, 1)
    backWall.Position = RANGE_ORIGIN + Vector3.new(0, 6, -25)
    backWall.Anchored = true
    backWall.BrickColor = BrickColor.new("Medium stone grey")
    backWall.Material = Enum.Material.Concrete
    backWall.Parent = rangeFolder

    -- Zone A: static dummies at varying distances
    for i, dist in ipairs(DUMMY_DISTANCES) do
        buildDummy("StaticDummy" .. i, RANGE_ORIGIN + Vector3.new(-25 + (i - 1) * 6, 0, -10 - dist * 0.3))
    end

    -- Zone B: 3 strafing dummies that ping-pong
    for i = 1, 3 do
        local anchorA = RANGE_ORIGIN + Vector3.new(10 + i * 5, 0, -18)
        local anchorB = anchorA + Vector3.new(0, 0, -8)
        local dummy = buildDummy("StrafeDummy" .. i, anchorA)
        dummy:SetAttribute("AnchorA_X", anchorA.X)
        dummy:SetAttribute("AnchorA_Y", anchorA.Y)
        dummy:SetAttribute("AnchorA_Z", anchorA.Z)
        dummy:SetAttribute("AnchorB_X", anchorB.X)
        dummy:SetAttribute("AnchorB_Y", anchorB.Y)
        dummy:SetAttribute("AnchorB_Z", anchorB.Z)
    end

    -- Spawn pad: where touching a player gets teleported on entry.
    local entry = Instance.new("Part")
    entry.Name = "RangeEntryPad"
    entry.Size = Vector3.new(8, 1, 8)
    entry.Position = RANGE_ORIGIN + Vector3.new(0, 0.5, 25)
    entry.Anchored = true
    entry.CanCollide = false
    entry.BrickColor = BrickColor.new("Lime green")
    entry.Material = Enum.Material.Neon
    entry.Transparency = 0.4
    entry.Parent = rangeFolder

    print("[TrainingRange] Built at " .. tostring(RANGE_ORIGIN))
end

function TrainingRange.Enter(Player)
    if not Player.Character or not Player.Character:FindFirstChild("HumanoidRootPart") then
        return
    end
    Player.Character.HumanoidRootPart.CFrame = CFrame.new(RANGE_ORIGIN + Vector3.new(0, 5, 20))
    Player.Character:SetAttribute("InTraining", true)
    Player.Character:SetAttribute("InfiniteAmmo", true)
end

function TrainingRange.Leave(Player)
    if Player.Character then
        Player.Character:SetAttribute("InTraining", nil)
        Player.Character:SetAttribute("InfiniteAmmo", nil)
    end
end

-- Strafing-dummy animator: each Heartbeat, move strafe dummies along their
-- A<->B segment. Static dummies are anchored and ignored.
local TICK = 0
RunService.Heartbeat:Connect(function(dt)
    TICK = TICK + dt
    if not rangeFolder then
        return
    end
    for _, rig in ipairs(rangeFolder:GetChildren()) do
        if rig:IsA("Model") and rig.Name:find("StrafeDummy") then
            local ax = rig:GetAttribute("AnchorA_X")
            local az = rig:GetAttribute("AnchorA_Z")
            local bz = rig:GetAttribute("AnchorB_Z")
            if ax and az and bz then
                local t = (math.sin(TICK * 1.5) + 1) * 0.5 -- 0..1
                local newZ = az + (bz - az) * t
                if rig.PrimaryPart then
                    rig.PrimaryPart.CFrame = CFrame.new(ax, rig.PrimaryPart.Position.Y, newZ)
                    -- Head follows torso
                    local head = rig:FindFirstChild("Head")
                    if head then
                        head.CFrame = CFrame.new(ax, rig.PrimaryPart.Position.Y + 1.6, newZ)
                    end
                end
            end
        end
    end
end)

-- Build immediately on server start.
TrainingRange.Build()

-- Clean up on player removing.
Players.PlayerRemoving:Connect(function(p)
    TrainingRange.Leave(p)
end)

return TrainingRange
