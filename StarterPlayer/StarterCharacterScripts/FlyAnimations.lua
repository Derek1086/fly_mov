local player = game.Players.LocalPlayer
repeat wait() until player.Character
local char = player.Character
local hrp = char:WaitForChild("HumanoidRootPart")
local humanoid = char:WaitForChild("Humanoid")

local animator = humanoid:WaitForChild("Animator")

-- hover
local hoverAnim = Instance.new("Animation")
hoverAnim.AnimationId = "rbxassetid://10444036921" 
local hoverAnimtrack
if hoverAnim then
	hoverAnimtrack = animator:LoadAnimation(hoverAnim)
end

-- fly
local flyAnim = Instance.new("Animation")
flyAnim.AnimationId = "rbxassetid://10444117580" 
local flyAnimTrack
if flyAnim then
	flyAnimTrack = animator:LoadAnimation(flyAnim)
end

-- values
local flying = player:WaitForChild("Flying")
local direction = hrp:WaitForChild("Direction")

-- update animation based on direction
direction.Changed:Connect(function()
	if humanoid.Health > 0 then
		if flying.Value == true then
			if direction.Value == "" then
				if flyAnimTrack then
					flyAnimTrack:Stop()
				end
				if hoverAnimtrack then
					hoverAnimtrack:Play()
				end
			else
				if hoverAnimtrack then
					hoverAnimtrack:Stop()
				end
				if flyAnimTrack then
					flyAnimTrack:Play()
				end
			end

		else
			if hoverAnimtrack then
				hoverAnimtrack:Stop()
			end
			if flyAnimTrack then
				flyAnimTrack:Stop()
			end
		end
	end
end)
