local this = script.Parent
local frame = this.Frame
local remote = this:WaitForChild('RemoteEvent')
local tweenService = game:GetService('TweenService')
local closeDebounce = false

frame.Close.AutoButtonColor = false
frame.Close.BackgroundTransparency = 1
frame.Close.MouseEnter:Connect(function()
	tweenService:Create(frame.Close, TweenInfo.new(.1, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {BackgroundTransparency=0}):Play()
end)
frame.Close.MouseLeave:Connect(function()
	tweenService:Create(frame.Close, TweenInfo.new(.1, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {BackgroundTransparency=1}):Play()
end)
frame.Close.MouseButton1Click:Connect(function()
	if (closeDebounce) then return end
	closeDebounce = true
	local tween = tweenService:Create(frame, TweenInfo.new(.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position=UDim2.new(.5, 0, 1+frame.AnchorPoint.Y, 0)})
	tween:Play()
	tween.Completed:Wait()
	remote:FireServer('destroy', {SHOW_MESSAGE=frame.Option.Checkbox:GetAttribute('isEnabled')})
end)

frame.Option.Checkbox:SetAttribute('isEnabled', false)
frame.Option.Checkbox.MouseButton1Click:Connect(function()
	local isEnabled = not frame.Option.Checkbox:GetAttribute('isEnabled')
	frame.Option.Checkbox:SetAttribute('isEnabled', isEnabled)
	tweenService:Create(frame.Option.Checkbox.Img, TweenInfo.new(.1, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {ImageTransparency=isEnabled and 0 or 1}):Play()
end)
local isEnabled = frame.Option.Checkbox:GetAttribute('isEnabled')
tweenService:Create(frame.Option.Checkbox.Img, TweenInfo.new(.1, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {ImageTransparency=isEnabled and 0 or 1}):Play()