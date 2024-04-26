local module = {}

local HEARTBEAT = _G.Cortex_SERVER.EVENTS.RUNTIME_EVENT.EVENT

function module:INITIATE_PLUGIN_INTERNAL(CORE, SOURCE) end --SILENCES INITIATION ERRORS

module.easingStyles = {
	['Linear'] = {Enum.EasingStyle.Linear, Enum.EasingDirection.InOut},
	['In_Sine'] = {Enum.EasingStyle.Sine, Enum.EasingDirection.In},
	['Out_Sine'] = {Enum.EasingStyle.Sine, Enum.EasingDirection.Out},
	['In_Out_Sine'] = {Enum.EasingStyle.Sine, Enum.EasingDirection.InOut},
	['In_Quad'] = {Enum.EasingStyle.Quad, Enum.EasingDirection.In},
	['Out_Quad'] = {Enum.EasingStyle.Quad, Enum.EasingDirection.Out},
	['In_Out_Quad'] = {Enum.EasingStyle.Quad, Enum.EasingDirection.InOut},
	['In_Quart'] = {Enum.EasingStyle.Quart, Enum.EasingDirection.In},
	['Out_Quart'] = {Enum.EasingStyle.Quart, Enum.EasingDirection.Out},
	['In_Out_Quart'] = {Enum.EasingStyle.Quart, Enum.EasingDirection.InOut},
	['In_Back'] = {Enum.EasingStyle.Back, Enum.EasingDirection.In},
	['Out_Back'] = {Enum.EasingStyle.Back, Enum.EasingDirection.Out},
	['In_Out_Back'] = {Enum.EasingStyle.Back, Enum.EasingDirection.InOut},
	['In_Bounce'] = {Enum.EasingStyle.Bounce, Enum.EasingDirection.In},
	['Out_Bounce'] = {Enum.EasingStyle.Bounce, Enum.EasingDirection.Out},
	['In_Out_Bounce'] = {Enum.EasingStyle.Bounce, Enum.EasingDirection.InOut},
	['In_Circular'] = {Enum.EasingStyle.Circular, Enum.EasingDirection.In},
	['Out_Circular'] = {Enum.EasingStyle.Circular, Enum.EasingDirection.Out},
	['In_Out_Circular'] = {Enum.EasingStyle.Circular, Enum.EasingDirection.InOut},
	['In_Cubic'] = {Enum.EasingStyle.Cubic, Enum.EasingDirection.In},
	['Out_Cubic'] = {Enum.EasingStyle.Cubic, Enum.EasingDirection.Out},
	['In_Out_Cubic'] = {Enum.EasingStyle.Cubic, Enum.EasingDirection.InOut},
	['In_Elastic'] = {Enum.EasingStyle.Elastic, Enum.EasingDirection.In},
	['Out_Elastic'] = {Enum.EasingStyle.Elastic, Enum.EasingDirection.Out},
	['In_Out_Elastic'] = {Enum.EasingStyle.Elastic, Enum.EasingDirection.InOut},
	['In_Exponential'] = {Enum.EasingStyle.Exponential, Enum.EasingDirection.In},
	['In_Out_Exponential'] = {Enum.EasingStyle.Exponential, Enum.EasingDirection.Out},
	['In_Quint'] = {Enum.EasingStyle.Quint, Enum.EasingDirection.In},
	['Out_Quint'] = {Enum.EasingStyle.Quint, Enum.EasingDirection.Out},
	['In_Out_Quint'] = {Enum.EasingStyle.Quint, Enum.EasingDirection.InOut},
}
module.easingStyles.functions = {
	--Linear
	Linear = function(t, b, c, d)
		return c * t / d + b 
	end,

	--Quad
	In_Quad = function(t, b, c, d) 
		return c * math.pow(t / d, 2) + b 
	end,

	Out_Quad = function(t, b, c, d)
		t = t / d
		return -c * t * (t - 2) + b
	end,

	In_Out_Quad = function(t, b, c, d)
		t = t / d * 2
		if t < 1 then return c / 2 * math.pow(t, 2) + b end
		return -c / 2 * ((t - 1) * (t - 3) - 1) + b
	end,

	Out_In_Quad = function(t, b, c, d)
		if t < d / 2 then return module.easingStyles.types.outQuad(t * 2, b, c / 2, d) end
		return module.easingStyles.types.inQuad((t * 2) - d, b + c / 2, c / 2, d)
	end,

	--Cubic
	In_Cubic = function(t, b, c, d) 
		return c * math.pow(t / d, 3) + b 
	end,

	Out_Cubic = function(t, b, c, d) 
		return c * (math.pow(t / d - 1, 3) + 1) + b 
	end,

	In_Out_Cubic = function(t, b, c, d)
		t = t / d * 2
		if t < 1 then return c / 2 * t * t * t + b end
		t = t - 2
		return c / 2 * (t * t * t + 2) + b
	end,

	Out_In_Cubic = function(t, b, c, d)
		if t < d / 2 then return module.easingStyles.types.outCubic(t * 2, b, c / 2, d) end
		return module.easingStyles.types.inCubic((t * 2) - d, b + c / 2, c / 2, d)
	end,


	--Quart

	On_Quart = function(t, b, c, d) 
		return c * math.pow(t / d, 4) + b 
	end,

	Out_Quart = function(t, b, c, d) 
		return -c * (math.pow(t / d - 1, 4) - 1) + b 
	end,

	In_Out_Quart = function(t, b, c, d)
		t = t / d * 2
		if t < 1 then return c / 2 * math.pow(t, 4) + b end
		return -c / 2 * (math.pow(t - 2, 4) - 2) + b
	end,

	Out_In_Quart = function(t, b, c, d)
		if t < d / 2 then return module.easingStyles.types.outQuart(t * 2, b, c / 2, d) end
		return module.easingStyles.types.inQuart((t * 2) - d, b + c / 2, c / 2, d)
	end,

	--Quint

	In_Quint = function(t, b, c, d)
		return c * math.pow(t / d, 5) + b 
	end,

	Out_Quint = function(t, b, c, d) 
		return c * (math.pow(t / d - 1, 5) + 1) + b 
	end,

	In_Out_Quint = function(t, b, c, d)
		t = t / d * 2
		if t < 1 then return c / 2 * math.pow(t, 5) + b end
		return c / 2 * (math.pow(t - 2, 5) + 2) + b
	end,

	Out_In_Quint = function(t, b, c, d)
		if t < d / 2 then return module.easingStyles.types.outQuint(t * 2, b, c / 2, d) end
		return module.easingStyles.types.inQuint((t * 2) - d, b + c / 2, c / 2, d)
	end,

	--Sine

	In_Sine = function(t, b, c, d) 
		return -c * math.cos(t / d * (math.pi / 2)) + c + b 
	end,

	Out_Sine = function(t, b, c, d) 
		return c * math.sin(t / d * (math.pi / 2)) + b 
	end,

	In_Out_Sine = function(t, b, c, d) 
		return -c / 2 * (math.cos(math.pi * t / d) - 1) + b 
	end,

	Out_In_Sine = function(t, b, c, d)
		if t < d / 2 then return module.easingStyles.types.outSine(t * 2, b, c / 2, d) end
		return module.easingStyles.types.inSine((t * 2) -d, b + c / 2, c / 2, d)
	end,

	--Expo

	In_Expo = function(t, b, c, d)
		if t == 0 then return b end
		return c * math.pow(2, 10 * (t / d - 1)) + b - c * 0.001
	end,

	Out_Expo = function(t, b, c, d)
		if t == d then return b + c end
		return c * 1.001 * (-math.pow(2, -10 * t / d) + 1) + b
	end,

	In_Out_Expo = function(t, b, c, d)
		if t == 0 then return b end
		if t == d then return b + c end
		t = t / d * 2
		if t < 1 then return c / 2 * math.pow(2, 10 * (t - 1)) + b - c * 0.0005 end
		return c / 2 * 1.0005 * (-math.pow(2, -10 * (t - 1)) + 2) + b
	end,

	Out_In_Expo = function(t, b, c, d)
		if t < d / 2 then return module.easingStyles.types.outExpo(t * 2, b, c / 2, d) end
		return module.easingStyles.types.inExpo((t * 2) - d, b + c / 2, c / 2, d)
	end,

	--Circ

	In_Circ = function(t, b, c, d) 
		return(-c * (math.sqrt(1 - math.pow(t / d, 2)) - 1) + b) 
	end,

	Out_Circ = function(t, b, c, d)  
		return(c * math.sqrt(1 - math.pow(t / d - 1, 2)) + b) 
	end,

	In_Out_Circ = function(t, b, c, d)
		t = t / d * 2
		if t < 1 then return -c / 2 * (math.sqrt(1 - t * t) - 1) + b end
		t = t - 2
		return c / 2 * (math.sqrt(1 - t * t) + 1) + b
	end,

	Out_In_Circ = function(t, b, c, d)
		if t < d / 2 then return module.easingStyles.types.outCirc(t * 2, b, c / 2, d) end
		return module.easingStyles.types.inCirc((t * 2) - d, b + c / 2, c / 2, d)
	end,



	--Back
	Out_Back = function(t, b, c, d, s)
		s = s or 1.2
		t = t / d - 1
		return c * (t * t * ((s + 1) * t + s) + 1) + b
	end,

	In_Back = function(t, b, c, d, s)
		s = s or 1.70158
		t = t / d
		return c * t * t * ((s + 1) * t - s) + b
	end,

	In_Out_Back = function(t, b, c, d, s)
		s = (s or 1.70158) * 1.525
		t = t / d * 2
		if t < 1 then return c / 2 * (t * t * ((s + 1) * t - s)) + b end
		t = t - 2
		return c / 2 * (t * t * ((s + 1) * t + s) + 2) + b
	end,

	Out_In_Back = function(t, b, c, d, s)
		if t < d / 2 then return module.easingStyles.types.outBack(t * 2, b, c / 2, d, s) end
		return module.easingStyles.types.inBack((t * 2) - d, b + c / 2, c / 2, d, s)
	end,

	--bounce

	Out_Bounce = function(t, b, c, d)
		t = t / d
		if t < 1 / 2.75 then return c * (7.5625 * t * t) + b end
		if t < 2 / 2.75 then
			t = t - (1.5 / 2.75)
			return c * (7.5625 * t * t + 0.75) + b
		elseif t < 2.5 / 2.75 then
			t = t - (2.25 / 2.75)
			return c * (7.5625 * t * t + 0.9375) + b
		end
		t = t - (2.625 / 2.75)
		return c * (7.5625 * t * t + 0.984375) + b
	end,

	In_Bounce = function(t, b, c, d) 
		return c - module.easingStyles.types.outBounce(d - t, 0, c, d) + b 
	end,

	In_Out_Bounce = function(t, b, c, d)
		if t < d / 2 then return module.easingStyles.types.inBounce(t * 2, 0, c, d) * 0.5 + b end
		return module.easingStyles.types.outBounce(t * 2 - d, 0, c, d) * 0.5 + c * .5 + b
	end,

	Out_In_Bounce = function(t, b, c, d)
		if t < d / 2 then return module.easingStyles.types.outBounce(t * 2, b, c / 2, d) end
		return module.easingStyles.types.inBounce((t * 2) - d, b + c / 2, c / 2, d)
	end,
}

local function checkBreakStatements(statements)
	for i,v in pairs((statements and typeof(statements) == 'function') and statements() or {}) do
		if (v) then return true end
	end
	return false
end

local codeName = 'InterpolationCode'

local runningThreads = {}

local signal = require(script.Parent.Signal)

function module.interpolate(weld: Weld, c0: CFrame, easingStyle: any, duration: number, breakStatements: any)
	easingStyle = easingStyle or 'Linear'
	easingStyle = module.easingStyles.functions[easingStyle] or module.easingStyles.functions.Linear
	if (not runningThreads[weld]) then runningThreads[weld] = {} end
	for i, v in pairs(runningThreads[weld]) do
		v.event:Fire(false)
		v.event:Destroy()
		pcall(task.cancel, v.thread)
		runningThreads[weld][i] = nil
	end
	local event = signal.new()
	local thread = task.spawn(function()
		local startTime = os.clock()
		local startC0 = weld.C0
		local alpha = 0
		while (alpha < 1) do
			alpha = math.clamp(((os.clock()-startTime)/duration), 0, 1)
			weld.C0 = startC0:Lerp(c0, easingStyle(alpha, 0, 1, 1))
			if (checkBreakStatements(breakStatements)) then event:Fire(false) return end
			HEARTBEAT:Wait()
		end
		event:Fire(alpha >= 1)
	end)
	if (runningThreads[weld]) then
		table.insert(runningThreads[weld], { ['thread'] = thread, ['event'] = event})
	end
	return event:Wait()
end

return module