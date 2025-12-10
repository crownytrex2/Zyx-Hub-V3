-- Key-protected Fly GUI (executable)
-- Paste / run this as a LocalScript or execute from your executor.
-- Requirements: HttpService must be allowed (HttpEnabled).

local RAW_URL = "https://raw.githubusercontent.com/crownytrex2/Zyx-Hub-V3/refs/heads/main/generated_keys.json"

-- ===== services =====
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
if not player then
    warn("This script must run in a LocalPlayer context.")
    return
end

-- ===== helpers =====
local function safeGet(url)
    local ok, res = pcall(function() return HttpService:GetAsync(url, true) end)
    if ok then return true, res end
    return false, tostring(res)
end

-- parse ISO8601 Z time (expects "...T...Z"), returns unix timestamp (seconds) or nil
local function isoToUnix(s)
    if not s then return nil end
    local y,m,d,h,min,sec = s:match("^(%d+)%-(%d+)%-(%d+)T(%d+):(%d+):([0-9%.]+)Z$")
    if not y then return nil end
    sec = math.floor(tonumber(sec) or 0)
    local t = { year = tonumber(y), month = tonumber(m), day = tonumber(d),
                hour = tonumber(h), min = tonumber(min), sec = sec }
    -- os.time(t) gives *local* epoch; convert to UTC epoch:
    local localEpoch = os.time(t)
    local utcNow = os.time(os.date("!*t"))
    local localNow = os.time(os.date("*t"))
    local offset = os.difftime(localNow, utcNow) -- seconds local - utc
    return localEpoch - offset
end

local function currentUnixUTC()
    return os.time(os.date("!*t"))
end

-- ===== UI: Key GUI (draggable, rounded, grey 70% transparent) =====
-- Clean previous
if game.CoreGui:FindFirstChild("KeyFlyGui") then
    game.CoreGui.KeyFlyGui:Destroy()
end

local sg = Instance.new("ScreenGui")
sg.Name = "KeyFlyGui"
sg.ResetOnSpawn = false
sg.Parent = game.CoreGui

local frame = Instance.new("Frame")
frame.Name = "Main"
frame.Size = UDim2.new(0,300,0,140)
frame.Position = UDim2.new(0.5,-150,0.45,-70)
frame.BackgroundColor3 = Color3.fromRGB(120,120,120)
frame.BackgroundTransparency = 0.7 -- 70% transparent
frame.Active = true
frame.Parent = sg

local uic = Instance.new("UICorner", frame)
uic.CornerRadius = UDim.new(0,12)

-- Title
local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, -20, 0, 28)
title.Position = UDim2.new(0,10,0,8)
title.BackgroundTransparency = 1
title.Text = "Enter Key to Unlock Fly"
title.TextColor3 = Color3.new(1,1,1)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 18
title.TextXAlignment = Enum.TextXAlignment.Left

-- Key input
local keyBox = Instance.new("TextBox", frame)
keyBox.Size = UDim2.new(1, -20, 0, 34)
keyBox.Position = UDim2.new(0,10,0,40)
keyBox.Text = ""
keyBox.PlaceholderText = "Paste your key here"
keyBox.BackgroundColor3 = Color3.fromRGB(75,75,75)
keyBox.TextColor3 = Color3.fromRGB(255,255,255)
Instance.new("UICorner", keyBox).CornerRadius = UDim.new(0,6)

-- Verify button
local verifyBtn = Instance.new("TextButton", frame)
verifyBtn.Size = UDim2.new(0,100,0,30)
verifyBtn.Position = UDim2.new(0,10,1,-40)
verifyBtn.Text = "Verify"
verifyBtn.BackgroundColor3 = Color3.fromRGB(60,130,60)
verifyBtn.TextColor3 = Color3.fromRGB(255,255,255)
Instance.new("UICorner", verifyBtn).CornerRadius = UDim.new(0,6)

-- Status label
local status = Instance.new("TextLabel", frame)
status.Size = UDim2.new(1, -130, 0, 30)
status.Position = UDim2.new(0,120,1,-40)
status.BackgroundTransparency = 1
status.Text = "Waiting..."
status.TextColor3 = Color3.fromRGB(230,230,230)
status.TextXAlignment = Enum.TextXAlignment.Left

-- draggable behavior (click and drag)
local dragging, dragInput, dragStart, startPos
local function update(pos)
    local delta = pos - dragStart
    frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
                               startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

frame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = frame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

frame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        update(input.Position)
    end
end)

-- ===== Key verification logic =====
local parsedKeysCache = nil
local function fetchKeys()
    if parsedKeysCache then return true, parsedKeysCache end
    local ok, res = safeGet(RAW_URL)
    if not ok then return false, ("HTTP error: %s"):format(res) end
    local ok2, json = pcall(function() return HttpService:JSONDecode(res) end)
    if not ok2 then return false, ("JSON parse error: %s"):format(json) end
    parsedKeysCache = json
    return true, json
end

local function checkKey(keyText)
    if not keyText or keyText:match("^%s*$") then
        return false, "Please enter a key."
    end
    local ok, keysOrErr = fetchKeys()
    if not ok then return false, keysOrErr end
    local now = currentUnixUTC()
    -- keysOrErr expected to be an array of objects with fields: value, prefix, expiresAt
    for _, entry in ipairs(keysOrErr) do
        local value = entry.value or entry.VALUE or entry.key or entry.value
        if tostring(value) == tostring(keyText) then
            -- check prefix match if present (optional)
            if entry.prefix and entry.prefix ~= "" then
                if not tostring(keyText):find(tostring(entry.prefix),1,true) then
                    return false, "Key prefix mismatch."
                end
            end
            -- check expiry
            local expUnix = isoToUnix(entry.expiresAt)
            if expUnix then
                if now > expUnix then
                    return false, "Key expired."
                else
                    return true, "OK"
                end
            else
                -- if no expiresAt present, accept (or you can reject; here we accept)
                return true, "OK"
            end
        end
    end
    return false, "Key not found."
end

-- ===== Fly GUI & Movement (created after successful verification) =====
local function createFlyGuiAndStart()
    -- clean any existing FlyGui in CoreGui
    if game.CoreGui:FindFirstChild("FlyGui") then
        game.CoreGui.FlyGui:Destroy()
    end

    local flySG = Instance.new("ScreenGui")
    flySG.Name = "FlyGui"
    flySG.ResetOnSpawn = false
    flySG.Parent = game.CoreGui

    local main = Instance.new("Frame")
    main.Name = "Main"
    main.Size = UDim2.new(0,220,0,120)
    main.Position = UDim2.new(0.5,-110,0.5,-60)
    main.BackgroundColor3 = Color3.fromRGB(100,100,100)
    main.BackgroundTransparency = 0.3
    main.Active = true
    main.Parent = flySG
    Instance.new("UICorner", main).CornerRadius = UDim.new(0,12)

    local toggle = Instance.new("TextButton", main)
    toggle.Name = "ToggleBtn"
    toggle.Size = UDim2.new(1,-20,0,36)
    toggle.Position = UDim2.new(0,10,0,10)
    toggle.Text = "Fly: OFF"
    toggle.BackgroundColor3 = Color3.fromRGB(70,70,70)
    toggle.TextColor3 = Color3.fromRGB(255,255,255)
    Instance.new("UICorner", toggle).CornerRadius = UDim.new(0,8)

    local speedLabel = Instance.new("TextLabel", main)
    speedLabel.Text = "Speed:"
    speedLabel.Size = UDim2.new(0,60,0,30)
    speedLabel.Position = UDim2.new(0,10,0,60)
    speedLabel.BackgroundTransparency = 1
    speedLabel.TextColor3 = Color3.fromRGB(255,255,255)
    speedLabel.TextXAlignment = Enum.TextXAlignment.Left

    local speedBox = Instance.new("TextBox", main)
    speedBox.Name = "SpeedBox"
    speedBox.Size = UDim2.new(0,60,0,30)
    speedBox.Position = UDim2.new(0,80,0,60)
    speedBox.BackgroundColor3 = Color3.fromRGB(50,50,50)
    speedBox.TextColor3 = Color3.fromRGB(255,255,255)
    speedBox.Text = "60"
    Instance.new("UICorner", speedBox).CornerRadius = UDim.new(0,6)

    -- Draggable main
    main.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = main.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    main.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    -- Movement setup
    local char = player.Character or player.CharacterAdded:Wait()
    local humanoid = char:WaitForChild("Humanoid")
    local hrp = char:WaitForChild("HumanoidRootPart")
    local flying = false
    local speed = 60
    local BV, BG

    local keys = {W=false,A=false,S=false,D=false,Up=false,Down=false}
    UserInputService.InputBegan:Connect(function(i, g)
        if g then return end
        if i.KeyCode == Enum.KeyCode.W then keys.W = true end
        if i.KeyCode == Enum.KeyCode.S then keys.S = true end
        if i.KeyCode == Enum.KeyCode.A then keys.A = true end
        if i.KeyCode == Enum.KeyCode.D then keys.D = true end
        if i.KeyCode == Enum.KeyCode.Space then keys.Up = true end
        if i.KeyCode == Enum.KeyCode.LeftControl or i.KeyCode == Enum.KeyCode.RightControl then keys.Down = true end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.KeyCode == Enum.KeyCode.W then keys.W = false end
        if i.KeyCode == Enum.KeyCode.S then keys.S = false end
        if i.KeyCode == Enum.KeyCode.A then keys.A = false end
        if i.KeyCode == Enum.KeyCode.D then keys.D = false end
        if i.KeyCode == Enum.KeyCode.Space then keys.Up = false end
        if i.KeyCode == Enum.KeyCode.LeftControl or i.KeyCode == Enum.KeyCode.RightControl then keys.Down = false end
    end)

    local function startFly()
        if flying then return end
        flying = true
        humanoid.PlatformStand = true
        BV = Instance.new("BodyVelocity")
        BV.MaxForce = Vector3.new(1e5,1e5,1e5)
        BV.P = 1e4
        BV.Parent = hrp
        BG = Instance.new("BodyGyro")
        BG.MaxTorque = Vector3.new(1e5,1e5,1e5)
        BG.P = 1e4
        BG.Parent = hrp
    end

    local function stopFly()
        if not flying then return end
        flying = false
        humanoid.PlatformStand = false
        if BV then BV:Destroy(); BV = nil end
        if BG then BG:Destroy(); BG = nil end
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

    RunService.RenderStepped:Connect(function()
        -- refresh character references if needed
        if not player.Character or not player.Character.Parent then
            char = player.Character or player.CharacterAdded:Wait()
            humanoid = char:WaitForChild("Humanoid")
            hrp = char:WaitForChild("HumanoidRootPart")
        end

        if flying and BV and BG and hrp then
            local cam = workspace.CurrentCamera
            local cf = cam.CFrame

            local move = Vector3.new()
            if keys.W then move = move + cf.LookVector end
            if keys.S then move = move - cf.LookVector end
            if keys.A then move = move - cf.RightVector end
            if keys.D then move = move + cf.RightVector end

            move = Vector3.new(move.X,0,move.Z)
            if move.Magnitude > 0 then move = move.Unit end

            local y = 0
            if keys.Up then y = y + 1 end
            if keys.Down then y = y - 1 end

            BV.Velocity = move * speed + Vector3.new(0, y * speed, 0)
            BG.CFrame = CFrame.new(hrp.Position, hrp.Position + Vector3.new(cf.LookVector.X, 0, cf.LookVector.Z))
        end
    end)
end

-- ===== Verify button behavior =====
verifyBtn.MouseButton1Click:Connect(function()
    status.Text = "Fetching keys..."
    verifyBtn.Active = false
    verifyBtn.AutoButtonColor = false
    local ok, msg = pcall(function()
        return checkKey(keyBox.Text)
    end)
    verifyBtn.Active = true
    verifyBtn.AutoButtonColor = true

    if not ok then
        status.Text = "Error: "..tostring(msg)
        return
    end

    local valid, reason = checkKey(keyBox.Text)
    if valid then
        status.Text = "Key valid — unlocking fly."
        -- small delay to let user see message
        task.delay(0.15, function()
            -- destroy key UI and create fly UI
            if sg and sg.Parent then sg:Destroy() end
            createFlyGuiAndStart()
        end)
    else
        status.Text = "Invalid: "..tostring(reason)
    end
end)

-- allow pressing Enter in the box to verify
keyBox.FocusLost:Connect(function(enter)
    if enter then
        verifyBtn.MouseButton1Click:Fire()
    end
end)

-- initial status
status.Text = "Enter key and press Verify."

-- end of script
