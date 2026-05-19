--[[
    RIVALS - Weapon Client (FPS System)
    Type: LocalScript
    Location: StarterPlayerScripts

    Handles weapon equipping, shooting, aiming, reloading, and ammo HUD.
    This is the main FPS controller for the client.
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local camera = workspace.CurrentCamera

local WeaponConfig = require(ReplicatedStorage:WaitForChild("WeaponConfig"))
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local DamageEvent = remotes:WaitForChild("DamagePlayer")
local FireWeaponEvent = remotes:WaitForChild("FireWeapon")
local MeleeAttackEvent = remotes:WaitForChild("MeleeAttack")
local EquipWeaponEvent = remotes:WaitForChild("EquipWeapon")
local GetPlayerDataFunc = remotes:WaitForChild("GetPlayerData")

-- ============== STATE ==============
local currentWeapon = nil -- weapon key string
local currentSlot = "primary"
local ammo = 0
local maxAmmo = 0
local isReloading = false
local isFiring = false
local lastFireTick = 0
local isAiming = false

-- ============== WEAPON HUD ==============
local playerGui = player:WaitForChild("PlayerGui")

local weaponGui = Instance.new("ScreenGui")
weaponGui.Name = "WeaponHUD"
weaponGui.ResetOnSpawn = false
weaponGui.Parent = playerGui

-- Crosshair
local crosshair = Instance.new("Frame")
crosshair.Name = "Crosshair"
crosshair.Size = UDim2.new(0, 2, 0, 20)
crosshair.Position = UDim2.new(0.5, -1, 0.5, -10)
crosshair.BackgroundColor3 = Color3.new(1, 1, 1)
crosshair.BorderSizePixel = 0
crosshair.Parent = weaponGui

local crosshairH = crosshair:Clone()
crosshairH.Size = UDim2.new(0, 20, 0, 2)
crosshairH.Position = UDim2.new(0.5, -10, 0.5, -1)
crosshairH.Parent = weaponGui

-- Ammo display
local ammoFrame = Instance.new("Frame")
ammoFrame.Name = "AmmoFrame"
ammoFrame.Size = UDim2.new(0, 200, 0, 60)
ammoFrame.Position = UDim2.new(1, -220, 1, -80)
ammoFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
ammoFrame.BackgroundTransparency = 0.3
ammoFrame.BorderSizePixel = 0
ammoFrame.Parent = weaponGui

local ammoCorner = Instance.new("UICorner")
ammoCorner.CornerRadius = UDim.new(0, 8)
ammoCorner.Parent = ammoFrame

local weaponLabel = Instance.new("TextLabel")
weaponLabel.Name = "WeaponName"
weaponLabel.Size = UDim2.new(1, -10, 0, 25)
weaponLabel.Position = UDim2.new(0, 10, 0, 5)
weaponLabel.BackgroundTransparency = 1
weaponLabel.Text = "No Weapon"
weaponLabel.TextColor3 = Color3.fromRGB(99, 102, 241)
weaponLabel.TextXAlignment = Enum.TextXAlignment.Left
weaponLabel.TextScaled = true
weaponLabel.Font = Enum.Font.GothamBold
weaponLabel.Parent = ammoFrame

local ammoLabel = Instance.new("TextLabel")
ammoLabel.Name = "AmmoCount"
ammoLabel.Size = UDim2.new(1, -10, 0, 25)
ammoLabel.Position = UDim2.new(0, 10, 0, 30)
ammoLabel.BackgroundTransparency = 1
ammoLabel.Text = "-- / --"
ammoLabel.TextColor3 = Color3.new(1, 1, 1)
ammoLabel.TextXAlignment = Enum.TextXAlignment.Left
ammoLabel.TextScaled = true
ammoLabel.Font = Enum.Font.GothamMedium
ammoLabel.Parent = ammoFrame

-- Weapon slot indicators (1, 2, 3, 4)
local slotFrame = Instance.new("Frame")
slotFrame.Name = "SlotFrame"
slotFrame.Size = UDim2.new(0, 300, 0, 40)
slotFrame.Position = UDim2.new(0.5, -150, 1, -50)
slotFrame.BackgroundTransparency = 1
slotFrame.Parent = weaponGui

local slotLayout = Instance.new("UIListLayout")
slotLayout.FillDirection = Enum.FillDirection.Horizontal
slotLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
slotLayout.Padding = UDim.new(0, 8)
slotLayout.Parent = slotFrame

local slotNames = {"primary", "secondary", "melee", "utility"}
local slotLabels = {"1", "2", "3", "4"}
local slotButtons = {}

for i, slotName in ipairs(slotNames) do
    local btn = Instance.new("TextButton")
    btn.Name = slotName
    btn.Size = UDim2.new(0, 65, 0, 35)
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
    btn.BackgroundTransparency = 0.3
    btn.Text = slotLabels[i] .. " " .. slotName:sub(1, 4):upper()
    btn.TextColor3 = Color3.fromRGB(150, 150, 170)
    btn.TextScaled = true
    btn.Font = Enum.Font.GothamBold
    btn.BorderSizePixel = 0
    btn.Parent = slotFrame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn

    slotButtons[slotName] = btn
end

-- Kill feed
local killFeedFrame = Instance.new("Frame")
killFeedFrame.Name = "KillFeed"
killFeedFrame.Size = UDim2.new(0, 350, 0, 150)
killFeedFrame.Position = UDim2.new(1, -370, 0, 10)
killFeedFrame.BackgroundTransparency = 1
killFeedFrame.Parent = weaponGui

local killFeedLayout = Instance.new("UIListLayout")
killFeedLayout.SortOrder = Enum.SortOrder.LayoutOrder
killFeedLayout.VerticalAlignment = Enum.VerticalAlignment.Top
killFeedLayout.Padding = UDim.new(0, 2)
killFeedLayout.Parent = killFeedFrame

-- ============== WEAPON FUNCTIONS ==============
local function equipWeapon(slotName)
    local pData = GetPlayerDataFunc:InvokeServer()
    if not pData then return end

    local weaponKey = pData.loadout[slotName]
    if not weaponKey then return end

    local weapon = WeaponConfig.Weapons[weaponKey]
    if not weapon then return end

    currentWeapon = weaponKey
    currentSlot = slotName
    isReloading = false

    if weapon.maxAmmo then
        ammo = weapon.maxAmmo
        maxAmmo = weapon.maxAmmo
    else
        ammo = 0
        maxAmmo = 0
    end

    -- Update HUD
    weaponLabel.Text = weapon.name
    weaponLabel.TextColor3 = weapon.color

    if weapon.type == "melee" then
        ammoLabel.Text = "MELEE"
    else
        ammoLabel.Text = ammo .. " / " .. maxAmmo
    end

    -- Highlight active slot
    for name, btn in pairs(slotButtons) do
        if name == slotName then
            btn.BackgroundColor3 = Color3.fromRGB(99, 102, 241)
            btn.TextColor3 = Color3.new(1, 1, 1)
        else
            btn.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
            btn.TextColor3 = Color3.fromRGB(150, 150, 170)
        end
    end

    EquipWeaponEvent:FireServer(weaponKey)
end

local function reload()
    if isReloading then return end
    local weapon = WeaponConfig.Weapons[currentWeapon]
    if not weapon or not weapon.maxAmmo then return end
    if ammo >= weapon.maxAmmo then return end

    isReloading = true
    ammoLabel.Text = "RELOADING..."

    task.wait(1.5) -- Reload time

    ammo = weapon.maxAmmo
    ammoLabel.Text = ammo .. " / " .. maxAmmo
    isReloading = false
end

local function fireWeapon()
    if isReloading then return end
    if not currentWeapon then return end

    local weapon = WeaponConfig.Weapons[currentWeapon]
    if not weapon then return end

    -- Fire rate check
    local now = tick()
    if now - lastFireTick < (weapon.fireRate or 0.1) then return end
    lastFireTick = now

    -- Melee
    if weapon.type == "melee" then
        -- Raycast for melee
        local origin = camera.CFrame.Position
        local direction = camera.CFrame.LookVector * (weapon.range or 8)
        local rayParams = RaycastParams.new()
        rayParams.FilterDescendantsInstances = {player.Character}
        rayParams.FilterType = Enum.RaycastFilterType.Exclude

        local result = workspace:Raycast(origin, direction, rayParams)
        if result and result.Instance then
            local hitChar = result.Instance:FindFirstAncestorOfClass("Model")
            if hitChar then
                local hitPlayer = Players:GetPlayerFromCharacter(hitChar)
                if hitPlayer and hitPlayer ~= player then
                    MeleeAttackEvent:FireServer(hitPlayer, currentWeapon)
                end
            end
        end
        return
    end

    -- Ammo check
    if ammo <= 0 then
        reload()
        return
    end

    ammo = ammo - 1
    ammoLabel.Text = ammo .. " / " .. maxAmmo

    -- Raycast for ranged weapons
    local origin = camera.CFrame.Position
    local spread = weapon.spread or 0
    local pellets = weapon.pellets or 1

    for p = 1, pellets do
        local spreadOffset = Vector3.new(
            (math.random() - 0.5) * spread * 2,
            (math.random() - 0.5) * spread * 2,
            0
        )
        local direction = (camera.CFrame.LookVector + spreadOffset).Unit * 500

        local rayParams = RaycastParams.new()
        rayParams.FilterDescendantsInstances = {player.Character}
        rayParams.FilterType = Enum.RaycastFilterType.Exclude

        local result = workspace:Raycast(origin, direction, rayParams)
        if result then
            -- Visual bullet tracer
            local tracer = Instance.new("Part")
            tracer.Size = Vector3.new(0.1, 0.1, (result.Position - origin).Magnitude)
            tracer.CFrame = CFrame.lookAt(origin, result.Position) * CFrame.new(0, 0, -tracer.Size.Z / 2)
            tracer.Anchored = true
            tracer.CanCollide = false
            tracer.Color = weapon.color
            tracer.Material = Enum.Material.Neon
            tracer.Transparency = 0.5
            tracer.Parent = workspace

            task.delay(0.05, function()
                tracer:Destroy()
            end)

            -- Hit detection
            if result.Instance then
                local hitChar = result.Instance:FindFirstAncestorOfClass("Model")
                if hitChar then
                    local hitPlayer = Players:GetPlayerFromCharacter(hitChar)
                    if hitPlayer and hitPlayer ~= player then
                        DamageEvent:FireServer(hitPlayer, currentWeapon, result.Instance)
                    end
                end

                -- Hit marker effect
                local hitMarker = Instance.new("Part")
                hitMarker.Size = Vector3.new(0.3, 0.3, 0.3)
                hitMarker.Position = result.Position
                hitMarker.Anchored = true
                hitMarker.CanCollide = false
                hitMarker.Shape = Enum.PartType.Ball
                hitMarker.Color = Color3.new(1, 1, 0)
                hitMarker.Material = Enum.Material.Neon
                hitMarker.Parent = workspace
                task.delay(0.2, function() hitMarker:Destroy() end)
            end
        end
    end

    -- Camera recoil
    local recoil = (weapon.damage or 10) * 0.02
    camera.CFrame = camera.CFrame * CFrame.Angles(math.rad(-recoil), 0, 0)

    FireWeaponEvent:FireServer(currentWeapon)
end

-- ============== INPUT HANDLING ==============
-- Number keys to switch weapons
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end

    if input.KeyCode == Enum.KeyCode.One then
        equipWeapon("primary")
    elseif input.KeyCode == Enum.KeyCode.Two then
        equipWeapon("secondary")
    elseif input.KeyCode == Enum.KeyCode.Three then
        equipWeapon("melee")
    elseif input.KeyCode == Enum.KeyCode.Four then
        equipWeapon("utility")
    elseif input.KeyCode == Enum.KeyCode.R then
        reload()
    end
end)

-- Mouse click to fire
mouse.Button1Down:Connect(function()
    isFiring = true
end)

mouse.Button1Up:Connect(function()
    isFiring = false
end)

-- Right click to aim (zoom)
mouse.Button2Down:Connect(function()
    if currentWeapon then
        local weapon = WeaponConfig.Weapons[currentWeapon]
        if weapon and weapon.scope then
            isAiming = true
            TweenService:Create(camera, TweenInfo.new(0.2), {FieldOfView = 30}):Play()
        end
    end
end)

mouse.Button2Up:Connect(function()
    isAiming = false
    TweenService:Create(camera, TweenInfo.new(0.2), {FieldOfView = 70}):Play()
end)

-- Auto-fire loop for automatic weapons
RunService.Heartbeat:Connect(function()
    if isFiring and currentWeapon then
        local weapon = WeaponConfig.Weapons[currentWeapon]
        if weapon and weapon.auto then
            fireWeapon()
        end
    end
end)

-- Single fire on click for non-auto weapons
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        if currentWeapon then
            local weapon = WeaponConfig.Weapons[currentWeapon]
            if weapon and not weapon.auto then
                fireWeapon()
            end
        end
    end
end)

-- ============== KILL FEED ==============
local KillFeedEvent = remotes:WaitForChild("KillFeed")
KillFeedEvent.OnClientEvent:Connect(function(killerName, victimName, weaponName, isHeadshot)
    local entry = Instance.new("TextLabel")
    entry.Size = UDim2.new(1, 0, 0, 20)
    entry.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    entry.BackgroundTransparency = 0.5
    entry.BorderSizePixel = 0
    entry.Font = Enum.Font.GothamMedium
    entry.TextScaled = true
    entry.TextColor3 = Color3.new(1, 1, 1)

    local hsText = isHeadshot and " [HEADSHOT]" or ""
    entry.Text = " " .. killerName .. " [" .. weaponName .. "] " .. victimName .. hsText

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = entry

    entry.Parent = killFeedFrame

    -- Remove after 5 seconds
    task.delay(5, function()
        if entry then entry:Destroy() end
    end)

    -- Keep only 5 entries
    local children = killFeedFrame:GetChildren()
    local labels = {}
    for _, child in ipairs(children) do
        if child:IsA("TextLabel") then table.insert(labels, child) end
    end
    while #labels > 5 do
        labels[1]:Destroy()
        table.remove(labels, 1)
    end
end)

-- ============== XP NOTIFICATIONS ==============
local XPEvent = remotes:WaitForChild("XPGained")
XPEvent.OnClientEvent:Connect(function(amount, totalXP)
    local notif = Instance.new("TextLabel")
    notif.Size = UDim2.new(0, 200, 0, 30)
    notif.Position = UDim2.new(0.5, -100, 0.4, 0)
    notif.BackgroundTransparency = 1
    notif.Text = "+" .. amount .. " XP"
    notif.TextColor3 = Color3.fromRGB(255, 215, 0)
    notif.TextScaled = true
    notif.Font = Enum.Font.GothamBold
    notif.Parent = weaponGui

    TweenService:Create(notif, TweenInfo.new(1.5), {
        Position = UDim2.new(0.5, -100, 0.35, 0),
        TextTransparency = 1
    }):Play()

    task.delay(1.5, function() notif:Destroy() end)
end)

local LevelUpEvent = remotes:WaitForChild("LevelUp")
LevelUpEvent.OnClientEvent:Connect(function(newLevel, keys)
    local notif = Instance.new("TextLabel")
    notif.Size = UDim2.new(0, 400, 0, 50)
    notif.Position = UDim2.new(0.5, -200, 0.3, 0)
    notif.BackgroundTransparency = 1
    notif.Text = "LEVEL UP! Level " .. newLevel .. " (+5 Keys)"
    notif.TextColor3 = Color3.fromRGB(99, 102, 241)
    notif.TextScaled = true
    notif.Font = Enum.Font.GothamBold
    notif.Parent = weaponGui

    TweenService:Create(notif, TweenInfo.new(3), {
        TextTransparency = 1
    }):Play()

    task.delay(3, function() notif:Destroy() end)
end)

-- ============== EQUIP DEFAULT ON SPAWN ==============
player.CharacterAdded:Connect(function()
    task.wait(0.5)
    equipWeapon("primary")
end)

-- Initial equip
task.spawn(function()
    player.CharacterAdded:Wait()
    task.wait(1)
    equipWeapon("primary")
end)

print("[RIVALS] Weapon Client loaded!")
