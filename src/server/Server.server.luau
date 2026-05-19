--[[
    RIVALS CLONE - SERVER SCRIPT
    Put this in ServerScriptService
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Studio dev convenience: ensure HttpService is enabled at boot so the MCP plugin,
-- analytics, and any HttpService:RequestAsync call works without needing the
-- per-place Game Settings toggle (which is greyed out for unsaved .rbxlx files).
-- No-op in production (RunService:IsStudio() guard).
local RunService = game:GetService("RunService")
if RunService:IsStudio() then
    local HttpService = game:GetService("HttpService")
    pcall(function()
        HttpService.HttpEnabled = true
    end)
end

local RivalsCore = require(ReplicatedStorage:WaitForChild("RivalsCore"))

local Server = {}
Server.__index = Server

function Server.new()
    local self = setmetatable({}, Server)
    self.Lobby = RivalsCore.LobbySystem.new()
    self.GameMode = nil
    self.Players = {}
    self.DataManager = RivalsCore.PlayerDataManager.new()
    self.Abilities = RivalsCore.AbilitySystem.new()
    self.RemoteEvents = self:CreateRemoteEvents()
    return self
end

function Server:CreateRemoteEvents()
    local Events = {}

    Events.JoinQueue = Instance.new("RemoteEvent")
    Events.JoinQueue.Name = "JoinQueue"
    Events.JoinQueue.Parent = ReplicatedStorage

    Events.LeaveQueue = Instance.new("RemoteEvent")
    Events.LeaveQueue.Name = "LeaveQueue"
    Events.LeaveQueue.Parent = ReplicatedStorage

    Events.Ready = Instance.new("RemoteEvent")
    Events.Ready.Name = "Ready"
    Events.Ready.Parent = ReplicatedStorage

    Events.SwitchWeapon = Instance.new("RemoteEvent")
    Events.SwitchWeapon.Name = "SwitchWeapon"
    Events.SwitchWeapon.Parent = ReplicatedStorage

    Events.UseAbility = Instance.new("RemoteEvent")
    Events.UseAbility.Name = "UseAbility"
    Events.UseAbility.Parent = ReplicatedStorage

    Events.UpdateMatchState = Instance.new("RemoteEvent")
    Events.UpdateMatchState.Name = "UpdateMatchState"
    Events.UpdateMatchState.Parent = ReplicatedStorage

    Events.KillFeed = Instance.new("RemoteEvent")
    Events.KillFeed.Name = "KillFeed"
    Events.KillFeed.Parent = ReplicatedStorage

    return Events
end

function Server:OnPlayerJoined(Player)
    local Data = self.DataManager:GetData(Player)

    local Leaderstats = Instance.new("Folder")
    Leaderstats.Name = "leaderstats"
    Leaderstats.Parent = Player

    local Level = Instance.new("IntValue")
    Level.Name = "Level"
    Level.Value = Data.Level
    Level.Parent = Leaderstats

    local Kills = Instance.new("IntValue")
    Kills.Name = "Kills"
    Kills.Value = Data.Kills
    Kills.Parent = Leaderstats

    local Wins = Instance.new("IntValue")
    Wins.Name = "Wins"
    Wins.Value = Data.RankedWins + Data.CasualWins
    Wins.Parent = Leaderstats

    Player.CharacterAdded:Connect(function(Character)
        self:OnCharacterAdded(Player, Character)
    end)

    if Player.Character then
        self:OnCharacterAdded(Player, Player.Character)
    end
end

function Server:OnCharacterAdded(Player, Character)
    local Humanoid = Character:FindFirstChild("Humanoid")
    if Humanoid then
        Humanoid.Died:Connect(function()
            self:OnPlayerDied(Player)
        end)
    end

    task.delay(0.1, function()
        self:SpawnInLobby(Player)
    end)
end

function Server:SpawnInLobby(Player)
    if Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
        local SpawnLocation = workspace:FindFirstChild("LobbySpawn")
        if SpawnLocation then
            Player.Character.HumanoidRootPart.CFrame = SpawnLocation.CFrame + Vector3.new(0, 5, 0)
        else
            Player.Character.HumanoidRootPart.CFrame = CFrame.new(0, 10, 0)
        end
    end
end

function Server:SetupRemoteListeners()
    self.RemoteEvents.JoinQueue.OnServerEvent:Connect(function(Player, QueueType)
        self:JoinQueue(Player, QueueType)
    end)

    self.RemoteEvents.LeaveQueue.OnServerEvent:Connect(function(Player)
        self.Lobby:LeaveQueue(Player)
    end)

    self.RemoteEvents.Ready.OnServerEvent:Connect(function(Player, IsReady)
        self:SetPlayerReady(Player, IsReady)
    end)

    self.RemoteEvents.SwitchWeapon.OnServerEvent:Connect(function(Player, Slot)
        self:SwitchPlayerWeapon(Player, Slot)
    end)

    self.RemoteEvents.UseAbility.OnServerEvent:Connect(function(Player, AbilityName)
        -- AbilityName is client-supplied; cap to known string keys to avoid table-key spam.
        if type(AbilityName) ~= "string" or #AbilityName > 32 then
            return
        end
        local ok, reason = self.Abilities:Use(Player, AbilityName)
        if not ok then
            -- Silent rejection on cooldown; warn for unknown abilities so devs notice during playtest.
            if reason == "unknown ability" then
                warn(string.format("[Server] UseAbility rejected: %q (%s)", AbilityName, reason))
            end
        end
    end)
end

-- Call this once a GameModeManager is active for the current match. Subscribes
-- to its phase events and rebroadcasts via the UpdateMatchState RemoteEvent so
-- clients can update HUD timers, score, phase text, etc.
function Server:WireGameMode(gameMode)
    self.GameMode = gameMode
    local update = self.RemoteEvents.UpdateMatchState
    gameMode:OnEvent("RoundStart", function(roundNumber)
        update:FireAllClients("RoundStart", {
            round = roundNumber,
            timeRemaining = gameMode.State.TimeRemaining,
            team1Score = gameMode.State.Team1Score,
            team2Score = gameMode.State.Team2Score,
        })
    end)
    gameMode:OnEvent("RoundEnd", function(winnerTeam, t1, t2)
        update:FireAllClients("RoundEnd", { winner = winnerTeam, team1Score = t1, team2Score = t2 })
    end)
    gameMode:OnEvent("MatchEnd", function(winnerTeam, t1, t2)
        update:FireAllClients("MatchEnd", { winner = winnerTeam, team1Score = t1, team2Score = t2 })
    end)
end

function Server:JoinQueue(Player, QueueType)
    if QueueType == "Ranked" and not self.DataManager:CanPlayRanked(Player) then
        return false
    end

    self.Lobby:JoinQueue(Player, QueueType)
    return true
end

function Server:SetPlayerReady(Player, IsReady)
    if not self.Players[Player] then
        self.Players[Player] = {}
    end
    self.Players[Player].Ready = IsReady
end

function Server:SwitchPlayerWeapon(Player, Slot)
    -- Validate slot is an integer in [1, 4] (slots = Primary, Secondary, Melee, Utility).
    if type(Slot) ~= "number" or Slot < 1 or Slot > 4 or Slot % 1 ~= 0 then
        return false
    end

    if not self.Players[Player] then
        self.Players[Player] = {}
    end

    if not self.Players[Player].WeaponSwitches then
        self.Players[Player].WeaponSwitches = 0
    end

    if self.Players[Player].WeaponSwitches >= 2 then
        return false
    end

    self.Players[Player].CurrentSlot = Slot

    self.Players[Player].WeaponSwitches = self.Players[Player].WeaponSwitches + 1
    return true
end

function Server:OnPlayerDied(Player)
    if self.GameMode and self.GameMode.State.Phase == "Playing" then
        local Team = self:GetPlayerTeam(Player)

        if Team then
            local Team1Alive = self.GameMode:GetAliveCount("Team1")
            local Team2Alive = self.GameMode:GetAliveCount("Team2")

            if Team1Alive == 0 or Team2Alive == 0 then
                local Winner = Team1Alive > 0 and "Team1" or "Team2"
                self.GameMode:EndRound(Winner)
            end
        end

        self.RemoteEvents.KillFeed:FireAllClients(Player)
    end
end

function Server:GetPlayerTeam(Player)
    if self.GameMode then
        for TeamName, Team in pairs(self.GameMode.State.Teams) do
            if table.find(Team, Player) then
                return TeamName
            end
        end
    end
    return nil
end

function Server:Start()
    self:SetupRemoteListeners()

    Players.PlayerAdded:Connect(function(Player)
        self:OnPlayerJoined(Player)
    end)

    Players.PlayerRemoving:Connect(function(Player)
        self.Lobby:LeaveQueue(Player)
        self.Players[Player] = nil
        self.Abilities:ClearPlayer(Player)
    end)

    for _, Player in ipairs(Players:GetPlayers()) do
        self:OnPlayerJoined(Player)
    end

    print("[Rivals] Server started successfully")
end

local GameServer = Server.new()
GameServer:Start()
