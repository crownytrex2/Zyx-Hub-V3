--// EXECUTABLE FLY GUI BY LUA Programming GOD

if game.CoreGui:FindFirstChild("FlyGui") then
    game.CoreGui.FlyGui:Destroy()
end

-- GUI CREATION ------------------------------------------------------------

local sg = Instance.new("ScreenGui")
sg.Name = "FlyGui"
sg.ResetOnSpawn = false
sg.Parent = game.CoreGui

local frame = Instance.new("Frame")
frame.Name = "Main"
frame.Size = UDim2.new(0, 220, 0, 120)
frame.Position = UDim2.new(0.5, -110, 0.5, -60)
frame.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
frame.BackgroundTransparency = 0.3   -- <--- 70% transparency
frame.Active = true
frame.Draggable = true
frame.Parent = sg

local corner = Instance.new("UICorner", frame)
corner.CornerRadius = UDim.new(0, 12)

local toggle = Instance.new("TextButton")
toggle.Name = "ToggleBtn"
toggle.Size = UDim2.new(1, -20, 0, 36)
toggle.Position = UDim2.new(0, 10, 0, 10)
toggle.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
toggle.TextColor3 = Color3.fromRGB(255, 255, 255)
toggle.Text = "Fly: OFF"
toggle.Parent = frame

local toggleCorner = Instance.new("UICorner", toggle)
toggleCorner.CornerRadius = UDim.new(0, 8)

local speedLabel = Instance.new("TextLabel")
speedLabel.Text = "Speed:"
speedLabel.Size = UDim2.new(0, 60, 0, 30)
speedLabel.Position = UDim2.new(0, 10, 0, 60)
speedLabel.BackgroundTransparency = 1
speedLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
speedLabel.TextXAlignment = Enum.TextXAlignment.Left
speedLabel.Parent = frame

local speedBox = Instance.new("TextBox")
speedBox.Name = "SpeedBox"
speedBox.Size = UDim2.new(0, 60, 0, 30)
speedBox.Position = UDim2.new(0, 80, 0, 60)
speedBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
speedBox.TextColor3 = Color3.fromRGB(255, 255, 255)
speedBox.Text = "60"
speedBox.Parent = frame

Instance.new("UICorner", speedBox).CornerRadius = UDim.new(0, 6)

-- FLY SYSTEM --------------------------------------------------------------

local player = game.Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local hum = char:WaitForChild("Humanoid")
local hrp = char:WaitForChild("HumanoidRootPart")

local flying = false
local speed = 60
local BV, BG

local UIS = game:GetService("UserInputService")
local RS = game:GetService("RunService")

local keys = {W=false, A=false, S=false, D=false, Up=false, Down=false}

UIS.InputBegan:Connect(function(i, g)
    if g then return end
    if i.KeyCode == Enum.KeyCode.W then keys.W = true end
    if i.KeyCode == Enum.KeyCode.S then keys.S = true end
    if i.KeyCode == Enum.KeyCode.A then keys.A = true end
    if i.KeyCode == Enum.KeyCode.D then keys.D = true end
    if i.KeyCode == Enum.KeyCode.Space then keys.Up = true end
    if i.KeyCode == Enum.KeyCode.LeftControl then keys.Down = true end
end)

UIS.InputEnded:Connect(function(i)
    if i.KeyCode == Enum.KeyCode.W then keys.W = false end
    if i.KeyCode == Enum.KeyCode.S then keys.S = false end
    if i.KeyCode == Enum.KeyCode.A then keys.A = false end
    if i.KeyCode == Enum.KeyCode.D then keys.D = false end
    if i.KeyCode == Enum.KeyCode.Space then keys.Up = false end
    if i.KeyCode == Enum.KeyCode.LeftControl then keys.Down = false end
end)

local function startFly()
    flying = true
    hum.PlatformStand = true

    BV = Instance.new("BodyVelocity")
    BV.MaxForce = Vector3.new(1e6, 1e6, 1e6)
    BV.Parent = hrp

    BG = Instance.new("BodyGyro")
    BG.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
    BG.Parent = hrp
end

local function stopFly()
    flying = false
    hum.PlatformStand = false
    if BV then BV:Destroy() end
    if BG then BG:Destroy() end
end

speedBox.FocusLost:Connect(function()
    local s = tonumber(speedBox.Text)
    if s then speed = math.clamp(s, 10, 500) end
end)

toggle.MouseButton1Click:Connect(function()
    if flying then
        stopFly()
        toggle.Text = "Fly: OFF"
    else
        startFly()
        toggle.Text = "Fly: ON"
    end
end)

RS.RenderStepped:Connect(function()
    if flying and BV and BG then
        local cam = workspace.CurrentCamera
        local cf = cam.CFrame

        local move = Vector3.zero
        if keys.W then move = move + cf.LookVector end
        if keys.S then move = move - cf.LookVector end
        if keys.A then move = move - cf.RightVector end
        if keys.D then move = move + cf.RightVector end

        move = Vector3.new(move.X, 0, move.Z)
        if move.Magnitude > 0 then move = move.Unit end

        local y = 0
        if keys.Up then y = 1 end
        if keys.Down then y = -1 end

        BV.Velocity = move * speed + Vector3.new(0, y * speed, 0)
        BG.CFrame = CFrame.new(hrp.Position, hrp.Position + cf.LookVector)
    end
end)
