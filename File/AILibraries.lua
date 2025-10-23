-- AI Libraries - Futuristic Roblox UI Framework
-- Main Module: AI.lua

local AI = {}
AI.__index = AI
AI.Version = "1.0.0"

-- Services
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

-- Local Variables
local player = Players.LocalPlayer
local mouse = player:GetMouse()
local themeManager = {}
local tweenManager = {}
local layoutManager = {}
local configManager = {}

-- Default Configuration
local defaultConfig = {
	theme = "AIDark",
	animationSpeed = 1,
	savePosition = true,
	windowSize = {400, 500}
}

-- Theme Definitions
local themes = {
	AIDark = {
		Primary = Color3.fromHex("#11111a"),
		Secondary = Color3.fromHex("#1b1b27"),
		Accent = Color3.fromHex("#3c4cf1"),
		AccentSecondary = Color3.fromHex("#8f9aff"),
		Text = Color3.fromHex("#e2e3f0"),
		Success = Color3.fromHex("#4cf13c"),
		Warning = Color3.fromHex("#f1a13c"),
		Error = Color3.fromHex("#f13c4c")
	},
	AILight = {
		Primary = Color3.fromHex("#f0f0f5"),
		Secondary = Color3.fromHex("#ffffff"),
		Accent = Color3.fromHex("#3c4cf1"),
		AccentSecondary = Color3.fromHex("#5c6cff"),
		Text = Color3.fromHex("#1b1b27"),
		Success = Color3.fromHex("#2aa22a"),
		Warning = Color3.fromHex("#ffaa00"),
		Error = Color3.fromHex("#ff4444")
	},
	CyberBlue = {
		Primary = Color3.fromHex("#0a0a12"),
		Secondary = Color3.fromHex("#151525"),
		Accent = Color3.fromHex("#00eeff"),
		AccentSecondary = Color3.fromHex("#0088ff"),
		Text = Color3.fromHex("#e0f0ff"),
		Success = Color3.fromHex("#00ff88"),
		Warning = Color3.fromHex("#ffcc00"),
		Error = Color3.fromHex("#ff0066")
	}
}

-- Tween Manager
function tweenManager.CreateTween(object, properties, duration, easingStyle, easingDirection)
	local tweenInfo = TweenInfo.new(
		duration or 0.3,
		easingStyle or Enum.EasingStyle.Quad,
		easingDirection or Enum.EasingDirection.Out
	)
	
	local tween = TweenService:Create(object, tweenInfo, properties)
	tween:Play()
	return tween
end

-- Theme Manager
function themeManager.GetCurrentTheme()
	return themes[configManager.currentConfig.theme] or themes.AIDark
end

function themeManager.ApplyTheme(element, elementType)
	local theme = themeManager.GetCurrentTheme()
	
	if elementType == "Window" then
		element.BackgroundColor3 = theme.Primary
	elseif elementType == "Panel" then
		element.BackgroundColor3 = theme.Secondary
	elseif elementType == "Button" then
		element.BackgroundColor3 = theme.Accent
		if element:FindFirstChild("TextLabel") then
			element.TextLabel.TextColor3 = theme.Text
		end
	elseif elementType == "Text" then
		element.TextColor3 = theme.Text
	end
	
	-- Apply rounded corners if not present
	if not element:FindFirstChildOfClass("UICorner") then
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 10)
		corner.Parent = element
	end
	
	-- Apply stroke if not present
	if not element:FindFirstChildOfClass("UIStroke") then
		local stroke = Instance.new("UIStroke")
		stroke.Color = theme.AccentSecondary
		stroke.Thickness = 1
		stroke.Parent = element
	end
end

-- Layout Manager
function layoutManager.ArrangeElements(parent)
	local elements = {}
	for _, child in ipairs(parent:GetChildren()) do
		if child:IsA("Frame") or child:IsA("TextButton") then
			if child.LayoutOrder ~= 0 then
				table.insert(elements, child)
			end
		end
	end
	
	table.sort(elements, function(a, b)
		return a.LayoutOrder < b.LayoutOrder
	end)
	
	local padding = 10
	local currentY = padding
	
	for _, element in ipairs(elements) do
		element.Position = UDim2.new(0, padding, 0, currentY)
		currentY = currentY + element.AbsoluteSize.Y + padding
	end
end

-- Config Manager
function configManager.LoadConfig()
	-- In a real implementation, this would load from datastore
	-- For now, we'll use default config
	configManager.currentConfig = defaultConfig
end

function configManager.SaveConfig()
	-- In a real implementation, this would save to datastore
	-- For now, we'll just keep in memory
end

-- Notification System
local notificationQueue = {}
local isShowingNotification = false

local function showNextNotification()
	if isShowingNotification or #notificationQueue == 0 then return end
	
	isShowingNotification = true
	local notification = table.remove(notificationQueue, 1)
	
	-- Create notification frame
	local notificationFrame = Instance.new("Frame")
	notificationFrame.Size = UDim2.new(0, 300, 0, 80)
	notificationFrame.Position = UDim2.new(1, 320, 1, -100)
	notificationFrame.AnchorPoint = Vector2.new(1, 1)
	notificationFrame.BackgroundColor3 = themeManager.GetCurrentTheme().Secondary
	notificationFrame.BorderSizePixel = 0
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = notificationFrame
	
	local stroke = Instance.new("UIStroke")
	stroke.Color = themeManager.GetCurrentTheme().Accent
	stroke.Thickness = 2
	stroke.Parent = notificationFrame
	
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -20, 0, 25)
	title.Position = UDim2.new(0, 10, 0, 10)
	title.BackgroundTransparency = 1
	title.Text = notification.title
	title.TextColor3 = themeManager.GetCurrentTheme().Text
	title.TextScaled = true
	title.Font = Enum.Font.GothamBold
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = notificationFrame
	
	local message = Instance.new("TextLabel")
	message.Size = UDim2.new(1, -20, 1, -45)
	message.Position = UDim2.new(0, 10, 0, 35)
	message.BackgroundTransparency = 1
	message.Text = notification.message
	message.TextColor3 = themeManager.GetCurrentTheme().Text
	message.TextScaled = true
	message.Font = Enum.Font.Gotham
	message.TextXAlignment = Enum.TextXAlignment.Left
	message.TextYAlignment = Enum.TextYAlignment.Top
	message.Parent = notificationFrame
	
	-- Color based on type
	if notification.type == "success" then
		stroke.Color = themeManager.GetCurrentTheme().Success
	elseif notification.type == "warning" then
		stroke.Color = themeManager.GetCurrentTheme().Warning
	elseif notification.type == "error" then
		stroke.Color = themeManager.GetCurrentTheme().Error
	end
	
	notificationFrame.Parent = player.PlayerGui:FindFirstChild("AILibrariesUI") or Instance.new("ScreenGui")
	
	-- Animation
	notificationFrame.Position = UDim2.new(1, 320, 1, -100)
	tweenManager.CreateTween(notificationFrame, {Position = UDim2.new(1, -20, 1, -100)}, 0.5)
	
	wait(notification.duration or 3)
	
	tweenManager.CreateTween(notificationFrame, {Position = UDim2.new(1, 320, 1, -100)}, 0.5)
	wait(0.5)
	notificationFrame:Destroy()
	isShowingNotification = false
	
	-- Show next notification
	showNextNotification()
end

-- Main API Functions
function AI.CreateWindow(options)
	options = options or {}
	local window = {}
	
	-- Create main GUI
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "AILibrariesUI"
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = player.PlayerGui
	
	-- Main window frame
	local mainFrame = Instance.new("Frame")
	mainFrame.Size = UDim2.new(0, options.width or 500, 0, options.height or 400)
	mainFrame.Position = UDim2.new(0.5, -250, 0.5, -200)
	mainFrame.BackgroundColor3 = themeManager.GetCurrentTheme().Primary
	mainFrame.BorderSizePixel = 0
	mainFrame.ClipsDescendants = true
	mainFrame.Parent = screenGui
	
	themeManager.ApplyTheme(mainFrame, "Window")
	
	-- Title bar
	local titleBar = Instance.new("Frame")
	titleBar.Size = UDim2.new(1, 0, 0, 40)
	titleBar.BackgroundColor3 = themeManager.GetCurrentTheme().Secondary
	titleBar.BorderSizePixel = 0
	titleBar.Parent = mainFrame
	
	themeManager.ApplyTheme(titleBar, "Panel")
	
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -80, 1, 0)
	title.Position = UDim2.new(0, 15, 0, 0)
	title.BackgroundTransparency = 1
	title.Text = options.title or "AI Libraries"
	title.TextColor3 = themeManager.GetCurrentTheme().Text
	title.TextScaled = true
	title.Font = Enum.Font.GothamBold
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = titleBar
	
	-- Close button
	local closeButton = Instance.new("TextButton")
	closeButton.Size = UDim2.new(0, 30, 0, 30)
	closeButton.Position = UDim2.new(1, -40, 0, 5)
	closeButton.BackgroundColor3 = themeManager.GetCurrentTheme().Error
	closeButton.Text = "X"
	closeButton.TextColor3 = themeManager.GetCurrentTheme().Text
	closeButton.TextScaled = true
	closeButton.Font = Enum.Font.GothamBold
	closeButton.Parent = titleBar
	
	themeManager.ApplyTheme(closeButton, "Button")
	
	-- Container for sidebar and content
	local container = Instance.new("Frame")
	container.Size = UDim2.new(1, 0, 1, -40)
	container.Position = UDim2.new(0, 0, 0, 40)
	container.BackgroundTransparency = 1
	container.Parent = mainFrame
	
	-- Sidebar for tabs
	local sidebar = Instance.new("Frame")
	sidebar.Size = UDim2.new(0, 120, 1, 0)
	sidebar.BackgroundColor3 = themeManager.GetCurrentTheme().Secondary
	sidebar.BorderSizePixel = 0
	sidebar.Parent = container
	
	themeManager.ApplyTheme(sidebar, "Panel")
	
	-- Content area
	local contentArea = Instance.new("Frame")
	contentArea.Size = UDim2.new(1, -120, 1, 0)
	contentArea.Position = UDim2.new(0, 120, 0, 0)
	contentArea.BackgroundTransparency = 1
	contentArea.ClipsDescendants = true
	contentArea.Parent = container
	
	-- Make window draggable
	local dragging = false
	local dragInput, dragStart, startPos
	
	titleBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStart = input.Position
			startPos = mainFrame.Position
			
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)
	
	titleBar.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			dragInput = input
		end
	end)
	
	UserInputService.InputChanged:Connect(function(input)
		if dragging and input == dragInput then
			local delta = input.Position - dragStart
			mainFrame.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + delta.X,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y
			)
		end
	end)
	
	-- Close button functionality
	closeButton.MouseButton1Click:Connect(function()
		tweenManager.CreateTween(mainFrame, {Size = UDim2.new(0, 0, 0, 0)}, 0.3)
		wait(0.3)
		screenGui:Destroy()
	end)
	
	-- Window methods
	window.gui = screenGui
	window.mainFrame = mainFrame
	window.sidebar = sidebar
	window.contentArea = contentArea
	window.tabs = {}
	window.currentTab = nil
	
	function window:AddTab(tabName)
		local tab = {}
		
		-- Tab button
		local tabButton = Instance.new("TextButton")
		tabButton.Size = UDim2.new(1, -10, 0, 40)
		tabButton.Position = UDim2.new(0, 5, 0, 10 + (#self.tabs * 45))
		tabButton.BackgroundColor3 = themeManager.GetCurrentTheme().Secondary
		tabButton.Text = ""
		tabButton.AutoButtonColor = false
		tabButton.Parent = self.sidebar
		
		themeManager.ApplyTheme(tabButton, "Panel")
		
		local tabText = Instance.new("TextLabel")
		tabText.Size = UDim2.new(1, 0, 1, 0)
		tabText.BackgroundTransparency = 1
		tabText.Text = tabName
		tabText.TextColor3 = themeManager.GetCurrentTheme().Text
		tabText.TextScaled = true
		tabText.Font = Enum.Font.Gotham
		tabText.Parent = tabButton
		
		-- Tab content
		local tabContent = Instance.new("ScrollingFrame")
		tabContent.Size = UDim2.new(1, 0, 1, 0)
		tabContent.Position = UDim2.new(1, 0, 0, 0)
		tabContent.BackgroundTransparency = 1
		tabContent.ScrollBarThickness = 4
		tabContent.ScrollBarImageColor3 = themeManager.GetCurrentTheme().Accent
		tabContent.Visible = false
		tabContent.AutomaticCanvasSize = Enum.AutomaticSize.Y
		tabContent.Parent = self.contentArea
		
		local layout = Instance.new("UIListLayout")
		layout.Padding = UDim.new(0, 10)
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Parent = tabContent
		
		-- Tab functionality
		tabButton.MouseButton1Click:Connect(function()
			if self.currentTab then
				self.currentTab.content.Visible = false
				tweenManager.CreateTween(self.currentTab.button, {BackgroundColor3 = themeManager.GetCurrentTheme().Secondary}, 0.2)
			end
			
			self.currentTab = tab
			tab.content.Visible = true
			tweenManager.CreateTween(tabButton, {BackgroundColor3 = themeManager.GetCurrentTheme().Accent}, 0.2)
			
			-- Animate content slide
			tab.content.Position = UDim2.new(1, 0, 0, 0)
			tweenManager.CreateTween(tab.content, {Position = UDim2.new(0, 0, 0, 0)}, 0.3)
		end)
		
		-- Set as first tab if none selected
		if #self.tabs == 0 then
			self.currentTab = tab
			tab.content.Visible = true
			tab.content.Position = UDim2.new(0, 0, 0, 0)
			tweenManager.CreateTween(tabButton, {BackgroundColor3 = themeManager.GetCurrentTheme().Accent}, 0.2)
		end
		
		tab.name = tabName
		tab.button = tabButton
		tab.content = tabContent
		table.insert(self.tabs, tab)
		
		return tab
	end
	
	-- Initial animation
	mainFrame.Size = UDim2.new(0, 0, 0, 0)
	tweenManager.CreateTween(mainFrame, {
		Size = UDim2.new(0, options.width or 500, 0, options.height or 400)
	}, 0.5)
	
	return window
end

function AI.CreateButton(parent, options)
	options = options or {}
	
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(1, -20, 0, 40)
	button.Position = UDim2.new(0, 10, 0, 10)
	button.BackgroundColor3 = themeManager.GetCurrentTheme().Accent
	button.Text = options.text or "Button"
	button.TextColor3 = themeManager.GetCurrentTheme().Text
	button.TextScaled = true
	button.Font = Enum.Font.GothamBold
	button.AutoButtonColor = false
	button.LayoutOrder = options.layoutOrder or 1
	button.Parent = parent
	
	themeManager.ApplyTheme(button, "Button")
	
	-- Hover effects
	button.MouseEnter:Connect(function()
		tweenManager.CreateTween(button, {BackgroundColor3 = themeManager.GetCurrentTheme().AccentSecondary}, 0.2)
	end)
	
	button.MouseLeave:Connect(function()
		tweenManager.CreateTween(button, {BackgroundColor3 = themeManager.GetCurrentTheme().Accent}, 0.2)
	end)
	
	-- Click animation
	button.MouseButton1Down:Connect(function()
		tweenManager.CreateTween(button, {Size = UDim2.new(1, -25, 0, 35)}, 0.1)
	end)
	
	button.MouseButton1Up:Connect(function()
		tweenManager.CreateTween(button, {Size = UDim2.new(1, -20, 0, 40)}, 0.1)
	end)
	
	-- Connect callback
	if options.callback and type(options.callback) == "function" then
		button.MouseButton1Click:Connect(options.callback)
	end
	
	return button
end

function AI.CreateToggle(parent, options)
	options = options or {}
	
	local toggle = Instance.new("Frame")
	toggle.Size = UDim2.new(1, -20, 0, 40)
	toggle.BackgroundTransparency = 1
	toggle.LayoutOrder = options.layoutOrder or 1
	toggle.Parent = parent
	
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0.7, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = options.text or "Toggle"
	label.TextColor3 = themeManager.GetCurrentTheme().Text
	label.TextScaled = true
	label.Font = Enum.Font.Gotham
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = toggle
	
	local toggleBackground = Instance.new("Frame")
	toggleBackground.Size = UDim2.new(0, 60, 0, 30)
	toggleBackground.Position = UDim2.new(1, -60, 0.5, -15)
	toggleBackground.BackgroundColor3 = themeManager.GetCurrentTheme().Secondary
	toggleBackground.Parent = toggle
	
	themeManager.ApplyTheme(toggleBackground, "Panel")
	
	local toggleKnob = Instance.new("Frame")
	toggleKnob.Size = UDim2.new(0, 24, 0, 24)
	toggleKnob.Position = UDim2.new(0, 3, 0.5, -12)
	toggleKnob.BackgroundColor3 = themeManager.GetCurrentTheme().Text
	toggleKnob.Parent = toggleBackground
	
	themeManager.ApplyTheme(toggleKnob, "Button")
	
	local state = options.default or false
	
	local function updateToggle()
		if state then
			tweenManager.CreateTween(toggleKnob, {Position = UDim2.new(1, -27, 0.5, -12)}, 0.2)
			tweenManager.CreateTween(toggleBackground, {BackgroundColor3 = themeManager.GetCurrentTheme().Accent}, 0.2)
		else
			tweenManager.CreateTween(toggleKnob, {Position = UDim2.new(0, 3, 0.5, -12)}, 0.2)
			tweenManager.CreateTween(toggleBackground, {BackgroundColor3 = themeManager.GetCurrentTheme().Secondary}, 0.2)
		end
	end
	
	toggleBackground.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			state = not state
			updateToggle()
			
			if options.callback and type(options.callback) == "function" then
				options.callback(state)
			end
		end
	end)
	
	updateToggle()
	
	return toggle
end

function AI.Notify(title, message, type, duration)
	table.insert(notificationQueue, {
		title = title or "Notification",
		message = message or "",
		type = type or "info",
		duration = duration or 3
	})
	
	showNextNotification()
end

function AI.SetTheme(themeName)
	if themes[themeName] then
		configManager.currentConfig.theme = themeName
		configManager.SaveConfig()
		
		-- In a full implementation, this would update all existing UI elements
		AI.Notify("Theme Changed", "Switched to " .. themeName .. " theme", "success")
	else
		AI.Notify("Theme Error", "Theme '" .. themeName .. "' not found", "error")
	end
end

function AI.AutoLayout(parent)
	layoutManager.ArrangeElements(parent)
end

function AI.Init()
	configManager.LoadConfig()
	AI.Notify("AI Libraries", "Framework initialized successfully!", "success", 2)
end

-- Initialize the library
AI.Init()

return AI
