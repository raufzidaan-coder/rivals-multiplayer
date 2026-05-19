--[[
    RIVALS CLONE - LOBBY PAD SYSTEM
    Create these pads in your Roblox Studio place
]]

local Players = game:GetService("Players")

local PadSystem = {}
PadSystem.__index = PadSystem

function PadSystem.new()
    local self = setmetatable({}, PadSystem)
    self.Pads = {}
    self.QueuedPlayers = {}
    return self
end

function PadSystem:CreatePad(Name, Color, Position, QueueType, TeamSize)
    local Pad = {}
    Pad.Name = Name
    Pad.Color = Color
    Pad.Position = Position
    Pad.QueueType = QueueType
    Pad.TeamSize = TeamSize
    Pad.Players = {}

    local Part = Instance.new("Part")
    Part.Name = Name .. "Pad"
    Part.Size = Vector3.new(6, 1, 6)
    Part.Position = Position
    Part.Anchored = true
    Part.CanCollide = false
    Part.Transparency = 0.5

    local Mesh = Instance.new("SpecialMesh")
    Mesh.MeshType = Enum.MeshType.Brick
    Mesh.Parent = Part

    local SurfaceGui = Instance.new("SurfaceGui")
    SurfaceGui.Adornee = Part
    SurfaceGui.Parent = Part

    local TextLabel = Instance.new("TextLabel")
    TextLabel.Size = UDim2.fromScale(1, 1)
    TextLabel.BackgroundTransparency = 1
    TextLabel.Text = Name
    TextLabel.TextColor3 = Color
    TextLabel.TextScaled = true
    TextLabel.Font = Enum.Font.GothamBold
    TextLabel.Parent = SurfaceGui

    local ClickDetector = Instance.new("ClickDetector")
    ClickDetector.MouseClick:Connect(function(Player)
        self:OnPadClicked(Player, Pad)
    end)
    ClickDetector.Parent = Part

    Part.Touched:Connect(function(otherPart)
        local character = otherPart.Parent
        if character and character:FindFirstChildOfClass("Humanoid") then
            local Player = Players:GetPlayerFromCharacter(character)
            if Player then
                self:OnPadTouched(Player, Pad)
            end
        end
    end)
    Part.TouchEnded:Connect(function(otherPart)
        local character = otherPart.Parent
        if character and character:FindFirstChildOfClass("Humanoid") then
            local Player = Players:GetPlayerFromCharacter(character)
            if Player then
                self:OnPadUntouched(Player, Pad)
            end
        end
    end)

    Part.Parent = workspace

    Pad.Part = Part
    Pad.TextLabel = TextLabel

    self.Pads[Name] = Pad

    return Pad
end

function PadSystem:OnPadClicked(Player, Pad)
    self:JoinPad(Player, Pad)
end

function PadSystem:OnPadTouched(Player, Pad)
    self:JoinPad(Player, Pad)
end

function PadSystem:OnPadUntouched(Player, Pad)
    self:LeavePad(Player, Pad)
end

function PadSystem:JoinPad(Player, Pad)
    if not table.find(Pad.Players, Player) then
        table.insert(Pad.Players, Player)
        self:UpdatePadVisual(Pad)

        if #Pad.Players >= Pad.TeamSize * 2 then
            self:StartMatchFromPad(Pad)
        end
    end
end

function PadSystem:LeavePad(Player, Pad)
    local Index = table.find(Pad.Players, Player)
    if Index then
        table.remove(Pad.Players, Index)
        self:UpdatePadVisual(Pad)
    end
end

function PadSystem:UpdatePadVisual(Pad)
    local Required = Pad.TeamSize * 2
    local Current = #Pad.Players

    local Text = string.format("%s\n%d/%d", Pad.Name, Current, Required)
    Pad.TextLabel.Text = Text

    local Intensity = Current / Required
    local BaseColor = Pad.Color

    if Pad.Part then
        Pad.Part.Color = Color3.new(
            BaseColor.R * (0.3 + Intensity * 0.7),
            BaseColor.G * (0.3 + Intensity * 0.7),
            BaseColor.B * (0.3 + Intensity * 0.7)
        )
    end
end

function PadSystem:StartMatchFromPad(Pad)
    local Team1 = {}
    local Team2 = {}

    for i, Player in ipairs(Pad.Players) do
        if i % 2 == 1 then
            table.insert(Team1, Player)
        else
            table.insert(Team2, Player)
        end
    end

    Pad.Players = {}
    self:UpdatePadVisual(Pad)

    local GameMode = require(game.ReplicatedStorage:WaitForChild("RivalsCore")).GameModeManager.new()
    GameMode:StartMatch(Team1, Team2, "Arena")

    print("[Rivals] Match started with " .. Pad.QueueType)
end

function PadSystem:SetupDefaultPads()
    self:CreatePad("1v1", Color3.new(0, 1, 0), Vector3.new(-30, 0.5, 0), "OneVOne", 1)
    self:CreatePad("2v2", Color3.new(0, 0.5, 1), Vector3.new(-15, 0.5, 0), "TwoVTwo", 2)
    self:CreatePad("5v5", Color3.new(1, 0.2, 0.2), Vector3.new(0, 0.5, 0), "FiveVFive", 5)
    self:CreatePad("Special", Color3.new(1, 1, 0), Vector3.new(15, 0.5, 0), "Special", 4)
    self:CreatePad("Shooting Range", Color3.new(0.5, 0.5, 0.5), Vector3.new(30, 0.5, 0), "Practice", 1)
end

return PadSystem
