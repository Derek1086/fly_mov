local player = game.Players.LocalPlayer
repeat wait() until player.Character
local char = player.Character
local humanoid = char:FindFirstChild("Humanoid")

local mouse = player:GetMouse()
local editing = player:FindFirstChild("Editing")

local hud = script.Parent
local topBar = hud.TopBar
local settingsButton = topBar.Settings
local controls = hud.Controls
local damageHud = hud.Damage
local crosshair = hud.CrossHair

local killEffect = hud.KillEffect
local smiley = killEffect.Smiley
local frowney = killEffect.Frowney

local newSmiley = nil
local newFrowney = nil

local DELAY_TIME = 2
local editingBool = false
local ORIGINAL_TRANS = .15
local NEW_TRANS = .3

crosshair.Visible = true

settingsButton.BackgroundColor3 = Color3.fromRGB(31, 31, 31)
settingsButton.BackgroundTransparency = ORIGINAL_TRANS

-- services
local UIS = game:GetService("UserInputService")
local RS = game:GetService("ReplicatedStorage")
local TS = game:GetService("TweenService")

local tweenInfo = TweenInfo.new(
	.5,
	Enum.EasingStyle.Quad,
	Enum.EasingDirection.In,
	0,
	false
)

local deleteInfo = TweenInfo.new(
	DELAY_TIME,
	Enum.EasingStyle.Quad,
	Enum.EasingDirection.In,
	0,
	false
)

local tweenSize = nil
local tweenRotate = nil
local tweenTrans = nil 

local killedPlayer = RS.AttackEvents.KilledPlayer
local takeDamage = RS.AttackEvents.TakeDamage

-- update ui
local function updateSettingsUI()
	editing.Value = editingBool
	controls.Visible = editingBool
	if editingBool then
		settingsButton.BackgroundTransparency = NEW_TRANS
	else
		settingsButton.BackgroundTransparency = ORIGINAL_TRANS
	end
end

-- press p 
UIS.InputEnded:Connect(function(input, process)
	if process then return end
	if input.KeyCode == Enum.KeyCode.P then
		editingBool = not editingBool
	end
	updateSettingsUI()
end)

-- click on button
settingsButton.MouseButton1Up:Connect(function()
	editingBool = not editingBool
	updateSettingsUI()
end)

settingsButton.MouseEnter:Connect(function()
	settingsButton.BackgroundTransparency = ORIGINAL_TRANS
end)

settingsButton.MouseLeave:Connect(function()
	settingsButton.BackgroundTransparency = NEW_TRANS
end)

local function tweenImage(image)
	if image then
		image.Visible = true
		
		-- increase size, rotate, and fade out
		tweenSize = TS:Create(image, tweenInfo, { Size = UDim2.new(1, 0, 1, 0)})
		tweenRotate = TS:Create(image, tweenInfo, { Rotation = 360})
		tweenTrans = TS:Create(image, deleteInfo, { ImageTransparency = 1})
		if tweenSize and tweenRotate and tweenTrans then
			tweenSize:Play()
			tweenRotate:Play()
			tweenTrans:Play()
			tweenTrans.Completed:Connect(function()
				if image then
					image:Destroy()
				end
			end)
		end
	end
end

local function checkIfExist(image)
	if image then
		image:Destroy()
	end
end

-- kill effect
killedPlayer.OnClientEvent:Connect(function(enemy)
	if enemy then
		if enemy.Name then
			checkIfExist(newSmiley)
			newSmiley = smiley:Clone()
			newSmiley.Parent = killEffect
			
			tweenImage(newSmiley)
		end
	end
end)



local function onDeath()
	-- if recently killed player
	checkIfExist(newSmiley)
	checkIfExist(newFrowney)
	newFrowney = frowney:Clone()
	newFrowney.Parent = killEffect

	tweenImage(newFrowney)
end

-- damage effect
local currentHealth = humanoid.Health
local damageTween = nil
takeDamage.OnClientEvent:Connect(function(newHealth)
	if newHealth <= 0 then -- died
		if damageTween then
			damageTween:Cancel()
		end
		damageTween = TS:Create(damageHud, tweenInfo, {ImageTransparency = 0})
		if damageTween then
			damageTween:Play()
		end
		onDeath()
		-- remove damage hud on respawn
		task.delay(3, function()
			damageHud.ImageTransparency = 1
			damageTween = nil
		end)
	elseif newHealth < currentHealth then -- took damage
		local updatedTrans = (humanoid.Health / humanoid.MaxHealth) - .2
		if updatedTrans <= 0.09 then
			updatedTrans = 0
		end
		if damageTween then
			damageTween:Cancel()
		end
		damageTween = TS:Create(damageHud, tweenInfo, {ImageTransparency = updatedTrans})
		if damageTween then
			damageTween:Play()
		end
	else -- healing
		if newHealth >= humanoid.MaxHealth then -- fully healed
			if damageTween then
				damageTween:Cancel()
			end
			damageTween = TS:Create(damageHud, tweenInfo, {ImageTransparency = 1})
			if damageTween then
				damageTween:Play()
			end
		end
		currentHealth = newHealth --update current health
	end
end)

