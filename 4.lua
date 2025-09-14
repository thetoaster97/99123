--// Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

--// CONFIGURATION
local TOOL_NAME = "Laser Cape"  -- change to the tool you want to auto-equip
local Event = ReplicatedStorage.Packages.Net:WaitForChild("RE/UseItem")

--// =======================
--// AUTO-EQUIP & AUTO-FIRE
--// =======================

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




--// =======================
--// PLAYER AURA TRACKER (ESP BOX + NAME)
--// =======================

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

--// =======================
--// TIMER ESP
--// =======================
local overlayFolder = Instance.new("Folder")
overlayFolder.Name = "TimerOverlays"
overlayFolder.Parent = player:WaitForChild("PlayerGui")

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
    RunService.RenderStepped:Connect(function()
        if sourceLabel.Parent and target then
            local text = sourceLabel.Text
            if text == "0s" or text == "0" then
                textLabel.Text = "Unlocked"
                textLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
            else
                textLabel.Text = text
                textLabel.TextColor3 = Color3.fromRGB(0, 200, 255)
            end
        else
            billboard.Enabled = false
        end
    end)
end

local function scanTimers()
    for _, descendant in ipairs(workspace:GetDescendants()) do
        if descendant:IsA("TextLabel") and descendant.Text:match("%ds") then
            local adornee = descendant:FindFirstAncestorWhichIsA("BasePart")
            if adornee and adornee.Position.Y <= 7 then
                makeBillboard(adornee, descendant)
            end
        end
    end
end

scanTimers()
workspace.DescendantAdded:Connect(function(obj)
    if obj:IsA("TextLabel") and obj.Text:match("%ds") then
        local adornee = obj:FindFirstAncestorWhichIsA("BasePart")
        if adornee and adornee.Position.Y <= 7 then
            makeBillboard(adornee, obj)
        end
    end
end)

--// =======================
--// BEST-EARNING PET TRACKER
--// =======================
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

--// =======================
--// INFINITE JUMP
--// =======================
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



--// =======================
--// AUTO-RELOAD ON TELEPORT
--// =======================

local SCRIPT_RAW_URL = "https://raw.githubusercontent.com/yourname/yourrepo/main/admin.lua" 

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
if queue_func and SCRIPT_RAW_URL and SCRIPT_RAW_URL ~= "" then
    local queued_payload = [[
        local url = "]] .. SCRIPT_RAW_URL .. [["
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
--// SERVERHOP BUTTON
--// =======================

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