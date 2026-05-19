--[[
    RIVALS - 3D Loading Screen
    Type: LocalScript
    Location: StarterPlayerScripts (or StarterGui)

    Creates a 3D animated loading screen with spinning weapon models,
    a progress bar, and the RIVALS logo.
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ============== CREATE LOADING GUI ==============
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "RivalsLoadingScreen"
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 100
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- Background
local background = Instance.new("Frame")
background.Name = "Background"
background.Size = UDim2.new(1, 0, 1, 0)
background.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
background.BorderSizePixel = 0
background.Parent = screenGui

-- Gradient overlay
local gradient = Instance.new("UIGradient")
gradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(15, 5, 30)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(10, 10, 15)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(5, 15, 30))
})
gradient.Rotation = 45
gradient.Parent = background

-- Animated particles (floating dots)
local particleHolder = Instance.new("Frame")
particleHolder.Name = "Particles"
particleHolder.Size = UDim2.new(1, 0, 1, 0)
particleHolder.BackgroundTransparency = 1
particleHolder.Parent = background

for i = 1, 30 do
    local particle = Instance.new("Frame")
    particle.Name = "Particle_" .. i
    particle.Size = UDim2.new(0, math.random(2, 6), 0, math.random(2, 6))
    particle.Position = UDim2.new(math.random() * 0.9 + 0.05, 0, math.random() * 0.9 + 0.05, 0)
    particle.BackgroundColor3 = Color3.fromRGB(
        math.random(80, 150),
        math.random(80, 150),
        math.random(200, 255)
    )
    particle.BackgroundTransparency = math.random() * 0.5 + 0.3
    particle.BorderSizePixel = 0
    particle.Parent = particleHolder

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = particle

    -- Float animation
    local startY = particle.Position.Y.Scale
    local tween = TweenService:Create(particle, TweenInfo.new(
        math.random(3, 7),
        Enum.EasingStyle.Sine,
        Enum.EasingDirection.InOut,
        -1, true
    ), {
        Position = UDim2.new(
            particle.Position.X.Scale + (math.random() - 0.5) * 0.1,
            0,
            startY + (math.random() - 0.5) * 0.15,
            0
        )
    })
    tween:Play()
end

-- ============== 3D VIEWPORT (Spinning Weapon) ==============
local viewportFrame = Instance.new("ViewportFrame")
viewportFrame.Name = "WeaponViewport"
viewportFrame.Size = UDim2.new(0.4, 0, 0.5, 0)
viewportFrame.Position = UDim2.new(0.3, 0, 0.1, 0)
viewportFrame.BackgroundTransparency = 1
viewportFrame.Parent = background

-- Create a 3D weapon model to spin in the viewport
local weaponModel = Instance.new("Model")
weaponModel.Name = "DisplayWeapon"

-- Build a stylized rifle shape from parts
local barrel = Instance.new("Part")
barrel.Name = "Barrel"
barrel.Size = Vector3.new(0.3, 0.3, 4)
barrel.Color = Color3.fromRGB(80, 80, 90)
barrel.Material = Enum.Material.Metal
barrel.Anchored = true
barrel.CanCollide = false
barrel.CFrame = CFrame.new(0, 0, 0)
barrel.Parent = weaponModel

local body = Instance.new("Part")
body.Name = "Body"
body.Size = Vector3.new(0.5, 0.7, 2.5)
body.Color = Color3.fromRGB(99, 102, 241) -- Indigo like AssaultRifle
body.Material = Enum.Material.SmoothPlastic
body.Anchored = true
body.CanCollide = false
body.CFrame = CFrame.new(0, -0.2, -1.5)
body.Parent = weaponModel

local stock = Instance.new("Part")
stock.Name = "Stock"
stock.Size = Vector3.new(0.4, 0.6, 1.2)
stock.Color = Color3.fromRGB(60, 60, 70)
stock.Material = Enum.Material.Metal
stock.Anchored = true
stock.CanCollide = false
stock.CFrame = CFrame.new(0, -0.1, -3.2)
stock.Parent = weaponModel

local grip = Instance.new("Part")
grip.Name = "Grip"
grip.Size = Vector3.new(0.3, 0.8, 0.4)
grip.Color = Color3.fromRGB(50, 50, 60)
grip.Material = Enum.Material.SmoothPlastic
grip.Anchored = true
grip.CanCollide = false
grip.CFrame = CFrame.new(0, -0.8, -1.8)
grip.Parent = weaponModel

local scope = Instance.new("Part")
scope.Name = "Scope"
scope.Shape = Enum.PartType.Cylinder
scope.Size = Vector3.new(1.2, 0.25, 0.25)
scope.Color = Color3.fromRGB(200, 50, 50)
scope.Material = Enum.Material.Neon
scope.Anchored = true
scope.CanCollide = false
scope.CFrame = CFrame.new(0, 0.4, -0.5) * CFrame.Angles(0, 0, math.rad(90))
scope.Parent = weaponModel

weaponModel.PrimaryPart = body
weaponModel.Parent = viewportFrame

-- Viewport camera
local vpCamera = Instance.new("Camera")
vpCamera.CFrame = CFrame.new(Vector3.new(4, 2, 4), Vector3.new(0, 0, -1))
vpCamera.Parent = viewportFrame
viewportFrame.CurrentCamera = vpCamera

-- ============== LOGO ==============
local logoFrame = Instance.new("Frame")
logoFrame.Name = "LogoFrame"
logoFrame.Size = UDim2.new(0.5, 0, 0.12, 0)
logoFrame.Position = UDim2.new(0.25, 0, 0.58, 0)
logoFrame.BackgroundTransparency = 1
logoFrame.Parent = background

local logoText = Instance.new("TextLabel")
logoText.Name = "Logo"
logoText.Size = UDim2.new(1, 0, 1, 0)
logoText.BackgroundTransparency = 1
logoText.Text = "R I V A L S"
logoText.TextColor3 = Color3.fromRGB(255, 255, 255)
logoText.TextScaled = true
logoText.Font = Enum.Font.GothamBold
logoText.Parent = logoFrame

local logoStroke = Instance.new("UIStroke")
logoStroke.Color = Color3.fromRGB(99, 102, 241)
logoStroke.Thickness = 2
logoStroke.Transparency = 0.3
logoStroke.Parent = logoText

-- Subtitle
local subtitle = Instance.new("TextLabel")
subtitle.Name = "Subtitle"
subtitle.Size = UDim2.new(0.4, 0, 0.04, 0)
subtitle.Position = UDim2.new(0.3, 0, 0.71, 0)
subtitle.BackgroundTransparency = 1
subtitle.Text = "MULTIPLAYER FPS"
subtitle.TextColor3 = Color3.fromRGB(150, 150, 180)
subtitle.TextScaled = true
subtitle.Font = Enum.Font.Gotham
subtitle.Parent = background

-- ============== PROGRESS BAR ==============
local barBg = Instance.new("Frame")
barBg.Name = "ProgressBarBG"
barBg.Size = UDim2.new(0.4, 0, 0.02, 0)
barBg.Position = UDim2.new(0.3, 0, 0.82, 0)
barBg.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
barBg.BorderSizePixel = 0
barBg.Parent = background

local barCorner = Instance.new("UICorner")
barCorner.CornerRadius = UDim.new(1, 0)
barCorner.Parent = barBg

local barFill = Instance.new("Frame")
barFill.Name = "Fill"
barFill.Size = UDim2.new(0, 0, 1, 0)
barFill.BackgroundColor3 = Color3.fromRGB(99, 102, 241)
barFill.BorderSizePixel = 0
barFill.Parent = barBg

local fillCorner = Instance.new("UICorner")
fillCorner.CornerRadius = UDim.new(1, 0)
fillCorner.Parent = barFill

local fillGradient = Instance.new("UIGradient")
fillGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(99, 102, 241)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(168, 85, 247))
})
fillGradient.Parent = barFill

-- Loading text
local loadingText = Instance.new("TextLabel")
loadingText.Name = "LoadingText"
loadingText.Size = UDim2.new(0.4, 0, 0.03, 0)
loadingText.Position = UDim2.new(0.3, 0, 0.85, 0)
loadingText.BackgroundTransparency = 1
loadingText.Text = "Loading assets..."
loadingText.TextColor3 = Color3.fromRGB(120, 120, 150)
loadingText.TextScaled = true
loadingText.Font = Enum.Font.Gotham
loadingText.Parent = background

-- Tip text
local tips = {
    "TIP: Use cover to avoid sniper fire!",
    "TIP: Melee weapons deal extra damage up close.",
    "TIP: The RPG has splash damage - watch your aim!",
    "TIP: Complete tasks to earn keys for new weapons.",
    "TIP: The Katana can reflect projectiles!",
    "TIP: Flashbangs blind enemies temporarily.",
    "TIP: Visit the Shooting Range to test new weapons!",
    "TIP: The Chainsaw has the highest DPS in the game.",
    "TIP: Use Jump Pads to reach high ground.",
    "TIP: The Bow gives you a double jump!"
}

local tipText = Instance.new("TextLabel")
tipText.Name = "Tip"
tipText.Size = UDim2.new(0.6, 0, 0.03, 0)
tipText.Position = UDim2.new(0.2, 0, 0.92, 0)
tipText.BackgroundTransparency = 1
tipText.Text = tips[math.random(1, #tips)]
tipText.TextColor3 = Color3.fromRGB(200, 200, 100)
tipText.TextScaled = true
tipText.Font = Enum.Font.GothamMedium
tipText.Parent = background

-- ============== ANIMATIONS ==============
-- Spin the 3D weapon
local angle = 0
local spinConnection
spinConnection = RunService.RenderStepped:Connect(function(dt)
    angle = angle + dt * 60
    for _, part in ipairs(weaponModel:GetDescendants()) do
        if part:IsA("BasePart") then
            local offset = part.CFrame - weaponModel.PrimaryPart.Position
            part.CFrame = CFrame.new(0, 0, -1) * CFrame.Angles(0, math.rad(angle), math.rad(15)) * offset
        end
    end
    -- Pulse the logo glow
    logoStroke.Transparency = 0.3 + math.sin(tick() * 2) * 0.2
end)

-- Logo fade-in
logoText.TextTransparency = 1
TweenService:Create(logoText, TweenInfo.new(1.5, Enum.EasingStyle.Quad), {
    TextTransparency = 0
}):Play()

-- ============== PROGRESS / PRELOADING ==============
-- Gather assets to preload
local assetsToLoad = {}
for _, desc in ipairs(game:GetDescendants()) do
    if desc:IsA("Sound") or desc:IsA("Decal") or desc:IsA("Texture") or desc:IsA("MeshPart") then
        table.insert(assetsToLoad, desc)
    end
end

local totalAssets = math.max(#assetsToLoad, 1)
local loaded = 0

-- Preload with progress
task.spawn(function()
    for i, asset in ipairs(assetsToLoad) do
        ContentProvider:PreloadAsync({asset})
        loaded = i
        local progress = loaded / totalAssets
        TweenService:Create(barFill, TweenInfo.new(0.2), {
            Size = UDim2.new(progress, 0, 1, 0)
        }):Play()
        loadingText.Text = string.format("Loading assets... %d%%", math.floor(progress * 100))
    end

    -- If no assets, just animate to 100%
    if #assetsToLoad == 0 then
        for i = 1, 20 do
            local progress = i / 20
            TweenService:Create(barFill, TweenInfo.new(0.1), {
                Size = UDim2.new(progress, 0, 1, 0)
            }):Play()
            loadingText.Text = string.format("Loading... %d%%", math.floor(progress * 100))
            task.wait(0.15)
        end
    end

    loadingText.Text = "Ready!"
    task.wait(1)

    -- Fade out
    local fadeOut = TweenService:Create(background, TweenInfo.new(1, Enum.EasingStyle.Quad), {
        BackgroundTransparency = 1
    })

    -- Fade all children
    for _, child in ipairs(background:GetDescendants()) do
        if child:IsA("TextLabel") then
            TweenService:Create(child, TweenInfo.new(1), {TextTransparency = 1}):Play()
        elseif child:IsA("Frame") then
            TweenService:Create(child, TweenInfo.new(1), {BackgroundTransparency = 1}):Play()
        elseif child:IsA("ViewportFrame") then
            TweenService:Create(child, TweenInfo.new(1), {ImageTransparency = 1}):Play()
        end
    end

    fadeOut:Play()
    fadeOut.Completed:Wait()

    spinConnection:Disconnect()
    screenGui:Destroy()
end)
