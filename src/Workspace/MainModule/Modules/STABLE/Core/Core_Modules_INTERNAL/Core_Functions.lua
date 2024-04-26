local module = {}

local HEARTBEAT = _G.Cortex_SERVER.EVENTS.RUNTIME_EVENT.EVENT

function module:lerp(a: number, b: number, t: number)
	return a+(b-a)*t
end
function module:getDecelerationRate(initialSpeed: number, finalSpeed: number, distance: number)
	local si,sf = initialSpeed^2,finalSpeed^2
	local d2 = si-sf
	return math.abs(d2/math.deg(2*distance))
end
function module:getAccelerationTime(prevSpeed: number, speed: number, acceleration: number)
	return math.abs((speed-prevSpeed)/math.deg(acceleration))
end
function module:conditionalStepWait(duration: number, breakStatements: any)
	duration = math.clamp(duration, 0, math.huge)
	local startTick = tick()
	local function checkStatements()
		for i,v in pairs((breakStatements and typeof(breakStatements) == 'function') and breakStatements() or {}) do
			if (v) then return true end
		end
		return false
	end
	if (checkStatements()) then return false,(tick()-startTick) end
	while ((tick()-startTick)/duration < 1) do
		if (checkStatements()) then return false,(tick()-startTick) end
		HEARTBEAT:Wait()
	end
	return true,(tick()-startTick)
end
function module:getTableLength(t: any) --THIS IS USED FOR TABLES WITH INDEXES THAT ARE NOT NUMBERS -- #t DOES NOT WORK
	if (typeof(t) ~= 'table') then return end
	local length = 0
	for i,v in pairs(t) do
		length += 1
	end
	return length
end

function module.smoothstep(min: number, max: number, value: number)
	local t = math.clamp((value-min)/(max-min), 0, 1)
	return t*t*(3-2*t)
end

function module.addInstance(append: Instance, type: string, name: string, replaceWithSameName: boolean?, properties: any)
	if (typeof(append) ~= 'Instance') then return end
	if (typeof(type) ~= 'string') then return end
	local result = (if typeof(replaceWithSameName) == 'boolean' then (not replaceWithSameName) else false) and append:FindFirstChild(name)
	if (not result) then
		result = Instance.new(type)
		result.Parent = append
		result.Name = name
		for i,v in pairs(properties) do
			pcall(function()
				result[i] = v
			end)
		end
	end
	return result
end

function module:INITIATE_PLUGIN_INTERNAL(CORE, SOURCE)

end

return module