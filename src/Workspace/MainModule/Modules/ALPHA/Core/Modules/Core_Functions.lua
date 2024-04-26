local module = {}

local heartbeat =_G.Cortex_SERVER.EVENTS.RUNTIME_EVENT.EVENT

function module.lerp(a, b, t)
	return a+(b-a)*t
end

function module.getAccelerationTime(initialSpeed, finalSpeed, rate)
	return math.abs(finalSpeed-initialSpeed)/math.deg(rate)
end

function module.findAncestor(model, name)
	if (not model or typeof(model) ~= 'Instance') then return end
	local result = model:FindFirstChild(name, true)
	if (result) then
		return result
	else
		return module.findAncestor(model.Parent, name)
	end
end

function module.conditionalWait(duration, conditions)
	if (typeof(duration) ~= 'number') then return false end
	
	local function checkConditions()
		if (typeof(conditions) ~= 'function') then return true end
		for _, v in pairs(conditions()) do
			if (not v) then return false end
		end
		return true
	end
	
	local startTime = os.clock()
	while ((os.clock()-startTime)/duration < 1) do
		heartbeat:Wait()
		if (not checkConditions()) then return false, (os.clock()-startTime) end
	end
	return true, (os.clock()-startTime)
end

return module