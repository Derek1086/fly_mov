local player = game.Players.LocalPlayer
repeat wait() until player.Character
local char = player.Character
local hrp = char:WaitForChild("HumanoidRootPart")
local humanoid = char:WaitForChild("Humanoid")

-- services
local TS = game:GetService("TweenService")

local tweenInfo = TweenInfo.new(
	.1,
	Enum.EasingStyle.Linear,
	Enum.EasingDirection.In,
	0,
	false
)

local cooldownInfo = TweenInfo.new(
	.5,
	Enum.EasingStyle.Linear,
	Enum.EasingDirection.Out,
	0,
	false
)

local ORIGINAL_TRANS = .25
local NEW_TRANS = 1

local hud = hrp:WaitForChild("HUD")
local healthContainer = hud.Health
local healthBar = healthContainer.HealthBar
local gradient = healthBar.UIGradient
local cooldown = healthContainer.Cooldown

hud.Enabled = true

local cooldownTweenGlow = TS:Create(cooldown, cooldownInfo, { ImageTransparency = ORIGINAL_TRANS})
local cooldownTweenDissipate = TS:Create(cooldown, cooldownInfo, { ImageTransparency = NEW_TRANS})

local function disableCooldown()
	if cooldownTweenGlow and cooldownTweenDissipate then
		cooldown.ImageTransparency = NEW_TRANS
		cooldownTweenGlow:Cancel()
		cooldownTweenDissipate:Cancel()
	end
end

-- animate health bar
humanoid:GetPropertyChangedSignal("Health"):Connect(function()
	local newPos = -(1 - (humanoid.Health / humanoid.MaxHealth))
	local tween = TS:Create(gradient, tweenInfo, { Offset = Vector2.new(0, newPos) })

	if tween then
		tween:Play()
	end
	
	while humanoid.Health <= 20 do
		wait()
		if humanoid.Health <= 0 then
			disableCooldown()
			hud.Enabled = false
			return
		end
		cooldownTweenGlow:Play()
		cooldownTweenGlow.Completed:Wait()
		cooldownTweenDissipate:Play()
		cooldownTweenDissipate.Completed:Wait()
	end
end)
