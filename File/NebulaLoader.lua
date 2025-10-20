-- NebulaUI Beta - Modern Futuristic UI Library for Roblox
-- Version: Beta 1.0
-- Complete with all components and advanced features

local NebulaUI = {}
NebulaUI.__index = NebulaUI

-- Services
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local TextService = game:GetService("TextService")
local HttpService = game:GetService("HttpService")

-- Performance Monitoring
local Performance = {
	FPS = 0,
	MemoryUsage = 0,
	LastUpdate = tick()
}

-- Default Themes
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
		AccentColor = Color3.fromRGB(100, 255, 255)
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
		AccentColor = Color3.fromRGB(0, 100, 255)
	},
	Cyberpunk = {
		SchemeColor = Color3.fromRGB(255, 0, 255),
		Background = Color3.fromRGB(10, 5, 15),
		Header = Color3.fromRGB(20, 5, 25),
		TextColor = Color3.fromRGB(255, 255, 255),
		ElementColor = Color3.fromRGB(30, 10, 35),
		SecondaryColor = Color3.fromRGB(40, 15, 45),
		HoverColor = Color3.fromRGB(60, 20, 65),
		ActiveColor = Color3.fromRGB(200, 0, 200),
		AccentColor = Color3.fromRGB(255, 50, 255)
	}
}

-- Utility Functions
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

-- Performance Profiler
local function UpdatePerformanceStats()
	local currentTime = tick()
	if currentTime - Performance.LastUpdate >= 1 then
		Performance.FPS = math.floor(1 / RunService.Heartbeat:Wait())
		Performance.MemoryUsage = collectgarbage("count")
		Performance.LastUpdate = currentTime
	end
end

-- Input Validation
local function IsValidColor(color)
	return typeof(color) == "Color3"
end

local function IsValidNumber(num)
	return typeof(num) == "number" and num == num -- Check for NaN
end

-- Main NebulaUI Class
function NebulaUI:CreateWindow(Options)
	Options = Options or {}
	local Window = {
		Tabs = {},
		CurrentTab = nil,
		Theme = Options.Theme and Themes[Options.Theme] or Options.CustomTheme or Themes.GalacticDark,
		Open = true
	}
	setmetatable(Window, self)
	
	-- Create Main ScreenGui
	Window.ScreenGui = Create("ScreenGui", {
		Name = "NebulaUI_" .. HttpService:GenerateGUID(false):sub(1, 8),
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Global,
		DisplayOrder = 10
	})
	
	if Options.Parent then
		Window.ScreenGui.Parent = Options.Parent
	else
		Window.ScreenGui.Parent = game:GetService("CoreGui")
	end
	
	-- Main Container with Neon Border Effect
	Window.MainFrame = Create("Frame", {
		Parent = Window.ScreenGui,
		Size = Options.Size or UDim2.new(0, 850, 0, 550),
		Position = UDim2.new(0.5, -425, 0.5, -275),
		BackgroundColor3 = Window.Theme.Background,
		BorderSizePixel = 0,
		ClipsDescendants = true
	})
	
	-- Neon Border Effect
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
	
	-- Header with improved styling
	Window.Header = Create("Frame", {
		Parent = Window.MainFrame,
		Size = UDim2.new(1, 0, 0, 45),
		Position = UDim2.new(0, 0, 0, 2),
		BackgroundColor3 = Window.Theme.Header,
		BorderSizePixel = 0
	})
	
	Create("TextLabel", {
		Parent = Window.Header,
		Size = UDim2.new(1, -100, 1, 0),
		Position = UDim2.new(0, 15, 0, 0),
		BackgroundTransparency = 1,
		Text = Options.Title or "NebulaUI Dashboard",
		TextColor3 = Window.Theme.TextColor,
		TextSize = 20,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left
	})
	
	-- Performance Stats in Header
	Window.PerfLabel = Create("TextLabel", {
		Parent = Window.Header,
		Size = UDim2.new(0, 80, 1, 0),
		Position = UDim2.new(1, -85, 0, 0),
		BackgroundTransparency = 1,
		Text = "FPS: 60",
		TextColor3 = Window.Theme.TextColor,
		TextTransparency = 0.5,
		TextSize = 12,
		Font = Enum.Font.Gotham,
		TextXAlignment = Enum.TextXAlignment.Right
	})
	
	-- Close Button
	Window.CloseButton = Create("TextButton", {
		Parent = Window.Header,
		Size = UDim2.new(0, 30, 0, 30),
		Position = UDim2.new(1, -35, 0.5, -15),
		BackgroundColor3 = Window.Theme.ElementColor,
		BorderSizePixel = 0,
		Text = "×",
		TextColor3 = Window.Theme.TextColor,
		TextSize = 20,
		Font = Enum.Font.GothamBold,
		AutoButtonColor = false
	})
	
	-- Tab Container (Left Side) with gradient
	Window.TabContainer = Create("Frame", {
		Parent = Window.MainFrame,
		Size = UDim2.new(0, 180, 1, -47),
		Position = UDim2.new(0, 0, 0, 47),
		BackgroundColor3 = Window.Theme.SecondaryColor,
		BorderSizePixel = 0
	})
	
	-- Content Container (Right Side)
	Window.ContentContainer = Create("Frame", {
		Parent = Window.MainFrame,
		Size = UDim2.new(1, -180, 1, -47),
		Position = UDim2.new(0, 180, 0, 47),
		BackgroundColor3 = Window.Theme.Background,
		BorderSizePixel = 0,
		ClipsDescendants = true
	})
	
	-- UI Layouts
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
	
	-- Make draggable
	local Dragging, DragInput, DragStart, StartPosition
	
	local function Update(input)
		local Delta = input.Position - DragStart
		Window.MainFrame.Position = UDim2.new(
			StartPosition.X.Scale, 
			StartPosition.X.Offset + Delta.X,
			StartPosition.Y.Scale, 
			StartPosition.Y.Offset + Delta.Y
		)
	end
	
	Window.Header.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			Dragging = true
			DragStart = input.Position
			StartPosition = Window.MainFrame.Position
			
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					Dragging = false
				end
			end)
		end
	end)
	
	Window.Header.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			DragInput = input
		end
	end)
	
	UserInputService.InputChanged:Connect(function(input)
		if input == DragInput and Dragging then
			Update(input)
		end
	end)
	
	-- Close button functionality
	Window.CloseButton.MouseButton1Click:Connect(function()
		Window:Toggle()
	end)
	
	-- Performance monitoring
	RunService.Heartbeat:Connect(function()
		UpdatePerformanceStats()
		if Window.PerfLabel then
			Window.PerfLabel.Text = string.format("FPS: %d", Performance.FPS)
		end
	end)
	
	-- Window Methods
	function Window:CreateTab(Title, Icon)
		local Tab = {
			Title = Title or "New Tab",
			Sections = {},
			Visible = false
		}
		
		-- Tab Button with improved styling
		Tab.Button = Create("TextButton", {
			Parent = Window.TabContainer,
			Size = UDim2.new(1, 0, 0, 40),
			BackgroundColor3 = Window.Theme.ElementColor,
			BorderSizePixel = 0,
			Text = "",
			AutoButtonColor = false
		})
		
		Create("UICorner", {
			Parent = Tab.Button,
			CornerRadius = UDim.new(0, 6)
		})
		
		Tab.ButtonLabel = Create("TextLabel", {
			Parent = Tab.Button,
			Size = UDim2.new(1, -15, 1, 0),
			Position = UDim2.new(0, 15, 0, 0),
			BackgroundTransparency = 1,
			Text = Title or "New Tab",
			TextColor3 = Window.Theme.TextColor,
			TextSize = 14,
			Font = Enum.Font.Gotham,
			TextXAlignment = Enum.TextXAlignment.Left
		})
		
		-- Tab Content Frame
		Tab.Frame = Create("ScrollingFrame", {
			Parent = Window.ContentContainer,
			Size = UDim2.new(1, 0, 1, 0),
			Position = UDim2.new(0, 0, 0, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 4,
			ScrollBarImageColor3 = Window.Theme.SchemeColor,
			ScrollBarImageTransparency = 0.7,
			Visible = false,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y
		})
		
		Create("UIListLayout", {
			Parent = Tab.Frame,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 15)
		})
		
		Create("UIPadding", {
			Parent = Tab.Frame,
			PaddingTop = UDim.new(0, 10),
			PaddingLeft = UDim.new(0, 15),
			PaddingRight = UDim.new(0, 15),
			PaddingBottom = UDim.new(0, 10)
		})
		
		-- Tab Button Interactions
		Tab.Button.MouseEnter:Connect(function()
			if Tab ~= Window.CurrentTab then
				Tween(Tab.Button, {BackgroundColor3 = Window.Theme.HoverColor}, 0.2)
			end
		end)
		
		Tab.Button.MouseLeave:Connect(function()
			if Tab ~= Window.CurrentTab then
				Tween(Tab.Button, {BackgroundColor3 = Window.Theme.ElementColor}, 0.2)
			end
		end)
		
		Tab.Button.MouseButton1Click:Connect(function()
			Window:SwitchTab(Tab)
		end)
		
		-- Tab Methods
		function Tab:CreateSection(Name, Side)
			local Section = {
				Name = Name or "New Section",
				Elements = {},
				Side = Side or "Full"
			}
			
			-- Section Container
			Section.Frame = Create("Frame", {
				Parent = Tab.Frame,
				Size = UDim2.new(Side == "Full" and 1 or 0.48, Side == "Full" and 0 or -5, 0, 0),
				BackgroundColor3 = Window.Theme.ElementColor,
				BorderSizePixel = 0,
				AutomaticSize = Enum.AutomaticSize.Y
			})
			
			if Side == "Left" then
				Section.Frame.Size = UDim2.new(0.48, 0, 0, 0)
			elseif Side == "Right" then
				Section.Frame.Position = UDim2.new(0.52, 0, 0, 0)
				Section.Frame.Size = UDim2.new(0.48, 0, 0, 0)
			end
			
			Create("UICorner", {
				Parent = Section.Frame,
				CornerRadius = UDim.new(0, 8)
			})
			
			AddGlowEffect(Section.Frame, Window.Theme.SchemeColor)
			
			-- Section Header
			Section.Header = Create("Frame", {
				Parent = Section.Frame,
				Size = UDim2.new(1, 0, 0, 35),
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
				TextSize = 14,
				Font = Enum.Font.GothamBold,
				TextXAlignment = Enum.TextXAlignment.Left
			})
			
			-- Section Content
			Section.Content = Create("Frame", {
				Parent = Section.Frame,
				Size = UDim2.new(1, 0, 0, 0),
				Position = UDim2.new(0, 0, 0, 35),
				BackgroundTransparency = 1,
				AutomaticSize = Enum.AutomaticSize.Y
			})
			
			Create("UIListLayout", {
				Parent = Section.Content,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 8)
			})
			
			Create("UIPadding", {
				Parent = Section.Content,
				PaddingTop = UDim.new(0, 12),
				PaddingBottom = UDim.new(0, 12),
				PaddingLeft = UDim.new(0, 12),
				PaddingRight = UDim.new(0, 12)
			})
			
			-- Section Methods
			function Section:CreateButton(Text, Description, Callback)
				local Button = {}
				
				Button.Frame = Create("Frame", {
					Parent = Section.Content,
					Size = UDim2.new(1, 0, 0, Description and 45 or 35),
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
					Size = UDim2.new(1, -10, Description and 0.5 or 1, 0),
					Position = UDim2.new(0, 10, 0, 0),
					BackgroundTransparency = 1,
					Text = Text or "Button",
					TextColor3 = Window.Theme.TextColor,
					TextSize = 14,
					Font = Enum.Font.Gotham,
					TextXAlignment = Enum.TextXAlignment.Left
				})
				
				if Description then
					Button.Description = Create("TextLabel", {
						Parent = Button.Frame,
						Size = UDim2.new(1, -10, 0.5, 0),
						Position = UDim2.new(0, 10, 0.5, 0),
						BackgroundTransparency = 1,
						Text = Description,
						TextColor3 = Window.Theme.TextColor,
						TextTransparency = 0.4,
						TextSize = 12,
						Font = Enum.Font.Gotham,
						TextXAlignment = Enum.TextXAlignment.Left
					})
				end
				
				-- Button Interactions
				Button.Button.MouseEnter:Connect(function()
					Tween(Button.Frame, {BackgroundColor3 = Window.Theme.HoverColor}, 0.2)
					Tween(Button.Frame, {Size = UDim2.new(1, 5, 0, Description and 47 or 37)}, 0.2)
				end)
				
				Button.Button.MouseLeave:Connect(function()
					Tween(Button.Frame, {BackgroundColor3 = Window.Theme.SecondaryColor}, 0.2)
					Tween(Button.Frame, {Size = UDim2.new(1, 0, 0, Description and 45 or 35)}, 0.2)
				end)
				
				Button.Button.MouseButton1Click:Connect(function()
					if Callback then
						Callback()
					end
				end)
				
				-- Button Methods
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
				
				table.insert(Section.Elements, Button)
				return Button
			end
			
			function Section:CreateToggle(Text, Description, Default, Callback)
				local Toggle = {
					Value = Default or false
				}
				
				Toggle.Frame = Create("Frame", {
					Parent = Section.Content,
					Size = UDim2.new(1, 0, 0, Description and 45 or 35),
					BackgroundColor3 = Window.Theme.SecondaryColor,
					BorderSizePixel = 0
				})
				
				Create("UICorner", {
					Parent = Toggle.Frame,
					CornerRadius = UDim.new(0, 6)
				})
				
				Create("TextLabel", {
					Parent = Toggle.Frame,
					Size = UDim2.new(0.7, -10, Description and 0.5 or 1, 0),
					Position = UDim2.new(0, 10, 0, 0),
					BackgroundTransparency = 1,
					Text = Text or "Toggle",
					TextColor3 = Window.Theme.TextColor,
					TextSize = 14,
					Font = Enum.Font.Gotham,
					TextXAlignment = Enum.TextXAlignment.Left
				})
				
				if Description then
					Create("TextLabel", {
						Parent = Toggle.Frame,
						Size = UDim2.new(0.7, -10, 0.5, 0),
						Position = UDim2.new(0, 10, 0.5, 0),
						BackgroundTransparency = 1,
						Text = Description,
						TextColor3 = Window.Theme.TextColor,
						TextTransparency = 0.4,
						TextSize = 12,
						Font = Enum.Font.Gotham,
						TextXAlignment = Enum.TextXAlignment.Left
					})
				end
				
				-- Toggle Switch
				Toggle.SwitchFrame = Create("Frame", {
					Parent = Toggle.Frame,
					Size = UDim2.new(0, 50, 0, 25),
					Position = UDim2.new(1, -60, 0.5, -12.5),
					BackgroundColor3 = Window.Theme.ElementColor,
					BorderSizePixel = 0
				})
				
				Create("UICorner", {
					Parent = Toggle.SwitchFrame,
					CornerRadius = UDim.new(1, 0)
				})
				
				Toggle.Switch = Create("Frame", {
					Parent = Toggle.SwitchFrame,
					Size = UDim2.new(0, 21, 0, 21),
					Position = UDim2.new(0, 2, 0, 2),
					BackgroundColor3 = Window.Theme.TextColor,
					BorderSizePixel = 0
				})
				
				Create("UICorner", {
					Parent = Toggle.Switch,
					CornerRadius = UDim.new(1, 0)
				})
				
				Toggle.Button = Create("TextButton", {
					Parent = Toggle.Frame,
					Size = UDim2.new(0, 50, 0, 25),
					Position = UDim2.new(1, -60, 0.5, -12.5),
					BackgroundTransparency = 1,
					Text = "",
					AutoButtonColor = false
				})
				
				-- Set initial state
				if Toggle.Value then
					Tween(Toggle.Switch, {Position = UDim2.new(0, 27, 0, 2)}, 0.2)
					Tween(Toggle.SwitchFrame, {BackgroundColor3 = Window.Theme.SchemeColor}, 0.2)
				end
				
				-- Toggle Interactions
				Toggle.Button.MouseButton1Click:Connect(function()
					Toggle.Value = not Toggle.Value
					
					if Toggle.Value then
						Tween(Toggle.Switch, {Position = UDim2.new(0, 27, 0, 2)}, 0.2)
						Tween(Toggle.SwitchFrame, {BackgroundColor3 = Window.Theme.SchemeColor}, 0.2)
					else
						Tween(Toggle.Switch, {Position = UDim2.new(0, 2, 0, 2)}, 0.2)
						Tween(Toggle.SwitchFrame, {BackgroundColor3 = Window.Theme.ElementColor}, 0.2)
					end
					
					if Callback then
						Callback(Toggle.Value)
					end
				end)
				
				-- Toggle Methods
				function Toggle:UpdateToggle(State)
					Toggle.Value = State
					
					if Toggle.Value then
						Tween(Toggle.Switch, {Position = UDim2.new(0, 27, 0, 2)}, 0.2)
						Tween(Toggle.SwitchFrame, {BackgroundColor3 = Window.Theme.SchemeColor}, 0.2)
					else
						Tween(Toggle.Switch, {Position = UDim2.new(0, 2, 0, 2)}, 0.2)
						Tween(Toggle.SwitchFrame, {BackgroundColor3 = Window.Theme.ElementColor}, 0.2)
					end
				end
				
				function Toggle:GetValue()
					return Toggle.Value
				end
				
				table.insert(Section.Elements, Toggle)
				return Toggle
			end
			
			function Section:CreateSlider(Text, Description, Min, Max, Default, Callback)
				local Slider = {
					Value = Default or Min,
					Min = Min or 0,
					Max = Max or 100,
					Callback = Callback
				}
				
				Slider.Frame = Create("Frame", {
					Parent = Section.Content,
					Size = UDim2.new(1, 0, 0, Description and 65 or 55),
					BackgroundColor3 = Window.Theme.SecondaryColor,
					BorderSizePixel = 0
				})
				
				Create("UICorner", {
					Parent = Slider.Frame,
					CornerRadius = UDim.new(0, 6)
				})
				
				Create("TextLabel", {
					Parent = Slider.Frame,
					Size = UDim2.new(1, -10, 0, 20),
					Position = UDim2.new(0, 10, 0, 5),
					BackgroundTransparency = 1,
					Text = Text or "Slider",
					TextColor3 = Window.Theme.TextColor,
					TextSize = 14,
					Font = Enum.Font.Gotham,
					TextXAlignment = Enum.TextXAlignment.Left
				})
				
				if Description then
					Create("TextLabel", {
						Parent = Slider.Frame,
						Size = UDim2.new(1, -10, 0, 15),
						Position = UDim2.new(0, 10, 0, 25),
						BackgroundTransparency = 1,
						Text = Description,
						TextColor3 = Window.Theme.TextColor,
						TextTransparency = 0.4,
						TextSize = 12,
						Font = Enum.Font.Gotham,
						TextXAlignment = Enum.TextXAlignment.Left
					})
				end
				
				-- Slider Track
				Slider.Track = Create("Frame", {
					Parent = Slider.Frame,
					Size = UDim2.new(1, -20, 0, 6),
					Position = UDim2.new(0, 10, 1, -25),
					BackgroundColor3 = Window.Theme.ElementColor,
					BorderSizePixel = 0
				})
				
				Create("UICorner", {
					Parent = Slider.Track,
					CornerRadius = UDim.new(1, 0)
				})
				
				Slider.Fill = Create("Frame", {
					Parent = Slider.Track,
					Size = UDim2.new((Slider.Value - Slider.Min) / (Slider.Max - Slider.Min), 0, 1, 0),
					BackgroundColor3 = Window.Theme.SchemeColor,
					BorderSizePixel = 0
				})
				
				Create("UICorner", {
					Parent = Slider.Fill,
					CornerRadius = UDim.new(1, 0)
				})
				
				Slider.Button = Create("TextButton", {
					Parent = Slider.Track,
					Size = UDim2.new(0, 18, 0, 18),
					Position = UDim2.new((Slider.Value - Slider.Min) / (Slider.Max - Slider.Min), -9, 0.5, -9),
					BackgroundColor3 = Window.Theme.TextColor,
					BorderSizePixel = 0,
					Text = "",
					AutoButtonColor = false
				})
				
				Create("UICorner", {
					Parent = Slider.Button,
					CornerRadius = UDim.new(1, 0)
				})
				
				AddGlowEffect(Slider.Button, Window.Theme.SchemeColor)
				
				Slider.ValueLabel = Create("TextLabel", {
					Parent = Slider.Frame,
					Size = UDim2.new(0, 50, 0, 20),
					Position = UDim2.new(1, -60, 0, 5),
					BackgroundTransparency = 1,
					Text = tostring(Slider.Value),
					TextColor3 = Window.Theme.TextColor,
					TextSize = 14,
					Font = Enum.Font.GothamBold,
					TextXAlignment = Enum.TextXAlignment.Right
				})
				
				-- Slider Logic
				local Dragging = false
				
				local function UpdateSlider(input)
					local pos = UDim2.new(
						math.clamp((input.Position.X - Slider.Track.AbsolutePosition.X) / Slider.Track.AbsoluteSize.X, 0, 1), 
						-9, 0.5, -9
					)
					
					Slider.Button.Position = pos
					Slider.Fill.Size = UDim2.new(pos.X.Scale, 0, 1, 0)
					
					local value = math.floor(Slider.Min + (pos.X.Scale * (Slider.Max - Slider.Min)))
					Slider.Value = value
					Slider.ValueLabel.Text = tostring(value)
					
					if Slider.Callback then
						Slider.Callback(value)
					end
				end
				
				Slider.Button.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						Dragging = true
					end
				end)
				
				Slider.Button.InputEnded:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						Dragging = false
					end
				end)
				
				Slider.Track.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						Dragging = true
						UpdateSlider(input)
					end
				end)
				
				UserInputService.InputChanged:Connect(function(input)
					if Dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
						UpdateSlider(input)
					end
				end)
				
				-- Slider Methods
				function Slider:UpdateSlider(NewValue)
					NewValue = math.clamp(NewValue, Slider.Min, Slider.Max)
					Slider.Value = NewValue
					
					local pos = UDim2.new((NewValue - Slider.Min) / (Slider.Max - Slider.Min), -9, 0.5, -9)
					Slider.Button.Position = pos
					Slider.Fill.Size = UDim2.new(pos.X.Scale, 0, 1, 0)
					Slider.ValueLabel.Text = tostring(NewValue)
				end
				
				function Slider:GetValue()
					return Slider.Value
				end
				
				function Slider:SetRange(NewMin, NewMax)
					Slider.Min = NewMin
					Slider.Max = NewMax
					Slider:UpdateSlider(math.clamp(Slider.Value, NewMin, NewMax))
				end
				
				table.insert(Section.Elements, Slider)
				return Slider
			end
			
			function Section:CreateTextbox(Text, Placeholder, Callback)
				local Textbox = {}
				
				Textbox.Frame = Create("Frame", {
					Parent = Section.Content,
					Size = UDim2.new(1, 0, 0, 35),
					BackgroundColor3 = Window.Theme.SecondaryColor,
					BorderSizePixel = 0
				})
				
				Create("UICorner", {
					Parent = Textbox.Frame,
					CornerRadius = UDim.new(0, 6)
				})
				
				Create("TextLabel", {
					Parent = Textbox.Frame,
					Size = UDim2.new(0.4, -10, 1, 0),
					Position = UDim2.new(0, 10, 0, 0),
					BackgroundTransparency = 1,
					Text = Text or "Textbox",
					TextColor3 = Window.Theme.TextColor,
					TextSize = 14,
					Font = Enum.Font.Gotham,
					TextXAlignment = Enum.TextXAlignment.Left
				})
				
				Textbox.Input = Create("TextBox", {
					Parent = Textbox.Frame,
					Size = UDim2.new(0.6, -15, 0.7, 0),
					Position = UDim2.new(0.4, 0, 0.15, 0),
					BackgroundColor3 = Window.Theme.ElementColor,
					BorderSizePixel = 0,
					Text = "",
					PlaceholderText = Placeholder or "Enter text...",
					TextColor3 = Window.Theme.TextColor,
					TextSize = 14,
					Font = Enum.Font.Gotham,
					ClearTextOnFocus = false
				})
				
				Create("UICorner", {
					Parent = Textbox.Input,
					CornerRadius = UDim.new(0, 4)
				})
				
				Textbox.Input.FocusLost:Connect(function(enterPressed)
					if enterPressed and Callback then
						Callback(Textbox.Input.Text)
					end
				end)
				
				-- Textbox Methods
				function Textbox:UpdateTextbox(NewText, NewPlaceholder)
					Textbox.Input.Text = NewText or ""
					if NewPlaceholder then
						Textbox.Input.PlaceholderText = NewPlaceholder
					end
				end
				
				function Textbox:GetValue()
					return Textbox.Input.Text
				end
				
				function Textbox:SetValue(Value)
					Textbox.Input.Text = Value or ""
				end
				
				table.insert(Section.Elements, Textbox)
				return Textbox
			end
			
			function Section:CreateDropdown(Text, Description, Options, Default, Callback)
				local Dropdown = {
					Value = Default or Options[1],
					Options = Options or {},
					Open = false
				}
				
				Dropdown.Frame = Create("Frame", {
					Parent = Section.Content,
					Size = UDim2.new(1, 0, 0, Description and 45 or 35),
					BackgroundColor3 = Window.Theme.SecondaryColor,
					BorderSizePixel = 0,
					ClipsDescendants = true
				})
				
				Create("UICorner", {
					Parent = Dropdown.Frame,
					CornerRadius = UDim.new(0, 6)
				})
				
				Create("TextLabel", {
					Parent = Dropdown.Frame,
					Size = UDim2.new(0.7, -10, Description and 0.5 or 1, 0),
					Position = UDim2.new(0, 10, 0, 0),
					BackgroundTransparency = 1,
					Text = Text or "Dropdown",
					TextColor3 = Window.Theme.TextColor,
					TextSize = 14,
					Font = Enum.Font.Gotham,
					TextXAlignment = Enum.TextXAlignment.Left
				})
				
				if Description then
					Create("TextLabel", {
						Parent = Dropdown.Frame,
						Size = UDim2.new(0.7, -10, 0.5, 0),
						Position = UDim2.new(0, 10, 0.5, 0),
						BackgroundTransparency = 1,
						Text = Description,
						TextColor3 = Window.Theme.TextColor,
						TextTransparency = 0.4,
						TextSize = 12,
						Font = Enum.Font.Gotham,
						TextXAlignment = Enum.TextXAlignment.Left
					})
				end
				
				Dropdown.Selected = Create("TextLabel", {
					Parent = Dropdown.Frame,
					Size = UDim2.new(0.25, -30, 1, 0),
					Position = UDim2.new(0.75, 0, 0, 0),
					BackgroundTransparency = 1,
					Text = Dropdown.Value or "Select...",
					TextColor3 = Window.Theme.TextColor,
					TextSize = 12,
					Font = Enum.Font.Gotham,
					TextXAlignment = Enum.TextXAlignment.Right
				})
				
				Dropdown.Button = Create("TextButton", {
					Parent = Dropdown.Frame,
					Size = UDim2.new(0, 25, 0, 25),
					Position = UDim2.new(1, -30, 0.5, -12.5),
					BackgroundColor3 = Window.Theme.ElementColor,
					BorderSizePixel = 0,
					Text = "▼",
					TextColor3 = Window.Theme.TextColor,
					TextSize = 12,
					AutoButtonColor = false
				})
				
				Create("UICorner", {
					Parent = Dropdown.Button,
					CornerRadius = UDim.new(0, 4)
				})
				
				-- Dropdown List
				Dropdown.List = Create("ScrollingFrame", {
					Parent = Dropdown.Frame,
					Size = UDim2.new(1, 0, 0, 0),
					Position = UDim2.new(0, 0, 1, 5),
					BackgroundColor3 = Window.Theme.ElementColor,
					BorderSizePixel = 0,
					ScrollBarThickness = 3,
					ScrollBarImageColor3 = Window.Theme.SchemeColor,
					Visible = false,
					CanvasSize = UDim2.new(0, 0, 0, 0),
					AutomaticCanvasSize = Enum.AutomaticSize.Y
				})
				
				Create("UICorner", {
					Parent = Dropdown.List,
					CornerRadius = UDim.new(0, 6)
				})
				
				Create("UIListLayout", {
					Parent = Dropdown.List,
					SortOrder = Enum.SortOrder.LayoutOrder
				})
				
				-- Dropdown Logic
				local function UpdateDropdown()
					Dropdown.Selected.Text = Dropdown.Value
					if Callback then
						Callback(Dropdown.Value)
					end
				end
				
				local function ToggleDropdown()
					Dropdown.Open = not Dropdown.Open
					
					if Dropdown.Open then
						Dropdown.List.Visible = true
						Tween(Dropdown.List, {Size = UDim2.new(1, 0, 0, math.min(#Dropdown.Options * 30, 150))}, 0.3)
						Tween(Dropdown.Button, {Rotation = 180}, 0.2)
					else
						Tween(Dropdown.List, {Size = UDim2.new(1, 0, 0, 0)}, 0.3)
						Tween(Dropdown.Button, {Rotation = 0}, 0.2)
						wait(0.3)
						Dropdown.List.Visible = false
					end
				end
				
				-- Create option buttons
				for i, option in ipairs(Dropdown.Options) do
					local OptionButton = Create("TextButton", {
						Parent = Dropdown.List,
						Size = UDim2.new(1, -10, 0, 25),
						Position = UDim2.new(0, 5, 0, (i-1)*30),
						BackgroundColor3 = Window.Theme.SecondaryColor,
						BorderSizePixel = 0,
						Text = option,
						TextColor3 = Window.Theme.TextColor,
						TextSize = 12,
						Font = Enum.Font.Gotham,
						AutoButtonColor = false
					})
					
					Create("UICorner", {
						Parent = OptionButton,
						CornerRadius = UDim.new(0, 4)
					})
					
					OptionButton.MouseEnter:Connect(function()
						Tween(OptionButton, {BackgroundColor3 = Window.Theme.HoverColor}, 0.2)
					end)
					
					OptionButton.MouseLeave:Connect(function()
						Tween(OptionButton, {BackgroundColor3 = Window.Theme.SecondaryColor}, 0.2)
					end)
					
					OptionButton.MouseButton1Click:Connect(function()
						Dropdown.Value = option
						UpdateDropdown()
						ToggleDropdown()
					end)
				end
				
				Dropdown.Button.MouseButton1Click:Connect(ToggleDropdown)
				
				-- Close dropdown when clicking outside
				UserInputService.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 and Dropdown.Open then
						if not Dropdown.Button:IsDescendantOf(input.Target) and not Dropdown.List:IsDescendantOf(input.Target) then
							ToggleDropdown()
						end
					end
				end)
				
				-- Dropdown Methods
				function Dropdown:Refresh(NewOptions, NewDefault)
					Dropdown.Options = NewOptions or Dropdown.Options
					Dropdown.Value = NewDefault or Dropdown.Options[1]
					
					-- Clear existing options
					for _, child in ipairs(Dropdown.List:GetChildren()) do
						if child:IsA("TextButton") then
							child:Destroy()
						end
					end
					
					-- Create new options
					for i, option in ipairs(Dropdown.Options) do
						local OptionButton = Create("TextButton", {
							Parent = Dropdown.List,
							Size = UDim2.new(1, -10, 0, 25),
							Position = UDim2.new(0, 5, 0, (i-1)*30),
							BackgroundColor3 = Window.Theme.SecondaryColor,
							BorderSizePixel = 0,
							Text = option,
							TextColor3 = Window.Theme.TextColor,
							TextSize = 12,
							Font = Enum.Font.Gotham,
							AutoButtonColor = false
						})
						
						Create("UICorner", {
							Parent = OptionButton,
							CornerRadius = UDim.new(0, 4)
						})
						
						OptionButton.MouseEnter:Connect(function()
							Tween(OptionButton, {BackgroundColor3 = Window.Theme.HoverColor}, 0.2)
						end)
						
						OptionButton.MouseLeave:Connect(function()
							Tween(OptionButton, {BackgroundColor3 = Window.Theme.SecondaryColor}, 0.2)
						end)
						
						OptionButton.MouseButton1Click:Connect(function()
							Dropdown.Value = option
							UpdateDropdown()
							ToggleDropdown()
						end)
					end
					
					UpdateDropdown()
				end
				
				function Dropdown:GetValue()
					return Dropdown.Value
				end
				
				function Dropdown:SetValue(Value)
					if table.find(Dropdown.Options, Value) then
						Dropdown.Value = Value
						UpdateDropdown()
					end
				end
				
				table.insert(Section.Elements, Dropdown)
				return Dropdown
			end
			
			function Section:CreateKeybind(Text, Description, DefaultKey, Callback)
				local Keybind = {
					Value = DefaultKey or Enum.KeyCode.LeftControl,
					Listening = false
				}
				
				Keybind.Frame = Create("Frame", {
					Parent = Section.Content,
					Size = UDim2.new(1, 0, 0, Description and 45 or 35),
					BackgroundColor3 = Window.Theme.SecondaryColor,
					BorderSizePixel = 0
				})
				
				Create("UICorner", {
					Parent = Keybind.Frame,
					CornerRadius = UDim.new(0, 6)
				})
				
				Create("TextLabel", {
					Parent = Keybind.Frame,
					Size = UDim2.new(0.7, -10, Description and 0.5 or 1, 0),
					Position = UDim2.new(0, 10, 0, 0),
					BackgroundTransparency = 1,
					Text = Text or "Keybind",
					TextColor3 = Window.Theme.TextColor,
					TextSize = 14,
					Font = Enum.Font.Gotham,
					TextXAlignment = Enum.TextXAlignment.Left
				})
				
				if Description then
					Create("TextLabel", {
						Parent = Keybind.Frame,
						Size = UDim2.new(0.7, -10, 0.5, 0),
						Position = UDim2.new(0, 10, 0.5, 0),
						BackgroundTransparency = 1,
						Text = Description,
						TextColor3 = Window.Theme.TextColor,
						TextTransparency = 0.4,
						TextSize = 12,
						Font = Enum.Font.Gotham,
						TextXAlignment = Enum.TextXAlignment.Left
					})
				end
				
				Keybind.Display = Create("TextButton", {
					Parent = Keybind.Frame,
					Size = UDim2.new(0, 80, 0, 25),
					Position = UDim2.new(1, -90, 0.5, -12.5),
					BackgroundColor3 = Window.Theme.ElementColor,
					BorderSizePixel = 0,
					Text = Keybind.Value.Name,
					TextColor3 = Window.Theme.TextColor,
					TextSize = 12,
					Font = Enum.Font.Gotham,
					AutoButtonColor = false
				})
				
				Create("UICorner", {
					Parent = Keybind.Display,
					CornerRadius = UDim.new(0, 4)
				})
				
				local function StartListening()
					Keybind.Listening = true
					Keybind.Display.Text = "..."
					Tween(Keybind.Display, {BackgroundColor3 = Window.Theme.SchemeColor}, 0.2)
				end
				
				local function StopListening()
					Keybind.Listening = false
					Keybind.Display.Text = Keybind.Value.Name
					Tween(Keybind.Display, {BackgroundColor3 = Window.Theme.ElementColor}, 0.2)
				end
				
				Keybind.Display.MouseButton1Click:Connect(StartListening)
				
				local Connection
				Connection = UserInputService.InputBegan:Connect(function(input)
					if Keybind.Listening then
						if input.UserInputType == Enum.UserInputType.Keyboard then
							Keybind.Value = input.KeyCode
							StopListening()
							if Callback then
								Callback(Keybind.Value)
							end
						end
					elseif input.KeyCode == Keybind.Value then
						if Callback then
							Callback(Keybind.Value)
						end
					end
				end)
				
				-- Keybind Methods
				function Keybind:UpdateKeybind(NewKey)
					Keybind.Value = NewKey or Keybind.Value
					Keybind.Display.Text = Keybind.Value.Name
				end
				
				function Keybind:GetValue()
					return Keybind.Value
				end
				
				function Keybind:Destroy()
					if Connection then
						Connection:Disconnect()
					end
				end
				
				table.insert(Section.Elements, Keybind)
				return Keybind
			end
			
			function Section:CreateColorPicker(Text, Description, DefaultColor, Callback)
				local ColorPicker = {
					Value = DefaultColor or Color3.fromRGB(255, 255, 255)
				}
				
				ColorPicker.Frame = Create("Frame", {
					Parent = Section.Content,
					Size = UDim2.new(1, 0, 0, Description and 45 or 35),
					BackgroundColor3 = Window.Theme.SecondaryColor,
					BorderSizePixel = 0
				})
				
				Create("UICorner", {
					Parent = ColorPicker.Frame,
					CornerRadius = UDim.new(0, 6)
				})
				
				Create("TextLabel", {
					Parent = ColorPicker.Frame,
					Size = UDim2.new(0.7, -10, Description and 0.5 or 1, 0),
					Position = UDim2.new(0, 10, 0, 0),
					BackgroundTransparency = 1,
					Text = Text or "Color Picker",
					TextColor3 = Window.Theme.TextColor,
					TextSize = 14,
					Font = Enum.Font.Gotham,
					TextXAlignment = Enum.TextXAlignment.Left
				})
				
				if Description then
					Create("TextLabel", {
						Parent = ColorPicker.Frame,
						Size = UDim2.new(0.7, -10, 0.5, 0),
						Position = UDim2.new(0, 10, 0.5, 0),
						BackgroundTransparency = 1,
						Text = Description,
						TextColor3 = Window.Theme.TextColor,
						TextTransparency = 0.4,
						TextSize = 12,
						Font = Enum.Font.Gotham,
						TextXAlignment = Enum.TextXAlignment.Left
					})
				end
				
				ColorPicker.Preview = Create("TextButton", {
					Parent = ColorPicker.Frame,
					Size = UDim2.new(0, 60, 0, 25),
					Position = UDim2.new(1, -70, 0.5, -12.5),
					BackgroundColor3 = ColorPicker.Value,
					BorderSizePixel = 0,
					Text = "",
					AutoButtonColor = false
				})
				
				Create("UICorner", {
					Parent = ColorPicker.Preview,
					CornerRadius = UDim.new(0, 4)
				})
				
				-- Color Picker Popup
				ColorPicker.Popup = Create("Frame", {
					Parent = ColorPicker.Frame,
					Size = UDim2.new(0, 200, 0, 150),
					Position = UDim2.new(1, 10, 0, 0),
					BackgroundColor3 = Window.Theme.ElementColor,
					BorderSizePixel = 0,
					Visible = false,
					ZIndex = 20
				})
				
				Create("UICorner", {
					Parent = ColorPicker.Popup,
					CornerRadius = UDim.new(0, 8)
				})
				
				AddGlowEffect(ColorPicker.Popup, Window.Theme.SchemeColor)
				
				-- Simple color palette
				local Colors = {
					Color3.fromRGB(255, 0, 0),    -- Red
					Color3.fromRGB(0, 255, 0),    -- Green
					Color3.fromRGB(0, 0, 255),    -- Blue
					Color3.fromRGB(255, 255, 0),  -- Yellow
					Color3.fromRGB(255, 0, 255),  -- Magenta
					Color3.fromRGB(0, 255, 255),  -- Cyan
					Color3.fromRGB(255, 255, 255),-- White
					Color3.fromRGB(0, 0, 0)       -- Black
				}
				
				for i, color in ipairs(Colors) do
					local ColorButton = Create("TextButton", {
						Parent = ColorPicker.Popup,
						Size = UDim2.new(0, 30, 0, 30),
						Position = UDim2.new(0, 10 + ((i-1) % 4) * 45, 0, 10 + math.floor((i-1) / 4) * 45),
						BackgroundColor3 = color,
						BorderSizePixel = 0,
						Text = "",
						AutoButtonColor = false
					})
					
					Create("UICorner", {
						Parent = ColorButton,
						CornerRadius = UDim.new(0, 4)
					})
					
					ColorButton.MouseButton1Click:Connect(function()
						ColorPicker.Value = color
						ColorPicker.Preview.BackgroundColor3 = color
						ColorPicker.Popup.Visible = false
						if Callback then
							Callback(color)
						end
					end)
				end
				
				ColorPicker.Preview.MouseButton1Click:Connect(function()
					ColorPicker.Popup.Visible = not ColorPicker.Popup.Visible
				end)
				
				-- Close popup when clicking outside
				UserInputService.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 and ColorPicker.Popup.Visible then
						if not ColorPicker.Preview:IsDescendantOf(input.Target) and not ColorPicker.Popup:IsDescendantOf(input.Target) then
							ColorPicker.Popup.Visible = false
						end
					end
				end)
				
				-- Color Picker Methods
				function ColorPicker:UpdateColor(NewColor)
					if IsValidColor(NewColor) then
						ColorPicker.Value = NewColor
						ColorPicker.Preview.BackgroundColor3 = NewColor
					end
				end
				
				function ColorPicker:GetValue()
					return ColorPicker.Value
				end
				
				table.insert(Section.Elements, ColorPicker)
				return ColorPicker
			end
			
			function Section:CreateLabel(Text)
				local Label = {}
				
				Label.Frame = Create("Frame", {
					Parent = Section.Content,
					Size = UDim2.new(1, 0, 0, 25),
					BackgroundTransparency = 1,
					BorderSizePixel = 0
				})
				
				Label.TextLabel = Create("TextLabel", {
					Parent = Label.Frame,
					Size = UDim2.new(1, -10, 1, 0),
					Position = UDim2.new(0, 10, 0, 0),
					BackgroundTransparency = 1,
					Text = Text or "Label",
					TextColor3 = Window.Theme.TextColor,
					TextSize = 14,
					Font = Enum.Font.Gotham,
					TextXAlignment = Enum.TextXAlignment.Left
				})
				
				-- Label Methods
				function Label:UpdateLabel(NewText)
					Label.TextLabel.Text = NewText
				end
				
				table.insert(Section.Elements, Label)
				return Label
			end
			
			table.insert(Tab.Sections, Section)
			return Section
		end
		
		table.insert(Window.Tabs, Tab)
		
		-- Auto-select first tab
		if #Window.Tabs == 1 then
			Window:SwitchTab(Tab)
		end
		
		return Tab
	end
	
	function Window:SwitchTab(NewTab)
		if Window.CurrentTab then
			Window.CurrentTab.Visible = false
			Window.CurrentTab.Frame.Visible = false
			Tween(Window.CurrentTab.Button, {BackgroundColor3 = Window.Theme.ElementColor}, 0.2)
		end
		
		Window.CurrentTab = NewTab
		NewTab.Visible = true
		NewTab.Frame.Visible = true
		Tween(NewTab.Button, {BackgroundColor3 = Window.Theme.ActiveColor}, 0.2)
	end
	
	function Window:SetThemeColors(Colors)
		if Colors then
			Window.Theme = Colors
			-- Update all UI elements with new theme
			Window.MainFrame.BackgroundColor3 = Colors.Background
			Window.Header.BackgroundColor3 = Colors.Header
			Window.TabContainer.BackgroundColor3 = Colors.SecondaryColor
			Window.NeonBorder.BackgroundColor3 = Colors.SchemeColor
		end
	end
	
	function Window:Toggle()
		Window.Open = not Window.Open
		if Window.Open then
			Window.MainFrame.Visible = true
			Tween(Window.MainFrame, {Size = Options.Size or UDim2.new(0, 850, 0, 550)}, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		else
			Tween(Window.MainFrame, {Size = UDim2.new(0, 0, 0, 0)}, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In)
			wait(0.3)
			Window.MainFrame.Visible = false
		end
	end
	
	function Window:Destroy()
		if Window.ScreenGui then
			Window.ScreenGui:Destroy()
		end
	end
	
	return Window
end

-- Enhanced Notification System
function NebulaUI:Notify(Title, Message, Duration, Type)
	Duration = Duration or 5
	Type = Type or "Info"
	
	-- Create notification container if it doesn't exist
	if not self.NotificationContainer then
		self.NotificationContainer = Create("Frame", {
			Parent = self.ScreenGui or game.CoreGui,
			Size = UDim2.new(0, 350, 1, -20),
			Position = UDim2.new(1, -370, 0, 20),
			BackgroundTransparency = 1,
			ZIndex = 100
		})
		
		Create("UIListLayout", {
			Parent = self.NotificationContainer,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 10)
		})
	end
	
	-- Type colors
	local TypeColors = {
		Success = Color3.fromRGB(46, 204, 113),
		Error = Color3.fromRGB(231, 76, 60),
		Warning = Color3.fromRGB(241, 196, 15),
		Info = Color3.fromRGB(52, 152, 219)
	}
	
	-- Create notification
	local Notification = Create("Frame", {
		Parent = self.NotificationContainer,
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundColor3 = Themes.GalacticDark.ElementColor,
		BorderSizePixel = 0,
		LayoutOrder = 999,
		AutomaticSize = Enum.AutomaticSize.Y
	})
	
	Create("UICorner", {
		Parent = Notification,
		CornerRadius = UDim.new(0, 8)
	})
	
	AddGlowEffect(Notification, TypeColors[Type] or TypeColors.Info)
	
	-- Type indicator
	Create("Frame", {
		Parent = Notification,
		Size = UDim2.new(0, 5, 1, 0),
		BackgroundColor3 = TypeColors[Type] or TypeColors.Info,
		BorderSizePixel = 0
	})
	
	Create("UICorner", {
		Parent = Notification:FindFirstChild("Frame"),
		CornerRadius = UDim.new(0, 8, 0, 0)
	})
	
	-- Content
	local Content = Create("Frame", {
		Parent = Notification,
		Size = UDim2.new(1, -15, 0, 0),
		Position = UDim2.new(0, 15, 0, 0),
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.Y
	})
	
	Create("UIListLayout", {
		Parent = Content,
		SortOrder = Enum.SortOrder.LayoutOrder
	})
	
	Create("UIPadding", {
		Parent = Content,
		PaddingTop = UDim.new(0, 10),
		PaddingBottom = UDim.new(0, 10)
	})
	
	Create("TextLabel", {
		Parent = Content,
		Size = UDim2.new(1, 0, 0, 25),
		BackgroundTransparency = 1,
		Text = Title or "Notification",
		TextColor3 = Themes.GalacticDark.TextColor,
		TextSize = 16,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left
	})
	
	Create("TextLabel", {
		Parent = Content,
		Size = UDim2.new(1, 0, 0, 0),
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
	
	-- Close button
	local CloseButton = Create("TextButton", {
		Parent = Notification,
		Size = UDim2.new(0, 20, 0, 20),
		Position = UDim2.new(1, -25, 0, 5),
		BackgroundTransparency = 1,
		Text = "×",
		TextColor3 = Themes.GalacticDark.TextColor,
		TextSize = 18,
		Font = Enum.Font.GothamBold
	})
	
	-- Animate in
	Notification.Size = UDim2.new(1, 0, 0, 0)
	Notification.Position = UDim2.new(1, 0, 0, 0)
	
	Tween(Notification, {Position = UDim2.new(0, 0, 0, 0)}, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	Tween(Notification, {Size = UDim2.new(1, 0, 0, Content.AbsoluteContentSize.Y + 20)}, 0.3)
	
	-- Auto remove after duration
	local removeConnection
	local function Remove()
		if removeConnection then
			removeConnection:Disconnect()
		end
		Tween(Notification, {Position = UDim2.new(1, 0, 0, 0)}, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In)
		Tween(Notification, {Size = UDim2.new(1, 0, 0, 0)}, 0.3)
		wait(0.3)
		Notification:Destroy()
	end
	
	removeConnection = RunService.Heartbeat:Connect(function()
		if Duration <= 0 then
			Remove()
		end
		Duration = Duration - RunService.Heartbeat:Wait()
	end)
	
	CloseButton.MouseButton1Click:Connect(Remove)
	
	-- Manual removal method
	function Notification:Remove()
		Remove()
	end
	
	return Notification
end

-- Theme Management
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

-- Performance Monitoring
function NebulaUI:GetPerformanceStats()
	return {
		FPS = Performance.FPS,
		MemoryUsage = Performance.MemoryUsage
	}
end

return NebulaUI
