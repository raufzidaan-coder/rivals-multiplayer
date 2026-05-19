--[[
    RIVALS CLONE - SETTINGS & UI SYSTEM
    LocalScript for player settings
]]

local Settings = {}
Settings.__index = Settings

function Settings.new()
    local self = setmetatable({}, Settings)
    self.Data = {}
    self:LoadDefaults()
    return self
end

function Settings:LoadDefaults()
    self.Data = {
        PC = {
            MouseSensitivity = 1.0,
            MouseSensitivityY = 1.0,
            RawInput = true,
            FOV = 70,
            ADSMultiplier = 0.7,
            InvertY = false,
            Keybinds = {
                Forward = Enum.KeyCode.W,
                Backward = Enum.KeyCode.S,
                Left = Enum.KeyCode.A,
                Right = Enum.KeyCode.D,
                Jump = Enum.KeyCode.Space,
                Sprint = Enum.KeyCode.LeftShift,
                Slide = Enum.KeyCode.LeftControl,
                ADS = Enum.UserInputType.MouseButton2,
                Fire = Enum.UserInputType.MouseButton1,
                Reload = Enum.KeyCode.R,
                Weapon1 = Enum.KeyCode.One,
                Weapon2 = Enum.KeyCode.Two,
                Utility = Enum.KeyCode.G,
                QuickMelee = Enum.KeyCode.F,
            },
            Crosshair = {
                Size = 1.0,
                Color = Color3.new(1, 1, 1),
                Opacity = 1.0,
                Gap = 2,
                Dynamic = true,
                ShowRecoil = true,
            },
        },
        Mobile = {
            TouchSensitivity = 1.0,
            AimAssistStrength = 0.5,
            AutoShoot = "Dynamic",
            ButtonScale = 1.0,
            HUDScale = 1.0,
        },
        Console = {
            ControllerSensitivity = 1.0,
            AimAssistStrength = 0.5,
            Deadzone = 0.1,
            VibrationIntensity = 1.0,
        },
        Graphics = {
            QualityLevel = 5,
            Shadows = true,
            Particles = true,
            PostProcessing = true,
        },
        Audio = {
            MasterVolume = 1.0,
            MusicVolume = 0.5,
            SFXVolume = 1.0,
            VoiceVolume = 1.0,
        },
        Gameplay = {
            ShowDamageNumbers = true,
            ShowHitMarkers = true,
            KillFeedDuration = 5,
            KillCamEnabled = true,
            TutorialEnabled = true,
        },
    }
end

function Settings:GetPC()
    return self.Data.PC
end

function Settings:GetMobile()
    return self.Data.Mobile
end

function Settings:GetConsole()
    return self.Data.Console
end

function Settings:SetMouseSensitivity(X, Y)
    self.Data.PC.MouseSensitivity = X
    self.Data.PC.MouseSensitivityY = Y or X
end

function Settings:SetFOV(FOV)
    self.Data.PC.FOV = math.clamp(FOV, 60, 120)
end

function Settings:SetCrosshairSize(Size)
    self.Data.PC.Crosshair.Size = math.clamp(Size, 0.5, 3.0)
end

function Settings:SetCrosshairColor(Color)
    self.Data.PC.Crosshair.Color = Color
end

function Settings:SetAimAssist(Strength, Platform)
    if Platform == "Mobile" then
        self.Data.Mobile.AimAssistStrength = math.clamp(Strength, 0, 1)
    elseif Platform == "Console" then
        self.Data.Console.AimAssistStrength = math.clamp(Strength, 0, 1)
    end
end

function Settings:BindKey(Action, KeyCode)
    if self.Data.PC.Keybinds[Action] then
        self.Data.PC.Keybinds[Action] = KeyCode
    end
end

function Settings:ResetToDefaults()
    self:LoadDefaults()
end

-- Settings UI Creator
local SettingsUI = {}
SettingsUI.__index = SettingsUI

function SettingsUI.new(Player)
    local self = setmetatable({}, SettingsUI)
    self.Player = Player
    self.Settings = Settings.new()
    return self
end

function SettingsUI:CreateMenu()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "SettingsMenu"
    ScreenGui.Parent = self.Player:FindFirstChild("PlayerGui")

    local MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.fromScale(0.8, 0.8)
    MainFrame.Position = UDim2.fromScale(0.1, 0.1)
    MainFrame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
    MainFrame.BorderSizePixel = 0
    MainFrame.Parent = ScreenGui

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, 0, 0, 50)
    Title.BackgroundColor3 = Color3.new(0.15, 0.15, 0.15)
    Title.BorderSizePixel = 0
    Title.Text = "SETTINGS"
    Title.TextColor3 = Color3.new(1, 1, 1)
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 32
    Title.Parent = MainFrame

    local Tabs = { "General", "Controls", "Graphics", "Audio" }
    local _TabButtons = {} -- placeholder for future tab-switching wire-up

    for i, TabName in ipairs(Tabs) do
        local TabButton = Instance.new("TextButton")
        TabButton.Size = UDim2.new(0.25, -4, 0, 40)
        TabButton.Position = UDim2.new((i - 1) * 0.25, 4, 0, 50)
        TabButton.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
        TabButton.BorderSizePixel = 0
        TabButton.Text = TabName
        TabButton.TextColor3 = Color3.new(0.8, 0.8, 0.8)
        TabButton.Font = Enum.Font.Gotham
        TabButton.TextSize = 16
        TabButton.Parent = MainFrame

        table.insert(_TabButtons, TabButton)
    end

    local ContentFrame = Instance.new("ScrollingFrame")
    ContentFrame.Size = UDim2.new(1, -20, 1, -100)
    ContentFrame.Position = UDim2.fromOffset(10, 90)
    ContentFrame.BackgroundTransparency = 1
    ContentFrame.ScrollBarThickness = 6
    ContentFrame.Parent = MainFrame

    local CloseButton = Instance.new("TextButton")
    CloseButton.Size = UDim2.fromOffset(40, 40)
    CloseButton.Position = UDim2.new(1, -50, 0, 5)
    CloseButton.BackgroundColor3 = Color3.new(0.8, 0.2, 0.2)
    CloseButton.BorderSizePixel = 0
    CloseButton.Text = "X"
    CloseButton.TextColor3 = Color3.new(1, 1, 1)
    CloseButton.Font = Enum.Font.GothamBold
    CloseButton.TextSize = 20
    CloseButton.Parent = MainFrame
    CloseButton.MouseButton1Click:Connect(function()
        ScreenGui:Destroy()
    end)

    return ScreenGui, ContentFrame
end

function SettingsUI:CreateSlider(Parent, Label, Min, Max, Value, OnChanged)
    local Container = Instance.new("Frame")
    Container.Size = UDim2.new(1, 0, 0, 40)
    Container.BackgroundTransparency = 1
    Container.Parent = Parent

    local LabelText = Instance.new("TextLabel")
    LabelText.Size = UDim2.new(0.3, 0, 0, 20)
    LabelText.BackgroundTransparency = 1
    LabelText.Text = Label
    LabelText.TextColor3 = Color3.new(0.9, 0.9, 0.9)
    LabelText.TextXAlignment = Enum.TextXAlignment.Left
    LabelText.Font = Enum.Font.Gotham
    LabelText.TextSize = 14
    LabelText.Parent = Container

    local ValueText = Instance.new("TextLabel")
    ValueText.Size = UDim2.new(0.1, 0, 0, 20)
    ValueText.Position = UDim2.fromScale(0.9, 0)
    ValueText.BackgroundTransparency = 1
    ValueText.Text = tostring(Value)
    ValueText.TextColor3 = Color3.new(0.6, 0.6, 0.6)
    ValueText.Font = Enum.Font.Gotham
    ValueText.TextSize = 14
    ValueText.Parent = Container

    local SliderBack = Instance.new("Frame")
    SliderBack.Size = UDim2.new(0.5, 0, 0, 8)
    SliderBack.Position = UDim2.new(0.3, 0, 0, 20)
    SliderBack.BackgroundColor3 = Color3.new(0.3, 0.3, 0.3)
    SliderBack.BorderSizePixel = 0
    SliderBack.Parent = Container

    local SliderFill = Instance.new("Frame")
    SliderFill.Size = UDim2.fromScale((Value - Min) / (Max - Min), 1)
    SliderFill.BackgroundColor3 = Color3.new(0, 0.7, 1)
    SliderFill.BorderSizePixel = 0
    SliderFill.Parent = SliderBack

    local SliderButton = Instance.new("TextButton")
    SliderButton.Size = UDim2.fromOffset(16, 16)
    SliderButton.Position = UDim2.new((Value - Min) / (Max - Min), -8, 0.5, -8)
    SliderButton.BackgroundColor3 = Color3.new(1, 1, 1)
    SliderButton.BorderSizePixel = 0
    SliderButton.Parent = SliderBack

    local IsDragging = false

    SliderButton.MouseButton1Down:Connect(function()
        IsDragging = true
    end)

    SliderButton.MouseButton1Up:Connect(function()
        IsDragging = false
    end)

    game:GetService("RunService").Heartbeat:Connect(function()
        if IsDragging then
            local Mouse = game.Players.LocalPlayer:GetMouse()
            local RelativeX = (Mouse.X - SliderBack.AbsolutePosition.X) / SliderBack.AbsoluteSize.X
            local NewValue = math.clamp(Min + (Max - Min) * RelativeX, Min, Max)
            SliderFill.Size = UDim2.fromScale((NewValue - Min) / (Max - Min), 1)
            SliderButton.Position = UDim2.new((NewValue - Min) / (Max - Min), -8, 0.5, -8)
            ValueText.Text = string.format("%.1f", NewValue)
            if OnChanged then
                OnChanged(NewValue)
            end
        end
    end)

    return Container
end

function SettingsUI:CreateToggle(Parent, Label, Value, OnChanged)
    local Container = Instance.new("Frame")
    Container.Size = UDim2.new(1, 0, 0, 40)
    Container.BackgroundTransparency = 1
    Container.Parent = Parent

    local LabelText = Instance.new("TextLabel")
    LabelText.Size = UDim2.new(0.7, 0, 0, 20)
    LabelText.BackgroundTransparency = 1
    LabelText.Text = Label
    LabelText.TextColor3 = Color3.new(0.9, 0.9, 0.9)
    LabelText.TextXAlignment = Enum.TextXAlignment.Left
    LabelText.Font = Enum.Font.Gotham
    LabelText.TextSize = 14
    LabelText.Parent = Container

    local Toggle = Instance.new("TextButton")
    Toggle.Size = UDim2.fromOffset(50, 26)
    Toggle.Position = UDim2.new(0.8, 0, 0, 7)
    Toggle.BackgroundColor3 = Value and Color3.new(0, 0.7, 0.3) or Color3.new(0.4, 0.4, 0.4)
    Toggle.BorderSizePixel = 0
    Toggle.Text = Value and "ON" or "OFF"
    Toggle.TextColor3 = Color3.new(1, 1, 1)
    Toggle.Font = Enum.Font.GothamBold
    Toggle.TextSize = 12
    Toggle.Parent = Container

    Toggle.MouseButton1Click:Connect(function()
        Value = not Value
        Toggle.BackgroundColor3 = Value and Color3.new(0, 0.7, 0.3) or Color3.new(0.4, 0.4, 0.4)
        Toggle.Text = Value and "ON" or "OFF"
        if OnChanged then
            OnChanged(Value)
        end
    end)

    return Container
end

Settings.UI = SettingsUI

return Settings
