local Signal = require(script.Signal)

local TweenService = game:GetService("TweenService")
local PlayerObject = game:GetService("Players").LocalPlayer
local UserInputService = game:GetService("UserInputService")

local Mouse = PlayerObject:GetMouse()
local Camera = workspace.CurrentCamera
local PlayerGui = PlayerObject:WaitForChild("PlayerGui")

local listOfDraggable = {}

local function ValidateParametersValue(UI: GuiObject, byScale: boolean?)
	if not UI then
		error("First argument must not be empty!")
	end

	if not (typeof(UI) == "Instance") then
		error("First argument must be a type of instance!")
	end

	if not (typeof(byScale) == "boolean") then
		error("Second argument must be a type of boolean!")
	end
end

local function IsMouseOrTouch(input: InputObject, isMouseMovement: boolean?): boolean
	return input.UserInputType
		== (if isMouseMovement then Enum.UserInputType.MouseMovement else Enum.UserInputType.MouseButton1)
		or input.UserInputType == Enum.UserInputType.Touch
end

local function GetDominantObject(list: { Instance }): GuiObject
	local dominant = math.huge
	local guiObject: GuiObject

	for _, value in ipairs(listOfDraggable) do
		local index = table.find(list, value._UI)

		if index and index < dominant then
			dominant = index
			guiObject = value._UI
		end
	end

	return guiObject
end

local DraggableUI = {}
DraggableUI.__index = DraggableUI
DraggableUI.__tostring = function()
	return "Draggable"
end

function DraggableUI.new(UI: GuiObject, byScale: true?)
	byScale = byScale or true
	ValidateParametersValue(UI, byScale)

	local self = setmetatable({
		_Released = Signal.new(),
		_Started = Signal.new(),
		_Moved = Signal.new(),

		_Connections = {},
		_Overlapping = {
			Disabled = false,
		},
		_LimitBoundingBox = {
			Enabled = false,
			Type = 0,
		},

		_TweenInfo = false,
		_UI = UI,
	}, DraggableUI)

	self.Released = self._Released.Event
	self.Started = self._Started.Event
	self.Moved = self._Moved.Event

	local success, result = pcall(self._Initialize, self, UI, byScale)

	if not success then
		error(("Something went wrong: %s"):format(result))
	end

	table.insert(listOfDraggable, self)
	return self
end

function DraggableUI:_Initialize(UI: GuiObject, byScale: boolean)
	local startPosition = UI.AbsolutePosition
	local dragStartPosition = UserInputService:GetMouseLocation()

	local mouseOnUI = false
	local button1Down = false

	table.insert(
		self._Connections,
		UI.MouseEnter:Connect(function()
			mouseOnUI = true
		end)
	)

	table.insert(
		self._Connections,
		UI.MouseLeave:Connect(function()
			mouseOnUI = false
		end)
	)

	table.insert(
		self._Connections,
		UserInputService.InputBegan:Connect(function(input)
			if IsMouseOrTouch(input) and mouseOnUI then
				local list = PlayerGui:GetGuiObjectsAtPosition(Mouse.X, Mouse.Y)

				if #list >= 2 then
					if not (GetDominantObject(list) == UI) then
						return
					end
				end

				for _, value in pairs(self._Overlapping) do
					if value then
						return
					end
				end

				startPosition = UI.AbsolutePosition + (UI.AbsoluteSize * UI.AnchorPoint) - UI.Parent.AbsolutePosition
				dragStartPosition = UserInputService:GetMouseLocation()
				button1Down = true

				self._Started:Fire()
			end
		end)
	)

	table.insert(
		self._Connections,
		UserInputService.InputEnded:Connect(function(input)
			if IsMouseOrTouch(input) and button1Down then
				button1Down = false
				self._Released:Fire(UserInputService:GetMouseLocation())
			end
		end)
	)

	table.insert(
		self._Connections,
		UserInputService.InputChanged:Connect(function(input)
			if IsMouseOrTouch(input, true) and button1Down then
				local mousePosition = UserInputService:GetMouseLocation()
				local delta = mousePosition - dragStartPosition
				local parentSize = UI.Parent.AbsoluteSize
				local position = startPosition + delta

				position = self:_LimitPosition(UI, position, parentSize)

				if not byScale then
					position = UDim2.fromOffset(position.X, position.Y)
				else
					position /= parentSize
					position = UDim2.fromScale(position.X, position.Y)
				end

				if self._TweenInfo then
					TweenService:Create(UI, self._TweenInfo, { Position = position }):Play()
				else
					UI.Position = position
				end

				self._Moved:Fire(mousePosition)
			end
		end)
	)
end

function DraggableUI:_LimitPosition(UI: GuiObject, position: Vector2, parentSize: Vector2)
	if self._LimitBoundingBox.Enabled then
		local offset = (UI.AbsoluteSize * UI.AnchorPoint)
		local uiSize = UI.AbsoluteSize

		if self._LimitBoundingBox.Type == 0 then
			local screenSize = Camera.ViewportSize
			local max = (screenSize - uiSize) + offset

			return Vector2.new(math.clamp(position.X, offset.X, max.X), math.clamp(position.Y, offset.Y, max.Y))
		else
			local max = (parentSize - uiSize) + offset

			return Vector2.new(math.clamp(position.X, offset.X, max.X), math.clamp(position.Y, offset.Y, max.Y))
		end
	end

	return position
end

function DraggableUI:_Ignore(UI: GuiObject)
	table.insert(
		self._Connections,
		UI.MouseEnter:Connect(function()
			self._Overlapping[UI] = true
		end)
	)

	table.insert(
		self._Connections,
		UI.MouseLeave:Connect(function()
			self._Overlapping[UI] = nil
		end)
	)
end

function DraggableUI:LimitScreenBoundingBox(byParent: false?, value: boolean?): boolean
	local limitBoundingBox = self._LimitBoundingBox
	byParent = byParent or false

	limitBoundingBox.Type = if byParent then 1 else 0
	limitBoundingBox.Enabled = if typeof(value) == "boolean" then value else not limitBoundingBox.Enabled

	return limitBoundingBox.Enabled
end

function DraggableUI:Toggle(value: boolean?): boolean
	local overlapping = self._Overlapping
	overlapping.Disabled = if typeof(value) == "boolean" then value else not overlapping.Disabled

	return overlapping.Disabled
end

function DraggableUI:SetTweenInfo(tweenInfo: TweenInfo)
	if not (typeof(tweenInfo) == "TweenInfo") then
		error("Argument must be a type of TweenInfo!")
	end

	self._TweenInfo = tweenInfo
end

function DraggableUI:Ignore(list: { Instance }, instanceCheck: false?)
	instanceCheck = instanceCheck or false

	if not (typeof(list) == "table") then
		error("First argument must be a type of table!")
	end

	if not (typeof(instanceCheck) == "boolean") then
		error("Second argument must be a type of boolean!")
	end

	local success = pcall(function()
		if instanceCheck then
			for _, object in ipairs(list) do
				pcall(function()
					self:_Ignore(object)
				end)
			end
		else
			for _, object in ipairs(list) do
				self:_Ignore(object)
			end
		end
	end)

	if not success then
		error("It seems that the array contained a none type of GuiObject")
	end
end

function DraggableUI:IgnoreChildren()
	self:Ignore(self._UI:GetChildren(), true)
end

function DraggableUI:IgnoreDescendants()
	self:Ignore(self._UI:GetDescendants(), true)
end

function DraggableUI:Destroy()
	for _, connection: RBXScriptSignal in ipairs(self._Connections) do
		if typeof(connection) == "RBXScriptSignal" then
			connection:Disconnect()
		end
	end

	for key, _ in pairs(self._IgnoreList) do
		self._IgnoreList[key] = nil
	end

	self._Released:Destroy()
	self._Started:Destroy()
	self._Moved:Destroy()

	table.remove(listOfDraggable, table.find(listOfDraggable, self))
	table.clear(self)
end

setmetatable(DraggableUI, {
	__index = function(_, key)
		error(("Attempt to get Connection::%s (not a valid member)"):format(tostring(key)), 2)
	end,

	__newindex = function(_, key)
		error(("Attempt to set Connection::%s (not a valid member)"):format(tostring(key)), 2)
	end,
})

export type Draggable = {
	LimitScreenBoundingBox: (self: { Draggable }, byParent: false?, value: boolean?) -> boolean,
	Ignore: (self: { Draggable }, list: { Frame | Instance }, instanceCheck: false?) -> (),
	SetTweenInfo: (self: { Draggable }, tweenInfo: TweenInfo) -> (),
	Toggle: (self: { Draggable }, value: boolean?) -> boolean,
	IgnoreDescendants: (self: { Draggable }) -> (),
	IgnoreChildren: (self: { Draggable }) -> (),
	Destroy: (self: { Draggable }) -> (),

	Released: Signal.Event,
	Started: Signal.Event,
	Moved: Signal.Event,
}

return DraggableUI :: {
	new: (UI: Instance, byScale: true?) -> Draggable,
}
