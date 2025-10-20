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

-- Ripple Effect Manager
local RippleManager = {}
RippleManager.ActiveRipples = {}

function RippleManager:CreateRipple(button, color, scaleMultiplier)
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
end

-- Dragging System
function Nebula:DraggingEnabled(frame, parent)
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
end

-- Notification System
local NotificationManager = {}
NotificationManager.Notifications = {}
NotificationManager.NotificationQueue = {}

function NotificationManager:SendNotification(title, message, notificationType, duration)
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
end

-- Main Library Creation
function Nebula:CreateLib(libName, themeList, defaultSize, defaultPosition)
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
    
    local tabFrames = Instance.new("ScrollingFrame")
    tabFrames.Name = "tabFrames"
    tabFrames.Parent = MainSide
    tabFrames.BackgroundTransparency = 1
    tabFrames.Position = UDim2.new(0, 5, 0, 5)
    tabFrames.Size = UDim2.new(1, -10, 1, -10)
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
            end
            
            -- Toggle element
            function Elements:NewToggle(tname, tipInfo, defaultState, callback)
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
            end
            
            -- Label element
            function Elements:NewLabel(labelText, textColor)
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
            end
            
            -- Add more elements here (Slider, Dropdown, Textbox, Keybind, ColorPicker) following the same pattern...
            
            return Elements
        end
        
        return Sections
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
end

-- Global functions
function Nebula:ChangeTheme(themeName)
    local newTheme = ThemeManager:SetTheme(themeName)
    if newTheme then
        for _, instance in ipairs(NebulaInstances) do
            instance.Theme = newTheme
        end
    end
    return newTheme
end

function Nebula:CreateCustomTheme(customTheme)
    return ThemeManager:CreateCustomTheme(customTheme)
end

function Nebula:SendNotification(title, message, notificationType, duration)
    return NotificationManager:SendNotification(title, message, notificationType, duration)
end

function Nebula:GetVersion()
    return "2.0.0"
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
