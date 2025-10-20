local Nebula = {}

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

-- Cache frequently used objects
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local Utility = {}
local Objects = {}
local ActiveTweens = {}
local NebulaInstances = {}

-- Configuration
local CONFIG = {
    DRAG_SMOOTHNESS = 0.1,
    TWEEN_DURATION = 0.15,
    COLOR_UPDATE_INTERVAL = 0.1,
    MAX_ELEMENTS_PER_SECTION = 50,
    SCROLL_DEBOUNCE = 0.1,
    ELEMENT_SPACING = 3
}

-- Theme system
local ThemeManager = {}
ThemeManager.CurrentTheme = "DarkTheme"

local ThemeStyles = {
    DarkTheme = {
        SchemeColor = Color3.fromRGB(74, 99, 135),
        Background = Color3.fromRGB(36, 37, 43),
        Header = Color3.fromRGB(28, 29, 34),
        TextColor = Color3.fromRGB(255, 255, 255),
        ElementColor = Color3.fromRGB(32, 32, 38),
        AccentColor = Color3.fromRGB(86, 76, 251),
        SuccessColor = Color3.fromRGB(46, 204, 113),
        WarningColor = Color3.fromRGB(241, 196, 15),
        ErrorColor = Color3.fromRGB(231, 76, 60)
    },
    LightTheme = {
        SchemeColor = Color3.fromRGB(150, 150, 150),
        Background = Color3.fromRGB(255, 255, 255),
        Header = Color3.fromRGB(200, 200, 200),
        TextColor = Color3.fromRGB(0, 0, 0),
        ElementColor = Color3.fromRGB(224, 224, 224),
        AccentColor = Color3.fromRGB(86, 76, 251),
        SuccessColor = Color3.fromRGB(46, 204, 113),
        WarningColor = Color3.fromRGB(241, 196, 15),
        ErrorColor = Color3.fromRGB(231, 76, 60)
    },
    BlueTheme = {
        SchemeColor = Color3.fromRGB(66, 135, 245),
        Background = Color3.fromRGB(25, 35, 60),
        Header = Color3.fromRGB(20, 28, 48),
        TextColor = Color3.fromRGB(240, 240, 240),
        ElementColor = Color3.fromRGB(35, 45, 70),
        AccentColor = Color3.fromRGB(86, 156, 251),
        SuccessColor = Color3.fromRGB(46, 204, 113),
        WarningColor = Color3.fromRGB(241, 196, 15),
        ErrorColor = Color3.fromRGB(231, 76, 60)
    },
    PurpleTheme = {
        SchemeColor = Color3.fromRGB(155, 89, 182),
        Background = Color3.fromRGB(45, 30, 60),
        Header = Color3.fromRGB(35, 22, 48),
        TextColor = Color3.fromRGB(240, 240, 240),
        ElementColor = Color3.fromRGB(55, 40, 70),
        AccentColor = Color3.fromRGB(175, 109, 202),
        SuccessColor = Color3.fromRGB(46, 204, 113),
        WarningColor = Color3.fromRGB(241, 196, 15),
        ErrorColor = Color3.fromRGB(231, 76, 60)
    }
}

function ThemeManager:ValidateTheme(theme)
    if type(theme) == "string" then
        return ThemeStyles[theme] or ThemeStyles.DarkTheme
    end
    
    local default = ThemeStyles.DarkTheme
    local validated = {}
    
    for key, value in pairs(default) do
        validated[key] = theme[key] or value
    end
    
    return validated
end

function ThemeManager:SetTheme(themeName)
    if ThemeStyles[themeName] then
        self.CurrentTheme = themeName
        return ThemeStyles[themeName]
    end
    return ThemeStyles.DarkTheme
end

function ThemeManager:GetCurrentTheme()
    return ThemeStyles[self.CurrentTheme]
end

function ThemeManager:CreateCustomTheme(customTheme)
    return self:ValidateTheme(customTheme)
end

-- Utility functions
function Utility:TweenObject(obj, properties, duration, easingStyle, easingDirection)
    if ActiveTweens[obj] then
        ActiveTweens[obj]:Cancel()
    end
    
    local tweenInfo = TweenInfo.new(
        duration or CONFIG.TWEEN_DURATION,
        easingStyle or Enum.EasingStyle.Quad,
        easingDirection or Enum.EasingDirection.Out
    )
    
    local tween = TweenService:Create(obj, tweenInfo, properties)
    ActiveTweens[obj] = tween
    tween:Play()
    
    tween.Completed:Connect(function()
        ActiveTweens[obj] = nil
    end)
    
    return tween
end

function Utility:CancelAllTweens()
    for _, tween in pairs(ActiveTweens) do
        pcall(function() tween:Cancel() end)
    end
    table.clear(ActiveTweens)
end

function Utility:CreateCoroutine(callback)
    return coroutine.wrap(callback)()
end

function Utility:Debounce(func, wait)
    local lastCall = 0
    return function(...)
        local now = tick()
        if now - lastCall > wait then
            lastCall = now
            return func(...)
        end
    end
end

-- Error Handling System
local ErrorHandler = {}
ErrorHandler.Enabled = true

function ErrorHandler:CaptureError(scope, errorMsg)
    if not self.Enabled then return end
    
    warn(string.format("[Nebula UI Error] %s: %s", scope, tostring(errorMsg)))
    
    -- Send to notification system if available
    pcall(function()
        if Nebula.SendNotification then
            Nebula:SendNotification("UI Error", string.format("Error in %s", scope), "Error", 5)
        end
    end)
end

function ErrorHandler:TryExecute(callback, errorScope)
    local success, result = pcall(callback)
    if not success then
        self:CaptureError(errorScope or "Unknown", result)
    end
    return success, result
end

-- Settings Manager
local SettingsManager = {}
SettingsManager.Configs = {}
SettingsManager.AutoSave = true

function SettingsManager:SaveConfig(libInstance, configName)
    ErrorHandler:TryExecute(function()
        configName = configName or "NebulaConfig"
        
        local configData = {
            Theme = ThemeManager.CurrentTheme,
            WindowSize = libInstance.Main.Size,
            WindowPosition = libInstance.Main.Position,
            Elements = {}
        }
        
        -- Recursively gather element states
        local function gatherElementStates(container, path)
            for _, child in ipairs(container:GetChildren()) do
                if child:IsA("TextButton") and child.Name:match("TabButton") then
                    local tabName = child.Name:gsub("TabButton", "")
                    local page = libInstance.Pages:FindFirstChild(tabName .. "Page")
                    
                    if page then
                        for _, section in ipairs(page:GetDescendants()) do
                            if section:IsA("Frame") and section.Name == "sectionFrame" then
                                local sectionName = section.sectionHead.sectionName.Text
                                
                                for _, element in ipairs(section.sectionInners:GetChildren()) do
                                    if element:IsA("TextButton") or element:IsA("Frame") then
                                        local elementData = {
                                            Type = element.ClassName,
                                            Name = element.Name,
                                            State = nil
                                        }
                                        
                                        -- Toggle state
                                        if element:FindFirstChild("toggleFrame") then
                                            elementData.State = element.toggleFrame.BackgroundColor3 == ThemeManager:GetCurrentTheme().SuccessColor
                                        -- Slider value
                                        elseif element:FindFirstChild("sliderValue") then
                                            elementData.State = tonumber(element.sliderValue.Text)
                                        -- Dropdown selection
                                        elseif element:FindFirstChild("dropdownValue") then
                                            elementData.State = element.dropdownValue.Text
                                        -- Textbox text
                                        elseif element:FindFirstChild("textboxInput") then
                                            elementData.State = element.textboxInput.Text
                                        -- Keybind value
                                        elseif element:FindFirstChild("keybindValue") then
                                            elementData.State = element.keybindValue.Text
                                        end
                                        
                                        if elementData.State ~= nil then
                                            table.insert(configData.Elements, {
                                                Path = path .. "/" .. tabName .. "/" .. sectionName .. "/" .. element.Name,
                                                Data = elementData
                                            })
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        
        gatherElementStates(libInstance.MainSide.tabFrames, "")
        
        local jsonData = HttpService:JSONEncode(configData)
        
        -- Save to data store (in real implementation, you'd use DataStoreService)
        SettingsManager.Configs[configName] = configData
        
        Nebula:SendNotification("Settings", string.format("Config '%s' saved!", configName), "Success", 3)
        return jsonData
    end, "SaveConfig")
end

function SettingsManager:LoadConfig(libInstance, configName)
    ErrorHandler:TryExecute(function()
        configName = configName or "NebulaConfig"
        local configData = SettingsManager.Configs[configName]
        
        if not configData then
            Nebula:SendNotification("Settings", string.format("Config '%s' not found!", configName), "Error", 3)
            return false
        end
        
        -- Apply theme
        if configData.Theme then
            Nebula:ChangeTheme(configData.Theme)
        end
        
        -- Apply window settings
        if configData.WindowSize then
            libInstance.Main.Size = configData.WindowSize
        end
        if configData.WindowPosition then
            libInstance.Main.Position = configData.WindowPosition
        end
        
        -- Apply element states
        for _, elementConfig in ipairs(configData.Elements) do
            local pathParts = string.split(elementConfig.Path, "/")
            -- Implementation would traverse UI tree and restore states
            -- This is simplified - actual implementation would need proper element finding
        end
        
        Nebula:SendNotification("Settings", string.format("Config '%s' loaded!", configName), "Success", 3)
        return true
    end, "LoadConfig")
end

function SettingsManager:ExportConfig(configName)
    ErrorHandler:TryExecute(function()
        configName = configName or "NebulaConfig"
        local configData = SettingsManager.Configs[configName]
        
        if configData then
            return HttpService:JSONEncode(configData)
        end
        return nil
    end, "ExportConfig")
end

function SettingsManager:ImportConfig(jsonData)
    ErrorHandler:TryExecute(function()
        local configData = HttpService:JSONDecode(jsonData)
        local configName = "ImportedConfig_" .. os.time()
        SettingsManager.Configs[configName] = configData
        return configName
    end, "ImportConfig")
end

-- Ripple Effect Manager
local RippleManager = {}
RippleManager.ActiveRipples = {}

function RippleManager:CreateRipple(button, color, scaleMultiplier)
    ErrorHandler:TryExecute(function()
        scaleMultiplier = scaleMultiplier or 1.5
        
        local Sample = Instance.new("ImageLabel")
        Sample.Name = "RippleSample"
        Sample.Parent = button
        Sample.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Sample.BackgroundTransparency = 1.000
        Sample.Image = "http://www.roblox.com/asset/?id=4560909609"
        Sample.ImageColor3 = color
        Sample.ImageTransparency = 0.600
        Sample.ZIndex = 10
        Sample.AnchorPoint = Vector2.new(0.5, 0.5)
        
        local buttonSize = button.AbsoluteSize
        local x, y = (Mouse.X - Sample.AbsolutePosition.X), (Mouse.Y - Sample.AbsolutePosition.Y)
        Sample.Position = UDim2.new(0, x, 0, y)
        
        local size = math.max(buttonSize.X, buttonSize.Y) * scaleMultiplier
        Sample.Size = UDim2.new(0, 0, 0, 0)
        
        local tween = Utility:TweenObject(Sample, {
            Size = UDim2.new(0, size, 0, size),
            Position = UDim2.new(0.5, -size/2, 0.5, -size/2),
            ImageTransparency = 1
        }, 0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        
        tween.Completed:Connect(function()
            if Sample and Sample.Parent then
                Sample:Destroy()
            end
        end)
        
        return Sample
    end, "CreateRipple")
end

-- Dragging System
function Nebula:DraggingEnabled(frame, parent)
    ErrorHandler:TryExecute(function()
        parent = parent or frame
        
        local dragging = false
        local dragInput, mousePos, framePos
        local connection

        local function Update(input)
            if not dragging then return end
            
            local delta = input.Position - mousePos
            local newPos = UDim2.new(
                framePos.X.Scale, 
                framePos.X.Offset + delta.X,
                framePos.Y.Scale, 
                framePos.Y.Offset + delta.Y
            )
            
            parent.Position = newPos
        end

        frame.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                mousePos = input.Position
                framePos = parent.Position
                
                if connection then
                    connection:Disconnect()
                end
                
                connection = input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                        if connection then
                            connection:Disconnect()
                        end
                    end
                end)
            end
        end)

        UserInputService.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement then
                dragInput = input
            end
            
            if input == dragInput and dragging then
                Update(input)
            end
        end)
    end, "DraggingEnabled")
end

-- Notification System
local NotificationManager = {}
NotificationManager.Notifications = {}
NotificationManager.NotificationQueue = {}

function NotificationManager:SendNotification(title, message, notificationType, duration)
    return ErrorHandler:TryExecute(function()
        duration = duration or 5
        notificationType = notificationType or "Info"
        
        local lib = NebulaInstances[1]
        if not lib then return end
        
        local notification = Instance.new("Frame")
        notification.Name = "Notification"
        notification.Parent = lib.Main
        notification.BackgroundColor3 = ThemeManager:GetCurrentTheme().ElementColor
        notification.BorderSizePixel = 0
        notification.Size = UDim2.new(0, 300, 0, 80)
        notification.Position = UDim2.new(1, 10, 1, -90)
        notification.AnchorPoint = Vector2.new(1, 1)
        notification.ZIndex = 100
        
        local UICorner = Instance.new("UICorner")
        UICorner.CornerRadius = UDim.new(0, 8)
        UICorner.Parent = notification
        
        local stroke = Instance.new("UIStroke")
        stroke.Parent = notification
        stroke.Color = ThemeManager:GetCurrentTheme().SchemeColor
        stroke.Thickness = 2
        
        local titleLabel = Instance.new("TextLabel")
        titleLabel.Name = "Title"
        titleLabel.Parent = notification
        titleLabel.BackgroundTransparency = 1
        titleLabel.Position = UDim2.new(0, 15, 0, 10)
        titleLabel.Size = UDim2.new(1, -30, 0, 20)
        titleLabel.Font = Enum.Font.GothamBold
        titleLabel.Text = title
        titleLabel.TextColor3 = ThemeManager:GetCurrentTheme().TextColor
        titleLabel.TextSize = 16
        titleLabel.TextXAlignment = Enum.TextXAlignment.Left
        
        local messageLabel = Instance.new("TextLabel")
        messageLabel.Name = "Message"
        messageLabel.Parent = notification
        messageLabel.BackgroundTransparency = 1
        messageLabel.Position = UDim2.new(0, 15, 0, 35)
        messageLabel.Size = UDim2.new(1, -30, 0, 35)
        messageLabel.Font = Enum.Font.Gotham
        messageLabel.Text = message
        messageLabel.TextColor3 = ThemeManager:GetCurrentTheme().TextColor
        messageLabel.TextSize = 14
        messageLabel.TextXAlignment = Enum.TextXAlignment.Left
        messageLabel.TextYAlignment = Enum.TextYAlignment.Top
        messageLabel.TextWrapped = true
        
        local closeBtn = Instance.new("ImageButton")
        closeBtn.Name = "Close"
        closeBtn.Parent = notification
        closeBtn.BackgroundTransparency = 1
        closeBtn.Position = UDim2.new(1, -25, 0, 10)
        closeBtn.Size = UDim2.new(0, 15, 0, 15)
        closeBtn.Image = "rbxassetid://3926305904"
        closeBtn.ImageRectOffset = Vector2.new(284, 4)
        closeBtn.ImageRectSize = Vector2.new(24, 24)
        closeBtn.ImageColor3 = ThemeManager:GetCurrentTheme().TextColor
        
        closeBtn.MouseButton1Click:Connect(function()
            Utility:TweenObject(notification, {
                Position = UDim2.new(1, 10, 1, 100)
            }, 0.3):Play()
            wait(0.3)
            notification:Destroy()
        end)
        
        -- Set color based on type
        local colorMap = {
            Info = ThemeManager:GetCurrentTheme().SchemeColor,
            Success = ThemeManager:GetCurrentTheme().SuccessColor,
            Warning = ThemeManager:GetCurrentTheme().WarningColor,
            Error = ThemeManager:GetCurrentTheme().ErrorColor
        }
        
        stroke.Color = colorMap[notificationType] or ThemeManager:GetCurrentTheme().SchemeColor
        
        -- Animate in
        notification.Position = UDim2.new(1, 10, 1, 100)
        Utility:TweenObject(notification, {
            Position = UDim2.new(1, 10, 1, -90)
        }, 0.3):Play()
        
        -- Auto remove after duration
        delay(duration, function()
            if notification and notification.Parent then
                Utility:TweenObject(notification, {
                    Position = UDim2.new(1, 10, 1, 100)
                }, 0.3):Play()
                wait(0.3)
                notification:Destroy()
            end
        end)
        
        table.insert(self.Notifications, notification)
        return notification
    end, "SendNotification")
end

-- Search System
local SearchSystem = {}
SearchSystem.ActiveFilters = {}

function SearchSystem:CreateSearchBar(container)
    ErrorHandler:TryExecute(function()
        local searchFrame = Instance.new("Frame")
        searchFrame.Name = "SearchBar"
        searchFrame.Parent = container
        searchFrame.BackgroundColor3 = ThemeManager:GetCurrentTheme().ElementColor
        searchFrame.Size = UDim2.new(1, -10, 0, 35)
        searchFrame.Position = UDim2.new(0, 5, 0, 5)
        
        local searchCorner = Instance.new("UICorner")
        searchCorner.CornerRadius = UDim.new(0, 6)
        searchCorner.Parent = searchFrame
        
        local searchBox = Instance.new("TextBox")
        searchBox.Name = "SearchBox"
        searchBox.Parent = searchFrame
        searchBox.BackgroundTransparency = 1
        searchBox.Position = UDim2.new(0, 35, 0, 0)
        searchBox.Size = UDim2.new(1, -40, 1, 0)
        searchBox.Font = Enum.Font.Gotham
        searchBox.PlaceholderText = "Search tabs..."
        searchBox.PlaceholderColor3 = Color3.fromRGB(140, 140, 140)
        searchBox.TextColor3 = ThemeManager:GetCurrentTheme().TextColor
        searchBox.TextSize = 14
        searchBox.TextXAlignment = Enum.TextXAlignment.Left
        searchBox.ClearTextOnFocus = false
        
        local searchIcon = Instance.new("ImageLabel")
        searchIcon.Name = "SearchIcon"
        searchIcon.Parent = searchFrame
        searchIcon.BackgroundTransparency = 1
        searchIcon.Position = UDim2.new(0, 10, 0.5, -8)
        searchIcon.Size = UDim2.new(0, 16, 0, 16)
        searchIcon.Image = "rbxassetid://3926305904"
        searchIcon.ImageRectOffset = Vector2.new(964, 324)
        searchIcon.ImageRectSize = Vector2.new(36, 36)
        searchIcon.ImageColor3 = ThemeManager:GetCurrentTheme().TextColor
        
        local clearButton = Instance.new("ImageButton")
        clearButton.Name = "ClearButton"
        clearButton.Parent = searchFrame
        clearButton.BackgroundTransparency = 1
        clearButton.Position = UDim2.new(1, -25, 0.5, -8)
        clearButton.Size = UDim2.new(0, 16, 0, 16)
        clearButton.Image = "rbxassetid://3926305904"
        clearButton.ImageRectOffset = Vector2.new(284, 4)
        clearButton.ImageRectSize = Vector2.new(24, 24)
        clearButton.ImageColor3 = ThemeManager:GetCurrentTheme().TextColor
        clearButton.Visible = false
        
        -- Search functionality
        local function performSearch()
            local searchText = string.lower(searchBox.Text)
            
            for _, tabButton in ipairs(container.Parent:GetChildren()) do
                if tabButton:IsA("TextButton") and tabButton.Name:match("TabButton") then
                    local tabName = string.lower(tabButton.Text)
                    
                    if searchText == "" or string.find(tabName, searchText, 1, true) then
                        tabButton.Visible = true
                        Utility:TweenObject(tabButton, {TextTransparency = 0}, 0.2)
                    else
                        Utility:TweenObject(tabButton, {TextTransparency = 0.5}, 0.2)
                    end
                end
            end
            
            clearButton.Visible = searchText ~= ""
        end
        
        -- Debounced search
        local debouncedSearch = Utility:Debounce(performSearch, 0.3)
        
        searchBox:GetPropertyChangedSignal("Text"):Connect(function()
            debouncedSearch()
        end)
        
        clearButton.MouseButton1Click:Connect(function()
            searchBox.Text = ""
            performSearch()
        end)
        
        -- Theme updates
        local searchThemeUpdater = RunService.Heartbeat:Connect(function()
            searchFrame.BackgroundColor3 = ThemeManager:GetCurrentTheme().ElementColor
            searchBox.TextColor3 = ThemeManager:GetCurrentTheme().TextColor
            searchBox.PlaceholderColor3 = Color3.fromRGB(
                ThemeManager:GetCurrentTheme().TextColor.r * 255 - 40,
                ThemeManager:GetCurrentTheme().TextColor.g * 255 - 40,
                ThemeManager:GetCurrentTheme().TextColor.b * 255 - 40
            )
            searchIcon.ImageColor3 = ThemeManager:GetCurrentTheme().TextColor
            clearButton.ImageColor3 = ThemeManager:GetCurrentTheme().TextColor
        end)
        
        return searchFrame
    end, "CreateSearchBar")
end

-- Main Library Creation
function Nebula:CreateLib(libName, themeList, defaultSize, defaultPosition)
    return ErrorHandler:TryExecute(function()
        libName = libName or "Nebula UI"
        themeList = ThemeManager:ValidateTheme(themeList)
        defaultSize = defaultSize or UDim2.new(0, 525, 0, 318)
        defaultPosition = defaultPosition or UDim2.new(0.336, 0, 0.275, 0)
        
        -- Clean up existing UI
        for _, gui in ipairs(CoreGui:GetChildren()) do
            if gui:IsA("ScreenGui") and gui.Name == libName then
                gui:Destroy()
            end
        end
        
        -- Create main container
        local ScreenGui = Instance.new("ScreenGui")
        ScreenGui.Name = libName
        ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        ScreenGui.ResetOnSpawn = false
        ScreenGui.Parent = CoreGui
        
        local Main = Instance.new("Frame")
        Main.Name = "Main"
        Main.Parent = ScreenGui
        Main.BackgroundColor3 = themeList.Background
        Main.ClipsDescendants = true
        Main.Position = defaultPosition
        Main.Size = defaultSize
        Main.Visible = false
        
        local MainCorner = Instance.new("UICorner")
        MainCorner.CornerRadius = UDim.new(0, 8)
        MainCorner.Parent = Main
        
        local MainStroke = Instance.new("UIStroke")
        MainStroke.Parent = Main
        MainStroke.Color = themeList.SchemeColor
        MainStroke.Thickness = 1
        
        -- Create header
        local MainHeader = Instance.new("Frame")
        MainHeader.Name = "MainHeader"
        MainHeader.Parent = Main
        MainHeader.BackgroundColor3 = themeList.Header
        MainHeader.Size = UDim2.new(1, 0, 0, 35)
        
        local headerCover = Instance.new("UICorner")
        headerCover.CornerRadius = UDim.new(0, 8)
        headerCover.Parent = MainHeader
        
        Nebula:DraggingEnabled(MainHeader, Main)
        
        -- Header content
        local title = Instance.new("TextLabel")
        title.Name = "title"
        title.Parent = MainHeader
        title.BackgroundTransparency = 1
        title.Position = UDim2.new(0, 15, 0, 0)
        title.Size = UDim2.new(0, 200, 1, 0)
        title.Font = Enum.Font.GothamBold
        title.Text = libName
        title.TextColor3 = themeList.TextColor
        title.TextSize = 16
        title.TextXAlignment = Enum.TextXAlignment.Left
        
        local close = Instance.new("ImageButton")
        close.Name = "close"
        close.Parent = MainHeader
        close.BackgroundTransparency = 1
        close.Position = UDim2.new(1, -30, 0.5, -10)
        close.Size = UDim2.new(0, 20, 0, 20)
        close.ZIndex = 2
        close.Image = "rbxassetid://3926305904"
        close.ImageRectOffset = Vector2.new(284, 4)
        close.ImageRectSize = Vector2.new(24, 24)
        close.ImageColor3 = themeList.TextColor
        
        local minimize = Instance.new("ImageButton")
        minimize.Name = "minimize"
        minimize.Parent = MainHeader
        minimize.BackgroundTransparency = 1
        minimize.Position = UDim2.new(1, -60, 0.5, -10)
        minimize.Size = UDim2.new(0, 20, 0, 20)
        minimize.ZIndex = 2
        minimize.Image = "rbxassetid://3926305904"
        minimize.ImageRectOffset = Vector2.new(4, 4)
        minimize.ImageRectSize = Vector2.new(24, 24)
        minimize.ImageColor3 = themeList.TextColor
        
        -- Sidebar
        local MainSide = Instance.new("Frame")
        MainSide.Name = "MainSide"
        MainSide.Parent = Main
        MainSide.BackgroundColor3 = themeList.Header
        MainSide.Position = UDim2.new(0, 0, 0, 35)
        MainSide.Size = UDim2.new(0, 150, 1, -35)
        
        local sideCorner = Instance.new("UICorner")
        sideCorner.CornerRadius = UDim.new(0, 8)
        sideCorner.Parent = MainSide
        
        -- Add search bar
        local searchBar = SearchSystem:CreateSearchBar(MainSide)
        
        local tabFrames = Instance.new("ScrollingFrame")
        tabFrames.Name = "tabFrames"
        tabFrames.Parent = MainSide
        tabFrames.BackgroundTransparency = 1
        tabFrames.Position = UDim2.new(0, 5, 0, 45)
        tabFrames.Size = UDim2.new(1, -10, 1, -50)
        tabFrames.ScrollBarThickness = 3
        tabFrames.ScrollBarImageColor3 = themeList.SchemeColor
        tabFrames.CanvasSize = UDim2.new(0, 0, 0, 0)
        
        local tabListing = Instance.new("UIListLayout")
        tabListing.Name = "tabListing"
        tabListing.Parent = tabFrames
        tabListing.SortOrder = Enum.SortOrder.LayoutOrder
        tabListing.Padding = UDim.new(0, 5)
        
        -- Pages container
        local pages = Instance.new("Frame")
        pages.Name = "pages"
        pages.Parent = Main
        pages.BackgroundTransparency = 1
        pages.Position = UDim2.new(0, 155, 0, 40)
        pages.Size = UDim2.new(1, -160, 1, -45)
        
        local Pages = Instance.new("Folder")
        Pages.Name = "Pages"
        Pages.Parent = pages
        
        -- Store instance
        local libInstance = {
            ScreenGui = ScreenGui,
            Main = Main,
            MainHeader = MainHeader,
            MainSide = MainSide,
            tabFrames = tabFrames,
            Pages = Pages,
            Theme = themeList
        }
        
        table.insert(NebulaInstances, libInstance)
        
        -- Theme updater
        local ThemeUpdater = RunService.Heartbeat:Connect(function()
            Main.BackgroundColor3 = themeList.Background
            MainHeader.BackgroundColor3 = themeList.Header
            MainSide.BackgroundColor3 = themeList.Header
            title.TextColor3 = themeList.TextColor
            close.ImageColor3 = themeList.TextColor
            minimize.ImageColor3 = themeList.TextColor
            MainStroke.Color = themeList.SchemeColor
            tabFrames.ScrollBarImageColor3 = themeList.SchemeColor
        end)
        
        -- Close button functionality
        close.MouseButton1Click:Connect(function()
            Utility:TweenObject(close, {ImageTransparency = 1}, 0.1)
            wait(0.1)
            Utility:TweenObject(Main, {
                Size = UDim2.new(0, 0, 0, 0),
                Position = UDim2.new(
                    0, Main.AbsolutePosition.X + (Main.AbsoluteSize.X / 2),
                    0, Main.AbsolutePosition.Y + (Main.AbsoluteSize.Y / 2)
                )
            }, 0.2)
            wait(0.2)
            ScreenGui:Destroy()
            Utility:CancelAllTweens()
            ThemeUpdater:Disconnect()
        end)
        
        -- Minimize functionality
        local isMinimized = false
        minimize.MouseButton1Click:Connect(function()
            if isMinimized then
                -- Restore
                Utility:TweenObject(Main, {
                    Size = defaultSize,
                    Position = defaultPosition
                }, 0.3)
                isMinimized = false
            else
                -- Minimize
                Utility:TweenObject(Main, {
                    Size = UDim2.new(0, 200, 0, 35),
                    Position = UDim2.new(0, Main.AbsolutePosition.X, 0, Main.AbsolutePosition.Y)
                }, 0.3)
                isMinimized = true
            end
        end)
        
        -- UI visibility toggle
        function libInstance:ToggleUI()
            if not Main.Visible then
                Main.Visible = true
                Utility:TweenObject(Main, {
                    Size = defaultSize,
                    Position = defaultPosition
                }, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
            else
                Utility:TweenObject(Main, {
                    Size = UDim2.new(0, 0, 0, 0),
                    Position = UDim2.new(
                        0, Main.AbsolutePosition.X + (Main.AbsoluteSize.X / 2),
                        0, Main.AbsolutePosition.Y + (Main.AbsoluteSize.Y / 2)
                    )
                }, 0.2)
                wait(0.2)
                Main.Visible = false
            end
        end
        
        -- Bind toggle to key
        UserInputService.InputBegan:Connect(function(input)
            if input.KeyCode == Enum.KeyCode.RightControl then
                libInstance:ToggleUI()
            end
        end)
        
        -- Tab management system
        local Tabs = {}
        local ActiveTab = nil
        
        function Tabs:NewTab(tabName, tabIcon)
            ErrorHandler:TryExecute(function()
                tabName = tabName or "Tab"
                
                local tabButton = Instance.new("TextButton")
                local UICorner = Instance.new("UICorner")
                local page = Instance.new("ScrollingFrame")
                local pageListing = Instance.new("UIListLayout")
                local pagePadding = Instance.new("UIPadding")
                
                -- Create tab button
                tabButton.Name = tabName .. "TabButton"
                tabButton.Parent = tabFrames
                tabButton.BackgroundColor3 = themeList.SchemeColor
                tabButton.Size = UDim2.new(1, 0, 0, 35)
                tabButton.AutoButtonColor = false
                tabButton.Font = Enum.Font.Gotham
                tabButton.Text = tabIcon and tabIcon .. " " .. tabName or tabName
                tabButton.TextColor3 = themeList.TextColor
                tabButton.TextSize = 14
                tabButton.BackgroundTransparency = 1
                
                UICorner.CornerRadius = UDim.new(0, 6)
                UICorner.Parent = tabButton
                
                -- Create page
                page.Name = tabName .. "Page"
                page.Parent = Pages
                page.Active = true
                page.BackgroundColor3 = themeList.Background
                page.BackgroundTransparency = 1
                page.BorderSizePixel = 0
                page.Size = UDim2.new(1, 0, 1, 0)
                page.ScrollBarThickness = 5
                page.ScrollBarImageColor3 = themeList.SchemeColor
                page.Visible = false
                page.CanvasSize = UDim2.new(0, 0, 0, 0)
                
                pagePadding.Parent = page
                pagePadding.PaddingLeft = UDim.new(0, 5)
                pagePadding.PaddingRight = UDim.new(0, 5)
                pagePadding.PaddingTop = UDim.new(0, 5)
                pagePadding.PaddingBottom = UDim.new(0, 5)
                
                pageListing.Name = "pageListing"
                pageListing.Parent = page
                pageListing.SortOrder = Enum.SortOrder.LayoutOrder
                pageListing.Padding = UDim.new(0, CONFIG.ELEMENT_SPACING)
                
                -- Dynamic canvas size update
                local function UpdatePageSize()
                    local contentSize = pageListing.AbsoluteContentSize
                    page.CanvasSize = UDim2.new(0, 0, 0, math.max(contentSize.Y, page.AbsoluteSize.Y))
                end
                
                pageListing:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(UpdatePageSize)
                UpdatePageSize()
                
                -- Tab selection logic
                tabButton.MouseButton1Click:Connect(function()
                    if ActiveTab == tabButton then return end
                    
                    -- Deselect previous tab
                    if ActiveTab then
                        Utility:TweenObject(ActiveTab, {BackgroundTransparency = 1}, 0.2)
                        ActiveTab.Parent.Page.Visible = false
                    end
                    
                    -- Select new tab
                    ActiveTab = tabButton
                    Utility:TweenObject(tabButton, {BackgroundTransparency = 0}, 0.2)
                    page.Visible = true
                    
                    -- Add ripple effect
                    RippleManager:CreateRipple(tabButton, themeList.SchemeColor, 1.2)
                end)
                
                -- Set as first tab if none active
                if not ActiveTab then
                    ActiveTab = tabButton
                    tabButton.BackgroundTransparency = 0
                    page.Visible = true
                end
                
                -- Update tab frames canvas size
                local function UpdateTabFramesSize()
                    local tabContentSize = tabListing.AbsoluteContentSize
                    tabFrames.CanvasSize = UDim2.new(0, 0, 0, tabContentSize.Y)
                end
                tabListing:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(UpdateTabFramesSize)
                UpdateTabFramesSize()
                
                -- Theme updates for this tab
                local tabThemeUpdater = RunService.Heartbeat:Connect(function()
                    if tabButton == ActiveTab then
                        tabButton.BackgroundColor3 = themeList.SchemeColor
                        tabButton.TextColor3 = themeList.TextColor
                    else
                        tabButton.BackgroundColor3 = themeList.ElementColor
                        tabButton.TextColor3 = Color3.fromRGB(
                            themeList.TextColor.r * 255 - 40,
                            themeList.TextColor.g * 255 - 40,
                            themeList.TextColor.b * 255 - 40
                        )
                    end
                    page.ScrollBarImageColor3 = themeList.SchemeColor
                end)
                
                -- Section creation system
                local Sections = {}
                
                function Sections:NewSection(secName, hidden, collapsible)
                    ErrorHandler:TryExecute(function()
                        secName = secName or "Section"
                        hidden = hidden or false
                        collapsible = collapsible or true
                        
                        local sectionFrame = Instance.new("Frame")
                        local sectionListLayout = Instance.new("UIListLayout")
                        local sectionHead = Instance.new("Frame")
                        local sectionName = Instance.new("TextLabel")
                        local collapseButton = Instance.new("ImageButton")
                        local sectionInners = Instance.new("Frame")
                        local sectionElListing = Instance.new("UIListLayout")
                        
                        -- Section frame
                        sectionFrame.Name = "sectionFrame"
                        sectionFrame.Parent = page
                        sectionFrame.BackgroundColor3 = themeList.Background
                        sectionFrame.BackgroundTransparency = 1
                        sectionFrame.BorderSizePixel = 0
                        sectionFrame.Size = UDim2.new(1, 0, 0, 0)
                        
                        sectionListLayout.Name = "sectionListLayout"
                        sectionListLayout.Parent = sectionFrame
                        sectionListLayout.SortOrder = Enum.SortOrder.LayoutOrder
                        sectionListLayout.Padding = UDim.new(0, 8)
                        
                        -- Section header
                        sectionHead.Name = "sectionHead"
                        sectionHead.Parent = sectionFrame
                        sectionHead.BackgroundColor3 = themeList.SchemeColor
                        sectionHead.Size = UDim2.new(1, 0, 0, 35)
                        sectionHead.Visible = not hidden
                        
                        local sHeadCorner = Instance.new("UICorner")
                        sHeadCorner.CornerRadius = UDim.new(0, 6)
                        sHeadCorner.Parent = sectionHead
                        
                        sectionName.Name = "sectionName"
                        sectionName.Parent = sectionHead
                        sectionName.BackgroundTransparency = 1
                        sectionName.Position = UDim2.new(0, 15, 0, 0)
                        sectionName.Size = UDim2.new(1, -50, 1, 0)
                        sectionName.Font = Enum.Font.GothamSemibold
                        sectionName.Text = secName
                        sectionName.TextColor3 = themeList.TextColor
                        sectionName.TextSize = 14
                        sectionName.TextXAlignment = Enum.TextXAlignment.Left
                        
                        -- Collapse button
                        if collapsible then
                            collapseButton.Name = "collapseButton"
                            collapseButton.Parent = sectionHead
                            collapseButton.BackgroundTransparency = 1
                            collapseButton.Position = UDim2.new(1, -35, 0.5, -10)
                            collapseButton.Size = UDim2.new(0, 20, 0, 20)
                            collapseButton.Image = "rbxassetid://3926305904"
                            collapseButton.ImageRectOffset = Vector2.new(964, 324)
                            collapseButton.ImageRectSize = Vector2.new(36, 36)
                            collapseButton.ImageColor3 = themeList.TextColor
                            
                            local isCollapsed = false
                            collapseButton.MouseButton1Click:Connect(function()
                                isCollapsed = not isCollapsed
                                sectionInners.Visible = not isCollapsed
                                
                                Utility:TweenObject(collapseButton, {
                                    Rotation = isCollapsed and 180 or 0
                                }, 0.2)
                                
                                UpdateSectionSize()
                            end)
                        end
                        
                        -- Section content
                        sectionInners.Name = "sectionInners"
                        sectionInners.Parent = sectionFrame
                        sectionInners.BackgroundTransparency = 1
                        sectionInners.Position = UDim2.new(0, 0, hidden and 0 or 1, hidden and 0 or 5)
                        sectionInners.Size = UDim2.new(1, 0, 0, 0)
                        
                        sectionElListing.Name = "sectionElListing"
                        sectionElListing.Parent = sectionInners
                        sectionElListing.SortOrder = Enum.SortOrder.LayoutOrder
                        sectionElListing.Padding = UDim.new(0, CONFIG.ELEMENT_SPACING)
                        
                        -- Dynamic sizing
                        local function UpdateSectionSize()
                            local innerSize = sectionElListing.AbsoluteContentSize
                            sectionInners.Size = UDim2.new(1, 0, 0, innerSize.Y)
                            
                            local frameSize = sectionListLayout.AbsoluteContentSize
                            sectionFrame.Size = UDim2.new(1, 0, 0, frameSize.Y)
                            
                            UpdatePageSize()
                        end
                        
                        sectionElListing:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(UpdateSectionSize)
                        sectionInners.ChildAdded:Connect(UpdateSectionSize)
                        sectionInners.ChildRemoved:Connect(UpdateSectionSize)
                        UpdateSectionSize()
                        
                        -- Theme updates
                        local sectionThemeUpdater = RunService.Heartbeat:Connect(function()
                            sectionFrame.BackgroundColor3 = themeList.Background
                            sectionHead.BackgroundColor3 = themeList.SchemeColor
                            sectionName.TextColor3 = themeList.TextColor
                            if collapseButton then
                                collapseButton.ImageColor3 = themeList.TextColor
                            end
                        end)
                        
                        -- Element creation system
                        local Elements = {}
                        
                        -- Button element
                        function Elements:NewButton(bname, tipInfo, callback, buttonColor)
                            return ErrorHandler:TryExecute(function()
                                bname = bname or "Button"
                                tipInfo = tipInfo or "Click this button"
                                callback = callback or function() end
                                buttonColor = buttonColor or themeList.SchemeColor
                                
                                local buttonElement = Instance.new("TextButton")
                                local UICorner = Instance.new("UICorner")
                                local btnInfo = Instance.new("TextLabel")
                                local touch = Instance.new("ImageLabel")
                                local buttonStroke = Instance.new("UIStroke")
                                
                                buttonElement.Name = bname
                                buttonElement.Parent = sectionInners
                                buttonElement.BackgroundColor3 = themeList.ElementColor
                                buttonElement.ClipsDescendants = true
                                buttonElement.Size = UDim2.new(1, 0, 0, 40)
                                buttonElement.AutoButtonColor = false
                                buttonElement.Text = ""
                                
                                UICorner.CornerRadius = UDim.new(0, 6)
                                UICorner.Parent = buttonElement
                                
                                buttonStroke.Parent = buttonElement
                                buttonStroke.Color = buttonColor
                                buttonStroke.Thickness = 1
                                
                                touch.Name = "touch"
                                touch.Parent = buttonElement
                                touch.BackgroundTransparency = 1
                                touch.Position = UDim2.new(0, 15, 0.5, -10)
                                touch.Size = UDim2.new(0, 20, 0, 20)
                                touch.Image = "rbxassetid://3926305904"
                                touch.ImageColor3 = buttonColor
                                touch.ImageRectOffset = Vector2.new(84, 204)
                                touch.ImageRectSize = Vector2.new(36, 36)
                                
                                btnInfo.Name = "btnInfo"
                                btnInfo.Parent = buttonElement
                                btnInfo.BackgroundTransparency = 1
                                btnInfo.Position = UDim2.new(0, 45, 0, 0)
                                btnInfo.Size = UDim2.new(1, -50, 1, 0)
                                btnInfo.Font = Enum.Font.GothamSemibold
                                btnInfo.Text = bname
                                btnInfo.TextColor3 = themeList.TextColor
                                btnInfo.TextSize = 14
                                btnInfo.TextXAlignment = Enum.TextXAlignment.Left
                                
                                -- Hover effects
                                local hovering = false
                                buttonElement.MouseEnter:Connect(function()
                                    hovering = true
                                    Utility:TweenObject(buttonElement, {
                                        BackgroundColor3 = Color3.fromRGB(
                                            themeList.ElementColor.r * 255 + 15,
                                            themeList.ElementColor.g * 255 + 15,
                                            themeList.ElementColor.b * 255 + 15
                                        )
                                    }, 0.2)
                                    Utility:TweenObject(buttonStroke, {Thickness = 2}, 0.2)
                                end)
                                
                                buttonElement.MouseLeave:Connect(function()
                                    hovering = false
                                    Utility:TweenObject(buttonElement, {
                                        BackgroundColor3 = themeList.ElementColor
                                    }, 0.2)
                                    Utility:TweenObject(buttonStroke, {Thickness = 1}, 0.2)
                                end)
                                
                                -- Click handler with ripple
                                buttonElement.MouseButton1Click:Connect(function()
                                    RippleManager:CreateRipple(buttonElement, buttonColor, 1.5)
                                    callback()
                                end)
                                
                                -- Theme updates
                                local buttonThemeUpdater = RunService.Heartbeat:Connect(function()
                                    if not hovering then
                                        buttonElement.BackgroundColor3 = themeList.ElementColor
                                    end
                                    btnInfo.TextColor3 = themeList.TextColor
                                    touch.ImageColor3 = buttonColor
                                    buttonStroke.Color = buttonColor
                                end)
                                
                                UpdateSectionSize()
                                
                                local ButtonFunctions = {}
                                
                                function ButtonFunctions:Update(newText, newColor)
                                    btnInfo.Text = newText or bname
                                    if newColor then
                                        buttonColor = newColor
                                    end
                                end
                                
                                function ButtonFunctions:SetCallback(newCallback)
                                    callback = newCallback or callback
                                end
                                
                                function ButtonFunctions:SetEnabled(enabled)
                                    buttonElement.Visible = enabled
                                    UpdateSectionSize()
                                end
                                
                                return ButtonFunctions
                            end, "NewButton")
                        end
                        
                        -- Toggle element
                        function Elements:NewToggle(tname, tipInfo, defaultState, callback)
                            return ErrorHandler:TryExecute(function()
                                tname = tname or "Toggle"
                                tipInfo = tipInfo or "Toggle this setting"
                                defaultState = defaultState or false
                                callback = callback or function() end
                                
                                local toggleElement = Instance.new("TextButton")
                                local UICorner = Instance.new("UICorner")
                                local toggleFrame = Instance.new("Frame")
                                local toggleKnob = Instance.new("Frame")
                                local togName = Instance.new("TextLabel")
                                local toggleStroke = Instance.new("UIStroke")
                                
                                local isToggled = defaultState
                                
                                toggleElement.Name = tname
                                toggleElement.Parent = sectionInners
                                toggleElement.BackgroundColor3 = themeList.ElementColor
                                toggleElement.ClipsDescendants = true
                                toggleElement.Size = UDim2.new(1, 0, 0, 40)
                                toggleElement.AutoButtonColor = false
                                toggleElement.Text = ""
                                
                                UICorner.CornerRadius = UDim.new(0, 6)
                                UICorner.Parent = toggleElement
                                
                                toggleStroke.Parent = toggleElement
                                toggleStroke.Color = themeList.SchemeColor
                                toggleStroke.Thickness = 1
                                
                                toggleFrame.Name = "toggleFrame"
                                toggleFrame.Parent = toggleElement
                                toggleFrame.BackgroundColor3 = isToggled and themeList.SuccessColor or themeList.ElementColor
                                toggleFrame.Position = UDim2.new(1, -55, 0.5, -10)
                                toggleFrame.Size = UDim2.new(0, 40, 0, 20)
                                
                                local toggleFrameCorner = Instance.new("UICorner")
                                toggleFrameCorner.CornerRadius = UDim.new(1, 0)
                                toggleFrameCorner.Parent = toggleFrame
                                
                                toggleKnob.Name = "toggleKnob"
                                toggleKnob.Parent = toggleFrame
                                toggleKnob.BackgroundColor3 = themeList.TextColor
                                toggleKnob.Position = isToggled and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
                                toggleKnob.Size = UDim2.new(0, 16, 0, 16)
                                
                                local toggleKnobCorner = Instance.new("UICorner")
                                toggleKnobCorner.CornerRadius = UDim.new(1, 0)
                                toggleKnobCorner.Parent = toggleKnob
                                
                                togName.Name = "togName"
                                togName.Parent = toggleElement
                                togName.BackgroundTransparency = 1
                                togName.Position = UDim2.new(0, 15, 0, 0)
                                togName.Size = UDim2.new(1, -70, 1, 0)
                                togName.Font = Enum.Font.GothamSemibold
                                togName.Text = tname
                                togName.TextColor3 = themeList.TextColor
                                togName.TextSize = 14
                                togName.TextXAlignment = Enum.TextXAlignment.Left
                                
                                local function updateToggle()
                                    Utility:TweenObject(toggleFrame, {
                                        BackgroundColor3 = isToggled and themeList.SuccessColor or themeList.ElementColor
                                    }, 0.2)
                                    
                                    Utility:TweenObject(toggleKnob, {
                                        Position = isToggled and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
                                    }, 0.2)
                                    
                                    callback(isToggled)
                                end
                                
                                -- Hover effects
                                local hovering = false
                                toggleElement.MouseEnter:Connect(function()
                                    hovering = true
                                    Utility:TweenObject(toggleElement, {
                                        BackgroundColor3 = Color3.fromRGB(
                                            themeList.ElementColor.r * 255 + 15,
                                            themeList.ElementColor.g * 255 + 15,
                                            themeList.ElementColor.b * 255 + 15
                                        )
                                    }, 0.2)
                                end)
                                
                                toggleElement.MouseLeave:Connect(function()
                                    hovering = false
                                    Utility:TweenObject(toggleElement, {
                                        BackgroundColor3 = themeList.ElementColor
                                    }, 0.2)
                                end)
                                
                                -- Click handler
                                toggleElement.MouseButton1Click:Connect(function()
                                    isToggled = not isToggled
                                    RippleManager:CreateRipple(toggleElement, themeList.SchemeColor, 1.2)
                                    updateToggle()
                                end)
                                
                                -- Initialize
                                updateToggle()
                                
                                -- Theme updates
                                local toggleThemeUpdater = RunService.Heartbeat:Connect(function()
                                    if not hovering then
                                        toggleElement.BackgroundColor3 = themeList.ElementColor
                                    end
                                    togName.TextColor3 = themeList.TextColor
                                    toggleStroke.Color = themeList.SchemeColor
                                end)
                                
                                UpdateSectionSize()
                                
                                local ToggleFunctions = {}
                                
                                function ToggleFunctions:Update(newText, newState)
                                    if newText then
                                        togName.Text = newText
                                    end
                                    if newState ~= nil then
                                        isToggled = newState
                                        updateToggle()
                                    end
                                end
                                
                                function ToggleFunctions:GetState()
                                    return isToggled
                                end
                                
                                function ToggleFunctions:SetCallback(newCallback)
                                    callback = newCallback or callback
                                end
                                
                                return ToggleFunctions
                            end, "NewToggle")
                        end
                        
                        -- Label element
                        function Elements:NewLabel(labelText, textColor)
                            return ErrorHandler:TryExecute(function()
                                labelText = labelText or "Label"
                                textColor = textColor or themeList.TextColor
                                
                                local labelElement = Instance.new("TextLabel")
                                local UICorner = Instance.new("UICorner")
                                
                                labelElement.Name = "label"
                                labelElement.Parent = sectionInners
                                labelElement.BackgroundColor3 = themeList.SchemeColor
                                labelElement.BackgroundTransparency = 0.8
                                labelElement.Size = UDim2.new(1, 0, 0, 30)
                                labelElement.Font = Enum.Font.Gotham
                                labelElement.Text = "  " .. labelText
                                labelElement.TextColor3 = textColor
                                labelElement.TextSize = 14
                                labelElement.TextXAlignment = Enum.TextXAlignment.Left
                                
                                UICorner.CornerRadius = UDim.new(0, 6)
                                UICorner.Parent = labelElement
                                
                                UpdateSectionSize()
                                
                                local LabelFunctions = {}
                                
                                function LabelFunctions:Update(newText, newColor)
                                    labelElement.Text = "  " .. (newText or labelText)
                                    if newColor then
                                        labelElement.TextColor3 = newColor
                                    end
                                end
                                
                                return LabelFunctions
                            end, "NewLabel")
                        end
                        
                        -- Slider element
                        function Elements:NewSlider(sname, tipInfo, minValue, maxValue, defaultValue, callback, valueType)
                            return ErrorHandler:TryExecute(function()
                                sname = sname or "Slider"
                                tipInfo = tipInfo or "Adjust this value"
                                minValue = minValue or 0
                                maxValue = maxValue or 100
                                defaultValue = defaultValue or minValue
                                callback = callback or function() end
                                valueType = valueType or "Number" -- "Number" or "Integer"
                                
                                local sliderElement = Instance.new("Frame")
                                local UICorner = Instance.new("UICorner")
                                local sliderName = Instance.new("TextLabel")
                                local sliderValue = Instance.new("TextLabel")
                                local sliderTrack = Instance.new("Frame")
                                local sliderFill = Instance.new("Frame")
                                local sliderThumb = Instance.new("Frame")
                                local sliderStroke = Instance.new("UIStroke")
                                
                                local currentValue = math.clamp(defaultValue, minValue, maxValue)
                                
                                sliderElement.Name = sname
                                sliderElement.Parent = sectionInners
                                sliderElement.BackgroundColor3 = themeList.ElementColor
                                sliderElement.Size = UDim2.new(1, 0, 0, 60)
                                
                                UICorner.CornerRadius = UDim.new(0, 6)
                                UICorner.Parent = sliderElement
                                
                                sliderStroke.Parent = sliderElement
                                sliderStroke.Color = themeList.SchemeColor
                                sliderStroke.Thickness = 1
                                
                                sliderName.Name = "sliderName"
                                sliderName.Parent = sliderElement
                                sliderName.BackgroundTransparency = 1
                                sliderName.Position = UDim2.new(0, 15, 0, 8)
                                sliderName.Size = UDim2.new(0.5, -20, 0, 20)
                                sliderName.Font = Enum.Font.GothamSemibold
                                sliderName.Text = sname
                                sliderName.TextColor3 = themeList.TextColor
                                sliderName.TextSize = 14
                                sliderName.TextXAlignment = Enum.TextXAlignment.Left
                                
                                sliderValue.Name = "sliderValue"
                                sliderValue.Parent = sliderElement
                                sliderValue.BackgroundTransparency = 1
                                sliderValue.Position = UDim2.new(0.5, 0, 0, 8)
                                sliderValue.Size = UDim2.new(0.5, -15, 0, 20)
                                sliderValue.Font = Enum.Font.Gotham
                                sliderValue.Text = tostring(currentValue)
                                sliderValue.TextColor3 = themeList.TextColor
                                sliderValue.TextSize = 14
                                sliderValue.TextXAlignment = Enum.TextXAlignment.Right
                                
                                sliderTrack.Name = "sliderTrack"
                                sliderTrack.Parent = sliderElement
                                sliderTrack.BackgroundColor3 = themeList.Header
                                sliderTrack.Position = UDim2.new(0, 15, 0, 35)
                                sliderTrack.Size = UDim2.new(1, -30, 0, 6)
                                
                                local trackCorner = Instance.new("UICorner")
                                trackCorner.CornerRadius = UDim.new(1, 0)
                                trackCorner.Parent = sliderTrack
                                
                                sliderFill.Name = "sliderFill"
                                sliderFill.Parent = sliderTrack
                                sliderFill.BackgroundColor3 = themeList.SchemeColor
                                sliderFill.Size = UDim2.new((currentValue - minValue) / (maxValue - minValue), 0, 1, 0)
                                
                                local fillCorner = Instance.new("UICorner")
                                fillCorner.CornerRadius = UDim.new(1, 0)
                                fillCorner.Parent = sliderFill
                                
                                sliderThumb.Name = "sliderThumb"
                                sliderThumb.Parent = sliderTrack
                                sliderThumb.BackgroundColor3 = themeList.TextColor
                                sliderThumb.Position = UDim2.new((currentValue - minValue) / (maxValue - minValue), -8, 0.5, -8)
                                sliderThumb.Size = UDim2.new(0, 16, 0, 16)
                                sliderThumb.ZIndex = 2
                                
                                local thumbCorner = Instance.new("UICorner")
                                thumbCorner.CornerRadius = UDim.new(1, 0)
                                thumbCorner.Parent = sliderThumb
                                
                                local thumbStroke = Instance.new("UIStroke")
                                thumbStroke.Parent = sliderThumb
                                thumbStroke.Color = themeList.SchemeColor
                                thumbStroke.Thickness = 2
                                
                                local dragging = false
                                
                                local function updateSlider(value)
                                    value = math.clamp(value, minValue, maxValue)
                                    if valueType == "Integer" then
                                        value = math.floor(value)
                                    end
                                    
                                    currentValue = value
                                    local fillWidth = (value - minValue) / (maxValue - minValue)
                                    
                                    Utility:TweenObject(sliderFill, {Size = UDim2.new(fillWidth, 0, 1, 0)}, 0.1)
                                    Utility:TweenObject(sliderThumb, {Position = UDim2.new(fillWidth, -8, 0.5, -8)}, 0.1)
                                    
                                    sliderValue.Text = tostring(value)
                                    callback(value)
                                end
                                
                                local function getValueFromPosition(xPosition)
                                    local trackAbsolute = sliderTrack.AbsolutePosition
                                    local trackSize = sliderTrack.AbsoluteSize
                                    local relativeX = math.clamp((xPosition - trackAbsolute.X) / trackSize.X, 0, 1)
                                    return minValue + (relativeX * (maxValue - minValue))
                                end
                                
                                -- Mouse interactions
                                sliderThumb.InputBegan:Connect(function(input)
                                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                                        dragging = true
                                        RippleManager:CreateRipple(sliderThumb, themeList.SchemeColor, 1.5)
                                    end
                                end)
                                
                                sliderTrack.InputBegan:Connect(function(input)
                                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                                        dragging = true
                                        local value = getValueFromPosition(input.Position.X)
                                        updateSlider(value)
                                        RippleManager:CreateRipple(sliderTrack, themeList.SchemeColor, 1.5)
                                    end
                                end)
                                
                                UserInputService.InputChanged:Connect(function(input)
                                    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                                        local value = getValueFromPosition(input.Position.X)
                                        updateSlider(value)
                                    end
                                end)
                                
                                UserInputService.InputEnded:Connect(function(input)
                                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                                        dragging = false
                                    end
                                end)
                                
                                -- Theme updates
                                local sliderThemeUpdater = RunService.Heartbeat:Connect(function()
                                    sliderElement.BackgroundColor3 = themeList.ElementColor
                                    sliderName.TextColor3 = themeList.TextColor
                                    sliderValue.TextColor3 = themeList.TextColor
                                    sliderStroke.Color = themeList.SchemeColor
                                    sliderTrack.BackgroundColor3 = themeList.Header
                                    sliderFill.BackgroundColor3 = themeList.SchemeColor
                                    sliderThumb.BackgroundColor3 = themeList.TextColor
                                    thumbStroke.Color = themeList.SchemeColor
                                end)
                                
                                UpdateSectionSize()
                                
                                local SliderFunctions = {}
                                
                                function SliderFunctions:Update(newText, newMin, newMax, newValue)
                                    if newText then
                                        sliderName.Text = newText
                                    end
                                    if newMin then
                                        minValue = newMin
                                    end
                                    if newMax then
                                        maxValue = newMax
                                    end
                                    if newValue then
                                        updateSlider(newValue)
                                    end
                                end
                                
                                function SliderFunctions:GetValue()
                                    return currentValue
                                end
                                
                                function SliderFunctions:SetCallback(newCallback)
                                    callback = newCallback or callback
                                end
                                
                                return SliderFunctions
                            end, "NewSlider")
                        end
                        
                        -- Dropdown element
                        function Elements:NewDropdown(dname, tipInfo, options, defaultOption, callback, multiSelect)
                            return ErrorHandler:TryExecute(function()
                                dname = dname or "Dropdown"
                                tipInfo = tipInfo or "Select an option"
                                options = options or {"Option 1", "Option 2", "Option 3"}
                                defaultOption = defaultOption or options[1]
                                callback = callback or function() end
                                multiSelect = multiSelect or false
                                
                                local dropdownElement = Instance.new("TextButton")
                                local UICorner = Instance.new("UICorner")
                                local dropdownName = Instance.new("TextLabel")
                                local dropdownValue = Instance.new("TextLabel")
                                local dropdownArrow = Instance.new("ImageLabel")
                                local dropdownStroke = Instance.new("UIStroke")
                                
                                local dropdownFrame = Instance.new("Frame")
                                local dropdownScroller = Instance.new("ScrollingFrame")
                                local dropdownListing = Instance.new("UIListLayout")
                                
                                local isOpen = false
                                local selectedOptions = multiSelect and {} or {defaultOption}
                                
                                dropdownElement.Name = dname
                                dropdownElement.Parent = sectionInners
                                dropdownElement.BackgroundColor3 = themeList.ElementColor
                                dropdownElement.ClipsDescendants = true
                                dropdownElement.Size = UDim2.new(1, 0, 0, 40)
                                dropdownElement.AutoButtonColor = false
                                dropdownElement.Text = ""
                                
                                UICorner.CornerRadius = UDim.new(0, 6)
                                UICorner.Parent = dropdownElement
                                
                                dropdownStroke.Parent = dropdownElement
                                dropdownStroke.Color = themeList.SchemeColor
                                dropdownStroke.Thickness = 1
                                
                                dropdownName.Name = "dropdownName"
                                dropdownName.Parent = dropdownElement
                                dropdownName.BackgroundTransparency = 1
                                dropdownName.Position = UDim2.new(0, 15, 0, 0)
                                dropdownName.Size = UDim2.new(0.6, -20, 1, 0)
                                dropdownName.Font = Enum.Font.GothamSemibold
                                dropdownName.Text = dname
                                dropdownName.TextColor3 = themeList.TextColor
                                dropdownName.TextSize = 14
                                dropdownName.TextXAlignment = Enum.TextXAlignment.Left
                                
                                dropdownValue.Name = "dropdownValue"
                                dropdownValue.Parent = dropdownElement
                                dropdownValue.BackgroundTransparency = 1
                                dropdownValue.Position = UDim2.new(0.6, 0, 0, 0)
                                dropdownValue.Size = UDim2.new(0.4, -40, 1, 0)
                                dropdownValue.Font = Enum.Font.Gotham
                                dropdownValue.Text = multiSelect and "Multiple" or tostring(defaultOption)
                                dropdownValue.TextColor3 = themeList.TextColor
                                dropdownValue.TextSize = 14
                                dropdownValue.TextXAlignment = Enum.TextXAlignment.Right
                                
                                dropdownArrow.Name = "dropdownArrow"
                                dropdownArrow.Parent = dropdownElement
                                dropdownArrow.BackgroundTransparency = 1
                                dropdownArrow.Position = UDim2.new(1, -25, 0.5, -8)
                                dropdownArrow.Size = UDim2.new(0, 16, 0, 16)
                                dropdownArrow.Image = "rbxassetid://3926305904"
                                dropdownArrow.ImageRectOffset = Vector2.new(964, 324)
                                dropdownArrow.ImageRectSize = Vector2.new(36, 36)
                                dropdownArrow.ImageColor3 = themeList.TextColor
                                
                                -- Dropdown frame (initially hidden)
                                dropdownFrame.Name = "dropdownFrame"
                                dropdownFrame.Parent = dropdownElement
                                dropdownFrame.BackgroundColor3 = themeList.ElementColor
                                dropdownFrame.BorderSizePixel = 0
                                dropdownFrame.Position = UDim2.new(0, 0, 1, 5)
                                dropdownFrame.Size = UDim2.new(1, 0, 0, 0)
                                dropdownFrame.ClipsDescendants = true
                                dropdownFrame.Visible = false
                                
                                local dropdownFrameCorner = Instance.new("UICorner")
                                dropdownFrameCorner.CornerRadius = UDim.new(0, 6)
                                dropdownFrameCorner.Parent = dropdownFrame
                                
                                local dropdownFrameStroke = Instance.new("UIStroke")
                                dropdownFrameStroke.Parent = dropdownFrame
                                dropdownFrameStroke.Color = themeList.SchemeColor
                                dropdownFrameStroke.Thickness = 1
                                
                                dropdownScroller.Name = "dropdownScroller"
                                dropdownScroller.Parent = dropdownFrame
                                dropdownScroller.BackgroundTransparency = 1
                                dropdownScroller.Size = UDim2.new(1, 0, 1, 0)
                                dropdownScroller.ScrollBarThickness = 3
                                dropdownScroller.ScrollBarImageColor3 = themeList.SchemeColor
                                dropdownScroller.CanvasSize = UDim2.new(0, 0, 0, 0)
                                
                                dropdownListing.Name = "dropdownListing"
                                dropdownListing.Parent = dropdownScroller
                                dropdownListing.SortOrder = Enum.SortOrder.LayoutOrder
                                dropdownListing.Padding = UDim.new(0, 2)
                                
                                local function updateDropdownSize()
                                    local contentSize = dropdownListing.AbsoluteContentSize
                                    dropdownScroller.CanvasSize = UDim2.new(0, 0, 0, contentSize.Y)
                                    local maxHeight = math.min(contentSize.Y, 150)
                                    dropdownFrame.Size = UDim2.new(1, 0, 0, maxHeight)
                                end
                                
                                local function createOption(option)
                                    local optionButton = Instance.new("TextButton")
                                    local optionCorner = Instance.new("UICorner")
                                    
                                    optionButton.Name = option
                                    optionButton.Parent = dropdownScroller
                                    optionButton.BackgroundColor3 = themeList.Header
                                    optionButton.Size = UDim2.new(1, -10, 0, 30)
                                    optionButton.AutoButtonColor = false
                                    optionButton.Font = Enum.Font.Gotham
                                    optionButton.Text = tostring(option)
                                    optionButton.TextColor3 = themeList.TextColor
                                    optionButton.TextSize = 14
                                    
                                    optionCorner.CornerRadius = UDim.new(0, 4)
                                    optionCorner.Parent = optionButton
                                    
                                    local isSelected = multiSelect and table.find(selectedOptions, option) or option == selectedOptions[1]
                                    
                                    if isSelected then
                                        optionButton.BackgroundColor3 = themeList.SchemeColor
                                    end
                                    
                                    optionButton.MouseButton1Click:Connect(function()
                                        if multiSelect then
                                            local index = table.find(selectedOptions, option)
                                            if index then
                                                table.remove(selectedOptions, index)
                                                optionButton.BackgroundColor3 = themeList.Header
                                            else
                                                table.insert(selectedOptions, option)
                                                optionButton.BackgroundColor3 = themeList.SchemeColor
                                            end
                                            
                                            if #selectedOptions == 0 then
                                                dropdownValue.Text = "None"
                                            elseif #selectedOptions == 1 then
                                                dropdownValue.Text = selectedOptions[1]
                                            else
                                                dropdownValue.Text = "Multiple"
                                            end
                                        else
                                            selectedOptions = {option}
                                            dropdownValue.Text = option
                                            
                                            -- Update all options
                                            for _, btn in ipairs(dropdownScroller:GetChildren()) do
                                                if btn:IsA("TextButton") then
                                                    btn.BackgroundColor3 = themeList.Header
                                                end
                                            end
                                            optionButton.BackgroundColor3 = themeList.SchemeColor
                                            
                                            -- Close dropdown after selection
                                            toggleDropdown()
                                        end
                                        
                                        callback(multiSelect and selectedOptions or selectedOptions[1])
                                        RippleManager:CreateRipple(optionButton, themeList.SchemeColor, 1.2)
                                    end)
                                    
                                    -- Hover effects
                                    optionButton.MouseEnter:Connect(function()
                                        if optionButton.BackgroundColor3 ~= themeList.SchemeColor then
                                            Utility:TweenObject(optionButton, {
                                                BackgroundColor3 = Color3.fromRGB(
                                                    themeList.Header.r * 255 + 20,
                                                    themeList.Header.g * 255 + 20,
                                                    themeList.Header.b * 255 + 20
                                                )
                                            }, 0.2)
                                        end
                                    end)
                                    
                                    optionButton.MouseLeave:Connect(function()
                                        if optionButton.BackgroundColor3 ~= themeList.SchemeColor then
                                            Utility:TweenObject(optionButton, {
                                                BackgroundColor3 = themeList.Header
                                            }, 0.2)
                                        end
                                    end)
                                end
                                
                                -- Create all options
                                for _, option in ipairs(options) do
                                    createOption(option)
                                end
                                
                                dropdownListing:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateDropdownSize)
                                updateDropdownSize()
                                
                                local function toggleDropdown()
                                    isOpen = not isOpen
                                    
                                    if isOpen then
                                        dropdownFrame.Visible = true
                                        Utility:TweenObject(dropdownFrame, {
                                            Size = UDim2.new(1, 0, 0, math.min(dropdownListing.AbsoluteContentSize.Y, 150))
                                        }, 0.2)
                                        Utility:TweenObject(dropdownArrow, {Rotation = 180}, 0.2)
                                    else
                                        Utility:TweenObject(dropdownFrame, {
                                            Size = UDim2.new(1, 0, 0, 0)
                                        }, 0.2)
                                        Utility:TweenObject(dropdownArrow, {Rotation = 0}, 0.2)
                                        wait(0.2)
                                        dropdownFrame.Visible = false
                                    end
                                end
                                
                                -- Toggle dropdown on click
                                dropdownElement.MouseButton1Click:Connect(function()
                                    toggleDropdown()
                                    RippleManager:CreateRipple(dropdownElement, themeList.SchemeColor, 1.2)
                                end)
                                
                                -- Close dropdown when clicking outside
                                local function closeDropdown(input)
                                    if isOpen and input.UserInputType == Enum.UserInputType.MouseButton1 then
                                        local isInDropdown = dropdownElement:IsDescendantOf(input.Target) or dropdownFrame:IsDescendantOf(input.Target)
                                        if not isInDropdown then
                                            toggleDropdown()
                                        end
                                    end
                                end
                                
                                UserInputService.InputBegan:Connect(closeDropdown)
                                
                                -- Theme updates
                                local dropdownThemeUpdater = RunService.Heartbeat:Connect(function()
                                    dropdownElement.BackgroundColor3 = themeList.ElementColor
                                    dropdownName.TextColor3 = themeList.TextColor
                                    dropdownValue.TextColor3 = themeList.TextColor
                                    dropdownArrow.ImageColor3 = themeList.TextColor
                                    dropdownStroke.Color = themeList.SchemeColor
                                    dropdownFrame.BackgroundColor3 = themeList.ElementColor
                                    dropdownFrameStroke.Color = themeList.SchemeColor
                                    dropdownScroller.ScrollBarImageColor3 = themeList.SchemeColor
                                end)
                                
                                UpdateSectionSize()
                                
                                local DropdownFunctions = {}
                                
                                function DropdownFunctions:Update(newText, newOptions, newDefault)
                                    if newText then
                                        dropdownName.Text = newText
                                    end
                                    if newOptions then
                                        options = newOptions
                                        -- Clear existing options
                                        for _, child in ipairs(dropdownScroller:GetChildren()) do
                                            if child:IsA("TextButton") then
                                                child:Destroy()
                                            end
                                        end
                                        -- Create new options
                                        for _, option in ipairs(newOptions) do
                                            createOption(option)
                                        end
                                        updateDropdownSize()
                                    end
                                    if newDefault then
                                        defaultOption = newDefault
                                        selectedOptions = multiSelect and {} or {newDefault}
                                        dropdownValue.Text = multiSelect and "None" or tostring(newDefault)
                                    end
                                end
                                
                                function DropdownFunctions:GetValue()
                                    return multiSelect and selectedOptions or selectedOptions[1]
                                end
                                
                                function DropdownFunctions:SetCallback(newCallback)
                                    callback = newCallback or callback
                                end
                                
                                return DropdownFunctions
                            end, "NewDropdown")
                        end
                        
                        -- Textbox element
                        function Elements:NewTextbox(tbname, tipInfo, placeholder, defaultText, callback, maxChars)
                            return ErrorHandler:TryExecute(function()
                                tbname = tbname or "Textbox"
                                tipInfo = tipInfo or "Enter text here"
                                placeholder = placeholder or "Type something..."
                                defaultText = defaultText or ""
                                callback = callback or function() end
                                maxChars = maxChars or 100
                                
                                local textboxElement = Instance.new("Frame")
                                local UICorner = Instance.new("UICorner")
                                local textboxName = Instance.new("TextLabel")
                                local textboxInput = Instance.new("TextBox")
                                local textboxStroke = Instance.new("UIStroke")
                                
                                textboxElement.Name = tbname
                                textboxElement.Parent = sectionInners
                                textboxElement.BackgroundColor3 = themeList.ElementColor
                                textboxElement.Size = UDim2.new(1, 0, 0, 60)
                                
                                UICorner.CornerRadius = UDim.new(0, 6)
                                UICorner.Parent = textboxElement
                                
                                textboxStroke.Parent = textboxElement
                                textboxStroke.Color = themeList.SchemeColor
                                textboxStroke.Thickness = 1
                                
                                textboxName.Name = "textboxName"
                                textboxName.Parent = textboxElement
                                textboxName.BackgroundTransparency = 1
                                textboxName.Position = UDim2.new(0, 15, 0, 8)
                                textboxName.Size = UDim2.new(1, -30, 0, 20)
                                textboxName.Font = Enum.Font.GothamSemibold
                                textboxName.Text = tbname
                                textboxName.TextColor3 = themeList.TextColor
                                textboxName.TextSize = 14
                                textboxName.TextXAlignment = Enum.TextXAlignment.Left
                                
                                textboxInput.Name = "textboxInput"
                                textboxInput.Parent = textboxElement
                                textboxInput.BackgroundColor3 = themeList.Header
                                textboxInput.Position = UDim2.new(0, 15, 0, 35)
                                textboxInput.Size = UDim2.new(1, -30, 0, 20)
                                textboxInput.Font = Enum.Font.Gotham
                                textboxInput.PlaceholderText = placeholder
                                textboxInput.Text = defaultText
                                textboxInput.TextColor3 = themeList.TextColor
                                textboxInput.TextSize = 14
                                textboxInput.ClearTextOnFocus = false
                                
                                local inputCorner = Instance.new("UICorner")
                                inputCorner.CornerRadius = UDim.new(0, 4)
                                inputCorner.Parent = textboxInput
                                
                                local inputStroke = Instance.new("UIStroke")
                                inputStroke.Parent = textboxInput
                                inputStroke.Color = themeList.SchemeColor
                                inputStroke.Thickness = 1
                                
                                local isFocused = false
                                
                                -- Focus effects
                                textboxInput.Focused:Connect(function()
                                    isFocused = true
                                    Utility:TweenObject(inputStroke, {Thickness = 2}, 0.2)
                                    Utility:TweenObject(textboxInput, {
                                        BackgroundColor3 = Color3.fromRGB(
                                            themeList.Header.r * 255 + 10,
                                            themeList.Header.g * 255 + 10,
                                            themeList.Header.b * 255 + 10
                                        )
                                    }, 0.2)
                                end)
                                
                                textboxInput.FocusLost:Connect(function(enterPressed)
                                    isFocused = false
                                    Utility:TweenObject(inputStroke, {Thickness = 1}, 0.2)
                                    Utility:TweenObject(textboxInput, {
                                        BackgroundColor3 = themeList.Header
                                    }, 0.2)
                                    
                                    if enterPressed then
                                        callback(textboxInput.Text)
                                    end
                                end)
                                
                                -- Character limit
                                textboxInput:GetPropertyChangedSignal("Text"):Connect(function()
                                    if #textboxInput.Text > maxChars then
                                        textboxInput.Text = string.sub(textboxInput.Text, 1, maxChars)
                                    end
                                end)
                                
                                -- Theme updates
                                local textboxThemeUpdater = RunService.Heartbeat:Connect(function()
                                    textboxElement.BackgroundColor3 = themeList.ElementColor
                                    textboxName.TextColor3 = themeList.TextColor
                                    textboxStroke.Color = themeList.SchemeColor
                                    textboxInput.BackgroundColor3 = isFocused and Color3.fromRGB(
                                        themeList.Header.r * 255 + 10,
                                        themeList.Header.g * 255 + 10,
                                        themeList.Header.b * 255 + 10
                                    ) or themeList.Header
                                    textboxInput.TextColor3 = themeList.TextColor
                                    textboxInput.PlaceholderColor3 = Color3.fromRGB(
                                        themeList.TextColor.r * 255 - 40,
                                        themeList.TextColor.g * 255 - 40,
                                        themeList.TextColor.b * 255 - 40
                                    )
                                    inputStroke.Color = themeList.SchemeColor
                                end)
                                
                                UpdateSectionSize()
                                
                                local TextboxFunctions = {}
                                
                                function TextboxFunctions:Update(newText, newPlaceholder, newDefault)
                                    if newText then
                                        textboxName.Text = newText
                                    end
                                    if newPlaceholder then
                                        textboxInput.PlaceholderText = newPlaceholder
                                    end
                                    if newDefault then
                                        textboxInput.Text = newDefault
                                    end
                                end
                                
                                function TextboxFunctions:GetValue()
                                    return textboxInput.Text
                                end
                                
                                function TextboxFunctions:SetCallback(newCallback)
                                    callback = newCallback or callback
                                end
                                
                                return TextboxFunctions
                            end, "NewTextbox")
                        end
                        
                        -- Keybind element
                        function Elements:NewKeybind(kname, tipInfo, defaultKey, callback, allowModifiers)
                            return ErrorHandler:TryExecute(function()
                                kname = kname or "Keybind"
                                tipInfo = tipInfo or "Press a key to bind"
                                defaultKey = defaultKey or Enum.KeyCode.LeftControl
                                callback = callback or function() end
                                allowModifiers = allowModifiers or true
                                
                                local keybindElement = Instance.new("TextButton")
                                local UICorner = Instance.new("UICorner")
                                local keybindName = Instance.new("TextLabel")
                                local keybindValue = Instance.new("TextLabel")
                                local keybindStroke = Instance.new("UIStroke")
                                
                                local currentKey = defaultKey
                                local listening = false
                                local modifiers = {}
                                
                                keybindElement.Name = kname
                                keybindElement.Parent = sectionInners
                                keybindElement.BackgroundColor3 = themeList.ElementColor
                                keybindElement.ClipsDescendants = true
                                keybindElement.Size = UDim2.new(1, 0, 0, 40)
                                keybindElement.AutoButtonColor = false
                                keybindElement.Text = ""
                                
                                UICorner.CornerRadius = UDim.new(0, 6)
                                UICorner.Parent = keybindElement
                                
                                keybindStroke.Parent = keybindElement
                                keybindStroke.Color = themeList.SchemeColor
                                keybindStroke.Thickness = 1
                                
                                keybindName.Name = "keybindName"
                                keybindName.Parent = keybindElement
                                keybindName.BackgroundTransparency = 1
                                keybindName.Position = UDim2.new(0, 15, 0, 0)
                                keybindName.Size = UDim2.new(0.6, -20, 1, 0)
                                keybindName.Font = Enum.Font.GothamSemibold
                                keybindName.Text = kname
                                keybindName.TextColor3 = themeList.TextColor
                                keybindName.TextSize = 14
                                keybindName.TextXAlignment = Enum.TextXAlignment.Left
                                
                                keybindValue.Name = "keybindValue"
                                keybindValue.Parent = keybindElement
                                keybindValue.BackgroundTransparency = 1
                                keybindValue.Position = UDim2.new(0.6, 0, 0, 0)
                                keybindValue.Size = UDim2.new(0.4, -15, 1, 0)
                                keybindValue.Font = Enum.Font.Gotham
                                keybindValue.Text = tostring(currentKey):gsub("Enum.KeyCode.", "")
                                keybindValue.TextColor3 = themeList.TextColor
                                keybindValue.TextSize = 14
                                keybindValue.TextXAlignment = Enum.TextXAlignment.Right
                                
                                local function updateDisplay()
                                    local displayText = tostring(currentKey):gsub("Enum.KeyCode.", "")
                                    if allowModifiers and #modifiers > 0 then
                                        local modifierText = table.concat(modifiers, " + ")
                                        displayText = modifierText .. " + " .. displayText
                                    end
                                    keybindValue.Text = displayText
                                end
                                
                                local function startListening()
                                    listening = true
                                    keybindValue.Text = "Press a key..."
                                    Utility:TweenObject(keybindElement, {
                                        BackgroundColor3 = themeList.SchemeColor
                                    }, 0.2)
                                    Utility:TweenObject(keybindValue, {
                                        TextColor3 = themeList.Header
                                    }, 0.2)
                                    
                                    modifiers = {}
                                    
                                    local connection
                                    connection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
                                        if gameProcessed then return end
                                        
                                        if input.UserInputType == Enum.UserInputType.Keyboard then
                                            local key = input.KeyCode
                                            
                                            -- Check for modifier keys
                                            if allowModifiers then
                                                if key == Enum.KeyCode.LeftControl or key == Enum.KeyCode.RightControl then
                                                    table.insert(modifiers, "Ctrl")
                                                    updateDisplay()
                                                    return
                                                elseif key == Enum.KeyCode.LeftShift or key == Enum.KeyCode.RightShift then
                                                    table.insert(modifiers, "Shift")
                                                    updateDisplay()
                                                    return
                                                elseif key == Enum.KeyCode.LeftAlt or key == Enum.KeyCode.RightAlt then
                                                    table.insert(modifiers, "Alt")
                                                    updateDisplay()
                                                    return
                                                end
                                            end
                                            
                                            -- Set the main key
                                            currentKey = key
                                            listening = false
                                            connection:Disconnect()
                                            
                                            Utility:TweenObject(keybindElement, {
                                                BackgroundColor3 = themeList.ElementColor
                                            }, 0.2)
                                            Utility:TweenObject(keybindValue, {
                                                TextColor3 = themeList.TextColor
                                            }, 0.2)
                                            
                                            updateDisplay()
                                            callback(currentKey, modifiers)
                                            RippleManager:CreateRipple(keybindElement, themeList.SchemeColor, 1.2)
                                        end
                                    end)
                                    
                                    -- Stop listening after 10 seconds
                                    delay(10, function()
                                        if listening then
                                            listening = false
                                            connection:Disconnect()
                                            updateDisplay()
                                            Utility:TweenObject(keybindElement, {
                                                BackgroundColor3 = themeList.ElementColor
                                            }, 0.2)
                                            Utility:TweenObject(keybindValue, {
                                                TextColor3 = themeList.TextColor
                                            }, 0.2)
                                        end
                                    end)
                                end
                                
                                -- Click to start listening
                                keybindElement.MouseButton1Click:Connect(function()
                                    if not listening then
                                        startListening()
                                    end
                                end)
                                
                                -- Hover effects
                                local hovering = false
                                keybindElement.MouseEnter:Connect(function()
                                    if not listening then
                                        hovering = true
                                        Utility:TweenObject(keybindElement, {
                                            BackgroundColor3 = Color3.fromRGB(
                                                themeList.ElementColor.r * 255 + 15,
                                                themeList.ElementColor.g * 255 + 15,
                                                themeList.ElementColor.b * 255 + 15
                                            )
                                        }, 0.2)
                                    end
                                end)
                                
                                keybindElement.MouseLeave:Connect(function()
                                    if not listening then
                                        hovering = false
                                        Utility:TweenObject(keybindElement, {
                                            BackgroundColor3 = themeList.ElementColor
                                        }, 0.2)
                                    end
                                end)
                                
                                -- Theme updates
                                local keybindThemeUpdater = RunService.Heartbeat:Connect(function()
                                    if not listening and not hovering then
                                        keybindElement.BackgroundColor3 = themeList.ElementColor
                                    end
                                    keybindName.TextColor3 = themeList.TextColor
                                    if not listening then
                                        keybindValue.TextColor3 = themeList.TextColor
                                    end
                                    keybindStroke.Color = themeList.SchemeColor
                                end)
                                
                                UpdateSectionSize()
                                
                                local KeybindFunctions = {}
                                
                                function KeybindFunctions:Update(newText, newKey)
                                    if newText then
                                        keybindName.Text = newText
                                    end
                                    if newKey then
                                        currentKey = newKey
                                        modifiers = {}
                                        updateDisplay()
                                    end
                                end
                                
                                function KeybindFunctions:GetValue()
                                    return currentKey, modifiers
                                end
                                
                                function KeybindFunctions:SetCallback(newCallback)
                                    callback = newCallback or callback
                                end
                                
                                return KeybindFunctions
                            end, "NewKeybind")
                        end
                        
                        -- ColorPicker element
                        function Elements:NewColorPicker(cpname, tipInfo, defaultColor, callback)
                            return ErrorHandler:TryExecute(function()
                                cpname = cpname or "ColorPicker"
                                tipInfo = tipInfo or "Pick a color"
                                defaultColor = defaultColor or Color3.fromRGB(255, 255, 255)
                                callback = callback or function() end
                                
                                local colorPickerElement = Instance.new("TextButton")
                                local UICorner = Instance.new("UICorner")
                                local colorPickerName = Instance.new("TextLabel")
                                local colorPreview = Instance.new("Frame")
                                local colorPickerStroke = Instance.new("UIStroke")
                                
                                local colorPickerFrame = Instance.new("Frame")
                                local hueSlider = Instance.new("ImageLabel")
                                local saturationValuePicker = Instance.new("ImageLabel")
                                local pickerCursor = Instance.new("Frame")
                                local sliderCursor = Instance.new("Frame")
                                local rgbInputs = Instance.new("Frame")
                                local hexInput = Instance.new("TextBox")
                                
                                local currentColor = defaultColor
                                local isOpen = false
                                
                                colorPickerElement.Name = cpname
                                colorPickerElement.Parent = sectionInners
                                colorPickerElement.BackgroundColor3 = themeList.ElementColor
                                colorPickerElement.ClipsDescendants = true
                                colorPickerElement.Size = UDim2.new(1, 0, 0, 40)
                                colorPickerElement.AutoButtonColor = false
                                colorPickerElement.Text = ""
                                
                                UICorner.CornerRadius = UDim.new(0, 6)
                                UICorner.Parent = colorPickerElement
                                
                                colorPickerStroke.Parent = colorPickerElement
                                colorPickerStroke.Color = themeList.SchemeColor
                                colorPickerStroke.Thickness = 1
                                
                                colorPickerName.Name = "colorPickerName"
                                colorPickerName.Parent = colorPickerElement
                                colorPickerName.BackgroundTransparency = 1
                                colorPickerName.Position = UDim2.new(0, 15, 0, 0)
                                colorPickerName.Size = UDim2.new(0.7, -20, 1, 0)
                                colorPickerName.Font = Enum.Font.GothamSemibold
                                colorPickerName.Text = cpname
                                colorPickerName.TextColor3 = themeList.TextColor
                                colorPickerName.TextSize = 14
                                colorPickerName.TextXAlignment = Enum.TextXAlignment.Left
                                
                                colorPreview.Name = "colorPreview"
                                colorPreview.Parent = colorPickerElement
                                colorPreview.BackgroundColor3 = currentColor
                                colorPreview.Position = UDim2.new(1, -35, 0.5, -10)
                                colorPreview.Size = UDim2.new(0, 20, 0, 20)
                                colorPreview.BorderSizePixel = 0
                                
                                local previewCorner = Instance.new("UICorner")
                                previewCorner.CornerRadius = UDim.new(0, 4)
                                previewCorner.Parent = colorPreview
                                
                                local previewStroke = Instance.new("UIStroke")
                                previewStroke.Parent = colorPreview
                                previewStroke.Color = themeList.SchemeColor
                                previewStroke.Thickness = 2
                                
                                -- Color picker frame (initially hidden)
                                colorPickerFrame.Name = "colorPickerFrame"
                                colorPickerFrame.Parent = colorPickerElement
                                colorPickerFrame.BackgroundColor3 = themeList.ElementColor
                                colorPickerFrame.BorderSizePixel = 0
                                colorPickerFrame.Position = UDim2.new(0, 0, 1, 5)
                                colorPickerFrame.Size = UDim2.new(1, 0, 0, 0)
                                colorPickerFrame.ClipsDescendants = true
                                colorPickerFrame.Visible = false
                                
                                local colorPickerFrameCorner = Instance.new("UICorner")
                                colorPickerFrameCorner.CornerRadius = UDim.new(0, 6)
                                colorPickerFrameCorner.Parent = colorPickerFrame
                                
                                local colorPickerFrameStroke = Instance.new("UIStroke")
                                colorPickerFrameStroke.Parent = colorPickerFrame
                                colorPickerFrameStroke.Color = themeList.SchemeColor
                                colorPickerFrameStroke.Thickness = 1
                                
                                -- Hue slider
                                hueSlider.Name = "hueSlider"
                                hueSlider.Parent = colorPickerFrame
                                hueSlider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                                hueSlider.Position = UDim2.new(0, 10, 0, 10)
                                hueSlider.Size = UDim2.new(0, 20, 0, 150)
                                hueSlider.Image = "rbxassetid://4155801252"
                                
                                local hueSliderCorner = Instance.new("UICorner")
                                hueSliderCorner.CornerRadius = UDim.new(0, 4)
                                hueSliderCorner.Parent = hueSlider
                                
                                sliderCursor.Name = "sliderCursor"
                                sliderCursor.Parent = hueSlider
                                sliderCursor.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                                sliderCursor.BorderSizePixel = 2
                                sliderCursor.BorderColor3 = Color3.fromRGB(0, 0, 0)
                                sliderCursor.Size = UDim2.new(1, 4, 0, 4)
                                sliderCursor.Position = UDim2.new(0, -2, 0, 0)
                                sliderCursor.ZIndex = 2
                                
                                local sliderCursorCorner = Instance.new("UICorner")
                                sliderCursorCorner.CornerRadius = UDim.new(1, 0)
                                sliderCursorCorner.Parent = sliderCursor
                                
                                -- Saturation/Value picker
                                saturationValuePicker.Name = "saturationValuePicker"
                                saturationValuePicker.Parent = colorPickerFrame
                                saturationValuePicker.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
                                saturationValuePicker.Position = UDim2.new(0, 40, 0, 10)
                                saturationValuePicker.Size = UDim2.new(0, 150, 0, 150)
                                saturationValuePicker.Image = "rbxassetid://4155801252"
                                
                                local svPickerCorner = Instance.new("UICorner")
                                svPickerCorner.CornerRadius = UDim.new(0, 4)
                                svPickerCorner.Parent = saturationValuePicker
                                
                                pickerCursor.Name = "pickerCursor"
                                pickerCursor.Parent = saturationValuePicker
                                pickerCursor.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                                pickerCursor.BorderSizePixel = 2
                                pickerCursor.BorderColor3 = Color3.fromRGB(0, 0, 0)
                                pickerCursor.Size = UDim2.new(0, 6, 0, 6)
                                pickerCursor.Position = UDim2.new(0, 0, 0, 0)
                                pickerCursor.ZIndex = 2
                                
                                local pickerCursorCorner = Instance.new("UICorner")
                                pickerCursorCorner.CornerRadius = UDim.new(1, 0)
                                pickerCursorCorner.Parent = pickerCursor
                                
                                -- RGB Inputs
                                rgbInputs.Name = "rgbInputs"
                                rgbInputs.Parent = colorPickerFrame
                                rgbInputs.BackgroundTransparency = 1
                                rgbInputs.Position = UDim2.new(0, 200, 0, 10)
                                rgbInputs.Size = UDim2.new(0, 80, 0, 150)
                                
                                local function createRGBInput(label, index)
                                    local inputFrame = Instance.new("Frame")
                                    local inputLabel = Instance.new("TextLabel")
                                    local inputBox = Instance.new("TextBox")
                                    
                                    inputFrame.Name = label
                                    inputFrame.Parent = rgbInputs
                                    inputFrame.BackgroundTransparency = 1
                                    inputFrame.Size = UDim2.new(1, 0, 0, 30)
                                    inputFrame.Position = UDim2.new(0, 0, 0, (index-1)*35)
                                    
                                    inputLabel.Name = "label"
                                    inputLabel.Parent = inputFrame
                                    inputLabel.BackgroundTransparency = 1
                                    inputLabel.Size = UDim2.new(0, 20, 1, 0)
                                    inputLabel.Font = Enum.Font.Gotham
                                    inputLabel.Text = label
                                    inputLabel.TextColor3 = themeList.TextColor
                                    inputLabel.TextSize = 14
                                    inputLabel.TextXAlignment = Enum.TextXAlignment.Left
                                    
                                    inputBox.Name = "input"
                                    inputBox.Parent = inputFrame
                                    inputBox.BackgroundColor3 = themeList.Header
                                    inputBox.Position = UDim2.new(0, 25, 0, 5)
                                    inputBox.Size = UDim2.new(0, 50, 0, 20)
                                    inputBox.Font = Enum.Font.Gotham
                                    inputBox.Text = "255"
                                    inputBox.TextColor3 = themeList.TextColor
                                    inputBox.TextSize = 14
                                    inputBox.ClearTextOnFocus = false
                                    
                                    local inputCorner = Instance.new("UICorner")
                                    inputCorner.CornerRadius = UDim.new(0, 4)
                                    inputCorner.Parent = inputBox
                                    
                                    local inputStroke = Instance.new("UIStroke")
                                    inputStroke.Parent = inputBox
                                    inputStroke.Color = themeList.SchemeColor
                                    inputStroke.Thickness = 1
                                    
                                    inputBox.FocusLost:Connect(function()
                                        local value = tonumber(inputBox.Text) or 255
                                        value = math.clamp(value, 0, 255)
                                        inputBox.Text = tostring(value)
                                        
                                        local r, g, b = currentColor.r * 255, currentColor.g * 255, currentColor.b * 255
                                        
                                        if label == "R" then r = value
                                        elseif label == "G" then g = value
                                        elseif label == "B" then b = value end
                                        
                                        setColor(Color3.fromRGB(r, g, b))
                                    end)
                                    
                                    return inputBox
                                end
                                
                                local rInput = createRGBInput("R", 1)
                                local gInput = createRGBInput("G", 2)
                                local bInput = createRGBInput("B", 3)
                                
                                -- Hex Input
                                local hexFrame = Instance.new("Frame")
                                hexFrame.Name = "hexFrame"
                                hexFrame.Parent = rgbInputs
                                hexFrame.BackgroundTransparency = 1
                                hexFrame.Size = UDim2.new(1, 0, 0, 30)
                                hexFrame.Position = UDim2.new(0, 0, 0, 105)
                                
                                local hexLabel = Instance.new("TextLabel")
                                hexLabel.Name = "hexLabel"
                                hexLabel.Parent = hexFrame
                                hexLabel.BackgroundTransparency = 1
                                hexLabel.Size = UDim2.new(0, 25, 1, 0)
                                hexLabel.Font = Enum.Font.Gotham
                                hexLabel.Text = "#"
                                hexLabel.TextColor3 = themeList.TextColor
                                hexLabel.TextSize = 14
                                hexLabel.TextXAlignment = Enum.TextXAlignment.Left
                                
                                hexInput.Name = "hexInput"
                                hexInput.Parent = hexFrame
                                hexInput.BackgroundColor3 = themeList.Header
                                hexInput.Position = UDim2.new(0, 25, 0, 5)
                                hexInput.Size = UDim2.new(0, 50, 0, 20)
                                hexInput.Font = Enum.Font.Gotham
                                hexInput.PlaceholderText = "FFFFFF"
                                hexInput.Text = "FFFFFF"
                                hexInput.TextColor3 = themeList.TextColor
                                hexInput.TextSize = 14
                                hexInput.ClearTextOnFocus = false
                                
                                local hexCorner = Instance.new("UICorner")
                                hexCorner.CornerRadius = UDim.new(0, 4)
                                hexCorner.Parent = hexInput
                                
                                local hexStroke = Instance.new("UIStroke")
                                hexStroke.Parent = hexInput
                                hexStroke.Color = themeList.SchemeColor
                                hexStroke.Thickness = 1
                                
                                hexInput.FocusLost:Connect(function()
                                    local hex = hexInput.Text:gsub("#", "")
                                    if hex:match("^[%x]+$") and #hex == 6 then
                                        setColor(Color3.fromHex(hex))
                                    else
                                        hexInput.Text = "FFFFFF"
                                    end
                                end)
                                
                                local function setColor(color)
                                    currentColor = color
                                    colorPreview.BackgroundColor3 = color
                                    
                                    -- Update RGB inputs
                                    rInput.Text = tostring(math.floor(color.r * 255))
                                    gInput.Text = tostring(math.floor(color.g * 255))
                                    bInput.Text = tostring(math.floor(color.b * 255))
                                    
                                    -- Update hex input
                                    hexInput.Text = string.format("%02X%02X%02X", 
                                        math.floor(color.r * 255),
                                        math.floor(color.g * 255),
                                        math.floor(color.b * 255))
                                    
                                    callback(color)
                                end
                                
                                local function toggleColorPicker()
                                    isOpen = not isOpen
                                    
                                    if isOpen then
                                        colorPickerFrame.Visible = true
                                        Utility:TweenObject(colorPickerFrame, {
                                            Size = UDim2.new(1, 0, 0, 170)
                                        }, 0.2)
                                    else
                                        Utility:TweenObject(colorPickerFrame, {
                                            Size = UDim2.new(1, 0, 0, 0)
                                        }, 0.2)
                                        wait(0.2)
                                        colorPickerFrame.Visible = false
                                    end
                                end
                                
                                -- Toggle color picker on click
                                colorPickerElement.MouseButton1Click:Connect(function()
                                    toggleColorPicker()
                                    RippleManager:CreateRipple(colorPickerElement, themeList.SchemeColor, 1.2)
                                end)
                                
                                -- Close color picker when clicking outside
                                local function closeColorPicker(input)
                                    if isOpen and input.UserInputType == Enum.UserInputType.MouseButton1 then
                                        local isInPicker = colorPickerElement:IsDescendantOf(input.Target) or colorPickerFrame:IsDescendantOf(input.Target)
                                        if not isInPicker then
                                            toggleColorPicker()
                                        end
                                    end
                                end
                                
                                UserInputService.InputBegan:Connect(closeColorPicker)
                                
                                -- Initialize with default color
                                setColor(defaultColor)
                                
                                -- Theme updates
                                local colorPickerThemeUpdater = RunService.Heartbeat:Connect(function()
                                    colorPickerElement.BackgroundColor3 = themeList.ElementColor
                                    colorPickerName.TextColor3 = themeList.TextColor
                                    colorPickerStroke.Color = themeList.SchemeColor
                                    previewStroke.Color = themeList.SchemeColor
                                    colorPickerFrame.BackgroundColor3 = themeList.ElementColor
                                    colorPickerFrameStroke.Color = themeList.SchemeColor
                                end)
                                
                                UpdateSectionSize()
                                
                                local ColorPickerFunctions = {}
                                
                                function ColorPickerFunctions:Update(newText, newColor)
                                    if newText then
                                        colorPickerName.Text = newText
                                    end
                                    if newColor then
                                        setColor(newColor)
                                    end
                                end
                                
                                function ColorPickerFunctions:GetValue()
                                    return currentColor
                                end
                                
                                function ColorPickerFunctions:SetCallback(newCallback)
                                    callback = newCallback or callback
                                end
                                
                                return ColorPickerFunctions
                            end, "NewColorPicker")
                        end
                        
                        return Elements
                    end, "NewSection")
                end
                
                return Sections
            end, "NewTab")
        end
        
        -- Show the UI
        Main.Visible = true
        Utility:TweenObject(Main, {
            Size = defaultSize,
            Position = defaultPosition
        }, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        
        -- Cleanup on destroy
        ScreenGui.Destroying:Connect(function()
            ThemeUpdater:Disconnect()
            Utility:CancelAllTweens()
            
            -- Remove from instances table
            for i, instance in ipairs(NebulaInstances) do
                if instance.ScreenGui == ScreenGui then
                    table.remove(NebulaInstances, i)
                    break
                end
            end
        end)
        
        return Tabs
    end, "CreateLib")
end

-- Global functions
function Nebula:ChangeTheme(themeName)
    return ErrorHandler:TryExecute(function()
        local newTheme = ThemeManager:SetTheme(themeName)
        if newTheme then
            for _, instance in ipairs(NebulaInstances) do
                instance.Theme = newTheme
            end
        end
        return newTheme
    end, "ChangeTheme")
end

function Nebula:CreateCustomTheme(customTheme)
    return ErrorHandler:TryExecute(function()
        return ThemeManager:CreateCustomTheme(customTheme)
    end, "CreateCustomTheme")
end

function Nebula:SendNotification(title, message, notificationType, duration)
    return ErrorHandler:TryExecute(function()
        return NotificationManager:SendNotification(title, message, notificationType, duration)
    end, "SendNotification")
end

function Nebula:SaveConfig(configName)
    return ErrorHandler:TryExecute(function()
        local libInstance = NebulaInstances[1]
        if libInstance then
            return SettingsManager:SaveConfig(libInstance, configName)
        end
        return nil
    end, "SaveConfig")
end

function Nebula:LoadConfig(configName)
    return ErrorHandler:TryExecute(function()
        local libInstance = NebulaInstances[1]
        if libInstance then
            return SettingsManager:LoadConfig(libInstance, configName)
        end
        return false
    end, "LoadConfig")
end

function Nebula:ExportConfig(configName)
    return ErrorHandler:TryExecute(function()
        return SettingsManager:ExportConfig(configName)
    end, "ExportConfig")
end

function Nebula:ImportConfig(jsonData)
    return ErrorHandler:TryExecute(function()
        return SettingsManager:ImportConfig(jsonData)
    end, "ImportConfig")
end

function Nebula:GetVersion()
    return "3.0.0"
end

-- Initialize
Utility:CreateCoroutine(function()
    while true do
        for _, instance in ipairs(NebulaInstances) do
            -- Perform periodic maintenance if needed
        end
        wait(10)
    end
end)

return Nebula
