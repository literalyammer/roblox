game.Players.LocalPlayer.Character:WaitForChild("Humanoid"):GetPropertyChangedSignal("WalkSpeed"):Connect(function()
	game.Players.LocalPlayer.Character:WaitForChild("Humanoid").WalkSpeed = 0
	game.Players.LocalPlayer.Character:WaitForChild("Humanoid").JumpPower = 0
end)