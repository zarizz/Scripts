local NebulaUI = {}
NebulaUI.__index = NebulaUI

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local TextService = game:GetService("TextService")
local HttpService = game:GetService("HttpService")
local GuiService = game:GetService("GuiService")
local CoreGui = game:GetService("CoreGui")

-- Loading System
local LoadingSystem = {
    ActiveLoaders = {},
    LoaderQueue = {},
    IsShowing = false
}

function LoadingSystem:CreateLoader(windowName)
    local loader = {
        WindowName = windowName or "NebulaUI",
        Progress = 0,
        IsVisible = false,
        Completed = false
    }
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "NebulaUILoader_" .. HttpService:GenerateGUID(false)
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    screenGui.DisplayOrder = 999
    screenGui.Parent = CoreGui
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 400, 0, 200)
    mainFrame.Position = UDim2.new(0.5, -200, 0.5, -100)
    mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
    mainFrame.BorderSizePixel = 0
    mainFrame.ClipsDescendants = true
    mainFrame.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = mainFrame
    
    local glow = Instance.new("ImageLabel")
    glow.Name = "Glow"
    glow.Image = "rbxassetid://4996891970"
    glow.ImageColor3 = Color3.fromRGB(0, 255, 255)
    glow.ImageTransparency = 0.8
    glow.ScaleType = Enum.ScaleType.Slice
    glow.SliceCenter = Rect.new(20, 20, 280, 280)
    glow.Size = UDim2.new(1, 40, 1, 40)
    glow.Position = UDim2.new(0, -20, 0, -20)
    glow.BackgroundTransparency = 1
    glow.ZIndex = 0
    glow.Parent = mainFrame
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -40, 0, 40)
    titleLabel.Position = UDim2.new(0, 20, 0, 20)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = windowName or "NebulaUI"
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextSize = 24
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = mainFrame
    
    local loadingLabel = Instance.new("TextLabel")
    loadingLabel.Size = UDim2.new(1, -40, 0, 20)
    loadingLabel.Position = UDim2.new(0, 20, 0, 70)
    loadingLabel.BackgroundTransparency = 1
    loadingLabel.Text = "Loading..."
    loadingLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    loadingLabel.TextSize = 16
    loadingLabel.Font = Enum.Font.Gotham
    loadingLabel.TextXAlignment = Enum.TextXAlignment.Left
    loadingLabel.Parent = mainFrame
    
    local progressContainer = Instance.new("Frame")
    progressContainer.Size = UDim2.new(1, -40, 0, 20)
    progressContainer.Position = UDim2.new(0, 20, 0, 120)
    progressContainer.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    progressContainer.BorderSizePixel = 0
    progressContainer.Parent = mainFrame
    
    local progressCorner = Instance.new("UICorner")
    progressCorner.CornerRadius = UDim.new(1, 0)
    progressCorner.Parent = progressContainer
    
    local progressBar = Instance.new("Frame")
    progressBar.Size = UDim2.new(0, 0, 1, 0)
    progressBar.BackgroundColor3 = Color3.fromRGB(0, 255, 255)
    progressBar.BorderSizePixel = 0
    progressBar.Parent = progressContainer
    
    local progressBarCorner = Instance.new("UICorner")
    progressBarCorner.CornerRadius = UDim.new(1, 0)
    progressBarCorner.Parent = progressBar
    
    local percentageLabel = Instance.new("TextLabel")
    percentageLabel.Size = UDim2.new(1, -40, 0, 20)
    percentageLabel.Position = UDim2.new(0, 20, 0, 150)
    percentageLabel.BackgroundTransparency = 1
    percentageLabel.Text = "0%"
    percentageLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    percentageLabel.TextSize = 14
    percentageLabel.Font = Enum.Font.Gotham
    percentageLabel.TextXAlignment = Enum.TextXAlignment.Right
    percentageLabel.Parent = mainFrame
    
    loader.Gui = screenGui
    loader.MainFrame = mainFrame
    loader.ProgressBar = progressBar
    loader.PercentageLabel = percentageLabel
    loader.LoadingLabel = loadingLabel
    
    function loader:Show()
        if self.IsVisible then return end
        
        self.IsVisible = true
        self.MainFrame.Size = UDim2.new(0, 0, 0, 0)
        self.MainFrame.Visible = true
        
        local tweenIn = TweenService:Create(self.MainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 400, 0, 200)
        })
        tweenIn:Play()
        
        LoadingSystem.IsShowing = true
    end
    
    function loader:Hide()
        if not self.IsVisible then return end
        
        local tweenOut = TweenService:Create(self.MainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 0, 0, 0)
        })
        tweenOut:Play()
        
        tweenOut.Completed:Connect(function()
            self.MainFrame.Visible = false
            self.IsVisible = false
            LoadingSystem.IsShowing = false
        end)
    end
    
    function loader:SetProgress(progress)
        progress = math.clamp(progress, 0, 100)
        self.Progress = progress
        
        local targetWidth = (progress / 100) * 360
        TweenService:Create(self.ProgressBar, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, targetWidth, 1, 0)
        }):Play()
        
        self.PercentageLabel.Text = math.floor(progress) .. "%"
        
        if progress >= 100 and not self.Completed then
            self.Completed = true
            self:Complete()
        end
    end
    
    function loader:SetText(text)
        self.LoadingLabel.Text = text or "Loading..."
    end
    
    function loader:Complete()
        self:SetProgress(100)
        
        delay(0.5, function()
            self:Hide()
            
            delay(0.5, function()
                if self.Gui then
                    self.Gui:Destroy()
                end
                
                NebulaUI:Notify("Success", "Successfully loaded " .. self.WindowName, 3, "Success")
            end)
        end)
    end
    
    function loader:Destroy()
        if self.Gui then
            self.Gui:Destroy()
        end
    end
    
    self.ActiveLoaders[loader] = true
    return loader
end

-- GitHub Raw Support System
local GitHubSupport = {
    BaseURL = "https://raw.githubusercontent.com/",
    Cache = {},
    Timeout = 10
}

function GitHubSupport:LoadFromGitHub(user, repo, branch, filePath)
    local cacheKey = user .. "/" .. repo .. "/" .. branch .. "/" .. filePath
    if self.Cache[cacheKey] then
        return self.Cache[cacheKey]
    end
    
    local url = self.BaseURL .. user .. "/" .. repo .. "/" .. branch .. "/" .. filePath
    
    local success, result = pcall(function()
        return game:HttpGetAsync(url)
    end)
    
    if success then
        self.Cache[cacheKey] = result
        return result
    else
        warn("[NebulaUI GitHub] Failed to load: " .. url)
        return nil
    end
end

function GitHubSupport:LoadLibrary(user, repo, branch, filePath)
    local loader = LoadingSystem:CreateLoader("NebulaUI Library")
    loader:Show()
    
    coroutine.wrap(function()
        for i = 1, 100 do
            loader:SetProgress(i)
            loader:SetText("Downloading library... " .. i .. "%")
            wait(0.02)
        end
    end)()
    
    local code = self:LoadFromGitHub(user, repo, branch, filePath)
    
    if code then
        local success, loadedFunction = pcall(loadstring, code)
        if success then
            loader:SetText("Initializing library...")
            wait(0.5)
            loader:Complete()
            return loadedFunction()
        else
            loader:SetText("Error loading library")
            wait(2)
            loader:Hide()
            warn("[NebulaUI GitHub] Error executing loaded code: " .. loadedFunction)
        end
    else
        loader:SetText("Failed to download")
        wait(2)
        loader:Hide()
    end
    
    return nil
end

-- Constants
local MIN_WINDOW_WIDTH = 300
local MIN_WINDOW_HEIGHT = 200
local MAX_WINDOW_WIDTH = 1200
local MAX_WINDOW_HEIGHT = 800
local MOBILE_BREAKPOINT = 768
local TABLET_BREAKPOINT = 1024

-- Memory Management System
local MemoryManager = {
    AllocationTracker = {},
    LeakDetector = {},
    GCOptimizer = {},
    PeakUsage = 0,
    CleanupCycles = 0
}

function MemoryManager:TrackAllocation(obj, type, stack)
    local id = tostring(obj)
    self.AllocationTracker[id] = {
        Object = obj,
        Type = type,
        Stack = stack,
        Timestamp = tick(),
        Size = self:CalculateMemoryFootprint(obj, 0, {})
    }
    self:ScheduleCleanup()
end

function MemoryManager:CalculateMemoryFootprint(obj, depth, visited)
    depth = depth or 0
    visited = visited or {}
    
    if depth > 50 then return 10 end
    
    local size = 0
    local objId = tostring(obj)
    
    if visited[objId] then
        return 0
    end
    visited[objId] = true
    
    if typeof(obj) == "Instance" then
        size = 100
        for _, child in ipairs(obj:GetChildren()) do
            size = size + self:CalculateMemoryFootprint(child, depth + 1, visited)
        end
    elseif type(obj) == "table" then
        size = 50
        for k, v in pairs(obj) do
            size = size + self:CalculateMemoryFootprint(k, depth + 1, visited) 
                      + self:CalculateMemoryFootprint(v, depth + 1, visited)
        end
    else
        size = 10
    end
    return size
end

function MemoryManager:DetectLeaks()
    local active = {}
    local leaks = {}
    
    for id, data in pairs(self.AllocationTracker) do
        if data.Object and (data.Object.Parent or (typeof(data.Object) == "RBXScriptConnection" and data.Object.Connected)) then
            active[id] = true
        else
            leaks[id] = data
        end
    end
    
    if next(leaks) then
        warn(string.format("[NebulaUI Memory Leak Detected] %d objects", table.count(leaks)))
        for id, leakData in pairs(leaks) do
            warn(string.format("- %s allocated at %f", leakData.Type, leakData.Timestamp))
            self.AllocationTracker[id] = nil
        end
    end
    
    return leaks
end

function MemoryManager:OptimizeGC()
    local memoryUsage = collectgarbage("count")
    self.PeakUsage = math.max(self.PeakUsage, memoryUsage)
    
    if memoryUsage > 50 * 1024 then
        collectgarbage("restart")
        collectgarbage("incremental", 100, 100)
    elseif memoryUsage > 20 * 1024 then
        collectgarbage("step", 200)
    end
end

function MemoryManager:ScheduleCleanup()
    self.CleanupCycles = self.CleanupCycles + 1
    if self.CleanupCycles % 100 == 0 then
        self:DetectLeaks()
        self:OptimizeGC()
    end
end

-- Performance Monitor
local PerformanceMonitor = {
    Metrics = {
        FrameTime = {},
        MemoryUsage = {},
        RenderPerformance = {},
        UserInteractions = {}
    },
    Alerts = {},
    Thresholds = {
        CRITICAL_FPS = 30,
        HIGH_MEMORY = 100 * 1024,
        SLOW_RENDER = 16
    }
}

function PerformanceMonitor:StartContinuousMonitoring()
    self.MonitoringConnection = RunService.Heartbeat:Connect(function(deltaTime)
        self:CaptureFrameMetrics(deltaTime)
        self:CheckPerformanceThresholds()
        self:AdaptiveOptimization()
    end)
end

function PerformanceMonitor:CaptureFrameMetrics(deltaTime)
    local metrics = {
        timestamp = tick(),
        frameTime = deltaTime,
        fps = 1 / deltaTime,
        memory = collectgarbage("count"),
        renderQueue = 0
    }
    
    table.insert(self.Metrics.FrameTime, metrics)
    
    if #self.Metrics.FrameTime > 300 then
        table.remove(self.Metrics.FrameTime, 1)
    end
end

function PerformanceMonitor:CheckPerformanceThresholds()
    if #self.Metrics.FrameTime == 0 then return end
    
    local currentFPS = self.Metrics.FrameTime[#self.Metrics.FrameTime].fps
    local currentMemory = self.Metrics.FrameTime[#self.Metrics.FrameTime].memory
    
    if currentFPS < self.Thresholds.CRITICAL_FPS then
        self:TriggerPerformanceAlert("CRITICAL_FPS", currentFPS)
        self:ActivateEmergencyMeasures()
    end
    
    if currentMemory > self.Thresholds.HIGH_MEMORY then
        self:TriggerPerformanceAlert("HIGH_MEMORY", currentMemory)
        self:ForceGarbageCollection()
    end
end

function PerformanceMonitor:TriggerPerformanceAlert(alertType, currentValue)
    warn(string.format("[NebulaUI Performance Alert] %s: %f", alertType, currentValue))
end

function PerformanceMonitor:ActivateEmergencyMeasures()
    collectgarbage("restart")
end

function PerformanceMonitor:ForceGarbageCollection()
    collectgarbage("collect")
end

function PerformanceMonitor:AdaptiveOptimization()
    MemoryManager:OptimizeGC()
end

-- Initialize systems
PerformanceMonitor:StartContinuousMonitoring()

local Performance = {
    FPS = 0,
    MemoryUsage = 0,
    LastUpdate = tick(),
    Connections = {}
}

local UIPool = {
    Buttons = {},
    Labels = {},
    Frames = {},
    Active = {}
}

local function GetDeviceType()
    local success, viewportSize = pcall(function()
        return workspace.CurrentCamera.ViewportSize
    end)
    
    if not success or not viewportSize then
        return "Desktop"
    end
    
    if viewportSize.X <= MOBILE_BREAKPOINT then
        return "Mobile"
    elseif viewportSize.X <= TABLET_BREAKPOINT then
        return "Tablet"
    else
        return "Desktop"
    end
end

local Themes = {
    GalacticDark = {
        SchemeColor = Color3.fromRGB(0, 255, 255),
        Background = Color3.fromRGB(15, 15, 25),
        Header = Color3.fromRGB(10, 10, 20),
        TextColor = Color3.fromRGB(255, 255, 255),
        ElementColor = Color3.fromRGB(25, 25, 35),
        SecondaryColor = Color3.fromRGB(35, 35, 45),
        HoverColor = Color3.fromRGB(45, 45, 65),
        ActiveColor = Color3.fromRGB(0, 150, 200),
        AccentColor = Color3.fromRGB(100, 255, 255),
        Mobile = {
            FontSize = 14,
            ElementHeight = 36,
            Padding = 8
        },
        Desktop = {
            FontSize = 16,
            ElementHeight = 40,
            Padding = 12
        }
    },
    NebulaLight = {
        SchemeColor = Color3.fromRGB(0, 100, 255),
        Background = Color3.fromRGB(240, 240, 245),
        Header = Color3.fromRGB(220, 220, 230),
        TextColor = Color3.fromRGB(30, 30, 40),
        ElementColor = Color3.fromRGB(250, 250, 255),
        SecondaryColor = Color3.fromRGB(230, 230, 240),
        HoverColor = Color3.fromRGB(210, 210, 220),
        ActiveColor = Color3.fromRGB(0, 80, 200),
        AccentColor = Color3.fromRGB(0, 100, 255),
        Mobile = {
            FontSize = 14,
            ElementHeight = 36,
            Padding = 8
        },
        Desktop = {
            FontSize = 16,
            ElementHeight = 40,
            Padding = 12
        }
    }
}

local function SafeDisconnect(connection)
    if connection and typeof(connection) == "RBXScriptConnection" then
        connection:Disconnect()
    end
end

local function CleanupTable(t)
    for k, v in pairs(t) do
        if typeof(v) == "RBXScriptConnection" then
            SafeDisconnect(v)
        elseif type(v) == "table" then
            CleanupTable(v)
        end
    end
    table.clear(t)
end

local function Create(class, properties)
    local obj = Instance.new(class)
    for prop, value in pairs(properties) do
        if prop ~= "Parent" then
            if pcall(function() return obj[prop] end) then
                obj[prop] = value
            end
        end
    end
    if properties.Parent then
        obj.Parent = properties.Parent
    end
    
    MemoryManager:TrackAllocation(obj, class, debug.traceback())
    return obj
end

local function Tween(Object, Properties, Duration, Style, Direction)
    local TweenInfo = TweenInfo.new(Duration or 0.2, Style or Enum.EasingStyle.Quad, Direction or Enum.EasingDirection.Out)
    local Tween = TweenService:Create(Object, TweenInfo, Properties)
    Tween:Play()
    return Tween
end

local function AddGlowEffect(frame, color)
    local Glow = Create("ImageLabel", {
        Name = "Glow",
        Image = "rbxassetid://4996891970",
        ImageColor3 = color or Color3.fromRGB(0, 255, 255),
        ImageTransparency = 0.8,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(20, 20, 280, 280),
        Size = UDim2.new(1, 40, 1, 40),
        Position = UDim2.new(0, -20, 0, -20),
        BackgroundTransparency = 1,
        ZIndex = 0
    })
    Glow.Parent = frame
    return Glow
end

local function CalculateResponsiveSize(deviceType, aspectRatio)
    local viewportSize = workspace.CurrentCamera.ViewportSize
    
    if deviceType == "Mobile" then
        if aspectRatio > 1 then
            return UDim2.new(0.9, 0, 0.85, 0)
        else
            return UDim2.new(0.95, 0, 0.9, 0)
        end
    elseif deviceType == "Tablet" then
        return UDim2.new(0.8, 0, 0.75, 0)
    else
        return UDim2.new(0, 650, 0, 500)
    end
end

local function UpdatePerformanceStats()
    local currentTime = tick()
    if currentTime - Performance.LastUpdate >= 1 then
        Performance.FPS = math.floor(1 / RunService.Heartbeat:Wait())
        Performance.MemoryUsage = collectgarbage("count")
        Performance.LastUpdate = currentTime
    end
end

local function MakeDraggable(frame, header, constraints)
    local dragData = {
        Dragging = false,
        DragInput = nil,
        DragStart = nil,
        StartPosition = nil,
        Connections = {}
    }
    
    local function GetScreenBounds()
        local viewportSize = workspace.CurrentCamera.ViewportSize
        local frameSize = frame.AbsoluteSize
        return {
            Left = 0,
            Right = viewportSize.X - frameSize.X,
            Top = 0,
            Bottom = viewportSize.Y - frameSize.Y
        }
    end
    
    local function SmoothUpdate(input)
        if not dragData.Dragging then return end
        
        local currentTime = tick()
        local Delta = input.Position - dragData.DragStart
        local newPosition = UDim2.new(
            dragData.StartPosition.X.Scale, 
            dragData.StartPosition.X.Offset + Delta.X,
            dragData.StartPosition.Y.Scale, 
            dragData.StartPosition.Y.Offset + Delta.Y
        )
        
        frame.Position = newPosition
    end
    
    local function ConstrainToBounds()
        local bounds = GetScreenBounds()
        local currentPos = frame.AbsolutePosition
        local frameSize = frame.AbsoluteSize
        
        local newX = math.clamp(currentPos.X, bounds.Left, bounds.Right)
        local newY = math.clamp(currentPos.Y, bounds.Top, bounds.Bottom)
        
        if newX ~= currentPos.X or newY ~= currentPos.Y then
            frame.Position = UDim2.new(0, newX, 0, newY)
        end
    end
    
    local function SnapToEdges()
        local bounds = GetScreenBounds()
        local currentPos = frame.AbsolutePosition
        local frameSize = frame.AbsoluteSize
        local snapThreshold = 20
        
        local newX, newY = currentPos.X, currentPos.Y
        
        if math.abs(currentPos.X - bounds.Left) < snapThreshold then
            newX = bounds.Left
        elseif math.abs(currentPos.X - bounds.Right) < snapThreshold then
            newX = bounds.Right
        end
        
        if math.abs(currentPos.Y - bounds.Top) < snapThreshold then
            newY = bounds.Top
        elseif math.abs(currentPos.Y - bounds.Bottom) < snapThreshold then
            newY = bounds.Bottom
        end
        
        if newX ~= currentPos.X or newY ~= currentPos.Y then
            Tween(frame, {
                Position = UDim2.new(0, newX, 0, newY)
            }, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        end
    end
    
    dragData.Connections.inputBegan = header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragData.Dragging = true
            dragData.DragStart = input.Position
            dragData.StartPosition = frame.Position
            
            dragData.Connections.inputChanged = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragData.Dragging = false
                    SnapToEdges()
                    SafeDisconnect(dragData.Connections.inputChanged)
                end
            end)
        end
    end)
    
    dragData.Connections.inputChanged = header.InputChanged:Connect(function(input)
        if (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            dragData.DragInput = input
        end
    end)
    
    dragData.Connections.userInputChanged = UserInputService.InputChanged:Connect(function(input)
        if input == dragData.DragInput and dragData.Dragging then
            SmoothUpdate(input)
            ConstrainToBounds()
        end
    end)
    
    dragData.Connections.viewportChanged = workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(ConstrainToBounds)
    
    return dragData
end

local KeybindSystem = {
    ActiveBinds = {},
    Connections = {}
}

function KeybindSystem:RegisterKeybind(key, callback, options)
    options = options or {}
    local keybind = {
        Key = key,
        Callback = callback,
        Options = options,
        Connection = nil
    }
    
    self.ActiveBinds[key] = keybind
    return keybind
end

function KeybindSystem:UnregisterKeybind(key)
    if self.ActiveBinds[key] then
        SafeDisconnect(self.ActiveBinds[key].Connection)
        self.ActiveBinds[key] = nil
    end
end

function KeybindSystem:Cleanup()
    for key, keybind in pairs(self.ActiveBinds) do
        SafeDisconnect(keybind.Connection)
    end
    table.clear(self.ActiveBinds)
    CleanupTable(self.Connections)
end

KeybindSystem.Connections.inputBegan = UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    
    if input.UserInputType == Enum.UserInputType.Keyboard then
        local keybind = KeybindSystem.ActiveBinds[input.KeyCode]
        if keybind then
            keybind.Callback()
        end
    end
end)

local ConfigSystem = {
    AutoSave = false,
    DefaultPath = "NebulaUI_Configs/",
    CurrentConfig = nil
}

function ConfigSystem:SaveConfig(configName, data)
    local success, result = pcall(function()
        local json = HttpService:JSONEncode(data)
        if not isfolder(self.DefaultPath) then
            makefolder(self.DefaultPath)
        end
        writefile(self.DefaultPath .. configName .. ".json", json)
        return true
    end)
    return success
end

function ConfigSystem:LoadConfig(configName)
    local success, result = pcall(function()
        if not isfolder(self.DefaultPath) then
            return nil
        end
        local path = self.DefaultPath .. configName .. ".json"
        if not isfile(path) then
            return nil
        end
        local data = readfile(path)
        return HttpService:JSONDecode(data)
    end)
    return success and result or nil
end

function ConfigSystem:DeleteConfig(configName)
    local success = pcall(function()
        local path = self.DefaultPath .. configName .. ".json"
        if isfile(path) then
            delfile(path)
            return true
        end
        return false
    end)
    return success
end

function NebulaUI:CreateWindow(Options)
    Options = Options or {}
    
    local Window = {
        Tabs = {},
        CurrentTab = nil,
        Theme = Options.Theme and Themes[Options.Theme] or Options.CustomTheme or Themes.GalacticDark,
        Open = true,
        DeviceType = GetDeviceType(),
        Connections = {},
        Keybinds = {},
        Config = {
            Name = Options.ConfigName or "DefaultConfig",
            AutoSave = Options.AutoSave or false
        },
        States = {},
        Analytics = {}
    }
    setmetatable(Window, self)
    
    if not Window.Theme then
        Window.Theme = Themes.GalacticDark
    end
    
    local viewportSize = workspace.CurrentCamera.ViewportSize
    local aspectRatio = viewportSize.X / viewportSize.Y
    local responsiveSize = CalculateResponsiveSize(Window.DeviceType, aspectRatio)
    
    local calculatedSize = UDim2.new(
        responsiveSize.X.Scale,
        math.clamp(responsiveSize.X.Offset, MIN_WINDOW_WIDTH, MAX_WINDOW_WIDTH),
        responsiveSize.Y.Scale,
        math.clamp(responsiveSize.Y.Offset, MIN_WINDOW_HEIGHT, MAX_WINDOW_HEIGHT)
    )
    
    Window.ScreenGui = Create("ScreenGui", {
        Name = "NebulaUI_" .. HttpService:GenerateGUID(false):sub(1, 8),
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Global,
        DisplayOrder = 10
    })
    
    if Options.Parent then
        Window.ScreenGui.Parent = Options.Parent
    else
        Window.ScreenGui.Parent = CoreGui
    end
    
    Window.MainFrame = Create("Frame", {
        Parent = Window.ScreenGui,
        Size = calculatedSize,
        Position = UDim2.new(0.5, -calculatedSize.X.Offset/2, 0.5, -calculatedSize.Y.Offset/2),
        BackgroundColor3 = Window.Theme.Background,
        BorderSizePixel = 0,
        ClipsDescendants = true
    })
    
    Window.NeonBorder = Create("Frame", {
        Parent = Window.MainFrame,
        Size = UDim2.new(1, 4, 1, 4),
        Position = UDim2.new(0, -2, 0, -2),
        BackgroundColor3 = Window.Theme.SchemeColor,
        BorderSizePixel = 0,
        ZIndex = 0
    })
    
    Create("Frame", {
        Parent = Window.NeonBorder,
        Size = UDim2.new(1, -4, 1, -4),
        Position = UDim2.new(0, 2, 0, 2),
        BackgroundColor3 = Window.Theme.Background,
        BorderSizePixel = 0
    })
    
    Window.Header = Create("Frame", {
        Parent = Window.MainFrame,
        Size = UDim2.new(1, 0, 0, Window.DeviceType == "Mobile" and 50 or 45),
        Position = UDim2.new(0, 0, 0, 2),
        BackgroundColor3 = Window.Theme.Header,
        BorderSizePixel = 0
    })
    
    local HeaderLayout = Create("UIListLayout", {
        Parent = Window.Header,
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 10)
    })
    
    local HeaderPadding = Create("UIPadding", {
        Parent = Window.Header,
        PaddingLeft = UDim.new(0, 15),
        PaddingRight = UDim.new(0, 15)
    })
    
    Window.TitleLabel = Create("TextLabel", {
        Parent = Window.Header,
        Size = UDim2.new(1, -150, 1, 0),
        LayoutOrder = 1,
        BackgroundTransparency = 1,
        Text = Options.Title or "NebulaUI Dashboard",
        TextColor3 = Window.Theme.TextColor,
        TextSize = Window.DeviceType == "Mobile" and 18 or 20,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd
    })
    
    Window.PerfLabel = Create("TextLabel", {
        Parent = Window.Header,
        Size = UDim2.new(0, 80, 1, 0),
        LayoutOrder = 2,
        BackgroundTransparency = 1,
        Text = "FPS: 60",
        TextColor3 = Window.Theme.TextColor,
        TextTransparency = 0.5,
        TextSize = Window.DeviceType == "Mobile" and 12 or 14,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Right,
        Visible = Window.DeviceType ~= "Mobile"
    })
    
    Window.CloseButton = Create("TextButton", {
        Parent = Window.Header,
        Size = UDim2.new(0, Window.DeviceType == "Mobile" and 40 or 30, 0, Window.DeviceType == "Mobile" and 40 or 30),
        LayoutOrder = 3,
        BackgroundColor3 = Window.Theme.ElementColor,
        BorderSizePixel = 0,
        Text = "×",
        TextColor3 = Window.Theme.TextColor,
        TextSize = Window.DeviceType == "Mobile" and 24 or 20,
        Font = Enum.Font.GothamBold,
        AutoButtonColor = false
    })
    
    Create("UICorner", {
        Parent = Window.CloseButton,
        CornerRadius = UDim.new(0, 6)
    })
    
    local tabContainerWidth = Window.DeviceType == "Mobile" and 0.3 or 0.2
    
    Window.TabContainer = Create("Frame", {
        Parent = Window.MainFrame,
        Size = UDim2.new(tabContainerWidth, 0, 1, -Window.Header.Size.Y.Offset - 2),
        Position = UDim2.new(0, 0, 0, Window.Header.Size.Y.Offset + 2),
        BackgroundColor3 = Window.Theme.SecondaryColor,
        BorderSizePixel = 0,
        Visible = Window.DeviceType ~= "Mobile"
    })
    
    Window.ContentContainer = Create("Frame", {
        Parent = Window.MainFrame,
        Size = Window.DeviceType == "Mobile" and UDim2.new(1, 0, 1, -Window.Header.Size.Y.Offset - 2) or UDim2.new(1 - tabContainerWidth, 0, 1, -Window.Header.Size.Y.Offset - 2),
        Position = Window.DeviceType == "Mobile" and UDim2.new(0, 0, 0, Window.Header.Size.Y.Offset + 2) or UDim2.new(tabContainerWidth, 0, 0, Window.Header.Size.Y.Offset + 2),
        BackgroundColor3 = Window.Theme.Background,
        BorderSizePixel = 0,
        ClipsDescendants = true
    })
    
    if Window.DeviceType == "Mobile" then
        Window.MobileTabSwitcher = Create("Frame", {
            Parent = Window.MainFrame,
            Size = UDim2.new(1, 0, 0, 40),
            Position = UDim2.new(0, 0, 0, Window.Header.Size.Y.Offset + 2),
            BackgroundColor3 = Window.Theme.SecondaryColor,
            BorderSizePixel = 0
        })
        
        local SwitcherLayout = Create("UIListLayout", {
            Parent = Window.MobileTabSwitcher,
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 5)
        })
        
        Create("UIPadding", {
            Parent = Window.MobileTabSwitcher,
            PaddingLeft = UDim.new(0, 10),
            PaddingRight = UDim.new(0, 10)
        })
        
        Window.ContentContainer.Position = UDim2.new(0, 0, 0, Window.Header.Size.Y.Offset + Window.MobileTabSwitcher.Size.Y.Offset + 2)
        Window.ContentContainer.Size = UDim2.new(1, 0, 1, -Window.Header.Size.Y.Offset - Window.MobileTabSwitcher.Size.Y.Offset - 2)
    end
    
    if Window.DeviceType ~= "Mobile" then
        Create("UIListLayout", {
            Parent = Window.TabContainer,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 8)
        })
        
        Create("UIPadding", {
            Parent = Window.TabContainer,
            PaddingTop = UDim.new(0, 10),
            PaddingLeft = UDim.new(0, 10),
            PaddingRight = UDim.new(0, 10)
        })
    end
    
    Window.DragData = MakeDraggable(Window.MainFrame, Window.Header, {
        Enabled = true,
        SnapToEdges = true,
        ConstrainToViewport = true
    })
    
    Window.Connections.closeButton = Window.CloseButton.MouseButton1Click:Connect(function()
        Window:Toggle()
    end)
    
    Window.Connections.closeTouch = Window.CloseButton.TouchTap:Connect(function()
        Window:Toggle()
    end)
    
    local lastPerformanceUpdate = 0
    Window.Connections.heartbeat = RunService.Heartbeat:Connect(function()
        local currentTime = tick()
        if currentTime - lastPerformanceUpdate >= 1 then
            UpdatePerformanceStats()
            if Window.PerfLabel then
                Window.PerfLabel.Text = string.format("FPS: %d", Performance.FPS)
            end
            lastPerformanceUpdate = currentTime
        end
    end)
    
    local resizeDebounce = false
    local function HandleResize()
        if resizeDebounce then return end
        resizeDebounce = true
        
        local viewportSize = workspace.CurrentCamera.ViewportSize
        local newDeviceType = GetDeviceType()
        local aspectRatio = viewportSize.X / viewportSize.Y
        
        if newDeviceType ~= Window.DeviceType then
            Window.DeviceType = newDeviceType
        end
        
        local bounds = {
            Left = 0,
            Right = viewportSize.X - Window.MainFrame.AbsoluteSize.X,
            Top = 0,
            Bottom = viewportSize.Y - Window.MainFrame.AbsoluteSize.Y
        }
        
        local currentPos = Window.MainFrame.AbsolutePosition
        local newX = math.clamp(currentPos.X, bounds.Left, bounds.Right)
        local newY = math.clamp(currentPos.Y, bounds.Top, bounds.Bottom)
        
        if newX ~= currentPos.X or newY ~= currentPos.Y then
            Window.MainFrame.Position = UDim2.new(0, newX, 0, newY)
        end
        
        resizeDebounce = false
    end
    
    Window.Connections.viewportResize = workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(HandleResize)
    
    function Window:CreateTab(Title, Icon)
        local Tab = {
            Title = Title or "New Tab",
            Sections = {},
            Visible = false,
            Connections = {},
            TwoColumnManager = {
                LeftSections = {},
                RightSections = {},
                LayoutOrder = 0
            }
        }
        
        if Window.DeviceType == "Mobile" then
            Tab.Button = Create("TextButton", {
                Parent = Window.MobileTabSwitcher,
                Size = UDim2.new(0.3, 0, 0.8, 0),
                LayoutOrder = #Window.Tabs + 1,
                BackgroundColor3 = Window.Theme.ElementColor,
                BorderSizePixel = 0,
                Text = Title or "Tab",
                TextColor3 = Window.Theme.TextColor,
                TextSize = 12,
                Font = Enum.Font.Gotham,
                AutoButtonColor = false
            })
        else
            Tab.Button = Create("TextButton", {
                Parent = Window.TabContainer,
                Size = UDim2.new(1, 0, 0, Window.DeviceType == "Tablet" and 45 or 40),
                BackgroundColor3 = Window.Theme.ElementColor,
                BorderSizePixel = 0,
                Text = "",
                AutoButtonColor = false
            })
            
            Tab.ButtonLabel = Create("TextLabel", {
                Parent = Tab.Button,
                Size = UDim2.new(1, -15, 1, 0),
                Position = UDim2.new(0, 15, 0, 0),
                BackgroundTransparency = 1,
                Text = Title or "New Tab",
                TextColor3 = Window.Theme.TextColor,
                TextSize = Window.DeviceType == "Tablet" and 14 or 12,
                Font = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Left
            })
        end
        
        if Tab.Button then
            Create("UICorner", {
                Parent = Tab.Button,
                CornerRadius = UDim.new(0, 6)
            })
        end
        
        Tab.Frame = Create("ScrollingFrame", {
            Parent = Window.ContentContainer,
            Size = UDim2.new(1, 0, 1, 0),
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = Window.DeviceType == "Mobile" and 6 or 4,
            ScrollBarImageColor3 = Window.Theme.SchemeColor,
            ScrollBarImageTransparency = 0.7,
            Visible = false,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y
        })
        
        local TabLayout = Create("UIListLayout", {
            Parent = Tab.Frame,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, Window.DeviceType == "Mobile" and 10 or 15)
        })
        
        Create("UIPadding", {
            Parent = Tab.Frame,
            PaddingTop = UDim.new(0, 10),
            PaddingLeft = UDim.new(0, 15),
            PaddingRight = UDim.new(0, 15),
            PaddingBottom = UDim.new(0, 10)
        })
        
        if Window.DeviceType ~= "Mobile" then
            Tab.TwoColumnContainer = Create("Frame", {
                Parent = Tab.Frame,
                Size = UDim2.new(1, 0, 0, 0),
                BackgroundTransparency = 1,
                AutomaticSize = Enum.AutomaticSize.Y,
                LayoutOrder = 1
            })
            
            local TwoColumnLayout = Create("UIListLayout", {
                Parent = Tab.TwoColumnContainer,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 15)
            })
            
            Tab.TwoColumnContainerUIPadding = Create("UIPadding", {
                Parent = Tab.TwoColumnContainer,
                PaddingLeft = UDim.new(0, 0),
                PaddingRight = UDim.new(0, 0)
            })
        end
        
        if Tab.Button then
            Tab.Connections.mouseEnter = Tab.Button.MouseEnter:Connect(function()
                if Tab ~= Window.CurrentTab then
                    Tween(Tab.Button, {BackgroundColor3 = Window.Theme.HoverColor}, 0.2)
                end
            end)
            
            Tab.Connections.mouseLeave = Tab.Button.MouseLeave:Connect(function()
                if Tab ~= Window.CurrentTab then
                    Tween(Tab.Button, {BackgroundColor3 = Window.Theme.ElementColor}, 0.2)
                end
            end)
            
            Tab.Connections.mouseClick = Tab.Button.MouseButton1Click:Connect(function()
                Window:SwitchTab(Tab)
            end)
            
            Tab.Connections.touchTap = Tab.Button.TouchTap:Connect(function()
                Window:SwitchTab(Tab)
            end)
        end
        
        function Tab:CreateSection(Name, Side)
            local Section = {
                Name = Name or "New Section",
                Elements = {},
                Side = Side or "Full",
                Connections = {}
            }
            
            local parentContainer = Tab.Frame
            local sectionWidth = UDim2.new(1, 0, 0, 0)
            
            if Window.DeviceType ~= "Mobile" and Side ~= "Full" then
                parentContainer = Tab.TwoColumnContainer
                sectionWidth = UDim2.new(0.48, -7.5, 0, 0)
                
                if Side == "Left" then
                    Tab.TwoColumnManager.LeftSections[#Tab.TwoColumnManager.LeftSections + 1] = Section
                elseif Side == "Right" then
                    Tab.TwoColumnManager.RightSections[#Tab.TwoColumnManager.RightSections + 1] = Section
                end
            end
            
            Section.Frame = Create("Frame", {
                Parent = parentContainer,
                Size = sectionWidth,
                BackgroundColor3 = Window.Theme.ElementColor,
                BorderSizePixel = 0,
                AutomaticSize = Enum.AutomaticSize.Y,
                LayoutOrder = Tab.TwoColumnManager.LayoutOrder
            })
            
            if Window.DeviceType ~= "Mobile" and Side == "Right" then
                Section.Frame.Position = UDim2.new(0.52, 0, 0, 0)
            end
            
            Create("UICorner", {
                Parent = Section.Frame,
                CornerRadius = UDim.new(0, 8)
            })
            
            AddGlowEffect(Section.Frame, Window.Theme.SchemeColor)
            
            Section.Header = Create("Frame", {
                Parent = Section.Frame,
                Size = UDim2.new(1, 0, 0, Window.DeviceType == "Mobile" and 40 or 35),
                BackgroundColor3 = Window.Theme.SecondaryColor,
                BorderSizePixel = 0
            })
            
            Create("UICorner", {
                Parent = Section.Header,
                CornerRadius = UDim.new(0, 8, 0, 0)
            })
            
            Create("TextLabel", {
                Parent = Section.Header,
                Size = UDim2.new(1, -15, 1, 0),
                Position = UDim2.new(0, 15, 0, 0),
                BackgroundTransparency = 1,
                Text = Name or "New Section",
                TextColor3 = Window.Theme.TextColor,
                TextSize = Window.DeviceType == "Mobile" and 16 or 14,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Left
            })
            
            Section.Content = Create("Frame", {
                Parent = Section.Frame,
                Size = UDim2.new(1, 0, 0, 0),
                Position = UDim2.new(0, 0, 0, Section.Header.Size.Y.Offset),
                BackgroundTransparency = 1,
                AutomaticSize = Enum.AutomaticSize.Y
            })
            
            Create("UIListLayout", {
                Parent = Section.Content,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, Window.DeviceType == "Mobile" and 8 or 10)
            })
            
            Create("UIPadding", {
                Parent = Section.Content,
                PaddingTop = UDim.new(0, 12),
                PaddingBottom = UDim.new(0, 12),
                PaddingLeft = UDim.new(0, 12),
                PaddingRight = UDim.new(0, 12)
            })
            
            function Section:CreateButton(Text, Description, Callback)
                local Button = {}
                local elementHeight = Window.DeviceType == "Mobile" and 44 or (Description and 45 or 35)
                
                Button.Frame = Create("Frame", {
                    Parent = Section.Content,
                    Size = UDim2.new(1, 0, 0, elementHeight),
                    BackgroundColor3 = Window.Theme.SecondaryColor,
                    BorderSizePixel = 0
                })
                
                Create("UICorner", {
                    Parent = Button.Frame,
                    CornerRadius = UDim.new(0, 6)
                })
                
                Button.Button = Create("TextButton", {
                    Parent = Button.Frame,
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text = "",
                    AutoButtonColor = false
                })
                
                Button.Title = Create("TextLabel", {
                    Parent = Button.Frame,
                    Size = Description and UDim2.new(1, -10, 0.6, 0) or UDim2.new(1, -10, 1, 0),
                    Position = UDim2.new(0, 10, 0, 0),
                    BackgroundTransparency = 1,
                    Text = Text or "Button",
                    TextColor3 = Window.Theme.TextColor,
                    TextSize = Window.DeviceType == "Mobile" and 16 or 14,
                    Font = Enum.Font.Gotham,
                    TextXAlignment = Enum.TextXAlignment.Left
                })
                
                if Description then
                    Button.Description = Create("TextLabel", {
                        Parent = Button.Frame,
                        Size = UDim2.new(1, -10, 0.4, 0),
                        Position = UDim2.new(0, 10, 0.6, 0),
                        BackgroundTransparency = 1,
                        Text = Description,
                        TextColor3 = Window.Theme.TextColor,
                        TextTransparency = 0.4,
                        TextSize = Window.DeviceType == "Mobile" and 12 or 11,
                        Font = Enum.Font.Gotham,
                        TextXAlignment = Enum.TextXAlignment.Left
                    })
                end
                
                local function onHover()
                    Tween(Button.Frame, {BackgroundColor3 = Window.Theme.HoverColor}, 0.2)
                    if Window.DeviceType ~= "Mobile" then
                        Tween(Button.Frame, {Size = UDim2.new(1, 5, 0, elementHeight + 2)}, 0.2)
                    end
                end
                
                local function onHoverEnd()
                    Tween(Button.Frame, {BackgroundColor3 = Window.Theme.SecondaryColor}, 0.2)
                    if Window.DeviceType ~= "Mobile" then
                        Tween(Button.Frame, {Size = UDim2.new(1, 0, 0, elementHeight)}, 0.2)
                    end
                end
                
                Button.Connections = {}
                Button.Connections.mouseEnter = Button.Button.MouseEnter:Connect(onHover)
                Button.Connections.mouseLeave = Button.Button.MouseLeave:Connect(onHoverEnd)
                
                Button.Connections.touchTap = Button.Button.TouchTap:Connect(function()
                    pcall(function()
                        if Callback then
                            Callback()
                        end
                    end)
                end)
                
                Button.Connections.mouseClick = Button.Button.MouseButton1Click:Connect(function()
                    pcall(function()
                        if Callback then
                            Callback()
                        end
                    end)
                end)
                
                function Button:UpdateButton(NewText, NewDescription)
                    Button.Title.Text = NewText or Text
                    if NewDescription and Button.Description then
                        Button.Description.Text = NewDescription
                    end
                end
                
                function Button:SetActive(Active)
                    if Active then
                        Tween(Button.Frame, {BackgroundColor3 = Window.Theme.ActiveColor}, 0.2)
                    else
                        Tween(Button.Frame, {BackgroundColor3 = Window.Theme.SecondaryColor}, 0.2)
                    end
                end
                
                function Button:Destroy()
                    CleanupTable(Button.Connections)
                    if Button.Frame then
                        Button.Frame:Destroy()
                    end
                end
                
                table.insert(Section.Elements, Button)
                return Button
            end
            
            function Section:CreateToggle(Text, Default, Callback)
                local Toggle = {}
                local elementHeight = Window.DeviceType == "Mobile" and 44 or 35
                local isToggled = Default or false
                
                Toggle.Frame = Create("Frame", {
                    Parent = Section.Content,
                    Size = UDim2.new(1, 0, 0, elementHeight),
                    BackgroundColor3 = Window.Theme.SecondaryColor,
                    BorderSizePixel = 0
                })
                
                Create("UICorner", {
                    Parent = Toggle.Frame,
                    CornerRadius = UDim.new(0, 6)
                })
                
                Toggle.Button = Create("TextButton", {
                    Parent = Toggle.Frame,
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text = "",
                    AutoButtonColor = false
                })
                
                Toggle.Title = Create("TextLabel", {
                    Parent = Toggle.Frame,
                    Size = UDim2.new(0.7, -10, 1, 0),
                    Position = UDim2.new(0, 10, 0, 0),
                    BackgroundTransparency = 1,
                    Text = Text or "Toggle",
                    TextColor3 = Window.Theme.TextColor,
                    TextSize = Window.DeviceType == "Mobile" and 16 or 14,
                    Font = Enum.Font.Gotham,
                    TextXAlignment = Enum.TextXAlignment.Left
                })
                
                Toggle.Switch = Create("Frame", {
                    Parent = Toggle.Frame,
                    Size = UDim2.new(0, 50, 0, 25),
                    Position = UDim2.new(1, -60, 0.5, -12.5),
                    BackgroundColor3 = isToggled and Window.Theme.ActiveColor or Window.Theme.ElementColor,
                    BorderSizePixel = 0
                })
                
                Create("UICorner", {
                    Parent = Toggle.Switch,
                    CornerRadius = UDim.new(1, 0)
                })
                
                Toggle.Thumb = Create("Frame", {
                    Parent = Toggle.Switch,
                    Size = UDim2.new(0, 21, 0, 21),
                    Position = isToggled and UDim2.new(1, -23, 0.5, -10.5) or UDim2.new(0, 2, 0.5, -10.5),
                    BackgroundColor3 = Window.Theme.TextColor,
                    BorderSizePixel = 0
                })
                
                Create("UICorner", {
                    Parent = Toggle.Thumb,
                    CornerRadius = UDim.new(1, 0)
                })
                
                local function updateToggle()
                    Tween(Toggle.Switch, {BackgroundColor3 = isToggled and Window.Theme.ActiveColor or Window.Theme.ElementColor}, 0.2)
                    Tween(Toggle.Thumb, {Position = isToggled and UDim2.new(1, -23, 0.5, -10.5) or UDim2.new(0, 2, 0.5, -10.5)}, 0.2)
                    
                    pcall(function()
                        if Callback then
                            Callback(isToggled)
                        end
                    end)
                end
                
                Toggle.Connections = {}
                Toggle.Connections.click = Toggle.Button.MouseButton1Click:Connect(function()
                    isToggled = not isToggled
                    updateToggle()
                end)
                
                Toggle.Connections.touch = Toggle.Button.TouchTap:Connect(function()
                    isToggled = not isToggled
                    updateToggle()
                end)
                
                function Toggle:SetValue(Value)
                    if isToggled ~= Value then
                        isToggled = Value
                        updateToggle()
                    end
                end
                
                function Toggle:GetValue()
                    return isToggled
                end
                
                function Toggle:Destroy()
                    CleanupTable(Toggle.Connections)
                    if Toggle.Frame then
                        Toggle.Frame:Destroy()
                    end
                end
                
                table.insert(Section.Elements, Toggle)
                return Toggle
            end
            
            function Section:CreateSlider(Text, Min, Max, Default, Callback)
                local Slider = {}
                local elementHeight = Window.DeviceType == "Mobile" and 60 or 50
                local currentValue = Default or Min
                
                Slider.Frame = Create("Frame", {
                    Parent = Section.Content,
                    Size = UDim2.new(1, 0, 0, elementHeight),
                    BackgroundColor3 = Window.Theme.SecondaryColor,
                    BorderSizePixel = 0
                })
                
                Create("UICorner", {
                    Parent = Slider.Frame,
                    CornerRadius = UDim.new(0, 6)
                })
                
                Slider.Title = Create("TextLabel", {
                    Parent = Slider.Frame,
                    Size = UDim2.new(1, -20, 0, 20),
                    Position = UDim2.new(0, 10, 0, 5),
                    BackgroundTransparency = 1,
                    Text = Text or "Slider",
                    TextColor3 = Window.Theme.TextColor,
                    TextSize = Window.DeviceType == "Mobile" and 14 or 12,
                    Font = Enum.Font.Gotham,
                    TextXAlignment = Enum.TextXAlignment.Left
                })
                
                Slider.ValueLabel = Create("TextLabel", {
                    Parent = Slider.Frame,
                    Size = UDim2.new(0, 60, 0, 20),
                    Position = UDim2.new(1, -70, 0, 5),
                    BackgroundTransparency = 1,
                    Text = tostring(currentValue),
                    TextColor3 = Window.Theme.TextColor,
                    TextSize = Window.DeviceType == "Mobile" and 14 or 12,
                    Font = Enum.Font.Gotham,
                    TextXAlignment = Enum.TextXAlignment.Right
                })
                
                Slider.Track = Create("Frame", {
                    Parent = Slider.Frame,
                    Size = UDim2.new(1, -20, 0, 6),
                    Position = UDim2.new(0, 10, 1, -20),
                    BackgroundColor3 = Window.Theme.ElementColor,
                    BorderSizePixel = 0
                })
                
                Create("UICorner", {
                    Parent = Slider.Track,
                    CornerRadius = UDim.new(1, 0)
                })
                
                Slider.Progress = Create("Frame", {
                    Parent = Slider.Track,
                    Size = UDim2.new((currentValue - Min) / (Max - Min), 0, 1, 0),
                    BackgroundColor3 = Window.Theme.ActiveColor,
                    BorderSizePixel = 0
                })
                
                Create("UICorner", {
                    Parent = Slider.Progress,
                    CornerRadius = UDim.new(1, 0)
                })
                
                Slider.Thumb = Create("Frame", {
                    Parent = Slider.Track,
                    Size = UDim2.new(0, 16, 0, 16),
                    Position = UDim2.new((currentValue - Min) / (Max - Min), -8, 0.5, -8),
                    BackgroundColor3 = Window.Theme.TextColor,
                    BorderSizePixel = 0,
                    ZIndex = 2
                })
                
                Create("UICorner", {
                    Parent = Slider.Thumb,
                    CornerRadius = UDim.new(1, 0)
                })
                
                local isDragging = false
                
                local function updateSlider(value)
                    currentValue = math.clamp(value, Min, Max)
                    local percent = (currentValue - Min) / (Max - Min)
                    
                    Slider.ValueLabel.Text = tostring(math.floor(currentValue))
                    Tween(Slider.Progress, {Size = UDim2.new(percent, 0, 1, 0)}, 0.1)
                    Tween(Slider.Thumb, {Position = UDim2.new(percent, -8, 0.5, -8)}, 0.1)
                    
                    pcall(function()
                        if Callback then
                            Callback(currentValue)
                        end
                    end)
                end
                
                local function onInputChanged(input)
                    if not isDragging then return end
                    
                    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                        local absolutePos = Slider.Track.AbsolutePosition
                        local absoluteSize = Slider.Track.AbsoluteSize
                        local relativeX = (input.Position.X - absolutePos.X) / absoluteSize.X
                        local value = Min + (Max - Min) * math.clamp(relativeX, 0, 1)
                        updateSlider(value)
                    end
                end
                
                Slider.Connections = {}
                Slider.Connections.inputBegan = Slider.Thumb.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        isDragging = true
                    end
                end)
                
                Slider.Connections.inputEnded = UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        isDragging = false
                    end
                end)
                
                Slider.Connections.inputChanged = UserInputService.InputChanged:Connect(onInputChanged)
                
                function Slider:SetValue(Value)
                    updateSlider(Value)
                end
                
                function Slider:GetValue()
                    return currentValue
                end
                
                function Slider:Destroy()
                    CleanupTable(Slider.Connections)
                    if Slider.Frame then
                        Slider.Frame:Destroy()
                    end
                end
                
                table.insert(Section.Elements, Slider)
                return Slider
            end
            
            function Section:CreateDropdown(Text, Options, Default, Callback)
                local Dropdown = {}
                local elementHeight = Window.DeviceType == "Mobile" and 44 or 35
                local isOpen = false
                local selectedOption = Default or (Options and Options[1]) or nil
                
                Dropdown.Frame = Create("Frame", {
                    Parent = Section.Content,
                    Size = UDim2.new(1, 0, 0, elementHeight),
                    BackgroundColor3 = Window.Theme.SecondaryColor,
                    BorderSizePixel = 0,
                    ClipsDescendants = true
                })
                
                Create("UICorner", {
                    Parent = Dropdown.Frame,
                    CornerRadius = UDim.new(0, 6)
                })
                
                Dropdown.Button = Create("TextButton", {
                    Parent = Dropdown.Frame,
                    Size = UDim2.new(1, 0, 0, elementHeight),
                    BackgroundTransparency = 1,
                    Text = "",
                    AutoButtonColor = false
                })
                
                Dropdown.Title = Create("TextLabel", {
                    Parent = Dropdown.Frame,
                    Size = UDim2.new(0.7, -10, 1, 0),
                    Position = UDim2.new(0, 10, 0, 0),
                    BackgroundTransparency = 1,
                    Text = Text or "Dropdown",
                    TextColor3 = Window.Theme.TextColor,
                    TextSize = Window.DeviceType == "Mobile" and 16 or 14,
                    Font = Enum.Font.Gotham,
                    TextXAlignment = Enum.TextXAlignment.Left
                })
                
                Dropdown.Selected = Create("TextLabel", {
                    Parent = Dropdown.Frame,
                    Size = UDim2.new(0.3, -30, 1, 0),
                    Position = UDim2.new(0.7, 0, 0, 0),
                    BackgroundTransparency = 1,
                    Text = selectedOption or "Select",
                    TextColor3 = Window.Theme.TextColor,
                    TextTransparency = 0.5,
                    TextSize = Window.DeviceType == "Mobile" and 14 or 12,
                    Font = Enum.Font.Gotham,
                    TextXAlignment = Enum.TextXAlignment.Right
                })
                
                Dropdown.Arrow = Create("TextLabel", {
                    Parent = Dropdown.Frame,
                    Size = UDim2.new(0, 20, 0, 20),
                    Position = UDim2.new(1, -25, 0.5, -10),
                    BackgroundTransparency = 1,
                    Text = "▼",
                    TextColor3 = Window.Theme.TextColor,
                    TextSize = 12,
                    Font = Enum.Font.Gotham,
                    TextXAlignment = Enum.TextXAlignment.Center
                })
                
                Dropdown.OptionsFrame = Create("Frame", {
                    Parent = Dropdown.Frame,
                    Size = UDim2.new(1, 0, 0, 0),
                    Position = UDim2.new(0, 0, 1, 5),
                    BackgroundColor3 = Window.Theme.ElementColor,
                    BorderSizePixel = 0,
                    Visible = false,
                    ClipsDescendants = true
                })
                
                Create("UICorner", {
                    Parent = Dropdown.OptionsFrame,
                    CornerRadius = UDim.new(0, 6)
                })
                
                local OptionsLayout = Create("UIListLayout", {
                    Parent = Dropdown.OptionsFrame,
                    SortOrder = Enum.SortOrder.LayoutOrder
                })
                
                local function toggleDropdown()
                    isOpen = not isOpen
                    
                    if isOpen then
                        Dropdown.OptionsFrame.Visible = true
                        Tween(Dropdown.Arrow, {Rotation = 180}, 0.2)
                        Tween(Dropdown.OptionsFrame, {Size = UDim2.new(1, 0, 0, math.min(#Options * 35, 175))}, 0.2)
                    else
                        Tween(Dropdown.Arrow, {Rotation = 0}, 0.2)
                        Tween(Dropdown.OptionsFrame, {Size = UDim2.new(1, 0, 0, 0)}, 0.2)
                        wait(0.2)
                        Dropdown.OptionsFrame.Visible = false
                    end
                end
                
                local function selectOption(option)
                    selectedOption = option
                    Dropdown.Selected.Text = option
                    toggleDropdown()
                    
                    pcall(function()
                        if Callback then
                            Callback(option)
                        end
                    end)
                end
                
                if Options then
                    for i, option in ipairs(Options) do
                        local OptionButton = Create("TextButton", {
                            Parent = Dropdown.OptionsFrame,
                            Size = UDim2.new(1, 0, 0, 35),
                            BackgroundColor3 = Window.Theme.ElementColor,
                            BorderSizePixel = 0,
                            Text = option,
                            TextColor3 = Window.Theme.TextColor,
                            TextSize = Window.DeviceType == "Mobile" and 14 or 12,
                            Font = Enum.Font.Gotham,
                            AutoButtonColor = false
                        })
                        
                        OptionButton.MouseEnter:Connect(function()
                            Tween(OptionButton, {BackgroundColor3 = Window.Theme.HoverColor}, 0.2)
                        end)
                        
                        OptionButton.MouseLeave:Connect(function()
                            Tween(OptionButton, {BackgroundColor3 = Window.Theme.ElementColor}, 0.2)
                        end)
                        
                        OptionButton.MouseButton1Click:Connect(function()
                            selectOption(option)
                        end)
                    end
                end
                
                Dropdown.Connections = {}
                Dropdown.Connections.click = Dropdown.Button.MouseButton1Click:Connect(toggleDropdown)
                Dropdown.Connections.touch = Dropdown.Button.TouchTap:Connect(toggleDropdown)
                
                function Dropdown:SetOptions(NewOptions)
                    Options = NewOptions
                    Dropdown.OptionsFrame:ClearAllChildren()
                    
                    if NewOptions then
                        for i, option in ipairs(NewOptions) do
                            local OptionButton = Create("TextButton", {
                                Parent = Dropdown.OptionsFrame,
                                Size = UDim2.new(1, 0, 0, 35),
                                BackgroundColor3 = Window.Theme.ElementColor,
                                BorderSizePixel = 0,
                                Text = option,
                                TextColor3 = Window.Theme.TextColor,
                                TextSize = Window.DeviceType == "Mobile" and 14 or 12,
                                Font = Enum.Font.Gotham,
                                AutoButtonColor = false
                            })
                            
                            OptionButton.MouseButton1Click:Connect(function()
                                selectOption(option)
                            end)
                        end
                    end
                end
                
                function Dropdown:SetSelected(Option)
                    if table.find(Options, Option) then
                        selectedOption = Option
                        Dropdown.Selected.Text = Option
                    end
                end
                
                function Dropdown:GetSelected()
                    return selectedOption
                end
                
                function Dropdown:Destroy()
                    CleanupTable(Dropdown.Connections)
                    if Dropdown.Frame then
                        Dropdown.Frame:Destroy()
                    end
                end
                
                table.insert(Section.Elements, Dropdown)
                return Dropdown
            end
            
            function Section:CreateInput(Text, Placeholder, Callback)
                local Input = {}
                local elementHeight = Window.DeviceType == "Mobile" and 44 or 35
                
                Input.Frame = Create("Frame", {
                    Parent = Section.Content,
                    Size = UDim2.new(1, 0, 0, elementHeight),
                    BackgroundColor3 = Window.Theme.SecondaryColor,
                    BorderSizePixel = 0
                })
                
                Create("UICorner", {
                    Parent = Input.Frame,
                    CornerRadius = UDim.new(0, 6)
                })
                
                if Text then
                    Input.Title = Create("TextLabel", {
                        Parent = Input.Frame,
                        Size = UDim2.new(0.3, -10, 1, 0),
                        Position = UDim2.new(0, 10, 0, 0),
                        BackgroundTransparency = 1,
                        Text = Text,
                        TextColor3 = Window.Theme.TextColor,
                        TextSize = Window.DeviceType == "Mobile" and 14 or 12,
                        Font = Enum.Font.Gotham,
                        TextXAlignment = Enum.TextXAlignment.Left
                    })
                end
                
                Input.TextBox = Create("TextBox", {
                    Parent = Input.Frame,
                    Size = Text and UDim2.new(0.7, -10, 1, 0) or UDim2.new(1, -20, 1, 0),
                    Position = Text and UDim2.new(0.3, 0, 0, 0) or UDim2.new(0, 10, 0, 0),
                    BackgroundTransparency = 1,
                    Text = "",
                    PlaceholderText = Placeholder or "Type here...",
                    TextColor3 = Window.Theme.TextColor,
                    PlaceholderColor3 = Color3.new(1, 1, 1),
                    TextTransparency = 0.3,
                    TextSize = Window.DeviceType == "Mobile" and 14 or 12,
                    Font = Enum.Font.Gotham,
                    TextXAlignment = Text and Enum.TextXAlignment.Left or Enum.TextXAlignment.Center,
                    ClearTextOnFocus = false
                })
                
                Input.Connections = {}
                Input.Connections.focusLost = Input.TextBox.FocusLost:Connect(function(enterPressed)
                    if enterPressed then
                        pcall(function()
                            if Callback then
                                Callback(Input.TextBox.Text)
                            end
                        end)
                    end
                end)
                
                function Input:SetText(Text)
                    Input.TextBox.Text = Text or ""
                end
                
                function Input:GetText()
                    return Input.TextBox.Text
                end
                
                function Input:Destroy()
                    CleanupTable(Input.Connections)
                    if Input.Frame then
                        Input.Frame:Destroy()
                    end
                end
                
                table.insert(Section.Elements, Input)
                return Input
            end
            
            function Section:CreateLabel(Text, TextSize)
                local Label = {}
                
                Label.Frame = Create("Frame", {
                    Parent = Section.Content,
                    Size = UDim2.new(1, 0, 0, TextSize or 30),
                    BackgroundTransparency = 1
                })
                
                Label.TextLabel = Create("TextLabel", {
                    Parent = Label.Frame,
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text = Text or "Label",
                    TextColor3 = Window.Theme.TextColor,
                    TextSize = TextSize or (Window.DeviceType == "Mobile" and 14 or 12),
                    Font = Enum.Font.Gotham,
                    TextXAlignment = Enum.TextXAlignment.Left
                })
                
                function Label:SetText(NewText)
                    Label.TextLabel.Text = NewText or Text
                end
                
                function Label:Destroy()
                    if Label.Frame then
                        Label.Frame:Destroy()
                    end
                end
                
                table.insert(Section.Elements, Label)
                return Label
            end
            
            function Section:Destroy()
                for _, element in ipairs(Section.Elements) do
                    if element.Destroy then
                        element:Destroy()
                    end
                end
                CleanupTable(Section.Connections)
                if Section.Frame then
                    Section.Frame:Destroy()
                end
            end
            
            table.insert(Tab.Sections, Section)
            return Section
        end
        
        function Tab:Destroy()
            for _, section in ipairs(Tab.Sections) do
                if section.Destroy then
                    section:Destroy()
                end
            end
            CleanupTable(Tab.Connections)
            if Tab.Frame then
                Tab.Frame:Destroy()
            end
            if Tab.Button then
                Tab.Button:Destroy()
            end
        end
        
        table.insert(Window.Tabs, Tab)
        
        if #Window.Tabs == 1 then
            Window:SwitchTab(Tab)
        end
        
        return Tab
    end
    
    function Window:SwitchTab(NewTab)
        if Window.CurrentTab then
            Window.CurrentTab.Visible = false
            Window.CurrentTab.Frame.Visible = false
            if Window.CurrentTab.Button then
                Tween(Window.CurrentTab.Button, {BackgroundColor3 = Window.Theme.ElementColor}, 0.2)
            end
        end
        
        Window.CurrentTab = NewTab
        NewTab.Visible = true
        NewTab.Frame.Visible = true
        if NewTab.Button then
            Tween(NewTab.Button, {BackgroundColor3 = Window.Theme.ActiveColor}, 0.2)
        end
    end
    
    function Window:SetThemeColors(Colors)
        if Colors then
            Window.Theme = Colors
            Window.MainFrame.BackgroundColor3 = Colors.Background
            Window.Header.BackgroundColor3 = Colors.Header
            if Window.TabContainer then
                Window.TabContainer.BackgroundColor3 = Colors.SecondaryColor
            end
            Window.NeonBorder.BackgroundColor3 = Colors.SchemeColor
        end
    end
    
    function Window:Toggle()
        Window.Open = not Window.Open
        if Window.Open then
            Window.MainFrame.Visible = true
            Tween(Window.MainFrame, {Size = Window.MainFrame.Size}, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        else
            Tween(Window.MainFrame, {Size = UDim2.new(0, 0, 0, 0)}, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In)
            wait(0.3)
            Window.MainFrame.Visible = false
        end
    end
    
    function Window:BindKey(Key, Callback, Options)
        local keybind = KeybindSystem:RegisterKeybind(Key, Callback, Options)
        Window.Keybinds[Key] = keybind
        return keybind
    end
    
    function Window:UnbindKey(Key)
        KeybindSystem:UnregisterKeybind(Key)
        Window.Keybinds[Key] = nil
    end
    
    function Window:SaveConfig()
        local configData = {
            Position = {Window.MainFrame.Position.X.Scale, Window.MainFrame.Position.X.Offset, Window.MainFrame.Position.Y.Scale, Window.MainFrame.Position.Y.Offset},
            Size = {Window.MainFrame.Size.X.Scale, Window.MainFrame.Size.X.Offset, Window.MainFrame.Size.Y.Scale, Window.MainFrame.Size.Y.Offset},
            Open = Window.Open,
            CurrentTab = Window.CurrentTab and Window.CurrentTab.Title or nil
        }
        
        return ConfigSystem:SaveConfig(Window.Config.Name, configData)
    end
    
    function Window:LoadConfig()
        local configData = ConfigSystem:LoadConfig(Window.Config.Name)
        if configData then
            if configData.Position then
                Window.MainFrame.Position = UDim2.new(configData.Position[1], configData.Position[2], configData.Position[3], configData.Position[4])
            end
            if configData.Size then
                Window.MainFrame.Size = UDim2.new(configData.Size[1], configData.Size[2], configData.Size[3], configData.Size[4])
            end
            if configData.Open ~= nil then
                Window.Open = configData.Open
                Window.MainFrame.Visible = Window.Open
            end
            return true
        end
        return false
    end
    
    function Window:DeleteConfig()
        return ConfigSystem:DeleteConfig(Window.Config.Name)
    end
    
    if Window.Config.AutoSave then
        Window.Connections.autoSave = Window.MainFrame:GetPropertyChangedSignal("Position"):Connect(function()
            Window:SaveConfig()
        end)
    end
    
    function Window:Destroy()
        CleanupTable(Window.Connections)
        
        if Window.DragData then
            CleanupTable(Window.DragData.Connections)
        end
        
        for key, keybind in pairs(Window.Keybinds) do
            KeybindSystem:UnregisterKeybind(key)
        end
        table.clear(Window.Keybinds)
        
        for _, tab in ipairs(Window.Tabs) do
            if tab.Destroy then
                tab:Destroy()
            end
        end
        table.clear(Window.Tabs)
        
        if Window.ScreenGui then
            Window.ScreenGui:Destroy()
        end
    end
    
    if Window.Config.AutoSave then
        Window:LoadConfig()
    end
    
    return Window
end

function NebulaUI:Notify(Title, Message, Duration, Type)
    Duration = Duration or 5
    Type = Type or "Info"
    
    local deviceType = GetDeviceType()
    local notificationWidth = deviceType == "Mobile" and UDim2.new(0.9, 0) or UDim2.new(0, 350)
    
    if not self.NotificationContainer then
        self.NotificationContainer = Create("Frame", {
            Parent = self.ScreenGui or CoreGui,
            Size = deviceType == "Mobile" and UDim2.new(1, -40, 1, -20) or UDim2.new(0, 350, 1, -20),
            Position = deviceType == "Mobile" and UDim2.new(0.5, 0, 0, 20) or UDim2.new(1, -370, 0, 20),
            BackgroundTransparency = 1,
            ZIndex = 100
        })
        
        Create("UIListLayout", {
            Parent = self.NotificationContainer,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 10)
        })
    end
    
    local notification = Create("Frame", {
        Parent = self.NotificationContainer,
        Size = notificationWidth,
        BackgroundColor3 = Themes.GalacticDark.ElementColor,
        BorderSizePixel = 0,
        LayoutOrder = #self.NotificationContainer:GetChildren()
    })
    
    Create("UICorner", {
        Parent = notification,
        CornerRadius = UDim.new(0, 8)
    })
    
    AddGlowEffect(notification, Themes.GalacticDark.SchemeColor)
    
    local titleLabel = Create("TextLabel", {
        Parent = notification,
        Size = UDim2.new(1, -20, 0, 25),
        Position = UDim2.new(0, 10, 0, 10),
        BackgroundTransparency = 1,
        Text = Title or "Notification",
        TextColor3 = Themes.GalacticDark.TextColor,
        TextSize = 16,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    local messageLabel = Create("TextLabel", {
        Parent = notification,
        Size = UDim2.new(1, -20, 0, 0),
        Position = UDim2.new(0, 10, 0, 40),
        BackgroundTransparency = 1,
        Text = Message or "",
        TextColor3 = Themes.GalacticDark.TextColor,
        TextTransparency = 0.3,
        TextSize = 14,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        AutomaticSize = Enum.AutomaticSize.Y
    })
    
    local textSize = TextService:GetTextSize(Message or "", 14, Enum.Font.Gotham, notificationWidth)
    notification.Size = UDim2.new(notification.Size.X.Scale, notification.Size.X.Offset, 0, math.max(80, textSize.Y + 60))
    
    delay(Duration, function()
        if notification and notification.Parent then
            Tween(notification, {Size = UDim2.new(notification.Size.X.Scale, notification.Size.X.Offset, 0, 0)}, 0.3)
            wait(0.3)
            notification:Destroy()
        end
    end)
    
    return notification
end

function NebulaUI:GetThemes()
    return Themes
end

function NebulaUI:AddTheme(Name, ThemeData)
    if not Themes[Name] then
        Themes[Name] = ThemeData
        return true
    end
    return false
end

function NebulaUI:GetPerformanceStats()
    return {
        FPS = Performance.FPS,
        MemoryUsage = Performance.MemoryUsage
    }
end

function NebulaUI:GetDeviceInfo()
    return {
        Type = GetDeviceType(),
        ViewportSize = workspace.CurrentCamera.ViewportSize,
        AspectRatio = workspace.CurrentCamera.ViewportSize.X / workspace.CurrentCamera.ViewportSize.Y
    }
end

function NebulaUI:CreateLoader(windowName)
    return LoadingSystem:CreateLoader(windowName)
end

function NebulaUI:LoadFromGitHub(user, repo, branch, filePath)
    return GitHubSupport:LoadFromGitHub(user, repo, branch, filePath)
end

function NebulaUI:LoadLibraryFromGitHub(user, repo, branch, filePath)
    return GitHubSupport:LoadLibrary(user, repo, branch, filePath)
end

function NebulaUI:GetMemoryStats()
    return {
        Allocations = table.count(MemoryManager.AllocationTracker),
        PeakUsage = MemoryManager.PeakUsage,
        CurrentUsage = collectgarbage("count")
    }
end

function NebulaUI:Cleanup()
    KeybindSystem:Cleanup()
    CleanupTable(Performance.Connections)
    
    for _, pool in pairs(UIPool) do
        for _, obj in pairs(pool) do
            if obj and obj.Destroy then
                obj:Destroy()
            end
        end
        table.clear(pool)
    end
    
    MemoryManager:DetectLeaks()
    MemoryManager:OptimizeGC()
end

game:BindToClose(function()
    NebulaUI:Cleanup()
end)

return NebulaUi
