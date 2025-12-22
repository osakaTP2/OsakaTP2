local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local LP = Players.LocalPlayer

--==================================================
-- REMOTES
--==================================================
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local AxeSwing = Remotes:WaitForChild("AxeSwing")
local EquipAxe = Remotes:WaitForChild("EquipAxe")

--==================================================
-- FOLDERS
--==================================================
local OrbsFolder = Workspace:WaitForChild("Orbs")
local DebrisFolder = Workspace:WaitForChild("Debris")

--==================================================
-- CHARACTER
--==================================================
local function Character()
	return LP.Character or LP.CharacterAdded:Wait()
end

local function HRP()
	return Character():WaitForChild("HumanoidRootPart")
end

--==================================================
-- AXE SYSTEM (SAFE)
--==================================================
local function GetCurrentAxe()
	for _, tool in ipairs(Character():GetChildren()) do
		if tool:IsA("Tool") and tool.Name:lower():find("axe") then
			return tool
		end
	end
end

local function HasAxe()
	return GetCurrentAxe() ~= nil
end

local function EquipToolSafe(tool)
	if not tool then return false end
	local hum = Character():FindFirstChildOfClass("Humanoid")
	if hum and tool.Parent ~= Character() then
		hum:EquipTool(tool)
		return true
	end
	return tool.Parent == Character()
end

local function EnsureAxe()
	if HasAxe() then return true end

	pcall(function()
		EquipAxe:FireServer("3")
	end)

	local timeout = os.clock() + 2
	while os.clock() < timeout do
		if HasAxe() then
			return true
		end
		task.wait(0.1)
	end

	return false
end

--==================================================
-- STATE
--==================================================
local AutoTree = false
local AutoCoin = false
local AutoLucky = false

local TreeSpeed = 0.3
local MIN_SPEED = 0.1

local CoinCount = 0
local LuckyCount = 0

local BusyLucky = false
local LastSafeCF = nil

--==================================================
-- UI (CHECKED – NO CUT)
--==================================================
local gui = Instance.new("ScreenGui")
gui.Name = "AutoFarmUI"
gui.ResetOnSpawn = false
gui.Parent = LP.PlayerGui

local frame = Instance.new("Frame")
frame.Parent = gui
frame.Size = UDim2.fromOffset(260,280)
frame.Position = UDim2.fromOffset(20,240)
frame.BackgroundColor3 = Color3.fromRGB(28,28,28)
frame.Active = true
frame.Draggable = true
Instance.new("UICorner", frame)

local title = Instance.new("TextLabel")
title.Parent = frame
title.Size = UDim2.new(1,0,0,32)
title.BackgroundTransparency = 1
title.Text = "🌲 Auto Trees / Coin / Lucky"
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.TextColor3 = Color3.new(1,1,1)

local stat = Instance.new("TextLabel")
stat.Parent = frame
stat.Position = UDim2.fromOffset(0,32)
stat.Size = UDim2.new(1,0,0,20)
stat.BackgroundTransparency = 1
stat.Text = "Coins: 0 | Lucky: 0"
stat.Font = Enum.Font.Gotham
stat.TextSize = 12
stat.TextColor3 = Color3.fromRGB(200,200,200)

local function NewButton(text, y)
	local b = Instance.new("TextButton")
	b.Parent = frame
	b.Position = UDim2.fromOffset(15,y)
	b.Size = UDim2.fromOffset(230,32)
	b.Text = text
	b.Font = Enum.Font.GothamBold
	b.TextSize = 13
	b.TextColor3 = Color3.new(1,1,1)
	b.BackgroundColor3 = Color3.fromRGB(170,60,60)
	Instance.new("UICorner", b)
	return b
end

local btnTree  = NewButton("AUTO TREE : OFF", 60)
local btnCoin  = NewButton("AUTO COIN : OFF", 100)
local btnLucky = NewButton("AUTO LUCKY : OFF", 140)

local speedText = Instance.new("TextLabel")
speedText.Parent = frame
speedText.Position = UDim2.fromOffset(15,180)
speedText.Size = UDim2.fromOffset(230,18)
speedText.BackgroundTransparency = 1
speedText.Text = "Tree Speed: "..TreeSpeed
speedText.Font = Enum.Font.Gotham
speedText.TextSize = 12
speedText.TextColor3 = Color3.fromRGB(220,220,220)

local btnSpeedUp   = NewButton("SPEED +", 200)
local btnSpeedDown = NewButton("SPEED -", 235)

--==================================================
-- UI LOGIC
--==================================================
btnTree.MouseButton1Click:Connect(function()
	AutoTree = not AutoTree
	btnTree.Text = AutoTree and "AUTO TREE : ON" or "AUTO TREE : OFF"
	btnTree.BackgroundColor3 = AutoTree and Color3.fromRGB(60,170,90) or Color3.fromRGB(170,60,60)
end)

btnCoin.MouseButton1Click:Connect(function()
	AutoCoin = not AutoCoin
	btnCoin.Text = AutoCoin and "AUTO COIN : ON" or "AUTO COIN : OFF"
	btnCoin.BackgroundColor3 = AutoCoin and Color3.fromRGB(60,170,90) or Color3.fromRGB(170,60,60)
end)

btnLucky.MouseButton1Click:Connect(function()
	AutoLucky = not AutoLucky
	btnLucky.Text = AutoLucky and "AUTO LUCKY : ON" or "AUTO LUCKY : OFF"
	btnLucky.BackgroundColor3 = AutoLucky and Color3.fromRGB(60,170,90) or Color3.fromRGB(170,60,60)
end)

btnSpeedUp.MouseButton1Click:Connect(function()
	TreeSpeed = math.max(MIN_SPEED, TreeSpeed - 0.1)
	speedText.Text = "Tree Speed: "..TreeSpeed
end)

btnSpeedDown.MouseButton1Click:Connect(function()
	TreeSpeed = TreeSpeed + 0.1
	speedText.Text = "Tree Speed: "..TreeSpeed
end)

--==================================================
-- AUTO TREE
--==================================================
task.spawn(function()
	while true do
		if AutoTree and not BusyLucky then
			if EnsureAxe() then
				AxeSwing:FireServer()
			end
		end
		task.wait(TreeSpeed)
	end
end)

--==================================================
-- AUTO COIN (UNCHANGED)
--==================================================
RunService.Heartbeat:Connect(function()
	if not AutoCoin then return end
	local hrp = HRP()
	for _, coin in ipairs(OrbsFolder:GetChildren()) do
		if coin:IsA("BasePart") then
			coin.Anchored = false
			coin.CanCollide = false
			coin.CFrame = coin.CFrame:Lerp(hrp.CFrame, 0.25)
		end
	end
end)

OrbsFolder.ChildRemoved:Connect(function()
	if AutoCoin then
		CoinCount += 1
		stat.Text = "Coins: "..CoinCount.." | Lucky: "..LuckyCount
	end
end)

--==================================================
-- AUTO LUCKY (FIXED AXE RESTORE)
--==================================================
local function CollectLucky(obj)
	local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
	if prompt and fireproximityprompt then
		fireproximityprompt(prompt)
		task.wait(0.12)
		if obj.Parent then fireproximityprompt(prompt) end
	end
end

DebrisFolder.ChildAdded:Connect(function(obj)
	if not AutoLucky then return end

	BusyLucky = true

	task.wait(1.5)
	local part = obj:FindFirstChildWhichIsA("BasePart", true)
	if not part then BusyLucky = false return end

	local hrp = HRP()

	-- 🔒 จำขวานที่ถืออยู่
	local savedAxe = GetCurrentAxe()

	LastSafeCF = hrp.CFrame
	hrp.CFrame = part.CFrame + Vector3.new(0,3,0)
	task.wait(0.15)

	CollectLucky(obj)

	local timeout = os.clock() + 3
	while obj.Parent and os.clock() < timeout do task.wait() end

	if not obj.Parent then
		LuckyCount += 1
		stat.Text = "Coins: "..CoinCount.." | Lucky: "..LuckyCount
	end

	if LastSafeCF then
		hrp.CFrame = LastSafeCF
	end

	task.wait(0.15)

	-- 🔁 ใส่ขวานเดิมกลับ (ถ้า AutoTree เปิด)
	if AutoTree then
		if not EquipToolSafe(savedAxe) then
			EnsureAxe()
		end
	end

	BusyLucky = false
end)

print("✅ AUTO FARM FINAL (FULL / AXE RESTORE FIX) LOADED")



