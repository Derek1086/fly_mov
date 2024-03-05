-- services
local RS = game:GetService("ReplicatedStorage")

-- events
local flyEvents = RS.FlyEvents
local attackEvents = RS.AttackEvents
local uiEvents = RS.UIEvents

local startFlying = flyEvents.StartFlying
local stopFlying = flyEvents.StopFlying
local takeDamage = attackEvents.TakeDamage
local killFeed = attackEvents.KillFeed
local updateLaser = uiEvents.UpdateLaser

local MAX_FORCE = 3000

game.Players.PlayerAdded:Connect(function(plr)
	-- create fly values
	local flyValue = Instance.new("BoolValue", plr)
	flyValue.Name = "Flying"
	
	local attacking = Instance.new("BoolValue", plr)
	attacking.Name = "Attacking"
	
	local editing = Instance.new("BoolValue", plr)
	editing.Name = "Editing"
	editing.Value = false
	
	local sprinting = Instance.new("BoolValue", plr)
	sprinting.Name = "Sprinting"
	
	local shielding = Instance.new("BoolValue", plr)
	shielding.Name = "Shielding"
	
	plr.CharacterAdded:Connect(function(char)
		updateLaser:FireClient(plr)
		
		-- reset values
		flyValue.Value = false
		attacking.Value = false
		sprinting.Value = false
		shielding.Value = false
		
		local hrp = char:WaitForChild("HumanoidRootPart")
		
		local killTag = Instance.new("StringValue", char)
		killTag.Name = "KillTag"
		killTag.Value = ""
		
		local gyro = Instance.new("BodyGyro", hrp)
		gyro.Name = "FlyGyro"
		gyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
		gyro.D = 100
		gyro.P = 10000
		
		local direction = Instance.new("StringValue", hrp)
		direction.Name = "Direction"
		direction.Value = "None"
		
		char.Humanoid.AutoRotate = false
	
		-- damage hud
		char.Humanoid.HealthChanged:Connect(function(newHealth)
			takeDamage:FireClient(plr, newHealth)
		end)
		
		local died
		died = char.Humanoid.Died:Connect(function()
			killFeed:FireAllClients(plr)
			local hrp = char:FindFirstChild("HumanoidRootPart")
			
			-- remove fly values
			if hrp then
				local flyVelocity = hrp:FindFirstChild("FlyVelocity")

				if flyVelocity then
					flyVelocity:Destroy()
				end

				local flyGyro = hrp:FindFirstChild("FlyGyro")
				if flyGyro then
					flyGyro:Destroy()
				end

				local direction = hrp:FindFirstChild("Direction")
				if direction then
					direction:Destroy()
				end

				for index,joint in pairs(char:GetDescendants()) do
					if joint:IsA("Motor6D") then
						local socket = Instance.new("BallSocketConstraint")
						local a1 = Instance.new("Attachment")
						local a2 = Instance.new("Attachment")
						a1.Parent = joint.Part0
						a2.Parent = joint.Part1
						socket.Parent = joint.Parent
						socket.Attachment0 = a1
						socket.Attachment1 = a2
						a1.CFrame = joint.C0
						a2.CFrame = joint.C1
						socket.LimitsEnabled = true
						socket.TwistLimitsEnabled = true
						joint:Destroy()
					end
				end
			end
		end)
	end)
end)

-- flying events
startFlying.OnServerEvent:Connect(function(plr)
	local flyValue = plr:FindFirstChild("Flying")
	if flyValue then
		local shieldPos = plr.Character:FindFirstChild("ShieldPos")
		if shieldPos then
			shieldPos.Connector.Part0 = plr.Character.PrimaryPart
		end
		
		plr.Flying.Value = true
		
		-- create fly velocity
		local flyVelocity = Instance.new("BodyVelocity", plr.Character.HumanoidRootPart)
		flyVelocity.Name = "FlyVelocity"
		flyVelocity.MaxForce = Vector3.new(MAX_FORCE, math.huge, MAX_FORCE)
		
		-- update direction
		local direction = plr.Character.HumanoidRootPart:FindFirstChild("Direction")
		if direction then
			direction.Value = ""
		end
		
		-- enable trails
		local windTrailRight = plr.Character.RightHand:FindFirstChild("WindTrail")
		local windTrailLeft = plr.Character.LeftHand:FindFirstChild("WindTrail")
		
		if windTrailRight and windTrailLeft then
			windTrailRight.Enabled = true
			windTrailLeft.Enabled = true
		end
	end
end)

stopFlying.OnServerEvent:Connect(function(plr)
	local flyValue = plr:FindFirstChild("Flying")
	if flyValue then
		local shieldPos = plr.Character:FindFirstChild("ShieldPos")
		if shieldPos then
			shieldPos.Connector.Part0 = plr.Character.Head
		end
		
		plr.Flying.Value = false
		
		-- destroy fly velocity
		local flyVelocity = plr.Character.HumanoidRootPart:FindFirstChild("FlyVelocity")
		if flyVelocity then
			flyVelocity:Destroy()
		end
		
		-- update direction
		local direction = plr.Character.HumanoidRootPart:FindFirstChild("Direction")
		if direction then
			direction.Value = "None"
		end
		
		-- disable trails
		local windTrailRight = plr.Character.RightHand:FindFirstChild("WindTrail")
		local windTrailLeft = plr.Character.LeftHand:FindFirstChild("WindTrail")

		if windTrailRight and windTrailLeft then
			windTrailRight.Enabled = false
			windTrailLeft.Enabled = false
		end
	end
end)

-- update color
local function updateLaserColor(plr, red, green, blue)
	local char = plr.Character
	local backpack = plr.Backpack
	local laserEyes = backpack.LaserEyes
	if laserEyes then
		local laserBeam = laserEyes.LaserBeam
		if red and green and blue then
			laserBeam.Color = ColorSequence.new(Color3.new(red, green, blue))
		end
	end
end

updateLaser.OnServerEvent:Connect(updateLaserColor)