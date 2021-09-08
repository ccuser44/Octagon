-- SilentsReplacement
-- PhysicsThreshold
-- September 08, 2021

--[[
	PhysicsThreshold.ComputeMaxVerticalSpeed(playerProfile : PlayerProfile, verticalSpeed : number) --> nil []
	PhysicsThreshold.ComputeMaxHorizontalSpeed(playerProfile : PlayerProfile, horizontalSpeed : number) --> nil []
]]

local PhysicsThreshold = {}

local detections = script:FindFirstAncestor("Octagon").Server.Detections
local VerticalSpeed = require(detections.Physics.VerticalSpeed)
local HorizontalSpeed = require(detections.Physics.HorizontalSpeed)

local LocalConstants = {
	MaxServerFPS = 60,
	AdditionalVerticalSpeedLeeway = 12,
}

function PhysicsThreshold.ComputeMaxVerticalSpeed(playerProfile, verticalSpeed)
	local verticalSpeedLeeway = VerticalSpeed.Leeway / 100

	playerProfile.PhysicsThresholds.VerticalSpeed = verticalSpeed
		+ math.sqrt(
			verticalSpeed * VerticalSpeed.LeewayMultiplier
		) * VerticalSpeed.LeewayMultiplier
		+ VerticalSpeed.LeewayMultiplier * (LocalConstants.MaxServerFPS * verticalSpeedLeeway)
		+ playerProfile:GetPhysicsThresholdIncrement(
			"VerticalSpeed"
		)
		+ LocalConstants.AdditionalVerticalSpeedLeeway

	return nil
end

function PhysicsThreshold.ComputeMaxHorizontalSpeed(playerProfile, horizontalSpeed)
	local horizontalSpeedLeeway = HorizontalSpeed.Leeway / 100

	playerProfile.PhysicsThresholds.HorizontalSpeed = horizontalSpeed
		+ math.sqrt(
			horizontalSpeed * HorizontalSpeed.LeewayMultiplier
		) * HorizontalSpeed.LeewayMultiplier
		+ HorizontalSpeed.LeewayMultiplier * (LocalConstants.MaxServerFPS * horizontalSpeedLeeway)
		+ playerProfile:GetPhysicsThresholdIncrement("HorizontalSpeed")

	return nil
end

return PhysicsThreshold
