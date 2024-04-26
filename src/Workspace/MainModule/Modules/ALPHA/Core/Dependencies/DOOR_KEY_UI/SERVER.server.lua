--local Connection
--Connection = script.Parent.AncestryChanged:Connect(function()
	if not script:IsDescendantOf(game.Players) then
		return--Connection:Disconnect()
	end
	
	local player = script:FindFirstAncestorOfClass('Player')
	print(script.Parent.RemoteEvent:GetFullName())
	script.Parent:WaitForChild("RemoteEvent").OnServerEvent:Connect(function(user, protocol, params)
		if (protocol == 'UPDATE_RATIO_VALUE' and user == player) then
			script.Parent.RATIO.Value = params
		end
	end)
--end)