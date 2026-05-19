--[[
    RIVALS - Game Server (Main Server Script)
    Type: Script
    Location: ServerScriptService

    Handles player data, matchmaking, combat, progression, and the weapon shop.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local ServerStorage = game:GetService("ServerStorage")

-- Get weapon config module
local WeaponConfig = require(ReplicatedStorage:WaitForChild("WeaponConfig"))

-- DataStore for saving player progress
local playerStore = DataStoreService:GetDataStore("RivalsPlayerData_v1")

-- ============== REMOTE EVENTS ==============
-- Create remotes folder
local remotes = Instance.new("Folder")
remotes.Name = "Remotes"
remotes.Parent = ReplicatedStorage

local function createRemoteEvent(name)
    local re = Instance.new("RemoteEvent")
    re.Name = name
    re.Parent = remotes
    return re
end

local function createRemoteFunction(name)
    local rf = Instance.new("RemoteFunction")
    rf.Name = name
    rf.Parent = remotes
    return rf
end

-- Events
local DamageEvent = createRemoteEvent("DamagePlayer")
local KillFeedEvent = createRemoteEvent("KillFeed")
local XPEvent = createRemoteEvent("XPGained")
local LevelUpEvent = createRemoteEvent("LevelUp")
local EquipWeaponEvent = createRemoteEvent("EquipWeapon")
local FireWeaponEvent = createRemoteEvent("FireWeapon")
local MeleeAttackEvent = createRemoteEvent("MeleeAttack")

-- Functions
local GetPlayerDataFunc = createRemoteFunction("GetPlayerData")
local BuyWeaponFunc = createRemoteFunction("BuyWeapon")
local SetLoadoutFunc = createRemoteFunction("SetLoadout")
local GetShopDataFunc = createRemoteFunction("GetShopData")

-- ============== PLAYER DATA ==============
local playerData = {} -- userId -> data table

local function getDefaultData()
    return {
        level = 1,
        xp = 0,
        keys = 10, -- Starting keys
        inventory = table.clone(WeaponConfig.DefaultInventory),
        loadout = {
            primary = WeaponConfig.DefaultLoadout.primary,
            secondary = WeaponConfig.DefaultLoadout.secondary,
            melee = WeaponConfig.DefaultLoadout.melee,
            utility = WeaponConfig.DefaultLoadout.utility,
        },
        stats = {
            kills = 0,
            deaths = 0,
            wins = 0,
            matchesPlayed = 0,
        }
    }
end

local function loadPlayerData(player)
    local success, data = pcall(function()
        return playerStore:GetAsync("Player_" .. player.UserId)
    end)

    if success and data then
        playerData[player.UserId] = data
    else
        playerData[player.UserId] = getDefaultData()
    end

    return playerData[player.UserId]
end

local function savePlayerData(player)
    local data = playerData[player.UserId]
    if data then
        pcall(function()
            playerStore:SetAsync("Player_" .. player.UserId, data)
        end)
    end
end

-- ============== XP & LEVELING ==============
local function getTotalXPForLevel(level)
    local total = 0
    for l = 1, level - 1 do
        total = total + WeaponConfig.XPForLevel(l)
    end
    return total
end

local function addXP(player, amount)
    local data = playerData[player.UserId]
    if not data then return end

    data.xp = data.xp + amount
    XPEvent:FireClient(player, amount, data.xp)

    -- Check for level ups
    while data.xp >= getTotalXPForLevel(data.level) + WeaponConfig.XPForLevel(data.level) do
        data.level = data.level + 1
        data.keys = data.keys + 5 -- Bonus keys on level up
        LevelUpEvent:FireClient(player, data.level, data.keys)
    end
end

-- ============== COMBAT ==============
local lastFireTime = {} -- playerId -> weaponName -> tick

DamageEvent.OnServerEvent:Connect(function(attacker, targetPlayer, weaponName, hitPart)
    if not targetPlayer or not targetPlayer.Character then return end
    local targetHumanoid = targetPlayer.Character:FindFirstChild("Humanoid")
    if not targetHumanoid or targetHumanoid.Health <= 0 then return end

    local weapon = WeaponConfig.Weapons[weaponName]
    if not weapon then return end

    -- Calculate damage
    local damage = weapon.damage or 0
    local isHeadshot = (hitPart and hitPart.Name == "Head")
    if isHeadshot then
        damage = damage * 2
    end

    -- Apply damage
    targetHumanoid:TakeDamage(damage)

    -- Check for kill
    if targetHumanoid.Health <= 0 then
        local attackerData = playerData[attacker.UserId]
        local targetData = playerData[targetPlayer.UserId]

        if attackerData then
            attackerData.stats.kills = attackerData.stats.kills + 1
            addXP(attacker, isHeadshot and 150 or 100) -- Bonus XP for headshot
            attackerData.keys = attackerData.keys + 1 -- 1 key per kill
        end
        if targetData then
            targetData.stats.deaths = targetData.stats.deaths + 1
        end

        -- Broadcast kill feed
        KillFeedEvent:FireAllClients(attacker.Name, targetPlayer.Name, weaponName, isHeadshot)
    end
end)

-- Melee attack handling
MeleeAttackEvent.OnServerEvent:Connect(function(attacker, targetPlayer, weaponName)
    if not targetPlayer or not targetPlayer.Character then return end
    local targetHumanoid = targetPlayer.Character:FindFirstChild("Humanoid")
    if not targetHumanoid or targetHumanoid.Health <= 0 then return end
    if not attacker.Character then return end

    local weapon = WeaponConfig.Weapons[weaponName]
    if not weapon or weapon.type ~= "melee" then return end

    -- Range check
    local dist = (attacker.Character.PrimaryPart.Position - targetPlayer.Character.PrimaryPart.Position).Magnitude
    if dist > (weapon.range or 8) + 2 then return end -- +2 tolerance

    targetHumanoid:TakeDamage(weapon.damage)

    if targetHumanoid.Health <= 0 then
        local attackerData = playerData[attacker.UserId]
        local targetData = playerData[targetPlayer.UserId]
        if attackerData then
            attackerData.stats.kills = attackerData.stats.kills + 1
            addXP(attacker, 120) -- Melee kill bonus
            attackerData.keys = attackerData.keys + 1
        end
        if targetData then
            targetData.stats.deaths = targetData.stats.deaths + 1
        end
        KillFeedEvent:FireAllClients(attacker.Name, targetPlayer.Name, weaponName, false)
    end
end)

-- ============== SHOP ==============
GetShopDataFunc.OnServerInvoke = function(player)
    local data = playerData[player.UserId]
    if not data then return {} end

    local shopData = {}
    for weaponKey, shopInfo in pairs(WeaponConfig.Shop) do
        local wep = WeaponConfig.Weapons[weaponKey]
        if wep then
            shopData[weaponKey] = {
                name = wep.name,
                type = wep.type,
                damage = wep.damage or 0,
                fireRate = wep.fireRate or 0,
                price = shopInfo.price,
                levelReq = shopInfo.levelReq,
                owned = table.find(data.inventory, weaponKey) ~= nil,
            }
        end
    end
    return shopData
end

BuyWeaponFunc.OnServerInvoke = function(player, weaponKey)
    local data = playerData[player.UserId]
    if not data then return false, "No data" end

    local shopInfo = WeaponConfig.Shop[weaponKey]
    if not shopInfo then return false, "Weapon not found" end

    if table.find(data.inventory, weaponKey) then
        return false, "Already owned"
    end

    if data.level < shopInfo.levelReq then
        return false, "Level too low (need " .. shopInfo.levelReq .. ")"
    end

    if data.keys < shopInfo.price then
        return false, "Not enough keys"
    end

    data.keys = data.keys - shopInfo.price
    table.insert(data.inventory, weaponKey)
    savePlayerData(player)

    return true, "Purchased!"
end

-- ============== LOADOUT ==============
SetLoadoutFunc.OnServerInvoke = function(player, slot, weaponKey)
    local data = playerData[player.UserId]
    if not data then return false end

    local weapon = WeaponConfig.Weapons[weaponKey]
    if not weapon then return false end

    if not table.find(data.inventory, weaponKey) then return false end

    -- Validate slot matches weapon type
    if weapon.type ~= slot then return false end

    data.loadout[slot] = weaponKey
    savePlayerData(player)
    return true
end

GetPlayerDataFunc.OnServerInvoke = function(player)
    return playerData[player.UserId]
end

-- ============== PLAYER CONNECTIONS ==============
Players.PlayerAdded:Connect(function(player)
    local data = loadPlayerData(player)

    -- Setup leaderboard stats
    local leaderstats = Instance.new("Folder")
    leaderstats.Name = "leaderstats"
    leaderstats.Parent = player

    local kills = Instance.new("IntValue")
    kills.Name = "Kills"
    kills.Value = data.stats.kills
    kills.Parent = leaderstats

    local level = Instance.new("IntValue")
    level.Name = "Level"
    level.Value = data.level
    level.Parent = leaderstats

    local keysVal = Instance.new("IntValue")
    keysVal.Name = "Keys"
    keysVal.Value = data.keys
    keysVal.Parent = leaderstats

    -- Respawn handling
    player.CharacterAdded:Connect(function(character)
        local humanoid = character:WaitForChild("Humanoid")
        humanoid.Died:Connect(function()
            task.wait(3) -- Respawn delay
            player:LoadCharacter()
        end)
    end)

    player:LoadCharacter()
end)

Players.PlayerRemoving:Connect(function(player)
    savePlayerData(player)
    playerData[player.UserId] = nil
end)

-- Auto-save every 5 minutes
task.spawn(function()
    while true do
        task.wait(300)
        for _, player in ipairs(Players:GetPlayers()) do
            savePlayerData(player)
        end
    end
end)

print("[RIVALS] Game Server loaded!")
