local STYLE = require(script.Parent.STYLE)
local BUTTON_SYS = require(script.Parent.BUTTON_SYS)
local TWEEN_SERVICE = game:GetService('TweenService')

return {

	['BUTTONS'] = {
		['CONTROLS'] = {
			['INDEX']=1;
			['ADDONS'] = {
				['CONTROLS_FRAME'] = function(FRAME, DATA)
					local ELEVATOR
					local MAIN_FRAME = FRAME:FindFirstChild('MAIN_FRAME') or Instance.new('ScrollingFrame')
					MAIN_FRAME.Parent = FRAME
					MAIN_FRAME.Name = 'MAIN_FRAME'
					MAIN_FRAME.Position = UDim2.new(.5, 0, .15, 0)
					MAIN_FRAME.Size = UDim2.new(.8, 0, .67, 0)
					MAIN_FRAME.BackgroundTransparency = 1
					MAIN_FRAME.AnchorPoint = Vector2.new(1, 0)*.5
					local UI_LIST = MAIN_FRAME:FindFirstChildOfClass('UIListLayout') or Instance.new('UIListLayout')
					UI_LIST.Parent = MAIN_FRAME
					UI_LIST.FillDirection = Enum.FillDirection.Vertical
					UI_LIST.VerticalAlignment = Enum.VerticalAlignment.Top
					UI_LIST.HorizontalAlignment = Enum.HorizontalAlignment.Center
					UI_LIST.Padding = UDim.new(0, 15)
					UI_LIST.SortOrder = Enum.SortOrder.LayoutOrder

					UI_LIST:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
						MAIN_FRAME.CanvasSize = UDim2.new(0, 0, 0, UI_LIST.AbsoluteContentSize.Y)
					end)

					return {
						REFRESH=function(PREVIOUS_ELEVATOR, NEW_ELEVATOR)
							local BUTTONS = {}
							ELEVATOR = NEW_ELEVATOR
							if (not NEW_ELEVATOR) then return [[error('NEW_ELEVATOR is nil', 2)]] end
							for i,v in pairs(MAIN_FRAME:GetChildren()) do
								if (not v:IsA('UIListLayout')) then
									v:Destroy()
								end
							end
							BUTTONS.CALL_BUTTON = {
								['INDEX']=1;
								['LABEL']='CALL';
								['INPUT_TYPE']='NUMERICAL';
								['INVOKE_FUNCTION']=function(REMOTE, ELEVATOR, VALUE)
									REMOTE:InvokeServer(ELEVATOR, {'Request_Call_F', VALUE});
								end;
							};
							for i,v in pairs(ELEVATOR.Legacy:GetChildren()) do
								if (string.match(v.Name, 'Door_State')) then
									local SIDE = string.split(string.split(v.Name, 'Door_State')[1], '_')[1]
									if (not BUTTONS[SIDE]) then
										BUTTONS[SIDE] = {}
									end
									BUTTONS[SIDE].LABEL_NAME = SIDE
									BUTTONS[SIDE].BUTTONS = {
										[`OPEN_{string.upper(SIDE)}_DOORS`]={
											['INDEX']=1;
											['LABEL']=`OPEN {string.upper(SIDE)} DOORS`;
											['INPUT_TYPE']='TRIGGER';
											['INVOKE_FUNCTION']=function(REMOTE, ELEVATOR, VALUE)
												REMOTE:InvokeServer(ELEVATOR, {'Door_Open', SIDE});
											end;
										},
										[`CLOSE_{string.upper(SIDE)}_DOORS`]={
											['INDEX']=2;
											['LABEL']=`CLOSE {string.upper(SIDE)} DOORS`;
											['INPUT_TYPE']='TRIGGER';
											['INVOKE_FUNCTION']=function(REMOTE, ELEVATOR, VALUE)
												REMOTE:InvokeServer(ELEVATOR, {'Door_Close', SIDE});
											end;
										},
										[`NUDGE_{string.upper(SIDE)}_DOORS`]={
											['INDEX']=3;
											['LABEL']=`NUDGE {string.upper(SIDE)} DOORS`;
											['INPUT_TYPE']='TRIGGER';
											['INVOKE_FUNCTION']=function(REMOTE, ELEVATOR, VALUE)
												REMOTE:InvokeServer(ELEVATOR, {'Door_Nudge', SIDE});
											end;
										}
									}
								end
							end
							return {BUTTONS=BUTTONS}
						end,
						CONTENT_FRAME=MAIN_FRAME
					}
				end,
			}
		};
		['FIRE_SERVICE'] = {
			['INDEX']=2;
			['BUTTONS']={
				['RECALL']={
					['INDEX']=1;
					['LABEL']='RECALL';
					['INPUT_TYPE']='NUMERICAL';
					['INVOKE_FUNCTION']=function(REMOTE, ELEVATOR, VALUE)
						REMOTE:InvokeServer(ELEVATOR, {'Fire_Recall', true, VALUE});
					end;
				};
				['DISABLE_RECALL']={
					['INDEX']=2;
					['LABEL']='DISABLE RECALL';
					['INPUT_TYPE']='TRIGGER';
					['INVOKE_FUNCTION']=function(REMOTE, ELEVATOR, VALUE)
						REMOTE:InvokeServer(ELEVATOR, {'Fire_Recall', false, ELEVATOR.Legacy.Floor.Value});
					end;
				};
				['ENABLE_PHASE_2']={
					['INDEX']=3;
					['LABEL']='ENABLE PHASE 2';
					['INPUT_TYPE']='TRIGGER';
					['INVOKE_FUNCTION']=function(REMOTE, ELEVATOR, VALUE)
						REMOTE:InvokeServer(ELEVATOR, {'Phase_2', true});
					end;
				};
				['DISABLE_PHASE_2']={
					['INDEX']=4;
					['LABEL']='DISABLE PHASE 2';
					['INPUT_TYPE']='TRIGGER';
					['INVOKE_FUNCTION']=function(REMOTE, ELEVATOR, VALUE)
						REMOTE:InvokeServer(ELEVATOR, {'Phase_2', false});
					end;
				};
			};
		};
		['INDEPENDENT_SERVICE'] = {
			['INDEX']=3;
			['BUTTONS']={
				['ENABLE']={
					['INDEX']=1;
					['LABEL']='ENABLE';
					['INPUT_TYPE']='TRIGGER';
					['INVOKE_FUNCTION']=function(REMOTE, ELEVATOR, VALUE)
						REMOTE:InvokeServer(ELEVATOR, {'invokeIndependentService', true});
					end;
				};
				['DISABLE']={
					['INDEX']=2;
					['LABEL']='DISABLE';
					['INPUT_TYPE']='TRIGGER';
					['INVOKE_FUNCTION']=function(REMOTE, ELEVATOR, VALUE)
						REMOTE:InvokeServer(ELEVATOR, {'invokeIndependentService', false});
					end;
				};
			};
		};
		['INSPECTION'] = {
			['INDEX']=4;
			['BUTTONS']={
				['ENABLE']={
					['INDEX']=1;
					['LABEL']='TURN ON INSPECTION';
					['INPUT_TYPE']='TRIGGER';
					['INVOKE_FUNCTION']=function(REMOTE, ELEVATOR, VALUE)
						REMOTE:InvokeServer(ELEVATOR, {'setInspection', true});
					end;
				};
				['DISABLE']={
					['INDEX']=2;
					['LABEL']='TURN OFF INSPECTION';
					['INPUT_TYPE']='TRIGGER';
					['INVOKE_FUNCTION']=function(REMOTE, ELEVATOR, VALUE)
						REMOTE:InvokeServer(ELEVATOR, {'setInspection', false});
					end;
				};

				['DRIVE_UP']={
					['INDEX']=3;
					['LABEL']='DRIVE CAR UP';
					['INPUT_TYPE']='TRIGGER_HOLD';
					['INVOKE_FUNCTION_DOWN']=function(REMOTE, ELEVATOR, VALUE)
						REMOTE:InvokeServer(ELEVATOR, {'inspectionMove', {'Up', require(ELEVATOR.Settings).Movement.Travel_Speed/2.5}});
					end;
					['INVOKE_FUNCTION_RELEASE']=function(REMOTE, ELEVATOR, VALUE)
						REMOTE:InvokeServer(ELEVATOR, {'inspectionStop', 'U'});
					end;
				};
				['DRIVE_DOWN']={
					['INDEX']=4;
					['LABEL']='DRIVE CAR DOWN';
					['INPUT_TYPE']='TRIGGER_HOLD';
					['INVOKE_FUNCTION_DOWN']=function(REMOTE, ELEVATOR, VALUE)
						REMOTE:InvokeServer(ELEVATOR, {'inspectionMove', {'Down', require(ELEVATOR.Settings).Movement.Travel_Speed/2.5}});
					end;
					['INVOKE_FUNCTION_RELEASE']=function(REMOTE, ELEVATOR, VALUE)
						REMOTE:InvokeServer(ELEVATOR, {'inspectionStop', 'D'});
					end;
				};
			};
		};
		['STOP_ELEVATOR'] = {
			['INDEX']=5;
			['BUTTONS']={
				['ENABLE']={
					['INDEX']=1;
					['LABEL']='STOP';
					['INPUT_TYPE']='TRIGGER';
					['INVOKE_FUNCTION']=function(REMOTE, ELEVATOR, VALUE)
						REMOTE:InvokeServer(ELEVATOR, {'Stop', true});
					end;
				};
				['DISABLE']={
					['INDEX']=2;
					['LABEL']='RELEASE';
					['INPUT_TYPE']='TRIGGER';
					['INVOKE_FUNCTION']=function(REMOTE, ELEVATOR, VALUE)
						REMOTE:InvokeServer(ELEVATOR, {'Stop', false});
					end;
				};
			};
		};
		['STATISTICS'] = {
			['INDEX']=6;
			['BUTTONS']={
				
			};
			['ADDONS'] = {
				['STATISTICS_FRAME'] = function(FRAME, DATA)
					local ELEVATOR
					local STATISTICS_FRAME = FRAME:FindFirstChild('STATISTICS_FRAME')
					if (not STATISTICS_FRAME) then
						STATISTICS_FRAME = Instance.new('ScrollingFrame')
						STATISTICS_FRAME.Size = UDim2.fromScale(.85, .7)
						STATISTICS_FRAME.AnchorPoint = Vector2.new(1,0)*.5
						STATISTICS_FRAME.Position = UDim2.fromScale(STATISTICS_FRAME.AnchorPoint.X, .1)
						STATISTICS_FRAME.BackgroundTransparency = 1
						STATISTICS_FRAME.Name = 'STATISTICS_FRAME'
						local UILISTLAYOUT = Instance.new('UIListLayout')
						UILISTLAYOUT.FillDirection = Enum.FillDirection.Vertical
						UILISTLAYOUT.VerticalAlignment = Enum.VerticalAlignment.Top
						UILISTLAYOUT.HorizontalAlignment = Enum.HorizontalAlignment.Center
						UILISTLAYOUT.SortOrder = Enum.SortOrder.LayoutOrder
						UILISTLAYOUT.Padding = UDim.new(0, 25)
						UILISTLAYOUT.Parent = STATISTICS_FRAME
						STATISTICS_FRAME.Parent = FRAME
						UILISTLAYOUT:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
							STATISTICS_FRAME.CanvasSize = UDim2.new(0, 0, 0, UILISTLAYOUT.AbsoluteContentSize.Y)
						end)
					end
					local CONNECTIONS = {}
					
					return {
						REFRESH=function(PREVIOUS_ELEVATOR, NEW_ELEVATOR)
							ELEVATOR = NEW_ELEVATOR
							for i,v in pairs(STATISTICS_FRAME:GetChildren()) do
								if (v.Name == 'LEGACY_VALUE') then
									v:Destroy()
								end
							end
							for _,v in pairs(CONNECTIONS) do
								if (v.Connected) then
									v:Disconnect()
								end
							end
							if (not NEW_ELEVATOR) then return [[error('NEW_ELEVATOR is nil', 2)]] end
							local legacyValues = {}
							for _,v in pairs(ELEVATOR:WaitForChild('Legacy'):GetChildren()) do
								table.insert(legacyValues, v)
							end
							table.sort(legacyValues, function(a,b) return a.Name < b.Name end)
							for _,v in ipairs(legacyValues) do
								local NEW_VALUE_FRAME = script.Parent.DEPENDENCIES.LEGACY_VALUE:Clone()
								NEW_VALUE_FRAME.Name = 'LEGACY_VALUE'
								local gsubName = select(1, string.gsub(v.Name, '_', ' '))
								NEW_VALUE_FRAME.NAME.Text = string.upper(gsubName)
								NEW_VALUE_FRAME.LayoutOrder = _
								NEW_VALUE_FRAME.Size = UDim2.new(.75, 0, 0, 40)
								NEW_VALUE_FRAME.Parent = STATISTICS_FRAME
								local CONNECTION: RBXScriptConnection
								CONNECTION = v:GetPropertyChangedSignal('Value'):Connect(function()
									NEW_VALUE_FRAME.VALUE.Text = string.upper(tonumber(v.Value) and math.round(tonumber(v.Value)*1000)/1000 or tostring(v.Value))
								end)
								NEW_VALUE_FRAME.VALUE.Text = string.upper(tonumber(v.Value) and math.round(tonumber(v.Value)*1000)/1000 or tostring(v.Value))
								table.insert(CONNECTIONS, CONNECTION)
							end
						end,
					}
				end,
			},
		};
		['LOCKING_MANAGER'] = {
			['INDEX']=7;
			['BUTTONS']={

			};
			['ADDONS'] = {
				['MAIN_FRAME'] = function(FRAME)
					local ELEVATOR
					local MAIN_FRAME = FRAME:FindFirstChild('MAIN_FRAME') or script.Parent.DEPENDENCIES.LM_MAIN_FRAME:Clone()
					MAIN_FRAME.Parent = FRAME
					local IS_IN_MENU = false
					local MENU_DEBOUNCE = false
					local SELECTED_FLOORS = {}

					local BUTTON_META = {
						['LOCK'] = {
							['LOCK_CAR'] = {
								['LABEL']='LOCK CAR',
								['ACTIVATE_FUNCTION']=function(PARAMS)
									local RAN,RES = pcall(function()
										script.Parent.Parent.DATA_REMOTE:InvokeServer('CORTEX_API_FIRE', {ELEVATOR=ELEVATOR,PROTOCOL='Lock_Floors',PARAMS=SELECTED_FLOORS})
									end)
									if (not RAN) then
										warn(`RemoteControls :: Locking Manager Error - {RES}`)
									end
								end,
							},
							['LOCK_HALL'] = {
								['LABEL']='LOCK HALL',
								['ACTIVATE_FUNCTION']=function(PARAMS)
									local RAN,RES = pcall(function()
										script.Parent.Parent.DATA_REMOTE:InvokeServer('CORTEX_API_FIRE', {ELEVATOR=ELEVATOR,PROTOCOL='Lock_Hall_Floors',PARAMS=SELECTED_FLOORS})
									end)
									if (not RAN) then
										warn(`RemoteControls :: Locking Manager Error - {RES}`)
									end
								end,
							}
						},
						----
						['UNLOCK'] = {
							['UNLOCK_CAR'] = {
								['LABEL']='UNLOCK CAR',
								['ACTIVATE_FUNCTION']=function(PARAMS)
									local RAN,RES = pcall(function()
										script.Parent.Parent.DATA_REMOTE:InvokeServer('CORTEX_API_FIRE', {ELEVATOR=ELEVATOR,PROTOCOL='Unlock_Floors',PARAMS=SELECTED_FLOORS})
									end)
									if (not RAN) then
										warn(`RemoteControls :: Locking Manager Error - {RES}`)
									end
								end,
							},
							['UNLOCK_HALL'] = {
								['LABEL']='UNLOCK HALL',
								['ACTIVATE_FUNCTION']=function(PARAMS)
									local RAN,RES = pcall(function()
										script.Parent.Parent.DATA_REMOTE:InvokeServer('CORTEX_API_FIRE', {ELEVATOR=ELEVATOR,PROTOCOL='Unlock_Hall_Floors',PARAMS=SELECTED_FLOORS})
									end)
									if (not RAN) then
										warn(`RemoteControls :: Locking Manager Error - {RES}`)
									end
								end,
							}
						},
					}

					local TYPE_INDEX = 0
					for TYPE,BUTTONS in next,BUTTON_META do
						TYPE_INDEX += 1
						local LABEL = MAIN_FRAME.LM_BUTTONS.LIST:FindFirstChild(`{TYPE}_LABEL`) or Instance.new('TextLabel')
						LABEL.Parent = MAIN_FRAME.LM_BUTTONS.LIST
						LABEL.Size = UDim2.new(1, 0, 0, 35)
						LABEL.AnchorPoint = Vector2.new(1, 1)*.5
						LABEL.Name = `{TYPE}_LABEL`
						LABEL.BackgroundTransparency = 1
						LABEL.Text = TYPE
						LABEL.FontFace = Font.new(`rbxassetid://{STYLE.FONT_ID}`, Enum.FontWeight.Regular, Enum.FontStyle.Normal)
						LABEL.TextColor3 = Color3.new(1, 1, 1)
						LABEL.TextScaled = true
						LABEL.RichText = true
						LABEL.LayoutOrder = TYPE_INDEX
						for LOCKING_TYPE,BUTTON in next,BUTTONS do
							local NEW_BUTTON = BUTTON_SYS.ADD_BUTTON(MAIN_FRAME.LM_BUTTONS.LIST, table.concat(string.split(LOCKING_TYPE, '_'), ' '))
							NEW_BUTTON.LayoutOrder = TYPE_INDEX+1
							NEW_BUTTON.Size = UDim2.new(0, NEW_BUTTON.AbsoluteSize.X, 0, 35)
							NEW_BUTTON.MouseButton1Click:Connect(function()
								BUTTON.ACTIVATE_FUNCTION({FLOORS=SELECTED_FLOORS})
							end)
							NEW_BUTTON.MouseEnter:Connect(function()
								TWEEN_SERVICE:Create(NEW_BUTTON.MASK.UIStroke, TweenInfo.new(.4, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {Color=require(script.Parent.COLORFRAME).TOP_BUTTONS.LOCKING_MANAGER.COLOR}):Play()
							end)
							NEW_BUTTON.MouseLeave:Connect(function()
								TWEEN_SERVICE:Create(NEW_BUTTON.MASK.UIStroke, TweenInfo.new(.4, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {Color=Color3.new(1, 1, 1)}):Play()
							end)
						end
					end

					MAIN_FRAME.LIST.UIListLayout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
						MAIN_FRAME.NO_FLOORS.Visible = #MAIN_FRAME.LIST:GetChildren() < 2
					end)
					MAIN_FRAME.NO_FLOORS.Visible = #MAIN_FRAME.LIST:GetChildren() < 2

					MAIN_FRAME.SUBMIT.MouseButton1Click:Connect(function()
						if (IS_IN_MENU or MENU_DEBOUNCE) then return end
						IS_IN_MENU = true
						MENU_DEBOUNCE = true
						local TWEEN = TWEEN_SERVICE:Create(MAIN_FRAME.LM_BUTTONS, TweenInfo.new(.4, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {Position=UDim2.new(.5, 0, .5, 0)})
						TWEEN:Play()
						TWEEN.Completed:Wait()
						if (TWEEN.PlaybackState ~= Enum.PlaybackState.Completed) then return end
						local TWEEN = TWEEN_SERVICE:Create(MAIN_FRAME.LM_BUTTONS, TweenInfo.new(.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size=UDim2.new(1, -MAIN_FRAME.LM_BUTTONS.UIStroke.Thickness, 1, -MAIN_FRAME.LM_BUTTONS.UIStroke.Thickness)})
						TWEEN:Play()
						TWEEN.Completed:Wait()
						if (TWEEN.PlaybackState ~= Enum.PlaybackState.Completed) then return end
						MENU_DEBOUNCE = false
					end)
					MAIN_FRAME.SUBMIT.MouseEnter:Connect(function()
						TWEEN_SERVICE:Create(MAIN_FRAME.SUBMIT.MASK.UIStroke, TweenInfo.new(.25, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {Color=require(script.Parent.COLORFRAME).TOP_BUTTONS.LOCKING_MANAGER.COLOR}):Play()
					end)
					MAIN_FRAME.SUBMIT.MouseLeave:Connect(function()
						TWEEN_SERVICE:Create(MAIN_FRAME.SUBMIT.MASK.UIStroke, TweenInfo.new(.25, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {Color=Color3.new(1, 1, 1)}):Play()
					end)
					MAIN_FRAME.LM_BUTTONS.Size = UDim2.new(1, 0, 0, 0)

					MAIN_FRAME.LM_BUTTONS.BACK.MouseButton1Click:Connect(function()
						if ((not IS_IN_MENU) or MENU_DEBOUNCE) then return end
						IS_IN_MENU = false
						MENU_DEBOUNCE = true
						local TWEEN = TWEEN_SERVICE:Create(MAIN_FRAME.LM_BUTTONS, TweenInfo.new(.4, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {Size=UDim2.new(1, -MAIN_FRAME.LM_BUTTONS.UIStroke.Thickness, 0, 0)})
						TWEEN:Play()
						TWEEN.Completed:Wait()
						if (TWEEN.PlaybackState ~= Enum.PlaybackState.Completed) then return end
						local TWEEN = TWEEN_SERVICE:Create(MAIN_FRAME.LM_BUTTONS, TweenInfo.new(.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position=UDim2.new(.5, 0, 1.5, 0)})
						TWEEN:Play()
						TWEEN.Completed:Wait()
						if (TWEEN.PlaybackState ~= Enum.PlaybackState.Completed) then return end
						MENU_DEBOUNCE = false
					end)
					MAIN_FRAME.LM_BUTTONS.BACK.MouseEnter:Connect(function()
						TWEEN_SERVICE:Create(MAIN_FRAME.LM_BUTTONS.BACK.MASK.UIStroke, TweenInfo.new(.25, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {Color=require(script.Parent.COLORFRAME).TOP_BUTTONS.LOCKING_MANAGER.COLOR}):Play()
					end)
					MAIN_FRAME.LM_BUTTONS.BACK.MouseLeave:Connect(function()
						TWEEN_SERVICE:Create(MAIN_FRAME.LM_BUTTONS.BACK.MASK.UIStroke, TweenInfo.new(.25, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {Color=Color3.new(1, 1, 1)}):Play()
					end)

					return {
						REFRESH=function(PREVIOUS_ELEVATOR, NEW_ELEVATOR)
							ELEVATOR = NEW_ELEVATOR
							for i,v in pairs(MAIN_FRAME.LIST:GetChildren()) do
								if (v:IsA('Frame')) then
									v:Destroy()
								end
							end
							if (not NEW_ELEVATOR) then return [[error('NEW_ELEVATOR is nil', 2)]] end
							for i,v in pairs(ELEVATOR.Floors:GetChildren()) do
								local FLOOR_NAME = tonumber(string.split(v.Name, 'Floor_')[2])
								local NEW_FRAME = MAIN_FRAME.LIST:FindFirstChild(`FLOOR_{FLOOR_NAME}_FRAME`) or Instance.new('Frame')
								NEW_FRAME.Parent = MAIN_FRAME.LIST
								NEW_FRAME.Name = `FLOOR_{FLOOR_NAME}_FRAME`
								NEW_FRAME.Size = UDim2.new(1, -20, 0, 50)
								NEW_FRAME.AnchorPoint = Vector2.new(1, 1)*.5
								NEW_FRAME.BackgroundTransparency = 1
								NEW_FRAME.BorderSizePixel = 0
								NEW_FRAME.LayoutOrder = FLOOR_NAME
								local TICK_BOX_FRAME = NEW_FRAME:FindFirstChild('TICK_BOX_FRAME') or Instance.new('Frame')
								TICK_BOX_FRAME.Parent = NEW_FRAME
								TICK_BOX_FRAME.Name = 'TICK_BOX_FRAME'
								TICK_BOX_FRAME.Position = UDim2.new(0, 10, .5, 0)
								TICK_BOX_FRAME.AnchorPoint = Vector2.new(0, 1)*.5
								TICK_BOX_FRAME.Size = UDim2.new(0, NEW_FRAME.AbsoluteSize.Y-20, 0, NEW_FRAME.AbsoluteSize.Y-20)
								TICK_BOX_FRAME.BackgroundTransparency = 1
								local UICORNER = TICK_BOX_FRAME:FindFirstChildOfClass('UICorner') or Instance.new('UICorner')
								UICORNER.Parent = TICK_BOX_FRAME
								UICORNER.CornerRadius = UDim.new(0, 5)
								local UISTROKE = TICK_BOX_FRAME:FindFirstChildOfClass('UIStroke') or Instance.new('UIStroke')
								UISTROKE.Parent = TICK_BOX_FRAME
								UISTROKE.Color = Color3.new(1, 1, 1)
								UISTROKE.Thickness = 2
								local TICK_IMG = TICK_BOX_FRAME:FindFirstChildOfClass('ImageButton') or Instance.new('ImageButton')
								TICK_IMG.Parent = TICK_BOX_FRAME
								TICK_IMG.Position = UDim2.new(.5, 0, .5, 0)
								TICK_IMG.AnchorPoint = Vector2.new(1, 1)*.5
								TICK_IMG.Size = UDim2.new(1, -3, 1, -3)
								TICK_IMG.BackgroundTransparency = 1
								TICK_IMG.Image = 'rbxassetid://5853990158'
								local UISCALE = TICK_BOX_FRAME:FindFirstChildOfClass('UIScale') or Instance.new('UIScale')
								UISCALE.Parent = TICK_IMG
								UISCALE.Scale = 0
								local MASK_FRAME = NEW_FRAME:FindFirstChild('MASK') or Instance.new('Frame')
								MASK_FRAME.Parent = NEW_FRAME
								MASK_FRAME.Name = 'MASK'
								MASK_FRAME.Size = UDim2.new(1, -5, 1, -5)
								MASK_FRAME.Position = UDim2.new(.5, 0, .5, 0)
								MASK_FRAME.AnchorPoint = Vector2.new(1, 1)*.5
								MASK_FRAME.BackgroundTransparency = 1
								MASK_FRAME.BorderSizePixel = 0
								local UICORNER = MASK_FRAME:FindFirstChildOfClass('UICorner') or Instance.new('UICorner')
								UICORNER.Parent = MASK_FRAME
								UICORNER.CornerRadius = UDim.new(0, 8)
								local UISTROKE = MASK_FRAME:FindFirstChildOfClass('UIStroke') or Instance.new('UIStroke')
								UISTROKE.Parent = MASK_FRAME
								UISTROKE.Color = Color3.new(1, 1, 1)
								UISTROKE.Thickness = 2
								local LABEL = MASK_FRAME:FindFirstChild(`Floor {FLOOR_NAME}`) or Instance.new('TextButton')
								LABEL.Parent = MASK_FRAME
								LABEL.Size = UDim2.new(.95, 0, .75, 0)
								LABEL.Position = UDim2.new(.5, 0, .5, 0)
								LABEL.AnchorPoint = Vector2.new(1, 1)*.5
								LABEL.BackgroundTransparency = 1
								LABEL.Text = `Floor {FLOOR_NAME}`
								LABEL.FontFace = Font.new(`rbxassetid://{STYLE.FONT_ID}`, Enum.FontWeight.Regular, Enum.FontStyle.Normal)
								LABEL.TextScaled = true
								LABEL.RichText = true
								LABEL.TextColor3 = Color3.new(1, 1, 1)

								LABEL.MouseButton1Click:Connect(function()
									if (not table.find(SELECTED_FLOORS, FLOOR_NAME)) then
										table.insert(SELECTED_FLOORS, FLOOR_NAME)
										TWEEN_SERVICE:Create(TICK_IMG.UIScale, TweenInfo.new(.3, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), {Scale=1}):Play()
									else
										local INDEX = table.find(SELECTED_FLOORS, FLOOR_NAME)
										table.remove(SELECTED_FLOORS, INDEX)
										TWEEN_SERVICE:Create(TICK_IMG.UIScale, TweenInfo.new(.15, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {Scale=0}):Play()
									end
								end)
								LABEL.MouseEnter:Connect(function()
									TWEEN_SERVICE:Create(UISTROKE, TweenInfo.new(.25, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {Color=require(script.Parent.COLORFRAME).TOP_BUTTONS.LOCKING_MANAGER.COLOR}):Play()
									TWEEN_SERVICE:Create(TICK_BOX_FRAME.UIStroke, TweenInfo.new(.25, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {Color=require(script.Parent.COLORFRAME).TOP_BUTTONS.LOCKING_MANAGER.COLOR}):Play()
								end)
								LABEL.MouseLeave:Connect(function()
									TWEEN_SERVICE:Create(UISTROKE, TweenInfo.new(.25, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {Color=Color3.new(1, 1, 1)}):Play()
									TWEEN_SERVICE:Create(TICK_BOX_FRAME.UIStroke, TweenInfo.new(.25, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {Color=Color3.new(1, 1, 1)}):Play()
								end)

							end
						end,
					}
				end,
			}
		};
		['OUTPUT'] = {
			['INDEX']=8;
			['BUTTONS']={

			};
			['ADDONS'] = {
				['OUTPUT_FRAME'] = function(FRAME, DATA)
					local ELEVATOR
					local OUTPUT_FRAME = FRAME:FindFirstChild('OUTPUT_FRAME') or script.Parent.DEPENDENCIES.OUTPUT_FRAME:Clone()
					OUTPUT_FRAME.Parent = FRAME
					local CANVAS_BOTTOM = Vector2.new(0, 999999999)

					local LAST_CANVAS_POSITION = OUTPUT_FRAME.LIST.CanvasPosition
					OUTPUT_FRAME.LIST.UIListLayout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
						OUTPUT_FRAME.NO_MESSAGES.Visible = OUTPUT_FRAME.LIST.UIListLayout.AbsoluteContentSize.Y <= 0
						local NEW_CANVAS_POS = Vector2.new(0, OUTPUT_FRAME.LIST.UIListLayout.AbsoluteContentSize.Y-OUTPUT_FRAME.LIST.AbsoluteSize.Y)
						local LAST_CANVAS_POS = OUTPUT_FRAME.LIST.CanvasPosition
						OUTPUT_FRAME.LIST.CanvasPosition = CANVAS_BOTTOM
						local NEW_CANVAS_POS = OUTPUT_FRAME.LIST.CanvasPosition
						OUTPUT_FRAME.LIST.CanvasSize = UDim2.new(0, 0, 0, OUTPUT_FRAME.LIST.UIListLayout.AbsoluteContentSize.Y)
						OUTPUT_FRAME.LIST.CanvasPosition = LAST_CANVAS_POS
						if (OUTPUT_FRAME.LIST.CanvasPosition.Y >= NEW_CANVAS_POS.Y) then
							game:GetService('TweenService'):Create(OUTPUT_FRAME.LIST, TweenInfo.new(.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {CanvasPosition=CANVAS_BOTTOM}):Play()
						end
						LAST_CANVAS_POSITION = OUTPUT_FRAME.LIST.CanvasPosition
					end)
					OUTPUT_FRAME.NO_MESSAGES.Visible = OUTPUT_FRAME.LIST.UIListLayout.AbsoluteContentSize.Y <= 0
					OUTPUT_FRAME.LIST.CanvasSize = UDim2.new(0, 0, 0, OUTPUT_FRAME.LIST.UIListLayout.AbsoluteContentSize.Y)

					local function ADD_OUTPUT_LABEL(DATA: any)
						local UID = game:GetService('HttpService'):GenerateGUID(false)
						local TIMESTAMP = DATA.timestamp:FormatLocalTime('HH:MM:ss', 'en-us')
						local MASK_FRAME = OUTPUT_FRAME.LIST:FindFirstChild(`OUTPUT_LABEL_MASK_{UID}`) or Instance.new('Frame')
						MASK_FRAME.Parent = OUTPUT_FRAME.LIST
						MASK_FRAME.Name = `OUTPUT_LABEL_MASK_{UID}`
						MASK_FRAME.Size = UDim2.new(1, -OUTPUT_FRAME.LIST.ScrollBarThickness, 0, 45)
						MASK_FRAME.BackgroundTransparency = 1
						MASK_FRAME:SetAttribute('MESSAGE_ID', DATA.message.id)
						local LABEL = MASK_FRAME:FindFirstChild('OUTPUT_LABEL') or Instance.new('TextLabel')
						LABEL.Name = 'OUTPUT_LABEL'
						LABEL.Parent = MASK_FRAME
						LABEL.AnchorPoint = Vector2.new(0, .5)
						LABEL.Position = UDim2.new(-1, 0, .5, 0)
						LABEL.Size = UDim2.new(1, 0, 1, 0)
						LABEL.FontFace = Font.new('rbxassetid://12187365364')
						LABEL.BackgroundTransparency = 1
						LABEL.TextSize = 20
						LABEL.TextWrapped = true
						LABEL.RichText = true
						local r,g,b = DATA.color.R,DATA.color.G,DATA.color.B
						LABEL.Text = `<font color="#ffffff"><b>[{TIMESTAMP}]: </b>{DATA.elevator.Name}</font><font color="rgb({math.ceil(r*255)},{math.ceil(g*255)},{math.ceil(b*255)})"> - {DATA.message.content}</font>`
						LABEL.TextXAlignment = Enum.TextXAlignment.Left
						MASK_FRAME.Size = UDim2.new(MASK_FRAME.Size.X.Scale, MASK_FRAME.Size.X.Offset, 0, LABEL.TextBounds.Y)
						game:GetService('TweenService'):Create(LABEL, TweenInfo.new(.15, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), {Position=UDim2.new(0, 0, .5, 0)}):Play()
					end

					local GLOBAL_REMOTE = game.ReplicatedStorage:WaitForChild('Cortex_Remote_GLOBAL')
					GLOBAL_REMOTE.OnClientEvent:Connect(function(PROTOCOL, PARAMS)
						if (PARAMS.elevator ~= ELEVATOR) then return end
						if (not ELEVATOR) then return [[error('ELEVATOR is nil', 2)]] end
						if (PROTOCOL == 'Cortex_Output_Message_Broadcast') then
							ADD_OUTPUT_LABEL(PARAMS)
						elseif (PROTOCOL == 'Cortex_Output_Message_Remove') then
							for i,v in pairs(OUTPUT_FRAME.LIST:GetChildren()) do
								if (v:GetAttribute('MESSAGE_ID') == PARAMS.message.id) then
									v:Destroy()
								end
							end
						end
					end)

					return {
						REFRESH=function(PREVIOUS_ELEVATOR, NEW_ELEVATOR)
							ELEVATOR = NEW_ELEVATOR
							for i,v in pairs(OUTPUT_FRAME.LIST:GetChildren()) do
								if (v.Name == 'OUTPUT_LABEL_MASK') then
									v:Destroy()
								end
							end
							if (not NEW_ELEVATOR) then return [[error('NEW_ELEVATOR is nil', 2)]] end
							local OUTPUT_STORAGE = script.Parent.Parent.DATA_REMOTE:InvokeServer('GET_ELEVATOR_OUTPUT_STORAGE')
							for KEY,DATA in pairs(OUTPUT_STORAGE[NEW_ELEVATOR.Name]) do
								ADD_OUTPUT_LABEL(DATA)
							end
						end,
					}

				end,
			}
		};
	};

};