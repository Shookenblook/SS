-- Blueblurhub - Private Backdoor
local G2L = {}
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local LP = Players.LocalPlayer

-- Main UI Setup
G2L["1"] = Instance.new("ScreenGui", LP:WaitForChild("PlayerGui"))
G2L["1"].Name = "Blueblurhub"
G2L["1"].ResetOnSpawn = false

-- Main Frame
G2L["Main"] = Instance.new("Frame", G2L["1"])
G2L["Main"].Size = UDim2.new(0, 420, 0, 300)
G2L["Main"].Position = UDim2.new(0.5, -210, 0.5, -150)
G2L["Main"].BackgroundColor3 = Color3.fromRGB(15, 15, 18)
G2L["Main"].BorderSizePixel = 0
Instance.new("UICorner", G2L["Main"]).CornerRadius = UDim.new(0, 8)

-- Header
G2L["Header"] = Instance.new("Frame", G2L["Main"])
G2L["Header"].Size = UDim2.new(1, 0, 0, 34)
G2L["Header"].BackgroundColor3 = Color3.fromRGB(22, 22, 26)
G2L["Header"].BorderSizePixel = 0
Instance.new("UICorner", G2L["Header"]).CornerRadius = UDim.new(0, 8)

-- "Blueblurhub" label (blue)
G2L["TitleBlue"] = Instance.new("TextLabel", G2L["Header"])
G2L["TitleBlue"].Size = UDim2.new(0, 100, 1, 0)
G2L["TitleBlue"].Position = UDim2.new(0, 12, 0, 0)
G2L["TitleBlue"].Text = "Blueblurhub"
G2L["TitleBlue"].TextColor3 = Color3.fromRGB(0, 180, 255)
G2L["TitleBlue"].Font = Enum.Font.GothamBold
G2L["TitleBlue"].TextSize = 13
G2L["TitleBlue"].TextXAlignment = Enum.TextXAlignment.Left
G2L["TitleBlue"].BackgroundTransparency = 1

-- "Private Backdoor" label (gray)
G2L["TitleGray"] = Instance.new("TextLabel", G2L["Header"])
G2L["TitleGray"].Size = UDim2.new(1, -160, 1, 0)
G2L["TitleGray"].Position = UDim2.new(0, 118, 0, 0)
G2L["TitleGray"].Text = "Private Backdoor"
G2L["TitleGray"].TextColor3 = Color3.fromRGB(140, 140, 140)
G2L["TitleGray"].Font = Enum.Font.Gotham
G2L["TitleGray"].TextSize = 13
G2L["TitleGray"].TextXAlignment = Enum.TextXAlignment.Left
G2L["TitleGray"].BackgroundTransparency = 1

-- Close Button
G2L["Close"] = Instance.new("TextButton", G2L["Header"])
G2L["Close"].Size = UDim2.new(0, 24, 0, 24)
G2L["Close"].Position = UDim2.new(1, -30, 0, 5)
G2L["Close"].Text = "X"
G2L["Close"].TextColor3 = Color3.fromRGB(170, 170, 170)
G2L["Close"].BackgroundTransparency = 1
G2L["Close"].Font = Enum.Font.GothamBold
G2L["Close"].TextSize = 13

-- Code Box
G2L["CodeBox"] = Instance.new("TextBox", G2L["Main"])
G2L["CodeBox"].Size = UDim2.new(0.94, 0, 0, 90)
G2L["CodeBox"].Position = UDim2.new(0.03, 0, 0, 44)
G2L["CodeBox"].BackgroundColor3 = Color3.fromRGB(25, 25, 30)
G2L["CodeBox"].Text = "-- Écris ton script ici"
G2L["CodeBox"].TextColor3 = Color3.fromRGB(136, 136, 136)
G2L["CodeBox"].Font = Enum.Font.Code
G2L["CodeBox"].TextSize = 12
G2L["CodeBox"].TextXAlignment = Enum.TextXAlignment.Left
G2L["CodeBox"].TextYAlignment = Enum.TextYAlignment.Top
G2L["CodeBox"].ClearTextOnFocus = false
G2L["CodeBox"].MultiLine = true
Instance.new("UICorner", G2L["CodeBox"]).CornerRadius = UDim.new(0, 4)

-- Asset Image (centered)
G2L["Asset"] = Instance.new("ImageLabel", G2L["Main"])
G2L["Asset"].Size = UDim2.new(0, 120, 0, 120)
G2L["Asset"].Position = UDim2.new(0.5, -60, 0, 144)
G2L["Asset"].Image = "rbxassetid://342190201"
G2L["Asset"].BackgroundTransparency = 1
G2L["Asset"].ScaleType = Enum.ScaleType.Fit

-- Button helper
local function createBtn(text, pos, size)
    local b = Instance.new("TextButton", G2L["Main"])
    b.Size = size
    b.Position = pos
    b.Text = text
    b.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    b.TextColor3 = Color3.fromRGB(255, 255, 255)
    b.Font = Enum.Font.GothamMedium
    b.TextSize = 13
    b.BorderSizePixel = 0
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4)
    return b
end

local iconSize = UDim2.new(0, 32, 0, 32)
local btnY = UDim2.new(0, 0, 1, -42)

local Exec  = createBtn("Execute", UDim2.new(0.03, 0, 1, -42), UDim2.new(0, 100, 0, 32))
local Clear = createBtn("Clear",   UDim2.new(0.03, 104, 1, -42), UDim2.new(0, 100, 0, 32))
local Eye   = createBtn("👁",      UDim2.new(1, -148, 1, -42), iconSize)
local Ref1  = createBtn("↺",      UDim2.new(1, -112, 1, -42), iconSize)
local Ref2  = createBtn("⟳",      UDim2.new(1, -76,  1, -42), iconSize)
local RC    = createBtn("RC",      UDim2.new(1, -40,  1, -42), iconSize)
RC.TextColor3 = Color3.fromRGB(0, 180, 255)
RC.BackgroundColor3 = Color3.fromRGB(0, 40, 60)

--- Dragging Logic ---
local dragging, dragInput, dragStart, startPos
local function update(input)
    local delta = input.Position - dragStart
    G2L["Main"].Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end
G2L["Header"].InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true; dragStart = input.Position; startPos = G2L["Main"].Position
        input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
    end
end)
G2L["Header"].InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
end)
UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then update(input) end
end)

--- Functional Logic ---
Exec.MouseButton1Click:Connect(function()
    local remote = game:GetService("ReplicatedStorage"):FindFirstChild("MangoRemote")
    if remote then
        remote:FireServer("REQUIRE", G2L["CodeBox"].Text)
    else
        warn("Blueblurhub: Bridge not found!")
    end
end)

Clear.MouseButton1Click:Connect(function() G2L["CodeBox"].Text = "" end)
G2L["Close"].MouseButton1Click:Connect(function() G2L["1"]:Destroy() end)

-- Eye toggle (hide/show GUI)
local guiVisible = true
Eye.MouseButton1Click:Connect(function()
    guiVisible = not guiVisible
    G2L["Main"].Visible = guiVisible
end)
