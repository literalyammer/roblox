return function(loader, whitelist, config)
	wait(4)
	local guardModel = loader.Parent
	local npc = loader.Parent:WaitForChild('Security Guard')
	local backup = npc:Clone()
	local root = npc.HumanoidRootPart
	local hum = npc.Humanoid
	local pathService = game:GetService("PathfindingService")	
	local handcuffs = script:WaitForChild("handcuffs"):Clone()
	handcuffs.Parent = game.ReplicatedStorage
	handcuffs.weld.Disabled = false
	local taser = script:WaitForChild("taser"):Clone()
	taser.Parent = game.ReplicatedStorage
	taser.Handle.Anchored = false
	local start = root.Position
	local currentlyArresting
	local isOpeningDoor = false
	local chasing = false
	local delta = 0
	local goingBack = false
	local path = pathService:CreatePath()
	
	
	local whitelist,config = require(whitelist),require(guardModel:FindFirstChild('Config'))
	if not config then return assert(false, 'Security Guard AI: Config module not found') end
	if not whitelist then return assert(false, 'Security Guard AI: Whitelist module not found') end
	local webhookModule = require(script.webhookModule)

	local violators,isViolatorEscorted = {},{}
	
	local api = guardModel:FindFirstChild('API') or Instance.new('BindableEvent', guardModel)
	api.Name = 'API'
	api.Event:Connect(function(protocol, params)

		if (protocol == 'addUsersToViolators') then
			for i,v in pairs(params) do
				local pl = game.Players:GetPlayerFromCharacter(v)
				if ((not pl) or whitelist[tostring(pl.UserId)]) then return end
				if (not violators[pl.UserId]) then
					violators[pl.UserId] = {v, pl}
				end
			end
		end

	end)

	local isChasing = false
	local escorting = false

	local collisions = guardModel.Collisions

	local setNetworkOwner = function(target, owner)
		for i,v in pairs(target:GetDescendants()) do
			if v:IsA("BasePart") then
				local anchor = v.Anchored
				v.Anchored = false
				pcall(function()
					v:SetNetworkOwner(owner)
				end)
				v.Anchored = anchor
			end
		end
	end

	root.Anchored = true

	workspace.ChildAdded:Connect(function(c)
		local pl = game.Players:GetPlayerFromCharacter(c)
		if pl then
			local plrGui = pl:WaitForChild('PlayerGui')
			local bind = script.bindControls:Clone()
			bind.Parent = plrGui
		end
	end)

	for i,pl in pairs(game.Players:GetChildren()) do
		local plrGui = pl:WaitForChild('PlayerGui')
		local bind = script.bindControls:Clone()
		bind.Parent = plrGui
	end

	local bv,bg
	local doors = {}

	local plrRoot,plrHum,plr,char
	local pathfind

	local checkDist = function(target)
		return (root.Position-target.Position).Magnitude
	end

	local toVector2 = function(inputPos)
		return Vector2.new(inputPos.X, inputPos.Z)
	end

	local goBack = function()
		warn(config.guardName..': Something went wrong, going back...', debug.traceback())
		hum:UnequipTools()
		isOpeningDoor = false
		escorting = false
		plrRoot = nil
		chasing = false
		goingBack = true
		pcall(function()
			violators[plr.UserId] = nil
		end)
		plr = nil
		pathfind(root.Position, start)
		isChasing = false
		goingBack = false
	end
	
	function checkSight(target)
		local ray = Ray.new(root.Position,(target.Position - root.Position).Unit * 75)
		local hit,position = workspace:FindPartOnRayWithIgnoreList(ray,{script.Parent})
		if hit then
			if hit:IsDescendantOf(target.Parent) then
				return true
			end
		end
		return false
	end

	pathfind = function(from, to)
		api:Fire('Path_Point_Fire')
		path:ComputeAsync(from, to)
		for i,v in pairs(npc:GetDescendants()) do
			if v:IsA('BasePart') then
				v.Anchored = false
			end
		end
		setNetworkOwner(npc, nil)
		print(config.guardName, path.Status)
		if path.Status == Enum.PathStatus.Success then
			local waypoints = path:GetWaypoints()
			for i=1,#waypoints do
				if (chasing and not goingBack) and ((not plr) or (not plr.Character) or (not plrHum:IsDescendantOf(workspace))) then
					return goBack()
				end
				local point = waypoints[i]
				local pointPos = point.Position
				hum:MoveTo(pointPos)
				if point.Action == Enum.PathWaypointAction.Jump or hum.Sit then
					hum.JumpPower = 50
					hum.Jump = true
				end
				hum.MoveToFinished:Wait()
				if (chasing and not goingBack) and ((not plr) or (not plr.Character) or (not plrHum:IsDescendantOf(workspace))) then
					return goBack()
				end
				if (chasing) then
					if i % 5 == 0 or (plrRoot.Position - waypoints[#waypoints].Position).Magnitude > 15 then
						break 
					end
				end
				if point.Action == Enum.PathWaypointAction.Jump or hum.Sit then
					hum.JumpPower = 50
					hum.Jump = true
				end
			end
		else
			hum:MoveTo(root.Position+Vector3.new(math.random(-30,30), 0, math.random(-30,30)))
			hum.MoveToFinished:Wait()
		end
	end

	hum:GetPropertyChangedSignal('Sit'):Connect(function()
		wait()
		if hum.Sit then
			hum.JumpPower = 50
			hum.Jump = true
		end
	end)

	hum.Died:Connect(function()
		wait(5)
		pcall(function()
			if config.webhookData.sendWebhookDataEnabled.guardDeath.enable then
				webhookModule.sendMsg(config.guardName, '', config.webhookData.profileIcon, {{
					["author"] = {
						["name"] = config.guardName,
						["icon_url"] = config.webhookData.authorIcon
					},
					["description"] = 'Guard died. Respawning...',
					["type"] = "rich",
					["color"] = config.webhookData.sendWebhookDataEnabled.guardDeath.color,
					["image"] = {
						["url"] = config.webhookData.imageUrl
					}
				}}, config.webhookData.webhookUrl)
			end
		end)
		backup.Parent = npc.Parent
		pcall(function()
			handcuffs.Parent = script
		end)
		npc:Destroy()
		local cl = script.reset:Clone()
		cl.Parent = loader
		isChasing = false
		escorting = false
		pcall(function()
			if bv and bg then
				bv:Destroy()
				bg:Destroy()
			end
		end)
		cl.Disabled = false
	end)

	local escortPlayer = function(v, hit)
		--local ran, message = pcall(function()
		plr = game.Players:GetPlayerFromCharacter(hit.Parent)
		if (not isChasing) and plr then
			isChasing = true
			chasing = true
			local val = Instance.new('BoolValue', plr.Character)
			val.Name = 'isChased'
			val.Value = true
			warn(config.guardName..': Now chasing player '..plr.Name..'!')
			currentlyArresting = plr
			char = plr.Character
			plrRoot = char.HumanoidRootPart
			plrHum = char.Humanoid
			if config.tasePlayer then
				hum:EquipTool(taser)
			else
				hum:EquipTool(handcuffs)
			end
			hum.WalkSpeed = 35
			if (not isChasing) or (not plr) or (not plr.Character) or (not plrHum:IsDescendantOf(workspace)) then
				return goBack()
			end
			pathfind(root.Position, plrRoot.Position)
			if (not isChasing) or (not plr) or (not plr.Character) or (not plrHum:IsDescendantOf(workspace)) then
				return goBack()
			end
			if config.tasePlayer then
				taser.Handle.Anchored = false
				hum:EquipTool(taser)
				spawn(function()
					for i=1,15 do
						wait()
						hum.PlatformStand = false
						hum:ChangeState(Enum.HumanoidStateType.RunningNoPhysics)
					end
				end)
				local at1,at2 = Instance.new('Attachment', taser.Handle),Instance.new('Attachment', plrRoot)
				local rod = Instance.new('RopeConstraint', taser.Handle)
				rod.Name = 'taserRod'
				rod.Color = BrickColor.new('Mid gray')
				rod.Attachment0,rod.Attachment1 = at1,at2
				rod.Length = rod.CurrentDistance
				rod.Visible = true
				rod.Thickness = .08
				game:GetService("Debris"):AddItem(at1, 2)
				game:GetService("Debris"):AddItem(at2, 2)
				game:GetService("Debris"):AddItem(rod, 2)
				taser.Handle.Deploy:Play()
				plrHum.PlatformStand = true
				local lastSpeed,lastJp = plrHum.WalkSpeed,plrHum.JumpPower
				plrHum.WalkSpeed = 0
				plrHum.JumpPower = 50
				delay(taser.Handle.Deploy.TimeLength, function()
					if (not isChasing) or (not plr) or (not plr.Character) or (not plrHum:IsDescendantOf(workspace)) then
						return goBack()
					end
					pathfind(root.Position, plrRoot.Position, false)
					plrHum.PlatformStand = false
					plrHum.WalkSpeed = lastSpeed
					plrHum.JumpPower = lastJp
				end)
				pcall(function()
					hum:EquipTool(handcuffs)
				end)
				wait(4)
				if (not isChasing) or (not plr) or (not plr.Character) or (not plrHum:IsDescendantOf(workspace)) then
					return goBack()
				end
				local ff = plr.Character:FindFirstChildWhichIsA('ForceField')
				if ff then
					ff:Destroy()
				end
			end
			while (root.Position-plrRoot.Position).Magnitude >= 12 do
				pathfind(root.Position, plrRoot.Position, false)
				if (not isChasing) or (not plr) or (not plr.Character) or (not plrHum:IsDescendantOf(workspace)) then
					return goBack()
				end
				game:GetService("RunService").Heartbeat:Wait()
			end
			chasing = false
			if (not isChasing) or (not plr) or (not plr.Character) or (not plrHum:IsDescendantOf(workspace)) then
				return goBack()
			end
			pcall(function()
				local noReset = script.noReset:Clone()
				noReset.Parent = plr.PlayerGui
				game:GetService("Debris"):AddItem(noReset, .1)
			end)
			if (not isChasing) or (not plr) or (not plr.Character) or (not plrHum:IsDescendantOf(workspace)) then
				return goBack()
			end
			local anim
			if plrHum.RigType == Enum.HumanoidRigType.R15 then
				anim = plrHum:LoadAnimation(script.arrest_R15)
			elseif plrHum.RigType == Enum.HumanoidRigType.R6 then
				anim = plrHum:LoadAnimation(script.arrest_R6)
			end
			anim:Play()
			handcuffs.Handle.Click:Play()
			warn(config.guardName..': Cuffed '..plr.Name..', escorting...')
			delay(handcuffs.Handle.Click.TimeLength, function()
				hum:UnequipTools()
			end)
			pcall(function()
				if config.webhookData.sendWebhookDataEnabled.arrestPlayer.enable then
					webhookModule.sendMsg(config.guardName, '', config.webhookData.profileIcon, {{
						["author"] = {
							["name"] = config.guardName,
							["icon_url"] = config.webhookData.authorIcon
						},
						["description"] = "User "..plr.Name.." has been arrested and escorted out of the building.",
						["type"] = "rich",
						["color"] = config.webhookData.sendWebhookDataEnabled.arrestPlayer.color,
						["image"] = {
							["url"] = config.webhookData.imageUrl
						}
					}}, config.webhookData.webhookUrl)
				end
			end)
			spawn(function()
				while not escorting do
					if (not isChasing) or (not plr) or (not plr.Character) or (not plrHum:IsDescendantOf(workspace)) then
						return goBack()
					end
					plrHum.WalkSpeed = 0
					plrHum.JumpPower = 0
					game:GetService("RunService").Heartbeat:Wait()
				end
				while escorting do
					if (not isChasing) or (not plr) or (not plr.Character) or (not plrHum:IsDescendantOf(workspace)) then
						return goBack()
					end
					plrHum.WalkSpeed = 0
					plrHum.JumpPower = 0
					game:GetService("RunService").Heartbeat:Wait()
				end
			end)
			wait(2)
			if (not isChasing) or (not plr) or (not plr.Character) or (not plrHum:IsDescendantOf(workspace)) then
				return goBack()
			end
			hum.WalkSpeed = 18
			bv = Instance.new("BodyVelocity", plrRoot)
			bv.MaxForce = Vector3.new(100000, 0, 100000)
			bv.Velocity = Vector3.new(0, 0, 0)
			bg = Instance.new("BodyGyro", plrRoot.Parent:FindFirstChild('LowerTorso') or plrRoot.Parent:FindFirstChild('Torso'))
			bg.MaxTorque = Vector3.new(0, 100000, 0)
			bg.CFrame = plrRoot.CFrame
			bg.D = 100
			if config.forceCameraTowardsGuard then
				pcall(function()
					local client = script.forceCamera:Clone()
					client.guard.Value = npc
					client.Parent = plr.PlayerGui
				end)
			end
			wait(1)
			if (not isChasing) or (not plr) or (not plr.Character) or (not plrHum:IsDescendantOf(workspace)) then
				return goBack()
			end
			escorting = true
			isViolatorEscorted[plr.UserId] = plr.UserId
			-- dooropenlock
			--for i,l in pairs(workspace.Doors:GetChildren()) do
			--	if l.Name =="PeponDoorsV2" then
			--		l.securityguardopen:Fire()
			--	end
			--end
			-- dooropenlock end
			spawn(function()
				pathfind(root.Position, guardModel.escortPos.Position, false)
				wait(1)
				escorting = false
			end)
			while escorting do
				wait()
				if (not isChasing) or (not plr) or (not plr.Character) or (not plrHum:IsDescendantOf(workspace)) then
					return goBack()
				end
				bv.Velocity = -(plrRoot.Position-(root.Position-(root.CFrame.LookVector*4)))*3
				bg.CFrame = CFrame.new(plrRoot.Position, (root.Position-(root.CFrame.LookVector*4)))
			end
			if (not isChasing) or (not plr) or (not plr.Character) or (not plrHum:IsDescendantOf(workspace)) then
				return goBack()
			end
			pcall(function()
				val:Destroy()
				bv:Destroy()
				bg:Destroy()
			end)
			pcall(function()
				if plr.PlayerGui:FindFirstChild('forceCamera') then
					plr.PlayerGui.forceCamera.guard.Value = nil
					plr.PlayerGui.forceCamera:Destroy()
				end
			end)
			pcall(function()
				if config.webhookData.sendWebhookDataEnabled.playerRelease.enable then
					webhookModule.sendMsg(config.guardName, '', config.webhookData.profileIcon, {{
						["author"] = {
							["name"] = config.guardName,
							["icon_url"] = config.webhookData.authorIcon
						},
						["description"] = "User "..plr.Name.." has been released.",
						["type"] = "rich",
						["color"] = config.webhookData.sendWebhookDataEnabled.playerRelease.color,
						["image"] = {
							["url"] = config.webhookData.imageUrl
						}
					}}, config.webhookData.webhookUrl)
				end
			end)
			wait(2)
			if (not isChasing) or (not plr) or (not plr.Character) or (not plrHum:IsDescendantOf(workspace)) then
				return goBack()
			end
			hum:UnequipTools()
			anim:Stop()
			delay(.1, function()
				plrHum.JumpPower = 50
				plrHum.WalkSpeed = 16
			end)
			isViolatorEscorted[plr.UserId] = nil
			api:Fire('userReleased', plr)
			-- dooropenlock
			--for i,l in pairs(workspace.Doors:GetChildren()) do
			--	if l.Name =="PeponDoorsV2" then
			--		l.securityguardopen:Fire()
			--	end
			--end
			-- dooropenlock end
			wait(1)
			pathfind(root.Position, start, hum)
			wait(.5)
			root.Anchored = true
			isChasing = false
			chasing = false
			violators[plr.UserId] = nil
		end
		--end)
		--return ran, message
	end
	
	game.Players.PlayerRemoving:Connect(function(plr)
		
		wait()
		if ((not violators[plr.UserId]) or currentlyArresting ~= plr) then return end
		api:Fire('userReleased', plr)
		
	end)

	local run = function(v, hit)
		--local ran, message = escortPlayer(v, hit)
		--return assert(ran, message)
		local pl = game.Players:GetPlayerFromCharacter(hit.Parent)
		if pl then
			if hit then
				escortPlayer(v, hit)
			end
		end
	end

	for i,v in pairs(collisions:GetChildren()) do
		v.Touched:Connect(function(hit)
			local pl = game.Players:GetPlayerFromCharacter(hit.Parent)
			if pl and whitelist[tostring(pl.UserId)] then return end
			pcall(function()
				if not isViolatorEscorted[pl.UserId] and not pl.Character:FindFirstChild('isChased') then
					pl.Character:MoveTo(v.tpPos.Position)
				end
			end)
			if pl and not violators[pl.UserId] then
				violators[pl.UserId] = {v, hit, pl}
			end
		end)
	end

	spawn(function()
		while wait() do
			for i,v in pairs(violators) do
				--pcall(function()
				run(v[1], v[2])
				--end)
			end
		end
	end)
end