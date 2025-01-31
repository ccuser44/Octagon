-- SilentsReplacement
-- PrimaryPartDeletion
-- July 26, 2021

--[[
    PrimaryPartDeletion.Enabled : boolean

    PrimaryPartDeletion.Start(playerProfile : PlayerProfile) --> nil []
    PrimaryPartDeletion.Cleanup() --> nil []
	PrimaryPartDeletion.Init() --> nil []
]]

local PrimaryPartDeletion = {
	Enabled = true,
}

local CollectionService = game:GetService("CollectionService")

local Octagon = script:FindFirstAncestor("Octagon")
local SharedConstants = require(Octagon.Shared.SharedConstants)
local Util = require(Octagon.Shared.Util)
local PlayerUtil = require(Octagon.Shared.Util.PlayerUtil)
local Signal = require(Octagon.Shared.Signal)
local Maid = require(Octagon.Shared.Maid)
local InitMaidFor = require(Octagon.Shared.InitMaidFor)
local DestroyAllMaids = require(Octagon.Shared.DestroyAllMaids)

function PrimaryPartDeletion.Start(playerProfile)
	local player = playerProfile.Player
	local primaryPartParentChangedConnection = nil
	primaryPartParentChangedConnection = player.Character.PrimaryPart.ChildRemoved:Connect(
		function() end
	)

	local childRemovingConnection = player.Character.ChildRemoved:Connect(function(child)
		task.defer(function()
			if
				not CollectionService:HasTag(child, SharedConstants.Tags.PrimaryPart)
				or not primaryPartParentChangedConnection.Connected
				or Util.HasBasePartFallenToVoid(child)
			then
				return
			end

			PrimaryPartDeletion._onPlayerDetection:Fire(playerProfile)
		end)
	end)

	PrimaryPartDeletion._maid:AddTask(childRemovingConnection)
	PrimaryPartDeletion._maid:AddTask(primaryPartParentChangedConnection)
	playerProfile.DetectionMaid:AddTask(childRemovingConnection)
	playerProfile.DetectionMaid:AddTask(primaryPartParentChangedConnection)

	return nil
end

function PrimaryPartDeletion.Cleanup()
	DestroyAllMaids(PrimaryPartDeletion)

	return nil
end

function PrimaryPartDeletion.Init()
	PrimaryPartDeletion._initSignals()

	return nil
end

function PrimaryPartDeletion._initSignals()
	PrimaryPartDeletion._onPlayerDetection = Signal.new()
	PrimaryPartDeletion._maid = Maid.new()

	InitMaidFor(PrimaryPartDeletion, PrimaryPartDeletion._maid, Signal.IsSignal)

	PrimaryPartDeletion._onPlayerDetection:Connect(function(playerProfile)
		PlayerUtil.LoadPlayerCharacter(playerProfile.Player)
	end)

	return nil
end

return PrimaryPartDeletion
