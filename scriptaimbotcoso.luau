local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Settings
local Settings = {
    ESP = {
        Enabled = false,
        ShowNames = true,
        ShowHealth = true,
        UseHighlights = false,
        UseRankColor = false,
        UseRankColorForName = false,
        ShowTeammates = true,
        ShowTool = true,
        TextSize = 14,
        TextColor = Color3.fromRGB(255, 255, 255),
        BoxColor = Color3.fromRGB(255, 0, 0),
        MaxDistance = 1000
    },
    Aimbot = {
        Enabled = false,
        AimbotMode = "Camera",
        TargetPart = "Head",
        FOV = 150,
        WallCheck = true,
        TeamCheck = true,
        Smoothness = 1,
        ShowFOV = true,
        FOVColor = Color3.fromRGB(255, 255, 255),
        MouseSensitivity = 1
    }
}

-- Runtime-only settings (not saved to config)
local RuntimeSettings = {
    Aimbot = {
        UserWhitelist = {},
        TeamWhitelist = {}
    }
}

-- Config Storage (in-memory cache)
local SavedConfigs = {}

-- FILE SYSTEM CONFIGURATION
local ConfigFolder = "ESP_Aimbot_Configs/"
local ConfigExtension = ".json"

-- Ensure config folder exists
if makefolder and not isfolder(ConfigFolder) then
    makefolder(ConfigFolder)
end

-- Helper to get full file path
local function GetConfigPath(name)
    return ConfigFolder .. name .. ConfigExtension
end

-- Load existing configs from files on startup
local function LoadExistingConfigs()
    if not listfiles then return end
    
    local files = listfiles(ConfigFolder)
    for _, filePath in ipairs(files) do
        -- Extract filename from path (handles both / and \)
        local filename = filePath:match("([^/\\]+)%.json$")
        if filename then
            local success, content = pcall(function()
                return readfile(filePath)
            end)
            
            if success and content then
                local decodeSuccess, data = pcall(function()
                    return HttpService:JSONDecode(content)
                end)
                
                if decodeSuccess and data and data.ESP and data.Aimbot then
                    SavedConfigs[filename] = data
                end
            end
        end
    end
end

-- Theme Colors
local Theme = {
    Background = Color3.fromRGB(15, 15, 20),
    Surface = Color3.fromRGB(25, 25, 35),
    SurfaceHover = Color3.fromRGB(35, 35, 50),
    Accent = Color3.fromRGB(100, 80, 255),
    AccentSecondary = Color3.fromRGB(80, 200, 255),
    Text = Color3.fromRGB(240, 240, 255),
    TextMuted = Color3.fromRGB(150, 150, 170),
    Success = Color3.fromRGB(80, 255, 150),
    Danger = Color3.fromRGB(255, 80, 100),
    Warning = Color3.fromRGB(255, 200, 80),
    Border = Color3.fromRGB(40, 40, 55)
}

-- GUI Creation
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ESP_Aimbot_GUI"
ScreenGui.Parent = CoreGui

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 420, 0, 540)
MainFrame.Position = UDim2.new(0.5, -210, 0.5, -270)
MainFrame.BackgroundColor3 = Theme.Background
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

-- Gradient background effect
local Gradient = Instance.new("UIGradient")
Gradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Theme.Background),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 20, 30))
})
Gradient.Rotation = 45
Gradient.Parent = MainFrame

-- Corner radius
local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 12)
Corner.Parent = MainFrame

-- Shadow
local Shadow = Instance.new("ImageLabel")
Shadow.Name = "Shadow"
Shadow.AnchorPoint = Vector2.new(0.5, 0.5)
Shadow.BackgroundTransparency = 1
Shadow.Position = UDim2.new(0.5, 0, 0.5, 0)
Shadow.Size = UDim2.new(1, 40, 1, 40)
Shadow.ZIndex = -1
Shadow.Image = "rbxassetid://6015897843"
Shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
Shadow.ImageTransparency = 0.3
Shadow.ScaleType = Enum.ScaleType.Slice
Shadow.SliceCenter = Rect.new(49, 49, 450, 450)
Shadow.Parent = MainFrame

-- Title Bar
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 50)
TitleBar.BackgroundColor3 = Theme.Surface
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 12)
TitleCorner.Parent = TitleBar

local TitleGradient = Instance.new("UIGradient")
TitleGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Theme.Accent),
    ColorSequenceKeypoint.new(1, Theme.AccentSecondary)
})
TitleGradient.Rotation = 90
TitleGradient.Parent = TitleBar

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -100, 1, 0)
Title.Position = UDim2.new(0, 20, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "⚡ ESP & AIMBOT"
Title.TextColor3 = Theme.Text
Title.TextSize = 18
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TitleBar

-- Draggable functionality
local dragging = false
local dragStart = nil
local startPos = nil

TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        local newPos = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        
        -- Smooth drag animation
        TweenService:Create(MainFrame, TweenInfo.new(0.05), {Position = newPos}):Play()
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

-- Control Buttons
local MinimizeButton = Instance.new("TextButton")
MinimizeButton.Size = UDim2.new(0, 30, 0, 30)
MinimizeButton.Position = UDim2.new(1, -70, 0.5, -15)
MinimizeButton.BackgroundColor3 = Theme.Surface
MinimizeButton.Text = "−"
MinimizeButton.TextColor3 = Theme.Text
MinimizeButton.TextSize = 20
MinimizeButton.Font = Enum.Font.GothamBold
MinimizeButton.Parent = TitleBar

local CloseButton = Instance.new("TextButton")
CloseButton.Size = UDim2.new(0, 30, 0, 30)
CloseButton.Position = UDim2.new(1, -35, 0.5, -15)
CloseButton.BackgroundColor3 = Theme.Danger
CloseButton.Text = "×"
CloseButton.TextColor3 = Theme.Text
CloseButton.TextSize = 20
CloseButton.Font = Enum.Font.GothamBold
CloseButton.Parent = TitleBar

for _, btn in ipairs({MinimizeButton, CloseButton}) do
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 8)
    btnCorner.Parent = btn
    
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = btn.BackgroundColor3:Lerp(Color3.new(1,1,1), 0.2)}):Play()
    end)
    
    btn.MouseLeave:Connect(function()
        local originalColor = btn == CloseButton and Theme.Danger or Theme.Surface
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = originalColor}):Play()
    end)
end

-- Tab Container
local TabContainer = Instance.new("Frame")
TabContainer.Size = UDim2.new(1, -20, 0, 40)
TabContainer.Position = UDim2.new(0, 10, 0, 60)
TabContainer.BackgroundColor3 = Theme.Surface
TabContainer.BorderSizePixel = 0
TabContainer.Parent = MainFrame

local TabCorner = Instance.new("UICorner")
TabCorner.CornerRadius = UDim.new(0, 8)
TabCorner.Parent = TabContainer

-- Tab Buttons (3 tabs now)
local ESPButton = Instance.new("TextButton")
ESPButton.Size = UDim2.new(0.333, -3, 1, 0)
ESPButton.Position = UDim2.new(0, 0, 0, 0)
ESPButton.BackgroundColor3 = Theme.Accent
ESPButton.Text = "ESP"
ESPButton.TextColor3 = Theme.Text
ESPButton.TextSize = 14
ESPButton.Font = Enum.Font.GothamBold
ESPButton.Parent = TabContainer

local AimbotButton = Instance.new("TextButton")
AimbotButton.Size = UDim2.new(0.333, -3, 1, 0)
AimbotButton.Position = UDim2.new(0.333, 3, 0, 0)
AimbotButton.BackgroundColor3 = Theme.SurfaceHover
AimbotButton.Text = "AIMBOT"
AimbotButton.TextColor3 = Theme.TextMuted
AimbotButton.TextSize = 14
AimbotButton.Font = Enum.Font.GothamBold
AimbotButton.Parent = TabContainer

local SettingsButton = Instance.new("TextButton")
SettingsButton.Size = UDim2.new(0.333, -3, 1, 0)
SettingsButton.Position = UDim2.new(0.666, 6, 0, 0)
SettingsButton.BackgroundColor3 = Theme.SurfaceHover
SettingsButton.Text = "SETTINGS"
SettingsButton.TextColor3 = Theme.TextMuted
SettingsButton.TextSize = 14
SettingsButton.Font = Enum.Font.GothamBold
SettingsButton.Parent = TabContainer

for _, btn in ipairs({ESPButton, AimbotButton, SettingsButton}) do
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = btn
end

-- Content Frames
local ESPFrame = Instance.new("ScrollingFrame")
ESPFrame.Size = UDim2.new(1, -20, 1, -115)
ESPFrame.Position = UDim2.new(0, 10, 0, 110)
ESPFrame.BackgroundColor3 = Theme.Surface
ESPFrame.BorderSizePixel = 0
ESPFrame.ScrollBarThickness = 4
ESPFrame.ScrollBarImageColor3 = Theme.Accent
ESPFrame.Visible = true
ESPFrame.Parent = MainFrame

local AimbotFrame = Instance.new("ScrollingFrame")
AimbotFrame.Size = UDim2.new(1, -20, 1, -115)
AimbotFrame.Position = UDim2.new(0, 10, 0, 110)
AimbotFrame.BackgroundColor3 = Theme.Surface
AimbotFrame.BorderSizePixel = 0
AimbotFrame.ScrollBarThickness = 4
AimbotFrame.ScrollBarImageColor3 = Theme.Accent
AimbotFrame.Visible = false
AimbotFrame.Parent = MainFrame

local SettingsFrame = Instance.new("ScrollingFrame")
SettingsFrame.Size = UDim2.new(1, -20, 1, -115)
SettingsFrame.Position = UDim2.new(0, 10, 0, 110)
SettingsFrame.BackgroundColor3 = Theme.Surface
SettingsFrame.BorderSizePixel = 0
SettingsFrame.ScrollBarThickness = 4
SettingsFrame.ScrollBarImageColor3 = Theme.Accent
SettingsFrame.Visible = false
SettingsFrame.Parent = MainFrame

for _, frame in ipairs({ESPFrame, AimbotFrame, SettingsFrame}) do
    local frameCorner = Instance.new("UICorner")
    frameCorner.CornerRadius = UDim.new(0, 8)
    frameCorner.Parent = frame
    
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 8)
    layout.Parent = frame
end

-- Helper Functions
local function CreateSection(parent, title)
    local section = Instance.new("Frame")
    section.Size = UDim2.new(1, -10, 0, 30)
    section.BackgroundTransparency = 1
    section.Parent = parent
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = title:upper()
    label.TextColor3 = Theme.Accent
    label.TextSize = 12
    label.Font = Enum.Font.GothamBold
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = section
    
    return section
end

local function CreateToggle(parent, text, settingTable, settingKey, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -10, 0, 40)
    frame.BackgroundColor3 = Theme.SurfaceHover
    frame.BorderSizePixel = 0
    frame.Parent = parent
    
    local frameCorner = Instance.new("UICorner")
    frameCorner.CornerRadius = UDim.new(0, 8)
    frameCorner.Parent = frame
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.6, 0, 1, 0)
    label.Position = UDim2.new(0, 15, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Theme.Text
    label.TextSize = 13
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame
    
    -- Toggle Switch Container
    local switchContainer = Instance.new("Frame")
    switchContainer.Size = UDim2.new(0, 50, 0, 26)
    switchContainer.Position = UDim2.new(1, -65, 0.5, -13)
    switchContainer.BackgroundColor3 = settingTable[settingKey] and Theme.Accent or Theme.Border
    switchContainer.BorderSizePixel = 0
    switchContainer.Parent = frame
    
    local switchCorner = Instance.new("UICorner")
    switchCorner.CornerRadius = UDim.new(1, 0)
    switchCorner.Parent = switchContainer
    
    -- Toggle Knob
    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 22, 0, 22)
    knob.Position = settingTable[settingKey] and UDim2.new(1, -24, 0.5, -11) or UDim2.new(0, 2, 0.5, -11)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel = 0
    knob.Parent = switchContainer
    
    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(1, 0)
    knobCorner.Parent = knob
    
    local function updateToggle(state)
        settingTable[settingKey] = state
        
        TweenService:Create(switchContainer, TweenInfo.new(0.2), {
            BackgroundColor3 = state and Theme.Accent or Theme.Border
        }):Play()
        
        TweenService:Create(knob, TweenInfo.new(0.2), {
            Position = state and UDim2.new(1, -24, 0.5, -11) or UDim2.new(0, 2, 0.5, -11)
        }):Play()
        
        if callback then callback(state) end
    end
    
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            updateToggle(not settingTable[settingKey])
        end
    end)
    
    return frame
end

local function CreateSlider(parent, text, settingTable, settingKey, min, max, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -10, 0, 60)
    frame.BackgroundColor3 = Theme.SurfaceHover
    frame.BorderSizePixel = 0
    frame.Parent = parent
    
    local frameCorner = Instance.new("UICorner")
    frameCorner.CornerRadius = UDim.new(0, 8)
    frameCorner.Parent = frame
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.7, 0, 0, 20)
    label.Position = UDim2.new(0, 15, 0, 8)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Theme.Text
    label.TextSize = 13
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame
    
    local valueLabel = Instance.new("TextLabel")
    valueLabel.Size = UDim2.new(0.3, -15, 0, 20)
    valueLabel.Position = UDim2.new(0.7, 0, 0, 8)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = tostring(settingTable[settingKey])
    valueLabel.TextColor3 = Theme.Accent
    valueLabel.TextSize = 13
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.Parent = frame
    
    local sliderFrame = Instance.new("Frame")
    sliderFrame.Size = UDim2.new(1, -30, 0, 6)
    sliderFrame.Position = UDim2.new(0, 15, 0, 38)
    sliderFrame.BackgroundColor3 = Theme.Border
    sliderFrame.BorderSizePixel = 0
    sliderFrame.Parent = frame
    
    local sliderCorner = Instance.new("UICorner")
    sliderCorner.CornerRadius = UDim.new(1, 0)
    sliderCorner.Parent = sliderFrame
    
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((settingTable[settingKey] - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = Theme.Accent
    fill.BorderSizePixel = 0
    fill.Parent = sliderFrame
    
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(1, 0)
    fillCorner.Parent = fill
    
    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 14, 0, 14)
    knob.Position = UDim2.new((settingTable[settingKey] - min) / (max - min), -7, 0.5, -7)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel = 0
    knob.ZIndex = 2
    knob.Parent = sliderFrame
    
    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(1, 0)
    knobCorner.Parent = knob
    
    local draggingSlider = false
    
    local function updateSlider(input)
        local pos = math.clamp((input.Position.X - sliderFrame.AbsolutePosition.X) / sliderFrame.AbsoluteSize.X, 0, 1)
        local value = math.floor(min + (max - min) * pos)
        settingTable[settingKey] = value
        
        fill.Size = UDim2.new(pos, 0, 1, 0)
        knob.Position = UDim2.new(pos, -7, 0.5, -7)
        valueLabel.Text = tostring(value)
        
        if callback then callback(value) end
    end
    
    sliderFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            draggingSlider = true
            updateSlider(input)
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if draggingSlider and input.UserInputType == Enum.UserInputType.MouseMovement then
            updateSlider(input)
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            draggingSlider = false
        end
    end)
    
    return frame
end

local function CreateDropdown(parent, text, options, settingTable, settingKey, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -10, 0, 40)
    frame.BackgroundColor3 = Theme.SurfaceHover
    frame.BorderSizePixel = 0
    frame.Parent = parent
    
    local frameCorner = Instance.new("UICorner")
    frameCorner.CornerRadius = UDim.new(0, 8)
    frameCorner.Parent = frame
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.4, 0, 1, 0)
    label.Position = UDim2.new(0, 15, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Theme.Text
    label.TextSize = 13
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame
    
    local dropdown = Instance.new("TextButton")
    dropdown.Size = UDim2.new(0.55, -10, 0, 28)
    dropdown.Position = UDim2.new(0.45, 5, 0.5, -14)
    dropdown.BackgroundColor3 = Theme.Border
    dropdown.Text = settingTable[settingKey]
    dropdown.TextColor3 = Theme.Text
    dropdown.TextSize = 12
    dropdown.Font = Enum.Font.Gotham
    dropdown.Parent = frame
    
    local dropdownCorner = Instance.new("UICorner")
    dropdownCorner.CornerRadius = UDim.new(0, 6)
    dropdownCorner.Parent = dropdown
    
    local arrow = Instance.new("TextLabel")
    arrow.Size = UDim2.new(0, 20, 1, 0)
    arrow.Position = UDim2.new(1, -20, 0, 0)
    arrow.BackgroundTransparency = 1
    arrow.Text = "▼"
    arrow.TextColor3 = Theme.TextMuted
    arrow.TextSize = 10
    arrow.Font = Enum.Font.Gotham
    arrow.Parent = dropdown
    
    local dropdownOpen = false
    local optionsFrame = nil
    
    dropdown.MouseButton1Click:Connect(function()
        if dropdownOpen and optionsFrame then
            optionsFrame:Destroy()
            dropdownOpen = false
            arrow.Text = "▼"
            return
        end
        
        optionsFrame = Instance.new("Frame")
        optionsFrame.Size = UDim2.new(1, 0, 0, #options * 32)
        optionsFrame.Position = UDim2.new(0, 0, 1, 5)
        optionsFrame.BackgroundColor3 = Theme.Surface
        optionsFrame.BorderSizePixel = 0
        optionsFrame.ZIndex = 10
        optionsFrame.Parent = dropdown
        
        local optionsCorner = Instance.new("UICorner")
        optionsCorner.CornerRadius = UDim.new(0, 6)
        optionsCorner.Parent = optionsFrame
        
        local stroke = Instance.new("UIStroke")
        stroke.Color = Theme.Border
        stroke.Thickness = 1
        stroke.Parent = optionsFrame
        
        for i, option in ipairs(options) do
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, 0, 0, 32)
            btn.Position = UDim2.new(0, 0, 0, (i-1) * 32)
            btn.BackgroundColor3 = Theme.Surface
            btn.Text = option
            btn.TextColor3 = Theme.Text
            btn.TextSize = 12
            btn.Font = Enum.Font.Gotham
            btn.ZIndex = 11
            btn.Parent = optionsFrame
            
            btn.MouseEnter:Connect(function()
                TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Theme.SurfaceHover}):Play()
            end)
            
            btn.MouseLeave:Connect(function()
                TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Theme.Surface}):Play()
            end)
            
            btn.MouseButton1Click:Connect(function()
                settingTable[settingKey] = option
                dropdown.Text = option
                optionsFrame:Destroy()
                dropdownOpen = false
                arrow.Text = "▼"
                if callback then callback(option) end
            end)
        end
        
        dropdownOpen = true
        arrow.Text = "▲"
    end)
    
    return frame
end

local WhitelistDisplays = {}

local function CreateWhitelistDisplay(parent, settingTable, settingKey)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -10, 0, 0)
    container.BackgroundTransparency = 1
    container.Parent = parent
    container.Name = "WhitelistDisplay_" .. settingKey
    
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 4)
    layout.Parent = container
    
    local function refreshList()
        -- Clear existing entries
        for _, child in ipairs(container:GetChildren()) do
            if child:IsA("Frame") then
                child:Destroy()
            end
        end
        
        -- Create entry for each whitelisted item
        for i, item in ipairs(settingTable[settingKey]) do
            local entry = Instance.new("Frame")
            entry.Size = UDim2.new(1, 0, 0, 28)
            entry.BackgroundColor3 = Theme.SurfaceHover
            entry.BorderSizePixel = 0
            entry.Parent = container
            
            local entryCorner = Instance.new("UICorner")
            entryCorner.CornerRadius = UDim.new(0, 6)
            entryCorner.Parent = entry
            
            local nameLabel = Instance.new("TextLabel")
            nameLabel.Size = UDim2.new(1, -70, 1, 0)
            nameLabel.Position = UDim2.new(0, 10, 0, 0)
            nameLabel.BackgroundTransparency = 1
            nameLabel.Text = item
            nameLabel.TextColor3 = Theme.Text
            nameLabel.TextSize = 12
            nameLabel.Font = Enum.Font.Gotham
            nameLabel.TextXAlignment = Enum.TextXAlignment.Left
            nameLabel.Parent = entry
            
            local removeBtn = Instance.new("TextButton")
            removeBtn.Size = UDim2.new(0, 60, 0, 22)
            removeBtn.Position = UDim2.new(1, -65, 0.5, -11)
            removeBtn.BackgroundColor3 = Theme.Danger
            removeBtn.Text = "REMOVE"
            removeBtn.TextColor3 = Theme.Text
            removeBtn.TextSize = 10
            removeBtn.Font = Enum.Font.GothamBold
            removeBtn.Parent = entry
            
            local removeCorner = Instance.new("UICorner")
            removeCorner.CornerRadius = UDim.new(0, 4)
            removeCorner.Parent = removeBtn
            
            removeBtn.MouseButton1Click:Connect(function()
                table.remove(settingTable[settingKey], i)
                refreshList()
            end)
        end
        
        -- Update container height based on number of entries
        local itemCount = #settingTable[settingKey]
        container.Size = UDim2.new(1, -10, 0, math.max(0, itemCount * 32 - 4))
        
        -- Update canvas size of parent scrolling frame
        local scrollingFrame = parent
        while scrollingFrame and scrollingFrame:IsA("ScrollingFrame") == false do
            scrollingFrame = scrollingFrame.Parent
        end
        if scrollingFrame then
            local contentHeight = 0
            for _, child in ipairs(scrollingFrame:GetChildren()) do
                if child:IsA("GuiObject") and child ~= scrollingFrame:FindFirstChildOfClass("UIListLayout") then
                    contentHeight = contentHeight + child.AbsoluteSize.Y + 8
                end
            end
            scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, contentHeight + 20)
        end
    end
    
    -- Store refresh function
    WhitelistDisplays[settingKey] = refreshList
    
    -- Initial population
    refreshList()
    
    return refreshList
end

local function CreateTextBox(parent, text, settingTable, settingKey, placeholder)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -10, 0, 45)
    frame.BackgroundColor3 = Theme.SurfaceHover
    frame.BorderSizePixel = 0
    frame.Parent = parent
    
    local frameCorner = Instance.new("UICorner")
    frameCorner.CornerRadius = UDim.new(0, 8)
    frameCorner.Parent = frame
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.35, 0, 0.5, 0)
    label.Position = UDim2.new(0, 15, 0, 5)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Theme.Text
    label.TextSize = 12
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame
    
    local boxContainer = Instance.new("Frame")
    boxContainer.Size = UDim2.new(0.65, -20, 0, 28)
    boxContainer.Position = UDim2.new(0.35, 10, 0.5, -8)
    boxContainer.BackgroundColor3 = Theme.Border
    boxContainer.BorderSizePixel = 0
    boxContainer.Parent = frame
    
    local boxCorner = Instance.new("UICorner")
    boxCorner.CornerRadius = UDim.new(0, 6)
    boxCorner.Parent = boxContainer
    
    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, -10, 1, 0)
    box.Position = UDim2.new(0, 5, 0, 0)
    box.BackgroundTransparency = 1
    box.Text = ""
    box.PlaceholderText = placeholder or "Username..."
    box.TextColor3 = Theme.Text
    box.PlaceholderColor3 = Theme.TextMuted
    box.TextSize = 12
    box.Font = Enum.Font.Gotham
    box.Parent = boxContainer
    
    local addBtn = Instance.new("TextButton")
    addBtn.Size = UDim2.new(0, 60, 0, 28)
    addBtn.Position = UDim2.new(1, -5, 0, 0)
    addBtn.AnchorPoint = Vector2.new(1, 0)
    addBtn.BackgroundColor3 = Theme.Accent
    addBtn.Text = "ADD"
    addBtn.TextColor3 = Theme.Text
    addBtn.TextSize = 11
    addBtn.Font = Enum.Font.GothamBold
    addBtn.Parent = boxContainer
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = addBtn
    
    addBtn.MouseEnter:Connect(function()
        TweenService:Create(addBtn, TweenInfo.new(0.2), {BackgroundColor3 = Theme.AccentSecondary}):Play()
    end)
    
    addBtn.MouseLeave:Connect(function()
        TweenService:Create(addBtn, TweenInfo.new(0.2), {BackgroundColor3 = Theme.Accent}):Play()
    end)
    
    addBtn.MouseButton1Click:Connect(function()
        local username = box.Text:gsub("%s+", "")
        if username ~= "" and not table.find(settingTable[settingKey], username) then
            table.insert(settingTable[settingKey], username)
            box.Text = ""
            
            -- Refresh whitelist display if it exists
            if WhitelistDisplays[settingKey] then
                WhitelistDisplays[settingKey]()
            end
            
            -- Success feedback
            local originalColor = boxContainer.BackgroundColor3
            TweenService:Create(boxContainer, TweenInfo.new(0.2), {BackgroundColor3 = Theme.Success}):Play()
            wait(0.3)
            TweenService:Create(boxContainer, TweenInfo.new(0.2), {BackgroundColor3 = originalColor}):Play()
        end
    end)
    
    return frame
end

-- ESP Controls
CreateSection(ESPFrame, "Main Settings")
CreateToggle(ESPFrame, "Enable ESP", Settings.ESP, "Enabled")
CreateToggle(ESPFrame, "Show Teammates", Settings.ESP, "ShowTeammates")
CreateToggle(ESPFrame, "Show Usernames", Settings.ESP, "ShowNames")
CreateToggle(ESPFrame, "Show Health", Settings.ESP, "ShowHealth")
CreateToggle(ESPFrame, "Show Equipped Tool", Settings.ESP, "ShowTool")

CreateSection(ESPFrame, "Visual Settings")
CreateToggle(ESPFrame, "Use Highlights", Settings.ESP, "UseHighlights")
CreateToggle(ESPFrame, "Use Rank Color (Box)", Settings.ESP, "UseRankColor")
CreateToggle(ESPFrame, "Use Rank Color (Name)", Settings.ESP, "UseRankColorForName")
CreateSlider(ESPFrame, "Max Distance", Settings.ESP, "MaxDistance", 100, 5000)

-- Aimbot Controls
CreateSection(AimbotFrame, "Main Settings")
CreateToggle(AimbotFrame, "Enable Aimbot", Settings.Aimbot, "Enabled")
CreateDropdown(AimbotFrame, "Aimbot Mode", {"Camera", "Mouse"}, Settings.Aimbot, "AimbotMode")
CreateDropdown(AimbotFrame, "Target Part", {"Head", "Torso", "HumanoidRootPart"}, Settings.Aimbot, "TargetPart")

CreateSection(AimbotFrame, "Targeting")
CreateToggle(AimbotFrame, "Show FOV Circle", Settings.Aimbot, "ShowFOV")
CreateToggle(AimbotFrame, "Wall Check", Settings.Aimbot, "WallCheck")
CreateToggle(AimbotFrame, "Team Check", Settings.Aimbot, "TeamCheck")
CreateSlider(AimbotFrame, "FOV Size", Settings.Aimbot, "FOV", 50, 500)
CreateSlider(AimbotFrame, "Smoothness", Settings.Aimbot, "Smoothness", 1, 10)
CreateSlider(AimbotFrame, "Mouse Sens", Settings.Aimbot, "MouseSensitivity", 1, 20)

-- User Whitelist Section
CreateSection(AimbotFrame, "User Whitelist (Session Only)")
CreateTextBox(AimbotFrame, "Add User", RuntimeSettings.Aimbot, "UserWhitelist", "Username...")
CreateWhitelistDisplay(AimbotFrame, RuntimeSettings.Aimbot, "UserWhitelist")

-- Team Whitelist Section
CreateSection(AimbotFrame, "Team Whitelist (Session Only)")
CreateTextBox(AimbotFrame, "Add Team", RuntimeSettings.Aimbot, "TeamWhitelist", "Team name...")
CreateWhitelistDisplay(AimbotFrame, RuntimeSettings.Aimbot, "TeamWhitelist")

-- Settings Tab UI
local ConfigNameInput = nil
local ConfigListFrame = nil
local SelectedConfig = nil

local function RefreshConfigList()
    if ConfigListFrame then
        ConfigListFrame:Destroy()
    end
    
    ConfigListFrame = Instance.new("Frame")
    ConfigListFrame.Size = UDim2.new(1, -20, 0, math.max(100, #SavedConfigs * 45))
    ConfigListFrame.BackgroundTransparency = 1
    ConfigListFrame.Parent = SettingsFrame
    
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 5)
    layout.Parent = ConfigListFrame
    
    local i = 0
    for name, data in pairs(SavedConfigs) do
        i = i + 1
        local configBtn = Instance.new("TextButton")
        configBtn.Size = UDim2.new(1, 0, 0, 40)
        configBtn.BackgroundColor3 = Theme.SurfaceHover
        configBtn.Text = name
        configBtn.TextColor3 = Theme.Text
        configBtn.TextSize = 14
        configBtn.Font = Enum.Font.GothamBold
        configBtn.Parent = ConfigListFrame
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 6)
        btnCorner.Parent = configBtn
        
        -- Selection indicator
        local selectedIndicator = Instance.new("Frame")
        selectedIndicator.Size = UDim2.new(0, 4, 1, 0)
        selectedIndicator.BackgroundColor3 = Theme.Accent
        selectedIndicator.BorderSizePixel = 0
        selectedIndicator.Visible = SelectedConfig == name
        selectedIndicator.Parent = configBtn
        
        local indicatorCorner = Instance.new("UICorner")
        indicatorCorner.CornerRadius = UDim.new(0, 2)
        indicatorCorner.Parent = selectedIndicator
        
        configBtn.MouseEnter:Connect(function()
            TweenService:Create(configBtn, TweenInfo.new(0.2), {BackgroundColor3 = Theme.Border}):Play()
        end)
        
        configBtn.MouseLeave:Connect(function()
            TweenService:Create(configBtn, TweenInfo.new(0.2), {BackgroundColor3 = Theme.SurfaceHover}):Play()
        end)
        
        configBtn.MouseButton1Click:Connect(function()
            SelectedConfig = name
            if ConfigNameInput then
                ConfigNameInput.Text = name
            end
            RefreshConfigList()
        end)
    end
    
    SettingsFrame.CanvasSize = UDim2.new(0, 0, 0, 400 + (i * 45))
end

CreateSection(SettingsFrame, "Config Manager")

-- Config Name Input
local ConfigNameFrame = Instance.new("Frame")
ConfigNameFrame.Size = UDim2.new(1, -10, 0, 45)
ConfigNameFrame.BackgroundColor3 = Theme.SurfaceHover
ConfigNameFrame.BorderSizePixel = 0
ConfigNameFrame.Parent = SettingsFrame

local nameCorner = Instance.new("UICorner")
nameCorner.CornerRadius = UDim.new(0, 8)
nameCorner.Parent = ConfigNameFrame

local nameLabel = Instance.new("TextLabel")
nameLabel.Size = UDim2.new(0.3, 0, 1, 0)
nameLabel.Position = UDim2.new(0, 15, 0, 0)
nameLabel.BackgroundTransparency = 1
nameLabel.Text = "Config Name:"
nameLabel.TextColor3 = Theme.Text
nameLabel.TextSize = 13
nameLabel.Font = Enum.Font.Gotham
nameLabel.TextXAlignment = Enum.TextXAlignment.Left
nameLabel.Parent = ConfigNameFrame

local nameBoxContainer = Instance.new("Frame")
nameBoxContainer.Size = UDim2.new(0.7, -25, 0, 32)
nameBoxContainer.Position = UDim2.new(0.3, 10, 0.5, -16)
nameBoxContainer.BackgroundColor3 = Theme.Border
nameBoxContainer.BorderSizePixel = 0
nameBoxContainer.Parent = ConfigNameFrame

local nameBoxCorner = Instance.new("UICorner")
nameBoxCorner.CornerRadius = UDim.new(0, 6)
nameBoxCorner.Parent = nameBoxContainer

ConfigNameInput = Instance.new("TextBox")
ConfigNameInput.Size = UDim2.new(1, -10, 1, 0)
ConfigNameInput.Position = UDim2.new(0, 5, 0, 0)
ConfigNameInput.BackgroundTransparency = 1
ConfigNameInput.Text = ""
ConfigNameInput.PlaceholderText = "Enter config name..."
ConfigNameInput.TextColor3 = Theme.Text
ConfigNameInput.PlaceholderColor3 = Theme.TextMuted
ConfigNameInput.TextSize = 13
ConfigNameInput.Font = Enum.Font.Gotham
ConfigNameInput.Parent = nameBoxContainer

-- Button Container
local ButtonContainer = Instance.new("Frame")
ButtonContainer.Size = UDim2.new(1, -10, 0, 40)
ButtonContainer.BackgroundTransparency = 1
ButtonContainer.Parent = SettingsFrame

local buttonLayout = Instance.new("UIListLayout")
buttonLayout.FillDirection = Enum.FillDirection.Horizontal
buttonLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
buttonLayout.Padding = UDim.new(0, 8)
buttonLayout.Parent = ButtonContainer

-- Save Button
local SaveBtn = Instance.new("TextButton")
SaveBtn.Size = UDim2.new(0, 90, 1, 0)
SaveBtn.BackgroundColor3 = Theme.Success
SaveBtn.Text = "SAVE"
SaveBtn.TextColor3 = Theme.Text
SaveBtn.TextSize = 13
SaveBtn.Font = Enum.Font.GothamBold
SaveBtn.Parent = ButtonContainer

local saveCorner = Instance.new("UICorner")
saveCorner.CornerRadius = UDim.new(0, 6)
saveCorner.Parent = SaveBtn

-- Load Button
local LoadBtn = Instance.new("TextButton")
LoadBtn.Size = UDim2.new(0, 90, 1, 0)
LoadBtn.BackgroundColor3 = Theme.Accent
LoadBtn.Text = "LOAD"
LoadBtn.TextColor3 = Theme.Text
LoadBtn.TextSize = 13
LoadBtn.Font = Enum.Font.GothamBold
LoadBtn.Parent = ButtonContainer

local loadCorner = Instance.new("UICorner")
loadCorner.CornerRadius = UDim.new(0, 6)
loadCorner.Parent = LoadBtn

-- Override Button
local OverrideBtn = Instance.new("TextButton")
OverrideBtn.Size = UDim2.new(0, 90, 1, 0)
OverrideBtn.BackgroundColor3 = Theme.Warning
OverrideBtn.Text = "OVERRIDE"
OverrideBtn.TextColor3 = Theme.Text
OverrideBtn.TextSize = 13
OverrideBtn.Font = Enum.Font.GothamBold
OverrideBtn.Parent = ButtonContainer

local overrideCorner = Instance.new("UICorner")
overrideCorner.CornerRadius = UDim.new(0, 6)
overrideCorner.Parent = OverrideBtn

-- Delete Button
local DeleteBtn = Instance.new("TextButton")
DeleteBtn.Size = UDim2.new(0, 90, 1, 0)
DeleteBtn.BackgroundColor3 = Theme.Danger
DeleteBtn.Text = "DELETE"
DeleteBtn.TextColor3 = Theme.Text
DeleteBtn.TextSize = 13
DeleteBtn.Font = Enum.Font.GothamBold
DeleteBtn.Parent = ButtonContainer

local deleteCorner = Instance.new("UICorner")
deleteCorner.CornerRadius = UDim.new(0, 6)
deleteCorner.Parent = DeleteBtn

-- Button hover effects
for _, btn in ipairs({SaveBtn, LoadBtn, OverrideBtn, DeleteBtn}) do
    local originalColor = btn.BackgroundColor3
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = originalColor:Lerp(Color3.new(1,1,1), 0.2)}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = originalColor}):Play()
    end)
end

-- Export/Import Section
CreateSection(SettingsFrame, "Import / Export")

local ExportImportFrame = Instance.new("Frame")
ExportImportFrame.Size = UDim2.new(1, -10, 0, 80)
ExportImportFrame.BackgroundColor3 = Theme.SurfaceHover
ExportImportFrame.BorderSizePixel = 0
ExportImportFrame.Parent = SettingsFrame

local eiCorner = Instance.new("UICorner")
eiCorner.CornerRadius = UDim.new(0, 8)
eiCorner.Parent = ExportImportFrame

local JsonBox = Instance.new("TextBox")
JsonBox.Size = UDim2.new(1, -20, 0, 40)
JsonBox.Position = UDim2.new(0, 10, 0, 8)
JsonBox.BackgroundColor3 = Theme.Border
JsonBox.Text = ""
JsonBox.PlaceholderText = "Paste JSON config here or click Export to copy..."
JsonBox.TextColor3 = Theme.Text
JsonBox.PlaceholderColor3 = Theme.TextMuted
JsonBox.TextSize = 11
JsonBox.Font = Enum.Font.Gotham
JsonBox.ClearTextOnFocus = false
JsonBox.Parent = ExportImportFrame

local jsonCorner = Instance.new("UICorner")
jsonCorner.CornerRadius = UDim.new(0, 6)
jsonCorner.Parent = JsonBox

local ExportBtn = Instance.new("TextButton")
ExportBtn.Size = UDim2.new(0.48, -5, 0, 28)
ExportBtn.Position = UDim2.new(0, 10, 1, -38)
ExportBtn.BackgroundColor3 = Theme.Accent
ExportBtn.Text = "EXPORT"
ExportBtn.TextColor3 = Theme.Text
ExportBtn.TextSize = 12
ExportBtn.Font = Enum.Font.GothamBold
ExportBtn.Parent = ExportImportFrame

local ImportBtn = Instance.new("TextButton")
ImportBtn.Size = UDim2.new(0.48, -5, 0, 28)
ImportBtn.Position = UDim2.new(0.52, 5, 1, -38)
ImportBtn.BackgroundColor3 = Theme.AccentSecondary
ImportBtn.Text = "IMPORT"
ImportBtn.TextColor3 = Theme.Text
ImportBtn.TextSize = 12
ImportBtn.Font = Enum.Font.GothamBold
ImportBtn.Parent = ExportImportFrame

for _, btn in ipairs({ExportBtn, ImportBtn}) do
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = btn
    
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Theme.SurfaceHover}):Play()
    end)
    btn.MouseLeave:Connect(function()
        local original = btn == ExportBtn and Theme.Accent or Theme.AccentSecondary
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = original}):Play()
    end)
end

-- Saved Configs List Section
CreateSection(SettingsFrame, "Saved Configs")

-- Config Management Functions
local function ShowNotification(text, color)
    local notif = Instance.new("Frame")
    notif.Size = UDim2.new(0, 200, 0, 40)
    notif.Position = UDim2.new(0.5, -100, 0, -50)
    notif.BackgroundColor3 = color or Theme.Accent
    notif.BorderSizePixel = 0
    notif.Parent = MainFrame
    
    local notifCorner = Instance.new("UICorner")
    notifCorner.CornerRadius = UDim.new(0, 8)
    notifCorner.Parent = notif
    
    local notifText = Instance.new("TextLabel")
    notifText.Size = UDim2.new(1, 0, 1, 0)
    notifText.BackgroundTransparency = 1
    notifText.Text = text
    notifText.TextColor3 = Theme.Text
    notifText.TextSize = 14
    notifText.Font = Enum.Font.GothamBold
    notifText.Parent = notif
    
    TweenService:Create(notif, TweenInfo.new(0.3), {Position = UDim2.new(0.5, -100, 0, 10)}):Play()
    wait(2)
    TweenService:Create(notif, TweenInfo.new(0.3), {Position = UDim2.new(0.5, -100, 0, -50)}):Play()
    wait(0.3)
    notif:Destroy()
end

local function DeepCopy(tbl)
    local copy = {}
    for k, v in pairs(tbl) do
        if type(v) == "table" then
            copy[k] = DeepCopy(v)
        else
            copy[k] = v
        end
    end
    return copy
end

-- Get settings for saving (excludes runtime-only settings)
local function GetSettingsForSave()
    local copy = DeepCopy(Settings)
    return copy
end

local function RefreshAllUI()
    -- Clear whitelist displays table
    WhitelistDisplays = {}
    
    -- Clear and recreate ESP and Aimbot frames to reflect loaded settings
    ESPFrame:ClearAllChildren()
    AimbotFrame:ClearAllChildren()
    
    local espLayout = Instance.new("UIListLayout")
    espLayout.Padding = UDim.new(0, 8)
    espLayout.Parent = ESPFrame
    
    local aimbotLayout = Instance.new("UIListLayout")
    aimbotLayout.Padding = UDim.new(0, 8)
    aimbotLayout.Parent = AimbotFrame
    
    -- Recreate ESP Controls
    CreateSection(ESPFrame, "Main Settings")
    CreateToggle(ESPFrame, "Enable ESP", Settings.ESP, "Enabled")
    CreateToggle(ESPFrame, "Show Teammates", Settings.ESP, "ShowTeammates")
    CreateToggle(ESPFrame, "Show Usernames", Settings.ESP, "ShowNames")
    CreateToggle(ESPFrame, "Show Health", Settings.ESP, "ShowHealth")
    CreateToggle(ESPFrame, "Show Equipped Tool", Settings.ESP, "ShowTool")
    
    CreateSection(ESPFrame, "Visual Settings")
    CreateToggle(ESPFrame, "Use Highlights", Settings.ESP, "UseHighlights")
    CreateToggle(ESPFrame, "Use Rank Color (Box)", Settings.ESP, "UseRankColor")
    CreateToggle(ESPFrame, "Use Rank Color (Name)", Settings.ESP, "UseRankColorForName")
    CreateSlider(ESPFrame, "Max Distance", Settings.ESP, "MaxDistance", 100, 5000)
    
    -- Recreate Aimbot Controls
    CreateSection(AimbotFrame, "Main Settings")
    CreateToggle(AimbotFrame, "Enable Aimbot", Settings.Aimbot, "Enabled")
    CreateDropdown(AimbotFrame, "Aimbot Mode", {"Camera", "Mouse"}, Settings.Aimbot, "AimbotMode")
    CreateDropdown(AimbotFrame, "Target Part", {"Head", "Torso", "HumanoidRootPart"}, Settings.Aimbot, "TargetPart")
    
    CreateSection(AimbotFrame, "Targeting")
    CreateToggle(AimbotFrame, "Show FOV Circle", Settings.Aimbot, "ShowFOV")
    CreateToggle(AimbotFrame, "Wall Check", Settings.Aimbot, "WallCheck")
    CreateToggle(AimbotFrame, "Team Check", Settings.Aimbot, "TeamCheck")
    CreateSlider(AimbotFrame, "FOV Size", Settings.Aimbot, "FOV", 50, 500)
    CreateSlider(AimbotFrame, "Smoothness", Settings.Aimbot, "Smoothness", 1, 10)
    CreateSlider(AimbotFrame, "Mouse Sens", Settings.Aimbot, "MouseSensitivity", 1, 20)
    
    -- User Whitelist Section
    CreateSection(AimbotFrame, "User Whitelist (Session Only)")
    CreateTextBox(AimbotFrame, "Add User", RuntimeSettings.Aimbot, "UserWhitelist", "Username...")
    CreateWhitelistDisplay(AimbotFrame, RuntimeSettings.Aimbot, "UserWhitelist")
    
    -- Team Whitelist Section
    CreateSection(AimbotFrame, "Team Whitelist (Session Only)")
    CreateTextBox(AimbotFrame, "Add Team", RuntimeSettings.Aimbot, "TeamWhitelist", "Team name...")
    CreateWhitelistDisplay(AimbotFrame, RuntimeSettings.Aimbot, "TeamWhitelist")
end

-- MODIFIED: Save to file (excludes runtime settings)
SaveBtn.MouseButton1Click:Connect(function()
    local name = ConfigNameInput.Text:gsub("%s+", "")
    if name == "" then
        ShowNotification("Enter a config name!", Theme.Danger)
        return
    end
    
    -- Check if file already exists
    if isfile and isfile(GetConfigPath(name)) then
        ShowNotification("Config already exists! Use Override.", Theme.Warning)
        return
    end
    
    -- Encode settings to JSON (without runtime settings)
    local success, json = pcall(function()
        return HttpService:JSONEncode(GetSettingsForSave())
    end)
    
    if not success then
        ShowNotification("Failed to encode settings!", Theme.Danger)
        return
    end
    
    -- Write to file
    if writefile then
        local writeSuccess, err = pcall(function()
            writefile(GetConfigPath(name), json)
        end)
        
        if writeSuccess then
            SavedConfigs[name] = DeepCopy(Settings)
            SelectedConfig = name
            RefreshConfigList()
            ShowNotification("Config '" .. name .. "' saved to file!", Theme.Success)
        else
            ShowNotification("Failed to write file: " .. tostring(err), Theme.Danger)
        end
    else
        -- Fallback: just save to memory if no file functions
        SavedConfigs[name] = DeepCopy(Settings)
        SelectedConfig = name
        RefreshConfigList()
        ShowNotification("Config '" .. name .. "' saved (memory only)!", Theme.Warning)
    end
end)

-- MODIFIED: Load from file (preserves runtime settings)
LoadBtn.MouseButton1Click:Connect(function()
    local name = ConfigNameInput.Text:gsub("%s+", "")
    if name == "" then
        ShowNotification("Enter a config name!", Theme.Danger)
        return
    end
    
    local path = GetConfigPath(name)
    
    -- Check if file exists
    if not isfile or not isfile(path) then
        -- Try loading from memory as fallback
        if SavedConfigs[name] then
            -- Preserve runtime settings
            local currentUserWhitelist = RuntimeSettings.Aimbot.UserWhitelist
            local currentTeamWhitelist = RuntimeSettings.Aimbot.TeamWhitelist
            Settings = DeepCopy(SavedConfigs[name])
            RuntimeSettings.Aimbot.UserWhitelist = currentUserWhitelist
            RuntimeSettings.Aimbot.TeamWhitelist = currentTeamWhitelist
            SelectedConfig = name
            RefreshAllUI()
            RefreshConfigList()
            ShowNotification("Config '" .. name .. "' loaded from memory!", Theme.Success)
            return
        end
        ShowNotification("Config file not found!", Theme.Danger)
        return
    end
    
    -- Read file
    local readSuccess, content = pcall(function()
        return readfile(path)
    end)
    
    if not readSuccess then
        ShowNotification("Failed to read file!", Theme.Danger)
        return
    end
    
    -- Decode JSON
    local decodeSuccess, data = pcall(function()
        return HttpService:JSONDecode(content)
    end)
    
    if not decodeSuccess or not data then
        ShowNotification("Failed to decode config!", Theme.Danger)
        return
    end
    
    -- Validate data structure
    if not data.ESP or not data.Aimbot then
        ShowNotification("Invalid config format!", Theme.Danger)
        return
    end
    
    -- Preserve runtime settings before applying
    local currentUserWhitelist = RuntimeSettings.Aimbot.UserWhitelist
    local currentTeamWhitelist = RuntimeSettings.Aimbot.TeamWhitelist
    
    -- Apply settings
    Settings = DeepCopy(data)
    SavedConfigs[name] = DeepCopy(data)
    SelectedConfig = name
    
    -- Restore runtime settings
    RuntimeSettings.Aimbot.UserWhitelist = currentUserWhitelist
    RuntimeSettings.Aimbot.TeamWhitelist = currentTeamWhitelist
    
    RefreshAllUI()
    RefreshConfigList()
    ShowNotification("Config '" .. name .. "' loaded from file!", Theme.Success)
end)

-- MODIFIED: Override file (excludes runtime settings)
OverrideBtn.MouseButton1Click:Connect(function()
    local name = ConfigNameInput.Text:gsub("%s+", "")
    if name == "" then
        ShowNotification("Enter a config name!", Theme.Danger)
        return
    end
    
    local path = GetConfigPath(name)
    
    -- Check if file exists
    if isfile and not isfile(path) then
        ShowNotification("Config file doesn't exist! Use Save.", Theme.Warning)
        return
    end
    
    -- Encode settings (without runtime settings)
    local success, json = pcall(function()
        return HttpService:JSONEncode(GetSettingsForSave())
    end)
    
    if not success then
        ShowNotification("Failed to encode settings!", Theme.Danger)
        return
    end
    
    -- Write to file
    if writefile then
        local writeSuccess, err = pcall(function()
            writefile(path, json)
        end)
        
        if writeSuccess then
            SavedConfigs[name] = DeepCopy(Settings)
            SelectedConfig = name
            RefreshConfigList()
            ShowNotification("Config '" .. name .. "' overridden!", Theme.Success)
        else
            ShowNotification("Failed to write file: " .. tostring(err), Theme.Danger)
        end
    else
        SavedConfigs[name] = DeepCopy(Settings)
        SelectedConfig = name
        RefreshConfigList()
        ShowNotification("Config '" .. name .. "' overridden (memory only)!", Theme.Warning)
    end
end)

-- MODIFIED: Delete file
DeleteBtn.MouseButton1Click:Connect(function()
    local name = ConfigNameInput.Text:gsub("%s+", "")
    if name == "" then
        ShowNotification("Enter a config name!", Theme.Danger)
        return
    end
    
    local path = GetConfigPath(name)
    local fileExists = isfile and isfile(path)
    
    if not fileExists and not SavedConfigs[name] then
        ShowNotification("Config not found!", Theme.Danger)
        return
    end
    
    -- Delete file if it exists
    if fileExists and delfile then
        local delSuccess, err = pcall(function()
            delfile(path)
        end)
        
        if not delSuccess then
            ShowNotification("Failed to delete file: " .. tostring(err), Theme.Danger)
            return
        end
    end
    
    -- Remove from memory
    SavedConfigs[name] = nil
    if SelectedConfig == name then
        SelectedConfig = nil
        ConfigNameInput.Text = ""
    end
    RefreshConfigList()
    ShowNotification("Config '" .. name .. "' deleted!", Theme.Success)
end)

-- MODIFIED: Export (excludes runtime settings)
ExportBtn.MouseButton1Click:Connect(function()
    local success, json = pcall(function()
        return HttpService:JSONEncode(GetSettingsForSave())
    end)
    
    if success then
        JsonBox.Text = json
        -- Copy to clipboard if possible
        if setclipboard then
            setclipboard(json)
            ShowNotification("Copied to clipboard!", Theme.Success)
        else
            ShowNotification("Export ready - copy from textbox", Theme.Accent)
        end
    else
        ShowNotification("Export failed!", Theme.Danger)
    end
end)

ImportBtn.MouseButton1Click:Connect(function()
    local json = JsonBox.Text
    if json == "" then
        ShowNotification("Paste JSON first!", Theme.Warning)
        return
    end
    
    local success, data = pcall(function()
        return HttpService:JSONDecode(json)
    end)
    
    if success and data then
        -- Validate data structure
        if data.ESP and data.Aimbot then
            -- Preserve runtime settings
            local currentUserWhitelist = RuntimeSettings.Aimbot.UserWhitelist
            local currentTeamWhitelist = RuntimeSettings.Aimbot.TeamWhitelist
            
            Settings = DeepCopy(data)
            
            -- Restore runtime settings
            RuntimeSettings.Aimbot.UserWhitelist = currentUserWhitelist
            RuntimeSettings.Aimbot.TeamWhitelist = currentTeamWhitelist
            
            RefreshAllUI()
            ShowNotification("Config imported!", Theme.Success)
        else
            ShowNotification("Invalid config format!", Theme.Danger)
        end
    else
        ShowNotification("Invalid JSON!", Theme.Danger)
    end
end)

-- Initialize config list (load from files)
LoadExistingConfigs()
RefreshConfigList()

-- Tab Switching with animation
local function switchTab(tabName)
    ESPFrame.Visible = tabName == "ESP"
    AimbotFrame.Visible = tabName == "AIMBOT"
    SettingsFrame.Visible = tabName == "SETTINGS"
    
    ESPButton.BackgroundColor3 = tabName == "ESP" and Theme.Accent or Theme.SurfaceHover
    ESPButton.TextColor3 = tabName == "ESP" and Theme.Text or Theme.TextMuted
    
    AimbotButton.BackgroundColor3 = tabName == "AIMBOT" and Theme.Accent or Theme.SurfaceHover
    AimbotButton.TextColor3 = tabName == "AIMBOT" and Theme.Text or Theme.TextMuted
    
    SettingsButton.BackgroundColor3 = tabName == "SETTINGS" and Theme.Accent or Theme.SurfaceHover
    SettingsButton.TextColor3 = tabName == "SETTINGS" and Theme.Text or Theme.TextMuted
end

ESPButton.MouseButton1Click:Connect(function()
    switchTab("ESP")
end)

AimbotButton.MouseButton1Click:Connect(function()
    switchTab("AIMBOT")
end)

SettingsButton.MouseButton1Click:Connect(function()
    switchTab("SETTINGS")
end)

-- Minimize functionality
local Minimized = false
MinimizeButton.MouseButton1Click:Connect(function()
    Minimized = not Minimized
    
    local targetSize = Minimized and UDim2.new(0, 420, 0, 50) or UDim2.new(0, 420, 0, 540)
    TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {Size = targetSize}):Play()
    
    MinimizeButton.Text = Minimized and "+" or "−"
    
    ESPFrame.Visible = not Minimized and ESPFrame.Visible
    AimbotFrame.Visible = not Minimized and AimbotFrame.Visible
    SettingsFrame.Visible = not Minimized and SettingsFrame.Visible
    TabContainer.Visible = not Minimized
end)

-- Close functionality
CloseButton.MouseButton1Click:Connect(function()
    TweenService:Create(MainFrame, TweenInfo.new(0.2), {Size = UDim2.new(0, 420, 0, 0)}):Play()
    wait(0.2)
    ScreenGui:Destroy()
    for _, player in ipairs(Players:GetPlayers()) do
        ClearESP(player)
    end
    if FOV_Circle then FOV_Circle:Remove() end
    if ESP_Connection then ESP_Connection:Disconnect() end
end)

-- ESP IMPLEMENTATION WITH TEAMMATE CHECK
local ESP_Objects = {}

local function GetCharacter(player)
    return player.Character
end

local function GetHumanoid(character)
    return character:FindFirstChildOfClass("Humanoid")
end

local function GetTeamColor(player)
    if player.Team then
        return player.Team.TeamColor.Color
    end
    return Color3.fromRGB(255, 255, 255)
end

local function IsTeammate(player)
    return player.Team == LocalPlayer.Team
end

local function GetRankColor(character)
    local head = character:FindFirstChild("Head")
    if not head then return nil end
    
    local rank = head:FindFirstChild("Rank")
    if not rank then return nil end
    
    local dept = rank:FindFirstChild("Dept")
    if not dept then return nil end
    
    local textObj = dept:FindFirstChild("Text")
    if not textObj then return nil end
    
    if textObj:IsA("TextLabel") or textObj:IsA("TextBox") or textObj:IsA("TextButton") then
        return textObj.TextColor3
    end
    
    if textObj:IsA("BasePart") then
        return textObj.Color
    end
    
    return nil
end

local function GetESPColor(player, character)
    if Settings.ESP.UseRankColor and character then
        local rankColor = GetRankColor(character)
        if rankColor then
            return rankColor
        end
    end
    return GetTeamColor(player)
end

-- NEW FUNCTION: Get name color based on settings
local function GetNameColor(player, character)
    if Settings.ESP.UseRankColorForName and character then
        local rankColor = GetRankColor(character)
        if rankColor then
            return rankColor
        end
    end
    return Settings.ESP.TextColor
end

local function ClearESP(player)
    if ESP_Objects[player] then
        if ESP_Objects[player].Box then ESP_Objects[player].Box:Remove() end
        if ESP_Objects[player].Name then ESP_Objects[player].Name:Remove() end
        if ESP_Objects[player].Health then ESP_Objects[player].Health:Remove() end
        if ESP_Objects[player].Tool then ESP_Objects[player].Tool:Remove() end
        if ESP_Objects[player].Highlight then ESP_Objects[player].Highlight:Destroy() end
        ESP_Objects[player] = nil
    end
end

local function ShouldShowESP(player)
    -- Don't show ESP for local player
    if player == LocalPlayer then return false end
    
    -- Check teammate setting
    if not Settings.ESP.ShowTeammates and IsTeammate(player) then
        return false
    end
    
    return true
end

local function CreateESP(player)
    if not ShouldShowESP(player) then return end
    
    ClearESP(player)
    
    local character = GetCharacter(player)
    if not character then return end
    
    local espColor = GetESPColor(player, character)
    
    local highlight = Instance.new("Highlight")
    highlight.Name = "ESPHighlight"
    highlight.FillTransparency = 0.6
    highlight.OutlineTransparency = 0.2
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.FillColor = espColor
    -- Cambiado a Occluded para que requiera línea de visión y no se vea a través de todo el mapa
    highlight.DepthMode = Enum.HighlightDepthMode.Occluded
    highlight.Parent = character
    
    local box = Drawing.new("Square")
    box.Visible = false
    box.Thickness = 2
    box.Filled = false
    
    local nameText = Drawing.new("Text")
    nameText.Visible = false
    nameText.Size = Settings.ESP.TextSize
    nameText.Center = true
    nameText.Outline = true
    nameText.OutlineColor = Color3.fromRGB(0, 0, 0)
    
    local healthText = Drawing.new("Text")
    healthText.Visible = false
    healthText.Size = Settings.ESP.TextSize
    healthText.Center = true
    healthText.Outline = true
    healthText.OutlineColor = Color3.fromRGB(0, 0, 0)
    
    local toolText = Drawing.new("Text")
    toolText.Visible = false
    toolText.Size = Settings.ESP.TextSize
    toolText.Center = true
    toolText.Outline = true
    toolText.OutlineColor = Color3.fromRGB(0, 0, 0)
    
    ESP_Objects[player] = {
        Box = box,
        Name = nameText,
        Health = healthText,
        Tool = toolText,
        Highlight = highlight,
        Character = character
    }
end

local function UpdateESP()
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        
        local character = GetCharacter(player)
        local espData = ESP_Objects[player]
        
        -- Check if we should show ESP for this player
        if not ShouldShowESP(player) then
            if espData then
                ClearESP(player)
            end
            continue
        end
        
        if character and not espData then
            CreateESP(player)
            espData = ESP_Objects[player]
        end
        
        if espData and not character then
            ClearESP(player)
            continue
        end
        
        if not character or not espData then continue end
        
        if espData.Character ~= character then
            ClearESP(player)
            CreateESP(player)
            espData = ESP_Objects[player]
        end
        
        local humanoid = GetHumanoid(character)
        local hrp = character:FindFirstChild("HumanoidRootPart")
        
        if not humanoid or not hrp or humanoid.Health <= 0 then
            espData.Box.Visible = false
            espData.Name.Visible = false
            espData.Health.Visible = false
            espData.Tool.Visible = false
            if espData.Highlight then espData.Highlight.Enabled = false end
            continue
        end
        
        local distance = (hrp.Position - Camera.CFrame.Position).Magnitude
        if distance > Settings.ESP.MaxDistance then
            espData.Box.Visible = false
            espData.Name.Visible = false
            espData.Health.Visible = false
            espData.Tool.Visible = false
            if espData.Highlight then espData.Highlight.Enabled = false end
            continue
        end
        
        local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
        if not onScreen then
            espData.Box.Visible = false
            espData.Name.Visible = false
            espData.Health.Visible = false
            espData.Tool.Visible = false
            if espData.Highlight then espData.Highlight.Enabled = false end
            continue
        end
        
        local espColor = GetESPColor(player, character)
        local nameColor = GetNameColor(player, character) -- Get name color based on settings
        
        if Settings.ESP.Enabled then
            if Settings.ESP.UseHighlights and espData.Highlight then
                espData.Highlight.Enabled = true
                espData.Highlight.FillColor = espColor
                espData.Highlight.OutlineColor = espColor
                espData.Box.Visible = false
            else
                if espData.Highlight then espData.Highlight.Enabled = false end
                
                local head = character:FindFirstChild("Head")
                if head then
                    local headPos = Camera:WorldToViewportPoint(head.Position)
                    local rootPos = Camera:WorldToViewportPoint(hrp.Position)
                    local height = math.abs(headPos.Y - rootPos.Y) * 1.2
                    local width = height * 0.6
                    
                    espData.Box.Size = Vector2.new(width, height)
                    espData.Box.Position = Vector2.new(pos.X - width/2, pos.Y - height/2)
                    espData.Box.Color = espColor
                    espData.Box.Visible = true
                end
            end
            
            if Settings.ESP.ShowNames then
                espData.Name.Position = Vector2.new(pos.X, pos.Y - 40)
                espData.Name.Text = player.Name
                espData.Name.Color = nameColor -- Use the new name color function
                espData.Name.Visible = true
            else
                espData.Name.Visible = false
            end
            
            if Settings.ESP.ShowHealth then
                espData.Health.Position = Vector2.new(pos.X, pos.Y - 25)
                espData.Health.Text = math.floor(humanoid.Health) .. "/" .. math.floor(humanoid.MaxHealth)
                espData.Health.Color = Color3.fromRGB(255 - (humanoid.Health/humanoid.MaxHealth)*255, (humanoid.Health/humanoid.MaxHealth)*255, 0)
                espData.Health.Visible = true
            else
                espData.Health.Visible = false
            end
            
            if Settings.ESP.ShowTool then
                local tool = character:FindFirstChildOfClass("Tool")
                espData.Tool.Position = Vector2.new(pos.X, pos.Y + 20)
                espData.Tool.Text = tool and tool.Name or "None"
                espData.Tool.Color = Color3.fromRGB(255, 255, 0)
                espData.Tool.Visible = true
            else
                espData.Tool.Visible = false
            end
        else
            espData.Box.Visible = false
            espData.Name.Visible = false
            espData.Health.Visible = false
            espData.Tool.Visible = false
            if espData.Highlight then espData.Highlight.Enabled = false end
        end
    end
end

-- AIMBOT
local FOV_Circle = Drawing.new("Circle")
FOV_Circle.Visible = false
FOV_Circle.Thickness = 1
FOV_Circle.Filled = false

local function IsPlayerValid(player)
    if player == LocalPlayer then return false end
    
    -- Check user whitelist (runtime only)
    if #RuntimeSettings.Aimbot.UserWhitelist > 0 then
        if table.find(RuntimeSettings.Aimbot.UserWhitelist, player.Name) then
            return false
        end
    end
    
    local character = GetCharacter(player)
    if not character then return false end
    
    local humanoid = GetHumanoid(character)
    if not humanoid or humanoid.Health <= 0 then return false end
    
    local targetPart = character:FindFirstChild(Settings.Aimbot.TargetPart)
    if not targetPart then return false end
    
    -- Check team whitelist (runtime only)
    if #RuntimeSettings.Aimbot.TeamWhitelist > 0 and player.Team then
        if table.find(RuntimeSettings.Aimbot.TeamWhitelist, tostring(player.Team.Name)) then
            return false
        end
    end
    
    if Settings.Aimbot.TeamCheck then
        if player.Team == LocalPlayer.Team then return false end
    end
    
    if Settings.Aimbot.WallCheck then
        local origin = Camera.CFrame.Position
        local direction = (targetPart.Position - origin).Unit * (targetPart.Position - origin).Magnitude
        local raycastParams = RaycastParams.new()
        raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, character}
        raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
        
        local result = Workspace:Raycast(origin, direction, raycastParams)
        if result then return false end
    end
    
    return true
end

local function GetClosestPlayer()
    local closestPlayer = nil
    local closestDistance = Settings.Aimbot.FOV
    local mousePos = UserInputService:GetMouseLocation()
    
    for _, player in ipairs(Players:GetPlayers()) do
        if not IsPlayerValid(player) then continue end
        
        local character = GetCharacter(player)
        local targetPart = character:FindFirstChild(Settings.Aimbot.TargetPart)
        if not targetPart then continue end
        
        local pos = Camera:WorldToViewportPoint(targetPart.Position)
        if pos.Z < 0 then continue end
        
        local distance = (Vector2.new(pos.X, pos.Y) - mousePos).Magnitude
        if distance < closestDistance then
            closestDistance = distance
            closestPlayer = player
        end
    end
    
    return closestPlayer
end

local function AimCameraAt(target)
    if not target then return end
    
    local character = GetCharacter(target)
    if not character then return end
    
    local targetPart = character:FindFirstChild(Settings.Aimbot.TargetPart)
    if not targetPart then return end
    
    local targetPos = targetPart.Position
    local targetCFrame = CFrame.new(Camera.CFrame.Position, targetPos)
    
    if Settings.Aimbot.Smoothness <= 1 then
        Camera.CFrame = targetCFrame
    else
        local smoothFactor = 1 / Settings.Aimbot.Smoothness
        Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, smoothFactor)
    end
end

local function AimMouseAt(target)
    if not target then return end
    
    local character = GetCharacter(target)
    if not character then return end
    
    local targetPart = character:FindFirstChild(Settings.Aimbot.TargetPart)
    if not targetPart then return end
    
    local pos = Camera:WorldToViewportPoint(targetPart.Position)
    if pos.Z < 0 then return end
    
    local currentMousePos = UserInputService:GetMouseLocation()
    local targetPos = Vector2.new(pos.X, pos.Y)
    
    local delta = targetPos - currentMousePos
    
    if Settings.Aimbot.Smoothness > 1 then
        delta = delta / Settings.Aimbot.Smoothness
    end
    
    delta = delta * (Settings.Aimbot.MouseSensitivity / 10)
    
    local success = pcall(function()
        mousemoverel(delta.X, delta.Y)
    end)
    
    if not success then
        pcall(function()
            mousemoveabs(pos.X, pos.Y)
        end)
    end
end

-- Initialize ESP for existing players
for _, player in ipairs(Players:GetPlayers()) do
    if player.Character then
        CreateESP(player)
    end
end

-- Handle new players and respawns
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(char)
        wait(0.5)
        CreateESP(player)
    end)
end)

for _, player in ipairs(Players:GetPlayers()) do
    player.CharacterAdded:Connect(function(char)
        wait(0.5)
        CreateESP(player)
    end)
end

Players.PlayerRemoving:Connect(function(player)
    ClearESP(player)
end)

-- Main Loop
ESP_Connection = RunService.RenderStepped:Connect(function()
    if Settings.Aimbot.ShowFOV and Settings.Aimbot.Enabled then
        FOV_Circle.Position = UserInputService:GetMouseLocation()
        FOV_Circle.Radius = Settings.Aimbot.FOV
        FOV_Circle.Color = Settings.Aimbot.FOVColor
        FOV_Circle.Visible = true
    else
        FOV_Circle.Visible = false
    end
    
    UpdateESP()
    
    if not Settings.Aimbot.Enabled then return end
    
    if Settings.Aimbot.AimbotMode == "Camera" then
        if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
            local target = GetClosestPlayer()
            if target then
                AimCameraAt(target)
            end
        end
    else
        if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
            local target = GetClosestPlayer()
            if target then
                AimMouseAt(target)
            end
        end
    end
end)

-- Toggle GUI with RightCtrl
UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.RightControl then
        MainFrame.Visible = not MainFrame.Visible
    end
end)
