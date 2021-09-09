-- SilentsReplacement
-- MultiToolEquip
-- July 26, 2021

--[[
    MultiToolEquip.Enabled : boolean
    
    MultiToolEquip.Start(playerProfile : PlayerProfile) --> nil []
    MultiToolEquip.Cleanup() --> nil []
	MultiToolEquip.Init() --> nil []
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

local playerEquippedTools = {}

function MultiToolEquip.Start(playerProfile)
	local player = playerProfile.Player
	playerEquippedTools[player] = playerEquippedTools[player]
		or {
			Count = 0,
			Tools = {},
			LastTool = nil,
		}

	local childAddedConnection = player.Character.ChildAdded:Connect(function(tool)
		if not tool:IsA("BackpackItem") then
			return
		end

		local playerEquippedToolsData = playerEquippedTools[player]

		playerEquippedToolsData.Tools[tool] = tool
		playerEquippedToolsData.Count += 1
		playerEquippedToolsData.LastTool = playerEquippedToolsData.LastTool or tool

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

		if playerEquippedToolsData.LastTool == tool then
			playerEquippedToolsData.LastTool = nil
		end
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

function MultiToolEquip.Init()
	MultiToolEquip._initSignals()

	return nil
end

function MultiToolEquip._initSignals()
	MultiToolEquip._onPlayerDetection = Signal.new()
	MultiToolEquip._maid = Maid.new()

	InitMaidFor(MultiToolEquip, MultiToolEquip._maid, Signal.IsSignal)

	MultiToolEquip._onPlayerDetection:Connect(function(playerProfile)
		local player = playerProfile.Player
		local playerEquippedToolsData = playerEquippedTools[player]
		local lastEquippedTool = playerEquippedToolsData.LastTool

		-- Parent all equipped tools back to the player's backpack:
		for _, tool in pairs(playerEquippedToolsData.Tools) do
			-- Handle edge case where the tool is immediately destroyed after being parented:
			if tool.Parent == player.Character then
				task.defer(function()
					tool.Parent = player.Backpack
				end)
			end
		end

		-- Finally equip the last tool equipped if not destroyed / already equipped:
		if lastEquippedTool ~= nil and lastEquippedTool.Parent == player.Backpack then
			lastEquippedTool.Parent = player.Character
		end
	end)

	return nil
end

return MultiToolEquip
