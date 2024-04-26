local connection
connection = game:GetService("RunService").RenderStepped:Connect(function()
	if (not script.guard.Value) or (not script.guard.Value:FindFirstChild('HumanoidRootPart')) then return connection:Disconnect() end
	workspace.CurrentCamera.CFrame = workspace.CurrentCamera.CFrame:Lerp(CFrame.new(workspace.CurrentCamera.CFrame.p, script.guard.Value.Head.CFrame.p), .16)
end)