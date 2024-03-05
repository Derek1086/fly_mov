-- services
local RS = game:GetService("ReplicatedStorage")
local DB = game:GetService("Debris")

-- events
local activate = RS.AttackEvents.ActivateLaser
local deactivate = RS.AttackEvents.DeactivateLaser
local fire = RS.AttackEvents.FireLasers
local damageIndicator = RS.AttackEvents.DamageIndicator
local killedPlayer = RS.AttackEvents.KilledPlayer

-- values
local DAMAGE = 4
local DESPAWN_TIME = 5
local debounce = false
local connecting = false
local endPointSpawned = false
local attacheSpawned = false
local reflecting = false

local RayParams = RaycastParams.new()
RayParams.FilterType = Enum.RaycastFilterType.Exclude

local endPoint = game.ServerStorage.EndPoint
local attache = game.ServerStorage.attache

-- create laser beam
local function MakeLaserBeams(att1, att2, plr)
	for i = 1, 2 do
		local laserbeam = script.Parent.LaserBeam:Clone()	
		local owner = laserbeam.Owner
		owner.Value = plr.Name
		laserbeam.Name = "LaserBeam" .. plr.Name	
		laserbeam.Enabled = true	
		laserbeam.Attachment0 = att1
		laserbeam.Attachment1 = att2
		laserbeam.Parent = game.Workspace
	end
end

-- create attachments
--local function MakeAttachments(addToTable, boolvalue, mouseHit, attacheBox)
--	local atts = {}
--	for i = 1, 2 do
--		local att = Instance.new("Attachment")		
--		att.Parent = attacheBox
--		--if boolvalue then
--		--	att.Position = mouseHit
--		--end
--		table.insert(atts, att)
--		table.insert(addToTable, att)	
--	end

--	return atts
--end

local offset1 = CFrame.new(.25, .25, 0)	
local offset2 = CFrame.new(-.25, .25, 0)

--local function ChangeCFrameTables(getTable, newCFrame)
--	if getTable ~= nil then
--		for i, v in ipairs(getTable) do
--			local FindOffset = i == 1 and offset1 or i == 2 and offset2
--			v.CFrame = newCFrame * FindOffset
--		end
--	end
--end

local function ClearAllTables(getTable, plr)
	if getTable ~= nil then
		for i,v in pairs(getTable) do
			v:Destroy()
		end
		table.clear(getTable)
	end
	-- remove lasers
	for _, lasers in pairs(game.Workspace:GetChildren()) do
		if lasers:IsA("Beam") and lasers.Name == "LaserBeam" .. plr.Name then
			DB:AddItem(lasers)
		end
	end
end

-- update endpoint to follow player and match surface
local function updateEndPoint(point, result, hrp)
	if point and result and hrp then
		local lookAtCFrame = CFrame.new(result.Position, result.Position + result.Normal + Vector3.new(0.1, 0.1, 0.1))
		point.CFrame = lookAtCFrame
	end
end

-- only fire killed once and not multiple times if they are dead
local function killedEnemy(player, humanoid)
	local enemy = humanoid.Parent
	if enemy then
		if not enemy:FindFirstChild("Dead") then
			local dead = Instance.new("BoolValue", enemy)
			dead.Name = "Dead"
			killedPlayer:FireClient(player, enemy)
			
			-- comment out later, prints out if kill enemy
			local killTag = enemy:FindFirstChild("KillTag")
			if killTag then
				killTag.Value = player.DisplayName
			end
		end
	end
end

local effectTable = {}	

local endPointPart = nil
local attachePart = nil

activate.OnServerEvent:Connect(function(plr, mouseHit)
	local char = plr.Character
	local humanoid = char:FindFirstChildWhichIsA("Humanoid")
	local hrp = char:FindFirstChild("HumanoidRootPart")
	local head = char:FindFirstChild("Head")	
	local shieldPos = char:FindFirstChild("ShieldPos")
	
	local attacking = plr:FindFirstChild("Attacking")
	attacking.Value = true
	
	RayParams.FilterDescendantsInstances = {char, shieldPos, game.Workspace.MapBorder:GetChildren(), attachePart} -- prevent laser from injuring the player itself
	
	local leftEye = head.LeftEye
	local rightEye = head.RightEye
	
	-- fire the lasers
	fire.OnServerEvent:Connect(function(player, length, unitray, camPosition)
		if not debounce then
			debounce = true
			local origin = camPosition			
			local unitDirection = unitray.Direction * length
			local result = workspace:Raycast(origin, unitDirection, RayParams)		
			local interscection = result and result.Position or origin + unitDirection
			local distance = (origin - interscection).Magnitude
			local oppositeCF = (CFrame.lookAt(interscection, origin) * CFrame.new(0, 0, distance)).Position
			
			if connecting then				
				if not endPointSpawned then
					endPointSpawned = true
					endPointPart = endPoint:Clone()
					if endPointPart then
						endPointPart.Parent = game.Workspace
					end
				end
				if endPointPart ~= nil and result and result.Position then
					updateEndPoint(endPointPart, result, player.Character:FindFirstChild("HumanoidRootPart"))
				end
			else
				-- remove endpoint if created
				if endPointSpawned and endPoint then
					DB:AddItem(endPointPart, DESPAWN_TIME)
				end
				endPointSpawned = false
				endPointPart = nil
			end
			
			spawn(function()		
				-- if hit something
				if result and result.Instance then
					--print(result.Instance.Name)
					if not attacheSpawned then
						attacheSpawned = true
						attachePart = attache:Clone()
						attachePart.Name = "attache" .. player.Name
						if attachePart then
							attachePart.Parent = player.Character
							-- create attachments for lasers
							--local getAttachmentsOdd = MakeAttachments(effectTable, false, mouseHit, attachePart)	
							--local getAttachmentsEven = MakeAttachments(effectTable, true, mouseHit, attachePart)	
							MakeLaserBeams(rightEye, attachePart.Attachment, player)	
							MakeLaserBeams(leftEye, attachePart.Attachment, player)	
							table.insert(effectTable, attachePart.Attachment)
							--ChangeCFrameTables(attachePart, CFrame.lookAt(origin, interscection))	
							--ChangeCFrameTables(attachePart, CFrame.lookAt(interscection, oppositeCF))
						end
					end
					
					if attachePart ~= nil then
						attachePart.Position = result.Position
					end
					
					
					local findInstance = result.Instance
					if findInstance.Parent then
						-- another player
						local isModel = (findInstance.Parent:IsA("Model") or findInstance:IsA("Model"))
						local hitHumanoid = (isModel and findInstance.Parent:FindFirstChildWhichIsA("Humanoid")) or findInstance.Parent.Parent:FindFirstChildWhichIsA("Humanoid")
						
						-- hit shield 
						if result.Instance.Name:match("Shield") then
							--print("hitting shield")
							reflecting = true
							connecting = false
						-- hit actual player and not shield
						elseif hitHumanoid and not result.Instance.Name:match("Shield") then -- ensure not shooting shield
							reflecting = false
							connecting = false
							
							-- if enemy still alive
							if hitHumanoid.Health > 0 then
								local totalDamage = math.floor(DAMAGE)
								hitHumanoid:TakeDamage(totalDamage)
								damageIndicator:FireClient(player, totalDamage, hitHumanoid)
							end
							
							-- detect if killed player
							if hitHumanoid.Health <= 0 then
								killedEnemy(player, hitHumanoid)
								-- slice off part if dead
								for _, child in pairs(findInstance:GetChildren()) do
									if child:IsA("Motor6D") then
										child:Destroy()
									end
								end
							end
						else
							reflecting = false
							connecting = true
						end		
					end
				else
					connecting = false
				end
			end)
			debounce = false
		end
	end)
end)

deactivate.OnServerEvent:Connect(function(plr)
	local attacking = plr:FindFirstChild("Attacking")
	attacking.Value = false
	
	for _, children in pairs(plr.Character:GetChildren()) do
		if children.Name:match("attache" .. plr.Name) then
			children.Parent = nil
			children:Destroy()
		end
	end
	
	ClearAllTables(effectTable, plr)
	
	-- remove endpoint if created
	if endPointSpawned and endPointPart then
		DB:AddItem(endPointPart, DESPAWN_TIME)
	end
	endPointPart = nil
	endPointSpawned = false
	
	if attacheSpawned and attachePart then
		attachePart.Parent = nil
		DB:AddItem(attachePart)
		attachePart = nil
	end
	attachePart = nil
	attacheSpawned = false
end)

