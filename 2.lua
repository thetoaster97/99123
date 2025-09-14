local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local Event = ReplicatedStorage.Packages.Net["RE/UseItem"]

-- Function to find your currently equipped tool
local function getEquippedTool()
    if player.Character then
        for _, item in pairs(player.Character:GetChildren()) do
            if item:IsA("Tool") then
                return item
            end
        end
    end
    return nil
end

-- Function to fire tool at a player depending on tool type
local function fireToolAtPlayer(tool, target)
    if not tool or not target or not target.Character or not target.Character:FindFirstChild("HumanoidRootPart") then return end
    local hrp = target.Character.HumanoidRootPart

    if tool.Name == "Laser Cape" then
        Event:FireServer(hrp.Position, hrp)
    elseif tool.Name == "Taser Gun" then
        Event:FireServer(hrp)
    elseif tool.Name == "Web Slinger" then
        Event:FireServer(hrp.Position, hrp)
    elseif tool.Name == "Bee Launcher" then
        Event:FireServer(target)
    end
end

-- Utility function to get distance between two positions
local function getDistance(pos1, pos2)
    return (pos1 - pos2).Magnitude
end

-- Function to find the closest player to you
local function getClosestPlayer()
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return nil end
    local myPos = player.Character.HumanoidRootPart.Position
    local closestPlayer = nil
    local closestDistance = math.huge

    for _, otherPlayer in pairs(Players:GetPlayers()) do
        if otherPlayer ~= player and otherPlayer.Character and otherPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local distance = getDistance(myPos, otherPlayer.Character.HumanoidRootPart.Position)
            if distance < closestDistance then
                closestDistance = distance
                closestPlayer = otherPlayer
            end
        end
    end
    return closestPlayer
end

-- Main loop: fire at closest player every frame
RunService.RenderStepped:Connect(function()
    local tool = getEquippedTool()
    if not tool then return end
    local closest = getClosestPlayer()
    if closest then
        fireToolAtPlayer(tool, closest)
    end
end)
