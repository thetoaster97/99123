
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

-- CONFIGURATION
local TOOL_NAME = "Laser Cape"  -- change to the tool you want to auto-equip
local Event = ReplicatedStorage.Packages.Net:WaitForChild("RE/UseItem")

-- =======================
-- AUTO-EQUIP & AUTO-FIRE
-- =======================

local forceEquipEnabled = true -- start enabled

-- Create simple toggle button
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AutoEquipToggleGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(0, 150, 0, 50)
toggleButton.Position = UDim2.new(0, 20, 0, 20)
toggleButton.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.Font = Enum.Font.SourceSansBold
toggleButton.TextSize = 18
toggleButton.Text = "Force Equip: ON"
toggleButton.Parent = screenGui

toggleButton.MouseButton1Click:Connect(function()
    forceEquipEnabled = not forceEquipEnabled
    toggleButton.Text = "Force Equip: " .. (forceEquipEnabled and "ON" or "OFF")
    toggleButton.BackgroundColor3 = forceEquipEnabled and Color3.fromRGB(0, 150, 255) or Color3.fromRGB(150, 0, 0)
end)

-- Function to get the equipped tool
local function getEquippedTool()
    local char = player.Character
    if not char then return nil end
    for _, item in ipairs(char:GetChildren()) do
        if item:IsA("Tool") then
            return item
        end
    end
end

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

-- Distance helper
local function getDistance(p1, p2)
    return (p1 - p2).Magnitude
end

-- Get closest player
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
                local dist = getDistance(hrp.Position, ohrp.Position)
                if dist < closestDist then
                    closestDist, closest = dist, other
                end
            end
        end
    end
    return closest
end

-- Force equip function
local function forceEquip()
    if not forceEquipEnabled then return end
    local char = player.Character
    if not char then return end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    local backpack = player:FindFirstChild("Backpack")
    if not humanoid or not backpack then return end
    local tool = backpack:FindFirstChild(TOOL_NAME) or char:FindFirstChild(TOOL_NAME)
    if tool and tool.Parent ~= char then
        humanoid:EquipTool(tool)
    end
end

-- Main Heartbeat loop
RunService.Heartbeat:Connect(function()
    forceEquip() -- only toggled
    local tool = getEquippedTool()
    if tool then
        local closest = getClosestPlayer()
        if closest then
            fireToolAtPlayer(tool, closest) -- always runs
        end
    end
end)

-- Reconnect when character respawns
player.CharacterAdded:Connect(function()
    task.wait(0.25)
    forceEquip()
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

-- =======================
-- BEST-EARNING PET TRACKER
-- =======================
local function parseMoney(text)
    text = string.lower(text or "")
    local num = tonumber(text:match("[%d%.]+")) or 0
    if text:find("k") then num *= 1e3
    elseif text:find("m") then num *= 1e6
    elseif text:find("b") then num *= 1e9
    elseif text:find("t") then num *= 1e12
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

local function isBlacklisted(obj)
    while obj do
        local name = string.lower(obj.Name or "")
        if name == "generationboard" or name:find("top") then return true end
        obj = obj.Parent
    end
    return false
end

local function findNameFromBillboard(billboard)
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

local billboardGui, textLabel, highlight = nil, nil, nil
local currentModel

local function clearVisuals()
    if billboardGui then billboardGui:Destroy() billboardGui = nil end
    if highlight then highlight:Destroy() highlight = nil end
    currentModel = nil
end

local function updateBest()
    local bestLabel, bestValue = nil, -math.huge
    for _, bb in ipairs(workspace:GetDescendants()) do
        if bb:IsA("BillboardGui") and not isBlacklisted(bb) then
            for _, lbl in ipairs(bb:GetDescendants()) do
                if lbl:IsA("TextLabel") then
                    local text = lbl.Text or ""
                    if text:find("/s") and text:find("%$") then
                        local val = parseMoney(text)
                        if val > bestValue then bestValue = val bestLabel = lbl end
                    end
                end
            end
        end
    end
    if not bestLabel then clearVisuals() return end
    local model = getModelForLabel(bestLabel)
    local part = getAnyPart(model)
    if not (model and part) then clearVisuals() return end
    if currentModel == model and textLabel then
        textLabel.Text = string.format("%s | $%s/s", findNameFromBillboard(bestLabel:FindFirstAncestorWhichIsA("BillboardGui")) or model.Name, abbreviate(bestValue))
        return
    end
    clearVisuals()
    currentModel = model
    highlight = Instance.new("Highlight")
    highlight.Name = "BestPetHighlight_Client"
    highlight.FillColor = Color3.fromRGB(0, 255, 0)
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency = 0.5
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Adornee = model
    highlight.Parent = model
    billboardGui = Instance.new("BillboardGui")
    billboardGui.Name = "BestPetBillboard_Client"
    billboardGui.Adornee = part
    billboardGui.Size = UDim2.new(0, 240, 0, 60)
    billboardGui.StudsOffset = Vector3.new(0, 6, 0)
    billboardGui.AlwaysOnTop = true
    billboardGui.MaxDistance = 1e6
    billboardGui.Parent = player:WaitForChild("PlayerGui")
    textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Font = Enum.Font.SourceSansBold
    textLabel.TextScaled = true
    textLabel.TextStrokeTransparency = 0
    textLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
    textLabel.Parent = billboardGui
    textLabel.Text = string.format("%s | $%s/s", findNameFromBillboard(bestLabel:FindFirstAncestorWhichIsA("BillboardGui")) or model.Name, abbreviate(bestValue))
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

local ADMIN_RAW_URL = "https://raw.githubusercontent.com/thetoaster97/99123/refs/heads/main/9.lua" -- replace with your raw script URL

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


-- =======================
-- MOBILE NOCLIP CAMERA BLOCK
-- =======================
do
    local Players = game:GetService("Players")
    local UserInputService = game:GetService("UserInputService")
    local RunService = game:GetService("RunService")

    local player = Players.LocalPlayer
    local camera = workspace.CurrentCamera

    -- Camera settings
    local minZoom, maxZoom = 5, 25
    local zoom = 12
    local yaw, pitch = 0, 0
    local rotationSensitivity = 0.5 -- Roblox-like drag sensitivity
    local zoomSensitivity = 0.15    -- faster pinch zoom

    -- Joystick area (ignore touches here)
    local screenSize = camera.ViewportSize
    local joystickArea = Rect.new(0, screenSize.Y - 250, 250, screenSize.Y) -- bottom-left 250x250 box

    -- Disable Roblox default camera
    camera.CameraType = Enum.CameraType.Scriptable

    -- Helper: get root
    local function getRoot()
        local char = player.Character or player.CharacterAdded:Wait()
        return char:WaitForChild("HumanoidRootPart")
    end

    -- Touch tracking
    local touches = {}

    local function isInJoystickArea(position: Vector2): boolean
        return position.X >= joystickArea.Min.X
            and position.X <= joystickArea.Max.X
            and position.Y >= joystickArea.Min.Y
            and position.Y <= joystickArea.Max.Y
    end

    UserInputService.TouchStarted:Connect(function(input)
        if isInJoystickArea(input.Position) then return end
        touches[input] = input.Position
    end)

    UserInputService.TouchEnded:Connect(function(input)
        touches[input] = nil
    end)

    UserInputService.TouchMoved:Connect(function(input)
        if not touches[input] then return end

        local touchCount = 0
        for _ in pairs(touches) do touchCount += 1 end

        -- Single finger = rotate
        if touchCount == 1 then
            local delta = input.Delta
            yaw -= delta.X * rotationSensitivity
            pitch = math.clamp(pitch - delta.Y * rotationSensitivity, -80, 80)
        end

        -- Two fingers = zoom
        if touchCount == 2 then
            local active = {}
            for t, _ in pairs(touches) do table.insert(active, t) end
            if #active == 2 then
                local oldDist = (touches[active[1]] - touches[active[2]]).Magnitude
                local newDist = (active[1].Position - active[2].Position).Magnitude
                local diff = newDist - oldDist
                zoom = math.clamp(zoom - diff * zoomSensitivity, minZoom, maxZoom)
            end
        end

        touches[input] = input.Position
    end)

    -- Camera update loop
    RunService.RenderStepped:Connect(function()
        local root = getRoot()
        local headOffset = Vector3.new(0, 2, 0)

        local rotation = CFrame.Angles(0, math.rad(yaw), 0) * CFrame.Angles(math.rad(pitch), 0, 0)
        local camPos = root.Position + headOffset - rotation.LookVector * zoom

        camera.CFrame = CFrame.new(camPos, root.Position + headOffset)
    end)

    print("✅ Mobile noclip camera active inside main script")
end

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

--// =======================
--// ULTRA-FAST TOOL REEQUIP + LOCAL VISUAL REMOVAL TOGGLE BUTTON
--// =======================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

local TOOL_NAME = "Galaxy Slap" -- replace with your tool
local tool = nil
local backpack = player:WaitForChild("Backpack")

local enabled = false -- starts off

-- Reference existing GUI
local screenGui = player:WaitForChild("PlayerGui"):FindFirstChild("AutoEquipToggleGui") or Instance.new("ScreenGui")
screenGui.Name = "AutoEquipToggleGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

-- Create toggle button under the existing Laser Cape button
local toggleToolButton = Instance.new("TextButton")
toggleToolButton.Size = UDim2.new(0, 120, 0, 40) -- slightly smaller
toggleToolButton.Position = UDim2.new(0, 40, 0, 75) -- below Laser Cape button (original at 20 + 50 height + 5 padding)
toggleToolButton.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
toggleToolButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleToolButton.Font = Enum.Font.SourceSansBold
toggleToolButton.TextSize = 16
toggleToolButton.Text = "Ultra Equip: OFF"
toggleToolButton.Parent = screenGui

toggleToolButton.MouseButton1Click:Connect(function()
    enabled = not enabled
    toggleToolButton.Text = "Ultra Equip: " .. (enabled and "ON" or "OFF")
    toggleToolButton.BackgroundColor3 = enabled and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(150, 0, 0)

    -- Apply to all existing players immediately when turned on
    if enabled then
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= player then
                removeLocalVisuals(plr)
            end
        end
    end
end)

-- Function to get the tool reference
local function updateTool()
    tool = backpack:FindFirstChild(TOOL_NAME) or character:FindFirstChild(TOOL_NAME)
end

updateTool()

-- Function to remove local visuals
local function removeLocalVisuals(plr)
    if not plr.Character then return end
    for _, item in ipairs(plr.Character:GetChildren()) do
        if item:IsA("Accessory") or item:IsA("Clothing") or item:IsA("ShirtGraphic") or item:IsA("Pants") then
            item:Destroy()
        elseif item:IsA("LayeredClothing") then
            item:Destroy()
        end
    end
end

-- Main loop for ultra-fast equip/unequip
RunService.Stepped:Connect(function()
    if not enabled then return end
    if not tool then updateTool() return end
    if tool.Parent == character then
        tool.Parent = backpack
    else
        humanoid:EquipTool(tool)
    end
end)

-- Apply to new players automatically
Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(function()
        if plr ~= player and enabled then
            removeLocalVisuals(plr)
        end
    end)
end)

--// CLEANUP AND RELOAD ON DEATH
local function cleanupAndReload()
    -- Remove GUIs added by this script
    local playerGui = player:WaitForChild("PlayerGui")
    for _, gui in ipairs(playerGui:GetChildren()) do
        if gui.Name:match("AutoEquipToggleGui") or gui.Name:match("TimerOverlays") or gui.Name:match("BestPetBillboard_Client") or gui.Name:match("FloatToggleGui") then
            gui:Destroy()
        end
    end

    -- Optionally, remove highlights or SelectionBoxes
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Highlight") and obj.Name:match("BestPetHighlight_Client") then
            obj:Destroy()
        elseif obj:IsA("SelectionBox") and obj.Name == "PlayerBox" then
            obj:Destroy()
        elseif obj:IsA("BillboardGui") and obj.Name == "PlayerNameTag" then
            obj:Destroy()
        end
    end

    -- Reload the script
    local currentScript = script
    local clonedScript = currentScript:Clone()
    clonedScript.Parent = currentScript.Parent
    currentScript:Destroy()
end

-- Connect to character death
if player.Character then
    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.Died:Connect(cleanupAndReload)
    end
end

player.CharacterAdded:Connect(function(char)
    local humanoid = char:WaitForChild("Humanoid")
    humanoid.Died:Connect(cleanupAndReload)
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