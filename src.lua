local plrs = game:GetService("Players")
local rs = game:GetService("RunService")
local rep = game:GetService("ReplicatedStorage")
local lp = plrs.LocalPlayer

local colors = {
	background = Color3.fromRGB(30, 30, 30),
	text = Color3.fromRGB(255, 255, 255),
	surface = Color3.fromRGB(50, 50, 50),
	accent = Color3.fromRGB(0, 170, 255),
	danger = Color3.fromRGB(255, 70, 70),
}

local whitelist = {}
local safeSpot = nil
local baseHeight = 1
local isRetreating = false
local lastDamageTime = 0
local retreatDuration = 5
local recentlyRetreated = false
local STOMP_HEALTH = 15

local gui = Instance.new("ScreenGui")
gui.Name = "AutoFarmUI"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = lp:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 300, 0, 250)
mainFrame.Position = UDim2.new(0.5, -150, 0.1, 0)
mainFrame.BackgroundColor3 = colors.background
mainFrame.BackgroundTransparency = 0.3
mainFrame.ClipsDescendants = true
mainFrame.Visible = true
mainFrame.Parent = gui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = mainFrame

local dragHeader = Instance.new("TextLabel")
dragHeader.Size = UDim2.new(1, 0, 0, 32)
dragHeader.BackgroundTransparency = 1
dragHeader.Font = Enum.Font.GothamBold
dragHeader.Text = "AUTO FARM"
dragHeader.TextColor3 = colors.text
dragHeader.TextSize = 18
dragHeader.ZIndex = 3
dragHeader.Parent = mainFrame

local inputFrame = Instance.new("Frame")
inputFrame.Size = UDim2.new(0.9, 0, 0, 36)
inputFrame.Position = UDim2.new(0.05, 0, 0.18, 0)
inputFrame.BackgroundTransparency = 1
inputFrame.ZIndex = 2
inputFrame.Parent = mainFrame

local textBox = Instance.new("TextBox")
textBox.Size = UDim2.new(0.7, 0, 1, 0)
textBox.Text = "Enter username..."
textBox.Font = Enum.Font.Gotham
textBox.TextColor3 = colors.text
textBox.BackgroundColor3 = colors.surface
textBox.ZIndex = 3
textBox.Parent = inputFrame

local addBtn = Instance.new("TextButton")
addBtn.Size = UDim2.new(0.25, 0, 1, 0)
addBtn.Position = UDim2.new(0.75, 0, 0, 0)
addBtn.Font = Enum.Font.GothamBold
addBtn.Text = "ADD"
addBtn.TextColor3 = colors.text
addBtn.BackgroundColor3 = colors.accent
addBtn.ZIndex = 3
addBtn.Parent = inputFrame

local clrBtn = Instance.new("TextButton")
clrBtn.Size = UDim2.new(0.9, 0, 0, 32)
clrBtn.Position = UDim2.new(0.05, 0, 0.4, 0)
clrBtn.Font = Enum.Font.GothamBold
clrBtn.Text = "CLEAR WHITELIST"
clrBtn.TextColor3 = colors.text
clrBtn.BackgroundColor3 = colors.danger
clrBtn.ZIndex = 3
clrBtn.Parent = mainFrame

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(0.9, 0, 0, 20)
statusLabel.Position = UDim2.new(0.05, 0, 0.65, 0)
statusLabel.Font = Enum.Font.Gotham
statusLabel.Text = "Status: Active"
statusLabel.TextColor3 = colors.text
statusLabel.BackgroundTransparency = 1
statusLabel.ZIndex = 3
statusLabel.Parent = mainFrame

local creditLabel = Instance.new("TextLabel")
creditLabel.Size = UDim2.new(0, 120, 0, 20)
creditLabel.Position = UDim2.new(1, -125, 1, -25)
creditLabel.Font = Enum.Font.GothamMedium
creditLabel.Text = "Made with ❤️ by mq"
creditLabel.TextColor3 = colors.text
creditLabel.TextSize = 12
creditLabel.BackgroundTransparency = 1
creditLabel.TextXAlignment = Enum.TextXAlignment.Right
creditLabel.ZIndex = 3
creditLabel.Parent = mainFrame

local function applyStomp(target)
	pcall(function()
		local humanoid = target.Character:FindFirstChild("Humanoid")
		if humanoid and humanoid.Health > 0 then
			rep.MainEvent:FireServer("Stomp")
		end
	end)
end

local function getValidTargets()
	local valid = {}
	for _, p in plrs:GetPlayers() do
		if p ~= lp and not whitelist[p] and p.Character then
			local hum = p.Character:FindFirstChild("Humanoid")
			if hum and hum.Health <= STOMP_HEALTH and hum.Health > 0 then
				table.insert(valid, p)
			end
		end
	end
	return valid
end

rs.Heartbeat:Connect(function()
	local now = tick()
	local char = lp.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")

	if not char or not root then return end

	if isRetreating then
		if now - lastDamageTime > retreatDuration then
			isRetreating = false
		else
			if safeSpot then
				local retreatPos = safeSpot.Position + Vector3.new(0, 5, 0)
				char:PivotTo(CFrame.new(retreatPos))
				statusLabel.Text = "Retreating (" .. math.floor(retreatDuration - (now - lastDamageTime)) .. "s)"
			end
			return
		end
	end

	local targets = getValidTargets()

	if #targets > 0 then
		local target = targets[1]
		local tRoot = target.Character and target.Character:FindFirstChild("HumanoidRootPart")

		if tRoot then
			local aboveTarget = tRoot.Position + Vector3.new(0, baseHeight, 0)
			char:PivotTo(CFrame.new(aboveTarget))
			applyStomp(target)
			statusLabel.Text = "Stomping " .. target.Name .. " (" .. math.floor(target.Character.Humanoid.Health) .. " HP)"
		end
	else
		if safeSpot then
			local safePos = safeSpot.Position + Vector3.new(0, 5, 0)
			char:PivotTo(CFrame.new(safePos))
			statusLabel.Text = "No valid targets"
		end
	end
end)

lp.CharacterAdded:Connect(function(char)
	local humanoid = char:WaitForChild("Humanoid")
	local root = char:WaitForChild("HumanoidRootPart")
	local zone = workspace:FindFirstChild("SafeZone")
	if zone then
		safeSpot = zone
	end
	humanoid.HealthChanged:Connect(function(newHealth)
		if newHealth < humanoid.MaxHealth and not recentlyRetreated then
			lastDamageTime = tick()
			isRetreating = true
			recentlyRetreated = true
			task.delay(retreatDuration + 0.5, function()
				recentlyRetreated = false
			end)
		end
	end)
end)

if lp.Character then
	local char = lp.Character
	local humanoid = char:FindFirstChild("Humanoid")
	local root = char:FindFirstChild("HumanoidRootPart")
	local zone = workspace:FindFirstChild("SafeZone")
	if zone then
		safeSpot = zone
	end
	if humanoid then
		humanoid.HealthChanged:Connect(function(newHealth)
			if newHealth < humanoid.MaxHealth and not recentlyRetreated then
				lastDamageTime = tick()
				isRetreating = true
				recentlyRetreated = true
				task.delay(retreatDuration + 0.5, function()
					recentlyRetreated = false
				end)
			end
		end)
	end
end

print("Health-Based Stomp System Loaded!")
