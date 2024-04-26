local Connection
Connection = script.Parent.AncestryChanged:Connect(function()
	if script:IsDescendantOf(game.Players) then
		Connection:Disconnect()
	end
	local player = script:FindFirstAncestorOfClass('Player')
	script.Parent.RemoteEvent.OnServerEvent:Connect(function(user,protocol,params)
		if (protocol == 'UPDATE_RATIO_VALUE' and user == player) then
			script.Parent.RATIO.Value = params
		end
	end)
end)