-- SilentsReplacement
-- MultiToolEquip
-- July 26, 2021

--[[
    MultiToolEquip.Enabled : boolean
    
	MultiToolEquip.Init() --> nil []
    MultiToolEquip.Start(playerProfile : PlayerProfile) --> nil []
    MultiToolEquip.Cleanup() --> nil []
	MultiToolEquip.CleanupForPlayer() --> nil []
]]

local MultiToolEquip = {
	Enabled = true,
}

local Octagon = script:FindFirstAncestor("Octagon")
local Util = require(Octagon.Shared.Util)
local Signal = require(Octagon.Shared.Signal)
local Maid = require(Octagon.Shared.Maid)
local InitMaidFor = require(Octagon.Shared.InitMaidFor)
local DestroyAllMaids = require(Octagon.Shared.DestroyAllMaids)

local LocalConstants = { MaxEquippedToolCount = 1 }

MultiToolEquip._onPlayerDetection = Signal.new()
MultiToolEquip._maid = Maid.new()

local playerEquippedTools = {}

function MultiToolEquip.Init()
	MultiToolEquip._initSignals()

	return nil
end

function MultiToolEquip.Start(playerProfile)
	local player = playerProfile.Player
	playerEquippedTools[player] = playerEquippedTools[player]
		or {
			Count = 0,
			Tools = {},
			OnToolEnequip = Signal.new(),
		}

	local childAddedConnection = player.Character.ChildAdded:Connect(function(tool)
		if not tool:IsA("BackpackItem") then
			return
		end

		local playerEquippedToolsData = playerEquippedTools[player]

		playerEquippedToolsData.Tools[tool] = tool
		playerEquippedToolsData.Count += 1

		if playerEquippedToolsData.Count > LocalConstants.MaxEquippedToolCount then
			MultiToolEquip._onPlayerDetection:Fire(playerProfile)
		end
	end)

	local childRemovedConnection = player.Character.ChildRemoved:Connect(function(tool)
		if not tool:IsA("BackpackItem") then
			return
		end
		local playerEquippedToolsData = playerEquippedTools[player]

		playerEquippedToolsData.Tools[tool] = nil
		playerEquippedToolsData.Count -= 1
		playerEquippedToolsData.OnToolEnequip:DeferredFire()
	end)

	playerProfile.DetectionMaid:AddTask(childAddedConnection)
	playerProfile.DetectionMaid:AddTask(childRemovedConnection)
	MultiToolEquip._maid:AddTask(childRemovedConnection)
	MultiToolEquip._maid:AddTask(childAddedConnection)

	-- Handle case where the player has already equipped more tools before the above
	-- events ran:
	do
		local equippedTools, equippedToolsCount = Util.GetPlayerEquippedTools(player)
		local playerEquippedToolsData = playerEquippedTools[player]

		playerEquippedToolsData.Count = equippedToolsCount
		playerEquippedToolsData.Tools = equippedTools

		if playerEquippedToolsData.Count > LocalConstants.MaxEquippedToolCount then
			MultiToolEquip._onPlayerDetection:Fire(playerProfile)
		end
	end

	return nil
end

function MultiToolEquip.Cleanup()
	DestroyAllMaids(MultiToolEquip)
	playerEquippedTools = {}

	return nil
end

function MultiToolEquip.CleanupForPlayer(player)
	playerEquippedTools[player] = nil

	return nil
end

function MultiToolEquip._initSignals()
	InitMaidFor(MultiToolEquip, MultiToolEquip._maid, Signal.IsSignal)

	MultiToolEquip._onPlayerDetection:Connect(function(playerProfile)
		local player = playerProfile.Player
		local playerEquippedToolsData = playerEquippedTools[player]

		-- Parent tools equipped to the player's backpack
		-- until the amount of tools the player has equipped is <=
		-- LocalConstants.MaxEquippedToolCount, effectively preventing
		-- multiple tools being equipped:
		for _, tool in pairs(playerEquippedToolsData.Tools) do
			if playerEquippedToolsData.Count == LocalConstants.MaxEquippedToolCount then
				break
			end

			-- Parent the tool back to the backpack;
			task.wait()
			tool.Parent = player.Backpack
 
			if playerEquippedToolsData.Tools[tool] ~= nil then
				playerEquippedToolsData.OnToolEnequip:Wait()
			end
		end
	end)

	return nil
end

return MultiToolEquip
