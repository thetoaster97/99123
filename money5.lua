local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer
local workspace = workspace

if not game:IsLoaded() then game.Loaded:Wait() end
task.wait(0.25)

local RemoteIndex = {}
local RemoteObjects = {}

local children = game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("Net"):GetChildren()
for i, obj in ipairs(children) do
	if obj:IsA("RemoteEvent") then
		local nextIndex = i + 1
		local nextObj = children[nextIndex]
		if nextObj then
			RemoteIndex[obj.Name] = nextIndex
			RemoteObjects[nextIndex] = nextObj
		end
	end
end

local function fireRemoteI(index, ...)
	local remote = RemoteObjects[index]
	if remote then
		remote:FireServer(...)
		return true
	else
		return false
	end
end

local function fireRemote(name, ...)
	local index = RemoteIndex[name]
	if index then
		return fireRemoteI(index, ...)
	else
		return false
	end
end

local SETTINGS_FILE = "AutoTPSettings.json"

local function loadSettings()
	local defaults = {
		autoTPButtonEnabled = true
	}
	pcall(function()
		if isfile and isfile(SETTINGS_FILE) then
			local data = HttpService:JSONDecode(readfile(SETTINGS_FILE))
			for k, v in pairs(data) do
				defaults[k] = v
			end
		end
	end)
	return defaults
end

local function saveSettings()
	pcall(function()
		if writefile then
			local data = {
				autoTPButtonEnabled = _G.ATP_autoTPButtonEnabled
			}
			writefile(SETTINGS_FILE, HttpService:JSONEncode(data))
		end
	end)
end

local savedSettings = loadSettings()

_G.ATP_isTeleporting = false
_G.TPSpeedItem = _G.TPSpeedItem or "Flying Carpet"
_G.ATP_ManualTPKey = _G.ATP_ManualTPKey or Enum.KeyCode.Q
_G.ATP_autoTPButtonEnabled = savedSettings.autoTPButtonEnabled

local BUTTON_GLOW_COLOR = Color3.fromRGB(0, 170, 255)
local plotsFolder = workspace:FindFirstChild("Plots")
local UPPER_FLOOR_Y_THRESHOLD = 10

local savedPositions = {
	Vector3.new(-340.85, 16.90, 6.69),
	Vector3.new(-341.14, 16.90, 113.76),
	Vector3.new(-341.25, 16.90, 221.40),
	Vector3.new(-478.53, 16.90, 220.10),
	Vector3.new(-478.29, 16.90, 113.33),
	Vector3.new(-478.81, 16.90, 6.43),
	Vector3.new(-478.45, 16.90, -100.71),
	Vector3.new(-341.11, 16.90, -99.67)
}
local TRANSPARENCY_THRESHOLD = 0.6
local WALL_OFFSET_DISTANCE = -2
local WINDOW_SCALE_CHECK = Vector3.new(0.99945068359375, 0.9998798370361328, 32)
local WINDOW_SCALE_TOLERANCE = 0.1
local WINDOW_EXPANDED_X = 4.99945068359375
local MAIN_SCALE_CHECK = Vector3.new(3.8243651390075684, 45.83666229248047, 18.140335083007812)
local MAIN_SCALE_TOLERANCE = 0.5
local modifiedWindowParts = {}
local originalSizes = {}

local function getCharacter(timeout)
	timeout = timeout or 5
	if not LocalPlayer then return nil end
	local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
	if not char then return nil end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then
		local started = os.clock()
		repeat
			hrp = char:FindFirstChild("HumanoidRootPart")
			task.wait()
		until hrp or (os.clock() - started) > timeout
	end
	if not hrp then return nil end
	return char, hrp
end

local function crunchBody(character)
	originalSizes = {}
	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
			originalSizes[part] = part.Size
			part.Size = Vector3.new(0.1, 0.1, 0.1)
		end
	end
end

local function restoreBody()
	for part, originalSize in pairs(originalSizes) do
		if part and part.Parent then
			part.Size = originalSize
		end
	end
	originalSizes = {}
end

local function findClosestSavedPosition(fromPosition)
	local closestPos = nil
	local closestDistance = math.huge
	for _, pos in ipairs(savedPositions) do
		local distance = (pos - fromPosition).Magnitude
		if distance < closestDistance then
			closestDistance = distance
			closestPos = pos
		end
	end
	return closestPos
end

local function isWindowScale(partSize)
	local xMatch = math.abs(partSize.X - WINDOW_SCALE_CHECK.X) < WINDOW_SCALE_TOLERANCE
	local yMatch = math.abs(partSize.Y - WINDOW_SCALE_CHECK.Y) < WINDOW_SCALE_TOLERANCE
	local zMatch = math.abs(partSize.Z - WINDOW_SCALE_CHECK.Z) < WINDOW_SCALE_TOLERANCE
	return xMatch and yMatch and zMatch
end

local function expandWindows()
	modifiedWindowParts = {}
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("BasePart") and isWindowScale(obj.Size) then
			modifiedWindowParts[obj] = obj.Size
			obj.Size = Vector3.new(WINDOW_EXPANDED_X, obj.Size.Y, obj.Size.Z)
		end
	end
end

local function restoreWindows()
	for part, originalSize in pairs(modifiedWindowParts) do
		if part and part.Parent then
			part.Size = originalSize
		end
	end
	modifiedWindowParts = {}
end

local function findClosestTransparentPart(fromPosition)
	local closestPart = nil
	local closestDistance = math.huge
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("BasePart") and math.abs(obj.Transparency - TRANSPARENCY_THRESHOLD) < 0.01 then
			local distance = (obj.Position - fromPosition).Magnitude
			if distance < closestDistance then
				closestDistance = distance
				closestPart = obj
			end
		end
	end
	return closestPart
end

local function positionAtWall(wallPart, currentPosition)
	local wallPos = wallPart.Position
	local toWall = (wallPos - currentPosition).Unit
	local finalPosition = wallPos - (toWall * math.abs(WALL_OFFSET_DISTANCE))
	local lookAtCFrame = CFrame.new(finalPosition, wallPos)
	return lookAtCFrame
end

local function useQuantumClonerMapped()
	local character = LocalPlayer.Character
	if not character then return false end
	
	local backpack = LocalPlayer:FindFirstChild("Backpack")
	if not backpack then return false end
	
	local quantumCloner = backpack:FindFirstChild("Quantum Cloner")
	if not quantumCloner then return false end
	
	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then return false end
	
	for _, tool in ipairs(character:GetChildren()) do
		if tool:IsA("Tool") then
			humanoid:UnequipTools()
			task.wait(0.03)
			break
		end
	end
	
	humanoid:EquipTool(quantumCloner)
	task.wait(0.05)
	
	fireRemote("RE/UseItem")
	task.wait(0.05)
	fireRemote("RE/QuantumCloner/OnTeleport")
	
	task.wait(0.1)
	
	local backpack2 = LocalPlayer:FindFirstChild("Backpack")
	if backpack2 then
		local carpet = backpack2:FindFirstChild(_G.TPSpeedItem or "Flying Carpet")
		if carpet then
			local humanoid2 = character:FindFirstChild("Humanoid")
			if humanoid2 then
				humanoid2:EquipTool(carpet)
			end
		end
	end
	
	return true
end

local function TeleportToHighest(isManualTP)
	local character, hrp = getCharacter()
	if not character or not character.Parent then _G.ATP_isTeleporting = false return end
	if not hrp or not hrp.Parent then _G.ATP_isTeleporting = false return end
	
	local debrisWait = 0
	while debrisWait < 0.5 do
		local debris = workspace:FindFirstChild("Debris")
		if debris and #debris:GetChildren() > 0 then break end
		task.wait(0.1)
		debrisWait = debrisWait + 0.1
	end
	
	local myPlotSign = nil
	plotsFolder = workspace:FindFirstChild("Plots")
	if plotsFolder then
		for _, plot in ipairs(plotsFolder:GetChildren()) do
			local plotSign = plot:FindFirstChild("PlotSign")
			if plotSign then
				local surfaceGui = plotSign:FindFirstChildWhichIsA("SurfaceGui", true)
				if surfaceGui then
					local textLabel = surfaceGui:FindFirstChildWhichIsA("TextLabel", true)
					if textLabel and textLabel.Text then
						local text = textLabel.Text:lower()
						if (LocalPlayer.Name and text:find(LocalPlayer.Name:lower(), 1, true)) or 
						   (LocalPlayer.DisplayName and text:find(LocalPlayer.DisplayName:lower(), 1, true)) then
							myPlotSign = plotSign
							break
						end
					end
				end
			end
		end
	end
	
	local itemsList = {}
	local myPlot = myPlotSign and myPlotSign.Parent or nil
	
	local plotOwners = {}
	if plotsFolder then
		for _, plot in ipairs(plotsFolder:GetChildren()) do
			local plotSign = plot:FindFirstChild("PlotSign")
			if plotSign then
				local plotPos = plot:GetPivot().Position
				local surfaceGui = plotSign:FindFirstChildWhichIsA("SurfaceGui", true)
				if surfaceGui then
					local textLabel = surfaceGui:FindFirstChildWhichIsA("TextLabel", true)
					if textLabel and textLabel.Text then
						local ownerText = textLabel.Text
						local ownerInGame = false
						for _, player in ipairs(Players:GetPlayers()) do
							if ownerText:lower():find(player.Name:lower(), 1, true) or 
							   ownerText:lower():find(player.DisplayName:lower(), 1, true) then
								ownerInGame = true
								break
							end
						end
						plotOwners[plot] = {
							position = plotPos,
							ownerInGame = ownerInGame,
							isMyPlot = (plot == myPlot)
						}
					end
				end
			end
		end
	end
	
	local debrisFolder = workspace:FindFirstChild("Debris")
	if debrisFolder then
		for _, obj in ipairs(debrisFolder:GetChildren()) do
			if obj:IsA("BasePart") then
				local closestPlot = nil
				local closestPlotDist = math.huge
				if plotsFolder then
					for plot, plotData in pairs(plotOwners) do
						local dx = obj.Position.X - plotData.position.X
						local dz = obj.Position.Z - plotData.position.Z
						local dist = math.sqrt(dx*dx + dz*dz)
						if dist < closestPlotDist then
							closestPlotDist = dist
							closestPlot = plot
						end
					end
				end
				
				if closestPlot and plotOwners[closestPlot] and plotOwners[closestPlot].isMyPlot then
					continue
				end
				
				if closestPlotDist > 300 then
					continue
				end
				
				if closestPlot and plotOwners[closestPlot] and not plotOwners[closestPlot].ownerInGame then
					continue
				end
				
				local displayNameLabel = nil
				local generationLabel = nil
				for _, child in ipairs(obj:GetChildren()) do
					if child:IsA("BillboardGui") or child:IsA("SurfaceGui") then
						for _, label in ipairs(child:GetDescendants()) do
							if label:IsA("TextLabel") then
								if label.Name == "DisplayName" then
									displayNameLabel = label
								elseif label.Name == "Generation" and (label.Text or ""):find("/s") then
									generationLabel = label
								end
							end
						end
					end
				end
				
				if displayNameLabel and generationLabel then
					local displayName = displayNameLabel.Text or "Unknown"
					local genText = string.lower(generationLabel.Text or "0")
					local petValue = tonumber(genText:match("[%d%.]+")) or 0
					if genText:find("t") then
						petValue = petValue * 1e12
					elseif genText:find("b") then
						petValue = petValue * 1e9
					elseif genText:find("m") then
						petValue = petValue * 1e6
					elseif genText:find("k") then
						petValue = petValue * 1e3
					end
					
					table.insert(itemsList, {
						value = petValue,
						position = obj.Position - Vector3.new(0, 11, 0),
						name = displayName,
						actualPart = obj
					})
				end
			end
		end
	end
	
	if #itemsList == 0 then
		_G.ATP_isTeleporting = false
		return
	end
	
	table.sort(itemsList, function(a, b) return a.value > b.value end)
	
	local targetItem = itemsList[1]
	if not targetItem then
		_G.ATP_isTeleporting = false
		return
	end
	
	local itemPos = targetItem.position
	local itemHeight = targetItem.position.Y
	local targetPetPart = targetItem.actualPart
	
	local isUpperFloor = itemHeight > UPPER_FLOOR_Y_THRESHOLD
	
	character, hrp = getCharacter()
	if hrp then
		_G.ATP_isTeleporting = true
		
		local humanoid = character:FindFirstChild("Humanoid")
		if humanoid then
			humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
			humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
			humanoid:SetStateEnabled(Enum.HumanoidStateType.Physics, false)
		end
		
		task.wait(0.15)
		
		local backpack = LocalPlayer:FindFirstChild("Backpack")
		if backpack then
			local carpet = backpack:FindFirstChild(_G.TPSpeedItem or "Flying Carpet")
			if carpet then
				if humanoid then humanoid:EquipTool(carpet) end
			end
		end
		
		task.wait(0.05)
		
		if isUpperFloor then
			crunchBody(character)
			expandWindows()
			
			local closestPos = findClosestSavedPosition(itemPos)
			if closestPos then
				hrp.CFrame = CFrame.new(hrp.Position)
				hrp.AssemblyLinearVelocity = Vector3.new(0, 150, 0)
				task.wait(0.2)
				hrp.CFrame = CFrame.new(closestPos)
				hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
				hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
				task.wait(0.15)
				
				local closestWallPart = findClosestTransparentPart(closestPos)
				if closestWallPart then
					local wallCFrame = positionAtWall(closestWallPart, closestPos)
					for i = 1, 3 do
						hrp.CFrame = wallCFrame
						hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
						hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
						task.wait(0.05)
					end
					task.wait(0.3)
					
					local cloneSuccess = useQuantumClonerMapped()
					if cloneSuccess then
						task.wait(0.3)
						
						local newChar = LocalPlayer.Character
						if newChar and targetPetPart then
							local newHRP = newChar:FindFirstChild("HumanoidRootPart")
							if newHRP then
								local petPosition = targetPetPart.Position - Vector3.new(0, 3, 0)
								newHRP.AssemblyLinearVelocity = Vector3.zero
								newHRP.AssemblyAngularVelocity = Vector3.zero
								newHRP.CFrame = CFrame.new(petPosition)
								newHRP.AssemblyLinearVelocity = Vector3.zero
								newHRP.AssemblyAngularVelocity = Vector3.zero
							end
						end
					end
					task.wait(0.2)
				end
			end
			
			restoreBody()
			restoreWindows()
			task.wait(0.05)
			
			if humanoid then
				humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
				humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
				humanoid:SetStateEnabled(Enum.HumanoidStateType.Physics, true)
			end
			
			_G.ATP_isTeleporting = false
			return
		end
		
		local targetPlotSign = nil
		local closestDistance = math.huge
		if plotsFolder then
			for _, plot in ipairs(plotsFolder:GetChildren()) do
				local plotSign = plot:FindFirstChild("PlotSign")
				if plotSign and plotSign ~= myPlotSign then
					local distance = (plotSign.Position - itemPos).Magnitude
					if distance < closestDistance then
						closestDistance = distance
						targetPlotSign = plotSign
					end
				end
			end
		end
		
		if not targetPlotSign then
			_G.ATP_isTeleporting = false
			return
		end
		
		local signPos = targetPlotSign.Position
		local targetCFrame = targetPlotSign.CFrame
		local finalPosition
		
		if itemHeight <= 6.11 then
			local directionFromItem = (signPos - itemPos).Unit
			local forwardOffset = Vector3.new(directionFromItem.X * 3, 0, directionFromItem.Z * 3)
			finalPosition = Vector3.new(signPos.X + forwardOffset.X, -4, signPos.Z + forwardOffset.Z)
		else
			local forwardOffset = targetCFrame.LookVector * -2
			finalPosition = targetPlotSign.Position + forwardOffset + Vector3.new(0, 6, 0)
		end
		
		local facingDirection
		if itemPos.X >= finalPosition.X then
			facingDirection = Vector3.new(1, 0, 0)
		else
			facingDirection = Vector3.new(-1, 0, 0)
		end
		
		local jumpPower, totalRise, tickDelay, timeout = 400, 40, 0.0015, 3
		local startY = hrp.Position.Y
		local riseTargetY = startY + totalRise
		local startTime = os.clock()
		local lastY = startY
		local v = hrp.AssemblyLinearVelocity
		local vX, vZ = v.X, v.Z
		
		while hrp.Parent do
			local currentY = hrp.Position.Y
			if currentY >= riseTargetY then break end
			local remaining = riseTargetY - currentY
			local power = remaining < 5 and math.min(jumpPower, remaining * 10) or jumpPower
			hrp.AssemblyLinearVelocity = Vector3.new(vX, power, vZ)
			task.wait(tickDelay)
			local nowY = hrp.Position.Y
			if nowY >= riseTargetY then
				hrp.AssemblyLinearVelocity = Vector3.new(vX, 0, vZ)
				break
			end
			if math.abs(nowY - lastY) < 0.05 then
				hrp.CFrame = hrp.CFrame + Vector3.new(0, 1, 0)
			end
			lastY = nowY
			if os.clock() - startTime > timeout then break end
		end
		
		if hrp.Parent then
			local finalY = hrp.Position.Y
			if finalY > riseTargetY then
				local p = hrp.Position
				hrp.CFrame = CFrame.new(p.X, riseTargetY, p.Z) * (hrp.CFrame - hrp.CFrame.Position)
			end
			v = hrp.AssemblyLinearVelocity
			hrp.AssemblyLinearVelocity = Vector3.new(v.X, 0, v.Z)
		end
		
		hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
		hrp.CFrame = CFrame.lookAt(finalPosition, finalPosition + facingDirection)
		hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
		
		local backpack2 = LocalPlayer:FindFirstChild("Backpack")
		if backpack2 then
			local carpet2 = backpack2:FindFirstChild(_G.TPSpeedItem or "Flying Carpet")
			if carpet2 then
				if humanoid then humanoid:EquipTool(carpet2) end
			end
		end
		
		task.wait(0.5)
		
		if hrp then
			local origin = hrp.Position
			local direction = hrp.CFrame.LookVector * 50
			local rayParams = RaycastParams.new()
			rayParams.FilterDescendantsInstances = {character}
			rayParams.FilterType = Enum.RaycastFilterType.Blacklist
			rayParams.IgnoreWater = true
			local result = workspace:Raycast(origin, direction, rayParams)
			if result then
				local wallOffset = itemHeight <= 6.11 and 0.3 or 0.35
				local safePos = result.Position - (hrp.CFrame.LookVector * wallOffset)
				hrp.AssemblyLinearVelocity = Vector3.zero
				hrp.CFrame = CFrame.lookAt(safePos, safePos + hrp.CFrame.LookVector)
				hrp.AssemblyLinearVelocity = Vector3.zero
			end
		end
		
		task.wait(0.2)
		local distFromTarget = (Vector3.new(hrp.Position.X, 0, hrp.Position.Z) - Vector3.new(itemPos.X, 0, itemPos.Z)).Magnitude
		local nearTarget = distFromTarget <= 50
		local hitWall = false
		
		pcall(function()
			local rayParams = RaycastParams.new()
			rayParams.FilterDescendantsInstances = {character}
			rayParams.FilterType = Enum.RaycastFilterType.Blacklist
			local rayOrigin = hrp.Position
			local rayDirection = hrp.CFrame.LookVector * 5
			local result = workspace:Raycast(rayOrigin, rayDirection, rayParams)
			if result then
				hitWall = true
			end
		end)
		
		if hitWall and nearTarget then
			local cloner = LocalPlayer.Backpack:FindFirstChild("Quantum Cloner")
			if cloner then
				local cloneSuccess = useQuantumClonerMapped()
				if cloneSuccess then
					task.wait(1.0)
					
					local newChar = LocalPlayer.Character
					if newChar and targetPetPart then
						local newHRP = newChar:FindFirstChild("HumanoidRootPart")
						if newHRP then
							local petPosition = targetPetPart.Position - Vector3.new(0, 3, 0)
							newHRP.AssemblyLinearVelocity = Vector3.zero
							newHRP.AssemblyAngularVelocity = Vector3.zero
							newHRP.CFrame = CFrame.new(petPosition.X, newHRP.Position.Y, petPosition.Z)
							newHRP.AssemblyLinearVelocity = Vector3.zero
							newHRP.AssemblyAngularVelocity = Vector3.zero
						end
					end
				end
			end
		end
		
		if humanoid then
			humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
			humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
			humanoid:SetStateEnabled(Enum.HumanoidStateType.Physics, true)
		end
		
		task.spawn(function()
			task.wait(1.5)
			_G.ATP_isTeleporting = false
		end)
	end
end
_G.ATP_TeleportToHighest = TeleportToHighest

task.spawn(function()
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if UserInputService:GetFocusedTextBox() then return end
		if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
		if input.KeyCode == (_G.ATP_ManualTPKey or Enum.KeyCode.Q) then
			if _G.ATP_isTeleporting then return end
			_G.ATP_isTeleporting = true
			pcall(function()
				if _G.ATP_TeleportToHighest then
					_G.ATP_TeleportToHighest(true)
				end
			end)
		end
	end)
end)

task.spawn(function()
	LocalPlayer.CharacterAdded:Connect(function(char)
		if not char then return end
		if not char:IsDescendantOf(workspace) then
			char.AncestryChanged:Wait()
		end
		local hum = char:WaitForChild("Humanoid", 5)
		if not hum then return end
		task.wait(0.1)
		pcall(function()
			local backpack = LocalPlayer:FindFirstChild("Backpack")
			if backpack and hum then
				local carpet = backpack:FindFirstChild(_G.TPSpeedItem or "Flying Carpet")
				if carpet then
					hum:EquipTool(carpet)
				end
			end
		end)
	end)
end)

task.spawn(function()
	local function onCharacterAdded(char)
		if not _G.ATP_autoTPButtonEnabled then return end
		if not char then return end
		if not char:IsDescendantOf(workspace) then
			char.AncestryChanged:Wait()
		end
		local hum = char:WaitForChild("Humanoid", 5)
		local hrp = char:WaitForChild("HumanoidRootPart", 5)
		if not hum or not hrp then return end
		if hum.Health <= 0 then return end
		
		for i = 1, 30 do
			local debris = workspace:FindFirstChild("Debris")
			if debris and #debris:GetChildren() > 0 then
				task.wait(0.3)
				break
			end
			task.wait(0.1)
		end
		
		if not _G.ATP_autoTPButtonEnabled then return end
		_G.ATP_isTeleporting = true
		pcall(function()
			if _G.ATP_TeleportToHighest then
				_G.ATP_TeleportToHighest()
			end
		end)
		task.delay(1.5, function()
			_G.ATP_isTeleporting = false
		end)
	end
	LocalPlayer.CharacterAdded:Connect(onCharacterAdded)
	
	if LocalPlayer.Character then
		onCharacterAdded(LocalPlayer.Character)
	end
end)

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AutoTPGui"
screenGui.ResetOnSpawn = false
pcall(function() screenGui.Parent = game:GetService("CoreGui") end)
if not screenGui.Parent then
	screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 140, 0, 46)
mainFrame.Position = UDim2.new(0, 10, 0.5, -23)
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = mainFrame

local mainBtn = Instance.new("TextButton")
mainBtn.Size = UDim2.new(1, -16, 0, 30)
mainBtn.Position = UDim2.new(0, 8, 0, 8)
mainBtn.BackgroundColor3 = _G.ATP_autoTPButtonEnabled and Color3.fromRGB(0, 140, 0) or Color3.fromRGB(80, 80, 80)
mainBtn.Text = _G.ATP_autoTPButtonEnabled and "AUTO TP [ON]" or "AUTO TP [OFF]"
mainBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
mainBtn.Font = Enum.Font.GothamBold
mainBtn.TextSize = 14
mainBtn.BorderSizePixel = 0
mainBtn.Parent = mainFrame

local mainBtnCorner = Instance.new("UICorner")
mainBtnCorner.CornerRadius = UDim.new(0, 6)
mainBtnCorner.Parent = mainBtn

mainBtn.MouseButton1Click:Connect(function()
	_G.ATP_autoTPButtonEnabled = not _G.ATP_autoTPButtonEnabled
	mainBtn.BackgroundColor3 = _G.ATP_autoTPButtonEnabled and Color3.fromRGB(0, 140, 0) or Color3.fromRGB(80, 80, 80)
	mainBtn.Text = _G.ATP_autoTPButtonEnabled and "AUTO TP [ON]" or "AUTO TP [OFF]"
	saveSettings()
end)

local dragging, dragInput, dragStart, startPos
mainFrame.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = mainFrame.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)
mainFrame.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		dragInput = input
	end
end)
UserInputService.InputChanged:Connect(function(input)
	if input == dragInput and dragging then
		local delta = input.Position - dragStart
		mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end)