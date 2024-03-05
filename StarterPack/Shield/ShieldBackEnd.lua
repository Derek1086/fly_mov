-- services
local RS = game:GetService("ReplicatedStorage")

-- events
local activate = RS.AttackEvents.ActivateShield
local deactivate = RS.AttackEvents.DeactivateShield
local fire = RS.AttackEvents.DeployShield
local updateReload = script.Parent.UpdateReload

local RayParams = RaycastParams.new()
RayParams.FilterType = Enum.RaycastFilterType.Exclude

local debounce = false

local shield = game.ServerStorage.Shield
local reloadVal = script.Parent.Reloading
local playerShield = nil

local function deactivatePlrShield(plr)
	local shielding = plr:FindFirstChild("Shielding")
	shielding.Value = false
	
	-- destroy shield
	if playerShield then
		playerShield:Destroy()
		playerShield = nil
	end
end

-- weird bug to prevent shield from respawning after being removed
updateReload.OnServerEvent:Connect(function(plr, value) 
	reloadVal.Value = value
end)

activate.OnServerEvent:Connect(function(plr, mouseHit)
	local char = plr.Character
	local humanoid = char:FindFirstChildWhichIsA("Humanoid")
	local hrp = char:FindFirstChild("HumanoidRootPart")
	local flying = plr:FindFirstChild("Flying")
	local shieldPos = char:FindFirstChild("ShieldPos")

	local shielding = plr:FindFirstChild("Shielding")
	shielding.Value = true

	RayParams.FilterDescendantsInstances = {char, shieldPos, game.Workspace.MapBorder:GetChildren()}

	-- deploy the shield
	fire.OnServerEvent:Connect(function(player, length, unitray, camPosition, unitRayBool)
		if not debounce then
			debounce = true
			local origin = camPosition
			local unitDirection
			
			if unitRayBool then -- using mouse position
				unitDirection = unitray.Direction * length
			else -- if not in the air
				unitDirection = unitray * length
			end
			
			local result = workspace:Raycast(origin, unitDirection, RayParams)		
			local interscection = result and result.Position or origin + unitDirection
			local distance = (origin - interscection).Magnitude
			local oppositeCF = (CFrame.lookAt(interscection, origin) * CFrame.new(0, 0, distance)).Position

			spawn(function()		
				-- if hit something, dont spawn shield
				if result and result.Instance and result.Instance.Name ~= "Shield" and result.Instance.Name ~= "killp" then
					--print(result.Instance.Name)
					deactivatePlrShield(player)
				else -- spawn shield
					if playerShield == nil and reloadVal.Value == false then
						playerShield = shield:Clone()
						if shieldPos and playerShield then
							playerShield.Parent = hrp
							playerShield.PrimaryPart.CFrame = shieldPos.CFrame
							local weld = playerShield.PrimaryPart.WeldConstraint
							if weld then
								weld.Part1 = shieldPos
							end
						end
					end
				end
			end)
			debounce = false
		end
	end)
end)

deactivate.OnServerEvent:Connect(deactivatePlrShield)