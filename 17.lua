local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

--// =======================
--// AUTO-FIRE ON MANUAL EQUIP
--// =======================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
-- Ensure Event exists
local Event = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Net"):WaitForChild("RE/UseItem")
local currentTool = nil
local fireConnection = nil
local FIRE_INTERVAL = 0.1 -- firing speed
-- Function to fire the tool at a player
local function fireToolAtPlayer(tool, target)
    if not tool or not target or not target.Character then return end
    local hrp = target.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    if tool.Name == "Laser Cape" or tool.Name == "Web Slinger" then
        Event:FireServer(hrp.Position, hrp)
    elseif tool.Name == "Taser Gun" then
        Event:FireServer(hrp)
    elseif tool.Name == "Bee Launcher" then
        Event:FireServer(target)
    end
end
-- Get the closest player
local function getClosestPlayer()
    local char = player.Character
    if not char then return nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local closest, closestDist = nil, math.huge
    for _, other in ipairs(Players:GetPlayers()) do
        if other ~= player and other.Character then
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
-- Stop previous fire loop
local function stopAutoFire()
    if fireConnection then
        fireConnection:Disconnect()
        fireConnection = nil
    end
end
-- Start auto-fire for a tool
local function startAutoFire(tool)
    stopAutoFire()
    fireConnection = RunService.Heartbeat:Connect(function()
        if not tool or tool.Parent ~= player.Character then
            stopAutoFire()
            return
        end
        local target = getClosestPlayer()
        if target then
            fireToolAtPlayer(tool, target)
        end
    end)
end
-- Poll for currently equipped tool
RunService.Heartbeat:Connect(function()
    local char = player.Character
    if not char then return end
    local equippedTool = nil
    for _, item in ipairs(char:GetChildren()) do
        if item:IsA("Tool") then
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
-- PLAYER AURA TRACKER (ESP BOX + NAME)
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
        if adornee and adornee.Position.Y <= 7 then
            makeBillboard(adornee, obj)
        end
    end
end)
--// =======================
--// BEST-EARNING PET TRACKER (Enhanced)
--// =======================
-- CONFIG
local VALUE_THRESHOLD = 5e6 -- highlight pets earning ≥ 5M/sec
local WHITELIST_NAMES = { "Graipuss Medussi", "Nooo My Hotspot", "La Sahur Combinasion", "Pot Hotspot", "Chicleteira Bicicleteira"}
-- Helpers
local function parseMoney(text)
    text = string.lower(text or "")
    local num = tonumber(text:match("[%d%.]+")) or 0
    if text:find("k") then num *= 1e3
    elseif text:find("m") then num *= 1e6
    elseif text:find("b") then num *= 1e9
    elseif text:find("t") then num *= 1e12 end
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
local function isBlacklisted(obj)
    while obj do
        local name = string.lower(obj.Name or "")
        if name == "generationboard" or name:find("top") then return true end
        obj = obj.Parent
    end
    return false
end
local function findMainName(billboard)
    local bestText, bestLen
    for _, d in ipairs(billboard:GetDescendants()) do
        if d:IsA("TextLabel") then
            local t = d.Text or ""
            if not t:find("/s") and not t:find("%$") then
                if not bestLen or #t > bestLen then bestText, bestLen = t, #t end
            end
        end
    end
    return bestText
end
-- Detect Lucky Block (two-line text)
local function isLuckyBlock(billboard)
    local sawLucky, sawSecret = false, false
    for _, d in ipairs(billboard:GetDescendants()) do
        if d:IsA("TextLabel") then
            local t = string.lower(d.Text or "")
            if t:find("lucky block") then sawLucky = true end
            if t:find("secret") then sawSecret = true end
        end
    end
    return sawLucky and sawSecret
end
local function getModelForLabel(label)
    local bb = label:FindFirstAncestorWhichIsA("BillboardGui")
    if bb then
        if bb.Adornee and bb.Adornee:IsA("BasePart") then
            local m = bb.Adornee:FindFirstAncestorWhichIsA("Model")
            if m then return m end
        end
        if bb.Parent and bb.Parent:IsA("Model") then return bb.Parent end
    end
    return label:FindFirstAncestorWhichIsA("Model")
end
local function getAnyPart(model)
    if not model then return nil end
    return model.PrimaryPart or model:FindFirstChild("HumanoidRootPart") or model:FindFirstChildWhichIsA("BasePart")
end
-- Visuals
local tracked = {} -- model -> { highlight, billboard, label }
local function clearVisuals(model)
    if tracked[model] then
        for _, v in ipairs(tracked[model]) do
            if v and v.Destroy then v:Destroy() end
        end
        tracked[model] = nil
    end
end
local function setVisuals(model, part, name, value, kind)
    clearVisuals(model)
    local highlight = Instance.new("Highlight")
    highlight.Name = "PetHighlight_Client"
    if kind == "top" then
        highlight.FillColor = Color3.fromRGB(0,255,0) -- green
    elseif kind == "whitelist" then
        highlight.FillColor = Color3.fromRGB(0,128,255) -- blue
    elseif kind == "lucky" then
        highlight.FillColor = Color3.fromRGB(180,0,255) -- purple
    else -- threshold
        highlight.FillColor = Color3.fromRGB(255,215,0) -- gold
    end
    highlight.OutlineColor = Color3.fromRGB(255,255,255)
    highlight.FillTransparency = 0.5
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Adornee = model
    highlight.Parent = model
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Name = "PetBillboard_Client"
    billboardGui.Adornee = part
    billboardGui.Size = UDim2.new(0, 240, 0, (kind == "threshold") and 30 or 60)
    billboardGui.StudsOffset = Vector3.new(0, 6, 0)
    billboardGui.AlwaysOnTop = true
    billboardGui.MaxDistance = 1e6
    billboardGui.Parent = player:WaitForChild("PlayerGui")
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Font = Enum.Font.SourceSansBold
    textLabel.TextScaled = true
    textLabel.TextStrokeTransparency = 0
    textLabel.TextColor3 = highlight.FillColor
    textLabel.Parent = billboardGui
    if kind == "lucky" then
        textLabel.Text = "Lucky Block (Secret!)"
    elseif value then
        textLabel.Text = string.format("%s | $%s/s", name, abbreviate(value))
    else
        textLabel.Text = name
    end
    tracked[model] = { highlight, billboardGui, textLabel }
end
-- Update loop
local function updateBest()
    local bestLabel, bestValue = nil, -math.huge
    local extraList = {}
    for _, bb in ipairs(workspace:GetDescendants()) do
        if bb:IsA("BillboardGui") and not isBlacklisted(bb) then
            -- Lucky Block
            if isLuckyBlock(bb) then
                local model = bb:FindFirstAncestorWhichIsA("Model")
                local part = getAnyPart(model)
                if model and part then
                    table.insert(extraList, {model, part, "Lucky Block", nil, "lucky"})
                end
            end
            -- Pets with values
            for _, lbl in ipairs(bb:GetDescendants()) do
                if lbl:IsA("TextLabel") then
                    local text = lbl.Text or ""
                    if text:find("/s") and text:find("%$") then
                        local val = parseMoney(text)
                        local model = getModelForLabel(lbl)
                        local part = getAnyPart(model)
                        if model and part then
                            -- Track best
                            if val > bestValue then
                                bestValue = val
                                bestLabel = lbl
                            end
                            -- Whitelist
                            local petName = findMainName(bb) or model.Name
                            for _, w in ipairs(WHITELIST_NAMES) do
                                if petName == w then
                                    table.insert(extraList, {model, part, petName, val, "whitelist"})
                                end
                            end
                            -- Threshold
                            if val >= VALUE_THRESHOLD then
                                local petName = findMainName(bb) or model.Name
                                table.insert(extraList, {model, part, petName, val, "threshold"})
                            end
                        end
                    end
                end
            end
        end
    end
    -- Clear old
    for model in pairs(tracked) do
        clearVisuals(model)
    end
    -- Top pet
    if bestLabel then
        local model = getModelForLabel(bestLabel)
        local part = getAnyPart(model)
        if model and part then
            local petName = findMainName(bestLabel:FindFirstAncestorWhichIsA("BillboardGui")) or model.Name
            setVisuals(model, part, petName, bestValue, "top")
        end
    end
    -- Extras
    for _, entry in ipairs(extraList) do
        local model, part, name, val, kind = unpack(entry)
        if model and part and not tracked[model] then
            setVisuals(model, part, name, val, kind)
        end
    end
end
spawn(function()
    while true do
        updateBest()
        task.wait(1)
    end
end)
-- =======================
-- INFINITE JUMP
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
--- =======================
-- AUTO-RELOAD ON TELEPORT (Lean & Session-Only)
-- =======================
local ADMIN_RAW_URL = "https://raw.githubusercontent.com/thetoaster97/99123/refs/heads/main/16.lua" -- replace with your raw script URL
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
-- =======================
-- SERVERHOP BUTTON
-- =======================
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local player = game:GetService("Players").LocalPlayer
local placeId = game.PlaceId

-- Create button UI
local hopGui = Instance.new("ScreenGui")
hopGui.Name = "ServerHopGui"
hopGui.ResetOnSpawn = false
hopGui.Parent = player:WaitForChild("PlayerGui")

local hopButton = Instance.new("TextButton")
hopButton.Name = "ServerHopButton"
hopButton.Size = UDim2.new(0, 100, 0, 40)
hopButton.Position = UDim2.new(1, -110, 0, 10)
hopButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
hopButton.TextColor3 = Color3.fromRGB(255, 255, 255)
hopButton.Font = Enum.Font.SourceSansBold
hopButton.TextSize = 18
hopButton.Text = "ServerHop"
hopButton.Parent = hopGui

-- Safer server fetch
local function getServer()
	local servers = {}
	local cursor = nil
	local tries = 0

	repeat
		local url = ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100%s"):format(
			placeId,
			cursor and ("&cursor=" .. cursor) or ""
		)

		local success, result = pcall(function()
			return game:HttpGet(url)
		end)

		if success and result then
			local data = HttpService:JSONDecode(result)
			if data and data.data then
				for _, server in ipairs(data.data) do
					-- Skip servers missing info
					if type(server.playing) == "number" and type(server.maxPlayers) == "number" then
						if server.playing < server.maxPlayers and server.id ~= game.JobId then
							table.insert(servers, server.id)
						end
					end
				end
			end
			cursor = data.nextPageCursor
		else
			warn("⚠️ Failed to get server list.")
			break
		end

		tries += 1
	until #servers > 0 or not cursor or tries >= 3

	if #servers > 0 then
		return servers[math.random(1, #servers)]
	else
		return nil
	end
end

-- Button click
hopButton.MouseButton1Click:Connect(function()
	hopButton.Text = "Hopping..."
	hopButton.Active = false

	local serverId = getServer()
	if serverId then
		TeleportService:TeleportToPlaceInstance(placeId, serverId, player)
	else
		warn("⚠️ No valid servers found.")
		hopButton.Text = "ServerHop"
		hopButton.Active = true
	end
end)


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
-- Remove from every player already in game
for _, plr in ipairs(Players:GetPlayers()) do
    stripVisualItems(plr.Character)
end
-- Handle players that join later
Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(stripVisualItems)
end)
-- Handle your own respawn
player.CharacterAdded:Connect(stripVisualItems)
-- Initial clean-up for your own character
stripVisualItems(player.Character)


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

    -- Kick with the specific detected text
    local function triggerKick(foundText)
        local message = foundText or "you stole something!"
        player:Kick(message)
    end

    -- Scan a GuiObject and its descendants for "you stole"
    local function scanGuiObject(guiObj)
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
        task.wait(0.05)
        scanGuiObject(child)

        child.DescendantAdded:Connect(function(desc)
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
            if desc:IsA("TextLabel") or desc:IsA("TextButton") or desc:IsA("TextBox") then
                local foundText = getYouStoleText(desc.Text)
                if foundText then
                    triggerKick(foundText)
                end
            end
        end)
    end
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

--// =======================
--// RAGDOLL MOVEMENT CONTROLS (PC + Mobile)
--// =======================
do
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local UserInputService = game:GetService("UserInputService")

    local player = Players.LocalPlayer
    
    local function initRagdollControls()
        local character = player.Character or player.CharacterAdded:Wait()
        local humanoid = character:WaitForChild("Humanoid")
        local rootPart = character:WaitForChild("HumanoidRootPart")

        local isRagdolled = false
        local moveDirection = Vector2.new(0, 0)
        local platform = nil
        local bodyPos = nil
        local initialHeight = 0
        local moveSpeed = 39
        local motors = {}
        
        -- PC input tracking
        local pcInputs = {
            [Enum.KeyCode.W] = false,
            [Enum.KeyCode.A] = false,
            [Enum.KeyCode.S] = false,
            [Enum.KeyCode.D] = false,
        }

        -- Create GUI
        local screenGui = Instance.new("ScreenGui")
        screenGui.Name = "RagdollControls"
        screenGui.ResetOnSpawn = false
        screenGui.Parent = player:WaitForChild("PlayerGui")

        -- Joystick outer circle
        local joystickOuter = Instance.new("ImageLabel")
        joystickOuter.Name = "JoystickOuter"
        joystickOuter.Size = UDim2.new(0, 170, 0, 170)
        joystickOuter.Position = UDim2.new(0, 30, 1, -200)
        joystickOuter.BackgroundTransparency = 1
        joystickOuter.Image = "rbxasset://textures/ui/Joystick/Outline.png"
        joystickOuter.ImageTransparency = 0.3
        joystickOuter.Visible = false
        joystickOuter.Parent = screenGui

        -- Joystick inner circle
        local joystickInner = Instance.new("ImageLabel")
        joystickInner.Name = "JoystickInner"
        joystickInner.Size = UDim2.new(0, 70, 0, 70)
        joystickInner.Position = UDim2.new(0.5, -35, 0.5, -35)
        joystickInner.BackgroundTransparency = 1
        joystickInner.Image = "rbxasset://textures/ui/Joystick/Base.png"
        joystickInner.ImageTransparency = 0.2
        joystickInner.Parent = joystickOuter

        -- Jump button
        local jumpButton = Instance.new("ImageButton")
        jumpButton.Name = "JumpButton"
        jumpButton.Size = UDim2.new(0, 90, 0, 90)
        jumpButton.Position = UDim2.new(1, -120, 1, -120)
        jumpButton.BackgroundTransparency = 1
        jumpButton.Image = "rbxasset://textures/ui/Input/Buttons/jump@2x.png"
        jumpButton.ImageTransparency = 0.2
        jumpButton.Visible = false
        jumpButton.Parent = screenGui

        -- Joystick logic (mobile)
        local dragging = false
        local touchInput = nil

        local function updateJoystick(input)
            local center = joystickOuter.AbsolutePosition + joystickOuter.AbsoluteSize / 2
            local delta = Vector2.new(input.Position.X, input.Position.Y) - center
            local maxRadius = 50
            local distance = math.min(delta.Magnitude, maxRadius)
            local direction = delta.Magnitude > 0 and delta.Unit or Vector2.new(0, 0)
            
            if delta.Magnitude > 0 then
                joystickInner.Position = UDim2.new(0.5, direction.X * distance - 35, 0.5, direction.Y * distance - 35)
                moveDirection = direction * (distance / maxRadius)
            else
                joystickInner.Position = UDim2.new(0.5, -35, 0.5, -35)
                moveDirection = Vector2.new(0, 0)
            end
        end

        joystickOuter.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                touchInput = input
                updateJoystick(input)
            end
        end)

        joystickOuter.InputChanged:Connect(function(input)
            if dragging and input == touchInput then
                updateJoystick(input)
            end
        end)

        joystickOuter.InputEnded:Connect(function(input)
            if input == touchInput then
                dragging = false
                touchInput = nil
                joystickInner.Position = UDim2.new(0.5, -35, 0.5, -35)
                moveDirection = Vector2.new(0, 0)
            end
        end)

        UserInputService.InputChanged:Connect(function(input)
            if dragging and input == touchInput then
                updateJoystick(input)
            end
        end)

        UserInputService.InputEnded:Connect(function(input)
            if input == touchInput then
                dragging = false
                touchInput = nil
                joystickInner.Position = UDim2.new(0.5, -35, 0.5, -35)
                moveDirection = Vector2.new(0, 0)
            end
        end)

        -- PC keyboard input
        local function updatePCMovement()
            local x = 0
            local y = 0
            
            if pcInputs[Enum.KeyCode.W] then y = y - 1 end
            if pcInputs[Enum.KeyCode.S] then y = y + 1 end
            if pcInputs[Enum.KeyCode.A] then x = x - 1 end
            if pcInputs[Enum.KeyCode.D] then x = x + 1 end
            
            if x ~= 0 or y ~= 0 then
                moveDirection = Vector2.new(x, y).Unit
            else
                moveDirection = Vector2.new(0, 0)
            end
        end

        UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed then return end
            
            -- PC jump (Space)
            if input.KeyCode == Enum.KeyCode.Space and isRagdolled and rootPart then
                rootPart.AssemblyLinearVelocity = rootPart.AssemblyLinearVelocity + Vector3.new(0, 25, 0)
            end
            
            -- PC movement keys
            if pcInputs[input.KeyCode] ~= nil then
                pcInputs[input.KeyCode] = true
                updatePCMovement()
            end
        end)

        UserInputService.InputEnded:Connect(function(input, gameProcessed)
            if pcInputs[input.KeyCode] ~= nil then
                pcInputs[input.KeyCode] = false
                updatePCMovement()
            end
        end)

        -- Jump button (mobile)
        jumpButton.Activated:Connect(function()
            if isRagdolled and rootPart then
                rootPart.AssemblyLinearVelocity = rootPart.AssemblyLinearVelocity + Vector3.new(0, 25, 0)
            end
        end)

        -- Setup ragdoll
        local function setupRagdoll()
            if isRagdolled then return end
            isRagdolled = true
            print("hit")

            initialHeight = rootPart.Position.Y
            
            -- Show mobile controls on touch devices
            if UserInputService.TouchEnabled then
                joystickOuter.Visible = true
                jumpButton.Visible = true
            end

            bodyPos = Instance.new("BodyPosition")
            bodyPos.MaxForce = Vector3.new(0, 5000, 0)
            bodyPos.D = 800
            bodyPos.P = 5000
            bodyPos.Position = Vector3.new(rootPart.Position.X, initialHeight + 1, rootPart.Position.Z)
            bodyPos.Parent = rootPart

            platform = Instance.new("Part")
            platform.Size = Vector3.new(12, 1, 12)
            platform.Anchored = true
            platform.CanCollide = true
            platform.Transparency = 0.8
            platform.Material = Enum.Material.SmoothPlastic
            platform.Color = Color3.fromRGB(100, 100, 255)
            platform.Name = "RagdollPlatform"
            platform.Parent = workspace
            platform.Position = Vector3.new(rootPart.Position.X, initialHeight - 4, rootPart.Position.Z)
        end

        -- Cleanup
        local function cleanupRagdoll()
            if not isRagdolled then return end
            isRagdolled = false
            joystickOuter.Visible = false
            jumpButton.Visible = false
            
            -- Reset PC inputs
            for key in pairs(pcInputs) do
                pcInputs[key] = false
            end
            moveDirection = Vector2.new(0, 0)

            if bodyPos then
                bodyPos:Destroy()
                bodyPos = nil
            end

            if platform then
                platform:Destroy()
                platform = nil
            end

            print("hit ended")
        end

        -- Listen for ragdoll event
        local ragdollEvent = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Ragdoll"):WaitForChild("Ragdoll")
        ragdollEvent.OnClientEvent:Connect(function(arg1, arg2)
            if arg2 == "manualM" then
                setupRagdoll()
            end
        end)

        -- Find motors
        local function findMotors()
            motors = {}
            for _, desc in pairs(character:GetDescendants()) do
                if desc:IsA("Motor6D") then
                    table.insert(motors, desc)
                end
            end
        end

        -- Check ragdoll ended
        local function checkRagdollEnded()
            local enabledCount = 0
            for _, motor in pairs(motors) do
                if motor.Parent and motor.Enabled == true then
                    enabledCount = enabledCount + 1
                end
            end
            return enabledCount >= 3
        end

        findMotors()

        -- Movement loop
        RunService.Heartbeat:Connect(function()
            if not character or not character.Parent or humanoid.Health <= 0 then return end

            if isRagdolled and checkRagdollEnded() then
                cleanupRagdoll()
            end

            if isRagdolled then
                if bodyPos then
                    bodyPos.Position = Vector3.new(rootPart.Position.X, initialHeight + 1, rootPart.Position.Z)
                end

                if platform then
                    platform.Position = Vector3.new(rootPart.Position.X, initialHeight - 4, rootPart.Position.Z)
                end

                if moveDirection.Magnitude > 0 then
                    local camera = workspace.CurrentCamera
                    local camCF = camera.CFrame

                    local forward = camCF.LookVector
                    local right = camCF.RightVector

                    local moveX = right * moveDirection.X
                    local moveZ = forward * -moveDirection.Y

                    local finalDir = (moveX + moveZ)
                    local flatDir = Vector3.new(finalDir.X, 0, finalDir.Z).Unit

                    rootPart.Velocity = flatDir * moveSpeed
                else
                    rootPart.Velocity = Vector3.new(0, rootPart.Velocity.Y, 0)
                end
            end
        end)
    end

    -- Init on character
    if player.Character then
        initRagdollControls()
    end

    player.CharacterAdded:Connect(initRagdollControls)

    print("Anti-ragdoll loaded (PC + Mobile)")
end


-- ======================= 
-- DESYNC/ANTI-HIT SCRIPT 
-- ======================= 
local player = game.Players.LocalPlayer
local character = player.Character

-- Godmode Script First
if character then
    local humanoid = character:FindFirstChild("Humanoid")
    if humanoid then
        humanoid.MaxHealth = math.huge
        humanoid.Health = math.huge
        humanoid:GetPropertyChangedSignal("Health"):Connect(function()
            humanoid.Health = math.huge
        end)
    end
end

-- Desync/Remote Event Script
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local PhysicsService = game:GetService("PhysicsService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
local Humanoid = Character:WaitForChild("Humanoid")

local DESYNC_ENABLED = false
local FAKE_POSITION = nil
local CLIENT_POSITION = nil
local UPDATE_INTERVAL = 1.0
local lastUpdate = tick()
local OFFSET_RANGE = 4
local DEBOUNCE = false
local LAST_F_PRESS = 0
local DOUBLE_PRESS_THRESHOLD = 0.3

-- Server position visualizer
local serverPosBox = nil

-- Function to create/update server position box
local function createServerPosBox()
    if serverPosBox then
        serverPosBox:Destroy()
    end
    
    serverPosBox = Instance.new("Part")
    serverPosBox.Name = "ServerPositionBox"
    serverPosBox.Size = Vector3.new(4, 5, 3)
    serverPosBox.Transparency = 0.7
    serverPosBox.Color = Color3.fromRGB(255, 0, 0)
    serverPosBox.Material = Enum.Material.Neon
    serverPosBox.CanCollide = false
    serverPosBox.Anchored = true
    serverPosBox.Parent = workspace
    
    -- Add outline
    local selectionBox = Instance.new("SelectionBox")
    selectionBox.Adornee = serverPosBox
    selectionBox.LineThickness = 0.05
    selectionBox.Color3 = Color3.fromRGB(255, 255, 0)
    selectionBox.Parent = serverPosBox
    
    -- Add text label above box
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Size = UDim2.new(0, 200, 0, 50)
    billboardGui.StudsOffset = Vector3.new(0, 3, 0)
    billboardGui.AlwaysOnTop = true
    billboardGui.Parent = serverPosBox
    
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = "WHERE OTHERS SEE YOU"
    textLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
    textLabel.TextScaled = true
    textLabel.Font = Enum.Font.GothamBold
    textLabel.TextStrokeTransparency = 0
    textLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    textLabel.Parent = billboardGui
end

-- Function to update server position box
local function updateServerPosBox()
    if DESYNC_ENABLED and HumanoidRootPart and FAKE_POSITION then
        if not serverPosBox then
            createServerPosBox()
        end
        -- Show box at fake/server position
        serverPosBox.CFrame = FAKE_POSITION
        serverPosBox.Transparency = 0.5
    else
        if serverPosBox then
            serverPosBox.Transparency = 1
        end
    end
end

-- Create blur effect
local function createBlurEffect()
    local blurEffect = Instance.new("BlurEffect")
    blurEffect.Name = "FlingBlur"
    blurEffect.Size = 0
    blurEffect.Parent = game:GetService("Lighting")
    return blurEffect
end

local blurEffect = createBlurEffect()

-- Function to toggle blur
local function toggleSyncEffects(enabled)
    if enabled then
        -- Max blur
        local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local tween = TweenService:Create(blurEffect, tweenInfo, {Size = 50})
        tween:Play()
    else
        -- Remove blur
        local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local tween = TweenService:Create(blurEffect, tweenInfo, {Size = 0})
        tween:Play()
    end
end

-- Create GUI
local function createGUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "DesyncGUI"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    -- Start Button
    local startButton = Instance.new("TextButton")
    startButton.Size = UDim2.new(0, 100, 0, 40)
    startButton.Position = UDim2.new(0, 10, 0, 10)
    startButton.BackgroundColor3 = Color3.fromRGB(0, 100, 255)
    startButton.Text = "START"
    startButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    startButton.TextSize = 18
    startButton.Font = Enum.Font.GothamBold
    startButton.BorderSizePixel = 0
    startButton.Parent = screenGui
    
    local startCorner = Instance.new("UICorner")
    startCorner.CornerRadius = UDim.new(0, 8)
    startCorner.Parent = startButton
    
    screenGui.Parent = game:GetService("CoreGui")
    
    return screenGui, startButton
end

local gui, startBtn = createGUI()

-- First print statement
print("hello " .. LocalPlayer.DisplayName .. " if ur anti hit aint working anymore press the desync button or press f again ty")

-- Second print statement
print("TUTORIAL: just press the button then it should work IF IT DOSENT HERES AN TUTORIAL FOR PC NOT MOBILE IT SHOULD WORK IF U PRESS THE BUTTON IM SURE. PRESS F 2x if u dont wanna press the button then it should work too")

pcall(function()
    PhysicsService:RegisterCollisionGroup("NoCollide")
    PhysicsService:CollisionGroupSetCollidable("NoCollide", "Default", false)
end)

local function applyFFlags(enable)
    pcall(function()
        if enable then
            setfflag("WorldStepMax", "-1000000")
            setfflag("DFIntS2PhysicsSenderRate", "1")
            setfflag("DFIntAssemblyExtentsExpansionStudHundredth", "1000")
            setfflag("FFlagRakNetForceUseUnreliable", "True")
            setfflag("FFlagDebugDisableTelemetryV2Event", "True")
            setfflag("DFIntNetworkLatencyTolerance", "9999")
            setfflag("DFIntTaskSchedulerTargetFps", "1")
            setfflag("DFIntNetworkPhysicsSenderRate", "1")
            setfflag("DFIntNetworkPhysicsRate", "1")
            setfflag("DFIntCharacterCollisionUpdateRate", "1")
            setfflag("DFIntCharacterControllerUpdateRate", "1")
        else
            setfflag("WorldStepMax", "0")
            setfflag("DFIntS2PhysicsSenderRate", "60")
            setfflag("DFIntAssemblyExtentsExpansionStudHundredth", "0")
            setfflag("DFIntNetworkLatencyTolerance", "100")
            setfflag("DFIntTaskSchedulerTargetFps", "60")
            setfflag("DFIntNetworkPhysicsSenderRate", "60")
            setfflag("DFIntNetworkPhysicsRate", "60")
            setfflag("DFIntCharacterCollisionUpdateRate", "30")
            setfflag("DFIntCharacterControllerUpdateRate", "30")
        end
    end)
end

local function setClientOwnership()
    for _, part in pairs(Character:GetDescendants()) do
        if part:IsA("BasePart") then
            pcall(function()
                if DESYNC_ENABLED then
                    -- Don't modify ANY body parts - let them behave normally
                    -- Desync happens through FFlags, not part manipulation
                    part.Anchored = false
                else
                    part:SetNetworkOwner(LocalPlayer)
                    part.Anchored = false
                    part.CollisionGroup = "Default"
                    part.CanCollide = true
                    part.Massless = false
                end
            end)
        end
        -- Keep ALL welds and Motor6Ds completely untouched
    end
    
    pcall(function()
        sethiddenproperty(LocalPlayer, "SimulationRadius", 99999)
    end)
end

local function initializeDesync()
    if HumanoidRootPart then
        -- Set fake position ahead of time without moving anything
        FAKE_POSITION = HumanoidRootPart.CFrame * CFrame.new(
            math.random(-OFFSET_RANGE, OFFSET_RANGE),
            0,
            math.random(-OFFSET_RANGE, OFFSET_RANGE)
        )
        CLIENT_POSITION = nil -- Don't lock position
        
        -- Apply FFlags first before touching any parts
        applyFFlags(true)
        wait(0.1)
        
        -- Then gently adjust ownership without forcing positions
        setClientOwnership()
        createServerPosBox()
    end
end

local function toggleDesync()
    DESYNC_ENABLED = not DESYNC_ENABLED
    
    if DESYNC_ENABLED then
        initializeDesync()
    else
        applyFFlags(false)
        setClientOwnership()
        CLIENT_POSITION = nil -- Fix freeze bug
        
        pcall(function()
            Humanoid:ChangeState(Enum.HumanoidStateType.Running)
            Humanoid.PlatformStand = false
            Humanoid.Sit = false
            Humanoid.AutoRotate = true
        end)
        
        if serverPosBox then
            serverPosBox:Destroy()
            serverPosBox = nil
        end
    end
end

-- Function to check and equip Quantum Cloner tool
local function equipQuantumCloner()
    local equippedTool = Character:FindFirstChildOfClass("Tool")
    
    -- Check if Quantum Cloner is already equipped
    if equippedTool and equippedTool.Name == "Quantum Cloner" then
        print("Quantum Cloner is already equipped!")
        return true
    end
    
    -- Look for Quantum Cloner in backpack
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if backpack then
        local quantumCloner = backpack:FindFirstChild("Quantum Cloner")
        if quantumCloner then
            print("Equipping Quantum Cloner from backpack...")
            Humanoid:EquipTool(quantumCloner)
            wait(0.2) -- Wait for equip to complete
            return true
        end
    end
    
    warn("Quantum Cloner tool not found in backpack!")
    return false
end

-- ONLY USE REMOTE EVENT - NO FLINGING AT ALL
local function fireQuantumTeleport()
    if not Character or not HumanoidRootPart then return end
    
    toggleSyncEffects(true)
    
    -- Check and equip Quantum Cloner if needed
    if equipQuantumCloner() then
        -- Fire UseItem event first
        local UseItemEvent = game:GetService("ReplicatedStorage").Packages.Net["RE/UseItem"]
        UseItemEvent:FireServer()
        print("Fired UseItem event!")
        
        wait(0.1)
        
        -- Fire the QuantumCloner teleport event
        local TeleportEvent = game:GetService("ReplicatedStorage").Packages.Net["RE/QuantumCloner/OnTeleport"]
        TeleportEvent:FireServer()
        print("Fired QuantumCloner teleport event!")
    else
        warn("Cannot fire events - Quantum Cloner not equipped!")
    end
    
    -- Brief wait for server to process
    wait(0.3)
    toggleSyncEffects(false)
end

-- Auto F spam function - Fire remote event FIRST, then 2x desync toggles
local function spamF()
    -- Check and equip Quantum Cloner if needed
    if equipQuantumCloner() then
        -- FIRE UseItem EVENT FIRST
        local UseItemEvent = game:GetService("ReplicatedStorage").Packages.Net["RE/UseItem"]
        UseItemEvent:FireServer()
        print("Fired UseItem event FIRST!")
        
        wait(0.1)
        
        -- FIRE TELEPORT EVENT
        local TeleportEvent = game:GetService("ReplicatedStorage").Packages.Net["RE/QuantumCloner/OnTeleport"]
        TeleportEvent:FireServer()
        print("Fired QuantumCloner teleport event!")
    else
        warn("Cannot fire events - Quantum Cloner not equipped!")
    end
    
    wait(0.5)
    
    -- Then do the desync toggles
    for i = 1, 2 do
        if not DEBOUNCE then
            DEBOUNCE = true
            toggleDesync()
            wait(1)
            DEBOUNCE = false
        end
    end
end

-- Button Connection
startBtn.MouseButton1Click:Connect(function()
    spamF()
end)

RunService.RenderStepped:Connect(function()
    if not DESYNC_ENABLED or not Character or not HumanoidRootPart then
        return
    end
    
    -- Minimal interference - just keep character responsive
    pcall(function()
        Humanoid.PlatformStand = false
        Humanoid.Sit = false
        HumanoidRootPart.Anchored = false
    end)
    
    -- Update server position box
    updateServerPosBox()
end)

RunService.Heartbeat:Connect(function()
    if not DESYNC_ENABLED or not Character or not HumanoidRootPart or not FAKE_POSITION then
        return
    end
    
    if tick() - lastUpdate >= UPDATE_INTERVAL then
        pcall(function()
            -- Update fake position to follow player smoothly
            local currentPos = HumanoidRootPart.Position
            local distance = (currentPos - FAKE_POSITION.Position).Magnitude
            
            -- Keep fake position closer and update less frequently
            if distance > OFFSET_RANGE * 3 then
                FAKE_POSITION = CFrame.new(currentPos) * CFrame.new(
                    math.random(-OFFSET_RANGE, OFFSET_RANGE),
                    0,
                    math.random(-OFFSET_RANGE, OFFSET_RANGE)
                )
            end
            
            -- DON'T move any body parts at all - let desync happen naturally through FFlags
            -- Only visual indicator (server box) shows the desync
        end)
        
        lastUpdate = tick()
    end
end)

-- Monitor for new parts/welds being added
Character.DescendantAdded:Connect(function(descendant)
    if not DESYNC_ENABLED then return end
    
    task.wait(0.1)
    pcall(function()
        if descendant:IsA("BasePart") then
            descendant.Anchored = false
        end
        -- Don't disable any welds or constraints
    end)
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed or DEBOUNCE or input.KeyCode ~= Enum.KeyCode.F then
        return
    end
    
    local currentTime = tick()
    
    if currentTime - LAST_F_PRESS <= DOUBLE_PRESS_THRESHOLD then
        if not DEBOUNCE then
            DEBOUNCE = true
            fireQuantumTeleport()
            wait(0.5)
            DEBOUNCE = false
        end
    else
        if not DEBOUNCE then
            DEBOUNCE = true
            toggleDesync()
            wait(0.3)
            DEBOUNCE = false
        end
    end
    
    LAST_F_PRESS = currentTime
end)

LocalPlayer.CharacterAdded:Connect(function(newChar)
    Character = newChar
    HumanoidRootPart = newChar:WaitForChild("HumanoidRootPart")
    Humanoid = newChar:WaitForChild("Humanoid")
    
    -- Reapply godmode on respawn
    if Humanoid then
        Humanoid.MaxHealth = math.huge
        Humanoid.Health = math.huge
        Humanoid:GetPropertyChangedSignal("Health"):Connect(function()
            Humanoid.Health = math.huge
        end)
    end
    
    if DESYNC_ENABLED then
        wait(1)
        initializeDesync()
    end
end)

-- Clean up effects when script ends
game:GetService("Lighting").ChildRemoved:Connect(function(child)
    if child.Name == "FlingBlur" then
        blurEffect = createBlurEffect()
    end
end)

-- Recreate GUI if removed
game:GetService("CoreGui").ChildRemoved:Connect(function(child)
    if child.Name == "DesyncGUI" then
        gui, startBtn = createGUI()
        
        -- Reconnect button
        startBtn.MouseButton1Click:Connect(function()
            spamF()
        end)
    end
end)

--// =======================
--// SILENT BEST PET TRACKER + AUTO GRAPPLE
--// =======================

do
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local PathfindingService = game:GetService("PathfindingService")
    local player = Players.LocalPlayer

    local GRAPPLE_SPEED = 150
    local GRAPPLE_TOOL_NAME = "Grapple Hook"
    local STOP_DISTANCE = 25
    local SMOOTH_RADIUS = 80
    local STUCK_THRESHOLD = 3
    local STUCK_TIME_LIMIT = 2

    local function parseMoney(text)
        text = string.lower(text or "")
        local num = tonumber(text:match("[%d%.]+")) or 0
        if text:find("k") then num *= 1e3
        elseif text:find("m") then num *= 1e6
        elseif text:find("b") then num *= 1e9
        elseif text:find("t") then num *= 1e12 end
        return num
    end

    local function isBlacklisted(obj)
        while obj do
            local name = string.lower(obj.Name or "")
            if name == "generationboard" or name:find("top") then return true end
            obj = obj.Parent
        end
        return false
    end

    local function getModelForLabel(label)
        local bb = label:FindFirstAncestorWhichIsA("BillboardGui")
        if bb then
            if bb.Adornee and bb.Adornee:IsA("BasePart") then
                local m = bb.Adornee:FindFirstAncestorWhichIsA("Model")
                if m then return m end
            end
            if bb.Parent and bb.Parent:IsA("Model") then return bb.Parent end
        end
        return label:FindFirstAncestorWhichIsA("Model")
    end

    local function getAnyPart(model)
        if not model then return nil end
        return model.PrimaryPart or model:FindFirstChild("HumanoidRootPart") or model:FindFirstChildWhichIsA("BasePart")
    end

    local currentPart = nil
    local currentWaypoints = {}
    local currentWaypointIndex = 1
    local lastPosition = nil
    local stuckTimer = 0
    local lastDistanceToTarget = math.huge

    local function updateBest()
        local bestLabel, bestValue = nil, -math.huge

        for _, bb in ipairs(workspace:GetDescendants()) do
            if bb:IsA("BillboardGui") and not isBlacklisted(bb) then
                for _, lbl in ipairs(bb:GetDescendants()) do
                    if lbl:IsA("TextLabel") then
                        local text = lbl.Text or ""
                        if text:find("/s") and text:find("%$") then
                            local val = parseMoney(text)
                            if val > bestValue then
                                bestValue = val
                                bestLabel = lbl
                            end
                        end
                    end
                end
            end
        end

        if not bestLabel then
            currentPart = nil
            return
        end

        local model = getModelForLabel(bestLabel)
        local part = getAnyPart(model)
        if not (model and part) then
            currentPart = nil
            return
        end

        currentPart = part
    end

    local grappleLine

    local function createGrappleLine(startPos, endPos)
        if grappleLine then grappleLine:Destroy() end
        
        local distance = (endPos - startPos).Magnitude
        local midpoint = (startPos + endPos) / 2
        
        grappleLine = Instance.new("Part")
        grappleLine.Anchored = true
        grappleLine.CanCollide = false
        grappleLine.Size = Vector3.new(0.2, 0.2, distance)
        grappleLine.CFrame = CFrame.lookAt(midpoint, endPos) * CFrame.new(0, 0, -distance / 2)
        grappleLine.BrickColor = BrickColor.new("Bright green")
        grappleLine.Material = Enum.Material.Neon
        grappleLine.Parent = workspace
    end

    local function clearGrappleLine()
        if grappleLine then
            grappleLine:Destroy()
            grappleLine = nil
        end
    end

    local character = player.Character or player.CharacterAdded:Wait()
    local humanoid = character:WaitForChild("Humanoid")

    local grappleMovementConnection = nil
    local isAutoGrappling = false

    local function findGrappleInBackpack()
        local backpack = player:FindFirstChild("Backpack")
        if backpack then
            return backpack:FindFirstChild(GRAPPLE_TOOL_NAME)
        end
        return nil
    end

    local function isGrappleEquipped()
        if character then
            local tool = character:FindFirstChild(GRAPPLE_TOOL_NAME)
            if tool and tool:IsA("Tool") then return true end
        end
        return false
    end

    local function findPathAroundWalls(startPos, endPos)
        local raycastParams = RaycastParams.new()
        raycastParams.FilterType = Enum.RaycastFilterType.Exclude
        raycastParams.FilterDescendantsInstances = {character}
        
        local direction = (endPos - startPos)
        local distance = direction.Magnitude
        local segments = math.ceil(distance / 8)
        local waypoints = {}
        
        local lastValidPos = startPos
        
        for i = 0, segments do
            local t = i / segments
            local testPos = startPos:Lerp(endPos, t)
            
            local checkResult = workspace:Raycast(lastValidPos, testPos - lastValidPos, raycastParams)
            
            if checkResult then
                local hitNormal = checkResult.Normal
                local hitPos = checkResult.Position
                
                local sidewaysOffset1 = Vector3.new(-hitNormal.Z, 0, hitNormal.X).Unit * 10
                local sidewaysOffset2 = Vector3.new(hitNormal.Z, 0, -hitNormal.X).Unit * 10
                
                local option1 = hitPos + sidewaysOffset1 + Vector3.new(0, 5, 0)
                local option2 = hitPos + sidewaysOffset2 + Vector3.new(0, 5, 0)
                
                local dist1 = (option1 - endPos).Magnitude
                local dist2 = (option2 - endPos).Magnitude
                
                local betterPos = dist1 < dist2 and option1 or option2
                
                table.insert(waypoints, {
                    Position = betterPos,
                    Action = Enum.PathWaypointAction.Walk
                })
                
                lastValidPos = betterPos
            else
                table.insert(waypoints, {
                    Position = testPos,
                    Action = Enum.PathWaypointAction.Walk
                })
                lastValidPos = testPos
            end
        end
        
        if #waypoints == 0 then
            table.insert(waypoints, {
                Position = endPos,
                Action = Enum.PathWaypointAction.Walk
            })
        end
        
        return waypoints
    end

    local function computePath(startPos, endPos)
        local path = PathfindingService:CreatePath({
            AgentRadius = 3,
            AgentHeight = 6,
            AgentCanJump = true,
            AgentCanClimb = false,
            WaypointSpacing = 4,
            Costs = {
                Water = 20,
                Danger = math.huge
            }
        })
        
        local success, errorMsg = pcall(function()
            path:ComputeAsync(startPos, endPos)
        end)
        
        if success and path.Status == Enum.PathStatus.Success then
            return path:GetWaypoints()
        end
        
        return nil
    end

    local function isStuck(rootPart)
        if not lastPosition then
            lastPosition = rootPart.Position
            stuckTimer = 0
            return false
        end
        
        local currentDistance = (rootPart.Position - lastPosition).Magnitude
        
        if currentDistance < STUCK_THRESHOLD then
            stuckTimer = stuckTimer + 0.1
        else
            stuckTimer = 0
            lastPosition = rootPart.Position
        end
        
        return stuckTimer >= STUCK_TIME_LIMIT
    end

    local function isGettingCloser(rootPart, targetPos)
        local currentDistance = (rootPart.Position - targetPos).Magnitude
        
        if currentDistance < lastDistanceToTarget - 2 then
            lastDistanceToTarget = currentDistance
            return true
        elseif currentDistance > lastDistanceToTarget + 5 then
            return false
        end
        
        lastDistanceToTarget = currentDistance
        return true
    end

    local function grappleToPet()
        if not currentPart or not character or not character:FindFirstChild("HumanoidRootPart") then
            clearGrappleLine()
            return
        end
        
        local rootPart = character.HumanoidRootPart
        local targetPos = currentPart.Position + Vector3.new(0, 7, 0)
        local currentPos = rootPart.Position
        
        createGrappleLine(currentPos, currentPart.Position)
        
        local horizontalDistance = math.sqrt(
            (targetPos.X - currentPos.X)^2 + 
            (targetPos.Z - currentPos.Z)^2
        )
        
        if horizontalDistance < STOP_DISTANCE then
            rootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            isAutoGrappling = false
            clearGrappleLine()
            
            local tool = character:FindFirstChild(GRAPPLE_TOOL_NAME)
            if tool and tool:IsA("Tool") then
                humanoid:UnequipTools()
            end
            
            if button then
                button.Text = "Grapple to Brainrot"
                button.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
            end
            return
        end
        
        if isStuck(rootPart) or not isGettingCloser(rootPart, targetPos) then
            warn("Stuck or can't get closer - stopping")
            rootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            isAutoGrappling = false
            clearGrappleLine()
            
            local tool = character:FindFirstChild(GRAPPLE_TOOL_NAME)
            if tool and tool:IsA("Tool") then
                humanoid:UnequipTools()
            end
            
            if button then
                button.Text = "Grapple to Brainrot"
                button.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
            end
            
            stuckTimer = 0
            lastPosition = nil
            lastDistanceToTarget = math.huge
            return
        end
        
        if not currentWaypoints or #currentWaypoints == 0 or currentWaypointIndex > #currentWaypoints then
            currentWaypoints = computePath(currentPos, targetPos)
            currentWaypointIndex = 1
            
            if not currentWaypoints then
                local direction = (targetPos - currentPos).Unit
                rootPart.AssemblyLinearVelocity = direction * GRAPPLE_SPEED
                return
            end
        end
        
        if currentWaypoints and currentWaypointIndex <= #currentWaypoints then
            local waypoint = currentWaypoints[currentWaypointIndex]
            local waypointPos = waypoint.Position
            local distanceToWaypoint = (waypointPos - currentPos).Magnitude
            
            if distanceToWaypoint < 5 then
                currentWaypointIndex = currentWaypointIndex + 1
                if currentWaypointIndex > #currentWaypoints then
                    currentWaypoints = nil
                end
            end
            
            local direction = (waypointPos - currentPos).Unit
            rootPart.AssemblyLinearVelocity = direction * GRAPPLE_SPEED
        end
        
        isAutoGrappling = true
    end

    local function startGrappleMovementLoop()
        if grappleMovementConnection then grappleMovementConnection:Disconnect() end
        
        grappleMovementConnection = RunService.Heartbeat:Connect(function()
            if isAutoGrappling then
                grappleToPet()
            end
        end)
    end

    local function stopGrappling()
        isAutoGrappling = false
        if character and character:FindFirstChild("HumanoidRootPart") then
            character.HumanoidRootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        end
        clearGrappleLine()
        currentWaypoints = {}
        currentWaypointIndex = 1
        stuckTimer = 0
        lastPosition = nil
        lastDistanceToTarget = math.huge
        
        local tool = character:FindFirstChild(GRAPPLE_TOOL_NAME)
        if tool and tool:IsA("Tool") then
            humanoid:UnequipTools()
        end
        
        if button then
            button.Text = "Grapple to Brainrot"
            button.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
        end
    end

    local function startGrappling()
        if isAutoGrappling then
            stopGrappling()
            return
        end
        
        if not isGrappleEquipped() then
            local grappleTool = findGrappleInBackpack()
            if grappleTool then
                humanoid:EquipTool(grappleTool)
                task.wait(0.3)
            else
                warn("Grapple Hook not found in backpack")
                return
            end
        end
        
        if not currentPart then
            warn("No best pet found")
            return
        end
        
        currentWaypoints = {}
        currentWaypointIndex = 1
        lastPosition = nil
        stuckTimer = 0
        lastDistanceToTarget = math.huge
        isAutoGrappling = true
    end

    local playerGui = player:WaitForChild("PlayerGui")
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "GrappleGui"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 150, 0, 50)
    frame.Position = UDim2.new(0.5, -75, 0.1, 0)
    frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    frame.BorderSizePixel = 2
    frame.BorderColor3 = Color3.fromRGB(0, 255, 0)
    frame.Active = true
    frame.Draggable = true
    frame.Parent = screenGui

    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -10, 1, -10)
    button.Position = UDim2.new(0, 5, 0, 5)
    button.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
    button.BorderSizePixel = 0
    button.Font = Enum.Font.SourceSansBold
    button.TextSize = 18
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Text = "Grapple to Brainrot"
    button.Parent = frame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame

    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 6)
    buttonCorner.Parent = button

    button.MouseButton1Click:Connect(function()
        if isAutoGrappling then
            stopGrappling()
        else
            button.Text = "Stop Grapple"
            button.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
            startGrappling()
        end
    end)

    local function initialize()
        startGrappleMovementLoop()
    end

    local function onCharacterAdded(newCharacter)
        character = newCharacter
        humanoid = character:WaitForChild("Humanoid")
        isAutoGrappling = false
        
        if grappleMovementConnection then grappleMovementConnection:Disconnect() grappleMovementConnection = nil end
        
        clearGrappleLine()
        currentWaypoints = {}
        currentWaypointIndex = 1
        stuckTimer = 0
        lastPosition = nil
        lastDistanceToTarget = math.huge
        button.Text = "Grapple to Brainrot"
        button.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
        
        task.wait(1)
        initialize()
    end

    player.CharacterAdded:Connect(onCharacterAdded)

    if character and character.Parent then
        initialize()
    end

    task.spawn(function()
        while true do
            updateBest()
            task.wait(1)
        end
    end)

    Players.PlayerRemoving:Connect(function(plr)
        if plr == player then
            if grappleMovementConnection then grappleMovementConnection:Disconnect() end
            clearGrappleLine()
        end
    end)
end

--// =======================
--// LOCKED TOOL BUTTON (Top-Left)
--// =======================
do
    local player = game:GetService("Players").LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local RunService = game:GetService("RunService")
    local TOOL_NAME = "All Seeing Sentry"
    local Event = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Net"):WaitForChild("RE/UseItem")

    local screenGui = Instance.new("ScreenGui", playerGui)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 150, 0, 35)
    button.Position = UDim2.new(0, 140, 0, 20) -- top-left, slightly right
    button.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Font = Enum.Font.SourceSansBold
    button.TextSize = 16
    button.Text = "Defense"
    button.Parent = screenGui
    button.AutoButtonColor = true
    button.MouseEnter:Connect(function() button.BackgroundColor3 = Color3.fromRGB(60, 60, 60) end)
    button.MouseLeave:Connect(function() button.BackgroundColor3 = Color3.fromRGB(40, 40, 40) end)

    local lockedTool = nil
    local lockEnabled = false
    local active = false

    local function equipTool()
        local character = player.Character
        if not character then return end
        local humanoid = character:FindFirstChild("Humanoid")
        if not humanoid then return end

        local tool = character:FindFirstChild(TOOL_NAME) or player.Backpack:FindFirstChild(TOOL_NAME)
        if tool then
            tool.Parent = character
            humanoid:EquipTool(tool)
            lockedTool = tool
            lockEnabled = true
        end
    end

    local function forceEquipLoop()
        spawn(function()
            while active and lockedTool do
                local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
                if humanoid and humanoid:FindFirstChildOfClass("Tool") ~= lockedTool then
                    lockedTool.Parent = player.Character
                    humanoid:EquipTool(lockedTool)
                end
                task.wait(0.01)
            end
        end)
    end

    local function monitorSentry()
        local conn
        conn = workspace.ChildAdded:Connect(function(child)
            if child.Name == "Sentry_"..player.UserId then
                active = false
                lockEnabled = false
                lockedTool = nil
                button.Text = "Defense"
                conn:Disconnect()
            end
        end)
    end

    local function startAutoUse()
        active = true
        equipTool()
        monitorSentry()
        forceEquipLoop()

        spawn(function()
            while active do
                Event:FireServer()
                task.wait(0)
            end
        end)
    end

    button.MouseButton1Click:Connect(function()
        if not active then
            button.Text = "Running..."
            startAutoUse()
        else
            active = false
            lockEnabled = false
            lockedTool = nil
            button.Text = "Defense"
        end
    end)
end

-- =======================
-- SENTRY PULLER
-- =======================
do
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local player = Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    local handledSentries = {}
    local distanceInFront = 6
    local activeSentry
    local swinging = false
    local followConnection
    
    -- Find one unhandled sentry
    local function findSentry()
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj.Name:lower():match("^sentry_") and (obj:IsA("BasePart") or obj:IsA("Model")) then
                if not handledSentries[obj] then
                    return obj
                end
            end
        end
        return nil
    end
    
    -- Disable sentry scripts
    local function disableSentryTargeting(sentry)
        for _, scr in pairs(sentry:GetDescendants()) do
            if scr:IsA("Script") or scr:IsA("LocalScript") then
                scr.Disabled = true
            end
        end
    end
    
    -- Make sentry parts non-collidable
    local function makeNonCollidable(sentry)
        for _, part in pairs(sentry:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
    
    -- Equip Bat and swing once (non-blocking)
    local function equipAndSwingBat()
        if swinging then return end
        swinging = true
        spawn(function()
            local backpack = player:FindFirstChildOfClass("Backpack")
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if not (backpack and humanoid) then 
                swinging = false 
                return 
            end
            local bat = backpack:FindFirstChild("Bat") or character:FindFirstChild("Bat")
            if bat then
                humanoid:EquipTool(bat)
                task.wait(0.15)
                if bat.Activate then bat:Activate() end
                task.wait(0.9) -- allow swing to register
                humanoid:UnequipTools()
            end
            swinging = false
        end)
    end
    
    -- Wait for 60s label
    local function waitFor60sLabel(sentry)
        local timeout, elapsed = 10, 0
        while elapsed < timeout and sentry.Parent do
            for _, d in pairs(sentry:GetDescendants()) do
                if d:IsA("TextLabel") or d:IsA("TextButton") then
                    local txt = string.lower(d.Text or "")
                    if txt:find("60s") then
                        return true
                    end
                end
            end
            task.wait(0.3)
            elapsed += 0.3
        end
        return false
    end
    
    -- Pull sentry to player and follow perfectly
    local function pullSentryToPlayer(sentry)
        if not (sentry and humanoidRootPart) then return end
        activeSentry = sentry
        makeNonCollidable(sentry)
        
        -- instant first position
        local frontCFrame = humanoidRootPart.CFrame * CFrame.new(0, 0, -distanceInFront)
        if sentry:IsA("Model") and sentry.PrimaryPart then
            sentry:SetPrimaryPartCFrame(frontCFrame)
        elseif sentry:IsA("BasePart") then
            sentry.CFrame = frontCFrame
        end
        
        -- swing bat immediately (non-blocking)
        equipAndSwingBat()
        
        -- follow sentry every frame
        if followConnection then followConnection:Disconnect() end
        followConnection = RunService.RenderStepped:Connect(function()
            if not activeSentry or not activeSentry.Parent or not humanoidRootPart.Parent then
                if followConnection then followConnection:Disconnect() end
                return
            end
            local targetCFrame = humanoidRootPart.CFrame * CFrame.new(0, 0, -distanceInFront)
            if activeSentry:IsA("Model") and activeSentry.PrimaryPart then
                activeSentry:SetPrimaryPartCFrame(targetCFrame)
            elseif activeSentry:IsA("BasePart") then
                activeSentry.CFrame = targetCFrame
            end
        end)
    end
    
    -- Main loop
    task.spawn(function()
        while true do
            local sentry = findSentry()
            if sentry then
                handledSentries[sentry] = true
                disableSentryTargeting(sentry)
                if waitFor60sLabel(sentry) then
                    pullSentryToPlayer(sentry)
                end
            end
            task.wait(0.4)
        end
    end)
end