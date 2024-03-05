local debounce = false
local RESPAWN_TIME = 30
local pack = script.Parent

local TS = game:GetService("TweenService")

local tweenInfo = TweenInfo.new(
	2,
	Enum.EasingStyle.Linear,
	Enum.EasingDirection.Out,
	0,
	false
)

local moveTweenUp = TS:Create(pack, tweenInfo, { Position = pack.Position + Vector3.new(0, 2, 0)})
local moveTweenDown = TS:Create(pack, tweenInfo, { Position = pack.Position - Vector3.new(0, 2, 0)})

-- animate pack
local function animatePart()
	while pack and pack.Transparency == 0 do
		wait()
		moveTweenUp:Play()
		moveTweenUp.Completed:Wait()
		moveTweenDown:Play()
		moveTweenDown.Completed:Wait()
	end
end

-- detect player touch
function onTouch(part)
	if not part.Name:match("Shield")  then
		local humanoid = part.Parent:findFirstChild("Humanoid")
		-- detect if touched by player
		if humanoid and humanoid.Health < humanoid.MaxHealth then
			if not debounce then
				debounce = true
				pack.Transparency = 1
				humanoid.Health = humanoid.MaxHealth

				-- respawn after touched
				task.delay(RESPAWN_TIME, function()
					debounce = false
					pack.Transparency = 0
					animatePart()
				end)
			end
		end
	end
end

pack.Touched:connect(onTouch)

animatePart()


