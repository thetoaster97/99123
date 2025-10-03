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
local ADMIN_RAW_URL = "https://raw.githubusercontent.com/thetoaster97/99123/refs/heads/main/12.lua" -- replace with your raw script URL
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
-- Create simple button UI
local hopGui = Instance.new("ScreenGui")
hopGui.Name = "ServerHopGui"
hopGui.ResetOnSpawn = false
hopGui.Parent = player:WaitForChild("PlayerGui")
local hopButton = Instance.new("TextButton")
hopButton.Name = "ServerHopButton"
hopButton.Size = UDim2.new(0, 100, 0, 40)
hopButton.Position = UDim2.new(1, -110, 0, 10) -- top-right
hopButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
hopButton.TextColor3 = Color3.fromRGB(255, 255, 255)
hopButton.Font = Enum.Font.SourceSansBold
hopButton.TextSize = 18
hopButton.Text = "ServerHop"
hopButton.Parent = hopGui
-- Function to find a new server
local function getServer()
    local servers = {}
    local req = game:HttpGet(
        ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100"):format(placeId)
    )
    local data = HttpService:JSONDecode(req)
    if data and data.data then
        for _, server in ipairs(data.data) do
            if server.playing < server.maxPlayers and server.id ~= game.JobId then
                table.insert(servers, server.id)
            end
        end
    end
    if #servers > 0 then
        return servers[math.random(1, #servers)]
    else
        return nil
    end
end
-- Button click = serverhop
hopButton.MouseButton1Click:Connect(function()
    local serverId = getServer()
    if serverId then
        TeleportService:TeleportToPlaceInstance(placeId, serverId, player)
    else
        warn("⚠️ No available servers found to hop into.")
    end
end)
print("✅ ServerHop button loaded.")
--// =======================
--// BULLETPROOF NOCLIP CAMERA (IMMUNE TO BOOGIE BOMB)
--// =======================
local UserInputService = game:GetService("UserInputService")
local camera = workspace.CurrentCamera
local player = Players.LocalPlayer
-- Camera settings
local minZoom, maxZoom = 5, 25
local zoom = 12
local yaw, pitch = 0, 0
local rotationSensitivity = 0.5
local zoomSensitivity = 0.15
-- Joystick area (ignore touches here)
local screenSize = camera.ViewportSize
local joystickArea = Rect.new(0, screenSize.Y - 250, 250, screenSize.Y)
-- Safe state
local targetCFrame = camera.CFrame
local lastRootPosition = Vector3.new(0, 0, 0)
-- Force camera to scriptable always
local function initializeCamera()
    camera.CameraType = Enum.CameraType.Scriptable
    camera.CameraSubject = nil
    camera.FieldOfView = 70
end
-- Get root with fallback
local function getRoot()
    local char = player.Character
    if not char then return nil end
    local root = char:FindFirstChild("HumanoidRootPart")
    if root then
        lastRootPosition = root.Position
        return root
    end
    return {Position = lastRootPosition}
end
-- Touch handling
local touches, activeTouches = {}, 0
local function isInJoystickArea(position)
    return position.X >= joystickArea.Min.X and position.X <= joystickArea.Max.X and
           position.Y >= joystickArea.Min.Y and position.Y <= joystickArea.Max.Y
end
local function updateActiveTouches()
    activeTouches = 0
    for _ in pairs(touches) do activeTouches += 1 end
end
UserInputService.TouchStarted:Connect(function(input)
    if isInJoystickArea(input.Position) then return end
    touches[input] = input.Position
    updateActiveTouches()
end)
UserInputService.TouchEnded:Connect(function(input)
    touches[input] = nil
    updateActiveTouches()
end)
UserInputService.TouchMoved:Connect(function(input)
    if not touches[input] then return end
    if activeTouches == 1 then
        local delta = input.Delta
        yaw -= delta.X * rotationSensitivity
        pitch = math.clamp(pitch - delta.Y * rotationSensitivity, -80, 80)
    elseif activeTouches == 2 then
        local activeList = {}
        for t in pairs(touches) do table.insert(activeList, t) end
        if #activeList >= 2 then
            local oldDist = (touches[activeList[1]] - touches[activeList[2]]).Magnitude
            local newDist = (activeList[1].Position - activeList[2].Position).Magnitude
            local diff = newDist - oldDist
            zoom = math.clamp(zoom - diff * zoomSensitivity, minZoom, maxZoom)
        end
    end
    touches[input] = input.Position
end)
-- Camera math
local function calculateCameraPosition()
    local root = getRoot()
    if not root then return targetCFrame end
    local headOffset = Vector3.new(0, 2, 0)
    local rotation = CFrame.Angles(0, math.rad(yaw), 0) * CFrame.Angles(math.rad(pitch), 0, 0)
    local camPos = root.Position + headOffset - rotation.LookVector * zoom
    return CFrame.new(camPos, root.Position + headOffset)
end
-- Update loop
local function protectAndUpdateCamera()
    if camera.CameraType ~= Enum.CameraType.Scriptable then
        camera.CameraType = Enum.CameraType.Scriptable
    end
    if camera.CameraSubject ~= nil then
        camera.CameraSubject = nil
    end
    local newCFrame = calculateCameraPosition()
    targetCFrame = newCFrame
    camera.CFrame = newCFrame
    camera.Focus = newCFrame
end
-- Init
initializeCamera()
RunService.RenderStepped:Connect(protectAndUpdateCamera)
RunService.Heartbeat:Connect(protectAndUpdateCamera)
-- Reset key
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.R then
        initializeCamera()
        yaw, pitch, zoom = 0, 0, 12
    end
end)
player.CharacterAdded:Connect(function()
    task.wait(0.5)
    initializeCamera()
    local root = getRoot()
    if root then lastRootPosition = root.Position end
end)
print("🛡️ Bulletproof noclip camera active")
-- =======================
-- AUTO-SPLATTERSLAP MAGNET ATTACKER (BLOCK)
-- =======================
do
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local player = Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local hrp = character:WaitForChild("HumanoidRootPart")
    local humanoid = character:WaitForChild("Humanoid")
    -- Config
    local TOOL_NAME = "Galaxy Slap"
    local MAGNET_RADIUS = 50
    local TELEPORT_INTERVAL = 0.03
    local SWING_INTERVAL = 0.03
    local FRONT_OFFSET = 1
    local RAGDOLL_VELOCITY = 50
    local FLING_VELOCITY = 200
    -- Tool reference
    local tool = character:FindFirstChild(TOOL_NAME) or player.Backpack:FindFirstChild(TOOL_NAME)
    if not tool then
        warn("Tool not found: "..TOOL_NAME)
        return
    end
    local locked = false
    local checkLoop
    local autoEnabled = false -- toggle state
    -- GUI Setup
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "AutoMagnetGui"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = player:WaitForChild("PlayerGui")
    local toggleButton = Instance.new("TextButton")
    toggleButton.Size = UDim2.new(0, 120, 0, 40)
    toggleButton.Position = UDim2.new(1, -130, 1, -50) -- bottom right corner
    toggleButton.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
    toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleButton.Font = Enum.Font.GothamBold
    toggleButton.TextSize = 16
    toggleButton.Text = "Auto: OFF"
    toggleButton.Parent = screenGui
    toggleButton.MouseButton1Click:Connect(function()
        autoEnabled = not autoEnabled
        if autoEnabled then
            toggleButton.Text = "Auto: ON"
            toggleButton.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
        else
            toggleButton.Text = "Auto: OFF"
            toggleButton.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
        end
    end)
    -- Lock tool
    local function lockTool()
        if locked then return end
        locked = true
        if tool.Parent ~= character then
            humanoid:EquipTool(tool)
            task.wait(0.05)
        end
        if not tool:FindFirstChild("LockListener") then
            local tag = Instance.new("BoolValue")
            tag.Name = "LockListener"
            tag.Parent = tool
            tool.Unequipped:Connect(function()
                if locked and humanoid and tool.Parent ~= character then
                    task.defer(function()
                        humanoid:EquipTool(tool)
                    end)
                end
            end)
        end
        local timer = 0
        checkLoop = RunService.Heartbeat:Connect(function(dt)
            timer += dt
            if timer >= 0.1 then
                timer = 0
                if locked and humanoid and tool.Parent ~= character then
                    humanoid:EquipTool(tool)
                end
            end
        end)
    end
    local function unlockTool()
        locked = false
        if checkLoop then
            checkLoop:Disconnect()
            checkLoop = nil
        end
    end
    -- Helpers
    local function getNearestPlayer()
        local closest, closestDist = nil, MAGNET_RADIUS
        for _, other in ipairs(Players:GetPlayers()) do
            if other ~= player and other.Character and other.Character:FindFirstChild("HumanoidRootPart") then
                local dist = (other.Character.HumanoidRootPart.Position - hrp.Position).Magnitude
                if dist <= closestDist then
                    closest = other
                    closestDist = dist
                end
            end
        end
        return closest
    end
    local function isRagdolled(target)
        local hrpTarget = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
        if not hrpTarget then return false end
        return hrpTarget.AssemblyLinearVelocity.Magnitude > RAGDOLL_VELOCITY
    end
    local function isFlinged(target)
        local hrpTarget = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
        if not hrpTarget then return false end
        return hrpTarget.AssemblyLinearVelocity.Magnitude > FLING_VELOCITY
    end
    local function swingTool()
        if tool.Parent == character then
            tool:Activate()
        end
    end
    -- Magnet loop with toggle
    task.spawn(function()
        while true do
            if autoEnabled then
                local target = getNearestPlayer()
                if target and target.Character then
                    local targetHRP = target.Character:FindFirstChild("HumanoidRootPart")
                    local targetHum = target.Character:FindFirstChild("Humanoid")
                    if targetHRP and targetHum and targetHum.Health > 0 then
                        lockTool()
                        task.wait(0.05)
                        while autoEnabled and targetHum.Health > 0 and targetHRP and not isRagdolled(target) and not isFlinged(target) do
                            local dir = (targetHRP.Position - hrp.Position).Unit
                            local newPos = targetHRP.Position - dir * FRONT_OFFSET
                            hrp.CFrame = CFrame.new(newPos, targetHRP.Position)
                            swingTool()
                            task.wait(SWING_INTERVAL)
                        end
                        unlockTool()
                    end
                end
            end
            task.wait(TELEPORT_INTERVAL)
        end
    end)
end
-- =======================
-- UNKILLABLE PLAYER BLOCK
-- =======================
do
    local player = game.Players.LocalPlayer
    local RunService = game:GetService("RunService")
    local FORCE_HEALTH = 100
    local FORCE_MAX_HEALTH = 100
    local function makeUnkillable(player)
        local function setupCharacter(character)
            local humanoid = character:FindFirstChild("Humanoid") or character:WaitForChild("Humanoid", 10)
            if humanoid then
                humanoid.MaxHealth = FORCE_MAX_HEALTH
                humanoid.Health = FORCE_HEALTH
                -- Prevent health from decreasing
                local healthConnection
                healthConnection = humanoid.HealthChanged:Connect(function(health)
                    if health < FORCE_HEALTH then
                        humanoid.Health = FORCE_HEALTH
                    end
                end)
                -- Prevent max health changes
                local maxHealthConnection
                maxHealthConnection = humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(function()
                    if humanoid.MaxHealth ~= FORCE_MAX_HEALTH then
                        humanoid.MaxHealth = FORCE_MAX_HEALTH
                        humanoid.Health = FORCE_HEALTH
                    end
                end)
                -- Prevent death
                local diedConnection
                diedConnection = humanoid.Died:Connect(function()
                    humanoid.Health = FORCE_HEALTH
                    humanoid:ChangeState(Enum.HumanoidStateType.Running)
                end)
                -- Prevent state changes that could lead to death
                humanoid.StateChanged:Connect(function(_, newState)
                    if newState == Enum.HumanoidStateType.Dead then
                        humanoid:ChangeState(Enum.HumanoidStateType.Running)
                        humanoid.Health = FORCE_HEALTH
                    end
                end)
                -- Continuous health monitoring
                local heartbeat
                heartbeat = RunService.Heartbeat:Connect(function()
                    if humanoid.Parent then
                        if humanoid.Health < FORCE_HEALTH then humanoid.Health = FORCE_HEALTH end
                        if humanoid.MaxHealth ~= FORCE_MAX_HEALTH then humanoid.MaxHealth = FORCE_MAX_HEALTH end
                    end
                end)
                -- Clean up connections when character is removed
                character.AncestryChanged:Connect(function()
                    if not character.Parent then
                        if healthConnection then healthConnection:Disconnect() end
                        if maxHealthConnection then maxHealthConnection:Disconnect() end
                        if diedConnection then diedConnection:Disconnect() end
                        if heartbeat then heartbeat:Disconnect() end
                    end
                end)
            end
        end
        if player.Character then setupCharacter(player.Character) end
        player.CharacterAdded:Connect(setupCharacter)
    end
    makeUnkillable(player)
end
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
--// GHOST PLAYERS / SENTRY / TRAP HANDLER
--// =======================
local Players   = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local task      = task
-- Weak tables so parts can be GC'd
local tracked = {
    others = setmetatable({}, { __mode = "k" }),
    localp = setmetatable({}, { __mode = "k" }),
    sentry = setmetatable({}, { __mode = "k" }),
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
    safeSet(part, "CanQuery", false)
    safeSet(part, "CanTouch", false)
end
local function applySentrySettings(part)
    safeSet(part, "CanCollide", true)
    safeSet(part, "CanQuery",   false)
    safeSet(part, "CanTouch",   true)
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
    tracked.sentry[part] = nil
    tracked.trap[part] = nil
end
local function watchPart(part, category)
    if not part or not part:IsA("BasePart") then return end
    if conns[part] then return end
    conns[part] = {}
    if category == "others" then tracked.others[part] = true applyOtherSettings(part)
    elseif category == "local" then tracked.localp[part] = true applyLocalSettings(part)
    elseif category == "sentry" then tracked.sentry[part] = true applySentrySettings(part)
    elseif category == "trap"   then tracked.trap[part]   = true applyTrapSettings(part) end
    local props = {}
    if category == "others" then props = {"CanCollide","CanQuery","CanTouch"}
    elseif category == "local" then props = {"CanQuery","CanTouch"}
    elseif category == "sentry" then props = {"CanCollide","CanQuery"}
    elseif category == "trap" then props = {"CanCollide","CanQuery","CanTouch"} end
    for _, prop in ipairs(props) do
        local ok, sig = pcall(function() return part:GetPropertyChangedSignal(prop) end)
        if ok and sig then
            table.insert(conns[part], sig:Connect(function()
                task.defer(function()
                    if not part or not part.Parent then return end
                    if category == "others" then applyOtherSettings(part)
                    elseif category == "local" then applyLocalSettings(part)
                    elseif category == "sentry" then applySentrySettings(part)
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
-- Workspace sentries/traps
local function processWorkspacePart(p)
    if not p:IsA("BasePart") then return end
    local name = (p.Name or ""):lower()
    if name:find("sentry") then
        watchPart(p, "sentry")
    elseif name:find("trap") then
        watchPart(p, "trap")
    end
end
for _, obj in ipairs(Workspace:GetDescendants()) do processWorkspacePart(obj) end
Workspace.DescendantAdded:Connect(processWorkspacePart)
-- Periodic enforcer
task.spawn(function()
    while true do
        task.wait(0.35)
        for part in pairs(tracked.others) do if part and part.Parent then applyOtherSettings(part) end end
        for part in pairs(tracked.localp) do if part and part.Parent then applyLocalSettings(part) end end
        for part in pairs(tracked.sentry) do if part and part.Parent then applySentrySettings(part) end end
        for part in pairs(tracked.trap)   do if part and part.Parent then applyTrapSettings(part) end end
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
        print("Grapple Hook speed & auto-fire active!")
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