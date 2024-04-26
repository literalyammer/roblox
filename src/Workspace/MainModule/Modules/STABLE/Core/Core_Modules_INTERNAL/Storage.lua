local storage = {}
local mainStorage = {}

function storage:INITIATE_PLUGIN_INTERNAL(CORE, SOURCE)
	--INDICATOR THAT THE PLUGIN IS READY TO INITIATE

	function storage:save(branch, key, value, options: {OVERWRITE: boolean | 'Overwrite existing content if keys are the same?'}, callback: any) --Saves the given data to the key in the given branch key name. Function: Master.(branch?).(key?) : {?} -> saved = Master -> branch -> key : {content}
		options = typeof(options) == 'table' and options or {OVERWRITE=true}
		local keyData = mainStorage[branch]
		if (not keyData) then mainStorage[branch] = {} end
		if (((not options.OVERWRITE) and (not mainStorage[branch][key])) or options.OVERWRITE) then
			mainStorage[branch][key] = value
			--warn(`Saved data under branch {branch} in key {key}`)
			if (typeof(callback) == 'function') then
				callback({BRANCH=branch,KEY=key,CONTENT=value})
			end
			return value
		end
		if (typeof(callback) == 'function') then
			callback({BRANCH=branch,KEY=key,CONTENT='NONE'})
		end
		return
	end
	function storage:get(branch, key) --Returns the stored data content using both the given branch & sub-branch key. Format: Master -> branch -> key : {content}
		local keyData = mainStorage[branch]
		if (not keyData) then return end
		return keyData[key]
	end
	function storage:getContentInBranch(branch) --Returns stored data content using the given branch key. Format: Master -> branch : {content}
		--storage.ContentLoaded:Fire({BRANCH=branch,KEY=nil,CONTENT=mainStorage[branch]})
		return mainStorage[branch]
	end
	return true
end

return storage