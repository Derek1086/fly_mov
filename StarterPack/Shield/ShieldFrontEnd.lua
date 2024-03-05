local player = game.Players.LocalPlayer
repeat wait() until player.Character
local char = player.Character
local hrp = char:WaitForChild("HumanoidRootPart")
local humanoid = char:WaitForChild("Humanoid")
local mouse = player:GetMouse()
local camera = workspace.CurrentCamera

-- services
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local RUN = game:GetService("RunService")
local TS = game:GetService("TweenService")

local hud = hrp:WaitForChild("HUD")
local shieldContainer = hud.Shield
local shieldBar = shieldContainer.ShieldBar
local gradient = shieldBar.UIGradient
local cooldown = shieldContainer.Cooldown

local MIN_DISTANCE = 30

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

local flying = player:FindFirstChild("Flying")
local editing = player:FindFirstChild("Editing")
local shielding = player:FindFirstChild("Shielding")

local activate = RS.AttackEvents.ActivateShield
local deactivate = RS.AttackEvents.DeactivateShield
local fire = RS.AttackEvents.DeployShield
local updateReload = script.Parent.UpdateReload

-- values
local MAX_USAGE_TIME = 10
local timeUsed = 0
local debounce = false
local conn = nil
local tween = nil
local reloadTween = nil
local reloading = false
local KEYCODE = Enum.KeyCode.E

local function canShield()
	return humanoid.Health > 0 and not reloading and editing.Value == false
end

local function deactivateShield()
	if conn then 
		conn:Disconnect()
	end
	deactivate:FireServer()
	
	-- detect if was shielding  when they stopped
	if tween then
		tween:Pause()
	end
	
	reloading = true
	updateReload:FireServer(true)
	
	local tweenInfoReload = TweenInfo.new(
		timeUsed,
		Enum.EasingStyle.Linear,
		Enum.EasingDirection.In,
		0,
		false
	)
	reloadTween = TS:Create(gradient, tweenInfoReload, { Offset = Vector2.new(0, 0)})
	reloadTween:Play()
	reloadTween.Completed:Connect(function()
		if reloadTween.PlaybackState == Enum.PlaybackState.Completed then
			timeUsed = 0
			reloading = false
			updateReload:FireServer(false)
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

local function activateShield()
	activate:FireServer(mouse.Hit.Position)
	
	if shielding.Value == false then
		repeat wait() until shielding.Value == true
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
			updateReload:FireServer(true)
			deactivateShield()
		end
	end)
	
	conn = RUN.RenderStepped:Connect(function(dt)
		if shielding.Value == true and UIS:IsKeyDown(KEYCODE) and canShield() then
			local DTick = tick()
			if DTick - startTick < MAX_USAGE_TIME then
				timeUsed = DTick - startTick
				if not debounce then
					debounce = true
					-- raycast
					local mouse = UIS:GetMouseLocation()
					local length = MIN_DISTANCE
					local unitray = camera:ViewportPointToRay(mouse.X, mouse.Y)
					if flying.Value == true then
						fire:FireServer(length, unitray, camera.CFrame.Position, true)
					else
						local head = char.Head
						fire:FireServer(length, head.CFrame.LookVector, head.CFrame.Position, false)
					end
					task.wait(math.min(3 * dt, .2))
					debounce = false
				end
			elseif DTick - startTick >= MAX_USAGE_TIME then -- went over max usage time so remove lasers
				deactivateShield()
			end
		else
			deactivateShield()
		end	
	end)
end

-- detect player inputs
UIS.InputBegan:Connect(function(input, process)
	if process then return end
	if canShield() then
		if UIS:IsKeyDown(KEYCODE)  then 
			if shielding.Value == false and canShield() and not reloading then
				activateShield()
			end
		end
	end
end)

UIS.InputEnded:Connect(function(input, process)
	if process then return end
	if input.KeyCode == KEYCODE then
		if shielding.Value == true and conn then
			deactivateShield()
		end
	end
end)