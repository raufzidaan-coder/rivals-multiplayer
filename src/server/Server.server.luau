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
local WeaponModels = require(script.Parent:WaitForChild("WeaponModels"))

local Server = {}
Server.__index = Server

function Server.new()
    local self = setmetatable({}, Server)
    self.Lobby = RivalsCore.LobbySystem.new()
    self.GameMode = nil
    self.Players = {}
    self.PlayerCombat = {} -- [Player] = CombatSystem instance (server-authoritative)
    self.LastFireTime = {} -- [Player] = tick() of last fire (rate limit floor)
    self.AbilityTokens = {} -- [Player] = {tokens=4, last=tick()} for UseAbility RemoteEvent
    self.DataManager = RivalsCore.PlayerDataManager.new()
    self.Abilities = RivalsCore.AbilitySystem.new()
    self.RemoteEvents = self:CreateRemoteEvents()
    return self
end

local TEAM_COLOR = {
    Team1 = Color3.fromRGB(80, 150, 255), -- cyan/blue
    Team2 = Color3.fromRGB(255, 80, 80), -- red
}

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

    Events.FireWeapon = Instance.new("RemoteEvent")
    Events.FireWeapon.Name = "FireWeapon"
    Events.FireWeapon.Parent = ReplicatedStorage

    -- DamageDealt fires to a player when THEY take damage (drives directional
    -- indicator + low-HP vignette on the client).
    Events.DamageDealt = Instance.new("RemoteEvent")
    Events.DamageDealt.Name = "DamageDealt"
    Events.DamageDealt.Parent = ReplicatedStorage

    -- HitConfirm fires to a shooter when THEIR shot lands on an enemy
    -- (drives hit marker UI).
    Events.HitConfirm = Instance.new("RemoteEvent")
    Events.HitConfirm.Name = "HitConfirm"
    Events.HitConfirm.Parent = ReplicatedStorage

    return Events
end

-- Server applies a Highlight + team-color attribute on each character spawn.
-- Color is read by the HUD (nametag) and lets clients tell teams apart
-- regardless of avatar customization.
function Server:ApplyTeamVisuals(Player, Character)
    local team = self.Players[Player] and self.Players[Player].Team
    if not team then
        -- Neutral lobby state — strip any existing Highlight.
        local existing = Character:FindFirstChild("RivalsTeamHL")
        if existing then
            existing:Destroy()
        end
        Character:SetAttribute("Team", nil)
        return
    end

    Character:SetAttribute("Team", team)
    local color = TEAM_COLOR[team] or Color3.new(1, 1, 1)

    local hl = Character:FindFirstChild("RivalsTeamHL") or Instance.new("Highlight")
    hl.Name = "RivalsTeamHL"
    hl.OutlineColor = color
    hl.OutlineTransparency = 0
    hl.FillTransparency = 1
    hl.DepthMode = Enum.HighlightDepthMode.Occluded
    hl.Parent = Character
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

    -- Server-authoritative combat state. Re-created each character spawn so the
    -- new Character/Humanoid references are bound. Old entries are GC'd.
    self.PlayerCombat[Player] = RivalsCore.CombatSystem.new(Character)

    self:ApplyTeamVisuals(Player, Character)
    self:GiveLoadout(Player)

    task.delay(0.1, function()
        self:SpawnInLobby(Player)
    end)
end

-- Populates the player's Backpack with one Tool per weapon they own.
-- Built fresh each spawn via WeaponModels.Build (Fists returns nil — bare hands
-- intended). Roblox auto-handles tool selection via number keys (1-6).
function Server:GiveLoadout(Player)
    local backpack = Player:FindFirstChildOfClass("Backpack")
    if not backpack then
        return
    end
    backpack:ClearAllChildren()
    -- Also strip currently-equipped tool from Character (carries over respawns)
    if Player.Character then
        for _, child in ipairs(Player.Character:GetChildren()) do
            if child:IsA("Tool") then
                child:Destroy()
            end
        end
    end

    local data = self.DataManager:GetData(Player)
    local owned = (data.Inventory and data.Inventory.Weapons) or data.WeaponsOwned or {}
    for _, weaponName in ipairs(owned) do
        local tool = WeaponModels.Build(weaponName)
        if tool then
            tool.Parent = backpack
        end
    end
end

-- Server-authoritative shot pipeline. Client sends aim direction + weapon name;
-- server re-raycasts from the player's HumanoidRootPart (not from a client-supplied
-- origin — that would let cheaters spoof position), looks up weapon stats from
-- the canonical WEAPONS table, rate-limits by WeaponData.FireRate, applies damage
-- via the victim's server-side CombatSystem.
function Server:ProcessFire(ShooterPlayer, WeaponName, AimDirection)
    -- Input shape validation: keep the surface tight.
    if type(WeaponName) ~= "string" or #WeaponName > 32 then
        return
    end
    if typeof(AimDirection) ~= "Vector3" then
        return
    end
    if AimDirection.Magnitude < 0.5 or AimDirection.Magnitude > 2 then
        return -- direction must be roughly unit
    end

    local WeaponData = RivalsCore.WEAPONS[WeaponName]
    if not WeaponData then
        return
    end

    -- Rate limit: server-side floor at WeaponData.FireRate to drop spam.
    local now = tick()
    local last = self.LastFireTime[ShooterPlayer] or 0
    if (now - last) < WeaponData.FireRate then
        return
    end
    self.LastFireTime[ShooterPlayer] = now

    local ShooterChar = ShooterPlayer.Character
    if not (ShooterChar and ShooterChar:FindFirstChild("HumanoidRootPart")) then
        return
    end

    local RayOrigin = ShooterChar.HumanoidRootPart.Position
    local Params = RaycastParams.new()
    Params.FilterDescendantInstances = { ShooterChar }
    Params.FilterType = Enum.RaycastFilterType.Exclude

    local Result = workspace:Raycast(RayOrigin, AimDirection.Unit * WeaponData.Range, Params)
    if not Result then
        return
    end

    local HitCharacter = Result.Instance:FindFirstAncestorWhichIsA("Model")
    if not HitCharacter or HitCharacter == ShooterChar then
        return
    end

    local Victim = Players:GetPlayerFromCharacter(HitCharacter)
    if not Victim then
        return
    end

    local victimCombat = self.PlayerCombat[Victim]
    if not victimCombat then
        return
    end

    local _, IsHeadshot = victimCombat:TakeDamage(WeaponData.Damage, ShooterPlayer, Result.Instance)

    -- Award headshot stat on shooter
    if IsHeadshot then
        local Data = self.DataManager:GetData(ShooterPlayer)
        Data.Headshots = (Data.Headshots or 0) + 1
    end

    -- Notify victim: drives directional indicator + low-HP vignette.
    local shooterChar = ShooterPlayer.Character
    local shooterPos = shooterChar
            and shooterChar:FindFirstChild("HumanoidRootPart")
            and shooterChar.HumanoidRootPart.Position
        or RayOrigin
    self.RemoteEvents.DamageDealt:FireClient(Victim, shooterPos, WeaponData.Damage, IsHeadshot)

    -- Notify shooter: drives hit marker UI.
    local wasLethal = victimCombat.IsDead == true
    self.RemoteEvents.HitConfirm:FireClient(ShooterPlayer, IsHeadshot, wasLethal)
end

-- Server-authoritative Grenade dispatch. Spawns a physics ball at the caster's
-- camera-forward, 3s fuse, then computes falloff damage on each player in range.
-- LOS halved damage (explosions wrap cover); friendly-fire off by default.
function Server:DispatchGrenade(Caster)
    local cfg = RivalsCore.AbilitySystem.GrenadeConfig
    local char = Caster.Character
    if not (char and char:FindFirstChild("HumanoidRootPart")) then
        return
    end
    local hrp = char.HumanoidRootPart
    local forward = hrp.CFrame.LookVector

    local grenade = Instance.new("Part")
    grenade.Name = "RivalsGrenade"
    grenade.Shape = Enum.PartType.Ball
    grenade.Size = Vector3.new(1.2, 1.2, 1.2)
    grenade.Material = Enum.Material.Metal
    grenade.BrickColor = BrickColor.new("Olive")
    grenade.CFrame = hrp.CFrame + forward * 2 + Vector3.new(0, 1.5, 0)
    grenade.CustomPhysicalProperties = PhysicalProperties.new(1.2, 0.5, 0.35, 1, 1)
    grenade.AssemblyLinearVelocity = forward * cfg.ThrowSpeed + Vector3.new(0, cfg.ThrowArcUp, 0)
    grenade.Parent = workspace

    task.delay(cfg.Fuse, function()
        if not grenade or not grenade.Parent then
            return
        end
        local blastCenter = grenade.Position
        grenade:Destroy()

        for _, otherPlayer in ipairs(Players:GetPlayers()) do
            local oc = otherPlayer.Character
            if oc and oc:FindFirstChild("HumanoidRootPart") then
                local dist = (oc.HumanoidRootPart.Position - blastCenter).Magnitude
                if dist <= cfg.OuterRadius then
                    local dmg
                    if dist <= cfg.InnerRadius then
                        dmg = cfg.MaxDmg
                    else
                        local t = (dist - cfg.InnerRadius) / (cfg.OuterRadius - cfg.InnerRadius)
                        dmg = cfg.MaxDmg - t * (cfg.MaxDmg - cfg.MinDmg)
                    end
                    -- LOS check: if blocked by world geometry, halve damage.
                    local rp = RaycastParams.new()
                    rp.FilterDescendantInstances = { oc, char }
                    rp.FilterType = Enum.RaycastFilterType.Exclude
                    local los = workspace:Raycast(blastCenter, oc.HumanoidRootPart.Position - blastCenter, rp)
                    if los then
                        dmg = dmg * 0.5
                    end
                    local victimCombat = self.PlayerCombat[otherPlayer]
                    if victimCombat then
                        victimCombat:TakeDamage(dmg, Caster, oc.HumanoidRootPart)
                    end
                end
            end
        end
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

    self.RemoteEvents.FireWeapon.OnServerEvent:Connect(function(Player, WeaponName, AimDirection)
        self:ProcessFire(Player, WeaponName, AimDirection)
    end)

    self.RemoteEvents.UseAbility.OnServerEvent:Connect(function(Player, AbilityName)
        -- Per-player token bucket on the RemoteEvent itself (research finding
        -- T-anticheat #2). Caps total UseAbility calls/sec regardless of
        -- which ability — drops spam at the wire before AbilitySystem sees it.
        local bucket = self.AbilityTokens[Player]
        if not bucket then
            bucket = { tokens = 4, last = tick() }
            self.AbilityTokens[Player] = bucket
        end
        local now = tick()
        bucket.tokens = math.min(4, bucket.tokens + (now - bucket.last) * 2) -- refill 2/sec, cap 4
        bucket.last = now
        if bucket.tokens < 1 then
            return
        end
        bucket.tokens = bucket.tokens - 1

        if type(AbilityName) ~= "string" or #AbilityName > 32 then
            return
        end
        local ok, reason = self.Abilities:Use(Player, AbilityName)
        if not ok then
            if reason == "unknown ability" then
                warn(string.format("[Server] UseAbility rejected: %q (%s)", AbilityName, reason))
            end
            return
        end
        -- Dispatch: route the now-authorized ability to its effect.
        if AbilityName == "Grenade" then
            self:DispatchGrenade(Player)
        end
        -- Flashbang/QuickMelee dispatchers can be wired here later.
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
    -- Voice chat: enable the new Audio API path so AudioDeviceInput/Emitter
    -- get auto-created per voice-enabled player. Team-scoping happens later
    -- in WireGameMode. The toggle is no-op if voice isn't available.
    pcall(function()
        local VoiceChatService = game:GetService("VoiceChatService")
        VoiceChatService.UseAudioApi = Enum.AudioApiRollout.Enabled
    end)

    -- Lighting + post-FX preset per T2-M6 research (Valorant-style clarity).
    pcall(function()
        local Lighting = game:GetService("Lighting")
        Lighting.Technology = Enum.Technology.ShadowMap
        Lighting.ClockTime = 14.5
        Lighting.Brightness = 2
        Lighting.Ambient = Color3.fromRGB(70, 70, 75)
        Lighting.OutdoorAmbient = Color3.fromRGB(110, 115, 125)
        Lighting.GlobalShadows = true
        Lighting.ShadowSoftness = 0.2
        Lighting.EnvironmentDiffuseScale = 0.4
        Lighting.EnvironmentSpecularScale = 0.2
        Lighting.FogStart = 400
        Lighting.FogEnd = 1200
        Lighting.FogColor = Color3.fromRGB(190, 195, 200)

        local function ensure(className, props)
            local existing = Lighting:FindFirstChildOfClass(className)
            if not existing then
                existing = Instance.new(className)
                existing.Parent = Lighting
            end
            for k, v in pairs(props) do
                existing[k] = v
            end
        end
        ensure("BloomEffect", { Intensity = 0.3, Size = 12, Threshold = 1.4 })
        ensure("ColorCorrectionEffect", {
            Saturation = 0.15,
            Contrast = 0.12,
            Brightness = 0.02,
            TintColor = Color3.fromRGB(255, 250, 245),
        })
        ensure("Atmosphere", { Density = 0.25, Offset = 0.1, Haze = 1.2, Glare = 0 })
        -- DepthOfField intentionally omitted: distance blur is fatal for FPS.
    end)

    self:SetupRemoteListeners()

    Players.PlayerAdded:Connect(function(Player)
        self:OnPlayerJoined(Player)
    end)

    Players.PlayerRemoving:Connect(function(Player)
        self.Lobby:LeaveQueue(Player)
        self.Players[Player] = nil
        self.PlayerCombat[Player] = nil
        self.LastFireTime[Player] = nil
        self.AbilityTokens[Player] = nil
        self.Abilities:ClearPlayer(Player)
    end)

    for _, Player in ipairs(Players:GetPlayers()) do
        self:OnPlayerJoined(Player)
    end

    -- The original code never connected GameModeManager:Update or per-player
    -- CombatSystem:Update to Heartbeat — round timers, knockback decay, and
    -- (future) armor regen were dead code. One Heartbeat connection fans out
    -- to every system that wants a per-frame tick.
    RunService.Heartbeat:Connect(function(dt)
        debug.profilebegin("RivalsServerTick")
        if self.GameMode then
            self.GameMode:Update(dt)
        end
        for _, combat in pairs(self.PlayerCombat) do
            combat:Update(dt)
        end
        debug.profileend()
    end)

    print("[Rivals] Server started successfully")
end

local GameServer = Server.new()
GameServer:Start()
