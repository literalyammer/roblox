local THIS = script.Parent

local MAIN_FRAME = THIS.MAIN_FRAME
local CONTENT = MAIN_FRAME.CONTENT
local TOPBAR = MAIN_FRAME.TOPBAR
local UNDERLINE = CONTENT.CONTROLS.UNDER
local PLAYER = game.Players.LocalPlayer
local MOUSE = PLAYER:GetMouse()
local STYLE = require(script.STYLE)
local CHAR = nil --PLAYER.Character or PLAYER.CharacterAdded:Wait()

local TOOLTIP = THIS:FindFirstChild('TOOLTIP') or script:FindFirstChild('TOOLTIP')
TOOLTIP.Parent = THIS
TOOLTIP:GetPropertyChangedSignal('BackgroundTransparency'):Connect(function()
	TOOLTIP.TEXT.TextTransparency = TOOLTIP.BackgroundTransparency
	TOOLTIP.UIStroke.Transparency = TOOLTIP.BackgroundTransparency
end)
TOOLTIP.BackgroundTransparency = 1

--PLAYER.CharacterAdded:Connect(function(C)
--	task.wait()
--	CHAR = C
--end)

local DEPENDENCIES = script.DEPENDENCIES

local COLORFRAME = require(script.COLORFRAME)
local BACKEND = require(script.BACKEND_DATA)

local TWEEN_SERVICE = game:GetService('TweenService')
local RUN_SERVICE = game:GetService('RunService')
local COLLECTION_SERVICE = game:GetService('CollectionService')
local USER_INPUT_SERVICE = game:GetService('UserInputService')
local KEYBOARD_ENABLED = not USER_INPUT_SERVICE.KeyboardEnabled -- 09/14 Checks if keyboard is enabled to show/hide expand button
print(`CORTEX REMOTECONTROLS CLIENT CHECK : KEYBOARD IS {not KEYBOARD_ENABLED and 'ENABLED' or 'DISABLED'}`)

local CURRENT_VERSION = '2.5'

local CONNECTIONS = {}

local function TWEEN_PLAY(INSTANCE, TWEEN_INFO, PROPERTIES, WAIT_UNTIL_COMPLETION)

	local TWEEN
	local SUCCESS, RESULT = pcall(function()
		TWEEN = TWEEN_SERVICE:Create(INSTANCE, TWEEN_INFO, PROPERTIES)
		TWEEN:Play()
		if (WAIT_UNTIL_COMPLETION) then
			TWEEN.Completed:Wait()
		end
	end)
	if (not SUCCESS) then
		return warn(string.format('TWEEN CREATION ERROR :: %s', string.upper(RESULT)))
	else
		return TWEEN
	end

end

local function GET_POSITION(ELEMENT, TARGET, ANCHOR_X)

	return ((TARGET.AbsolutePosition.X+(TARGET.AbsoluteSize.X*ANCHOR_X))-ELEMENT.AbsolutePosition.X)

end
local function GET_LENGTH(ELEMENT, TARGET, ANCHOR_X)

	return math.abs(ELEMENT.AbsolutePosition.X-(TARGET.AbsolutePosition.X+(TARGET.AbsoluteSize.X*ANCHOR_X)))

end

local DEBOUNCE = false
local TOPBAR_BUTTONS = {}
local PREVIOUS_BUTTON
local CURRENT_PAGE = 'CONTROLS'
local CURRENT_ELEVATOR
local ELEVATORS = {}
local ELEVATOR_BUTTONS = {}
local REMOTE = game.ReplicatedStorage:WaitForChild('CORTEX_RC_REMOTE')
local DATA_REMOTE = THIS:WaitForChild('DATA_REMOTE')
local ELEVATOR_CONNECTIONS = {}
local READONLY_VALUES = {}
local IS_OPEN = false

MAIN_FRAME.TOPBAR.TITLE.Text = string.format('Cortex RemoteControls Hub v%s', CURRENT_VERSION)
local ADDON_DATA = {}

local LAST_FUNCTION_INVOKE = os.clock()
local function HANDLE_INPUT_TYPE(b, CONTENT_FRAME, COLOR)
	if (b.INPUT_TYPE == 'TRIGGER' or b.INPUT_TYPE == 'TRIGGER_HOLD') then
		local TRIGGER_BUTTON = DEPENDENCIES.TRIGGER_BUTTON:Clone()
		TRIGGER_BUTTON.Parent = CONTENT_FRAME
		TRIGGER_BUTTON.Name = b.LABEL
		TRIGGER_BUTTON.MASK.LABEL.Text = b.LABEL
		TRIGGER_BUTTON.LayoutOrder = b.INDEX
		local CONNECTION = TRIGGER_BUTTON.MASK.UIStroke:GetPropertyChangedSignal('Color'):Connect(function()
			TRIGGER_BUTTON.MASK.LABEL.TextColor3 = TRIGGER_BUTTON.MASK.UIStroke.Color
		end)
		local CONNECTION = TRIGGER_BUTTON.MouseEnter:Connect(function()
			TWEEN_PLAY(TRIGGER_BUTTON.MASK.UIStroke, TweenInfo.new(.15, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {Color=COLOR})
		end)
		table.insert(CONNECTIONS, CONNECTION)
		local CONNECTION = TRIGGER_BUTTON.MouseLeave:Connect(function()
			TWEEN_PLAY(TRIGGER_BUTTON.MASK.UIStroke, TweenInfo.new(.15, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {Color=Color3.new(1, 1, 1)})
		end)
		table.insert(CONNECTIONS, CONNECTION)
		if (b.INPUT_TYPE == 'TRIGGER') then
			local CONNECTION = TRIGGER_BUTTON.MouseButton1Click:Connect(function()
				if ((os.clock()-LAST_FUNCTION_INVOKE) <= .1) then return end
				LAST_FUNCTION_INVOKE = os.clock()
				b.INVOKE_FUNCTION(REMOTE, CURRENT_ELEVATOR, '')
			end)
			table.insert(CONNECTIONS, CONNECTION)
		elseif (b.INPUT_TYPE == 'TRIGGER_HOLD') then
			local CONNECTION = TRIGGER_BUTTON.MouseButton1Down:Connect(function()
				b.INVOKE_FUNCTION_DOWN(REMOTE, CURRENT_ELEVATOR, '')
			end)
			table.insert(CONNECTIONS, CONNECTION)
			local CONNECTION = TRIGGER_BUTTON.MouseButton1Up:Connect(function()
				b.INVOKE_FUNCTION_RELEASE(REMOTE, CURRENT_ELEVATOR, '')
			end)
			table.insert(CONNECTIONS, CONNECTION)
		end
	elseif (b.INPUT_TYPE == 'READONLY') then
		local READONLY_VALUE = DEPENDENCIES.READONLY_VALUE:Clone()
		READONLY_VALUE.Parent = CONTENT_FRAME
		READONLY_VALUE.Name = b.LABEL
		READONLY_VALUE.LayoutOrder = b.INDEX
		if (not b.REFRESH) then
			b.REFRESH = function(ELEVATOR)
				task.spawn(function()
					local VALUE = b.VALUE_TO_LISTEN(ELEVATOR)
					if (VALUE) then
						local UPDATE_CONNECTION = VALUE:GetPropertyChangedSignal(b.PROPERTY_CHANGED_SIGNAL_NAME):Connect(function()
							b.PROPERTY_CHANGED_INVOKE(REMOTE, ELEVATOR, READONLY_VALUE.VALUE, VALUE.Value)
						end)
						b.PROPERTY_CHANGED_INVOKE(REMOTE, ELEVATOR, READONLY_VALUE.VALUE, VALUE.Value)
						table.insert(ELEVATOR_CONNECTIONS, UPDATE_CONNECTION)
						READONLY_VALUE.NAME.Text = string.upper(b.LABEL)
					end
				end)
			end
		end
		table.insert(READONLY_VALUES, {READONLY_VALUE, b})
	elseif (b.INPUT_TYPE == 'NUMERICAL') then
		local NUMERICAL_INPUT = DEPENDENCIES.NUMERICAL_INPUT:Clone()
		NUMERICAL_INPUT.Parent = CONTENT_FRAME
		NUMERICAL_INPUT.MASK.INPUT.Text = ''
		NUMERICAL_INPUT.MASK.BUTTON.MASK.TEXT.Text = b.LABEL
		NUMERICAL_INPUT.LayoutOrder = b.INDEX
		local BUTTON_LOCKED = false
		local function VALIDATE_ENTRY()
			if (not BUTTON_LOCKED) then
				local VALUE = tonumber(NUMERICAL_INPUT.MASK.INPUT.Text)
				NUMERICAL_INPUT.MASK.INPUT.Text = ''
				if (not VALUE) then
					BUTTON_LOCKED = true
					for i=1,2 do
						TWEEN_PLAY(NUMERICAL_INPUT.MASK.UIStroke, TweenInfo.new(.23, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Color=Color3.new(1, 0.309804, 0.0784314)}, true)
						TWEEN_PLAY(NUMERICAL_INPUT.MASK.UIStroke, TweenInfo.new(.23, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Color=Color3.new(1, 1, 1)}, true)
					end
					BUTTON_LOCKED = false
					return
				end
				task.spawn(function()
					TWEEN_PLAY(NUMERICAL_INPUT.MASK.UIStroke, TweenInfo.new(.23, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Color=COLOR}, true)
					TWEEN_PLAY(NUMERICAL_INPUT.MASK.UIStroke, TweenInfo.new(.23, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Color=Color3.new(1, 1, 1)}, true)
				end)
				b.INVOKE_FUNCTION(REMOTE, CURRENT_ELEVATOR, VALUE)
			end
		end
		local CONNECTION = NUMERICAL_INPUT.MASK.BUTTON.MASK.UIStroke:GetPropertyChangedSignal('Color'):Connect(function()
			NUMERICAL_INPUT.MASK.BUTTON.MASK.TEXT.TextColor3 = NUMERICAL_INPUT.MASK.BUTTON.MASK.UIStroke.Color
		end)
		table.insert(CONNECTIONS, CONNECTION)
		local CONNECTION = NUMERICAL_INPUT.MASK.BUTTON.MouseEnter:Connect(function()
			if (BUTTON_LOCKED) then return end
			TWEEN_PLAY(NUMERICAL_INPUT.MASK.BUTTON.MASK.UIStroke, TweenInfo.new(.15, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {Color=COLOR})
		end)
		table.insert(CONNECTIONS, CONNECTION)
		local CONNECTION = NUMERICAL_INPUT.MASK.BUTTON.MouseLeave:Connect(function()
			if (BUTTON_LOCKED) then return end
			TWEEN_PLAY(NUMERICAL_INPUT.MASK.BUTTON.MASK.UIStroke, TweenInfo.new(.15, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {Color=Color3.new(1, 1, 1)})
		end)
		table.insert(CONNECTIONS, CONNECTION)
		local CONNECTION = NUMERICAL_INPUT.MASK.BUTTON.MouseButton1Click:Connect(function()
			VALIDATE_ENTRY()
		end)
		table.insert(CONNECTIONS, CONNECTION)
		local CONNECTION = NUMERICAL_INPUT.MASK.INPUT.FocusLost:Connect(function()
			VALIDATE_ENTRY()
		end)
		table.insert(CONNECTIONS, CONNECTION)
	end
end

RUN_SERVICE:BindToRenderStep('TOOLTIP_BIND', Enum.RenderPriority.Camera.Value, function()
	TOOLTIP.Position = UDim2.new(0, MOUSE.X-((TOOLTIP.AbsoluteSize.X/2)*TOOLTIP.AnchorPoint.X), 0, 25+MOUSE.Y+((TOOLTIP.AbsoluteSize.Y/2)*TOOLTIP.AnchorPoint.Y))
end)

for i,v in pairs(BACKEND.BUTTONS) do

	local COLORFRAME_DATA = COLORFRAME.TOP_BUTTONS[i]
	local NEW_BUTTON = CONTENT.CONTROLS.BUTTONS:FindFirstChild(i) or DEPENDENCIES.TOPBAR_BUTTON:Clone()
	local DATA = {DATA=v,BUTTON=NEW_BUTTON}
	if (i == CURRENT_PAGE and (not PREVIOUS_BUTTON)) then
		PREVIOUS_BUTTON = DATA
	end
	NEW_BUTTON.LayoutOrder = v.INDEX
	NEW_BUTTON.Parent = CONTENT.CONTROLS.BUTTONS
	NEW_BUTTON.Name = i
	local CONNECTION = NEW_BUTTON.MASK.UIStroke:GetPropertyChangedSignal('Color'):Connect(function()
		NEW_BUTTON.NEON.ImageColor3 = NEW_BUTTON.MASK.UIStroke.Color
		NEW_BUTTON.MASK.IMG.ImageColor3 = NEW_BUTTON.MASK.UIStroke.Color
	end)
	table.insert(CONNECTIONS, CONNECTION)
	NEW_BUTTON.MASK.UIStroke.Color = Color3.new(1, 1, 1)
	NEW_BUTTON.MASK.IMG.Image = string.format('rbxassetid://%s', COLORFRAME_DATA.MASK_IMAGE)
	NEW_BUTTON.NEON.ImageTransparency = 1

	local COLOR = COLORFRAME_DATA.COLOR

	local CONTENT_FRAME = CONTENT.PAGES.MASK:FindFirstChild(i) or DEPENDENCIES.CONTENT_FRAME:Clone()
	CONTENT_FRAME.Parent = CONTENT.PAGES.MASK
	CONTENT_FRAME.Name = i
	CONTENT_FRAME.LayoutOrder = v.INDEX
	CONTENT_FRAME.TITLE.Text = table.concat(string.split(i, '_'), ' ')
	local UILAYOUT = (CONTENT_FRAME.BUTTONS:FindFirstChildOfClass('UIGridLayout') or CONTENT_FRAME.BUTTONS:FindFirstChildOfClass('UIListLayout'))
	local CONNECTION = UILAYOUT:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
		CONTENT_FRAME.BUTTONS.CanvasSize = UDim2.new(0, 0, 0, UILAYOUT.AbsoluteContentSize.Y)
	end)
	CONTENT_FRAME.BUTTONS.CanvasSize = UDim2.new(0, 0, 0, UILAYOUT.AbsoluteContentSize.Y)
	table.insert(CONNECTIONS, CONNECTION)

	for i,f in pairs(typeof(v.ADDONS) == 'table' and v.ADDONS or {}) do
		local DATA = f(CONTENT_FRAME, {CURRENT_ELEVATOR=CURRENT_ELEVATOR})
		DATA.CONTENT_FRAME = DATA.CONTENT_FRAME or CONTENT_FRAME
		DATA.BUTTON_HOVER_COLOR = COLOR
		ADDON_DATA[i] = DATA
		if (typeof(DATA.REFRESH) == 'function') then
			local SUCCESS, MSG = pcall(DATA.REFRESH, nil, CURRENT_ELEVATOR)
			if (not SUCCESS) then warn(`RemoteControls backend addon refresh error: {MSG}`) end
		end
	end

	for i,b in pairs(v.BUTTONS or {}) do
		HANDLE_INPUT_TYPE(b, CONTENT_FRAME.BUTTONS, COLOR)
	end

	NEW_BUTTON.MouseEnter:Connect(function()
		TWEEN_PLAY(TOOLTIP, TweenInfo.new(.15, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {BackgroundTransparency=0}, false)
		TOOLTIP.TEXT.Size = UDim2.new(10, 0, 1, 0)
		TOOLTIP.TEXT.Text = table.concat(string.split(i, '_'), ' ')
		TOOLTIP.TEXT.Size = UDim2.new(1, 0, 1, 0)
		TOOLTIP.Size = UDim2.new(0, TOOLTIP.TEXT.TextBounds.X, 0, TOOLTIP.AbsoluteSize.Y)
	end)
	NEW_BUTTON.MouseLeave:Connect(function()
		TWEEN_PLAY(TOOLTIP, TweenInfo.new(.15, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {BackgroundTransparency=1}, false)
	end)

	local CONNECTION = NEW_BUTTON.MouseButton1Click:Connect(function()
		if ((not DEBOUNCE) and DATA ~= PREVIOUS_BUTTON) then
			DEBOUNCE = true
			for i,v in pairs(TOPBAR_BUTTONS) do
				TWEEN_PLAY(v.BUTTON.MASK.UIStroke, TweenInfo.new(.5, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {Color=Color3.new(1, 1, 1)}, false)
				TWEEN_PLAY(v.BUTTON.NEON, TweenInfo.new(.5, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {ImageTransparency=1}, false)
			end
			TWEEN_PLAY(NEW_BUTTON.MASK.UIStroke, TweenInfo.new(.5, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {Color=COLOR}, false)
			TWEEN_PLAY(NEW_BUTTON.NEON, TweenInfo.new(.5, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {ImageTransparency=0}, false)

			TWEEN_PLAY(CONTENT.PAGES.MASK, TweenInfo.new(.5, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut), {Position=UDim2.new(-(v.INDEX-1), 0, 0, 0)})

			task.spawn(function()
				local INDEX_M = (DATA.DATA.INDEX > PREVIOUS_BUTTON.DATA.INDEX and 1 or DATA.DATA.INDEX < PREVIOUS_BUTTON.DATA.INDEX and -1 or 0)
				UNDERLINE.AnchorPoint = Vector2.new(INDEX_M == 1 and 0 or INDEX_M == -1 and 1 or 0, 1)
				local PREV_POS = GET_POSITION(MAIN_FRAME, PREVIOUS_BUTTON.BUTTON, INDEX_M == 1 and 0 or INDEX_M == -1 and 1 or 0)
				UNDERLINE.Position = UDim2.new(0, PREV_POS, 1, 0)

				local LENGTH = (math.abs((NEW_BUTTON.AbsolutePosition.X+(NEW_BUTTON.AbsoluteSize.X*(INDEX_M == 1 and 1 or INDEX_M == -1 and 0 or 0)))-(PREVIOUS_BUTTON.BUTTON.AbsolutePosition.X+(PREVIOUS_BUTTON.BUTTON.AbsoluteSize.X*(INDEX_M == 1 and 0 or INDEX_M == -1 and 1 or 0)))))

				local POSITION = UDim2.new(0, GET_POSITION(MAIN_FRAME, NEW_BUTTON, INDEX_M == 1 and 1 or INDEX_M == -1 and 0 or 0), 1, 0)
				TWEEN_PLAY(CONTENT.CONTROLS.UNDER, TweenInfo.new(.5, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {BackgroundColor3=COLOR}, false)
				TWEEN_PLAY(UNDERLINE, TweenInfo.new(.25, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {Size=UDim2.new(0, LENGTH, 0, UNDERLINE.AbsoluteSize.Y)}, true)
				UNDERLINE.AnchorPoint = Vector2.new(INDEX_M == 1 and 1 or INDEX_M == -1 and 0 or 0, 1)
				UNDERLINE.Position = POSITION
				TWEEN_PLAY(UNDERLINE, TweenInfo.new(.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size=UDim2.new(0, NEW_BUTTON.AbsoluteSize.X, 0, UNDERLINE.AbsoluteSize.Y)}, true)
				DEBOUNCE = false
			end)
			PREVIOUS_BUTTON = DATA
		end
	end)
	table.insert(CONNECTIONS, CONNECTION)
	TOPBAR_BUTTONS[i] = DATA

end

CONTENT.ELEVATOR_SELECTION.Visible = true
CONTENT.PAGES.Visible = false

local CONNECTION = CONTENT.PAGES.BACK.MASK.UIStroke:GetPropertyChangedSignal('Color'):Connect(function()
	CONTENT.PAGES.BACK.MASK.TEXT.TextColor3 = CONTENT.PAGES.BACK.MASK.UIStroke.Color
end)
table.insert(CONNECTIONS, CONNECTION)

local CONNECTION = CONTENT.PAGES.BACK.MouseEnter:Connect(function()
	TWEEN_PLAY(CONTENT.PAGES.BACK.MASK.UIStroke, TweenInfo.new(.15, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {Color=Color3.new(1, 0.254902, 0.12549)})
end)
table.insert(CONNECTIONS, CONNECTION)
local CONNECTION = CONTENT.PAGES.BACK.MouseLeave:Connect(function()
	TWEEN_PLAY(CONTENT.PAGES.BACK.MASK.UIStroke, TweenInfo.new(.15, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {Color=Color3.new(1, 1, 1)})
end)
table.insert(CONNECTIONS, CONNECTION)
local CONNECTION = CONTENT.PAGES.BACK.MouseButton1Click:Connect(function()

	CONTENT.ELEVATOR_SELECTION.Visible = true
	CONTENT.PAGES.Visible = false
	for i,b in pairs(ELEVATOR_BUTTONS) do
		TWEEN_PLAY(b, TweenInfo.new(.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size=UDim2.new(b.Size.X.Scale, b.Size.X.Offset, 0, 50)})
		TWEEN_PLAY(b.MASK, TweenInfo.new(.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size=UDim2.new(b.MASK.Size.X.Scale, b.MASK.Size.X.Offset, 1, 0)})
		TWEEN_PLAY(b.MASK.UIStroke, TweenInfo.new(.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Thickness=1})
		wait(.05)
	end

end)
table.insert(CONNECTIONS, CONNECTION)

local function HANDLE_LIST_UPDATER(UILAYOUT: any)
	if ((not UILAYOUT:IsA('UIListLayout')) and (not UILAYOUT:IsA('UIGridLayout'))) then return end
	local FRAME: ScrollingFrame = UILAYOUT.Parent:IsA('ScrollingFrame') and UILAYOUT.Parent
	if (not FRAME) then return end
	local CONNECTION = UILAYOUT:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
		FRAME.CanvasSize = UDim2.new(0, 0, 0, UILAYOUT.AbsoluteContentSize.Y)
	end)
	table.insert(CONNECTIONS, CONNECTION)
	FRAME.CanvasSize = UDim2.new(0, 0, 0, UILAYOUT.AbsoluteContentSize.Y)
end

for i,UILAYOUT in next,CONTENT:GetDescendants() do
	HANDLE_LIST_UPDATER(UILAYOUT)
end
CONTENT.DescendantAdded:Connect(HANDLE_LIST_UPDATER)

local SORT_ORDER = 'A-Z'

local DEBOUNCE = false

task.wait()
local function SORT_ELEVATOR_BUTTONS()
	if (SORT_ORDER == 'A-Z') then
		table.sort(ELEVATOR_BUTTONS, function(A, B)
			return string.lower(A.MASK.TEXT.Text) < string.lower(B.MASK.TEXT.Text)
		end)
	else
		table.sort(ELEVATOR_BUTTONS, function(A, B)
			return string.lower(A.MASK.TEXT.Text) > string.lower(B.MASK.TEXT.Text)
		end)
	end
	for i,ELEVATOR_BUTTON in next,ELEVATOR_BUTTONS do
		local TWEEN = game:GetService('TweenService'):Create(ELEVATOR_BUTTON.UIScale, TweenInfo.new(.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Scale=0})
		TWEEN:Play()
		task.delay(TWEEN.TweenInfo.Time+.2, function()
			if (TWEEN.PlaybackState ~= Enum.PlaybackState.Completed) then return end
			ELEVATOR_BUTTON.LayoutOrder = i
			game:GetService('TweenService'):Create(ELEVATOR_BUTTON.UIScale, TweenInfo.new(.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Scale=1}):Play()
		end)
	end
end

local PREVIOUS_ELEVATOR
local function RELOAD_ADDON_DATA()
	for i,DATA in pairs(ADDON_DATA) do
		local COLORFRAME_DATA = COLORFRAME.TOP_BUTTONS[i]
		if (typeof(DATA.REFRESH) == 'function') then
			local SUCCESS, MSG = pcall(DATA.REFRESH, PREVIOUS_ELEVATOR, CURRENT_ELEVATOR)
			if (not SUCCESS) then warn(`RemoteControls backend addon refresh error: {MSG}`) end
			if (MSG and MSG.BUTTONS) then
				local INDEX = 0
				for i,v in pairs(MSG.BUTTONS or {}) do
					if (v.INPUT_TYPE) then
						HANDLE_INPUT_TYPE(v, DATA.CONTENT_FRAME, DATA.BUTTON_HOVER_COLOR)
					else
						INDEX += 1
						if (v.LABEL_NAME) then
							local LABEL = Instance.new('TextLabel')
							LABEL.Name = 'DOOR_SIDE_LABEL'
							LABEL.Size = UDim2.new(1, 0, 0, 30)
							LABEL.BackgroundTransparency = 1
							LABEL.Text = `{string.upper(v.LABEL_NAME)} DOORS`
							LABEL.TextColor3 = Color3.new(1, 1, 1)
							LABEL.FontFace = Font.new(`rbxassetid://{STYLE.FONT_ID}`, Enum.FontWeight.Bold)
							LABEL.TextScaled = true
							LABEL.RichText = true
							LABEL.LayoutOrder = INDEX
							LABEL.Parent = DATA.CONTENT_FRAME
						end
						local BUTTON_GROUP_FRAME = Instance.new('Frame')
						BUTTON_GROUP_FRAME.Name = 'BUTTON_GROUP_FRAME'
						BUTTON_GROUP_FRAME.Size = UDim2.new(1, 0, 0, 0)
						BUTTON_GROUP_FRAME.BackgroundTransparency = 1
						BUTTON_GROUP_FRAME.LayoutOrder = INDEX+1
						BUTTON_GROUP_FRAME.Parent = DATA.CONTENT_FRAME
						local UILIST = Instance.new('UIListLayout')
						UILIST.FillDirection = Enum.FillDirection.Vertical
						UILIST.VerticalAlignment = Enum.VerticalAlignment.Top
						UILIST.HorizontalAlignment = Enum.HorizontalAlignment.Center
						UILIST.SortOrder = Enum.SortOrder.LayoutOrder
						UILIST.Padding = UDim.new(0, 5)
						UILIST.Parent = BUTTON_GROUP_FRAME
						UILIST:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
							BUTTON_GROUP_FRAME.Size = UDim2.new(1, 0, 0, UILIST.AbsoluteContentSize.Y)
						end)
						for i,b in pairs(v.BUTTONS) do
							HANDLE_INPUT_TYPE(b, BUTTON_GROUP_FRAME, DATA.BUTTON_HOVER_COLOR)
						end
					end
				end
			end
		end
	end
	PREVIOUS_ELEVATOR = CURRENT_ELEVATOR
end

local function CHECK_ELEVATOR(v)
	task.spawn(function()
		task.wait()
		if (v:FindFirstChild('Cortex_API') and v:FindFirstChild('Car') and v:FindFirstChild('Legacy') and (not ELEVATORS[v])) then

			local ELEVATOR_BUTTON = DEPENDENCIES.ELEVATOR:Clone()
			ELEVATOR_BUTTON.Parent = CONTENT.ELEVATOR_SELECTION.LIST
			ELEVATOR_BUTTON.Name = string.upper(v.Name)
			ELEVATOR_BUTTON.MASK.TEXT.Text = v:GetFullName()

			local CONNECTION = ELEVATOR_BUTTON.MASK.UIStroke:GetPropertyChangedSignal('Color'):Connect(function()
				ELEVATOR_BUTTON.MASK.TEXT.TextColor3 = ELEVATOR_BUTTON.MASK.UIStroke.Color
			end)
			table.insert(CONNECTIONS, CONNECTION)

			local CONNECTION = ELEVATOR_BUTTON.MouseEnter:Connect(function()
				TWEEN_PLAY(ELEVATOR_BUTTON.MASK.UIStroke, TweenInfo.new(.15, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {Color=Color3.new(0.215686, 1, 0.333333)}, false)
			end)
			table.insert(CONNECTIONS, CONNECTION)
			local CONNECTION = ELEVATOR_BUTTON.MouseLeave:Connect(function()
				TWEEN_PLAY(ELEVATOR_BUTTON.MASK.UIStroke, TweenInfo.new(.15, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {Color=Color3.new(1, 1, 1)}, false)
			end)
			table.insert(CONNECTIONS, CONNECTION)
			local CONNECTION = ELEVATOR_BUTTON.MouseButton1Click:Connect(function()
				if (not DEBOUNCE) then
					DEBOUNCE = true
					for i,c in pairs(ELEVATOR_CONNECTIONS) do
						c:Disconnect()
					end
					ELEVATOR_CONNECTIONS = {}
					for i,r in pairs(READONLY_VALUES) do
						r[2].REFRESH(v)
					end
					--if (CURRENT_ELEVATOR) then return end
					for i,e in pairs(ELEVATOR_BUTTONS) do
						if (e ~= ELEVATOR_BUTTON) then
							TWEEN_PLAY(e.MASK.CHECK, TweenInfo.new(.5, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {BackgroundTransparency=1}, false)
							TWEEN_PLAY(e.MASK.CHECK.IMG.UIScale, TweenInfo.new(.5, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {Scale=0}, false)
						end
					end
					local PREVIOUS_ELEVATOR = CURRENT_ELEVATOR
					CURRENT_ELEVATOR = v
					RELOAD_ADDON_DATA()
					if (PREVIOUS_ELEVATOR ~= CURRENT_ELEVATOR) then
						TWEEN_PLAY(ELEVATOR_BUTTON.MASK.CHECK, TweenInfo.new(.5, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {BackgroundTransparency=.5}, false)
						TWEEN_PLAY(ELEVATOR_BUTTON.MASK.CHECK.IMG.UIScale, TweenInfo.new(.5, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), {Scale=1}, true)
					end
					for i,b in pairs(ELEVATOR_BUTTONS) do
						TWEEN_PLAY(b, TweenInfo.new(.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size=UDim2.new(b.Size.X.Scale, b.Size.X.Offset, 0, 0)})
						TWEEN_PLAY(b.MASK, TweenInfo.new(.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size=UDim2.new(b.MASK.Size.X.Scale, b.MASK.Size.X.Offset, 0, 0)})
						TWEEN_PLAY(b.MASK.UIStroke, TweenInfo.new(.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Thickness=0})
						wait(.05)
					end
					task.delay(PREVIOUS_ELEVATOR ~= CURRENT_ELEVATOR and .25 or 0, function()
						CONTENT.ELEVATOR_SELECTION.Visible = false
						CONTENT.PAGES.Visible = true
						DEBOUNCE = false
					end)
				end
			end)
			table.insert(CONNECTIONS, CONNECTION)
			ELEVATOR_BUTTON.MASK.CHECK.IMG.UIScale.Scale = 0
			ELEVATOR_BUTTON.MASK.CHECK.BackgroundTransparency = 1
			ELEVATOR_BUTTON:SetAttribute('ELEVATOR_PATH_NAME', v:GetFullName())
			ELEVATOR_BUTTON:SetAttribute('SIZE_FULL', ELEVATOR_BUTTON.Size)
			ELEVATOR_BUTTON:SetAttribute('MASK_SIZE_FULL', ELEVATOR_BUTTON.MASK.Size)
			ELEVATOR_BUTTON:SetAttribute('BORDER_THICKNESS', ELEVATOR_BUTTON.MASK.UIStroke.Thickness)
			table.insert(ELEVATOR_BUTTONS, ELEVATOR_BUTTON)
			task.spawn(SORT_ELEVATOR_BUTTONS)

			ELEVATORS[v] = {ELEVATOR_BUTTON}

		end
	end)
end

--//AUDIT 02/11/2023: ADD ABILITY TO CHANGE SORT ORDER TO ASCENDING OR DESCENDING
CONTENT.ELEVATOR_SELECTION.SORT_BUTTON.BTN.MouseButton1Click:Connect(function()
	if (CONTENT.ELEVATOR_SELECTION.SORT_BUTTON.BTN:GetAttribute('DISABLED')) then return end
	CONTENT.ELEVATOR_SELECTION.SORT_BUTTON.BTN:SetAttribute('DISABLED', true)
	SORT_ORDER = SORT_ORDER == 'A-Z' and 'Z-A' or 'A-Z'
	CONTENT.ELEVATOR_SELECTION.SORT_BUTTON.BTN.Text = SORT_ORDER
	task.spawn(SORT_ELEVATOR_BUTTONS)
	task.delay(.4, function()
		CONTENT.ELEVATOR_SELECTION.SORT_BUTTON.BTN:SetAttribute('DISABLED', false)
	end)
end)
CONTENT.ELEVATOR_SELECTION.SORT_BUTTON.BTN.Text = SORT_ORDER

local SEARCH_INPUT = CONTENT.ELEVATOR_SELECTION.SEARCH.INPUT
SEARCH_INPUT:GetPropertyChangedSignal('Text'):Connect(function()
	for i,b in pairs(ELEVATOR_BUTTONS) do
		task.spawn(function()
			local IS_SHOWN = string.match(string.upper(b:GetAttribute('ELEVATOR_PATH_NAME')), string.upper(SEARCH_INPUT.Text)) ~= nil
			local TWEEN = TWEEN_PLAY(b, TweenInfo.new(.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size=IS_SHOWN and b:GetAttribute('SIZE_FULL') or UDim2.new()})
			TWEEN_PLAY(b.MASK, TweenInfo.new(.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size=IS_SHOWN and b:GetAttribute('MASK_SIZE_FULL') or UDim2.new()})
			TWEEN_PLAY(b.MASK.UIStroke, TweenInfo.new(.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Thickness=IS_SHOWN and b:GetAttribute('BORDER_THICKNESS') or 0})
			if (not IS_SHOWN) then
				TWEEN.Completed:Wait()
				if (TWEEN.PlaybackState == Enum.PlaybackState.Completed) then
					b.Visible = IS_SHOWN
				end
			else
				b.Visible = IS_SHOWN
			end
		end)
	end
end)

local DRAG_START,START_POS,DRAG_INPUT
local IS_DRAGGING = false
local IS_TOGGLED = false

local function UPDATE_DRAG(INPUT)

	local DELTA = INPUT.Position-DRAG_START
	TWEEN_SERVICE:Create(MAIN_FRAME, TweenInfo.new(.04, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {Position=UDim2.new(START_POS.X.Scale, START_POS.X.Offset+DELTA.X, START_POS.Y.Scale, START_POS.Y.Offset+DELTA.Y)}):Play()

end

TOPBAR.InputBegan:Connect(function(INPUT)

	if (INPUT.UserInputState == Enum.UserInputState.Begin and (INPUT.UserInputType == Enum.UserInputType.MouseButton1 or INPUT.UserInputType == Enum.UserInputType.Touch)) then
		DRAG_START = INPUT.Position
		START_POS = MAIN_FRAME.Position
		IS_DRAGGING = true
		local CONNECTION,UPDATE_CONNECTION
		CONNECTION = INPUT.Changed:Connect(function()
			if (INPUT.UserInputState == Enum.UserInputState.End) then
				IS_DRAGGING = false
				CONNECTION:Disconnect()
				UPDATE_CONNECTION:Disconnect()
			end
		end)
		UPDATE_CONNECTION = RUN_SERVICE.RenderStepped:Connect(function()
			if (IS_DRAGGING) then
				UPDATE_DRAG(DRAG_INPUT)
			end
		end)
	end

end)
TOPBAR.InputChanged:Connect(function(INPUT)
	DRAG_INPUT = INPUT
end)

local function TOGGLE_GUI(BOOL: boolean)
	if (BOOL) then
		THIS.MAIN_FRAME.Visible = true
		if (THIS.KeyCodeHint.Visible) then
			THIS.KeyCodeHint.Visible = false
		end
	end
	IS_TOGGLED = BOOL
	local TWEEN = TWEEN_SERVICE:Create(THIS.MAIN_FRAME, TweenInfo.new(.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {GroupTransparency=BOOL and 0 or 1})
	TWEEN:Play()
	TWEEN.Completed:Wait()
	TOGGLE_DEBOUNCE = false
	if (TWEEN.PlaybackState ~= Enum.PlaybackState.Completed) then return end
	if (not BOOL) then
		THIS.MAIN_FRAME.Visible = false
	end
end

if (IS_TOGGLED) then
	THIS.MAIN_FRAME.Visible = true
	if (THIS.KeyCodeHint.Visible) then
		THIS.KeyCodeHint.Visible = false
	end
end
local TWEEN = TWEEN_SERVICE:Create(THIS.MAIN_FRAME, TweenInfo.new(.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {GroupTransparency=IS_TOGGLED and 0 or 1})
TWEEN:Play()
TWEEN.Completed:Wait()
TOGGLE_DEBOUNCE = false
if (TWEEN.PlaybackState ~= Enum.PlaybackState.Completed) then return end
if (not IS_TOGGLED) then
	THIS.MAIN_FRAME.Visible = false
end

THIS.EXPAND.Position = UDim2.new(1, 5, .5, 0)
THIS.EXPAND.MouseButton1Click:Connect(function()
	TOGGLE_GUI(true)
	TWEEN_PLAY(THIS.EXPAND, TweenInfo.new(.4, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {Position=UDim2.new(1, IS_TOGGLED and 55 or 5, .5, 0)}, false)
end)

THIS.EXPAND.MASK.UIStroke:GetPropertyChangedSignal('Color'):Connect(function()
	THIS.EXPAND.MASK.TEXT.TextColor3 = THIS.EXPAND.MASK.UIStroke.Color
end)
THIS.EXPAND.MouseEnter:Connect(function()
	TWEEN_PLAY(THIS.EXPAND.MASK.UIStroke, TweenInfo.new(.15, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {Color=Color3.new(0.290196, 1, 0.513725)}, false)
end)
THIS.EXPAND.MouseLeave:Connect(function()
	TWEEN_PLAY(THIS.EXPAND.MASK.UIStroke, TweenInfo.new(.15, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {Color=Color3.new(1, 1, 1)}, false)
end)

TOPBAR.CLOSE.MouseButton1Click:Connect(function()
	TOGGLE_GUI(false)
	TWEEN_PLAY(THIS.EXPAND, TweenInfo.new(.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position=UDim2.new(1, IS_TOGGLED and 50 or 5, .5, 0)}, false)
end)

task.wait()
local NEW_BUTTON = TOPBAR_BUTTONS[CURRENT_PAGE]
NEW_BUTTON.BUTTON.MASK.UIStroke.Color = COLORFRAME.TOP_BUTTONS[CURRENT_PAGE].COLOR
NEW_BUTTON.BUTTON.NEON.ImageTransparency = 0

local ELEVATOR_STORAGE = DATA_REMOTE:InvokeServer('GET_ELEVATOR_STORAGE')

UNDERLINE.Size = UDim2.new(0, NEW_BUTTON.BUTTON.AbsoluteSize.X, 0, UNDERLINE.AbsoluteSize.Y)
UNDERLINE.AnchorPoint = Vector2.new(1, 1)
UNDERLINE.Position = UDim2.new(0, GET_POSITION(MAIN_FRAME, NEW_BUTTON.BUTTON, 1), 1, 0)
UNDERLINE.BackgroundColor3 = COLORFRAME.TOP_BUTTONS[CURRENT_PAGE].COLOR

workspace.DescendantAdded:Connect(CHECK_ELEVATOR)
workspace.DescendantRemoving:Connect(function(elev: Instance)
	task.wait()
	if (not ELEVATORS[elev]) then return end
	for _,v in pairs(ELEVATORS[elev]) do
		v:Destroy()
	end
	ELEVATORS[elev] = nil
end)
for i,v in pairs(ELEVATOR_STORAGE) do
	CHECK_ELEVATOR(v)
end

MAIN_FRAME.CONTENT.ELEVATOR_SELECTION.PROX_SELECT.MouseEnter:Connect(function()
	TWEEN_PLAY(MAIN_FRAME.CONTENT.ELEVATOR_SELECTION.PROX_SELECT.MASK.UIStroke, TweenInfo.new(.15, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {Color=Color3.new(0.290196, 1, 0.513725)}, false)
	TWEEN_PLAY(MAIN_FRAME.CONTENT.ELEVATOR_SELECTION.PROX_SELECT.MASK.TEXT, TweenInfo.new(.15, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {TextColor3=Color3.new(0.290196, 1, 0.513725)}, false)
end)
MAIN_FRAME.CONTENT.ELEVATOR_SELECTION.PROX_SELECT.MouseLeave:Connect(function()
	TWEEN_PLAY(MAIN_FRAME.CONTENT.ELEVATOR_SELECTION.PROX_SELECT.MASK.UIStroke, TweenInfo.new(.15, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {Color=Color3.new(1, 1, 1)}, false)
	TWEEN_PLAY(MAIN_FRAME.CONTENT.ELEVATOR_SELECTION.PROX_SELECT.MASK.TEXT, TweenInfo.new(.15, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {TextColor3=Color3.new(1, 1, 1)}, false)
end)
MAIN_FRAME.CONTENT.PROX_ELEVATOR_FRAME.CANCEL.MouseEnter:Connect(function()
	TWEEN_PLAY(MAIN_FRAME.CONTENT.PROX_ELEVATOR_FRAME.CANCEL.MASK.UIStroke, TweenInfo.new(.15, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {Color=Color3.new(0.290196, 1, 0.513725)}, false)
	TWEEN_PLAY(MAIN_FRAME.CONTENT.PROX_ELEVATOR_FRAME.CANCEL.MASK.TEXT, TweenInfo.new(.15, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {TextColor3=Color3.new(0.290196, 1, 0.513725)}, false)
end)
MAIN_FRAME.CONTENT.PROX_ELEVATOR_FRAME.CANCEL.MouseLeave:Connect(function()
	TWEEN_PLAY(MAIN_FRAME.CONTENT.PROX_ELEVATOR_FRAME.CANCEL.MASK.UIStroke, TweenInfo.new(.15, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {Color=Color3.new(1, 1, 1)}, false)
	TWEEN_PLAY(MAIN_FRAME.CONTENT.PROX_ELEVATOR_FRAME.CANCEL.MASK.TEXT, TweenInfo.new(.15, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {TextColor3=Color3.new(1, 1, 1)}, false)
end)

local IS_OPENED = false
local PARAMS = OverlapParams.new()
PARAMS.FilterType = Enum.RaycastFilterType.Whitelist
PARAMS.MaxParts = 1
MAIN_FRAME.CONTENT.ELEVATOR_SELECTION.PROX_SELECT.MouseButton1Click:Connect(function()
	CHAR = PLAYER.Character
	if not CHAR or not CHAR.Parent then return end
	if (IS_OPENED) then return end
	MAIN_FRAME.CONTENT.PROX_ELEVATOR_FRAME.Visible = true
	TWEEN_PLAY(MAIN_FRAME.CONTENT.PROX_ELEVATOR_FRAME, TweenInfo.new(.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position=UDim2.new(.5, 0, 0, 0)}, false)
	IS_OPENED = true
	PARAMS.FilterDescendantsInstances = {CHAR}
	local PREV_ELEVATOR
	local function GET_ELEVATORS_IN_BOUNDS()
		local ELEVATORS = {}
		for i,ELEVATOR in pairs(ELEVATOR_STORAGE) do
			local CAR: Model? = ELEVATOR:FindFirstChild('Car')
			if (not CAR) then return end
			local IS_IN_PROXIMITY = #workspace:GetPartBoundsInBox(CAR.Platform.CFrame, (2*CAR.Platform.Size)+CAR.Platform.CFrame.UpVector*28, PARAMS) > 0
			if (IS_IN_PROXIMITY) then
				table.insert(ELEVATORS, ELEVATOR)
			end
		end
		return ELEVATORS
	end
	local function GET_NEAREST_ELEVATOR(ELEVATORS: {any})
		if (typeof(ELEVATORS) ~= 'table') then return end
		local DIST = math.huge
		local ELEVATOR
		for i,v in pairs(ELEVATORS) do
			local THIS_DIST = (v.Car.Platform.Position-CHAR.HumanoidRootPart.Position).Magnitude
			if (THIS_DIST <= DIST) then
				DIST = THIS_DIST
				ELEVATOR = v
			end
		end
		return ELEVATOR
	end

	while (IS_OPENED) do
		task.wait()
		local ELEVATORS = GET_ELEVATORS_IN_BOUNDS()
		local NEAREST_ELEVATOR = GET_NEAREST_ELEVATOR(ELEVATORS)
		if (NEAREST_ELEVATOR ~= PREV_ELEVATOR) then
			for i,v in pairs(MAIN_FRAME.CONTENT.PROX_ELEVATOR_FRAME:GetChildren()) do
				if (v:IsA('Frame')) then
					v:Destroy()
				end
			end
			PREV_ELEVATOR = NEAREST_ELEVATOR
			CONTENT.PROX_ELEVATOR_FRAME.NO_ELEVATOR.Visible = not NEAREST_ELEVATOR
			if (NEAREST_ELEVATOR) then
				local NEW_PROX_ITEM = DEPENDENCIES.PROX_ITEM:Clone()
				NEW_PROX_ITEM.Name = string.format('%s_PROX_ITEM', string.upper(NEAREST_ELEVATOR.Name))
				NEW_PROX_ITEM.Parent = MAIN_FRAME.CONTENT.PROX_ELEVATOR_FRAME
				NEW_PROX_ITEM.ELEVATOR_NAME.Text = NEAREST_ELEVATOR:GetFullName()
				NEW_PROX_ITEM.BUTTON.MouseEnter:Connect(function()
					TWEEN_PLAY(NEW_PROX_ITEM.UIStroke, TweenInfo.new(.15, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {Color=Color3.new(0.290196, 1, 0.513725)}, false)
					TWEEN_PLAY(NEW_PROX_ITEM.ELEVATOR_NAME, TweenInfo.new(.15, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {TextColor3=Color3.new(0.290196, 1, 0.513725)}, false)
				end)
				NEW_PROX_ITEM.BUTTON.MouseLeave:Connect(function()
					TWEEN_PLAY(NEW_PROX_ITEM.UIStroke, TweenInfo.new(.15, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {Color=Color3.new(1, 1, 1)}, false)
					TWEEN_PLAY(NEW_PROX_ITEM.ELEVATOR_NAME, TweenInfo.new(.15, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {TextColor3=Color3.new(1, 1, 1)}, false)
				end)
				NEW_PROX_ITEM.BUTTON.MouseButton1Click:Connect(function()
					TWEEN_PLAY(MAIN_FRAME.CONTENT.PROX_ELEVATOR_FRAME, TweenInfo.new(.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Position=UDim2.new(.5, 0, -1, 0)}, false)
					CONTENT.ELEVATOR_SELECTION.Visible = false
					CONTENT.PAGES.Visible = true
					DEBOUNCE = false
					IS_OPENED = false
					local PREVIOUS_ELEVATOR = CURRENT_ELEVATOR
					CURRENT_ELEVATOR = NEAREST_ELEVATOR
					RELOAD_ADDON_DATA()
					for i,c in pairs(ELEVATOR_CONNECTIONS) do
						c:Disconnect()
					end
					ELEVATOR_CONNECTIONS = {}
					for i,r in pairs(READONLY_VALUES) do
						r[2].REFRESH(NEAREST_ELEVATOR)
					end
					for i,b in pairs(ELEVATOR_BUTTONS) do
						TWEEN_PLAY(b, TweenInfo.new(0, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size=UDim2.new(b.Size.X.Scale, b.Size.X.Offset, 0, 0)})
						TWEEN_PLAY(b.MASK, TweenInfo.new(0, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size=UDim2.new(b.MASK.Size.X.Scale, b.MASK.Size.X.Offset, 0, 0)})
						TWEEN_PLAY(b.MASK.UIStroke, TweenInfo.new(0, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Thickness=0})
						if (NEAREST_ELEVATOR.Name ~= b.Name) then
							TWEEN_PLAY(b.MASK.CHECK, TweenInfo.new(0, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {BackgroundTransparency=1}, false)
							TWEEN_PLAY(b.MASK.CHECK.IMG.UIScale, TweenInfo.new(0, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {Scale=0}, false)
						end
					end
				end)
			end
		end
	end
	for i,v in pairs(MAIN_FRAME.CONTENT.PROX_ELEVATOR_FRAME:GetChildren()) do
		if (v:IsA('Frame')) then
			v:Destroy()
		end
	end
end)
MAIN_FRAME.CONTENT.PROX_ELEVATOR_FRAME.CANCEL.MouseButton1Click:Connect(function()
	TWEEN_PLAY(MAIN_FRAME.CONTENT.PROX_ELEVATOR_FRAME, TweenInfo.new(.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Position=UDim2.new(.5, 0, -1, 0)}, false)
	IS_OPENED = false
end)

MAIN_FRAME.CONTENT.PROX_ELEVATOR_FRAME.Position = UDim2.new(.5, 0, -1, 0)

-- 09/14 Add keyboard support; disable the expand button for PC clients
THIS.EXPAND.Visible = KEYBOARD_ENABLED
local CURRENT_SIZE = THIS.MAIN_FRAME.Size
local TOGGLE_DEBOUNCE = false

THIS.MAIN_FRAME.GroupTransparency = IS_TOGGLED and 0 or 1
THIS.KeyCodeHint.Visible = not KEYBOARD_ENABLED

USER_INPUT_SERVICE.InputBegan:Connect(function(INPUT: InputObject, GAME_PROCESSED_EVENT: boolean)
	if (GAME_PROCESSED_EVENT or INPUT.UserInputType ~= Enum.UserInputType.Keyboard or INPUT.KeyCode ~= Enum.KeyCode.R or TOGGLE_DEBOUNCE) then return end
	TOGGLE_GUI(not IS_TOGGLED)
end)

THIS.Enabled = true -- 09/14 Update UI to enable after loading