local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local MarketplaceService = game:GetService("MarketplaceService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TeleportService = game:GetService("TeleportService")

local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()

local oldUI = Player:WaitForChild("PlayerGui"):FindFirstChild("AnimeSquadronUI")
if oldUI then oldUI:Destroy() end

local CONFIG_FILE_NAME = "webhook_config.json"
local DISCORD_WEBHOOK_URL = ""

local config = {
    url = DISCORD_WEBHOOK_URL,
    enabled = true,
    showItems = true,
    autoReplay = true,
    autoNext = false,
    intervalHours = 1
}

local sessionStats = {
    totalMatches = 0,
    startTime = tick(),
    itemsEarned = {},
    intervalMatches = 0,
    intervalItems = {}
}

local oldSnapshot = {}
local blacklist = {
    ["time_spent"] = true, ["playtime"] = true, ["games"] = true, ["progress"] = true,
    ["kills"] = true, ["id"] = true, ["amount"] = true, ["log"] = true,
    ["map"] = true, ["stage"] = true, ["exp"] = true, ["xp"] = true, ["ingame"] = true
}

local function saveConfig()
    if writefile then
        pcall(function()
            writefile(CONFIG_FILE_NAME, HttpService:JSONEncode(config))
        end)
    end
end

local function loadConfig()
    if readfile and isfile and isfile(CONFIG_FILE_NAME) then
        pcall(function()
            local saved = HttpService:JSONDecode(readfile(CONFIG_FILE_NAME))
            if type(saved) == "table" then
                for k, v in pairs(saved) do
                    config[k] = v
                end
            end
        end)
    end
end

loadConfig()

local Colors = {
    Background = Color3.fromRGB(44, 44, 44),
    Panel = Color3.fromRGB(58, 58, 58),
    Border = Color3.fromRGB(74, 56, 40),
    Primary = Color3.fromRGB(93, 187, 99),
    Hover = Color3.fromRGB(126, 226, 122),
    Danger = Color3.fromRGB(214, 75, 75),
    Text = Color3.fromRGB(240, 240, 240),
    SecondaryText = Color3.fromRGB(189, 189, 189),
    OakWood = Color3.fromRGB(102, 76, 42)
}

local function Create(className, properties)
    local inst = Instance.new(className)
    for prop, val in pairs(properties) do
        inst[prop] = val
    end
    return inst
end

local function ApplyCorner(parent, radius)
    Create("UICorner", {CornerRadius = UDim.new(0, radius or 8), Parent = parent})
end

local function ApplyStroke(parent, color, thickness, transparency)
    Create("UIStroke", {
        Color = color or Colors.Border,
        Thickness = thickness or 2,
        Transparency = transparency or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = parent
    })
end

local function PlayHoverAnimation(obj)
    local scale = obj:FindFirstChild("UIScale") or Create("UIScale", {Parent = obj})
    obj.MouseEnter:Connect(function()
        TweenService:Create(scale, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Scale = 1.05}):Play()
    end)
    obj.MouseLeave:Connect(function()
        TweenService:Create(scale, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Scale = 1}):Play()
    end)
end

local function PlayClickAnimation(obj)
    local scale = obj:FindFirstChild("UIScale") or Create("UIScale", {Parent = obj})
    obj.MouseButton1Down:Connect(function()
        TweenService:Create(scale, TweenInfo.new(0.1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Scale = 0.95}):Play()
    end)
    obj.MouseButton1Up:Connect(function()
        TweenService:Create(scale, TweenInfo.new(0.1, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out), {Scale = 1.05}):Play()
    end)
end

local function SpawnParticles(parent, position, color)
    for i = 1, 6 do
        local particle = Create("Frame", {
            Size = UDim2.new(0, 4, 0, 4),
            Position = position,
            BackgroundColor3 = color,
            Parent = parent,
            ZIndex = 100
        })
        ApplyCorner(particle, i)
        local randX = math.random(-50, 50)
        local randY = math.random(-50, 50)
        local targetPos = UDim2.new(position.X.Scale, position.X.Offset + randX, position.Y.Scale, position.Y.Offset + randY)
        TweenService:Create(particle, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Position = targetPos,
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 0, 0, 0)
        }):Play()
        task.delay(0.5, function() particle:Destroy() end)
    end
end

local ScreenGui = Create("ScreenGui", {Name = "AnimeSquadronUI", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = Player:WaitForChild("PlayerGui")})
local FloatBtn = Create("TextButton", {Name = "FloatBtn", Size = UDim2.new(0, 60, 0, 60), Position = UDim2.new(0, 50, 0.5, -30), BackgroundColor3 = Colors.Primary, Text = "", Visible = false, ClipsDescendants = true, Parent = ScreenGui})
ApplyCorner(FloatBtn, 30) ApplyStroke(FloatBtn, Colors.Border, 3, 0) Create("UIScale", {Scale = 0, Parent = FloatBtn}) PlayHoverAnimation(FloatBtn) PlayClickAnimation(FloatBtn)

local FloatIcon = Create("ImageLabel", {Name = "Icon", Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Image = "rbxthumb://type=Asset&id=9676276958&w=420&h=420", ScaleType = Enum.ScaleType.Crop, Parent = FloatBtn})
ApplyCorner(FloatIcon, 30)

local floatDragging, floatDragInput, floatDragStart, floatStartPos
FloatBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        floatDragging = true floatDragStart = input.Position floatStartPos = FloatBtn.Position
        input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then floatDragging = false end end)
    end
end)
FloatBtn.InputChanged:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then floatDragInput = input end end)
UserInputService.InputChanged:Connect(function(input)
    if input == floatDragInput and floatDragging then
        local delta = input.Position - floatDragStart
        FloatBtn.Position = UDim2.new(floatStartPos.X.Scale, floatStartPos.X.Offset + delta.X, floatStartPos.Y.Scale, floatStartPos.Y.Offset + delta.Y)
    end
end)

local MainFrame = Create("Frame", {Name = "MainFrame", Size = UDim2.new(0, 600, 0, 400), Position = UDim2.new(0.5, -300, 0.5, -200), BackgroundColor3 = Colors.Background, ClipsDescendants = true, Parent = ScreenGui})
ApplyCorner(MainFrame, 10) ApplyStroke(MainFrame, Colors.Border, 3, 0)
Create("UIPadding", {PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4), PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4), Parent = MainFrame})
Create("UIScale", {Scale = 0, Parent = MainFrame})

TweenService:Create(MainFrame.UIScale, TweenInfo.new(0.5, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Scale = 1}):Play()

local dragging, dragInput, dragStart, startPos
MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true dragStart = input.Position startPos = MainFrame.Position
        input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
    end
end)
MainFrame.InputChanged:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end end)
UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        TweenService:Create(MainFrame, TweenInfo.new(0.1, Enum.EasingStyle.Linear), {Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)}):Play()
    end
end)

local Header = Create("Frame", {Name = "Header", Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = Colors.Panel, Parent = MainFrame})
ApplyCorner(Header, 8)

local TitleLabel = Create("TextLabel", {Size = UDim2.new(0, 250, 1, 0), Position = UDim2.new(0, 10, 0, 0), BackgroundTransparency = 1, Text = "ANIME SQUADRON", TextColor3 = Colors.Text, TextScaled = true, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left, Parent = Header})
Create("UIPadding", {PaddingBottom = UDim.new(0, 8), PaddingTop = UDim.new(0, 8), Parent = TitleLabel})

local VersionLabel = Create("TextLabel", {Size = UDim2.new(0, 50, 1, 0), Position = UDim2.new(0, 210, 0, 0), BackgroundTransparency = 1, Text = "v1.0", TextColor3 = Colors.SecondaryText, TextScaled = true, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left, Parent = Header})
Create("UIPadding", {PaddingBottom = UDim.new(0, 12), PaddingTop = UDim.new(0, 12), Parent = VersionLabel})

local StatusDot = Create("Frame", {Size = UDim2.new(0, 8, 0, 8), Position = UDim2.new(1, -20, 0.5, -4), BackgroundColor3 = Colors.Primary, Parent = Header})
ApplyCorner(StatusDot, 4)
task.spawn(function()
    while true do
        TweenService:Create(StatusDot, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {BackgroundTransparency = 0.5}):Play() task.wait(1)
        TweenService:Create(StatusDot, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {BackgroundTransparency = 0}):Play() task.wait(1)
    end
end)

local CloseBtn = Create("TextButton", {Size = UDim2.new(0, 24, 0, 24), Position = UDim2.new(1, -58, 0.5, -12), BackgroundColor3 = Colors.Danger, Text = "X", TextColor3 = Colors.Text, Font = Enum.Font.GothamBold, TextSize = 14, Parent = Header})
ApplyCorner(CloseBtn, 6) PlayHoverAnimation(CloseBtn) PlayClickAnimation(CloseBtn)
CloseBtn.MouseButton1Click:Connect(function()
    TweenService:Create(MainFrame.UIScale, TweenInfo.new(0.3, Enum.EasingStyle.Exponential, Enum.EasingDirection.In), {Scale = 0}):Play()
    task.wait(0.3) ScreenGui:Destroy()
end)

local MinBtn = Create("TextButton", {Size = UDim2.new(0, 24, 0, 24), Position = UDim2.new(1, -90, 0.5, -12), BackgroundColor3 = Colors.OakWood, Text = "-", TextColor3 = Colors.Text, Font = Enum.Font.GothamBold, TextSize = 14, Parent = Header})
ApplyCorner(MinBtn, 6) PlayHoverAnimation(MinBtn) PlayClickAnimation(MinBtn)

MinBtn.MouseButton1Click:Connect(function()
    TweenService:Create(MainFrame.UIScale, TweenInfo.new(0.3, Enum.EasingStyle.Exponential, Enum.EasingDirection.In), {Scale = 0}):Play()
    task.wait(0.2) FloatBtn.Visible = true
    FloatBtn.Position = UDim2.new(MainFrame.Position.X.Scale, MainFrame.Position.X.Offset + MainFrame.Size.X.Offset/2 - 30, MainFrame.Position.Y.Scale, MainFrame.Position.Y.Offset + 20)
    TweenService:Create(FloatBtn.UIScale, TweenInfo.new(0.4, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Scale = 1}):Play()
end)

FloatBtn.MouseButton1Click:Connect(function()
    TweenService:Create(FloatBtn.UIScale, TweenInfo.new(0.3, Enum.EasingStyle.Exponential, Enum.EasingDirection.In), {Scale = 0}):Play()
    task.wait(0.2) FloatBtn.Visible = false
    MainFrame.Position = UDim2.new(FloatBtn.Position.X.Scale, FloatBtn.Position.X.Offset - MainFrame.Size.X.Offset/2 + 30, FloatBtn.Position.Y.Scale, FloatBtn.Position.Y.Offset)
    TweenService:Create(MainFrame.UIScale, TweenInfo.new(0.4, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Scale = 1}):Play()
end)

local GrassStrip = Create("Frame", {Size = UDim2.new(1, 0, 0, 4), Position = UDim2.new(0, 0, 1, 0), BackgroundColor3 = Colors.Primary, Parent = Header})
Create("UIGradient", {Color = ColorSequence.new(Colors.Hover, Colors.Primary), Rotation = 90, Parent = GrassStrip})

local Body = Create("Frame", {Name = "Body", Size = UDim2.new(1, 0, 1, -44), Position = UDim2.new(0, 0, 0, 44), BackgroundTransparency = 1, Parent = MainFrame})
local Sidebar = Create("Frame", {Name = "Sidebar", Size = UDim2.new(0, 140, 1, 0), BackgroundColor3 = Colors.Panel, Parent = Body})
ApplyCorner(Sidebar, 8) Create("UIListLayout", {Padding = UDim.new(0, 8), Parent = Sidebar})
Create("UIPadding", {PaddingTop = UDim.new(0, 8), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), Parent = Sidebar})

local ContentArea = Create("Frame", {Name = "Content", Size = UDim2.new(1, -150, 1, -10), Position = UDim2.new(0, 150, 0, 10), BackgroundColor3 = Colors.Panel, Parent = Body})
ApplyCorner(ContentArea, 8) ApplyStroke(ContentArea, Colors.Border, 1, 0.5)

local Tabs = { Dashboard = {}, Automation = {}, Webhook = {} }
local TabButtons = {}
local FirstTab = true

for tabName, _ in pairs(Tabs) do
    local TabFrame = Create("ScrollingFrame", {Name = tabName, Size = UDim2.new(1, -20, 1, -20), Position = UDim2.new(0, 10, 0, 10), BackgroundTransparency = 1, ScrollBarThickness = 4, ScrollBarImageColor3 = Colors.Primary, Visible = FirstTab, Parent = ContentArea})
    Create("UIListLayout", {Padding = UDim.new(0, 10), Parent = TabFrame})
    Tabs[tabName] = TabFrame

    local Btn = Create("TextButton", {Name = tabName .. "Btn", Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = FirstTab and Colors.Primary or Colors.Background, Text = tabName, TextColor3 = Colors.Text, Font = Enum.Font.GothamSemibold, TextSize = 12, Parent = Sidebar})
    ApplyCorner(Btn, 6) ApplyStroke(Btn, Colors.Border, 1, 0.5) PlayHoverAnimation(Btn) PlayClickAnimation(Btn)
    TabButtons[tabName] = Btn

    Btn.MouseButton1Click:Connect(function()
        for name, frame in pairs(Tabs) do
            frame.Visible = (name == tabName)
            TabButtons[name].BackgroundColor3 = (name == tabName) and Colors.Primary or Colors.Background
            if name == tabName then
                frame.Position = UDim2.new(0, 20, 0, 10)
                TweenService:Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.new(0, 10, 0, 10)}):Play()
            end
        end
    end)
    FirstTab = false
end

local UIElements = {}

function UIElements:CreateButton(tabName, text, callback)
    local tab = Tabs[tabName]
    local btn = Create("TextButton", {Size = UDim2.new(1, 0, 0, 35), BackgroundColor3 = Colors.Background, Text = "", Parent = tab})
    ApplyCorner(btn, 6) ApplyStroke(btn, Colors.Primary, 1, 0.5)
    Create("TextLabel", {Size = UDim2.new(1, -20, 1, 0), Position = UDim2.new(0, 10, 0, 0), BackgroundTransparency = 1, Text = text, TextColor3 = Colors.Text, Font = Enum.Font.Gotham, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, Parent = btn})
    PlayHoverAnimation(btn) PlayClickAnimation(btn)
    btn.MouseButton1Click:Connect(function()
        SpawnParticles(tab, UDim2.new(0.5, 0, 0.5, 0), Colors.Primary)
        TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3 = Colors.Hover}):Play() task.wait(0.1)
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Colors.Background}):Play()
        if callback then callback() end
    end)
end

function UIElements:CreateToggle(tabName, text, default, callback)
    local tab = Tabs[tabName]
    local state = default or false

    local toggleFrame = Create("Frame", {Size = UDim2.new(1, 0, 0, 35), BackgroundColor3 = Colors.Background, Parent = tab})
    ApplyCorner(toggleFrame, 6) ApplyStroke(toggleFrame, Colors.Border, 1, 0.5)
    Create("TextLabel", {Size = UDim2.new(1, -60, 1, 0), Position = UDim2.new(0, 10, 0, 0), BackgroundTransparency = 1, Text = text, TextColor3 = Colors.Text, Font = Enum.Font.Gotham, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, Parent = toggleFrame})

    local SwitchBg = Create("TextButton", {Size = UDim2.new(0, 40, 0, 20), Position = UDim2.new(1, -50, 0.5, -10), BackgroundColor3 = state and Colors.Primary or Colors.Danger, Text = "", Parent = toggleFrame})
    ApplyCorner(SwitchBg, 10)
    local Knob = Create("Frame", {Size = UDim2.new(0, 16, 0, 16), Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8), BackgroundColor3 = Colors.Text, Parent = SwitchBg})
    ApplyCorner(Knob, 8) ApplyStroke(Knob, Colors.Border, 1, 0.5) PlayHoverAnimation(SwitchBg) PlayClickAnimation(SwitchBg)

    local toggleObj = {}
    function toggleObj:Set(newState)
        state = newState
        local targetColor = state and Colors.Primary or Colors.Danger
        local targetPos = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
        TweenService:Create(SwitchBg, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = targetColor}):Play()
        TweenService:Create(Knob, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = targetPos}):Play()
    end

    SwitchBg.MouseButton1Click:Connect(function()
        state = not state
        SpawnParticles(toggleFrame, SwitchBg.Position + UDim2.new(0, 20, 0, 10), state and Colors.Primary or Colors.Danger)
        toggleObj:Set(state)
        if callback then callback(state) end
    end)
    return toggleObj
end

function UIElements:CreateTextBox(tabName, placeholder, initialText, callback)
    local tab = Tabs[tabName]
    local box = Create("TextBox", {Size = UDim2.new(1, 0, 0, 35), BackgroundColor3 = Colors.Background, Text = initialText or "", PlaceholderText = placeholder, PlaceholderColor3 = Colors.SecondaryText, TextColor3 = Colors.Text, Font = Enum.Font.Gotham, TextSize = 11, ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left, Parent = tab})
    ApplyCorner(box, 6) ApplyStroke(box, Colors.Border, 1, 0.5) Create("UIPadding", {PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), Parent = box})

    box.Focused:Connect(function()
        TweenService:Create(box, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = Colors.Panel}):Play()
        local stroke = box:FindFirstChild("UIStroke") if stroke then TweenService:Create(stroke, TweenInfo.new(0.3), {Color = Colors.Primary, Thickness = 2}):Play() end
    end)
    box.FocusLost:Connect(function()
        TweenService:Create(box, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = Colors.Background}):Play()
        local stroke = box:FindFirstChild("UIStroke") if stroke then TweenService:Create(stroke, TweenInfo.new(0.3), {Color = Colors.Border, Thickness = 1}):Play() end
        if callback then callback(box.Text) end
    end)
end

function UIElements:CreateStatCard(tabName, title, value)
    local tab = Tabs[tabName]
    local card = Create("Frame", {Size = UDim2.new(1, -10, 0, 60), BackgroundColor3 = Colors.Background, Parent = tab})
    ApplyCorner(card, 6) ApplyStroke(card, Colors.Border, 1, 0.5)
    Create("TextLabel", {Size = UDim2.new(1, -20, 0, 20), Position = UDim2.new(0, 10, 0, 5), BackgroundTransparency = 1, Text = title, TextColor3 = Colors.SecondaryText, Font = Enum.Font.Gotham, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left, Parent = card})
    local ValueLabel = Create("TextLabel", {Size = UDim2.new(1, -20, 0, 30), Position = UDim2.new(0, 10, 0, 25), BackgroundTransparency = 1, Text = value, TextColor3 = Colors.Text, Font = Enum.Font.GothamBold, TextSize = 18, TextXAlignment = Enum.TextXAlignment.Left, Parent = card})
    
    return function(newValue)
        ValueLabel.Text = tostring(newValue)
    end
end

local function flatten(t, path, res)
    res = res or {} path = path or ""
    if type(t) ~= "table" then return res end
    for k, v in pairs(t) do
        local p = path == "" and tostring(k) or path .. "." .. tostring(k)
        if type(v) == "table" then flatten(v, p, res) else res[p] = v end
    end
    return res
end

local function takeSnapshot()
    local success, rawData = pcall(function() return ReplicatedStorage.Remotes.Players.get:InvokeServer() end)
    if success and type(rawData) == "table" then oldSnapshot = flatten(rawData) end
end

takeSnapshot()

local function formatTime(seconds)
    local minutes = math.floor(seconds / 60)
    local remSeconds = math.floor(seconds % 60)
    return string.format("%02d:%02d", minutes, remSeconds)
end

local function getMapName()
    local targets = {game, Workspace, ReplicatedStorage, Player}
    local attrNames = {"Map", "Stage", "CurrentMap", "MapName", "Level", "Zone"}
    for _, obj in pairs(targets) do
        if obj then
            for _, attr in pairs(attrNames) do
                local val = obj:GetAttribute(attr)
                if val and type(val) == "string" and val ~= "" and val:lower() ~= "ingame" and val:lower() ~= "in-game" then return val end
            end
        end
    end
    for _, name in pairs({"CurrentMap", "Map", "Stage", "MapName", "GameMode", "ActiveMap"}) do
        local obj = ReplicatedStorage:FindFirstChild(name) or Workspace:FindFirstChild(name)
        if obj and (obj:IsA("StringValue") or obj:IsA("ObjectValue")) and obj.Value and tostring(obj.Value) ~= "" then
            local valStr = tostring(obj.Value)
            if valStr:lower() ~= "ingame" and valStr:lower() ~= "in-game" and valStr:lower() ~= "map" then return valStr end
        end
    end
    local success, info = pcall(function() return MarketplaceService:GetProductInfo(game.PlaceId) end)
    if success and info and info.Name then
        local n = info.Name:lower()
        if not n:find("hub") and not n:find("lobby") and n ~= "ingame" and n ~= "in-game" then return info.Name end
    end
    return "Unknown Map"
end

local function trackMatchEnd()
    sessionStats.totalMatches = sessionStats.totalMatches + 1
    sessionStats.intervalMatches = sessionStats.intervalMatches + 1
    
    if config.showItems then
        local success, rawData = pcall(function() return ReplicatedStorage.Remotes.Players.get:InvokeServer() end)
        if success and type(rawData) == "table" then
            local newSnapshot = flatten(rawData)
            local seen = {}
            for p, val in pairs(newSnapshot) do
                local lastKey = p:match("[^.]+$") or p
                local lowerKey = lastKey:lower()
                if not blacklist[lowerKey] then
                    local oldVal = oldSnapshot[p]
                    local gained = 0
                    local isItem = false
                    if not oldVal then
                        if p:find("%.name$") and not p:find("%.stats%.") then gained = 1 isItem = true
                        elseif type(val) == "number" and val > 0 and not p:find("codes") then gained = val end
                    elseif type(val) == "number" and type(oldVal) == "number" and val > oldVal then gained = val - oldVal end
                    if gained > 0 then
                        local itemKey = isItem and tostring(val) or lastKey
                        if not seen[itemKey] then
                            seen[itemKey] = true
                            sessionStats.itemsEarned[itemKey] = (sessionStats.itemsEarned[itemKey] or 0) + gained
                            sessionStats.intervalItems[itemKey] = (sessionStats.intervalItems[itemKey] or 0) + gained
                        end
                    end
                end
            end
            oldSnapshot = newSnapshot
        end
    end
end

local function sendReport()
    if not config.enabled then return end
    local totalSessionTime = tick() - sessionStats.startTime
    
    local intervalChanges = {}
    for k, v in pairs(sessionStats.intervalItems) do
        table.insert(intervalChanges, "• " .. k .. ": +" .. tostring(v))
    end
    local intervalText = #intervalChanges > 0 and table.concat(intervalChanges, "\n") or "No items gained in this period"

    local totalSummary = {}
    for k, v in pairs(sessionStats.itemsEarned) do
        table.insert(totalSummary, "• " .. k .. ": " .. tostring(v))
    end
    local totalText = #totalSummary > 0 and table.concat(totalSummary, "\n") or "No items collected yet"

    local hourlyEstimates = {}
    for k, v in pairs(sessionStats.itemsEarned) do
        local perSecond = v / totalSessionTime
        table.insert(hourlyEstimates, "• " .. k .. ": ~" .. math.floor(perSecond * 3600) .. "/hr")
    end
    local hourlyText = #hourlyEstimates > 0 and table.concat(hourlyEstimates, "\n") or "N/A"

    local embed = {
        ["title"] = "📊 Periodic Farming Report Summary", ["color"] = 3447003,
        ["fields"] = {
            {["name"] = "👤 Player Profile", ["value"] = Player.Name, ["inline"] = true},
            {["name"] = "⏳ Active Session Time", ["value"] = formatTime(totalSessionTime), ["inline"] = true},
            {["name"] = "🔄 Matches In This Period", ["value"] = tostring(sessionStats.intervalMatches) .. " Matches", ["inline"] = true},
            {["name"] = "🎁 Items Earned (In This Interval)", ["value"] = "```diff\n" .. intervalText .. "\n```", ["inline"] = false},
            {["name"] = "📈 Current Farming Speed (Per Hour)", ["value"] = "```\n" .. hourlyText .. "\n```", ["inline"] = false},
            {["name"] = "🏆 Grand Cumulative Total (Whole Session)", ["value"] = "```yaml\n• Total Matches: " .. tostring(sessionStats.totalMatches) .. "\n" .. totalText .. "\n```", ["inline"] = false}
        },
        ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ")
    }

    local requestFunc = syn and syn.request or http_request or request or (http and http.request)
    if requestFunc then
        pcall(function()
            requestFunc({ Url = config.url, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = HttpService:JSONEncode({["embeds"] = {embed}}) })
        end)
    end

    sessionStats.intervalMatches = 0
    sessionStats.intervalItems = {}
end

local function doAntiAFKClick()
    local camera = Workspace.CurrentCamera if not camera then return end
    local size = camera.ViewportSize
    VirtualInputManager:SendMouseButtonEvent(size.X / 2, size.Y / 2, 1, true, game, 1) task.wait(0.05)
    VirtualInputManager:SendMouseButtonEvent(size.X / 2, size.Y / 2, 1, false, game, 1)
end

local updateSessionTime = UIElements:CreateStatCard("Dashboard", "Session Accumulated Time", "00:00")
local updateMatches = UIElements:CreateStatCard("Dashboard", "Total Matches Played", "0")

local autoReplayToggle, autoNextToggle
autoReplayToggle = UIElements:CreateToggle("Automation", "Auto Replay (End Match)", config.autoReplay, function(val)
    config.autoReplay = val
    if val then config.autoNext = false if autoNextToggle then autoNextToggle:Set(false) end end
    saveConfig()
end)
autoNextToggle = UIElements:CreateToggle("Automation", "Auto Next Stage", config.autoNext, function(val)
    config.autoNext = val
    if val then config.autoReplay = false if autoReplayToggle then autoReplayToggle:Set(false) end end
    saveConfig()
end)

UIElements:CreateToggle("Webhook", "Enable Discord Webhook", config.enabled, function(val) config.enabled = val saveConfig() end)
UIElements:CreateToggle("Webhook", "Show New Items in Report", config.showItems, function(val) config.showItems = val saveConfig() end)
UIElements:CreateTextBox("Webhook", "Webhook Interval (Hours) e.g. 1 or 0.5", tostring(config.intervalHours), function(text) 
    local num = tonumber(text) 
    if num and num > 0 then 
        config.intervalHours = num 
        saveConfig() 
    end 
end)
UIElements:CreateTextBox("Webhook", "Paste Discord Webhook URL...", config.url, function(text) config.url = text saveConfig() end)
UIElements:CreateButton("Webhook", "Test Send Live Webhook", function() sendReport() end)

task.spawn(function()
    while MainFrame.Parent do
        local totalSessionTime = tick() - sessionStats.startTime
        updateSessionTime(formatTime(totalSessionTime))
        updateMatches(tostring(sessionStats.totalMatches))
        task.wait(1)
    end
end)

ReplicatedStorage.Remotes.Game.ending.OnClientEvent:Connect(function()
    task.spawn(trackMatchEnd) task.wait(0.2)
    pcall(function()
        local gameRemotes = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("Game")
        if gameRemotes then
            if config.autoNext then
                local nextEvent = gameRemotes:FindFirstChild("next")
                if nextEvent and nextEvent:IsA("RemoteEvent") then nextEvent:FireServer() end
            elseif config.autoReplay then
                local replayEvent = gameRemotes:FindFirstChild("replay")
                if replayEvent and replayEvent:IsA("RemoteEvent") then replayEvent:FireServer() end
            end
        end
    end)
end)

task.spawn(function()
    while true do
        local waitTime = (config.intervalHours or 1) * 3600
        task.wait(waitTime)
        pcall(sendReport)
    end
end)

local guiServiceSuccess, guiProvider = pcall(function() return game:GetService("GuiService") end)
if guiServiceSuccess then
    guiProvider.ErrorMessageChanged:Connect(function()
        task.wait(5)
        pcall(function()
            if #Players:GetPlayers() <= 1 then TeleportService:Teleport(game.PlaceId, Player)
            else TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, Player) end
        end)
    end)
end

Player.Idled:Connect(function()
    local virtualUser = game:GetService("VirtualUser")
    virtualUser:CaptureController() virtualUser:ClickButton2(Vector2.new(0,0))
end)

task.spawn(function()
    while true do task.wait(120) pcall(doAntiAFKClick) end
end)

task.spawn(function()
    while MainFrame.Parent do
        local p = Create("Frame", {Size = UDim2.new(0, math.random(2,5), 0, math.random(2,5)), Position = UDim2.new(math.random(), 0, 1, 0), BackgroundColor3 = math.random() > 0.5 and Colors.Primary or Colors.Hover, BackgroundTransparency = 0.8, ZIndex = 0, Parent = MainFrame})
        ApplyCorner(p, 1)
        TweenService:Create(p, TweenInfo.new(math.random(4, 7), Enum.EasingStyle.Linear), {Position = UDim2.new(p.Position.X.Scale, p.Position.X.Offset, -0.1, 0), BackgroundTransparency = 1}):Play()
        task.delay(7, function() p:Destroy() end)
        task.wait(math.random(1, 30)/10)
    end
end)
