if shared.AutoExecuted then
    shared.AutoExecuted = nil
    task.wait(5)
end

if not game:IsLoaded() then
    game.Loaded:Wait()
end

local Players = game:GetService("Players")
local Player = Players.LocalPlayer
while not Player do
    task.wait(0.5)
    Player = Players.LocalPlayer
end

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local MarketplaceService = game:GetService("MarketplaceService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")

local queue_on_teleport = queue_on_teleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport)
local GITHUB_URL = "https://raw.githubusercontent.com/Diablo4925/AnimeSquadron/main/Beta.lua"

local function queueAutoExecute()
    if not queue_on_teleport then return end
    if GITHUB_URL == "" then return end
    pcall(function()
        queue_on_teleport("shared.AutoExecuted = true; loadstring(game:HttpGet(\"" .. GITHUB_URL .. "\"))()")
    end)
end

local GameRemotes = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("Game")
local ReplayEvent = GameRemotes and GameRemotes:FindFirstChild("replay")
local NextEvent = GameRemotes and GameRemotes:FindFirstChild("next")
local PlayerRemotes = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("Players")
local preventAfkEv = PlayerRemotes and PlayerRemotes:FindFirstChild("prevent_afk")

task.spawn(function()
    if not ReplayEvent or not NextEvent then
        local remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
        local gameRemotes = remotes and remotes:WaitForChild("Game", 10)
        if gameRemotes then
            ReplayEvent = ReplayEvent or gameRemotes:WaitForChild("replay", 10)
            NextEvent = NextEvent or gameRemotes:WaitForChild("next", 10)
        end
    end
end)

pcall(function()
    local settingsRemote = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("Settings") and ReplicatedStorage.Remotes.Settings:FindFirstChild("change")
    if settingsRemote then
        settingsRemote:InvokeServer("hide_damage_indicators", true)
        settingsRemote:InvokeServer("hide_ultimates", true)
    end
end)

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
    intervalHours = 1,
    autoExecute = false,
    lowMemoryMode = false
}

local sessionStats = {
    totalMatches = 0,
    startTime = tick(),
    itemsEarned = {},
    currentBalances = {},
    intervalMatches = 0,
    intervalItems = {}
}

local oldData = {}

local function saveConfig()
    if writefile then
        pcall(function()
            writefile(CONFIG_FILE_NAME, HttpService:JSONEncode(config))
        end)
    end
end

local function loadConfig()
    if readfile then
        pcall(function()
            local content = readfile(CONFIG_FILE_NAME)
            if content and content ~= "" then
                local saved = HttpService:JSONDecode(content)
                if type(saved) == "table" then
                    for k, v in pairs(saved) do
                        config[k] = v
                    end
                end
            end
        end)
    end
end

loadConfig()

if config.autoExecute then
    queueAutoExecute()
end

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

local ScreenGui = Create("ScreenGui", {Name = "AnimeSquadronUI", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = Player:WaitForChild("PlayerGui")})
local FloatBtn = Create("TextButton", {Name = "FloatBtn", Size = UDim2.new(0, 60, 0, 60), Position = UDim2.new(0, 50, 0.5, -30), BackgroundColor3 = Colors.Primary, Text = "", Visible = false, ClipsDescendants = true, Parent = ScreenGui})
ApplyCorner(FloatBtn, 30)
ApplyStroke(FloatBtn, Colors.Border, 3, 0)
Create("UIScale", {Scale = 0, Parent = FloatBtn})
PlayHoverAnimation(FloatBtn)
PlayClickAnimation(FloatBtn)

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
ApplyCorner(MainFrame, 10)
ApplyStroke(MainFrame, Colors.Border, 3, 0)
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

local VersionLabel = Create("TextLabel", {Size = UDim2.new(0, 50, 1, 0), Position = UDim2.new(0, 210, 0, 0), BackgroundTransparency = 1, Text = "v2.4", TextColor3 = Colors.SecondaryText, TextScaled = true, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left, Parent = Header})
Create("UIPadding", {PaddingBottom = UDim.new(0, 12), PaddingTop = UDim.new(0, 12), Parent = VersionLabel})

local StatusDot = Create("Frame", {Size = UDim2.new(0, 8, 0, 8), Position = UDim2.new(1, -20, 0.5, -4), BackgroundColor3 = Colors.Primary, Parent = Header})
ApplyCorner(StatusDot, 4)
TweenService:Create(StatusDot, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {BackgroundTransparency = 0.6}):Play()

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
    ApplyCorner(btn, 6) ApplyStroke(btn, Colors.Border, 1, 0.5)
    Create("TextLabel", {Size = UDim2.new(1, -20, 1, 0), Position = UDim2.new(0, 10, 0, 0), BackgroundTransparency = 1, Text = text, TextColor3 = Colors.Text, Font = Enum.Font.GothamBold, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, Parent = btn})
    PlayHoverAnimation(btn) PlayClickAnimation(btn)
    btn.MouseButton1Click:Connect(function()
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

local function takeSnapshot()
    local success, rawData = pcall(function() return ReplicatedStorage.Remotes.Players.get:InvokeServer() end)
    if success and type(rawData) == "table" then oldData = rawData end
end

takeSnapshot()

local function formatTime(seconds)
    local minutes = math.floor(seconds / 60)
    local remSeconds = math.floor(seconds % 60)
    return string.format("%02d:%02d", minutes, remSeconds)
end

local cachedMapName = "Anime Squadron"
local function getMapName()
    local pgui = Player:FindFirstChild("PlayerGui")
    local menus = pgui and pgui:FindFirstChild("Menus")
    local endStats = menus and menus:FindFirstChild("EndScreen") and menus.EndScreen:FindFirstChild("Stats")

    if endStats then
        local world = endStats:FindFirstChild("World") and endStats.World.Text
        local chapter = endStats:FindFirstChild("Chapter") and endStats.Chapter.Text:gsub("<[^>]+>", "")
        local mode = endStats:FindFirstChild("Mode") and endStats.Mode.Text
        local diff = endStats:FindFirstChild("Difficulty") and endStats.Difficulty.Text

        if world and world ~= "" then
            local mapTitle = world
            if chapter and chapter ~= "" then mapTitle = mapTitle .. " - " .. chapter end
            if mode and mode ~= "" then
                if diff and diff ~= "" then
                    mapTitle = mapTitle .. " [" .. mode .. " (" .. diff .. ")]"
                else
                    mapTitle = mapTitle .. " [" .. mode .. "]"
                end
            end
            cachedMapName = mapTitle
            return cachedMapName
        end
    end

    local startAnim = menus and menus:FindFirstChild("Start_Animation")
    local startWorld = startAnim and startAnim:FindFirstChild("start_animation") and startAnim.start_animation:FindFirstChild("World")
    if startWorld and startWorld.Text ~= "" then
        cachedMapName = startWorld.Text
        return cachedMapName
    end

    return cachedMapName
end

local function cleanItemName(rawName)
    local str = tostring(rawName)
    str = str:gsub("^corrupted_", "Corrupted ")
    str = str:gsub("_[0-9]+_", " ")
    str = str:gsub("_", " ")
    str = str:gsub("(%a)([%w_']*)", function(first, rest)
        return first:upper() .. rest:lower()
    end)
    return str
end

local function trackMatchEnd()
    sessionStats.totalMatches = sessionStats.totalMatches + 1
    sessionStats.intervalMatches = sessionStats.intervalMatches + 1

    if config.showItems then
        local success, rawData = pcall(function() return ReplicatedStorage.Remotes.Players.get:InvokeServer() end)
        local ignoreKeys = { level = true, xp = true, exp = true }

        if success and type(rawData) == "table" then
            for _, folder in ipairs({"caps", "items", "stats", "gear"}) do
                if rawData[folder] then
                    for itemName, amount in pairs(rawData[folder]) do
                        local lowerKey = tostring(itemName):lower()
                        if type(amount) == "number" and not ignoreKeys[lowerKey] and itemName ~= "" then
                            local oldAmount = (type(oldData) == "table" and oldData[folder] and oldData[folder][itemName]) or 0
                            local gained = amount - oldAmount
                            local finalName = cleanItemName(itemName)

                            sessionStats.currentBalances[finalName] = amount

                            if gained > 0 then
                                sessionStats.itemsEarned[finalName] = (sessionStats.itemsEarned[finalName] or 0) + gained
                                sessionStats.intervalItems[finalName] = (sessionStats.intervalItems[finalName] or 0) + gained
                            end
                        end
                    end
                end
            end
            oldData = rawData
        end
    end
end

local function formatAnsiItemsWithTotal(itemsTable)
    local lines = {}
    for name, gained in pairs(itemsTable) do
        local totalInInventory = sessionStats.currentBalances[name] or gained
        local gainedStr = "[+] +" .. tostring(gained) .. "x"
        local line = string.format("%-10s %-24s (Total: %s)", gainedStr, name, tostring(totalInInventory))
        table.insert(lines, line)
    end

    if #lines > 0 then
        return "```ansi\n" .. table.concat(lines, "\n") .. "\n```"
    end
    return "```ansi\n[-] No new items dropped this interval\n```"
end

local function sendReport()
    if not config.enabled then return end
    local totalSessionTime = tick() - sessionStats.startTime

    local fields = {
        {["name"] = "👤 Player", ["value"] = Player.Name, ["inline"] = true},
        {["name"] = "🌍 Current Stage", ["value"] = getMapName(), ["inline"] = true},
        {["name"] = "⏱️ Time Elapsed", ["value"] = formatTime(totalSessionTime), ["inline"] = true},
        {["name"] = "🔄 Matches (Interval)", ["value"] = tostring(sessionStats.intervalMatches), ["inline"] = true},
        {["name"] = "🏆 Matches (Total)", ["value"] = tostring(sessionStats.totalMatches), ["inline"] = true},
        {["name"] = "\u{200B}", ["value"] = "\u{200B}", ["inline"] = true},
    }

    local itemsGainedText = formatAnsiItemsWithTotal(sessionStats.intervalItems)
    table.insert(fields, {["name"] = "🎒 Stage Drops & Current Inventory", ["value"] = itemsGainedText, ["inline"] = false})

    local embed = {
        ["title"] = "✨ Anime Squadron - Stage Farming Report",
        ["color"] = 5763719,
        ["fields"] = fields,
        ["thumbnail"] = {["url"] = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. Player.UserId .. "&width=150&height=150&format=png"},
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
local updateCurrentStage = UIElements:CreateStatCard("Dashboard", "Current Stage", getMapName())

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

UIElements:CreateToggle("Automation", "🖥️ Low RAM / CPU Mode (Disable 3D)", config.lowMemoryMode, function(val)
    config.lowMemoryMode = val
    saveConfig()
    pcall(function()
        RunService:Set3dRenderingEnabled(not val)
    end)
end)

UIElements:CreateToggle("Automation", "🔁 Auto Execute (on Server Change)", config.autoExecute, function(val)
    config.autoExecute = val
    saveConfig()
    if val and queue_on_teleport then
        queueAutoExecute()
    end
end)

UIElements:CreateToggle("Webhook", "Enable Discord Webhook", config.enabled, function(val) config.enabled = val saveConfig() end)
UIElements:CreateToggle("Webhook", "Show Drops & Total in Report", config.showItems, function(val) config.showItems = val saveConfig() end)
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
        updateCurrentStage(getMapName())
        task.wait(1)
    end
end)

local lastFireTime = 0
local function fireReplay()
    local now = tick()
    if (now - lastFireTime) < 0.5 then return end
    lastFireTime = now

    pcall(function()
        if config.autoNext and NextEvent then
            NextEvent:FireServer()
        elseif config.autoReplay and ReplayEvent then
            ReplayEvent:FireServer()
        end
    end)
    task.spawn(trackMatchEnd)
end

if ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("Game") and ReplicatedStorage.Remotes.Game:FindFirstChild("ending") then
    ReplicatedStorage.Remotes.Game.ending.OnClientEvent:Connect(fireReplay)
end

task.spawn(function()
    local hookedValues = {}
    while true do
        task.wait(0.2)
        pcall(function()
            local gameFolder = Workspace:FindFirstChild("Game")
            if gameFolder then
                local statsFolder = gameFolder:FindFirstChild("Stats")
                if statsFolder then
                    local wonVal = statsFolder:FindFirstChild("Won")
                    local lostVal = statsFolder:FindFirstChild("Lost")

                    if wonVal and not hookedValues[wonVal] then
                        hookedValues[wonVal] = true
                        wonVal.Changed:Connect(function()
                            if wonVal.Value > 0 then fireReplay() end
                        end)
                    end

                    if lostVal and not hookedValues[lostVal] then
                        hookedValues[lostVal] = true
                        lostVal.Changed:Connect(function()
                            if lostVal.Value > 0 then fireReplay() end
                        end)
                    end
                end
            end
        end)
    end
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
            TeleportService:Teleport(game.PlaceId, Player)
        end)
    end)
end

Player.Idled:Connect(function()
    local virtualUser = game:GetService("VirtualUser")
    virtualUser:CaptureController()
    virtualUser:ClickButton2(Vector2.new(0,0))
end)

task.spawn(function()
    while true do task.wait(120) pcall(doAntiAFKClick) end
end)

task.spawn(function()
    while true do
        task.wait(300)
        if preventAfkEv then
            pcall(function() preventAfkEv:FireServer() end)
        end
    end
end)
