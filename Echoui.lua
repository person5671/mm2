--[[
	EchoUI - Lightweight Roblox UI Library
	Usage:
		local EchoUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/YOURNAME/YOURREPO/main/EchoUI.lua"))()
		local Window = EchoUI:CreateWindow({ Title = "Echo Menu" })
		local Tab = Window:CreateTab("Main")
		Tab:CreateButton({ Name = "Click Me", Callback = function() print("clicked") end })
]]

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local EchoUI = {}
EchoUI.__index = EchoUI

print("[EchoUI] Loaded version: v1.6-inline-swatch")

-- ============================================================
-- THEME
-- ============================================================
local Theme = {
	Background   = Color3.fromRGB(18, 18, 24),
	Surface      = Color3.fromRGB(26, 26, 34),
	SurfaceLight = Color3.fromRGB(34, 34, 44),
	Border       = Color3.fromRGB(48, 48, 60),
	Accent       = Color3.fromRGB(90, 60, 220),   -- purple
	AccentAlt    = Color3.fromRGB(45, 210, 200),  -- teal
	Text         = Color3.fromRGB(235, 235, 245),
	SubText      = Color3.fromRGB(150, 150, 165),
	Success      = Color3.fromRGB(80, 220, 130),
	Danger       = Color3.fromRGB(230, 80, 90),
}

local function tween(obj, props, time, style, dir)
	local t = TweenService:Create(obj, TweenInfo.new(
		time or 0.2,
		style or Enum.EasingStyle.Quad,
		dir or Enum.EasingDirection.Out
	), props)
	t:Play()
	return t
end

local function corner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 6)
	c.Parent = parent
	return c
end

local function stroke(parent, color, thickness)
	local s = Instance.new("UIStroke")
	s.Color = color or Theme.Border
	s.Thickness = thickness or 1
	s.Parent = parent
	return s
end

local function make(class, props)
	local inst = Instance.new(class)
	for k, v in pairs(props or {}) do
		inst[k] = v
	end
	return inst
end

local function makeDraggable(frame, handle)
	local dragging, dragInput, dragStart, startPos

	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = frame.Position

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	handle.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			local delta = input.Position - dragStart
			frame.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + delta.X,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y
			)
		end
	end)
end

-- Reusable inline color swatch: a small clickable square that expands an
-- R/G/B panel below `Holder`. Used by CreateToggle (inline) and
-- CreateColorPicker (standalone). Returns the swatch button and a small API.
local function attachColorSwatch(Holder, position, initialColor, callback)
	local color = initialColor or Color3.fromRGB(255, 255, 255)
	local expanded = false

	local SwatchBtn = make("TextButton", {
		Text = "",
		BackgroundColor3 = color,
		Size = UDim2.new(0, 20, 0, 20),
		Position = position,
		ZIndex = 3,
		Parent = Holder,
	})
	corner(SwatchBtn, 5)
	stroke(SwatchBtn, Theme.Border, 1)

	local Panel = make("Frame", {
		Size = UDim2.new(1, 0, 0, 100),
		Position = UDim2.new(0, 0, 1, 4),
		BackgroundColor3 = Theme.SurfaceLight,
		Visible = false,
		ZIndex = 5,
		Parent = Holder,
	})
	corner(Panel, 6)
	stroke(Panel, Theme.Border, 1)
	make("UIPadding", {
		PaddingTop = UDim.new(0, 8),
		PaddingLeft = UDim.new(0, 10),
		PaddingRight = UDim.new(0, 10),
		Parent = Panel,
	})

	local r, g, b = math.floor(color.R * 255), math.floor(color.G * 255), math.floor(color.B * 255)

	local function fire()
		SwatchBtn.BackgroundColor3 = color
		if callback then
			local ok, err = pcall(callback, color)
			if not ok then warn("[EchoUI] ColorSwatch callback error: " .. tostring(err)) end
		end
	end

	local function makeChannelSlider(labelText, initial, yOffset, channelColor, onChange)
		local Row = make("Frame", {
			Size = UDim2.new(1, 0, 0, 26),
			Position = UDim2.new(0, 0, 0, yOffset),
			BackgroundTransparency = 1,
			ZIndex = 5,
			Parent = Panel,
		})

		make("TextLabel", {
			Text = labelText,
			Font = Enum.Font.GothamBold,
			TextSize = 11,
			TextColor3 = channelColor,
			BackgroundTransparency = 1,
			Size = UDim2.new(0, 16, 1, 0),
			ZIndex = 5,
			Parent = Row,
		})

		local Track = make("Frame", {
			Size = UDim2.new(1, -50, 0, 6),
			Position = UDim2.new(0, 20, 0.5, -3),
			BackgroundColor3 = Theme.Background,
			ZIndex = 5,
			Parent = Row,
		})
		corner(Track, 3)

		local Fill = make("Frame", {
			Size = UDim2.new(initial / 255, 0, 1, 0),
			BackgroundColor3 = channelColor,
			ZIndex = 5,
			Parent = Track,
		})
		corner(Fill, 3)

		local ValLabel = make("TextLabel", {
			Text = tostring(initial),
			Font = Enum.Font.Gotham,
			TextSize = 11,
			TextColor3 = Theme.SubText,
			BackgroundTransparency = 1,
			Position = UDim2.new(1, -26, 0, 0),
			Size = UDim2.new(0, 26, 1, 0),
			TextXAlignment = Enum.TextXAlignment.Right,
			ZIndex = 5,
			Parent = Row,
		})

		local dragging = false
		local function setFromAlpha(alpha)
			alpha = math.clamp(alpha, 0, 1)
			local val = math.floor(alpha * 255 + 0.5)
			Fill.Size = UDim2.new(alpha, 0, 1, 0)
			ValLabel.Text = tostring(val)
			onChange(val)
		end

		Track.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				local alpha = (input.Position.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X
				setFromAlpha(alpha)
			end
		end)
		UserInputService.InputChanged:Connect(function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				local alpha = (input.Position.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X
				setFromAlpha(alpha)
			end
		end)
		UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = false
			end
		end)
	end

	makeChannelSlider("R", r, 0, Color3.fromRGB(255, 90, 90), function(v)
		r = v
		color = Color3.fromRGB(r, g, b)
		fire()
	end)
	makeChannelSlider("G", g, 32, Color3.fromRGB(90, 255, 120), function(v)
		g = v
		color = Color3.fromRGB(r, g, b)
		fire()
	end)
	makeChannelSlider("B", b, 64, Color3.fromRGB(100, 140, 255), function(v)
		b = v
		color = Color3.fromRGB(r, g, b)
		fire()
	end)

	SwatchBtn.MouseButton1Click:Connect(function()
		expanded = not expanded
		Panel.Visible = expanded
	end)

	return {
		Button = SwatchBtn,
		Set = function(_, c)
			color = c
			r, g, b = math.floor(c.R * 255), math.floor(c.G * 255), math.floor(c.B * 255)
			SwatchBtn.BackgroundColor3 = color
		end,
		Get = function() return color end,
	}
end

-- ============================================================
-- WINDOW
-- ============================================================
function EchoUI:CreateWindow(config)
	config = config or {}
	local title = config.Title or "Echo UI"
	local subtitle = config.Subtitle or ""
	local size = config.Size or UDim2.fromOffset(720, 460)
	local loadingEnabled = config.LoadingEnabled
	if loadingEnabled == nil then loadingEnabled = true end
	local loadingTitle = config.LoadingTitle or title
	local loadingSubtitle = config.LoadingSubtitle or subtitle
	local loadingTime = config.LoadingTime or 3.5

	-- cleanup any previous instance with same name
	local existing = PlayerGui:FindFirstChild("EchoUI_" .. title)
	if existing then existing:Destroy() end

	local ScreenGui = make("ScreenGui", {
		Name = "EchoUI_" .. title,
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		IgnoreGuiInset = true,
		Parent = PlayerGui,
	})

	local Main = make("Frame", {
		Name = "Main",
		Size = size,
		Position = UDim2.new(0.5, -size.X.Offset / 2, 0.5, -size.Y.Offset / 2),
		BackgroundColor3 = Theme.Background,
		Visible = not loadingEnabled,
		Parent = ScreenGui,
	})
	corner(Main, 10)
	stroke(Main, Theme.Border, 1)

	local Scale = make("UIScale", {
		Scale = 1,
		Parent = Main,
	})

	-- ========================================================
	-- LOADING SCREEN
	-- ========================================================
	if loadingEnabled then
		local BlurEffect = make("BlurEffect", {
			Name = "EchoUI_LoadingBlur",
			Size = 0,
			Parent = Lighting,
		})
		tween(BlurEffect, { Size = 24 }, loadingTime * 0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

		local LoadFrame = make("Frame", {
			Name = "LoadingScreen",
			Size = UDim2.new(1, 0, 1, 0),
			Position = UDim2.new(0, 0, 0, 0),
			BackgroundColor3 = Color3.new(0, 0, 0),
			BackgroundTransparency = 0.25,
			BorderSizePixel = 0,
			ZIndex = 50,
			Parent = ScreenGui,
		})

		local NameLabel = make("TextLabel", {
			Text = loadingTitle,
			Font = Enum.Font.GothamBold,
			TextSize = 24,
			TextColor3 = Color3.new(1, 1, 1),
			BackgroundTransparency = 1,
			Size = UDim2.new(0, 400, 0, 30),
			Position = UDim2.new(0.5, -200, 0.5, -34),
			TextXAlignment = Enum.TextXAlignment.Center,
			ZIndex = 51,
			Parent = LoadFrame,
		})

		local SubLabel = make("TextLabel", {
			Text = loadingSubtitle,
			Font = Enum.Font.Gotham,
			TextSize = 13,
			TextColor3 = Color3.fromRGB(230, 230, 230),
			BackgroundTransparency = 1,
			Size = UDim2.new(0, 400, 0, 18),
			Position = UDim2.new(0.5, -200, 0.5, -2),
			TextXAlignment = Enum.TextXAlignment.Center,
			ZIndex = 51,
			Parent = LoadFrame,
		})

		local BarTrack = make("Frame", {
			Size = UDim2.new(0, 300, 0, 5),
			Position = UDim2.new(0.5, -150, 0.5, 24),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 0.8,
			BorderSizePixel = 0,
			ZIndex = 51,
			Parent = LoadFrame,
		})
		corner(BarTrack, 3)

		local BarFill = make("Frame", {
			Size = UDim2.new(0, 0, 1, 0),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0,
			ZIndex = 52,
			Parent = BarTrack,
		})
		corner(BarFill, 3)

		tween(BarFill, { Size = UDim2.new(1, 0, 1, 0) }, loadingTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

		task.delay(loadingTime, function()
			tween(LoadFrame, { BackgroundTransparency = 1 }, 0.35)
			tween(NameLabel, { TextTransparency = 1 }, 0.35)
			tween(SubLabel, { TextTransparency = 1 }, 0.35)
			tween(BarTrack, { BackgroundTransparency = 1 }, 0.35)
			tween(BarFill, { BackgroundTransparency = 1 }, 0.35)
			tween(BlurEffect, { Size = 0 }, 0.35)
			task.wait(0.35)
			LoadFrame:Destroy()
			BlurEffect:Destroy()
			Main.Visible = true
			Main.BackgroundTransparency = 1
			tween(Main, { BackgroundTransparency = 0 }, 0.2)
		end)
	end

	local TopBar = make("Frame", {
		Name = "TopBar",
		Size = UDim2.new(1, 0, 0, 44),
		BackgroundColor3 = Theme.Surface,
		Parent = Main,
	})
	corner(TopBar, 10)

	-- mask bottom corners of topbar so it looks flush
	make("Frame", {
		Size = UDim2.new(1, 0, 0, 10),
		Position = UDim2.new(0, 0, 1, -10),
		BackgroundColor3 = Theme.Surface,
		BorderSizePixel = 0,
		Parent = TopBar,
	})

	local TitleLabel = make("TextLabel", {
		Text = title,
		Font = Enum.Font.GothamBold,
		TextSize = 15,
		TextColor3 = Theme.Text,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 14, 0, 4),
		Size = UDim2.new(1, -28, 0, 18),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = TopBar,
	})

	make("TextLabel", {
		Text = subtitle,
		Font = Enum.Font.Gotham,
		TextSize = 11,
		TextColor3 = Theme.SubText,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 14, 0, 22),
		Size = UDim2.new(1, -28, 0, 16),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = TopBar,
	})

	local CloseBtn = make("TextButton", {
		Text = "×",
		Font = Enum.Font.GothamBold,
		TextSize = 20,
		TextColor3 = Theme.SubText,
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 32, 0, 32),
		Position = UDim2.new(1, -38, 0, 6),
		Parent = TopBar,
	})
	CloseBtn.MouseButton1Click:Connect(function()
		tween(Main, { Size = UDim2.fromOffset(0, 0) }, 0.2)
		task.wait(0.2)
		ScreenGui:Destroy()
	end)
	CloseBtn.MouseEnter:Connect(function() tween(CloseBtn, { TextColor3 = Theme.Danger }, 0.15) end)
	CloseBtn.MouseLeave:Connect(function() tween(CloseBtn, { TextColor3 = Theme.SubText }, 0.15) end)

	local MinimizeBtn = make("TextButton", {
		Text = "–",
		Font = Enum.Font.GothamBold,
		TextSize = 20,
		TextColor3 = Theme.SubText,
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 32, 0, 32),
		Position = UDim2.new(1, -70, 0, 6),
		Parent = TopBar,
	})
	MinimizeBtn.MouseEnter:Connect(function() tween(MinimizeBtn, { TextColor3 = Theme.Text }, 0.15) end)
	MinimizeBtn.MouseLeave:Connect(function() tween(MinimizeBtn, { TextColor3 = Theme.SubText }, 0.15) end)

	makeDraggable(Main, TopBar)

	-- Tab bar (left column)
	local TabBar = make("Frame", {
		Name = "TabBar",
		Size = UDim2.new(0, 130, 1, -44),
		Position = UDim2.new(0, 0, 0, 44),
		BackgroundColor3 = Theme.Surface,
		Parent = Main,
	})

	-- Player profile footer (bottom of sidebar) - parented to Main directly,
	-- NOT to TabBar, so the tab UIListLayout can't reposition it
	local ProfileFooter = make("Frame", {
		Name = "ProfileFooter",
		Size = UDim2.new(0, 130, 0, 56),
		Position = UDim2.new(0, 0, 1, -56),
		BackgroundColor3 = Theme.Surface,
		Parent = Main,
	})

	make("Frame", {
		Size = UDim2.new(1, -16, 0, 1),
		Position = UDim2.new(0, 8, 0, 0),
		BackgroundColor3 = Theme.Border,
		BorderSizePixel = 0,
		Parent = ProfileFooter,
	})

	local AvatarImage = make("ImageLabel", {
		Size = UDim2.new(0, 36, 0, 36),
		Position = UDim2.new(0, 8, 0, 10),
		BackgroundColor3 = Theme.SurfaceLight,
		Parent = ProfileFooter,
	})
	corner(AvatarImage, 18)
	stroke(AvatarImage, Theme.Border, 1)

	local ok, content = pcall(function()
		return Players:GetUserThumbnailAsync(
			LocalPlayer.UserId,
			Enum.ThumbnailType.HeadShot,
			Enum.ThumbnailSize.Size100x100
		)
	end)
	if ok and content then
		AvatarImage.Image = content
	end

	make("TextLabel", {
		Text = LocalPlayer.DisplayName,
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		TextColor3 = Theme.Text,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 52, 0, 12),
		Size = UDim2.new(1, -60, 0, 16),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = ProfileFooter,
	})

	make("TextLabel", {
		Text = "@" .. LocalPlayer.Name,
		Font = Enum.Font.Gotham,
		TextSize = 11,
		TextColor3 = Theme.SubText,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 52, 0, 28),
		Size = UDim2.new(1, -60, 0, 14),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = ProfileFooter,
	})

	local ProfileClickCatcher = make("TextButton", {
		Text = "",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		ZIndex = 2,
		Parent = ProfileFooter,
	})
	ProfileClickCatcher.MouseEnter:Connect(function() tween(ProfileFooter, { BackgroundColor3 = Theme.SurfaceLight }, 0.15) end)
	ProfileClickCatcher.MouseLeave:Connect(function() tween(ProfileFooter, { BackgroundColor3 = Theme.Surface }, 0.15) end)

	local TabList = make("UIListLayout", {
		Padding = UDim.new(0, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = TabBar,
	})
	make("UIPadding", {
		PaddingTop = UDim.new(0, 10),
		PaddingLeft = UDim.new(0, 8),
		PaddingRight = UDim.new(0, 8),
		PaddingBottom = UDim.new(0, 64),
		Parent = TabBar,
	})

	-- Playtime page (shown when the profile footer is clicked)
	local InjectedAt = tick()
	local PlaytimePage = make("Frame", {
		Name = "PlaytimePage",
		Size = UDim2.new(1, -20, 1, -20),
		Position = UDim2.new(0, 10, 0, 10),
		BackgroundTransparency = 1,
		Visible = false,
		Parent = nil, -- set once ContentArea exists, below
	})

	local PlaytimeLabel = make("TextLabel", {
		Text = "Playtime this session",
		Font = Enum.Font.GothamBold,
		TextSize = 16,
		TextColor3 = Theme.Text,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 24),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = PlaytimePage,
	})

	local PlaytimeValue = make("TextLabel", {
		Text = "00:00:00",
		Font = Enum.Font.GothamBold,
		TextSize = 32,
		TextColor3 = Theme.AccentAlt,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, 32),
		Size = UDim2.new(1, 0, 0, 44),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = PlaytimePage,
	})

	make("TextLabel", {
		Text = "Since the menu was injected",
		Font = Enum.Font.Gotham,
		TextSize = 12,
		TextColor3 = Theme.SubText,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, 80),
		Size = UDim2.new(1, 0, 0, 16),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = PlaytimePage,
	})

	-- Content area (right side)
	local ContentArea = make("Frame", {
		Name = "ContentArea",
		Size = UDim2.new(1, -130, 1, -44),
		Position = UDim2.new(0, 130, 0, 44),
		BackgroundTransparency = 1,
		Parent = Main,
	})

	PlaytimePage.Parent = ContentArea

	local Window = setmetatable({
		ScreenGui = ScreenGui,
		Main = Main,
		Scale = Scale,
		TabBar = TabBar,
		ContentArea = ContentArea,
		Tabs = {},
		ActiveTab = nil,
		OriginalSize = size,
		Minimized = false,
		HasShownMinimizeNotice = false,
		ToggleKey = config.ToggleKey or Enum.KeyCode.RightShift,
		PlaytimePage = PlaytimePage,
	}, EchoUI)

	function Window:ShowPlaytime()
		for _, t in ipairs(self.Tabs) do
			t.Page.Visible = false
			tween(t.Button, { BackgroundTransparency = 1 }, 0.15)
			tween(t.Label, { TextColor3 = Theme.SubText }, 0.15)
			if t.Icon then
				tween(t.Icon, { ImageColor3 = Theme.SubText }, 0.15)
			end
		end
		PlaytimePage.Visible = true
		self.ActiveTab = nil
	end

	function Window:ToggleMinimize()
		self.Minimized = not self.Minimized

		if self.Minimized then
			tween(self.Main, { Size = UDim2.fromOffset(0, 0) }, 0.2)
			task.delay(0.2, function()
				self.Main.Visible = false
			end)

			if not self.HasShownMinimizeNotice then
				self.HasShownMinimizeNotice = true
				task.delay(0.25, function()
					EchoUI:Notify({
						Title = "Menu Minimized",
						Content = "Press " .. self.ToggleKey.Name .. " to bring it back.",
						Duration = 5,
					})
				end)
			end
		else
			self.Main.Visible = true
			self.Main.Size = UDim2.fromOffset(0, 0)
			tween(self.Main, { Size = self.OriginalSize }, 0.2)
		end
	end

	MinimizeBtn.MouseButton1Click:Connect(function()
		Window:ToggleMinimize()
	end)

	UserInputService.InputBegan:Connect(function(input, processed)
		if UserInputService:GetFocusedTextBox() then return end
		if input.KeyCode == Window.ToggleKey then
			Window:ToggleMinimize()
		end
	end)

	ProfileClickCatcher.MouseButton1Click:Connect(function()
		Window:ShowPlaytime()
	end)

	task.spawn(function()
		while ScreenGui.Parent do
			if PlaytimePage.Visible then
				local elapsed = math.floor(tick() - InjectedAt)
				local h = math.floor(elapsed / 3600)
				local m = math.floor((elapsed % 3600) / 60)
				local s = elapsed % 60
				PlaytimeValue.Text = string.format("%02d:%02d:%02d", h, m, s)
			end
			task.wait(1)
		end
	end)

	-- percent: 50 to 200 (e.g. 100 = normal size, 150 = 150%)
	function Window:SetScale(percent)
		percent = math.clamp(percent, 50, 200)
		tween(self.Scale, { Scale = percent / 100 }, 0.15)
		return percent
	end

	function Window:GetScale()
		return self.Scale.Scale * 100
	end

	return Window
end

-- ============================================================
-- TAB
-- ============================================================
function EchoUI:CreateTab(name, icon)
	local TabButton = make("TextButton", {
		Text = "",
		BackgroundColor3 = Theme.SurfaceLight,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 32),
		LayoutOrder = #self.Tabs,
		Parent = self.TabBar,
	})
	corner(TabButton, 6)

	local IconImage
	local labelXOffset = 12
	if icon then
		IconImage = make("ImageLabel", {
			BackgroundTransparency = 1,
			ImageColor3 = Theme.SubText,
			Size = UDim2.new(0, 16, 0, 16),
			Position = UDim2.new(0, 10, 0.5, -8),
			Parent = TabButton,
		})

		if type(icon) == "table" then
			-- sprite-sheet style icon, e.g. from lucide-roblox / icons.rest
			-- icon = { Id = "rbxassetid://123", Offset = Vector2.new(x, y), Size = Vector2.new(w, h) }
			IconImage.Image = icon.Id
			if icon.Offset then IconImage.ImageRectOffset = icon.Offset end
			if icon.Size then IconImage.ImageRectSize = icon.Size end
		else
			-- plain rbxassetid string
			IconImage.Image = icon
		end

		labelXOffset = 34
	end

	local TabLabel = make("TextLabel", {
		Text = name,
		Font = Enum.Font.Gotham,
		TextSize = 13,
		TextColor3 = Theme.SubText,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, labelXOffset, 0, 0),
		Size = UDim2.new(1, -labelXOffset - 8, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = TabButton,
	})

	local Page = make("ScrollingFrame", {
		Name = name .. "Page",
		Size = UDim2.new(1, -20, 1, -20),
		Position = UDim2.new(0, 10, 0, 10),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = Theme.Accent,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Visible = false,
		Parent = self.ContentArea,
	})
	local Layout = make("UIListLayout", {
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = Page,
	})

	local Tab = {
		Button = TabButton,
		Page = Page,
		Window = self,
	}

	local function activate()
		for _, t in ipairs(self.Tabs) do
			t.Page.Visible = false
			tween(t.Button, { BackgroundTransparency = 1 }, 0.15)
			tween(t.Label, { TextColor3 = Theme.SubText }, 0.15)
			if t.Icon then
				tween(t.Icon, { ImageColor3 = Theme.SubText }, 0.15)
			end
		end
		if self.PlaytimePage then
			self.PlaytimePage.Visible = false
		end
		Page.Visible = true
		tween(TabButton, { BackgroundTransparency = 0 }, 0.15)
		tween(TabLabel, { TextColor3 = Theme.Text }, 0.15)
		if IconImage then
			tween(IconImage, { ImageColor3 = Theme.AccentAlt }, 0.15)
		end
		self.ActiveTab = Tab
	end

	TabButton.MouseButton1Click:Connect(activate)

	Tab.Label = TabLabel
	Tab.Icon = IconImage

	table.insert(self.Tabs, Tab)
	if #self.Tabs == 1 then activate() end

	-- =========================================================
	-- ELEMENT: Button
	-- =========================================================
	function Tab:CreateButton(opts)
		opts = opts or {}
		local Btn = make("TextButton", {
			Text = opts.Name or "Button",
			Font = Enum.Font.Gotham,
			TextSize = 13,
			TextColor3 = Theme.Text,
			BackgroundColor3 = Theme.Surface,
			Size = UDim2.new(1, 0, 0, 36),
			Parent = Page,
		})
		corner(Btn, 6)
		stroke(Btn, Theme.Border, 1)

		Btn.MouseEnter:Connect(function() tween(Btn, { BackgroundColor3 = Theme.SurfaceLight }, 0.15) end)
		Btn.MouseLeave:Connect(function() tween(Btn, { BackgroundColor3 = Theme.Surface }, 0.15) end)
		Btn.MouseButton1Click:Connect(function()
			if opts.Callback then
				local ok, err = pcall(opts.Callback)
				if not ok then warn("[EchoUI] Button callback error: " .. tostring(err)) end
			end
		end)

		return Btn
	end

	-- =========================================================
	-- ELEMENT: Toggle
	-- =========================================================
	function Tab:CreateToggle(opts)
		opts = opts or {}
		local state = opts.CurrentValue or false
		local hasColor = opts.Color ~= nil

		local Holder = make("Frame", {
			Size = UDim2.new(1, 0, 0, 36),
			BackgroundColor3 = Theme.Surface,
			ClipsDescendants = false,
			Parent = Page,
		})
		corner(Holder, 6)
		stroke(Holder, Theme.Border, 1)

		make("TextLabel", {
			Text = opts.Name or "Toggle",
			Font = Enum.Font.Gotham,
			TextSize = 13,
			TextColor3 = Theme.Text,
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 12, 0, 0),
			Size = UDim2.new(1, hasColor and -96 or -60, 1, 0),
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = Holder,
		})

		local Switch = make("Frame", {
			Size = UDim2.new(0, 38, 0, 20),
			Position = UDim2.new(1, -48, 0.5, -10),
			BackgroundColor3 = state and Theme.Accent or Theme.SurfaceLight,
			Parent = Holder,
		})
		corner(Switch, 10)

		local Knob = make("Frame", {
			Size = UDim2.new(0, 16, 0, 16),
			Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8),
			BackgroundColor3 = Theme.Text,
			Parent = Switch,
		})
		corner(Knob, 8)

		local ClickCatcher = make("TextButton", {
			Text = "",
			BackgroundTransparency = 1,
			Size = UDim2.new(1, hasColor and -32 or 0, 1, 0),
			Parent = Holder,
		})

		local colorSwatch = nil
		if hasColor then
			colorSwatch = attachColorSwatch(Holder, UDim2.new(1, -84, 0.5, -10), opts.Color, opts.ColorCallback)
		end

		local function setState(newState, fire)
			state = newState
			tween(Switch, { BackgroundColor3 = state and Theme.Accent or Theme.SurfaceLight }, 0.15)
			tween(Knob, { Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8) }, 0.15)
			if fire ~= false and opts.Callback then
				local ok, err = pcall(opts.Callback, state)
				if not ok then warn("[EchoUI] Toggle callback error: " .. tostring(err)) end
			end
		end

		ClickCatcher.MouseButton1Click:Connect(function() setState(not state) end)

		if state and opts.Callback then
			pcall(opts.Callback, state)
		end

		return {
			Set = function(_, v) setState(v) end,
			Get = function() return state end,
			SetColor = function(_, c) if colorSwatch then colorSwatch:Set(c) end end,
			GetColor = function() return colorSwatch and colorSwatch:Get() or nil end,
		}
	end

	-- =========================================================
	-- ELEMENT: Slider
	-- =========================================================
	function Tab:CreateSlider(opts)
		opts = opts or {}
		local min = (opts.Range and opts.Range[1]) or 0
		local max = (opts.Range and opts.Range[2]) or 100
		local increment = opts.Increment or 1
		local value = opts.CurrentValue or min

		local Holder = make("Frame", {
			Size = UDim2.new(1, 0, 0, 48),
			BackgroundColor3 = Theme.Surface,
			Parent = Page,
		})
		corner(Holder, 6)
		stroke(Holder, Theme.Border, 1)

		local Label = make("TextLabel", {
			Text = opts.Name or "Slider",
			Font = Enum.Font.Gotham,
			TextSize = 13,
			TextColor3 = Theme.Text,
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 12, 0, 6),
			Size = UDim2.new(1, -70, 0, 18),
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = Holder,
		})

		local ValueLabel = make("TextLabel", {
			Text = tostring(value),
			Font = Enum.Font.GothamBold,
			TextSize = 13,
			TextColor3 = Theme.AccentAlt,
			BackgroundTransparency = 1,
			Position = UDim2.new(1, -58, 0, 6),
			Size = UDim2.new(0, 46, 0, 18),
			TextXAlignment = Enum.TextXAlignment.Right,
			Parent = Holder,
		})

		local Track = make("Frame", {
			Size = UDim2.new(1, -24, 0, 6),
			Position = UDim2.new(0, 12, 0, 32),
			BackgroundColor3 = Theme.SurfaceLight,
			Parent = Holder,
		})
		corner(Track, 3)

		local Fill = make("Frame", {
			Size = UDim2.new((value - min) / (max - min), 0, 1, 0),
			BackgroundColor3 = Theme.Accent,
			Parent = Track,
		})
		corner(Fill, 3)

		local dragging = false

		local function setFromAlpha(alpha)
			alpha = math.clamp(alpha, 0, 1)
			local raw = min + (max - min) * alpha
			raw = math.floor(raw / increment + 0.5) * increment
			raw = math.clamp(raw, min, max)
			value = raw
			Fill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
			ValueLabel.Text = tostring(value)
			if opts.Callback then
				local ok, err = pcall(opts.Callback, value)
				if not ok then warn("[EchoUI] Slider callback error: " .. tostring(err)) end
			end
		end

		Track.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				local alpha = (input.Position.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X
				setFromAlpha(alpha)
			end
		end)

		UserInputService.InputChanged:Connect(function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				local alpha = (input.Position.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X
				setFromAlpha(alpha)
			end
		end)

		UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = false
			end
		end)

		return {
			Set = function(_, v) setFromAlpha((v - min) / (max - min)) end,
			Get = function() return value end,
		}
	end

	-- =========================================================
	-- ELEMENT: Color Picker
	-- =========================================================
	function Tab:CreateColorPicker(opts)
		opts = opts or {}
		local color = opts.Color or Color3.fromRGB(255, 255, 255)
		local expanded = false

		local Holder = make("Frame", {
			Size = UDim2.new(1, 0, 0, 36),
			BackgroundColor3 = Theme.Surface,
			ClipsDescendants = false,
			Parent = Page,
		})
		corner(Holder, 6)
		stroke(Holder, Theme.Border, 1)

		make("TextLabel", {
			Text = opts.Name or "Color",
			Font = Enum.Font.Gotham,
			TextSize = 13,
			TextColor3 = Theme.Text,
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 12, 0, 0),
			Size = UDim2.new(1, -50, 1, 0),
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = Holder,
		})

		local SwatchBtn = make("TextButton", {
			Text = "",
			BackgroundColor3 = color,
			Size = UDim2.new(0, 26, 0, 20),
			Position = UDim2.new(1, -36, 0.5, -10),
			Parent = Holder,
		})
		corner(SwatchBtn, 5)
		stroke(SwatchBtn, Theme.Border, 1)

		local Panel = make("Frame", {
			Size = UDim2.new(1, 0, 0, 110),
			Position = UDim2.new(0, 0, 1, 4),
			BackgroundColor3 = Theme.SurfaceLight,
			Visible = false,
			ZIndex = 5,
			Parent = Holder,
		})
		corner(Panel, 6)
		stroke(Panel, Theme.Border, 1)
		make("UIPadding", {
			PaddingTop = UDim.new(0, 8),
			PaddingLeft = UDim.new(0, 10),
			PaddingRight = UDim.new(0, 10),
			Parent = Panel,
		})

		local r, g, b = math.floor(color.R * 255), math.floor(color.G * 255), math.floor(color.B * 255)

		local function fireCallback()
			SwatchBtn.BackgroundColor3 = color
			if opts.Callback then
				local ok, err = pcall(opts.Callback, color)
				if not ok then warn("[EchoUI] ColorPicker callback error: " .. tostring(err)) end
			end
		end

		local function makeChannelSlider(labelText, initial, yOffset, channelColor, onChange)
			local Row = make("Frame", {
				Size = UDim2.new(1, 0, 0, 26),
				Position = UDim2.new(0, 0, 0, yOffset),
				BackgroundTransparency = 1,
				ZIndex = 5,
				Parent = Panel,
			})

			make("TextLabel", {
				Text = labelText,
				Font = Enum.Font.GothamBold,
				TextSize = 11,
				TextColor3 = channelColor,
				BackgroundTransparency = 1,
				Size = UDim2.new(0, 16, 1, 0),
				ZIndex = 5,
				Parent = Row,
			})

			local Track = make("Frame", {
				Size = UDim2.new(1, -50, 0, 6),
				Position = UDim2.new(0, 20, 0.5, -3),
				BackgroundColor3 = Theme.Background,
				ZIndex = 5,
				Parent = Row,
			})
			corner(Track, 3)

			local Fill = make("Frame", {
				Size = UDim2.new(initial / 255, 0, 1, 0),
				BackgroundColor3 = channelColor,
				ZIndex = 5,
				Parent = Track,
			})
			corner(Fill, 3)

			local ValLabel = make("TextLabel", {
				Text = tostring(initial),
				Font = Enum.Font.Gotham,
				TextSize = 11,
				TextColor3 = Theme.SubText,
				BackgroundTransparency = 1,
				Position = UDim2.new(1, -26, 0, 0),
				Size = UDim2.new(0, 26, 1, 0),
				TextXAlignment = Enum.TextXAlignment.Right,
				ZIndex = 5,
				Parent = Row,
			})

			local dragging = false
			local function setFromAlpha(alpha)
				alpha = math.clamp(alpha, 0, 1)
				local val = math.floor(alpha * 255 + 0.5)
				Fill.Size = UDim2.new(alpha, 0, 1, 0)
				ValLabel.Text = tostring(val)
				onChange(val)
			end

			Track.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					dragging = true
					local alpha = (input.Position.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X
					setFromAlpha(alpha)
				end
			end)
			UserInputService.InputChanged:Connect(function(input)
				if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
					local alpha = (input.Position.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X
					setFromAlpha(alpha)
				end
			end)
			UserInputService.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					dragging = false
				end
			end)
		end

		makeChannelSlider("R", r, 0, Color3.fromRGB(255, 90, 90), function(v)
			r = v
			color = Color3.fromRGB(r, g, b)
			fireCallback()
		end)
		makeChannelSlider("G", g, 32, Color3.fromRGB(90, 255, 120), function(v)
			g = v
			color = Color3.fromRGB(r, g, b)
			fireCallback()
		end)
		makeChannelSlider("B", b, 64, Color3.fromRGB(100, 140, 255), function(v)
			b = v
			color = Color3.fromRGB(r, g, b)
			fireCallback()
		end)

		SwatchBtn.MouseButton1Click:Connect(function()
			expanded = not expanded
			Panel.Visible = expanded
		end)

		return {
			Set = function(_, c)
				color = c
				r, g, b = math.floor(c.R * 255), math.floor(c.G * 255), math.floor(c.B * 255)
				SwatchBtn.BackgroundColor3 = color
			end,
			Get = function() return color end,
		}
	end

	-- =========================================================
	-- ELEMENT: Dropdown
	-- =========================================================
	function Tab:CreateDropdown(opts)
		opts = opts or {}
		local options = opts.Options or {}
		local selected = opts.CurrentOption

		local Holder = make("Frame", {
			Size = UDim2.new(1, 0, 0, 36),
			BackgroundColor3 = Theme.Surface,
			ClipsDescendants = false,
			Parent = Page,
		})
		corner(Holder, 6)
		stroke(Holder, Theme.Border, 1)

		local Label = make("TextButton", {
			Text = (selected and tostring(selected) or opts.Name or "Select") .. "  ▾",
			Font = Enum.Font.Gotham,
			TextSize = 13,
			TextColor3 = Theme.Text,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -12, 1, 0),
			Position = UDim2.new(0, 12, 0, 0),
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = Holder,
		})

		local ListFrame = make("Frame", {
			Size = UDim2.new(1, 0, 0, math.min(#options, 5) * 30),
			Position = UDim2.new(0, 0, 1, 4),
			BackgroundColor3 = Theme.SurfaceLight,
			Visible = false,
			ZIndex = 5,
			Parent = Holder,
		})
		corner(ListFrame, 6)
		stroke(ListFrame, Theme.Border, 1)

		local ListLayout = make("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Parent = ListFrame })
		local ScrollFrame = make("ScrollingFrame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 2,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ZIndex = 5,
			Parent = ListFrame,
		})
		ListLayout.Parent = ScrollFrame

		local open = false
		Label.MouseButton1Click:Connect(function()
			open = not open
			ListFrame.Visible = open
		end)

		for i, opt in ipairs(options) do
			local OptBtn = make("TextButton", {
				Text = tostring(opt),
				Font = Enum.Font.Gotham,
				TextSize = 12,
				TextColor3 = Theme.Text,
				BackgroundColor3 = Theme.SurfaceLight,
				Size = UDim2.new(1, 0, 0, 28),
				LayoutOrder = i,
				ZIndex = 5,
				Parent = ScrollFrame,
			})
			OptBtn.MouseEnter:Connect(function() tween(OptBtn, { BackgroundColor3 = Theme.Accent }, 0.1) end)
			OptBtn.MouseLeave:Connect(function() tween(OptBtn, { BackgroundColor3 = Theme.SurfaceLight }, 0.1) end)
			OptBtn.MouseButton1Click:Connect(function()
				selected = opt
				Label.Text = tostring(opt) .. "  ▾"
				open = false
				ListFrame.Visible = false
				if opts.Callback then
					local ok, err = pcall(opts.Callback, opt)
					if not ok then warn("[EchoUI] Dropdown callback error: " .. tostring(err)) end
				end
			end)
		end

		return {
			Get = function() return selected end,
		}
	end

	-- =========================================================
	-- ELEMENT: Input (textbox)
	-- =========================================================
	function Tab:CreateInput(opts)
		opts = opts or {}

		local Holder = make("Frame", {
			Size = UDim2.new(1, 0, 0, 36),
			BackgroundColor3 = Theme.Surface,
			Parent = Page,
		})
		corner(Holder, 6)
		stroke(Holder, Theme.Border, 1)

		local Box = make("TextBox", {
			PlaceholderText = opts.PlaceholderText or opts.Name or "Enter text...",
			Text = "",
			Font = Enum.Font.Gotham,
			TextSize = 13,
			TextColor3 = Theme.Text,
			PlaceholderColor3 = Theme.SubText,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -24, 1, 0),
			Position = UDim2.new(0, 12, 0, 0),
			ClearTextOnFocus = false,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = Holder,
		})

		Box.FocusLost:Connect(function(enterPressed)
			if opts.Callback then
				local ok, err = pcall(opts.Callback, Box.Text, enterPressed)
				if not ok then warn("[EchoUI] Input callback error: " .. tostring(err)) end
			end
			if opts.RemoveTextAfterFocusLost then
				Box.Text = ""
			end
		end)

		return {
			Set = function(_, v) Box.Text = v end,
			Get = function() return Box.Text end,
		}
	end

	-- =========================================================
	-- ELEMENT: Keybind
	-- =========================================================
	function Tab:CreateKeybind(opts)
		opts = opts or {}
		local currentKey = opts.CurrentKeybind or Enum.KeyCode.RightShift
		local listening = false

		local Holder = make("Frame", {
			Size = UDim2.new(1, 0, 0, 36),
			BackgroundColor3 = Theme.Surface,
			Parent = Page,
		})
		corner(Holder, 6)
		stroke(Holder, Theme.Border, 1)

		make("TextLabel", {
			Text = opts.Name or "Keybind",
			Font = Enum.Font.Gotham,
			TextSize = 13,
			TextColor3 = Theme.Text,
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 12, 0, 0),
			Size = UDim2.new(1, -110, 1, 0),
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = Holder,
		})

		local KeyBtn = make("TextButton", {
			Text = currentKey.Name,
			Font = Enum.Font.GothamBold,
			TextSize = 12,
			TextColor3 = Theme.AccentAlt,
			BackgroundColor3 = Theme.SurfaceLight,
			Size = UDim2.new(0, 90, 0, 26),
			Position = UDim2.new(1, -98, 0.5, -13),
			Parent = Holder,
		})
		corner(KeyBtn, 5)

		KeyBtn.MouseButton1Click:Connect(function()
			if listening then return end
			listening = true
			local originalText = KeyBtn.Text
			KeyBtn.Text = "..."

			local conn
			conn = UserInputService.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.Keyboard then
					currentKey = input.KeyCode
					KeyBtn.Text = currentKey.Name
					listening = false
					conn:Disconnect()
					if opts.Callback then
						local ok, err = pcall(opts.Callback, currentKey)
						if not ok then warn("[EchoUI] Keybind callback error: " .. tostring(err)) end
					end
				end
			end)
		end)

		return {
			Set = function(_, key) currentKey = key; KeyBtn.Text = key.Name end,
			Get = function() return currentKey end,
		}
	end

	-- =========================================================
	-- ELEMENT: Section (visual divider/label)
	-- =========================================================
	function Tab:CreateSection(name)
		make("TextLabel", {
			Text = name,
			Font = Enum.Font.GothamBold,
			TextSize = 12,
			TextColor3 = Theme.AccentAlt,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 20),
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = Page,
		})
	end

	return Tab
end

-- ============================================================
-- NOTIFY
-- ============================================================
function EchoUI:Notify(opts)
	opts = opts or {}
	local title = opts.Title or "Notification"
	local content = opts.Content or ""
	local duration = opts.Duration or 3

	local holder = PlayerGui:FindFirstChild("EchoUI_Notifications")
	if not holder then
		holder = make("ScreenGui", { Name = "EchoUI_Notifications", ResetOnSpawn = false, Parent = PlayerGui })
		make("UIListLayout", {
			Padding = UDim.new(0, 8),
			VerticalAlignment = Enum.VerticalAlignment.Bottom,
			HorizontalAlignment = Enum.HorizontalAlignment.Right,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = holder,
		})
		make("Frame", { -- anchor frame for the list layout to align against
			Size = UDim2.new(0, 1, 1, 0),
			Position = UDim2.new(1, -280, 0, 0),
			BackgroundTransparency = 1,
			Parent = holder,
		})
	end

	local Notif = make("Frame", {
		Size = UDim2.new(0, 260, 0, 64),
		Position = UDim2.new(1, -280, 1, -80),
		AnchorPoint = Vector2.new(0, 0),
		BackgroundColor3 = Theme.Surface,
		Parent = holder,
	})
	corner(Notif, 8)
	stroke(Notif, Theme.Accent, 1)

	make("TextLabel", {
		Text = title,
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		TextColor3 = Theme.Text,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 10, 0, 8),
		Size = UDim2.new(1, -20, 0, 18),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = Notif,
	})

	make("TextLabel", {
		Text = content,
		Font = Enum.Font.Gotham,
		TextSize = 12,
		TextColor3 = Theme.SubText,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 10, 0, 28),
		Size = UDim2.new(1, -20, 0, 30),
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		Parent = Notif,
	})

	Notif.BackgroundTransparency = 1
	tween(Notif, { BackgroundTransparency = 0 }, 0.2)

	task.delay(duration, function()
		if Notif and Notif.Parent then
			tween(Notif, { BackgroundTransparency = 1 }, 0.3)
			task.wait(0.3)
			Notif:Destroy()
		end
	end)
end

return EchoUI
