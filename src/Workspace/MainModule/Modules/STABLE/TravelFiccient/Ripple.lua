local image = script.Circle

function RippleEffect(btn,mX,mY)
	coroutine.resume(coroutine.create(function()
		local clone = image:Clone()
		clone.Parent = btn
		clone.ZIndex = btn.ZIndex
		local newX = mX - clone.AbsolutePosition.X
		local newY = mY - clone.AbsolutePosition.Y
		clone.Position = UDim2.new(0,newX,0,newY)
		local Size = 0
		if btn.AbsoluteSize.X > btn.AbsoluteSize.Y then
			 Size = btn.AbsoluteSize.X*3
		elseif btn.AbsoluteSize.X < btn.AbsoluteSize.Y then
			 Size = btn.AbsoluteSize.Y*3
		elseif btn.AbsoluteSize.X == btn.AbsoluteSize.Y then																																																																													
			Size = btn.AbsoluteSize.X*3
		end
		clone:TweenSizeAndPosition(UDim2.new(0,Size,0,Size),UDim2.new(0.5, -Size/2, 0.5, -Size/2), "Out", "Quart", 1.4, false, nil)
		for i = .25,1,.05 do
			clone.ImageTransparency = i
			wait(.01)
		end
		clone:Destroy()
	end))
end

return RippleEffect