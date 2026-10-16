-- Place this inside a LocalScript (e.g., in StarterPlayerScripts or StarterGui)
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local ProximityPromptService = game:GetService("ProximityPromptService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

player.CharacterAdded:Connect(function(char)
    character = char
end)

-- Create ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AntiChaseGUI"
screenGui.ResetOnSpawn = false

pcall(function()
    screenGui.Parent = CoreGui
end)
if not screenGui.Parent then
    screenGui.Parent = player:WaitForChild("PlayerGui")
end

-- Main Frame
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 180, 0, 100)
mainFrame.Position = UDim2.new(0.5, -90, 0.1, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, 8)
uiCorner.Parent = mainFrame

-- Title
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -30, 0, 30)
title.Position = UDim2.new(0, 10, 0, 0)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.Text = "Anti-Chase Menu"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 14
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = mainFrame

-- Top X Close Button
local hideBtn = Instance.new("TextButton")
hideBtn.Size = UDim2.new(0, 24, 0, 24)
hideBtn.Position = UDim2.new(1, -28, 0, 4)
hideBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
hideBtn.Font = Enum.Font.GothamBold
hideBtn.Text = "X"
hideBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
hideBtn.TextSize = 12
hideBtn.Parent = mainFrame

local hideCorner = Instance.new("UICorner")
hideCorner.CornerRadius = UDim.new(0, 4)
hideCorner.Parent = hideBtn

-- Anti-Chase Toggle Button
local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0.9, 0, 0, 35)
toggleBtn.Position = UDim2.new(0.05, 0, 0, 45)
toggleBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
toggleBtn.Font = Enum.Font.GothamSemibold
toggleBtn.Text = "Anti-Chase: OFF"
toggleBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
toggleBtn.TextSize = 13
toggleBtn.Parent = mainFrame

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 6)
toggleCorner.Parent = toggleBtn

-- Floating "Egg" Open Button (Draggable)
local openBtn = Instance.new("TextButton")
openBtn.Size = UDim2.new(0, 40, 0, 40)
openBtn.Position = UDim2.new(0, 10, 0, 10)
openBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
openBtn.Font = Enum.Font.GothamBold
openBtn.Text = "🥚"
openBtn.TextSize = 20
openBtn.Visible = false
openBtn.Parent = screenGui

local openCorner = Instance.new("UICorner")
openCorner.CornerRadius = UDim.new(0, 8)
openCorner.Parent = openBtn

-- Draggable Logic for openBtn
local dragging, dragInput, dragStart, startPos

openBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = openBtn.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        openBtn.Position = UDim2.new(
            startPos.X.Scale, 
            startPos.X.Offset + delta.X, 
            startPos.Y.Scale, 
            startPos.Y.Offset + delta.Y
        )
    end
end)

-- Logic State & Caching
local antiChaseEnabled = false
local isTeleporting = false
local cachedSpawnPosition = Vector3.new(0, 10, 0)
local originalDurations = {}
local promptAddedConn = nil

local function cacheSpawn()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("SpawnLocation") then
            cachedSpawnPosition = obj.Position
            break
        end
    end
end
cacheSpawn()

-- Handle Instant Interact (0 HoldDuration)
local function setInstantInteract(enable)
    if enable then
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("ProximityPrompt") then
                if originalDurations[obj] == nil then
                    originalDurations[obj] = obj.HoldDuration
                end
                obj.HoldDuration = 0
            end
        end
        
        if not promptAddedConn then
            promptAddedConn = Workspace.DescendantAdded:Connect(function(obj)
                if obj:IsA("ProximityPrompt") and antiChaseEnabled then
                    if originalDurations[obj] == nil then
                        originalDurations[obj] = obj.HoldDuration
                    end
                    obj.HoldDuration = 0
                end
            end)
        end
    else
        for prompt, duration in pairs(originalDurations) do
            if prompt and prompt.Parent then
                prompt.HoldDuration = duration
            end
        end
        originalDurations = {}
        if promptAddedConn then
            promptAddedConn:Disconnect()
            promptAddedConn = nil
        end
    end
end

-- Toggle Anti-Chase & Instant Interact
toggleBtn.MouseButton1Click:Connect(function()
    antiChaseEnabled = not antiChaseEnabled
    if antiChaseEnabled then
        toggleBtn.Text = "Anti-Chase: ON"
        toggleBtn.TextColor3 = Color3.fromRGB(100, 255, 100)
        cacheSpawn()
        setInstantInteract(true)
    else
        toggleBtn.Text = "Anti-Chase: OFF"
        toggleBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
        setInstantInteract(false)
    end
end)

-- Hide / Show GUI logic
hideBtn.MouseButton1Click:Connect(function()
    mainFrame.Visible = false
    openBtn.Visible = true
end)

openBtn.MouseButton1Click:Connect(function()
    mainFrame.Visible = true
    openBtn.Visible = false
end)

-- Freeze, wait, then teleport to a fixed position near spawn
ProximityPromptService.PromptTriggered:Connect(function(prompt, triggeringPlayer)
    if triggeringPlayer == player and antiChaseEnabled and not isTeleporting then
        isTeleporting = true
        
        local rootPart = character and character:FindFirstChild("HumanoidRootPart")
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        
        if rootPart and humanoid then
            local oldWalkSpeed = humanoid.WalkSpeed
            humanoid.WalkSpeed = 0
            rootPart.Anchored = true
            
            task.wait(0.2)
            
            rootPart.Anchored = false
            rootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            rootPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
            
            local fixedOffset = Vector3.new(20, 5, 0)
            local landingPosition = cachedSpawnPosition + fixedOffset
            
            for _ = 1, 5 do
                rootPart.CFrame = CFrame.new(landingPosition)
                task.wait()
            end
            
            humanoid.WalkSpeed = oldWalkSpeed
        end
        
        isTeleporting = false
    end
end)