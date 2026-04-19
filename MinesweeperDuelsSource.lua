--[[
    Minesweeper Vision - v1.0.0 (Complete Edition)
    Features: Full sidebar UI, auto-detect nearest board, performance mode,
              developer mode, number overlay, theme system with proper contrast
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local VERSION = "v1.0.0"
local AUTO_RESCAN_INTERVAL = 3

local DEFAULT_SAFE_COLOR = Color3.fromRGB(50, 200, 50)
local DEFAULT_MINE_COLOR = Color3.fromRGB(200, 50, 50)

local THEMES = {
    Dark = {
        Background = Color3.fromRGB(20, 20, 20),
        Panel = Color3.fromRGB(30, 30, 30),
        Accent = Color3.fromRGB(80, 160, 255),
        Text = Color3.fromRGB(255, 255, 255),
        ButtonBg = Color3.fromRGB(40, 40, 40),
        ButtonText = Color3.fromRGB(255, 255, 255)
    },
    Light = {
        Background = Color3.fromRGB(235, 235, 235),
        Panel = Color3.fromRGB(245, 245, 245),
        Accent = Color3.fromRGB(60, 120, 220),
        Text = Color3.fromRGB(20, 20, 20),
        ButtonBg = Color3.fromRGB(220, 220, 220),
        ButtonText = Color3.fromRGB(20, 20, 20)
    },
    Neon = {
        Background = Color3.fromRGB(10, 10, 20),
        Panel = Color3.fromRGB(15, 15, 30),
        Accent = Color3.fromRGB(0, 255, 180),
        Text = Color3.fromRGB(230, 255, 255),
        ButtonBg = Color3.fromRGB(25, 25, 45),
        ButtonText = Color3.fromRGB(230, 255, 255)
    }
}

local helperEnabled = true
local autoRescanEnabled = false
local outlineModeEnabled = false
local performanceModeEnabled = false
local developerModeEnabled = false
local numberOverlayEnabled = false
local disableAnimations = false
local disableShadows = false
local nearPlayerOnly = false
local maxDistance = 100

local currentThemeName = "Dark"
local safeColor = DEFAULT_SAFE_COLOR
local mineColor = DEFAULT_MINE_COLOR

local coloredTiles = {}
local debugLabels = {}
local numberLabels = {}
local lastRescanRequested = false
local autoRescanTimer = 0

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MinesweeperVision"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local function roundCorners(instance, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 8)
    corner.Parent = instance
end

local function addShadow(instance)
    if disableShadows then return end
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.Size = UDim2.new(1, 20, 1, 20)
    shadow.Position = UDim2.new(0, -10, 0, -10)
    shadow.BackgroundTransparency = 1
    shadow.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
    shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    shadow.ImageTransparency = 0.7
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(10, 10, 10, 10)
    shadow.ZIndex = instance.ZIndex - 1
    shadow.Parent = instance
end

local hamburgerButton = Instance.new("TextButton")
hamburgerButton.Name = "Hamburger"
hamburgerButton.Size = UDim2.new(0, 40, 0, 40)
hamburgerButton.Position = UDim2.new(0, 10, 0, 10)
hamburgerButton.BackgroundColor3 = THEMES[currentThemeName].Panel
hamburgerButton.TextColor3 = THEMES[currentThemeName].Text
hamburgerButton.Font = Enum.Font.GothamBold
hamburgerButton.TextSize = 24
hamburgerButton.Text = "≡"
hamburgerButton.Parent = screenGui
roundCorners(hamburgerButton, 8)
addShadow(hamburgerButton)

local sidebar = Instance.new("Frame")
sidebar.Name = "Sidebar"
sidebar.Size = UDim2.new(0, 300, 1, 0)
sidebar.Position = UDim2.new(0, -300, 0, 0)
sidebar.BackgroundColor3 = THEMES[currentThemeName].Background
sidebar.BorderSizePixel = 0
sidebar.Parent = screenGui

local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 70)
header.BackgroundColor3 = THEMES[currentThemeName].Panel
header.BorderSizePixel = 0
header.Parent = sidebar

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -50, 0, 32)
titleLabel.Position = UDim2.new(0, 15, 0, 10)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Minesweeper Vision"
titleLabel.TextColor3 = THEMES[currentThemeName].Text
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 20
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = header

local versionLabel = Instance.new("TextLabel")
versionLabel.Size = UDim2.new(1, -50, 0, 20)
versionLabel.Position = UDim2.new(0, 15, 0, 42)
versionLabel.BackgroundTransparency = 1
versionLabel.Text = VERSION
versionLabel.TextColor3 = THEMES[currentThemeName].Accent
versionLabel.Font = Enum.Font.Gotham
versionLabel.TextSize = 14
versionLabel.TextXAlignment = Enum.TextXAlignment.Left
versionLabel.Parent = header

local closeButton = Instance.new("TextButton")
closeButton.Name = "Close"
closeButton.Size = UDim2.new(0, 30, 0, 30)
closeButton.Position = UDim2.new(1, -40, 0, 10)
closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.Font = Enum.Font.GothamBold
closeButton.TextSize = 18
closeButton.Text = "✕"
closeButton.Parent = header
roundCorners(closeButton, 6)

local tabButtonsFrame = Instance.new("Frame")
tabButtonsFrame.Size = UDim2.new(0, 100, 1, -70)
tabButtonsFrame.Position = UDim2.new(0, 0, 0, 70)
tabButtonsFrame.BackgroundColor3 = THEMES[currentThemeName].Background
tabButtonsFrame.BorderSizePixel = 0
tabButtonsFrame.Parent = sidebar

local contentFrame = Instance.new("ScrollingFrame")
contentFrame.Size = UDim2.new(1, -100, 1, -70)
contentFrame.Position = UDim2.new(0, 100, 0, 70)
contentFrame.BackgroundColor3 = THEMES[currentThemeName].Panel
contentFrame.BorderSizePixel = 0
contentFrame.ScrollBarThickness = 6
contentFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
contentFrame.Parent = sidebar

local function createTabButton(name, order)
    local btn = Instance.new("TextButton")
    btn.Name = name .. "Tab"
    btn.Size = UDim2.new(1, 0, 0, 36)
    btn.Position = UDim2.new(0, 0, 0, (order - 1) * 40 + 10)
    btn.BackgroundColor3 = THEMES[currentThemeName].Background
    btn.TextColor3 = THEMES[currentThemeName].Text
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 14
    btn.Text = name
    btn.Parent = tabButtonsFrame
    return btn
end

local function createPage(name)
    local page = Instance.new("Frame")
    page.Name = name .. "Page"
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.Visible = false
    page.Parent = contentFrame
    
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 8)
    layout.Parent = page
    
    return page
end

local mainTabButton = createTabButton("Main", 1)
local settingsTabButton = createTabButton("Settings", 2)
local performanceTabButton = createTabButton("Performance", 3)
local developerTabButton = createTabButton("Developer", 4)
local creditsTabButton = createTabButton("Credits", 5)

local mainPage = createPage("Main")
local settingsPage = createPage("Settings")
local performancePage = createPage("Performance")
local developerPage = createPage("Developer")
local creditsPage = createPage("Credits")

local currentPage = nil
local uiElements = {}

local function switchPage(page)
    if currentPage then currentPage.Visible = false end
    currentPage = page
    currentPage.Visible = true
    
    local contentHeight = 0
    for _, child in ipairs(page:GetChildren()) do
        if child:IsA("GuiObject") and child.Visible then
            contentHeight = contentHeight + child.Size.Y.Offset + 8
        end
    end
    contentFrame.CanvasSize = UDim2.new(0, 0, 0, contentHeight + 20)
end

local function setActiveTab(activeButton)
    for _, child in ipairs(tabButtonsFrame:GetChildren()) do
        if child:IsA("TextButton") then
            local isActive = (child == activeButton)
            child.BackgroundColor3 = isActive and THEMES[currentThemeName].Panel or THEMES[currentThemeName].Background
            child.TextColor3 = THEMES[currentThemeName].Text
        end
    end
end

local function createButton(parent, text, yPos)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 180, 0, 32)
    btn.Position = UDim2.new(0, 10, 0, yPos)
    btn.BackgroundColor3 = THEMES[currentThemeName].ButtonBg
    btn.TextColor3 = THEMES[currentThemeName].ButtonText
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 14
    btn.Text = text
    btn.Parent = parent
    roundCorners(btn, 6)
    table.insert(uiElements, btn)
    return btn
end

local function createLabel(parent, text, yPos, size)
    local lbl = Instance.new("TextLabel")
    lbl.Size = size or UDim2.new(1, -20, 0, 24)
    lbl.Position = UDim2.new(0, 10, 0, yPos)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = THEMES[currentThemeName].Text
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 16
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = parent
    table.insert(uiElements, lbl)
    return lbl
end

do
    createLabel(mainPage, "Main Controls", 10)
    
    local helperButton = createButton(mainPage, "Helper: ON", 50)
    local rescanButton = createButton(mainPage, "Rescan Board", 92)
    
    helperButton.MouseButton1Click:Connect(function()
        helperEnabled = not helperEnabled
        helperButton.Text = helperEnabled and "Helper: ON" or "Helper: OFF"
        
        if not helperEnabled then
            for tile, data in pairs(coloredTiles) do
                if tile and tile.Parent then tile.Color = data.OriginalColor end
                if data.Highlight then data.Highlight:Destroy() end
            end
            table.clear(coloredTiles)
            
            for _, label in pairs(numberLabels) do
                if label then label:Destroy() end
            end
            table.clear(numberLabels)
        else
            lastRescanRequested = true
        end
    end)
    
    rescanButton.MouseButton1Click:Connect(function()
        lastRescanRequested = true
    end)
end

do
    createLabel(settingsPage, "Settings", 10)
    
    local outlineToggle = createButton(settingsPage, "Mode: Color", 50)
    local autoRescanToggle = createButton(settingsPage, "Auto-Rescan: OFF", 92)
    local numberOverlayToggle = createButton(settingsPage, "Number Overlay: OFF", 134)
    local resetColors = createButton(settingsPage, "Reset Colors", 176)
    local themeButton = createButton(settingsPage, "Theme: Dark", 218)
    
    outlineToggle.MouseButton1Click:Connect(function()
        outlineModeEnabled = not outlineModeEnabled
        outlineToggle.Text = outlineModeEnabled and "Mode: Outline" or "Mode: Color"
        lastRescanRequested = true
    end)
    
    autoRescanToggle.MouseButton1Click:Connect(function()
        autoRescanEnabled = not autoRescanEnabled
        autoRescanToggle.Text = autoRescanEnabled and "Auto-Rescan: ON" or "Auto-Rescan: OFF"
    end)
    
    numberOverlayToggle.MouseButton1Click:Connect(function()
        numberOverlayEnabled = not numberOverlayEnabled
        numberOverlayToggle.Text = numberOverlayEnabled and "Number Overlay: ON" or "Number Overlay: OFF"
        lastRescanRequested = true
    end)
    
    resetColors.MouseButton1Click:Connect(function()
        safeColor = DEFAULT_SAFE_COLOR
        mineColor = DEFAULT_MINE_COLOR
        lastRescanRequested = true
    end)
    
    local themeOrder = {"Dark", "Light", "Neon"}
    
    local function applyTheme()
        local theme = THEMES[currentThemeName]
        sidebar.BackgroundColor3 = theme.Background
        tabButtonsFrame.BackgroundColor3 = theme.Background
        contentFrame.BackgroundColor3 = theme.Panel
        header.BackgroundColor3 = theme.Panel
        titleLabel.TextColor3 = theme.Text
        versionLabel.TextColor3 = theme.Accent
        hamburgerButton.BackgroundColor3 = theme.Panel
        hamburgerButton.TextColor3 = theme.Text
        
        for _, element in ipairs(uiElements) do
            if element:IsA("TextButton") then
                element.BackgroundColor3 = theme.ButtonBg
                element.TextColor3 = theme.ButtonText
            elseif element:IsA("TextLabel") then
                element.TextColor3 = theme.Text
            end
        end
        
        for _, child in ipairs(tabButtonsFrame:GetChildren()) do
            if child:IsA("TextButton") then
                child.TextColor3 = theme.Text
            end
        end
        
        setActiveTab(currentPage == mainPage and mainTabButton or
                     currentPage == settingsPage and settingsTabButton or
                     currentPage == performancePage and performanceTabButton or
                     currentPage == developerPage and developerTabButton or
                     creditsTabButton)
    end
    
    themeButton.MouseButton1Click:Connect(function()
        local idx
        for i, name in ipairs(themeOrder) do
            if name == currentThemeName then idx = i break end
        end
        idx = (idx % #themeOrder) + 1
        currentThemeName = themeOrder[idx]
        themeButton.Text = "Theme: " .. currentThemeName
        applyTheme()
    end)
    
    applyTheme()
end

do
    createLabel(performancePage, "Performance Mode", 10)
    
    local performanceToggle = createButton(performancePage, "Performance Mode: OFF", 50)
    local animToggle = createButton(performancePage, "Disable Animations: OFF", 92)
    local shadowToggle = createButton(performancePage, "Disable Shadows: OFF", 134)
    local nearPlayerToggle = createButton(performancePage, "Near Player Only: OFF", 176)
    
    performanceToggle.MouseButton1Click:Connect(function()
        performanceModeEnabled = not performanceModeEnabled
        performanceToggle.Text = performanceModeEnabled and "Performance Mode: ON" or "Performance Mode: OFF"
        
        if performanceModeEnabled then
            disableAnimations = true
            disableShadows = true
            nearPlayerOnly = true
            animToggle.Text = "Disable Animations: ON"
            shadowToggle.Text = "Disable Shadows: ON"
            nearPlayerToggle.Text = "Near Player Only: ON"
        end
    end)
    
    animToggle.MouseButton1Click:Connect(function()
        disableAnimations = not disableAnimations
        animToggle.Text = disableAnimations and "Disable Animations: ON" or "Disable Animations: OFF"
    end)
    
    shadowToggle.MouseButton1Click:Connect(function()
        disableShadows = not disableShadows
        shadowToggle.Text = disableShadows and "Disable Shadows: ON" or "Disable Shadows: OFF"
    end)
    
    nearPlayerToggle.MouseButton1Click:Connect(function()
        nearPlayerOnly = not nearPlayerOnly
        nearPlayerToggle.Text = nearPlayerOnly and "Near Player Only: ON" or "Near Player Only: OFF"
    end)
end

do
    createLabel(developerPage, "Developer Mode", 10)
    
    local devToggle = createButton(developerPage, "Developer Mode: OFF", 50)
    
    local infoLabel = createLabel(developerPage, "Shows tile debug info", 92, UDim2.new(1, -20, 0, 60))
    infoLabel.TextWrapped = true
    infoLabel.TextSize = 12
    infoLabel.Font = Enum.Font.Gotham
    
    devToggle.MouseButton1Click:Connect(function()
        developerModeEnabled = not developerModeEnabled
        devToggle.Text = developerModeEnabled and "Developer Mode: ON" or "Developer Mode: OFF"
        
        if not developerModeEnabled then
            for _, label in pairs(debugLabels) do
                if label then label:Destroy() end
            end
            table.clear(debugLabels)
        else
            lastRescanRequested = true
        end
    end)
end

do
    createLabel(creditsPage, "Credits", 10)
    
    local credits = createLabel(creditsPage, "Minesweeper Vision " .. VERSION .. "\n\nMade by: @banner_666 on Discord\n\nFeatures: Auto-detect, Performance mode, Developer tools, Theme system", 50, UDim2.new(1, -20, 0, 120))
    credits.TextWrapped = true
    credits.TextSize = 13
    credits.Font = Enum.Font.Gotham
    credits.TextYAlignment = Enum.TextYAlignment.Top
end

local sidebarVisible = false
hamburgerButton.MouseButton1Click:Connect(function()
    sidebarVisible = not sidebarVisible
    local target = sidebarVisible and UDim2.new(0, 0, 0, 0) or UDim2.new(0, -300, 0, 0)
    local duration = disableAnimations and 0 or 0.3
    TweenService:Create(sidebar, TweenInfo.new(duration, Enum.EasingStyle.Quad), {Position = target}):Play()
end)

closeButton.MouseButton1Click:Connect(function()
    screenGui:Destroy()
end)

mainTabButton.MouseButton1Click:Connect(function()
    setActiveTab(mainTabButton)
    switchPage(mainPage)
end)

settingsTabButton.MouseButton1Click:Connect(function()
    setActiveTab(settingsTabButton)
    switchPage(settingsPage)
end)

performanceTabButton.MouseButton1Click:Connect(function()
    setActiveTab(performanceTabButton)
    switchPage(performancePage)
end)

developerTabButton.MouseButton1Click:Connect(function()
    setActiveTab(developerTabButton)
    switchPage(developerPage)
end)

creditsTabButton.MouseButton1Click:Connect(function()
    setActiveTab(creditsTabButton)
    switchPage(creditsPage)
end)

setActiveTab(mainTabButton)
switchPage(mainPage)

local function getCharacterRoot()
    local char = player.Character or player.CharacterAdded:Wait()
    return char:FindFirstChild("HumanoidRootPart")
end

local function isMineTile(tile)
    return tile:GetAttribute("Bomb") == true or tile:GetAttribute("bomb") == true
end

local function isActivated(tile)
    return tile:GetAttribute("Activated") == true
end

local function clearColors()
    for tile, data in pairs(coloredTiles) do
        if tile and tile.Parent then
            tile.Color = data.OriginalColor
        end
        if data.Highlight then
            data.Highlight:Destroy()
        end
    end
    table.clear(coloredTiles)
    
    for _, label in pairs(numberLabels) do
        if label then label:Destroy() end
    end
    table.clear(numberLabels)
    
    for _, label in pairs(debugLabels) do
        if label then label:Destroy() end
    end
    table.clear(debugLabels)
end

local function getBoardCenter(boardFolder)
    if not boardFolder then return nil end
    local sum = Vector3.new(0, 0, 0)
    local count = 0
    for _, tile in ipairs(boardFolder:GetChildren()) do
        if tile:IsA("BasePart") then
            sum += tile.Position
            count += 1
        end
    end
    if count == 0 then return nil end
    return sum / count
end

local function getNearestBoard(boards)
    local root = getCharacterRoot()
    if not root then return nil end
    
    local bestBoard = nil
    local bestDist = math.huge
    
    for _, name in ipairs({"Left", "Right"}) do
        local board = boards:FindFirstChild(name)
        if board then
            local center = getBoardCenter(board)
            if center then
                local dist = (center - root.Position).Magnitude
                if dist < bestDist then
                    bestDist = dist
                    bestBoard = board
                end
            end
        end
    end
    
    return bestBoard
end

local function colorBoard(boardFolder)
    if not boardFolder then return end
    
    local root = getCharacterRoot()
    
    for _, tile in ipairs(boardFolder:GetChildren()) do
        if tile:IsA("BasePart") and tile:GetAttribute("Tile") then
            if not isActivated(tile) then
                
                if nearPlayerOnly and root then
                    local dist = (tile.Position - root.Position).Magnitude
                    if dist > maxDistance then continue end
                end
                
                local data = coloredTiles[tile]
                if not data then
                    data = {OriginalColor = tile.Color}
                    coloredTiles[tile] = data
                end
                
                local isMine = isMineTile(tile)
                
                if outlineModeEnabled then
                    if data.Highlight then
                        data.Highlight:Destroy()
                    end
                    
                    local highlight = Instance.new("Highlight")
                    highlight.Adornee = tile
                    highlight.FillTransparency = 1
                    highlight.OutlineTransparency = 0
                    highlight.OutlineColor = isMine and mineColor or safeColor
                    highlight.Parent = screenGui
                    data.Highlight = highlight
                else
                    if data.Highlight then
                        data.Highlight:Destroy()
                        data.Highlight = nil
                    end
                    tile.Color = isMine and mineColor or safeColor
                end
                
                if numberOverlayEnabled then
                    local bombCount = tile:GetAttribute("BombCount") or 0
                    if not numberLabels[tile] and bombCount > 0 then
                        local billboard = Instance.new("BillboardGui")
                        billboard.Adornee = tile
                        billboard.Size = UDim2.new(0, 30, 0, 30)
                        billboard.StudsOffset = Vector3.new(0, 1, 0)
                        billboard.AlwaysOnTop = true
                        billboard.Parent = screenGui
                        
                        local label = Instance.new("TextLabel")
                        label.Size = UDim2.new(1, 0, 1, 0)
                        label.BackgroundTransparency = 1
                        label.Text = tostring(bombCount)
                        label.TextColor3 = Color3.fromRGB(255, 255, 255)
                        label.TextStrokeTransparency = 0.5
                        label.Font = Enum.Font.GothamBold
                        label.TextSize = 18
                        label.Parent = billboard
                        
                        numberLabels[tile] = billboard
                    end
                end
                
                if developerModeEnabled then
                    if not debugLabels[tile] then
                        local billboard = Instance.new("BillboardGui")
                        billboard.Adornee = tile
                        billboard.Size = UDim2.new(0, 100, 0, 60)
                        billboard.StudsOffset = Vector3.new(0, 2, 0)
                        billboard.AlwaysOnTop = true
                        billboard.Parent = screenGui
                        
                        local label = Instance.new("TextLabel")
                        label.Size = UDim2.new(1, 0, 1, 0)
                        label.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                        label.BackgroundTransparency = 0.5
                        label.TextColor3 = Color3.fromRGB(255, 255, 255)
                        label.Font = Enum.Font.Code
                        label.TextSize = 10
                        label.TextWrapped = true
                        label.TextYAlignment = Enum.TextYAlignment.Top
                        label.Parent = billboard
                        
                        local info = string.format(
                            "Bomb: %s\nCount: %d\nActivated: %s\nName: %s",
                            tostring(isMine),
                            tile:GetAttribute("BombCount") or 0,
                            tostring(isActivated(tile)),
                            tile.Name
                        )
                        label.Text = info
                        
                        debugLabels[tile] = billboard
                    end
                end
            end
        end
    end
end

local function colorAllArenas()
    clearColors()
    if not helperEnabled then return end
    
    local objects = workspace:FindFirstChild("Objects")
    if not objects then return end
    
    local arenas = objects:FindFirstChild("Arenas")
    if not arenas then return end
    
    for _, arena in ipairs(arenas:GetChildren()) do
        local boards = arena:FindFirstChild("Boards")
        if boards then
            local board = getNearestBoard(boards)
            if board then
                colorBoard(board)
            end
        end
    end
end

RunService.RenderStepped:Connect(function(dt)
    if autoRescanEnabled and helperEnabled then
        autoRescanTimer = autoRescanTimer + dt
        if autoRescanTimer >= AUTO_RESCAN_INTERVAL then
            autoRescanTimer = 0
            colorAllArenas()
        end
    end
end)

RunService.RenderStepped:Connect(function()
    if lastRescanRequested then
        lastRescanRequested = false
        colorAllArenas()
    end
end)

colorAllArenas()
