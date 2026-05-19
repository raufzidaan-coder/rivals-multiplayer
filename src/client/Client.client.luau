--[[
    RIVALS CLONE - CLIENT STARTER SCRIPT
    Put this in StarterPlayer -> StarterPlayerScripts
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local RivalsCore = require(ReplicatedStorage:WaitForChild("RivalsCore"))

local Client = {}
Client.__index = Client

function Client.new()
    local self = setmetatable({}, Client)
    self.Controller = nil
    self.Character = nil
    self.Connections = {}
    return self
end

function Client:Initialize()
    local Character = Player.Character or Player.CharacterAdded:Wait()
    self.Character = Character

    self.Controller = RivalsCore.ClientController.new(Player)
    self.Controller:Initialize()

    self:SetupConnections()
    self:Loadout()

    print("[Rivals] Client initialized")
end

function Client:SetupConnections()
    Player.CharacterAdded:Connect(function(Character)
        self.Character = Character
        self.Controller.Character = Character
        self.Controller.Movement = RivalsCore.MovementSystem.new(Character)
        self.Controller.Combat = RivalsCore.CombatSystem.new(Character)
    end)
end

function Client:Loadout()
    self.Controller:EquipWeapon(1)
end

function Client:Run()
    local Heartbeat = game:GetService("RunService").Heartbeat

    Heartbeat:Connect(function(DeltaTime)
        if self.Controller then
            self.Controller:Update(DeltaTime)
        end
    end)
end

local GameClient = Client.new()
GameClient:Initialize()
GameClient:Run()
