-- SilentsReplacement
-- PlayerProfile
-- August 07, 2021

--[[
    PlayerProfile.new() --> PlayerProfile []
    PlayerProfile.IsPlayerProfile(self : any) --> boolean [IsPlayerProfile]

    -- Only when accessed from an object returned by PlayerProfile.new:

    PlayerProfile.OnPhysicsDetectionFlag : Signal (flag : string)
    PlayerProfile.OnPhysicsDetectionFlagExpire : Signal (expiredFlag : string)
    PlayerProfile.Player : Player
    PlayerProfile.Maid : Maid
	PlayerProfile.OnInit : Signal ()
    PlayerProfile.DetectionMaid : Maid
    PlayerProfile.PhysicsDetectionFlagsHistory : table
    PlayerProfile.PhysicsDetectionFlags : number
    
	PlayerProfile:UpdateAllDetectionPhysicsData(key : string, value : any) --> nil []
	PlayerProfile:IncrementPhysicsThreshold(physicsThreshold : string, thresholdIncrement : number) --> nil []
	PlayerProfile:DecrementPhysicsThreshold(physicsThreshold : string, thresholdDecrement : number) --> nil []
    PlayerProfile:RegisterPhysicsDetectionFlag(detection : string, flag : string) --> nil []
	PlayerProfile:GetPhysicsThresholdIncrement(physicsThreshold : string) --> number [thresholdIncrement]
    PlayerProfile:IsDestroyed() --> boolean [IsDestroyed]
    PlayerProfile:Destroy() --> nil []
    PlayerProfile:Init() --> nil []
    PlayerProfile:IsInit() --> boolean [IsInit]
    PlayerProfile:GetCurrentActivePhysicsDetectionFlag() --> string | nil [physicsDetectionFlag]
]]

local PlayerProfile = {}
PlayerProfile.__index = PlayerProfile

local Workspace = game:GetService("Workspace")

local Octagon = script:FindFirstAncestor("Octagon")
local Signal = require(Octagon.Shared.Signal)
local Maid = require(Octagon.Shared.Maid)
local DestroyAllMaids = require(Octagon.Shared.DestroyAllMaids)
local InitMaidFor = require(Octagon.Shared.InitMaidFor)
local PlayerProfileService = require(script.Parent)
local SharedConstants = require(Octagon.Shared.SharedConstants)
local PhysicsThreshold = require(Octagon.Server.PhysicsThreshold)

local LocalConstants = {
	MinPhysicsThreshold = 0,
	MaxPhysicsThreshold = math.huge,
	MinPhysicsThresholdIncrement = 0,
	MaxPhysicsThresholdIncrement = math.huge,

	Methods = {
		AlwaysAvailable = {
			"IsDestroyed",
		},
	},
}

function PlayerProfile.IsPlayerProfile(self)
	return typeof(self) == "table" and self._isPlayerProfile
end

function PlayerProfile.new(player)
	assert(
		typeof(player) == "Instance" and player:IsA("Player"),
		SharedConstants.ErrorMessages.InvalidArgument:format(
			1,
			"PlayerProfile.new()",
			"a player object",
			typeof(player)
		)
	)

	assert(
		not PlayerProfileService.LoadedPlayerProfiles[player],
		"Can't create new player profile class for the same player!"
	)

	local self = setmetatable({
		Maid = Maid.new(),
		DetectionMaid = Maid.new(),
		ThresholdUpdateMaid = Maid.new(),
		Player = player,
		DetectionData = {},
		PhysicsThresholds = {
			HorizontalSpeed = 0,
			VerticalSpeed = 0,
		},
		PhysicsDetectionFlagsHistory = {},
		OnPhysicsDetectionFlag = Signal.new(),
		OnPhysicsDetectionFlagExpire = Signal.new(),
		OnInit = Signal.new(),
		PhysicsDetectionFlagCount = 0,
		_isPlayerProfile = true,
		_isInit = false,
		_isDestroyed = false,
		_physicsThresholdIncrements = {},
	}, PlayerProfile)

	InitMaidFor(self, self.Maid, Signal.IsSignal)
	PlayerProfileService.LoadedPlayerProfiles[player] = self
	PlayerProfileService.OnPlayerProfileLoaded:Fire(self)

	return self
end

function PlayerProfile:IsDestroyed()
	return self._isDestroyed
end

function PlayerProfile:Destroy()
	local player = self.Player
	local activePhysicsDetectionFlag = self:GetCurrentActivePhysicsDetectionFlag()

	if activePhysicsDetectionFlag ~= nil then
		self.DetectionData[activePhysicsDetectionFlag].FlagExpireDt = 0
		self.OnPhysicsDetectionFlagExpire:Fire()
	end

	self:_cleanup()
	self._isDestroyed = true

	setmetatable(self, {
		__index = function(_, key)
			if typeof(PlayerProfile[key]) == "function" then
				assert(
					table.find(LocalConstants.Methods.AlwaysAvailable, key) ~= nil,
					("Can only call methods [%s] as profile is destroyed"):format(
						table.concat(LocalConstants.Methods.AlwaysAvailable)
					)
				)

				return PlayerProfile[key]
			end

			return nil
		end,
	})

	PlayerProfileService.OnPlayerProfileDestroyed:Fire(player)

	return nil
end

function PlayerProfile:IsInit()
	return self._isInit
end

function PlayerProfile:Init(physicsDetections)
	assert(not self:IsInit(), "Cannot init player profile if it is already init")
	assert(
		typeof(physicsDetections) == "table",
		SharedConstants.ErrorMessages.InvalidArgument:format(
			1,
			"PlayerProfile:Init()",
			"table",
			typeof(physicsDetections)
		)
	)

	self:_initPhysicsDetectionData(physicsDetections)
	self:_initPhysicsThresholds(physicsDetections)

	self._isInit = true
	PlayerProfileService.OnPlayerProfileInit:Fire(self)
	self.OnInit:Fire()

	return nil
end

function PlayerProfile:IncrementPhysicsThreshold(physicsThreshold, thresholdIncrement)
	assert(
		typeof(physicsThreshold) == "string",
		SharedConstants.ErrorMessages.InvalidArgument:format(
			1,
			"PlayerProfile:IncrementPhysicsThreshold()",
			"string",
			typeof(physicsThreshold)
		)
	)

	assert(
		typeof(thresholdIncrement) == "number",
		SharedConstants.ErrorMessages.InvalidArgument:format(
			2,
			"PlayerProfile:IncrementPhysicsThreshold()",
			"number",
			typeof(thresholdIncrement)
		)
	)

	assert(self.PhysicsThresholds[physicsThreshold] ~= nil, "Invalid physics threshold")
	assert(thresholdIncrement > 0, "Invalid physics threshold increment")

	self.PhysicsThresholds[physicsThreshold] += thresholdIncrement
	self._physicsThresholdIncrements[physicsThreshold] += thresholdIncrement

	return nil
end

function PlayerProfile:DecrementPhysicsThreshold(physicsThreshold, thresholdDecrement)
	assert(
		typeof(physicsThreshold) == "string",
		SharedConstants.ErrorMessages.InvalidArgument:format(
			1,
			"PlayerProfile:DecrementPhysicsThreshold()",
			"string",
			typeof(physicsThreshold)
		)
	)

	assert(
		typeof(thresholdDecrement) == "number",
		SharedConstants.ErrorMessages.InvalidArgument:format(
			2,
			"PlayerProfile:DecrementPhysicsThreshold()",
			"number",
			typeof(thresholdDecrement)
		)
	)

	assert(self.PhysicsThresholds[physicsThreshold] ~= nil, "Invalid physics threshold")

	self.PhysicsThresholds[physicsThreshold] = math.clamp(
		self.PhysicsThresholds[physicsThreshold] - thresholdDecrement,
		LocalConstants.MinPhysicsThreshold,
		LocalConstants.MaxPhysicsThreshold
	)

	self._physicsThresholdIncrements[physicsThreshold] = math.clamp(
		self._physicsThresholdIncrements[physicsThreshold] - thresholdDecrement,
		LocalConstants.MinPhysicsThreshold,
		LocalConstants.MaxPhysicsThreshold
	)

	return nil
end

function PlayerProfile:RegisterPhysicsDetectionFlag(detection, flag)
	assert(
		typeof(detection) == "string",
		SharedConstants.ErrorMessages.InvalidArgument:format(
			1,
			"PlayerProfile:RegisterPhysicsDetectionFlag()",
			"string",
			typeof(detection)
		)
	)

	assert(
		typeof(flag) == "string",
		SharedConstants.ErrorMessages.InvalidArgument:format(
			2,
			"PlayerProfile:RegisterPhysicsDetectionFlag()",
			"string",
			typeof(flag)
		)
	)

	local detections = Octagon.Server.Detections
	local physicsDetectionModule = detections.Physics:FindFirstChild(detection)
		and require(detections.Physics[detection])

	assert(
		(physicsDetectionModule or detections.NonPhysics:FindFirstChild(detection)) ~= nil,
		"Invalid detection"
	)

	if physicsDetectionModule ~= nil then
		local detectionData = self.DetectionData[detection]

		detectionData.FlagExpireDt = physicsDetectionModule.PlayerDetectionFlagExpireInterval

		task.spawn(function()
			while detectionData.FlagExpireDt > 0 do
				detectionData.FlagExpireDt -= task.wait(1)
			end

			-- Prevent edge case where the player profile was
			-- destroyed while this loop is running. This happens
			-- when the player immediately leaves after being flagged
			-- by a physics detection:
			if not self:IsDestroyed() then
				detectionData.FlagExpireDt = 0
				self.OnPhysicsDetectionFlagExpire:Fire(flag)
			end
		end)
	end

	self.PhysicsDetectionFlagCount += 1
	table.insert(self.PhysicsDetectionFlagsHistory, flag)
	self.OnPhysicsDetectionFlag:Fire(flag)

	return nil
end

function PlayerProfile:SetDeinitTag()
	self._isInit = false

	return nil
end

function PlayerProfile:GetCurrentActivePhysicsDetectionFlag()
	for detection, detectionData in pairs(self.DetectionData) do
		if detectionData.FlagExpireDt > 0 then
			return detection
		end
	end

	return nil
end

function PlayerProfile:GetPhysicsThresholdIncrement(physicsThreshold)
	assert(
		typeof(physicsThreshold) == "string",
		SharedConstants.ErrorMessages.InvalidArgument:format(
			1,
			"PlayerProfile:GetPhysicsThresholdIncrement()",
			"string",
			typeof(physicsThreshold)
		)
	)

	return self._physicsThresholdIncrements[physicsThreshold]
end

function PlayerProfile:_cleanup()
	DestroyAllMaids(self)
	self.Player = nil

	return nil
end

function PlayerProfile:_initPhysicsDetectionData(physicsDetections)
	-- Setup detection data:
	for _, module in ipairs(physicsDetections) do
		local detection = module.Name

		local physicsData = {
			LastCFrame = nil,
			RaycastParams = nil,
		}

		if detection == "NoClip" then
			-- Setup ray cast params for no clip detection:
			local rayCastParams = RaycastParams.new()
			rayCastParams.FilterDescendantsInstances = { self.Player.Character }
			rayCastParams.IgnoreWater = true
			physicsData.RaycastParams = rayCastParams
		end

		local detectionData = self.DetectionData[detection]
		local lastStartDt = detectionData and detectionData.LastStartDt or 0
		local flagExpireDt = detectionData and detectionData.FlagExpireDt or 0

		self.DetectionData[detection] = {
			LastStartDt = lastStartDt,
			FlagExpireDt = flagExpireDt,
			PhysicsData = physicsData,
			PlayerDetectionExpireInterval = detection.PlayerDetectionExpireInterval,
		}
	end

	return nil
end

function PlayerProfile:UpdateAllDetectionPhysicsData(key, value)
	for _, detectionData in pairs(self.DetectionData) do
		detectionData.PhysicsData[key] = value
	end

	return nil
end

function PlayerProfile:_initPhysicsThresholds(physicsDetections)
	local function ComputeJumpPowerFromJumpHeight(jumpHeight)
		return math.sqrt(2 * Workspace.Gravity * jumpHeight)
	end

	local player = self.Player
	local humanoid = player.Character.Humanoid

	for _, module in ipairs(physicsDetections) do
		local detection = module.Name

		self._physicsThresholdIncrements[detection] = self._physicsThresholdIncrements[detection]
			or 0
		self.PhysicsThresholds[detection] = 0
	end

	PhysicsThreshold.ComputeMaxVerticalSpeed(
		self,
		humanoid.UseJumpPower and humanoid.JumpPower
			or ComputeJumpPowerFromJumpHeight(humanoid.JumpHeight)
	)
	PhysicsThreshold.ComputeMaxHorizontalSpeed(self, humanoid.WalkSpeed)

	self.ThresholdUpdateMaid:AddTask(
		humanoid:GetPropertyChangedSignal("JumpPower"):Connect(function()
			PhysicsThreshold.ComputeMaxVerticalSpeed(self, humanoid.JumpPower)
		end)
	)

	self.ThresholdUpdateMaid:AddTask(
		humanoid:GetPropertyChangedSignal("JumpHeight"):Connect(function()
			PhysicsThreshold.ComputeMaxVerticalSpeed(
				self,
				ComputeJumpPowerFromJumpHeight(humanoid.JumpHeight)
			)
		end)
	)

	self.ThresholdUpdateMaid:AddTask(
		humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
			PhysicsThreshold.ComputeMaxHorizontalSpeed(self, humanoid.WalkSpeed)
		end)
	)

	return nil
end

return PlayerProfile
