local player = game.Players.LocalPlayer

-- services
local RS = game:GetService("ReplicatedStorage")

local killFeedEvent = RS.AttackEvents.KillFeed
local template = RS.KillFeedItem
local playerTemplate = RS.KillFeedItemPlayer

local hud = script.Parent.Parent
local killFeedContainer = hud.KillFeed

local killFeedModule = require(hud.KillFeedModule)

local killFeed = killFeedModule:New(template, killFeedContainer)

-- create kill feed item from player
killFeedEvent.OnClientEvent:Connect(function(charKilled)
	if charKilled then
		-- grab character from player
		local charFromPlr = charKilled.Character
		if charFromPlr then
			local killer = charKilled.Character:FindFirstChild("KillTag") -- find killer tag
			if killer then
				local killFeedText = ""
				--if player died from another player
				if killer.Value ~= "" then
					killFeedText = killer.Value .. " killed " .. charKilled.DisplayName
					-- if player died from natural causes
				else	
					killFeedText = charKilled.DisplayName .. " died"
				end
				
				-- if killfeed involves player, change the color of killfeed
				if charKilled.DisplayName == player.DisplayName or killer.Value == player.DisplayName then
					killFeed = killFeedModule:UpdateTemplate(playerTemplate)
				else
					killFeed = killFeedModule:UpdateTemplate(template)
				end

				if killFeedText ~= "" then
					killFeed = killFeed + killFeedText
				end
			end
		end
	end
end)
