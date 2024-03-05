local player = game:GetService("Players").LocalPlayer
local char = player.Character
local hrp = char:WaitForChild("HumanoidRootPart")
local humanoid = char:WaitForChild("Humanoid")

local editing = player:WaitForChild("Editing")
local gyro = hrp:WaitForChild("FlyGyro")
local direction = hrp:WaitForChild("Direction")
local shieldPos = char:WaitForChild("ShieldPos")
local connector = shieldPos:WaitForChild("Connector")

-- services
local UIS = game:GetService("UserInputService")
local RS = game:GetService("RunService")
local TS = game:GetService("TweenService")
local context = game:GetService("ContextActionService")

local tweenInfo = TweenInfo.new(
	.2,
	Enum.EasingStyle.Linear,
	Enum.EasingDirection.Out,
	0,
	false
)

local shieldTween = nil

-- camera
local camera = game:GetService("Workspace").CurrentCamera
local mouse = player:GetMouse()
local cameraDB = false
local zoomDB = false

-- values
local xAngle = 0
local yAngle = 0

local ORIGINAL_POS = Vector3.new(2, 2, 17)
local ZOOM_POS = Vector3.new(2, 1, 10)

local cameraPosition = ORIGINAL_POS
local SHIELD_OFFSET = 8

local hold = false
local isFlying = false

camera.CameraType = Enum.CameraType.Scriptable

-- detect right click holding
UIS.InputBegan:Connect(function(inputObject)
	if inputObject.UserInputType == Enum.UserInputType.MouseButton2 then
		hold = true
	end
end)

UIS.InputEnded:Connect(function(inputObject)
	if inputObject.UserInputType == Enum.UserInputType.MouseButton2 then
		hold = false
	end
end)

-- change gyo if flying
local flying = player:WaitForChild("Flying")
flying.Changed:Connect(function()
	isFlying = flying.Value
	if isFlying then
		gyro.MaxTorque = Vector3.new(5000, 750, 5000)
	else
		gyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
	end
end)

context:BindAction("CameraMovement", function(_,_, input)
	xAngle = xAngle - input.Delta.x * 0.4
	yAngle = math.clamp(yAngle - input.Delta.y * 0.4, -80, 80)
end, false, Enum.UserInputType.MouseMovement)

local function tweenShieldPosition(goal)
	if shieldTween then
		shieldTween:Cancel()
	end
	shieldTween = TS:Create(connector, tweenInfo, {C1 = goal})
	if shieldTween then
		shieldTween:Play()
	end
end

RS.RenderStepped:Connect(function()
	if char and hrp and shieldPos and connector then
		-- camera follows player
		local startCFrame = CFrame.new((hrp.CFrame.p + Vector3.new(0,2,0))) * CFrame.Angles(0, math.rad(xAngle), 0) * CFrame.Angles(math.rad(yAngle), 0, 0)
		local cameraCFrame = startCFrame + startCFrame:VectorToWorldSpace(Vector3.new(cameraPosition.X, cameraPosition.Y, cameraPosition.Z))
		local cameraFocus = startCFrame + startCFrame:VectorToWorldSpace(Vector3.new(cameraPosition.X, cameraPosition.Y, -50000))
		camera.CFrame = CFrame.new(cameraCFrame.p, cameraFocus.p)
		
		-- if in settings menu
		if editing.Value == true then
			UIS.MouseBehavior = Enum.MouseBehavior.Default
			UIS.MouseIconEnabled = true
		else
			UIS.MouseBehavior = Enum.MouseBehavior.LockCenter
			UIS.MouseIconEnabled = false

			-- zoom in on holding right click
			if hold == true then
				cameraPosition = ZOOM_POS
			else
				cameraPosition = ORIGINAL_POS
			end
			
			-- UPDATE GYRO AND SHIELD POSITIONING BASED ON MOVEMENT
			-- only use y axis if flying
			if not isFlying then
				tweenShieldPosition(CFrame.new(connector.C1.Position, connector.C1.Position + Vector3.new(0, 0, -SHIELD_OFFSET)))
				--connector.C1 = CFrame.new(connector.C1.Position, connector.C1.Position + Vector3.new(0, 0, -8))
				gyro.CFrame = CFrame.new(hrp.Position, hrp.Position + Vector3.new(camera.CFrame.LookVector.X, 0, camera.CFrame.LookVector.Z))
			else
				-- if flying, determine the rotation
				if direction.Value == "Forward" then
					tweenShieldPosition(CFrame.new(connector.C1.Position, connector.C1.Position + Vector3.new(0, 0, -SHIELD_OFFSET)))
					--connector.C1 = CFrame.new(connector.C1.Position, connector.C1.Position + Vector3.new(0, 0, -8))
					gyro.CFrame = CFrame.new(hrp.Position, hrp.Position + Vector3.new(camera.CFrame.LookVector.X, camera.CFrame.LookVector.Y, camera.CFrame.LookVector.Z))
				elseif direction.Value == "Left" then
					tweenShieldPosition(CFrame.new(connector.C1.Position, connector.C1.Position + Vector3.new(0, 0, -SHIELD_OFFSET)) * CFrame.Angles(0, math.pi/2, 0))
					--connector.C1 = CFrame.new(connector.C1.Position, connector.C1.Position + Vector3.new(0, 0, -8)) * CFrame.Angles(0, math.pi/2, 0)
					gyro.CFrame = CFrame.lookAt(hrp.Position, mouse.Hit.Position) * CFrame.Angles(0, math.pi/2, 0)
				elseif direction.Value == "Right" then
					tweenShieldPosition(CFrame.new(connector.C1.Position, connector.C1.Position + Vector3.new(0, 0, -SHIELD_OFFSET)) * CFrame.Angles(0, -(math.pi/2), 0))
					--connector.C1 = CFrame.new(connector.C1.Position, connector.C1.Position + Vector3.new(0, 0, -8)) * CFrame.Angles(0, -(math.pi/2), 0)
					gyro.CFrame = CFrame.lookAt(hrp.Position, mouse.Hit.Position) * CFrame.Angles(0, -(math.pi/2), 0)
				elseif direction.Value == "Backward" then
					tweenShieldPosition(CFrame.new(connector.C1.Position, connector.C1.Position + Vector3.new(0, 0, -SHIELD_OFFSET)) * CFrame.Angles(0, math.pi, 0))
					--connector.C1 = CFrame.new(connector.C1.Position, connector.C1.Position + Vector3.new(0, 0, -8)) * CFrame.Angles(0, math.pi, 0)
					gyro.CFrame = CFrame.lookAt(hrp.Position, mouse.Hit.Position) * CFrame.Angles(0, math.pi, 0)
				elseif direction.Value == "ForwardLeft" then
					tweenShieldPosition(CFrame.new(connector.C1.Position, connector.C1.Position + Vector3.new(0, 0, -SHIELD_OFFSET)) * CFrame.Angles(0, math.pi/4, 0))
					--connector.C1 = CFrame.new(connector.C1.Position, connector.C1.Position + Vector3.new(0, 0, -8)) * CFrame.Angles(0, math.pi/4, 0)
					gyro.CFrame = CFrame.lookAt(hrp.Position, mouse.Hit.Position) * CFrame.Angles(0, math.pi/4, 0)
				elseif direction.Value == "ForwardRight" then
					tweenShieldPosition(CFrame.new(connector.C1.Position, connector.C1.Position + Vector3.new(0, 0, -SHIELD_OFFSET)) * CFrame.Angles(0, -(math.pi/4), 0))
					--connector.C1 = CFrame.new(connector.C1.Position, connector.C1.Position + Vector3.new(0, 0, -8)) * CFrame.Angles(0, -(math.pi/4), 0)
					gyro.CFrame = CFrame.lookAt(hrp.Position, mouse.Hit.Position) * CFrame.Angles(0, -(math.pi/4), 0)
				elseif direction.Value == "BackwardLeft" then
					tweenShieldPosition(CFrame.new(connector.C1.Position, connector.C1.Position + Vector3.new(0, 0, -SHIELD_OFFSET)) * CFrame.Angles(0, math.pi-(math.pi/4), 0))
					--connector.C1 = CFrame.new(connector.C1.Position, connector.C1.Position + Vector3.new(0, 0, -8)) * CFrame.Angles(0, math.pi-(math.pi/4), 0)
					gyro.CFrame = CFrame.lookAt(hrp.Position, mouse.Hit.Position) * CFrame.Angles(0, math.pi-(math.pi/4), 0)
				elseif direction.Value == "BackwardRight" then
					tweenShieldPosition(CFrame.new(connector.C1.Position, connector.C1.Position + Vector3.new(0, 0, -SHIELD_OFFSET)) * CFrame.Angles(0, math.pi+(math.pi/4), 0))
					--connector.C1 = CFrame.new(connector.C1.Position, connector.C1.Position + Vector3.new(0, 0, -8)) * CFrame.Angles(0, math.pi+(math.pi/4), 0)
					gyro.CFrame = CFrame.lookAt(hrp.Position, mouse.Hit.Position) * CFrame.Angles(0, math.pi+(math.pi/4), 0)
				else
					tweenShieldPosition(CFrame.new(connector.C1.Position, connector.C1.Position + Vector3.new(0, 0, -SHIELD_OFFSET)))
					gyro.CFrame = CFrame.new(hrp.Position, hrp.Position + Vector3.new(camera.CFrame.LookVector.X, camera.CFrame.LookVector.Y, camera.CFrame.LookVector.Z))
				end
			end
			task.wait()
		end
	end
end)