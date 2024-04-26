local voiceModule = {}
voiceModule.__index = voiceModule

function voiceModule.new(voiceSettings)
	local self = setmetatable(voiceModule, {})
	
	self.voiceSettings = voiceSettings
	
	return self
end

function voiceModule:PlayClip(voiceAudio, clip, pauseThread)
	
	if (not voiceAudio) then return warn('Cortex Voice voiceModule: No sound instance supplied!') end
	if (not clip) then return warn('Cortex Voice voiceModule: No voice clip supplied!') end
	
	local function run()
		voiceAudio.SoundId = clip.SoundId and `rbxassetid://{clip.SoundId}` or `rbxassetid://{self.voiceSettings.SoundId}`
		voiceAudio.Volume = clip.Volume and clip.Volume or self.voiceSettings.Volume
		voiceAudio.Pitch = clip.Pitch and clip.Pitch or self.voiceSettings.Pitch
		voiceAudio.TimePosition = clip.Start or 0
		voiceAudio:Play()
		local clipEnd = clip.End or voiceAudio.TimeLength
		while (voiceAudio.IsPlaying and voiceAudio.TimePosition < clipEnd) do game:GetService('RunService').Heartbeat:Wait() end
		voiceAudio:Stop()
		
	end
	
	if (pauseThread) then
		run()
	else
		task.spawn(run)
	end
	
end

return voiceModule