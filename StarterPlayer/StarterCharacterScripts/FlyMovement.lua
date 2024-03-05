local player = game.Players.LocalPlayer
repeat wait() until player.Character
local char = player.Character
local hrp = char:WaitForChild("HumanoidRootPart")
local humanoid = char:WaitForChild("Humanoid")

local flying = player:FindFirstChild("Flying")
local editing = player:FindFirstChild("Editing")
local sprinting = player:FindFirstChild("Sprinting")
local direction = hrp:WaitForChild("Direction")

-- services
local UIS = game:GetService("UserInputService")
local RS = game:GetService("ReplicatedStorage")
local RUN = game:GetService("RunService")
local TS = game:GetService("TweenService")

-- events
local flyEvents = RS.FlyEvents
local startFlying = flyEvents.StartFlying
local stopFlying = flyEvents.StopFlying

local mouse = player:GetMouse()
local camera = game.Workspace.CurrentCamera

local hud = hrp:WaitForChild("HUD")
local sprint = hud.Sprint
local sprintBar = sprint.SprintBar
local gradient = sprintBar.UIGradient

-- values
local flyVelocity = nil
local MIN_SPEED = 0
local MAX_SPEED = 100
local SPEED = MAX_SPEED
local strafing = false

local canSprint = true
local SPRINT_DELAY = 5
local SPRINT_SPEED = MAX_SPEED * 4.5

-- tween info for sprint bar
local sprintInfo = TweenInfo.new(
	2,
	Enum.EasingStyle.Linear,
	Enum.EasingDirection.Out,
	0,
	false
)

local reloadSprintInfo = TweenInfo.new(
	SPRINT_DELAY,
	Enum.EasingStyle.Linear,
	Enum.EasingDirection.Out,
	0,
	false
)

local ORIGINAL_TRANS = .25
local NEW_TRANS = 1

local tween = TS:Create(gradient, sprintInfo, { Offset = Vector2.new(0, -1)})
local reloadTween = TS:Create(gradient, reloadSprintInfo, { Offset = Vector2.new(0, 0)})

local conn

local function canFly()
	return humanoid.Health > 0 and editing.Value == false
end

-- start flying
local function startFlight()
	flying.Value = true
	
	startFlying:FireServer()
	if flyVelocity == nil then
		flyVelocity = hrp:WaitForChild("FlyVelocity")
		flyVelocity.Velocity = mouse.Hit.LookVector * 0 -- hovering
	end
	
	if conn then conn:Disconnect() end
	conn = RUN.RenderStepped:Connect(function()
		-- movement keys
		UIS.InputBegan:Connect(function(input, process)
			if process then return end
			if flying.Value == true then
				if canFly() then
					if UIS:IsKeyDown(Enum.KeyCode.W) then
						direction.Value = "Forward"
					elseif UIS:IsKeyDown(Enum.KeyCode.A) then
						direction.Value = "Left"
					elseif UIS:IsKeyDown(Enum.KeyCode.D) then
						direction.Value = "Right"
					elseif UIS:IsKeyDown(Enum.KeyCode.S) then
						direction.Value = "Backward"
					end
					if UIS:IsKeyDown(Enum.KeyCode.W) and UIS:IsKeyDown(Enum.KeyCode.A) then
						direction.Value = "ForwardLeft"
						strafing = true
					elseif UIS:IsKeyDown(Enum.KeyCode.W) and UIS:IsKeyDown(Enum.KeyCode.D) then
						direction.Value = "ForwardRight"
						strafing = true
					elseif UIS:IsKeyDown(Enum.KeyCode.S) and UIS:IsKeyDown(Enum.KeyCode.A) then
						direction.Value = "BackwardLeft"
						strafing = true
					elseif UIS:IsKeyDown(Enum.KeyCode.S) and UIS:IsKeyDown(Enum.KeyCode.D) then
						direction.Value = "BackwardRight"
						strafing = true 
					elseif UIS:IsKeyDown(Enum.KeyCode.LeftShift) and canSprint and direction.Value ~= "" then
						sprinting.Value = true
					end
				end
			end
		end)
		UIS.InputEnded:Connect(function(input, process)
			if process then return end
			-- end movement
			if canFly() then
				if strafing then
					if direction.Value == "ForwardLeft" then
						if input.KeyCode == Enum.KeyCode.W then
							direction.Value = "Left"
						else
							direction.Value = "Forward"
						end
					end
					if direction.Value == "ForwardRight" then
						if input.KeyCode == Enum.KeyCode.W then
							direction.Value = "Right"
						else
							direction.Value = "Forward"
						end
					end
					if direction.Value == "BackwardLeft" then
						if input.KeyCode == Enum.KeyCode.S then
							direction.Value = "Left"
						else
							direction.Value = "Backward"
						end
					end
					if direction.Value == "BackwardRight" then
						if input.KeyCode == Enum.KeyCode.S then
							direction.Value = "Right"
						else
							direction.Value = "Backward"
						end
					end
					task.delay(.01, function()
						strafing = false
					end)
				else
					if input.KeyCode == Enum.KeyCode.W or input.KeyCode == Enum.KeyCode.S or input.KeyCode == Enum.KeyCode.A or input.KeyCode == Enum.KeyCode.D then
						direction.Value = ""
					end
				end
			end
		end)
		
		-- velocities based on movement
		if direction.Value ~= "" then
			if direction.Value == "Forward" then
				flyVelocity.Velocity = hrp.CFrame.LookVector * SPEED
			elseif direction.Value == "Left" then
				flyVelocity.Velocity = hrp.CFrame.LookVector * SPEED
			elseif direction.Value == "Right" then
				flyVelocity.Velocity = hrp.CFrame.LookVector * SPEED
			elseif direction.Value == "Backward" then
				flyVelocity.Velocity = hrp.CFrame.LookVector * SPEED
			elseif direction.Value == "ForwardLeft" then
				flyVelocity.Velocity = (hrp.CFrame.LookVector * (SPEED))
			elseif direction.Value == "ForwardRight" then
				flyVelocity.Velocity = (hrp.CFrame.LookVector * (SPEED))
			elseif direction.Value == "BackwardLeft" then
				flyVelocity.Velocity = (hrp.CFrame.LookVector * (SPEED))
			elseif direction.Value == "BackwardRight" then
				flyVelocity.Velocity = (hrp.CFrame.LookVector * (SPEED))
			end
		else
			flyVelocity.Velocity = mouse.Hit.LookVector * MIN_SPEED
		end
	end)
end

-- stop flying
local function endFlight()
	stopFlying:FireServer()
	flyVelocity = nil
	flying.Value = false
	if conn then
		conn:Disconnect()
	end
end

-- press f key to start/stop flying
UIS.InputBegan:Connect(function(input, process)
	if process then return end
	if input.KeyCode == Enum.KeyCode.Space then
		if canFly() then
			if flying.Value == false then
				startFlight()
			else
				endFlight()
			end
		end
	end 
end)

-- detect when sprinting
sprinting.Changed:Connect(function()
	if sprinting.Value == true then
		canSprint = false
		SPEED = SPRINT_SPEED
		tween:Play()
		tween.Completed:Connect(function()
			sprinting.Value = false
			SPEED = MAX_SPEED
			reloadTween:Play()
			-- after reloading, player can sprint again
			reloadTween.Completed:Connect(function()
				canSprint = true
			end)
		end)
	end
end)

-- prevent player from flying into floors
humanoid.StateChanged:Connect(function(oldState, newState)
	-- detect if landed, stop flying
	if newState == Enum.HumanoidStateType.Landed or newState == Enum.HumanoidStateType.GettingUp then
		if hrp then
			if flying.Value == true then
				endFlight()
			end
		end
		-- detect if falling down after landing, go back into flight
	elseif newState == Enum.HumanoidStateType.FallingDown then
		if hrp then
			if flying.Value == false and canFly() then
				task.wait(.05)
				startFlight()
			end
		end
	else
		--print(newState)
	end	
end)
