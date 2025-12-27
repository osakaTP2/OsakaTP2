--==================================================
-- SERVICES
--==================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

--==================================================
-- CHARACTER (REBIND AFTER RESPAWN)
--==================================================
local Character, HRP

local function bindCharacter(char)
	Character = char
	HRP = char:WaitForChild("HumanoidRootPart")
end

bindCharacter(Player.Character or Player.CharacterAdded:Wait())
Player.CharacterAdded:Connect(bindCharacter)


--==================================================
-- UI SETUP
--==================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ProUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = PlayerGui

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.fromOffset(200, 280)
MainFrame.Position = UDim2.fromScale(0.5, 0.5)
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.BackgroundColor3 = Color3.fromRGB(30,30,30)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0,16)

local Stroke = Instance.new("UIStroke", MainFrame)
Stroke.Thickness = 1.9
Stroke.Color = Color3.fromRGB(80,80,80)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1,-40,0,40)
Title.Position = UDim2.fromOffset(20,10)
Title.BackgroundTransparency = 1
Title.Text = "OsakaTP2 v.1"
Title.TextColor3 = Color3.new(1,1,1)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 17
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = MainFrame

--==================================================
-- TOGGLE UI BUTTON
--==================================================
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.fromOffset(44,44)
ToggleBtn.Position = UDim2.fromOffset(12,12)
ToggleBtn.Text = "≡"
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 22
ToggleBtn.TextColor3 = Color3.new(1,1,1)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(50,50,50)
ToggleBtn.Parent = ScreenGui
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(1,0)

local uiOpened = true
ToggleBtn.MouseButton1Click:Connect(function()
	uiOpened = not uiOpened
	MainFrame.Visible = uiOpened
end)

--==================================================
-- SCROLL AREA
--==================================================
local Scroll = Instance.new("ScrollingFrame")
Scroll.Size = UDim2.new(1,-20,1,-70)
Scroll.Position = UDim2.fromOffset(10,60)
Scroll.ScrollBarThickness = 6
Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
Scroll.BackgroundTransparency = 1
Scroll.Parent = MainFrame

local Layout = Instance.new("UIListLayout", Scroll)
Layout.Padding = UDim.new(0,8)
Layout.HorizontalAlignment = Enum.HorizontalAlignment.Center

--==================================================
-- BUTTON HELPER
--==================================================
local function createButton(text)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.fromOffset(160,36)
	btn.BackgroundColor3 = Color3.fromRGB(170,0,0)
	btn.TextColor3 = Color3.new(1,1,1)
	btn.Font = Enum.Font.Gotham
	btn.TextSize = 11.5
	btn.Text = text.." : OFF"
	btn.Parent = Scroll
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0,8)
	return btn
end

--==================================================
-- DIAMOND FILTER (FAKE CHECK)
--==================================================
local FakeCFrames = {
	CFrame.new(864.4,16.6,433.6),
	CFrame.new(868.2,24.9,429.0),
	CFrame.new(864.4,16.6,424.6),
	CFrame.new(817.4,16.7,-173.3),
	CFrame.new(826.4,16.7,-173.6),
}

local function isFakeDiamond(pos)
	for _, cf in ipairs(FakeCFrames) do
		if (pos - cf.Position).Magnitude < 12 then
			return true
		end
	end
	return false
end

local function getRealDiamonds()
	local diamonds = {}
	for _, v in ipairs(workspace:GetChildren()) do
		if v.Name == "Diamond" then
			local part = v:IsA("BasePart") and v or v:FindFirstChildWhichIsA("BasePart")
			if part and not isFakeDiamond(part.Position) then
				table.insert(diamonds, part)
			end
		end
	end
	return diamonds
end

--==================================================
-- STATES
--==================================================
local AUTO_PULL  = false
local AUTO_CHAOS = false
local AUTO_FIRE2 = false
local AUTO_FIRE3 = false

--==================================================
-- DIAMOND PULL
--==================================================
local function touch(part)
	firetouchinterest(HRP, part, 0)
	task.wait()
	firetouchinterest(HRP, part, 1)
end

task.spawn(function()
	while task.wait(0.12) do
		if AUTO_PULL and HRP then
			for _, d in ipairs(getRealDiamonds()) do
				pcall(function()
					d.CFrame = HRP.CFrame
					touch(d)
				end)
			end
		end
	end
end)

--==================================================
-- NEAREST PLAYER
--==================================================
local function getNearestPlayer()
	if not HRP then return nil end

	local nearest, shortest = nil, math.huge
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= Player and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
			local dist = (plr.Character.HumanoidRootPart.Position - HRP.Position).Magnitude
			if dist < shortest then
				shortest = dist
				nearest = plr
			end
		end
	end
	return nearest
end

--==================================================
-- CHAOS AUTO ATTACK
--==================================================
task.spawn(function()
	while task.wait(0.35) do
		if not AUTO_CHAOS or not Character then continue end

		local dragon = Character:FindFirstChild("Chaotic Dragon", true)
		local event = dragon and dragon:FindFirstChild("Event", true)
		local target = getNearestPlayer()

		if event and target then
			event:FireServer("FIRE_ATTACK", target.Character.HumanoidRootPart.Position)
		end
	end
end)

--==================================================
-- FIRE SKILL Q
--==================================================
local ATTACK_RANGE = 150
local lastFire2Target = nil

local function getNearbyAlivePlayer()
	if not HRP then return nil end

	local best, range = nil, ATTACK_RANGE
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= Player and plr.Character then
			local hum = plr.Character:FindFirstChildOfClass("Humanoid")
			local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
			if hum and hrp and hum.Health > 0 then
				local dist = (hrp.Position - HRP.Position).Magnitude
				if dist <= range then
					range = dist
					best = plr
				end
			end
		end
	end
	return best
end

task.spawn(function()
	while task.wait(0.2) do
		if not AUTO_FIRE2 or not Character or not HRP then continue end

		local sword = Character:FindFirstChild("Fire GreatSword")
		local qevent = sword and sword:FindFirstChild("Qevent")
		if not qevent then continue end

		local target = getNearbyAlivePlayer()
		if not target or target == lastFire2Target then continue end

		local tChar = target.Character
		local hum = tChar:FindFirstChildOfClass("Humanoid")
		local tHRP = tChar:FindFirstChild("HumanoidRootPart")
		if not hum or hum.Health <= 0 then continue end

		lastFire2Target = target
		local savedCF = HRP.CFrame

		for _ = 1,4 do
			if not AUTO_FIRE2 or hum.Health <= 0 then break end
			qevent:FireServer()
			task.wait(0.1)
		end

		local followTime = tick() + 0.5
		while tick() < followTime and AUTO_FIRE2 and hum.Health > 0 do
			HRP.CFrame = tHRP.CFrame * CFrame.new(0,0,-2)
			task.wait(0.05)
		end

		task.wait(5)
		if HRP then HRP.CFrame = savedCF end
	end
end)

--==================================================
-- FIRE SKILL X
--==================================================
local lastFire3Target = nil

task.spawn(function()
	while task.wait(0.3) do
		if not AUTO_FIRE3 or not Character or not HRP then continue end

		local sword = Character:FindFirstChild("Fire GreatSword")
		local xevent = sword and sword:FindFirstChild("Xevent")
		if not xevent then continue end

		local target = getNearestPlayer()
		if not target or target == lastFire3Target then
			lastFire3Target = nil
			continue
		end

		local tHRP = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
		if not tHRP then continue end

		lastFire3Target = target
		HRP.CFrame = tHRP.CFrame * CFrame.new(0,0,-5)
		task.wait(0.15)

		for _ = 1,4 do
			if not AUTO_FIRE3 then break end
			xevent:FireServer(tHRP.Position)
			task.wait(0.1)
		end

		task.wait(8)
	end
end)

--==================================================
-- UI BUTTONS
--==================================================
local pullBtn = createButton("DIAMOND")
pullBtn.MouseButton1Click:Connect(function()
	AUTO_PULL = not AUTO_PULL
	pullBtn.Text = "DIAMOND : "..(AUTO_PULL and "ON" or "OFF")
	pullBtn.BackgroundColor3 = AUTO_PULL and Color3.fromRGB(0,170,0) or Color3.fromRGB(170,0,0)
end)

local chaosBtn = createButton("CHAOS / Skill 3")
chaosBtn.MouseButton1Click:Connect(function()
	AUTO_CHAOS = not AUTO_CHAOS
	chaosBtn.Text = "CHAOS / Skill 3 : "..(AUTO_CHAOS and "ON" or "OFF")
	chaosBtn.BackgroundColor3 = AUTO_CHAOS and Color3.fromRGB(0,170,0) or Color3.fromRGB(170,0,0)
end)

local fire2Btn = createButton("FIRE Sword Q")
fire2Btn.MouseButton1Click:Connect(function()
	AUTO_FIRE2 = not AUTO_FIRE2
	fire2Btn.Text = "FIRE Sword Q : "..(AUTO_FIRE2 and "ON" or "OFF")
	fire2Btn.BackgroundColor3 = AUTO_FIRE2 and Color3.fromRGB(0,170,0) or Color3.fromRGB(170,0,0)
end)

local fire3Btn = createButton("FIRE Sword X")
fire3Btn.MouseButton1Click:Connect(function()
	AUTO_FIRE3 = not AUTO_FIRE3
	fire3Btn.Text = "FIRE Sword X : "..(AUTO_FIRE3 and "ON" or "OFF")
	fire3Btn.BackgroundColor3 = AUTO_FIRE3 and Color3.fromRGB(0,170,0) or Color3.fromRGB(170,0,0)
end)

--==================================================
-- DRAG UI
--==================================================
local dragging, dragStart, startPos

local function updateDrag(input)
	local delta = input.Position - dragStart
	MainFrame.Position = UDim2.new(
		startPos.X.Scale, startPos.X.Offset + delta.X,
		startPos.Y.Scale, startPos.Y.Offset + delta.Y
	)
end

Title.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragStart = input.Position
		startPos = MainFrame.Position

		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

Title.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement and dragging then
		updateDrag(input)
	end
end)


