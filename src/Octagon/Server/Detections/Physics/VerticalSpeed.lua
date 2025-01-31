-- SilentsReplacement
-- VerticalSpeed
-- July 18, 2021

--[[
    VerticalSpeed.Leeway : number
    VerticalSpeed.StartInterval : number
    VerticalSpeed.PlayerDetectionFlagExpireInterval : number
    VerticalSpeed.LeewayMultiplier : number
    VerticalSpeed.Enabled : boolean

	VerticalSpeed.Init() --> nil []
	VerticalSpeed.Cleanup() --> []
    VerticalSpeed.Start(
        detectionData : table
        playerProfile : PlayerProfile
        dt : number
    ) --> nil []
]]

local VerticalSpeed = {
	Leeway = 10,
	StartInterval = 0.1,
	PlayerDetectionFlagExpireInterval = 4,
	LeewayMultiplier = 1.25,
	Enabled = true,
}

local Octagon = script:FindFirstAncestor("Octagon")
local Util = require(Octagon.Shared.Util)
local SharedConstants = require(Octagon.Shared.SharedConstants)
local Signal = require(Octagon.Shared.Signal)
local Maid = require(Octagon.Shared.Maid)
local InitMaidFor = require(Octagon.Shared.InitMaidFor)
local DestroyAllMaids = require(Octagon.Shared.DestroyAllMaids)

function VerticalSpeed.Start(detectionData, playerProfile, deltaTime)
	local character = playerProfile.Player.Character
	local humanoid = character:FindFirstChildWhichIsA("Humanoid")

	local lastCFrame = detectionData.PhysicsData.LastCFrame
	local averageVerticalSpeed = VerticalSpeed._calculateVerticalSpeed(
		character.PrimaryPart.Position,
		lastCFrame.Position,
		deltaTime
	)
  
	if averageVerticalSpeed > playerProfile.PhysicsThresholds.VerticalSpeed then
		-- Common case: the event for listening to the humanoid's seat part changing was deferred
		-- and the player was temporarily black listed from being monitored
		-- while this detection ran:
		if (humanoid and humanoid.SeatPart) ~= nil then
			return nil
		end

		VerticalSpeed._onPlayerDetection:Fire(playerProfile, lastCFrame)
	end

	return nil
end

function VerticalSpeed.Cleanup()
	DestroyAllMaids(VerticalSpeed)

	return nil
end

function VerticalSpeed._calculateVerticalSpeed(currentPosition, lastPosition, dt)
	return math.floor(
		(
			currentPosition * SharedConstants.Vectors.Y
			- lastPosition * SharedConstants.Vectors.Y
		).Magnitude / dt
	)
end

function VerticalSpeed.Init()
	VerticalSpeed._initSignals()

	return nil
end

function VerticalSpeed._initSignals()
	VerticalSpeed._maid = Maid.new()
	VerticalSpeed._onPlayerDetection = Signal.new()

	InitMaidFor(VerticalSpeed, VerticalSpeed._maid, Signal.IsSignal)

	VerticalSpeed._onPlayerDetection:Connect(function(playerProfile, lastCFrame)
		local player = playerProfile.Player
		local primaryPart = player.Character.PrimaryPart

		playerProfile:RegisterPhysicsDetectionFlag("VerticalSpeed", "HighVerticalSpeed")

		-- Zero out the player's velocity on the Y axis to have them immediately fall down:
		primaryPart.AssemblyLinearVelocity *= SharedConstants.Vectors.XZ
		primaryPart.CFrame = lastCFrame

		-- Temporarily have the server handle physics
		-- for the player, which means the player can't do
		-- any physics exploits but results in jerky movement
		Util.SetBasePartNetworkOwner(primaryPart, nil)
	end)

	return nil
end

return VerticalSpeed
