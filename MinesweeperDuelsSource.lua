--// SERVICES
local Players = game:GetService("Players")
local player = Players.LocalPlayer

--// UI CREATION
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MinesweeperHelper"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 220, 0, 90)
frame.Position = UDim2.new(0, 50, 0, 200)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
frame.BorderSizePixel = 1
frame.Active = true
frame.Draggable = true
frame.Parent = screenGui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -20, 0, 24)
title.Position = UDim2.new(0, 10, 0, 5)
title.BackgroundTransparency = 1
title.Text = "Minesweeper Helper"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = frame

local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(0, 90, 0, 24)
toggleButton.Position = UDim2.new(0, 10, 0, 35)
toggleButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.Font = Enum.Font.Gotham
toggleButton.TextSize = 14
toggleButton.Text = "Helper: ON"
toggleButton.Parent = frame

local rescanButton = Instance.new("TextButton")
rescanButton.Size = UDim2.new(0, 90, 0, 24)
rescanButton.Position = UDim2.new(0, 120, 0, 35)
rescanButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
rescanButton.TextColor3 = Color3.fromRGB(255, 255, 255)
rescanButton.Font = Enum.Font.Gotham
rescanButton.TextSize = 14
rescanButton.Text = "Rescan"
rescanButton.Parent = frame

local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 24, 0, 24)
closeButton.Position = UDim2.new(1, -28, 0, 5)
closeButton.BackgroundColor3 = Color3.fromRGB(60, 0, 0)
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.Font = Enum.Font.GothamBold
closeButton.TextSize = 14
closeButton.Text = "X"
closeButton.Parent = frame

--// STATE
local helperEnabled = true
local coloredTiles = {} -- [Instance] = originalColor

local function clearColors()
	for tile, originalColor in pairs(coloredTiles) do
		if tile and tile.Parent then
			tile.Color = originalColor
		end
	end
	table.clear(coloredTiles)
end

local function isMineTile(tile)
	return tile:GetAttribute("Bomb") == true
		or tile:GetAttribute("bomb") == true
end

local function isActivated(tile)
	return tile:GetAttribute("Activated") == true
end

local function colorBoard(boardFolder)
	if not boardFolder then return end

	for _, tile in ipairs(boardFolder:GetChildren()) do
		if tile:IsA("BasePart") and tile:GetAttribute("Tile") then

			if not isActivated(tile) then
				local originalColor = tile.Color
				coloredTiles[tile] = originalColor

				if isMineTile(tile) then
					tile.Color = Color3.fromRGB(200, 50, 50) -- red
				else
					tile.Color = Color3.fromRGB(50, 200, 50) -- green
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
			colorBoard(boards:FindFirstChild("Left"))
			colorBoard(boards:FindFirstChild("Right"))
		end
	end
end

--// UI HOOKS
toggleButton.MouseButton1Click:Connect(function()
	helperEnabled = not helperEnabled
	toggleButton.Text = helperEnabled and "Helper: ON" or "Helper: OFF"

	if helperEnabled then
		colorAllArenas()
	else
		clearColors()
	end
end)

rescanButton.MouseButton1Click:Connect(function()
	colorAllArenas()
end)

closeButton.MouseButton1Click:Connect(function()
	clearColors()
	screenGui:Destroy()
end)

-- Initial run
colorAllArenas()
