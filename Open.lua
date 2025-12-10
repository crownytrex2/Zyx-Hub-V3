--======================================--
-- Zyx Hub | Raw Key List Version
--======================================--

local RAW_URL = "https://raw.githubusercontent.com/crownytrex2/Zyx-Hub-V3/main/generated_keys.txt"

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

-- Cleanup existing GUI
pcall(function()
    if game.CoreGui:FindFirstChild("ZyxKeyGUI") then
        game.CoreGui.ZyxKeyGUI:Destroy()
    end
    if game.CoreGui:FindFirstChild("FlyGui") then
        game.CoreGui.FlyGui:Destroy()
    end
end)

--======================================--
-- CREATE KEY GUI
--======================================--

local gui = Instance.new("ScreenGui", game.CoreGui)
gui.Name = "ZyxKeyGUI"

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0,350,0,150)
frame.Position = UDim2.new(0.5,-175,0.5,-75)
frame.BackgroundColor3 = Color3.fromRGB(100,100,100)
frame.BackgroundTransparency = 0.3
frame.Active = true
frame.Draggable = true
Instance.new("UICorner", frame).CornerRadius = UDim.new(0,12)

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1,0,0,30)
title.BackgroundTransparency = 1
title.Text = "Zyx Hub | Key System"
title.Font = Enum.Font.GothamBold
title.TextColor3 = Color3.new(1,1,1)
title.TextSize = 18

local keyBox = Instance.new("TextBox", frame)
keyBox.Size = UDim2.new(1,-20,0,35)
keyBox.Position = UDim2.new(0,10,0,45)
keyBox.PlaceholderText = "Enter Key"
keyBox.BackgroundColor3 = Color3.fromRGB(70,70,70)
keyBox.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", keyBox).CornerRadius = UDim.new(0,8)

local verifyBtn = Instance.new("TextButton", frame)
verifyBtn.Size = UDim2.new(0,120,0,35)
verifyBtn.Position = UDim2.new(0,10,1,-45)
verifyBtn.Text = "Verify"
verifyBtn.BackgroundColor3 = Color3.fromRGB(0,150,0)
verifyBtn.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", verifyBtn).CornerRadius = UDim.new(0,8)

local status = Instance.new("TextLabel", frame)
status.Size = UDim2.new(0,180,0,35)
status.Position = UDim2.new(0,140,1,-45)
status.BackgroundTransparency = 1
status.TextColor3 = Color3.new(1,1,1)
status.Text = "Waiting..."
status.TextXAlignment = Enum.TextXAlignment.Left

--======================================--
-- RAW KEY VALIDATION
--======================================--

local function checkKey(k)
    local ok, data = pcall(function()
        return HttpService:GetAsync(RAW_URL)
    end)

    if not ok then
        return false, "GitHub Error"
    end

    -- Split by lines
    local keyList = {}
    for key in string.gmatch(data, "[^\r\n]+") do
        table.insert(keyList, key)
    end

    -- Compare
    for _, v in ipairs(keyList) do
        if k == v then
            return true, "Valid Key"
        end
    end

    return false, "Invalid Key"
end

--======================================--
-- LOAD FLY GUI (ONLY AFTER VALID KEY)
--======================================--

local function loadFly()
    gui:Destroy()

    local flyGui = Instance.new("ScreenGui", game.CoreGui)
    flyGui.Name = "FlyGui"

    local frame = Instance.new("Frame", flyGui)
    frame.Size = UDim2.new(0,220,0,120)
    frame.Position = UDim2.new(0.4,0,0.4,0)
    frame.BackgroundColor3 = Color3.fromRGB(120,120,120)
    frame.BackgroundTransparency = 0.3
    frame.Active = true
    frame.Draggable = true
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0,12)

    local toggle = Instance.new("TextButton", frame)
    toggle.Size = UDim2.new(1,-20,0,35)
    toggle.Position = UDim2.new(0,10,0,10)
    toggle.Text = "Fly: OFF"
    toggle.BackgroundColor3 = Color3.fromRGB(80,80,80)
    toggle.TextColor3 = Color3.new(1,1,1)
    Instance.new("UICorner", toggle).CornerRadius = UDim.new(0,8)

    local speedBox = Instance.new("TextBox", frame)
    speedBox.Size = UDim2.new(0,60,0,30)
    speedBox.Position = UDim2.new(0,10,0,60)
    speedBox.Text = "60"
    speedBox.BackgroundColor3 = Color3.fromRGB(60,60,60)
    speedBox.TextColor3 = Color3.new(1,1,1)
    Instance.new("UICorner", speedBox).CornerRadius = UDim.new(0,8)

    local char = player.Character or player.CharacterAdded:Wait()
    local hum = char:WaitForChild("Humanoid")
    local hrp = char:WaitForChild("HumanoidRootPart")

    local flying = false
    local speed = 60
    local BV, BG
    local keys = {W=false,S=false,A=false,D=false,Up=false,Down=false}

    UserInputService.InputBegan:Connect(function(i,g)
        if g then return end
        if i.KeyCode == Enum.KeyCode.W then keys.W=true end
        if i.KeyCode == Enum.KeyCode.S then keys.S=true end
        if i.KeyCode == Enum.KeyCode.A then keys.A=true end
        if i.KeyCode == Enum.KeyCode.D then keys.D=true end
        if i.KeyCode == Enum.KeyCode.Space then keys.Up=true end
        if i.KeyCode == Enum.KeyCode.LeftControl then keys.Down=true end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.KeyCode == Enum.KeyCode.W then keys.W=false end
        if i.KeyCode == Enum.KeyCode.S then keys.S=false end
        if i.KeyCode == Enum.KeyCode.A then keys.A=false end
        if i.KeyCode == Enum.KeyCode.D then keys.D=false end
        if i.KeyCode == Enum.KeyCode.Space then keys.Up=false end
        if i.KeyCode == Enum.KeyCode.LeftControl then keys.Down=false end
    end)

    toggle.MouseButton1Click:Connect(function()
        if flying then
            flying=false
            toggle.Text="Fly: OFF"
            hum.PlatformStand=false
            if BV then BV:Destroy() end
            if BG then BG:Destroy() end
        else
            flying=true
            toggle.Text="Fly: ON"
            hum.PlatformStand=true
            BV=Instance.new("BodyVelocity", hrp)
            BV.MaxForce=Vector3.new(1e6,1e6,1e6)
            BG=Instance.new("BodyGyro", hrp)
            BG.MaxTorque=Vector3.new(1e6,1e6,1e6)
        end
    end)

    speedBox.FocusLost:Connect(function()
        local s = tonumber(speedBox.Text)
        if s then speed=s end
    end)

    RunService.RenderStepped:Connect(function()
        if flying and BV and BG then
            local cam = workspace.CurrentCamera
            local move = Vector3.zero

            if keys.W then move += cam.CFrame.LookVector end
            if keys.S then move -= cam.CFrame.LookVector end
            if keys.A then move -= cam.CFrame.RightVector end
            if keys.D then move += cam.CFrame.RightVector end

            move = Vector3.new(move.X,0,move.Z)
            if move.Magnitude > 0 then move = move.Unit end

            local y = (keys.Up and 1 or 0) + (keys.Down and -1 or 0)

            BV.Velocity = move * speed + Vector3.new(0,y*speed,0)
            BG.CFrame = CFrame.new(hrp.Position, hrp.Position + cam.CFrame.LookVector)
        end
    end)
end

--======================================--
-- VERIFY BUTTON
--======================================--

verifyBtn.MouseButton1Click:Connect(function()
    status.Text = "Checking..."

    local ok, msg = checkKey(keyBox.Text)

    if ok then
        status.Text = "Key Valid ✓"
        task.wait(0.5)
        loadFly()
    else
        status.Text = "❌ " .. msg
    end
end)
