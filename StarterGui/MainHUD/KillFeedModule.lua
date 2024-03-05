local killFeedModule = {}

killFeedModule.__index = killFeedModule

killFeedModule.Entries = {}
killFeedModule.MaxEntries = 5
killFeedModule.Lifetime = 10

local newKillFeed

function killFeedModule:New(template, parent)
	newKillFeed = setmetatable({}, self)
	newKillFeed.__index = newKillFeed
	newKillFeed.Template = template
	newKillFeed.Parent = parent
	
	return newKillFeed
end

function killFeedModule:UpdateTemplate(template)
	if newKillFeed then
		newKillFeed.Template = template
	end
	return newKillFeed
end

-- add killfeed item
function killFeedModule.__add(addingKillFeed, value)
	addingKillFeed:CreateEntry(value)
	addingKillFeed:Cycle()
	
	return addingKillFeed
end

-- set entry to killfeed item
function killFeedModule:CreateEntry(str)
	local entry = self.Template:Clone()
	entry.Text = str
	entry.Parent = self.Parent
	entry.Visible = true
	
	-- index of 1
	table.insert(self.Entries, 1, entry)
	
	task.delay(self.Lifetime, function()
		-- remove killfeed item after lifetime
		if entry then
			entry:Destroy()
		end
	end)
end

-- cycle through and remove entry if past max entries
function killFeedModule:Cycle()
	for i, entry in pairs(self.Entries) do
		entry.LayoutOrder = i
		
		if i > self.MaxEntries then
			entry:Destroy()
		end
	end
end

return killFeedModule
