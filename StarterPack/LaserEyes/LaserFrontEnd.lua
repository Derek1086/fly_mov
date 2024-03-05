local player = game.Players.LocalPlayer
repeat wait() until player.Character
local char = player.Character
local hrp = char:WaitForChild("HumanoidRootPart")
local humanoid = char:WaitForChild("Humanoid")
local mouse = player:GetMouse()
local camera = workspace.CurrentCamera

local flying = player:FindFirstChild("Flying")
local editing = player:FindFirstChild("Editing")
local shielding = player:FindFirstChild("Shielding")
local direction = hrp:WaitForChild("Direction")

-- services
local UIS = game:GetService("UserInputService")
local RS = game:GetService("ReplicatedStorage")
local RUN = game:GetService("RunService")
local TS = game:GetService("TweenService")

local hud = hrp:WaitForChild("HUD")
local laserContainer = hud.Laser
local laserBar = laserContainer.LaserBar
local gradient = laserBar.UIGradient
local cooldown = laserContainer.Cooldown

local cooldownInfo = TweenInfo.new(
	.5,
	Enum.EasingStyle.Linear,
	Enum.EasingDirection.Out,
	0,
	false
)

local ORIGINAL_TRANS = .25
local NEW_TRANS = 1

local cooldownTweenGlow = TS:Create(cooldown, cooldownInfo, { ImageTransparency = ORIGINAL_TRANS})
local cooldownTweenDissipate = TS:Create(cooldown, cooldownInfo, { ImageTransparency = NEW_TRANS})

local attacking = player:FindFirstChild("Attacking")
local direction = hrp:FindFirstChild("Direction")

local activate = RS.AttackEvents.ActivateLaser
local deactivate = RS.AttackEvents.DeactivateLaser
local fire = RS.AttackEvents.FireLasers
local indicateDamage = RS.AttackEvents.DamageIndicator

-- values
local MAX_USAGE_TIME = 5
local DESPAWN_TIME = 1.5
local timeUsed = 0
local debounce = false
local conn = nil
local tween = nil
local reloadTween = nil
local reloading = false
local KEYCODE = Enum.KeyCode.Q

local function canAttack()
	return humanoid.Health > 0 and not reloading and editing.Value == false and shielding.Value == false and not UIS:IsKeyDown(Enum.KeyCode.E)
end

-- laser functions
local function DeactivateLaser()
	if conn then 
		conn:Disconnect()
	end
	deactivate:FireServer()
	
	-- detect if was lasering when they stopped
	if tween then
		tween:Pause()
	end
	
	reloading = true
	
	local tweenInfoReload = TweenInfo.new(
		timeUsed,
		Enum.EasingStyle.Linear,
		Enum.EasingDirection.In,
		0,
		false
	)
	
	deactivate:FireServer()
	reloadTween = TS:Create(gradient, tweenInfoReload, { Offset = Vector2.new(0, 0)})
	reloadTween:Play()
	reloadTween.Completed:Connect(function()
		if reloadTween.PlaybackState == Enum.PlaybackState.Completed then
			timeUsed = 0
			reloading = false
			deactivate:FireServer()
		end
	end)
	
	-- animate cooldown bar
	while reloadTween.PlaybackState ~= Enum.PlaybackState.Completed and timeUsed > MAX_USAGE_TIME - .1 do
		wait()
		cooldownTweenGlow:Play()
		cooldownTweenGlow.Completed:Wait()
		cooldownTweenDissipate:Play()
		cooldownTweenDissipate.Completed:Wait()
	end
	if cooldownTweenGlow and cooldownTweenDissipate then
		cooldown.ImageTransparency = NEW_TRANS
		cooldownTweenGlow:Cancel()
		cooldownTweenDissipate:Cancel()
	end
end

local function ActivateLaser()
	activate:FireServer(mouse.Hit.Position)
	
	if attacking.Value == false then
		repeat wait() until attacking.Value == true
	end
	
	local startTick = tick() -- start counter
	
	-- cancel reload tween
	if reloadTween then
		reloadTween:Pause()
	end
	
	local tweenInfo = TweenInfo.new(
		MAX_USAGE_TIME - timeUsed,
		Enum.EasingStyle.Linear,
		Enum.EasingDirection.In,
		0,
		false
	)

	-- animate laser bar
	tween = TS:Create(gradient, tweenInfo, { Offset = Vector2.new(0, 1)})
	tween:Play()
	tween.Completed:Connect(function()
		if tween.PlaybackState == Enum.PlaybackState.Completed then
			reloading = true
			DeactivateLaser()
		end
	end)
	
	conn = RUN.RenderStepped:Connect(function(dt)
		local dir = direction.Value
		if attacking.Value == true and UIS:IsKeyDown(KEYCODE) and not dir:match("Backward") and canAttack() then
			local DTick = tick()
			if DTick - startTick < MAX_USAGE_TIME then
				timeUsed = DTick - startTick

				if not debounce then
					debounce = true
					-- raycast
					local mouse = UIS:GetMouseLocation()
					local length = 500			
					local unitray = camera:ViewportPointToRay(mouse.X, mouse.Y)
					fire:FireServer(length, unitray, camera.CFrame.Position)
					task.wait(math.min(3 * dt, .2))
					debounce = false
				end
			elseif DTick - startTick >= MAX_USAGE_TIME then -- went over max usage time so remove lasers
				DeactivateLaser()
			end
		else
			DeactivateLaser()
		end	
	end)
end

-- damage indicator
indicateDamage.OnClientEvent:Connect(function(damage, hitHumanoid)
	local totalDamage = damage
	local damageIndicator = hitHumanoid.Parent:FindFirstChild("DamageIndicator")
	
	-- if indicator already exist, update the text to total damage
	if damageIndicator then
		local gui = damageIndicator.UI
		if gui then
			local damageText = gui.DamageText
			local currDamage = tonumber(damageText.Text)
			totalDamage += currDamage
			damageIndicator:Destroy()
		end
	end
	
	damageIndicator = game.ReplicatedStorage.DamageIndicator:Clone()
	if damageIndicator then
		damageIndicator.Parent = hitHumanoid.Parent
		local head = hitHumanoid.Parent.Head
		if head then
			damageIndicator.Position = head.Position + Vector3.new(math.random(0, 2), 4, math.random(0, 2))
			local gui = damageIndicator.UI
			if gui then
				local damageText = gui.DamageText
				damageText.Text = totalDamage
			end
		end
	end

	-- remove damage indicator
	task.delay(DESPAWN_TIME, function()
		if damageIndicator then
			damageIndicator:Destroy()
		end
	end)
end)

-- detect player inputs
UIS.InputBegan:Connect(function(input, process)
	if process then return end
	if canAttack() then
		local dir = direction.Value
		if UIS:IsKeyDown(KEYCODE) and not dir:match("Backward") then -- make sure player isnt facing backwards
			if attacking.Value == false and canAttack() and not reloading then
				ActivateLaser()
			end
		end
	end
end)

UIS.InputEnded:Connect(function(input, process)
	if process then return end
	if input.KeyCode == KEYCODE then
		if attacking.Value == true and conn then
			DeactivateLaser()
		end
	end
end)

