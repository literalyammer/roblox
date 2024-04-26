local controlScript = require(game.Players.LocalPlayer.PlayerScripts:WaitForChild("PlayerModule"):WaitForChild("ControlModule"))

function script.binder.OnClientInvoke(bind)
	if bind then
		controlScript:Enable()
	else
		controlScript:Disable()
	end
end