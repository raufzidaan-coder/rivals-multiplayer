--[[
    RIVALS - Weapon Shop GUI
    Type: LocalScript
    Location: StarterPlayerScripts

    In-game shop for buying weapons with keys.
    Press B to open/close shop.
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local WeaponConfig = require(ReplicatedStorage:WaitForChild("WeaponConfig"))
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local BuyWeaponFunc = remotes:WaitForChild("BuyWeapon")
local GetShopDataFunc = remotes:WaitForChild("GetShopData")
local GetPlayerDataFunc = remotes:WaitForChild("GetPlayerData")
local SetLoadoutFunc = remotes:WaitForChild("SetLoadout")

local shopOpen = false

-- ============== SHOP GUI ==============
local shopGui = Instance.new("ScreenGui")
shopGui.Name = "WeaponShop"
shopGui.ResetOnSpawn = false
shopGui.Enabled = false
shopGui.Parent = playerGui

-- Main frame
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0.7, 0, 0.75, 0)
mainFrame.Position = UDim2.new(0.15, 0, 0.125, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
mainFrame.BackgroundTransparency = 0.05
mainFrame.BorderSizePixel = 0
mainFrame.Parent = shopGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 12)
mainCorner.Parent = mainFrame

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(99, 102, 241)
mainStroke.Thickness = 2
mainStroke.Parent = mainFrame

-- Title bar
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 50)
titleBar.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 12)
titleCorner.Parent = titleBar

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(0.5, 0, 1, 0)
titleLabel.Position = UDim2.new(0, 15, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "WEAPON SHOP"
titleLabel.TextColor3 = Color3.fromRGB(99, 102, 241)
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.TextScaled = true
titleLabel.Font = Enum.Font.GothamBold
titleLabel.Parent = titleBar

local keysLabel = Instance.new("TextLabel")
keysLabel.Name = "KeysLabel"
keysLabel.Size = UDim2.new(0.3, 0, 1, 0)
keysLabel.Position = UDim2.new(0.65, 0, 0, 0)
keysLabel.BackgroundTransparency = 1
keysLabel.Text = "Keys: 0"
keysLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
keysLabel.TextXAlignment = Enum.TextXAlignment.Right
keysLabel.TextScaled = true
keysLabel.Font = Enum.Font.GothamBold
keysLabel.Parent = titleBar

-- Close button
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 40, 0, 40)
closeBtn.Position = UDim2.new(1, -45, 0, 5)
closeBtn.BackgroundColor3 = Color3.fromRGB(239, 68, 68)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.new(1, 1, 1)
closeBtn.TextScaled = true
closeBtn.Font = Enum.Font.GothamBold
closeBtn.BorderSizePixel = 0
closeBtn.Parent = titleBar

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 8)
closeCorner.Parent = closeBtn

-- Category tabs
local tabFrame = Instance.new("Frame")
tabFrame.Size = UDim2.new(1, -20, 0, 35)
tabFrame.Position = UDim2.new(0, 10, 0, 55)
tabFrame.BackgroundTransparency = 1
tabFrame.Parent = mainFrame

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.Padding = UDim.new(0, 5)
tabLayout.Parent = tabFrame

local categories = {"primary", "secondary", "melee", "utility"}
local currentCategory = "primary"
local tabButtons = {}

for _, cat in ipairs(categories) do
    local tab = Instance.new("TextButton")
    tab.Name = cat
    tab.Size = UDim2.new(0, 100, 1, 0)
    tab.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
    tab.Text = cat:upper()
    tab.TextColor3 = Color3.fromRGB(150, 150, 170)
    tab.TextScaled = true
    tab.Font = Enum.Font.GothamBold
    tab.BorderSizePixel = 0
    tab.Parent = tabFrame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = tab

    tabButtons[cat] = tab
end

-- Scrolling weapon list
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Name = "WeaponList"
scrollFrame.Size = UDim2.new(1, -20, 1, -105)
scrollFrame.Position = UDim2.new(0, 10, 0, 95)
scrollFrame.BackgroundTransparency = 1
scrollFrame.ScrollBarThickness = 6
scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(99, 102, 241)
scrollFrame.BorderSizePixel = 0
scrollFrame.Parent = mainFrame

local gridLayout = Instance.new("UIGridLayout")
gridLayout.CellSize = UDim2.new(0, 220, 0, 120)
gridLayout.CellPadding = UDim2.new(0, 10, 0, 10)
gridLayout.SortOrder = Enum.SortOrder.Name
gridLayout.Parent = scrollFrame

-- ============== POPULATE SHOP ==============
local function refreshShop()
    -- Clear existing
    for _, child in ipairs(scrollFrame:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end

    local shopData = GetShopDataFunc:InvokeServer()
    local pData = GetPlayerDataFunc:InvokeServer()
    if not shopData or not pData then return end

    keysLabel.Text = "Keys: " .. (pData.keys or 0)

    -- Highlight active tab
    for cat, btn in pairs(tabButtons) do
        if cat == currentCategory then
            btn.BackgroundColor3 = Color3.fromRGB(99, 102, 241)
            btn.TextColor3 = Color3.new(1, 1, 1)
        else
            btn.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
            btn.TextColor3 = Color3.fromRGB(150, 150, 170)
        end
    end

    for weaponKey, info in pairs(shopData) do
        if info.type == currentCategory then
            local card = Instance.new("Frame")
            card.Name = weaponKey
            card.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
            card.BorderSizePixel = 0
            card.Parent = scrollFrame

            local cardCorner = Instance.new("UICorner")
            cardCorner.CornerRadius = UDim.new(0, 8)
            cardCorner.Parent = card

            -- Weapon color bar
            local weapon = WeaponConfig.Weapons[weaponKey]
            local colorBar = Instance.new("Frame")
            colorBar.Size = UDim2.new(1, 0, 0, 4)
            colorBar.BackgroundColor3 = weapon and weapon.color or Color3.new(1, 1, 1)
            colorBar.BorderSizePixel = 0
            colorBar.Parent = card

            -- Name
            local nameLabel = Instance.new("TextLabel")
            nameLabel.Size = UDim2.new(1, -10, 0, 22)
            nameLabel.Position = UDim2.new(0, 5, 0, 8)
            nameLabel.BackgroundTransparency = 1
            nameLabel.Text = info.name
            nameLabel.TextColor3 = Color3.new(1, 1, 1)
            nameLabel.TextXAlignment = Enum.TextXAlignment.Left
            nameLabel.TextScaled = true
            nameLabel.Font = Enum.Font.GothamBold
            nameLabel.Parent = card

            -- Stats
            local statsLabel = Instance.new("TextLabel")
            statsLabel.Size = UDim2.new(1, -10, 0, 18)
            statsLabel.Position = UDim2.new(0, 5, 0, 32)
            statsLabel.BackgroundTransparency = 1
            statsLabel.Text = "DMG: " .. info.damage .. " | Rate: " .. string.format("%.2f", info.fireRate)
            statsLabel.TextColor3 = Color3.fromRGB(150, 150, 170)
            statsLabel.TextXAlignment = Enum.TextXAlignment.Left
            statsLabel.TextScaled = true
            statsLabel.Font = Enum.Font.Gotham
            statsLabel.Parent = card

            -- Level req
            local levelLabel = Instance.new("TextLabel")
            levelLabel.Size = UDim2.new(1, -10, 0, 16)
            levelLabel.Position = UDim2.new(0, 5, 0, 52)
            levelLabel.BackgroundTransparency = 1
            levelLabel.Text = "Level " .. info.levelReq .. " required"
            levelLabel.TextColor3 = pData.level >= info.levelReq and Color3.fromRGB(34, 197, 94) or Color3.fromRGB(239, 68, 68)
            levelLabel.TextXAlignment = Enum.TextXAlignment.Left
            levelLabel.TextScaled = true
            levelLabel.Font = Enum.Font.Gotham
            levelLabel.Parent = card

            -- Buy / Equip button
            local actionBtn = Instance.new("TextButton")
            actionBtn.Size = UDim2.new(1, -10, 0, 28)
            actionBtn.Position = UDim2.new(0, 5, 1, -33)
            actionBtn.BorderSizePixel = 0
            actionBtn.TextScaled = true
            actionBtn.Font = Enum.Font.GothamBold

            local actionCorner = Instance.new("UICorner")
            actionCorner.CornerRadius = UDim.new(0, 6)
            actionCorner.Parent = actionBtn

            if info.owned then
                local isEquipped = pData.loadout[info.type] == weaponKey
                actionBtn.Text = isEquipped and "EQUIPPED" or "EQUIP"
                actionBtn.BackgroundColor3 = isEquipped and Color3.fromRGB(34, 197, 94) or Color3.fromRGB(59, 130, 246)
                actionBtn.TextColor3 = Color3.new(1, 1, 1)

                if not isEquipped then
                    actionBtn.MouseButton1Click:Connect(function()
                        SetLoadoutFunc:InvokeServer(info.type, weaponKey)
                        refreshShop()
                    end)
                end
            else
                actionBtn.Text = info.price .. " Keys"
                actionBtn.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
                actionBtn.TextColor3 = Color3.fromRGB(20, 20, 20)

                actionBtn.MouseButton1Click:Connect(function()
                    local success, msg = BuyWeaponFunc:InvokeServer(weaponKey)
                    if success then
                        refreshShop()
                    else
                        actionBtn.Text = msg
                        actionBtn.BackgroundColor3 = Color3.fromRGB(239, 68, 68)
                        task.wait(1.5)
                        refreshShop()
                    end
                end)
            end

            actionBtn.Parent = card
        end
    end

    -- Update canvas size
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, gridLayout.AbsoluteContentSize.Y + 20)
end

-- ============== TAB SWITCHING ==============
for cat, btn in pairs(tabButtons) do
    btn.MouseButton1Click:Connect(function()
        currentCategory = cat
        refreshShop()
    end)
end

-- ============== OPEN / CLOSE ==============
local function toggleShop()
    shopOpen = not shopOpen
    shopGui.Enabled = shopOpen
    if shopOpen then
        refreshShop()
    end
end

closeBtn.MouseButton1Click:Connect(function()
    shopOpen = false
    shopGui.Enabled = false
end)

-- Press B to open shop
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.B then
        toggleShop()
    end
end)

print("[RIVALS] Shop GUI loaded! Press B to open.")
