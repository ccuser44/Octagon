-- SilentsReplacement
-- PlayerUtil
-- September 02, 2021

--[[
	PlayerUtil.GetPlayerGroupRankInGroup(player : Player, groupId : number) --> number [groupRank]
	PlayerUtil.GetPlayerGroupRoleInGroup(player : Player, groupId : number) --> string [groupRole]
	PlayerUtil.GetPlayerPolicyInfo(player : Player) --> table [policyInfo]
	PlayerUtil.GetPlayerCountryRegion(player : Player) --> string [region code]
	PlayerUtil.DoesPlayerOwnGamePass(playerUserId : number, gamePassId : number) --> boolean [DoesPlayerOwnGamePass]
	PlayerUtil.GetPlayerFromInstance(instance : Instance) --> Player | nil []
	PlayerUtil.IsPlayerGameOwner(player : Player) --> boolean [IsPlayerGameOwner]
]]

local PlayerUtil = {
	_playerGroupRanksCache = {},
	_playerGroupRolesCache = {},
	_playerPoliciesCache = {},
	_playerGamePassesCache = {},
	_playerCountryRegionsCache = {},
}

local MarketplaceService = game:GetService("MarketplaceService")
local PolicyService = game:GetService("PolicyService")
local Players = game:GetService("Players")
local LocalizationService = game:GetService("LocalizationService")

local RetryPcall = require(script.RetryPcall)

local LocalConstants = {
	ErrorMessages = {
		InvalidArgument = "Invalid argument#%d to %s: expected %s, got %s",
	},

	PlayerUtil = "[PlayerUtil]:",
	DefaulPlayerGroupRank = 0,
	OwnerGroupRank = 255,
	DefaultPlayerGroupRole = "",
	DefaultPlayerCountryRegion = "US",
	DefaultPlayerPolicyInfo = {
		ArePaidRandomItemsRestricted = false,
		AllowedExternalLinkReferences = {},
		IsPaidItemTradingAllowed = false,
		IsSubjectToChinaPolicies = true,
	},

	DoesPlayerOwnGamePassByDefault = false,
}

function PlayerUtil.GetPlayerGroupRankInGroup(player, groupId)
	assert(
		typeof(player) == "Instance" and player:IsA("Player"),
		LocalConstants.ErrorMessages.InvalidArgument:format(
			1,
			"PlayerUtil.GetPlayerGroupRankInGroup()",
			"Player",
			typeof(player)
		)
	)

	assert(
		typeof(groupId) == "number",
		LocalConstants.ErrorMessages.InvalidArgument:format(
			2,
			"PlayerUtil.GetPlayerGroupRankInGroup()",
			"number",
			typeof(groupId)
		)
	)

	local cachedResult = PlayerUtil._playerGroupRanksCache[player.UserId]

	if (cachedResult and cachedResult[groupId]) ~= nil then
		return cachedResult[groupId]
	end

	local wasSuccessFull, response = RetryPcall(
		LocalConstants.MaxFailedPcallTries,
		LocalConstants.FailedPcallRetryInterval,

		{
			player.GetRankInGroup,
			player,
			groupId,
		}
	)

	if not wasSuccessFull then
		warn(
			(("[PlayerUtil.GetPlayerGroupRankInGroup()]: Failed. Error: %s"):format(response))
		)

		response = LocalConstants.DefaulPlayerGroupRank
	end

	PlayerUtil._playerGroupRanksCache[player.UserId] = PlayerUtil._playerGroupRanksCache[player.UserId]
		or {}
	PlayerUtil._playerGroupRanksCache[player.UserId][groupId] = response

	return response
end

function PlayerUtil.GetPlayerGroupRoleInGroup(player, groupId)
	assert(
		typeof(player) == "Instance" and player:IsA("Player"),
		LocalConstants.ErrorMessages.InvalidArgument:format(
			1,
			"PlayerUtil.GetPlayerGroupRoleInGroup()",
			"Player",
			typeof(player)
		)
	)

	assert(
		typeof(groupId) == "number",
		LocalConstants.ErrorMessages.InvalidArgument:format(
			2,
			"PlayerUtil.GetPlayerGroupRoleInGroup()",
			"number",
			typeof(groupId)
		)
	)

	local cachedResult = PlayerUtil._playerGroupRolesCache[player.UserId]

	if (cachedResult and cachedResult[groupId]) ~= nil then
		return cachedResult[groupId]
	end

	local wasSuccessFull, response = RetryPcall(nil, nil, {
		player.GetRoleInGroup,
		player,
		groupId,
	})

	if not wasSuccessFull then
		warn(("[PlayerUtil.GetPlayerGroupRoleInGroup()]: Failed. Error: %s"):format(response))

		response = LocalConstants.DefaultPlayerGroupRole
	end

	PlayerUtil._playerGroupRolesCache[player.UserId] = PlayerUtil._playerGroupRolesCache[player.UserId]
		or {}
	PlayerUtil._playerGroupRolesCache[player.UserId][groupId] = response

	return response
end

function PlayerUtil.GetPolicyInfoForPlayer(player)
	assert(
		typeof(player) == "Instance" and player:IsA("Player"),
		LocalConstants.ErrorMessages.InvalidArgument:format(
			1,
			"PlayerUtil.GetPolicyInfoForPlayer()",
			"Player",
			typeof(player)
		)
	)

	local cachedResult = PlayerUtil._playerPoliciesCache[player.UserId]

	if cachedResult ~= nil then
		return cachedResult
	end

	local wasSuccessFull, response = RetryPcall(nil, nil, {
		PolicyService.GetPolicyInfoForPlayerAsync,
		PolicyService,
		player,
	})

	if not wasSuccessFull then
		warn(("[PlayerUtil.GetPolicyInfoForPlayer()]: Failed. Error: %s"):format(response))

		response = LocalConstants.DefaultPlayerPolicyInfo
	end

	PlayerUtil._playerPoliciesCache[player.UserId] = response

	return response
end

function PlayerUtil.DoesPlayerOwnGamePass(playerUserId, gamePassId)
	assert(
		typeof(playerUserId) == "number",
		LocalConstants.ErrorMessages.InvalidArgument:format(
			1,
			"PlayerUtil.DoesPlayerOwnGamePass()",
			"number",
			typeof(playerUserId)
		)
	)

	assert(
		typeof(gamePassId) == "number",
		LocalConstants.ErrorMessages.InvalidArgument:format(
			2,
			"PlayerUtil.DoesPlayerOwnGamePass()",
			"number",
			typeof(gamePassId)
		)
	)

	local cachedResult = PlayerUtil._playerPoliciesCache[playerUserId]

	if (cachedResult and cachedResult[gamePassId]) ~= nil then
		return cachedResult[gamePassId]
	end

	local wasSuccessFull, response = RetryPcall(nil, nil, {
		MarketplaceService.UserOwnsGamePassAsync,
		MarketplaceService,
		playerUserId,
		gamePassId,
	})

	if not wasSuccessFull then
		warn(("[PlayerUtil.DoesPlayerOwnGamePass()]: Failed. Error: %s"):format(response))

		response = LocalConstants.DoesPlayerOwnGamePassByDefault
	end

	PlayerUtil._playerGamePassesCache[playerUserId] = PlayerUtil._playerGamePassesCache[playerUserId]
		or {}
	PlayerUtil._playerGamePassesCache[playerUserId][gamePassId] = response

	return response
end

function PlayerUtil.GetPlayerCountryRegion(player)
	assert(
		typeof(player) == "Instance" and player:IsA("Player"),
		LocalConstants.ErrorMessages.InvalidArgument:format(
			1,
			"PlayerUtil.GetPlayerCountryRegion()",
			"Player",
			typeof(player)
		)
	)

	local cachedResult = PlayerUtil._playerCountryRegionsCache[player]

	if cachedResult ~= nil then
		return cachedResult
	end

	local wasSuccessFull, response = RetryPcall(nil, nil, {
		LocalizationService.GetCountryRegionForPlayerAsync,
		LocalizationService,
		player,
	})

	if not wasSuccessFull then
		warn(("[PlayerUtil.GetPlayerCountryRegion()]: Failed. Error: %s"):format(response))

		response = LocalConstants.DefaultPlayerCountryRegion
	end

	PlayerUtil._playerCountryRegionsCache[player.UserId] = response

	return response
end

function PlayerUtil.GetPlayerFromInstance(instance)
	assert(
		typeof(instance) == "Instance",
		LocalConstants.ErrorMessages.InvalidArgument:format(
			1,
			"PlayerUtil.GetPlayerFromInstance()",
			"Instance",
			typeof(instance)
		)
	)

	return Players:GetPlayerFromCharacter(instance.Parent)
		or Players:GetPlayerFromCharacter(instance.Parent.Parent)
end

function PlayerUtil.IsPlayerGameOwner(player)
	assert(
		typeof(player) == "Instance" and player:IsA("Player"),
		LocalConstants.ErrorMessages.InvalidArgument:format(
			1,
			"PlayerUtil.IsPlayerGameOwner()",
			"Player",
			typeof(player)
		)
	)

	local isPlayerGameOwner = nil

	if game.CreatorType == Enum.CreatorType.Group then
		local _, response = PlayerUtil.GetPlayerGroupRankInGroup(player, game.CreatorId)

		isPlayerGameOwner = response == LocalConstants.OwnerGroupRank
	else
		isPlayerGameOwner = player.UserId == game.CreatorId
	end

	return isPlayerGameOwner
end

return PlayerUtil
