script.Parent.Disabled = true
delay(.1, function()
	script.Parent.Disabled = false
	script:Destroy()
end)