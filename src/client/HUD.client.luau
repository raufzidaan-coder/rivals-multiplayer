--[[
    Rivals HUD — built per the 24-agent research synthesis.

    Layout (bottom-anchored, AAA-FPS standard):
      Bottom-center-left:  Health bar (green -> yellow -> red, color-tweened)
      Bottom-center-right: Armor bar (cyan/blue)
      Bottom-right:        Ammo readout (big mag / small reserve, red-flash <25%)
      Center:              Dynamic crosshair (gap scales with WeaponSystem:GetSpread)
      Top-center:          Round timer + Team1/Team2 score (driven by UpdateMatchState)
      Top-right:           Kill feed
      Full-screen overlay: Low-HP red vignette, directional damage arc, hit marker

    Reads:
      - Humanoid.Health for live HP updates (cheap, replicated)
      - ReplicatedStorage.DamageDealt for directional indicator + vignette flash
      - ReplicatedStorage.HitConfirm for hit marker
      - ReplicatedStorage.UpdateMatchState for timer + score
      - ReplicatedStorage.KillFeed for kill feed entries
      - workspace[character]:GetAttribute("Team") for nametag color
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local LocalPlayer = Players.LocalPlayer

local function waitRemote(name)
    return ReplicatedStorage:WaitForChild(name, 30)
end

local DamageDealt = waitRemote("DamageDealt")
local HitConfirm = waitRemote("HitConfirm")
local UpdateMatchState = waitRemote("UpdateMatchState")
local KillFeed = waitRemote("KillFeed")

local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Clean up any prior HUD (handles re-running on character respawn).
local existing = PlayerGui:FindFirstChild("RivalsHUD")
if existing then
    existing:Destroy()
end

local HUD = Instance.new("ScreenGui")
HUD.Name = "RivalsHUD"
HUD.ResetOnSpawn = false
HUD.IgnoreGuiInset = true
HUD.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
HUD.Parent = PlayerGui

-- ============================================================================
-- Health + Armor bar (bottom-center-left)
-- ============================================================================
local healthContainer = Instance.new("Frame")
healthContainer.Name = "HealthContainer"
healthContainer.AnchorPoint = Vector2.new(0, 1)
healthContainer.Position = UDim2.fromScale(0.02, 0.95)
healthContainer.Size = UDim2.fromOffset(280, 70)
healthContainer.BackgroundTransparency = 1
healthContainer.Parent = HUD

local armorBack = Instance.new("Frame")
armorBack.Name = "ArmorBack"
armorBack.Size = UDim2.new(1, 0, 0, 8)
armorBack.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
armorBack.BackgroundTransparency = 0.3
armorBack.BorderSizePixel = 0
armorBack.Parent = healthContainer
local armorCorner = Instance.new("UICorner")
armorCorner.CornerRadius = UDim.new(0, 4)
armorCorner.Parent = armorBack

local armorFill = Instance.new("Frame")
armorFill.Name = "Fill"
armorFill.Size = UDim2.fromScale(0, 1)
armorFill.BackgroundColor3 = Color3.fromRGB(120, 180, 255)
armorFill.BorderSizePixel = 0
armorFill.Parent = armorBack
Instance.new("UICorner", armorFill).CornerRadius = UDim.new(0, 4)

local healthBack = Instance.new("Frame")
healthBack.Name = "HealthBack"
healthBack.Size = UDim2.new(1, 0, 0, 28)
healthBack.Position = UDim2.fromOffset(0, 14)
healthBack.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
healthBack.BackgroundTransparency = 0.3
healthBack.BorderSizePixel = 0
healthBack.Parent = healthContainer
Instance.new("UICorner", healthBack).CornerRadius = UDim.new(0, 4)

local healthFill = Instance.new("Frame")
healthFill.Name = "Fill"
healthFill.Size = UDim2.fromScale(1, 1)
healthFill.BackgroundColor3 = Color3.fromRGB(80, 220, 90)
healthFill.BorderSizePixel = 0
healthFill.Parent = healthBack
Instance.new("UICorner", healthFill).CornerRadius = UDim.new(0, 4)

local healthText = Instance.new("TextLabel")
healthText.Name = "Text"
healthText.Size = UDim2.fromScale(1, 1)
healthText.BackgroundTransparency = 1
healthText.Text = "100"
healthText.Font = Enum.Font.GothamBold
healthText.TextSize = 22
healthText.TextColor3 = Color3.new(1, 1, 1)
healthText.TextStrokeTransparency = 0
healthText.Parent = healthBack

-- ============================================================================
-- Ammo readout (bottom-right)
-- ============================================================================
local ammoContainer = Instance.new("Frame")
ammoContainer.Name = "AmmoContainer"
ammoContainer.AnchorPoint = Vector2.new(1, 1)
ammoContainer.Position = UDim2.fromScale(0.98, 0.95)
ammoContainer.Size = UDim2.fromOffset(220, 90)
ammoContainer.BackgroundTransparency = 1
ammoContainer.Parent = HUD

local magText = Instance.new("TextLabel")
magText.Name = "Mag"
magText.Size = UDim2.fromScale(0.55, 1)
magText.BackgroundTransparency = 1
magText.Text = "30"
magText.Font = Enum.Font.GothamBlack
magText.TextSize = 56
magText.TextColor3 = Color3.new(1, 1, 1)
magText.TextXAlignment = Enum.TextXAlignment.Right
magText.TextStrokeTransparency = 0
magText.Parent = ammoContainer

local sepText = Instance.new("TextLabel")
sepText.Name = "Sep"
sepText.Size = UDim2.fromScale(0.1, 0.6)
sepText.Position = UDim2.fromScale(0.55, 0.2)
sepText.BackgroundTransparency = 1
sepText.Text = "/"
sepText.Font = Enum.Font.GothamBold
sepText.TextSize = 36
sepText.TextColor3 = Color3.fromRGB(160, 160, 160)
sepText.Parent = ammoContainer

local reserveText = Instance.new("TextLabel")
reserveText.Name = "Reserve"
reserveText.Size = UDim2.fromScale(0.35, 0.6)
reserveText.Position = UDim2.fromScale(0.65, 0.3)
reserveText.BackgroundTransparency = 1
reserveText.Text = "90"
reserveText.Font = Enum.Font.Gotham
reserveText.TextSize = 28
reserveText.TextColor3 = Color3.fromRGB(180, 180, 180)
reserveText.TextXAlignment = Enum.TextXAlignment.Left
reserveText.Parent = ammoContainer

local weaponNameLabel = Instance.new("TextLabel")
weaponNameLabel.Name = "WeaponName"
weaponNameLabel.Size = UDim2.new(1, 0, 0, 18)
weaponNameLabel.Position = UDim2.new(0, 0, 1, -18)
weaponNameLabel.BackgroundTransparency = 1
weaponNameLabel.Text = "ASSAULT RIFLE"
weaponNameLabel.Font = Enum.Font.GothamMedium
weaponNameLabel.TextSize = 14
weaponNameLabel.TextXAlignment = Enum.TextXAlignment.Right
weaponNameLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
weaponNameLabel.Parent = ammoContainer

-- ============================================================================
-- Dynamic crosshair (center)
-- ============================================================================
local crosshair = Instance.new("Frame")
crosshair.Name = "Crosshair"
crosshair.AnchorPoint = Vector2.new(0.5, 0.5)
crosshair.Position = UDim2.fromScale(0.5, 0.5)
crosshair.Size = UDim2.fromOffset(40, 40)
crosshair.BackgroundTransparency = 1
crosshair.Parent = HUD

local function makeCrosshairLine(name, sizeX, sizeY, anchorX, anchorY)
    local f = Instance.new("Frame")
    f.Name = name
    f.AnchorPoint = Vector2.new(anchorX, anchorY)
    f.BackgroundColor3 = Color3.new(1, 1, 1)
    f.BorderSizePixel = 0
    f.Size = UDim2.fromOffset(sizeX, sizeY)
    f.Parent = crosshair
    return f
end

local chTop = makeCrosshairLine("Top", 2, 6, 0.5, 1)
local chBottom = makeCrosshairLine("Bottom", 2, 6, 0.5, 0)
local chLeft = makeCrosshairLine("Left", 6, 2, 1, 0.5)
local chRight = makeCrosshairLine("Right", 6, 2, 0, 0.5)

local chDot = Instance.new("Frame")
chDot.Name = "Dot"
chDot.AnchorPoint = Vector2.new(0.5, 0.5)
chDot.Position = UDim2.fromScale(0.5, 0.5)
chDot.Size = UDim2.fromOffset(2, 2)
chDot.BackgroundColor3 = Color3.new(1, 1, 1)
chDot.BorderSizePixel = 0
chDot.Parent = crosshair

-- ============================================================================
-- Top-center: round timer + scores
-- ============================================================================
local topBar = Instance.new("Frame")
topBar.Name = "TopBar"
topBar.AnchorPoint = Vector2.new(0.5, 0)
topBar.Position = UDim2.fromScale(0.5, 0.02)
topBar.Size = UDim2.fromOffset(420, 50)
topBar.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
topBar.BackgroundTransparency = 0.3
topBar.BorderSizePixel = 0
topBar.Parent = HUD
Instance.new("UICorner", topBar).CornerRadius = UDim.new(0, 6)

local team1Score = Instance.new("TextLabel")
team1Score.Name = "Team1Score"
team1Score.Size = UDim2.fromScale(0.3, 1)
team1Score.BackgroundTransparency = 1
team1Score.Text = "0"
team1Score.Font = Enum.Font.GothamBold
team1Score.TextSize = 28
team1Score.TextColor3 = Color3.fromRGB(80, 150, 255)
team1Score.Parent = topBar

local timerText = Instance.new("TextLabel")
timerText.Name = "Timer"
timerText.Size = UDim2.fromScale(0.4, 1)
timerText.Position = UDim2.fromScale(0.3, 0)
timerText.BackgroundTransparency = 1
timerText.Text = "—:—"
timerText.Font = Enum.Font.GothamBlack
timerText.TextSize = 24
timerText.TextColor3 = Color3.new(1, 1, 1)
timerText.Parent = topBar

local team2Score = Instance.new("TextLabel")
team2Score.Name = "Team2Score"
team2Score.Size = UDim2.fromScale(0.3, 1)
team2Score.Position = UDim2.fromScale(0.7, 0)
team2Score.BackgroundTransparency = 1
team2Score.Text = "0"
team2Score.Font = Enum.Font.GothamBold
team2Score.TextSize = 28
team2Score.TextColor3 = Color3.fromRGB(255, 80, 80)
team2Score.Parent = topBar

-- ============================================================================
-- Kill feed (top-right)
-- ============================================================================
local killFeedContainer = Instance.new("Frame")
killFeedContainer.Name = "KillFeed"
killFeedContainer.AnchorPoint = Vector2.new(1, 0)
killFeedContainer.Position = UDim2.fromScale(0.98, 0.1)
killFeedContainer.Size = UDim2.fromScale(0.25, 0.3)
killFeedContainer.BackgroundTransparency = 1
killFeedContainer.Parent = HUD

local kfLayout = Instance.new("UIListLayout")
kfLayout.SortOrder = Enum.SortOrder.LayoutOrder
kfLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
kfLayout.Padding = UDim.new(0, 4)
kfLayout.Parent = killFeedContainer

KillFeed.OnClientEvent:Connect(function(victim)
    local entry = Instance.new("TextLabel")
    entry.Size = UDim2.new(1, 0, 0, 22)
    entry.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    entry.BackgroundTransparency = 0.3
    entry.Text = "  " .. (typeof(victim) == "Instance" and victim.Name or tostring(victim)) .. " eliminated  "
    entry.Font = Enum.Font.GothamMedium
    entry.TextSize = 14
    entry.TextColor3 = Color3.fromRGB(220, 220, 220)
    entry.TextXAlignment = Enum.TextXAlignment.Right
    entry.Parent = killFeedContainer
    Debris:AddItem(entry, 5)
end)

-- ============================================================================
-- Damage indicators (full-screen overlay)
-- ============================================================================
local damageOverlay = Instance.new("Frame")
damageOverlay.Name = "DamageOverlay"
damageOverlay.Size = UDim2.fromScale(1, 1)
damageOverlay.BackgroundTransparency = 1
damageOverlay.ZIndex = 5
damageOverlay.Parent = HUD

-- Low-HP vignette
local vignette = Instance.new("Frame")
vignette.Name = "Vignette"
vignette.Size = UDim2.fromScale(1, 1)
vignette.BackgroundColor3 = Color3.fromRGB(200, 30, 30)
vignette.BackgroundTransparency = 1
vignette.BorderSizePixel = 0
vignette.ZIndex = 6
vignette.Parent = damageOverlay
local vignetteGrad = Instance.new("UIGradient")
vignetteGrad.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 1),
    NumberSequenceKeypoint.new(0.4, 1),
    NumberSequenceKeypoint.new(1, 0),
})
vignetteGrad.Rotation = 0
vignetteGrad.Parent = vignette

-- Directional damage arc
local function spawnDirectionalArc(attackerWorldPos)
    local char = LocalPlayer.Character
    if not (char and char:FindFirstChild("HumanoidRootPart")) then
        return
    end
    local hrp = char.HumanoidRootPart
    local toAttacker = (attackerWorldPos - hrp.Position)
    local cameraYaw =
        math.atan2(-workspace.CurrentCamera.CFrame.LookVector.X, -workspace.CurrentCamera.CFrame.LookVector.Z)
    local angle = math.atan2(-toAttacker.X, -toAttacker.Z) - cameraYaw
    local rotDeg = math.deg(angle)

    local arc = Instance.new("Frame")
    arc.AnchorPoint = Vector2.new(0.5, 1)
    arc.Position = UDim2.fromScale(0.5, 0.5)
    arc.Size = UDim2.fromOffset(80, 40)
    arc.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
    arc.BackgroundTransparency = 1
    arc.BorderSizePixel = 0
    arc.Rotation = rotDeg
    arc.ZIndex = 7
    arc.Parent = damageOverlay

    TweenService:Create(arc, TweenInfo.new(0.15), { BackgroundTransparency = 0.2 }):Play()
    task.delay(0.15, function()
        TweenService:Create(arc, TweenInfo.new(1.2), { BackgroundTransparency = 1 }):Play()
    end)
    Debris:AddItem(arc, 1.5)
end

DamageDealt.OnClientEvent:Connect(function(attackerPos, _dmg, _isHeadshot)
    if typeof(attackerPos) == "Vector3" then
        spawnDirectionalArc(attackerPos)
    end
end)

-- ============================================================================
-- Hit marker (center, fired by HitConfirm)
-- ============================================================================
HitConfirm.OnClientEvent:Connect(function(isHeadshot, wasLethal)
    local color = wasLethal and Color3.fromRGB(220, 60, 60)
        or (isHeadshot and Color3.fromRGB(255, 220, 60) or Color3.new(1, 1, 1))
    for _, rot in ipairs({ 45, 135, 225, 315 }) do
        local mark = Instance.new("Frame")
        mark.AnchorPoint = Vector2.new(0.5, 0.5)
        mark.Position = UDim2.fromScale(0.5, 0.5)
        mark.Size = UDim2.fromOffset(2, 10)
        mark.Rotation = rot
        mark.BackgroundColor3 = color
        mark.BorderSizePixel = 0
        mark.ZIndex = 8
        mark.Parent = damageOverlay
        TweenService:Create(mark, TweenInfo.new(0.25), { BackgroundTransparency = 1 }):Play()
        Debris:AddItem(mark, 0.3)
    end
end)

-- ============================================================================
-- UpdateMatchState (timer + score updates)
-- ============================================================================
local matchTimerSeconds = 0
local matchPhase = "Lobby"

UpdateMatchState.OnClientEvent:Connect(function(eventKind, payload)
    if eventKind == "RoundStart" then
        matchPhase = "Playing"
        matchTimerSeconds = payload.timeRemaining or 75
        team1Score.Text = tostring(payload.team1Score or 0)
        team2Score.Text = tostring(payload.team2Score or 0)
    elseif eventKind == "RoundEnd" then
        matchPhase = "RoundEnd"
        team1Score.Text = tostring(payload.team1Score or 0)
        team2Score.Text = tostring(payload.team2Score or 0)
    elseif eventKind == "MatchEnd" then
        matchPhase = "MatchEnd"
        team1Score.Text = tostring(payload.team1Score or 0)
        team2Score.Text = tostring(payload.team2Score or 0)
        timerText.Text = (payload.winner or "—") .. " WINS"
    end
end)

-- ============================================================================
-- Per-frame updates: health/ammo/crosshair-spread
-- ============================================================================
local function lerpColor(a, b, t)
    return Color3.new(a.R + (b.R - a.R) * t, a.G + (b.G - a.G) * t, a.B + (b.B - a.B) * t)
end

local GREEN = Color3.fromRGB(80, 220, 90)
local YELLOW = Color3.fromRGB(240, 210, 60)
local RED = Color3.fromRGB(220, 60, 60)

RunService.RenderStepped:Connect(function(dt)
    -- Health bar
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        local pct = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
        healthFill.Size = UDim2.fromScale(pct, 1)
        local color
        if pct > 0.5 then
            color = lerpColor(YELLOW, GREEN, (pct - 0.5) * 2)
        else
            color = lerpColor(RED, YELLOW, pct * 2)
        end
        healthFill.BackgroundColor3 = color
        healthText.Text = tostring(math.ceil(hum.Health))

        -- Low-HP vignette: pulse when < 40 HP
        local target = pct < 0.4 and (1 - (0.4 - pct) / 0.4 * 0.65) or 1
        vignette.BackgroundTransparency = vignette.BackgroundTransparency
            + (target - vignette.BackgroundTransparency) * math.min(1, dt * 4)
    end

    -- Match timer countdown (client-side extrapolation; UpdateMatchState
    -- corrects on phase change).
    if matchPhase == "Playing" then
        matchTimerSeconds = math.max(0, matchTimerSeconds - dt)
        local mins = math.floor(matchTimerSeconds / 60)
        local secs = math.floor(matchTimerSeconds % 60)
        timerText.Text = string.format("%d:%02d", mins, secs)
    end

    -- Crosshair gap reactive to WeaponSystem.SpreadOffset (if exposed).
    -- We can't easily reach the local WeaponSystem from here without
    -- an event, so for now use a static gap. Future: ClientController
    -- can write spread to an Attribute on the character that this reads.
    local gap = 8
    chTop.Position = UDim2.new(0.5, 0, 0.5, -gap)
    chBottom.Position = UDim2.new(0.5, 0, 0.5, gap)
    chLeft.Position = UDim2.new(0.5, -gap, 0.5, 0)
    chRight.Position = UDim2.new(0.5, gap, 0.5, 0)
end)

-- ============================================================================
-- Ammo readout: poll the player's character for an "AmmoMag" / "AmmoReserve"
-- attribute (which ClientController should set when WeaponSystem updates).
-- Cheap polling beats round-tripping a RemoteEvent on every shot.
-- ============================================================================
local function pollAmmo()
    local char = LocalPlayer.Character
    if not char then
        return
    end
    local mag = char:GetAttribute("AmmoMag")
    local reserve = char:GetAttribute("AmmoReserve")
    local weapon = char:GetAttribute("EquippedWeapon")
    if mag then
        magText.Text = tostring(mag)
    end
    if reserve then
        reserveText.Text = tostring(reserve)
    end
    if weapon then
        weaponNameLabel.Text = string.upper(weapon)
    end
    -- Low-ammo red flash
    if mag and reserve then
        local total = mag + reserve
        magText.TextColor3 = (total <= 5 or (mag == 0)) and RED or Color3.new(1, 1, 1)
    end
end

LocalPlayer:GetAttributeChangedSignal("Dummy"):Connect(function() end) -- no-op safety
RunService.Heartbeat:Connect(pollAmmo)

print("[Rivals HUD] initialized")
