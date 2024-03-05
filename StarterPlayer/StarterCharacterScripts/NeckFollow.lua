local player = game.Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local humanoid = char:WaitForChild("Humanoid")
local hrp = char:WaitForChild("HumanoidRootPart")
local head = char:WaitForChild("Head")
local neck = head:WaitForChild("Neck")
local torso = char:WaitForChild("UpperTorso")
local waist = torso:WaitForChild("Waist")

local neckOriginC0 = neck.C0
local waistOriginC0 = waist.C0

local mouse = player:GetMouse()

-- services
local RS = game:GetService("RunService")

local editing = player:FindFirstChild("Editing")

local cam = workspace.CurrentCamera

neck.MaxVelocity = 1/3

RS.RenderStepped:Connect(function() 
	local camCFrame = cam.CoordinateFrame
	
	if editing then
		if editing.Value == false then
			if torso and head then
				local torsoLookVector = torso.CFrame.lookVector
				local headPosition = head.CFrame.p

				if neck and waist then
					local point = mouse.Hit.p

					local dist = (head.CFrame.p - point).magnitude
					local diff = head.CFrame.Y - point.Y
					neck.C0 = neck.C0:lerp(neckOriginC0 * CFrame.Angles(-(math.atan(diff / dist) * 0.5), (((headPosition - point).Unit):Cross(torsoLookVector)).Y * 1, 0), 0.5 / 2)
					waist.C0 = waist.C0:lerp(waistOriginC0 * CFrame.Angles(-(math.atan(diff / dist) * 0.5), (((headPosition - point).Unit):Cross(torsoLookVector)).Y * 0.5, 0), 0.5 / 2)
				end
			end	
		end
	end
end)