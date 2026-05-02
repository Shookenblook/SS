-- Blueblurhub - Private Backdoor (Patrihub-style)
local G2L = {}
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local LP = Players.LocalPlayer

-- ScreenGui
G2L["1"] = Instance.new("ScreenGui", LP:WaitForChild("PlayerGui"))
G2L["1"].Name = "Blueblurhub"
G2L["1"].ResetOnSpawn = false
G2L["1"].ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Main Frame
G2L["2"] = Instance.new("Frame", G2L["1"])
G2L["2"].BorderSizePixel = 0
G2L["2"].BackgroundColor3 = Color3.fromRGB(27, 28, 33)
G2L["2"].Size = UDim2.new(0, 464, 0, 304)
G2L["2"].Position = UDim2.new(0.5, -232, 0.5, -152)
G2L["2"].BorderColor3 = Color3.fromRGB(0, 0, 0)
Instance.new("UICorner", G2L["2"])

-- Title Bar
G2L["3"] = Instance.new("Frame", G2L["2"])
G2L["3"].BorderSizePixel = 0
G2L["3"].BackgroundColor3 = Color3.fromRGB(26, 27, 32)
G2L["3"].Size = UDim2.new(0, 451, 0, 23)
G2L["3"].Position = UDim2.new(0.01509, 0, 0.01974, 0)
G2L["3"].Name = "TitleBar"
Instance.new("UICorner", G2L["3"])
local titleStroke = Instance.new("UIStroke", G2L["3"])
titleStroke.Color = Color3.fromRGB(98, 98, 98)

-- Title Label (RichText)
G2L["6"] = Instance.new("TextLabel", G2L["3"])
G2L["6"].BorderSizePixel = 0
G2L["6"].TextSize = 16
G2L["6"].BackgroundTransparency = 1
G2L["6"].FontFace = Font.new([[rbxasset://fonts/families/GothamSSm.json]], Enum.FontWeight.Medium, Enum.FontStyle.Italic)
G2L["6"].TextColor3 = Color3.fromRGB(255, 255, 255)
G2L["6"].RichText = true
G2L["6"].Size = UDim2.new(0, 300, 0, 23)
G2L["6"].Position = UDim2.new(0.03, 0, 0, 0)
G2L["6"].Text = [[<font color="#00b4ff">Blueblurhub</font> - <font color="#ffffff">Private Backdoor</font>]]
G2L["6"].TextXAlignment = Enum.TextXAlignment.Left

-- Close Button (X image)
G2L["13"] = Instance.new("ImageButton", G2L["2"])
G2L["13"].BackgroundTransparency = 1
G2L["13"].ZIndex = 2
G2L["13"].Image = [[rbxassetid://3926305904]]
G2L["13"].ImageRectSize = Vector2.new(24, 24)
G2L["13"].ImageRectOffset = Vector2.new(284, 4)
G2L["13"].Size = UDim2.new(0, 24, 0, 24)
G2L["13"].Position = UDim2.new(0.92026, 0, 0.01777, 0)
G2L["13"].Name = "CloseButton"

-- Executor Frame
G2L["8"] = Instance.new("Frame", G2L["2"])
G2L["8"].BorderSizePixel = 0
G2L["8"].BackgroundColor3 = Color3.fromRGB(18, 20, 23)
G2L["8"].Size = UDim2.new(0, 451, 0, 215)
G2L["8"].Position = UDim2.new(0.01509, 0, 0.11842, 0)
G2L["8"].Name = "Executor"
Instance.new("UICorner", G2L["8"])
local execStroke = Instance.new("UIStroke", G2L["8"])
execStroke.Color = Color3.fromRGB(98, 98, 98)

-- Watermark image (centered, semi-transparent)
G2L["12"] = Instance.new("ImageLabel", G2L["8"])
G2L["12"].BorderSizePixel = 0
G2L["12"].BackgroundTransparency = 1
G2L["12"].ImageTransparency = 0.78
G2L["12"].Image = [[rbxassetid://342190201]]
G2L["12"].Size = UDim2.new(0, 150, 0, 150)
G2L["12"].AnchorPoint = Vector2.new(0.5, 0.5)
G2L["12"].Position = UDim2.new(0.5, 0, 0.5, 0)
G2L["12"].ScaleType = Enum.ScaleType.Fit

-- Mode label (top-right of executor)
G2L["ModeLabel"] = Instance.new("TextLabel", G2L["8"])
G2L["ModeLabel"].Size = UDim2.new(0, 200, 0, 16)
G2L["ModeLabel"].Position = UDim2.new(1, -205, 0, 2)
G2L["ModeLabel"].BackgroundTransparency = 1
G2L["ModeLabel"].Text = "MODE: LOADSTRING"
G2L["ModeLabel"].TextColor3 = Color3.fromRGB(0, 180, 255)
G2L["ModeLabel"].Font = Enum.Font.GothamBold
G2L["ModeLabel"].TextSize = 10
G2L["ModeLabel"].TextXAlignment = Enum.TextXAlignment.Right
G2L["ModeLabel"].ZIndex = 3

-- TextBox
G2L["b"] = Instance.new("TextBox", G2L["8"])
G2L["b"].CursorPosition = -1
G2L["b"].TextXAlignment = Enum.TextXAlignment.Left
G2L["b"].TextYAlignment = Enum.TextYAlignment.Top
G2L["b"].BorderSizePixel = 0
G2L["b"].TextSize = 15
G2L["b"].TextColor3 = Color3.fromRGB(205, 205, 205)
G2L["b"].BackgroundTransparency = 1
G2L["b"].FontFace = Font.new([[rbxasset://fonts/families/Inconsolata.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal)
G2L["b"].Size = UDim2.new(0, 444, 0, 200)
G2L["b"].Position = UDim2.new(0, 4, 0, 16)
G2L["b"].Text = ""
G2L["b"].PlaceholderText = "-- paste require(id) or loadstring script here"
G2L["b"].PlaceholderColor3 = Color3.fromRGB(70, 72, 80)
G2L["b"].ClearTextOnFocus = false
G2L["b"].MultiLine = true
G2L["b"].ZIndex = 2

-- Button factory
local function makeBtn(parent, text, pos, size)
    local b = Instance.new("TextButton", parent)
    b.TextSize = 15
    b.AutoButtonColor = false
    b.TextColor3 = Color3.fromRGB(255, 255, 255)
    b.BackgroundColor3 = Color3.fromRGB(18, 20, 23)
    b.FontFace = Font.new([[rbxasset://fonts/families/GothamSSm.json]], Enum.FontWeight.Medium, Enum.FontStyle.Normal)
    b.Size = size
    b.Position = pos
    b.Text = text
    b.BorderSizePixel = 0
    local c = Instance.new("UICorner", b)
    c.CornerRadius = UDim.new(0, 6)
    local s = Instance.new("UIStroke", b)
    s.Transparency = 0.5
    s.Color = Color3.fromRGB(98, 98, 98)
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    return b
end

local function makeIconBtn(parent, imageId, pos, rectOffset, rectSize)
    local b = Instance.new("TextButton", parent)
    b.TextTransparency = 1
    b.Text = ""
    b.AutoButtonColor = false
    b.BackgroundColor3 = Color3.fromRGB(18, 20, 23)
    b.Size = UDim2.new(0, 34, 0, 34)
    b.Position = pos
    b.BorderSizePixel = 0
    local c = Instance.new("UICorner", b)
    c.CornerRadius = UDim.new(0, 6)
    local s = Instance.new("UIStroke", b)
    s.Transparency = 0.5
    s.Color = Color3.fromRGB(98, 98, 98)
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    local img = Instance.new("ImageLabel", b)
    img.BackgroundTransparency = 1
    img.AnchorPoint = Vector2.new(0.5, 0.5)
    img.Position = UDim2.new(0.5, 0, 0.5, 0)
    img.Size = UDim2.new(0, 22, 0, 22)
    img.Image = imageId
    if rectOffset then img.ImageRectOffset = rectOffset end
    if rectSize  then img.ImageRectSize  = rectSize  end
    return b
end

-- Execute button
local Exec = makeBtn(G2L["2"], "Execute",
    UDim2.new(0.01472, 0, 0.89009, 0),
    UDim2.new(0, 130, 0, 33))

-- Clear button
local Clear = makeBtn(G2L["2"], "Clear",
    UDim2.new(0.31644, 0, 0.89009, 0),
    UDim2.new(0, 99, 0, 33))

-- Hide button (eye icon)
local HideBtn = makeIconBtn(G2L["2"],
    [[rbxassetid://3926307971]],
    UDim2.new(0.63206, 0, 0.88645, 0),
    Vector2.new(84, 44), Vector2.new(36, 36))

-- RE-execute button (refresh icon)
local ReExecBtn = makeIconBtn(G2L["2"],
    [[rbxassetid://7072721335]],
    UDim2.new(0.72217, 0, 0.88810, 0),
    nil, nil)

-- Copy button
local CopyBtn = makeIconBtn(G2L["2"],
    [[rbxassetid://10734933966]],
    UDim2.new(0.80891, 0, 0.88974, 0),
    nil, nil)

-- R6 button
local R6Btn = makeIconBtn(G2L["2"],
    [[rbxassetid://4941166750]],
    UDim2.new(0.89788, 0, 0.88974, 0),
    nil, nil)

-- =====================
-- MODE DETECTION
-- =====================
local function updateMode(text)
    text = text:match("^%s*(.-)%s*$") or ""
    if text:match("^require%(%d+%)") then
        G2L["ModeLabel"].Text = "MODE: REQUIRE"
        G2L["ModeLabel"].TextColor3 = Color3.fromRGB(255, 180, 0)
    elseif text:sub(1, 4) == "http" then
        G2L["ModeLabel"].Text = "MODE: LOADSTRING (URL)"
        G2L["ModeLabel"].TextColor3 = Color3.fromRGB(0, 255, 128)
    else
        G2L["ModeLabel"].Text = "MODE: LOADSTRING"
        G2L["ModeLabel"].TextColor3 = Color3.fromRGB(0, 180, 255)
    end
end

G2L["b"]:GetPropertyChangedSignal("Text"):Connect(function()
    updateMode(G2L["b"].Text)
end)

-- =====================
-- EXECUTE LOGIC
-- =====================
local lastScript = ""

local function doExecute()
    local remote = game:GetService("ReplicatedStorage"):FindFirstChild("MangoRemote")
    if not remote then
        warn("[Blueblurhub] MangoRemote not found! Is the bridge script running?")
        return
    end

    local text = G2L["b"].Text:match("^%s*(.-)%s*$")
    if text == "" then
        warn("[Blueblurhub] Nothing to execute.")
        return
    end

    lastScript = text

    local requireId = text:match("^require%((%d+)%)")
    if requireId then
        print("[Blueblurhub] Firing REQUIRE: " .. requireId)
        remote:FireServer("REQUIRE", requireId)
        return
    end

    if text:sub(1, 4) == "http" then
        print("[Blueblurhub] Firing LOADSTRING (URL)")
        remote:FireServer("LOADSTRING", text)
        return
    end

    print("[Blueblurhub] Firing LOADSTRING (raw Lua)")
    remote:FireServer("LOADSTRING", text)
end

-- =====================
-- BUTTON CONNECTIONS
-- =====================
Exec.MouseButton1Click:Connect(doExecute)

Clear.MouseButton1Click:Connect(function()
    G2L["b"].Text = ""
end)

G2L["13"].MouseButton1Click:Connect(function()
    G2L["1"]:Destroy()
end)

HideBtn.MouseButton1Click:Connect(function()
    G2L["2"].Visible = false
end)

-- Shift to show again
UIS.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.LeftShift or
       input.KeyCode == Enum.KeyCode.RightShift then
        G2L["2"].Visible = true
    end
end)

ReExecBtn.MouseButton1Click:Connect(function()
    if lastScript ~= "" then
        G2L["b"].Text = lastScript
        doExecute()
    else
        warn("[Blueblurhub] No previous script to re-run.")
    end
end)

CopyBtn.MouseButton1Click:Connect(function()
    -- Sets clipboard if supported, otherwise just warns
    local ok = pcall(function()
        setclipboard(G2L["b"].Text)
    end)
    if not ok then
        warn("[Blueblurhub] Clipboard not supported in this environment.")
    end
end)

R6Btn.MouseButton1Click:Connect(function()
    local char = LP.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then hum.RigType = Enum.HumanoidRigType.R6 end
end)

-- =====================
-- SMOOTH TWEEN DRAG
-- =====================
local dragging = false
local dragInput, mousePos, framePos

G2L["3"].InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or
       input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        mousePos = input.Position
        framePos = G2L["2"].Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

G2L["3"].InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or
       input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UIS.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - mousePos
        TweenService:Create(G2L["2"],
            TweenInfo.new(0.05, Enum.EasingStyle.Linear),
            {Position = UDim2.new(
                framePos.X.Scale, framePos.X.Offset + delta.X,
                framePos.Y.Scale, framePos.Y.Offset + delta.Y
            )}
        ):Play()
    end
end)

print("[Blueblurhub] Private Backdoor successfully initialized.")

return G2L["1"]
