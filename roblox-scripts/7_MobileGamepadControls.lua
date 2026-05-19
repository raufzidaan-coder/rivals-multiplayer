--[[
    RIVALS - Mobile & Gamepad Controls
    Type: LocalScript
    Location: StarterPlayerScripts

    Adds touch-screen controls for mobile/tablet and
    gamepad button mappings for Xbox/PlayStation.
    Auto-detects the device and shows the right controls.
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera = workspace.CurrentCamera

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local WeaponConfig = require(ReplicatedStorage:WaitForChild("WeaponConfig"))
local GetPlayerDataFunc = remotes:WaitForChild("GetPlayerData")
local DamageEvent = remotes:WaitForChild("DamagePlayer")
local MeleeAttackEvent = remotes:WaitForChild("MeleeAttack")
local FireWeaponEvent = remotes:WaitForChild("FireWeapon")
local EquipWeaponEvent = remotes:WaitForChild("EquipWeapon")

-- ============== DEVICE DETECTION ==============
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local isGamepad = UserInputService.GamepadEnabled
local isConsole = GuiService:IsTenFootInterface()

-- ============== SHARED STATE ==============
-- These BindableEvents let us communicate with WeaponClient (5_WeaponClient.lua)
-- We fire weapon actions through the same remotes
local currentWeapon = nil
local currentSlot = "primary"
local ammo = 0
local maxAmmo = 0
local isReloading = false
local isFiring = false
local lastFireTick = 0
local isAiming = false

local function getWeaponData()
    local pData = GetPlayerDataFunc:InvokeServer()
    if pData then
        currentWeapon = pData.loadout[currentSlot]
    end
    if currentWeapon then
        local wep = WeaponConfig.Weapons[currentWeapon]
        if wep and wep.maxAmmo then
            ammo = wep.maxAmmo
            maxAmmo = wep.maxAmmo
        end
    end
end

-- ============== FIRE FUNCTION (shared) ==============
local function doFire()
    if isReloading or not currentWeapon then return end
    local weapon = WeaponConfig.Weapons[currentWeapon]
    if not weapon then return end

    local now = tick()
    if now - lastFireTick < (weapon.fireRate or 0.1) then return end
    lastFireTick = now

    if weapon.type == "melee" then
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

    if ammo <= 0 then return end
    ammo = ammo - 1

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
        if result and result.Instance then
            local hitChar = result.Instance:FindFirstAncestorOfClass("Model")
            if hitChar then
                local hitPlayer = Players:GetPlayerFromCharacter(hitChar)
                if hitPlayer and hitPlayer ~= player then
                    DamageEvent:FireServer(hitPlayer, currentWeapon, result.Instance)
                end
            end
        end
    end

    FireWeaponEvent:FireServer(currentWeapon)
end

local function doReload()
    if isReloading or not currentWeapon then return end
    local weapon = WeaponConfig.Weapons[currentWeapon]
    if not weapon or not weapon.maxAmmo or ammo >= weapon.maxAmmo then return end
    isReloading = true
    task.wait(1.5)
    ammo = weapon.maxAmmo
    maxAmmo = weapon.maxAmmo
    isReloading = false
end

local function doEquip(slot)
    currentSlot = slot
    getWeaponData()
    EquipWeaponEvent:FireServer(currentWeapon)
end

-- ======================================================
--  MOBILE TOUCH CONTROLS
-- ======================================================
if isMobile then
    local touchGui = Instance.new("ScreenGui")
    touchGui.Name = "MobileControls"
    touchGui.ResetOnSpawn = false
    touchGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    touchGui.Parent = playerGui

    -- Helper to make a circular button
    local function makeButton(name, text, size, position, color, parent)
        local btn = Instance.new("TextButton")
        btn.Name = name
        btn.Size = size
        btn.Position = position
        btn.BackgroundColor3 = color
        btn.BackgroundTransparency = 0.3
        btn.Text = text
        btn.TextColor3 = Color3.new(1, 1, 1)
        btn.TextScaled = true
        btn.Font = Enum.Font.GothamBold
        btn.BorderSizePixel = 0
        btn.Parent = parent or touchGui

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0)
        corner.Parent = btn

        local stroke = Instance.new("UIStroke")
        stroke.Color = Color3.new(1, 1, 1)
        stroke.Thickness = 2
        stroke.Transparency = 0.5
        stroke.Parent = btn

        return btn
    end

    -- ===== FIRE BUTTON (right side, large) =====
    local fireBtn = makeButton(
        "FireButton", "",
        UDim2.new(0, 90, 0, 90),
        UDim2.new(1, -120, 1, -180),
        Color3.fromRGB(239, 68, 68)
    )

    -- Fire icon (crosshair inside)
    local fireIcon = Instance.new("TextLabel")
    fireIcon.Size = UDim2.new(0.6, 0, 0.6, 0)
    fireIcon.Position = UDim2.new(0.2, 0, 0.2, 0)
    fireIcon.BackgroundTransparency = 1
    fireIcon.Text = "+"
    fireIcon.TextColor3 = Color3.new(1, 1, 1)
    fireIcon.TextScaled = true
    fireIcon.Font = Enum.Font.GothamBold
    fireIcon.Parent = fireBtn

    local fireHeld = false
    fireBtn.MouseButton1Down:Connect(function()
        fireHeld = true
        isFiring = true
    end)
    fireBtn.MouseButton1Up:Connect(function()
        fireHeld = false
        isFiring = false
    end)
    fireBtn.TouchLongPress:Connect(function()
        fireHeld = true
        isFiring = true
    end)

    -- ===== AIM / SCOPE BUTTON =====
    local aimBtn = makeButton(
        "AimButton", "AIM",
        UDim2.new(0, 65, 0, 65),
        UDim2.new(1, -200, 1, -150),
        Color3.fromRGB(59, 130, 246)
    )

    aimBtn.MouseButton1Down:Connect(function()
        isAiming = true
        if currentWeapon then
            local weapon = WeaponConfig.Weapons[currentWeapon]
            if weapon and weapon.scope then
                TweenService:Create(camera, TweenInfo.new(0.2), {FieldOfView = 30}):Play()
            else
                TweenService:Create(camera, TweenInfo.new(0.2), {FieldOfView = 55}):Play()
            end
        end
    end)
    aimBtn.MouseButton1Up:Connect(function()
        isAiming = false
        TweenService:Create(camera, TweenInfo.new(0.2), {FieldOfView = 70}):Play()
    end)

    -- ===== RELOAD BUTTON =====
    local reloadBtn = makeButton(
        "ReloadButton", "R",
        UDim2.new(0, 55, 0, 55),
        UDim2.new(1, -130, 1, -280),
        Color3.fromRGB(245, 158, 11)
    )

    reloadBtn.MouseButton1Click:Connect(function()
        task.spawn(doReload)
    end)

    -- ===== WEAPON SWITCH BUTTONS (bottom-left) =====
    local slotNames = {"primary", "secondary", "melee", "utility"}
    local slotIcons = {"1", "2", "3", "4"}
    local slotColors = {
        Color3.fromRGB(99, 102, 241),
        Color3.fromRGB(170, 170, 170),
        Color3.fromRGB(34, 197, 94),
        Color3.fromRGB(239, 68, 68)
    }

    for i, slot in ipairs(slotNames) do
        local slotBtn = makeButton(
            slot .. "Btn", slotIcons[i],
            UDim2.new(0, 48, 0, 48),
            UDim2.new(0, 10 + (i - 1) * 55, 1, -70),
            slotColors[i]
        )

        slotBtn.MouseButton1Click:Connect(function()
            doEquip(slot)
            -- Highlight selected
            for j, s in ipairs(slotNames) do
                local b = touchGui:FindFirstChild(s .. "Btn")
                if b then
                    b.BackgroundTransparency = (s == slot) and 0.1 or 0.5
                end
            end
        end)
    end

    -- ===== SHOP BUTTON =====
    local shopBtn = makeButton(
        "ShopButton", "SHOP",
        UDim2.new(0, 60, 0, 40),
        UDim2.new(0, 10, 0, 40),
        Color3.fromRGB(255, 215, 0)
    )
    shopBtn.TextColor3 = Color3.fromRGB(20, 20, 20)

    shopBtn.MouseButton1Click:Connect(function()
        -- Toggle shop GUI
        local shopGui = playerGui:FindFirstChild("WeaponShop")
        if shopGui then
            shopGui.Enabled = not shopGui.Enabled
        end
    end)

    -- ===== JUMP BUTTON =====
    local jumpBtn = makeButton(
        "JumpButton", "^",
        UDim2.new(0, 70, 0, 70),
        UDim2.new(1, -110, 1, -300),
        Color3.fromRGB(52, 211, 153)
    )

    jumpBtn.MouseButton1Down:Connect(function()
        local char = player.Character
        if char then
            local humanoid = char:FindFirstChild("Humanoid")
            if humanoid then
                humanoid.Jump = true
            end
        end
    end)

    -- ===== AMMO DISPLAY (mobile) =====
    local mobileAmmo = Instance.new("TextLabel")
    mobileAmmo.Name = "MobileAmmo"
    mobileAmmo.Size = UDim2.new(0, 120, 0, 30)
    mobileAmmo.Position = UDim2.new(1, -140, 1, -70)
    mobileAmmo.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    mobileAmmo.BackgroundTransparency = 0.4
    mobileAmmo.Text = "-- / --"
    mobileAmmo.TextColor3 = Color3.new(1, 1, 1)
    mobileAmmo.TextScaled = true
    mobileAmmo.Font = Enum.Font.GothamBold
    mobileAmmo.BorderSizePixel = 0
    mobileAmmo.Parent = touchGui

    local ammoCorner = Instance.new("UICorner")
    ammoCorner.CornerRadius = UDim.new(0, 8)
    ammoCorner.Parent = mobileAmmo

    -- Auto-fire loop for mobile
    RunService.Heartbeat:Connect(function()
        if fireHeld and currentWeapon then
            local weapon = WeaponConfig.Weapons[currentWeapon]
            if weapon then
                doFire()
            end
        end

        -- Update mobile ammo display
        if currentWeapon then
            local weapon = WeaponConfig.Weapons[currentWeapon]
            if weapon then
                if weapon.type == "melee" then
                    mobileAmmo.Text = weapon.name
                else
                    mobileAmmo.Text = ammo .. " / " .. maxAmmo
                end
            end
        end
    end)

    print("[RIVALS] Mobile touch controls loaded!")
end

-- ======================================================
--  GAMEPAD / CONTROLLER CONTROLS (Xbox, PlayStation)
-- ======================================================
if isGamepad or isConsole then
    local gamepadGui = Instance.new("ScreenGui")
    gamepadGui.Name = "GamepadHints"
    gamepadGui.ResetOnSpawn = false
    gamepadGui.Parent = playerGui

    -- Button hint display (bottom of screen)
    local hintFrame = Instance.new("Frame")
    hintFrame.Name = "ControlHints"
    hintFrame.Size = UDim2.new(0, 500, 0, 35)
    hintFrame.Position = UDim2.new(0.5, -250, 1, -45)
    hintFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
    hintFrame.BackgroundTransparency = 0.4
    hintFrame.BorderSizePixel = 0
    hintFrame.Parent = gamepadGui

    local hintCorner = Instance.new("UICorner")
    hintCorner.CornerRadius = UDim.new(0, 8)
    hintCorner.Parent = hintFrame

    local hintLabel = Instance.new("TextLabel")
    hintLabel.Size = UDim2.new(1, -10, 1, 0)
    hintLabel.Position = UDim2.new(0, 5, 0, 0)
    hintLabel.BackgroundTransparency = 1
    hintLabel.Text = "RT: Fire | LT: Aim | RB/LB: Switch Weapon | X: Reload | Y: Shop"
    hintLabel.TextColor3 = Color3.fromRGB(180, 180, 200)
    hintLabel.TextScaled = true
    hintLabel.Font = Enum.Font.Gotham
    hintLabel.Parent = hintFrame

    -- Gamepad state
    local gpFiring = false
    local currentSlotIndex = 1
    local slots = {"primary", "secondary", "melee", "utility"}

    -- ===== GAMEPAD INPUT =====
    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end

        -- RT (Right Trigger) = Fire
        if input.KeyCode == Enum.KeyCode.ButtonR2 then
            gpFiring = true
            isFiring = true
            -- Single fire for non-auto weapons
            if currentWeapon then
                local weapon = WeaponConfig.Weapons[currentWeapon]
                if weapon and not weapon.auto then
                    doFire()
                end
            end
        end

        -- LT (Left Trigger) = Aim/Scope
        if input.KeyCode == Enum.KeyCode.ButtonL2 then
            isAiming = true
            if currentWeapon then
                local weapon = WeaponConfig.Weapons[currentWeapon]
                if weapon and weapon.scope then
                    TweenService:Create(camera, TweenInfo.new(0.2), {FieldOfView = 30}):Play()
                else
                    TweenService:Create(camera, TweenInfo.new(0.2), {FieldOfView = 55}):Play()
                end
            end
        end

        -- RB (Right Bumper) = Next weapon
        if input.KeyCode == Enum.KeyCode.ButtonR1 then
            currentSlotIndex = currentSlotIndex % 4 + 1
            doEquip(slots[currentSlotIndex])
        end

        -- LB (Left Bumper) = Previous weapon
        if input.KeyCode == Enum.KeyCode.ButtonL1 then
            currentSlotIndex = (currentSlotIndex - 2) % 4 + 1
            doEquip(slots[currentSlotIndex])
        end

        -- X button = Reload
        if input.KeyCode == Enum.KeyCode.ButtonX then
            task.spawn(doReload)
        end

        -- Y button = Toggle shop
        if input.KeyCode == Enum.KeyCode.ButtonY then
            local shopGui = playerGui:FindFirstChild("WeaponShop")
            if shopGui then
                shopGui.Enabled = not shopGui.Enabled
            end
        end

        -- D-Pad for quick weapon select
        if input.KeyCode == Enum.KeyCode.DPadUp then
            doEquip("primary")
            currentSlotIndex = 1
        elseif input.KeyCode == Enum.KeyCode.DPadRight then
            doEquip("secondary")
            currentSlotIndex = 2
        elseif input.KeyCode == Enum.KeyCode.DPadDown then
            doEquip("melee")
            currentSlotIndex = 3
        elseif input.KeyCode == Enum.KeyCode.DPadLeft then
            doEquip("utility")
            currentSlotIndex = 4
        end
    end)

    UserInputService.InputEnded:Connect(function(input, processed)
        -- Release RT = Stop firing
        if input.KeyCode == Enum.KeyCode.ButtonR2 then
            gpFiring = false
            isFiring = false
        end

        -- Release LT = Stop aiming
        if input.KeyCode == Enum.KeyCode.ButtonL2 then
            isAiming = false
            TweenService:Create(camera, TweenInfo.new(0.2), {FieldOfView = 70}):Play()
        end
    end)

    -- Auto-fire loop for gamepad (automatic weapons)
    RunService.Heartbeat:Connect(function()
        if gpFiring and currentWeapon then
            local weapon = WeaponConfig.Weapons[currentWeapon]
            if weapon and weapon.auto then
                doFire()
            end
        end
    end)

    -- Fade out hints after 10 seconds
    task.delay(10, function()
        TweenService:Create(hintFrame, TweenInfo.new(2), {BackgroundTransparency = 1}):Play()
        TweenService:Create(hintLabel, TweenInfo.new(2), {TextTransparency = 1}):Play()
    end)

    print("[RIVALS] Gamepad controls loaded!")
end

-- ======================================================
--  INITIAL SETUP
-- ======================================================
player.CharacterAdded:Connect(function()
    task.wait(0.5)
    getWeaponData()
end)

task.spawn(function()
    player.CharacterAdded:Wait()
    task.wait(1)
    getWeaponData()
end)

print("[RIVALS] Cross-platform controls initialized! Device: " ..
    (isMobile and "Mobile" or (isConsole and "Console" or (isGamepad and "Gamepad" or "PC"))))
