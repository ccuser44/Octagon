-- SilentsReplacement
-- PlayerUtil
-- September 02, 2021

--[[
	PlayerUtil.ClearAllCaches() --> nil []
	PlayerUtil.GetPlayerGroupRankInGroup(player : Player, groupId : number) --> number [groupRank]
	PlayerUtil.GetPlayerGroupRoleInGroup(player : Player, groupId : number) --> string [groupRole]
	PlayerUtil.IsPlayerInGroup(player : Player, groupId : number) --> boolean [IsPlayerInGroup]
	PlayerUtil.GetPlayerPolicyInfo(player : Player) --> table [policyInfo]
	PlayerUtil.GetPlayerCountryRegion(player : Player) --> string [region code]
	PlayerUtil.DoesPlayerOwnGamePass(playerUserId : number, gamePassId : number) --> boolean [DoesPlayerOwnGamePass]
	PlayerUtil.GetPlayerFrom(instance : any) --> Player | nil []
	PlayerUtil.IsPlayerGameOwner(player : Player) --> boolean [IsPlayerGameOwner]
	PlayerUtil.LoadPlayerCharacter(player : Player) --> nil []
	PlayerUtil.GetPlayerFriendsOnlineData(player : Player, maxFriends : number | nil) --> table | nil [FriendsOnlineData]
	PlayerUtil.IsPlayerInGroup(player : Player, groupId : number) --> boolean [IsPlayerInGroup]
	PlayerUtil.IsPlayerFriendsWith(player : Player, userId : number) --> boolean [IsPlayerFriendsWith]
	PlayerUtil.RequestStreamAroundAsync(player : Player, position : Vector3, timeOut : number | nil) --> nil []
]]

local PlayerUtil = {
	_playerGroupRanksCache = {},
	_playerGroupRolesCache = {},
	_playerPoliciesCache = {},
	_playerGamePassesCache = {},
	_playerCountryRegionsCache = {},
	_playerOnlineFriendsDataCache = {},
	_playerOnlineFriendsCache = {},
	_playerGroupsCache = {},
	_playerStreamsCache = {},
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
	DefaultPlayerGroupRank = 0,
	DefaultStreamAroundTimeout = 0,
	OwnerGroupRank = 255,
	DefaultPlayerGroupRole = "",
	DefaultPlayerCountryRegion = "US",
	DefaultPlayerPolicyInfo = {
		ArePaidRandomItemsRestricted = false,
		AllowedExternalLinkReferences = {},
		IsPaidItemTradingAllowed = false,
		IsSubjectToChinaPolicies = true,
	},

	MaxFriends = 200,
	DefaultPlayerOnlineFriendsData = {},
	DoesPlayerOwnGamePassByDefault = false,
	IsPlayerInGroupByDefault = false,
	IsPlayerFriendsWithUserIdByDefault = false,
}

function PlayerUtil.ClearAllCaches()
	for key, _ in pairs(PlayerUtil) do
		PlayerUtil[key] = nil
	end

	return nil
end

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

		response = LocalConstants.DefaultPlayerGroupRank
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

	if cachedResult and cachedResult[gamePassId] ~= nil then
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

	local cachedResult = PlayerUtil._playerCountryRegionsCache[player.UserId]

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

function PlayerUtil.GetPlayerFrom(instance)
	if not instance then
		return nil
	end

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

function PlayerUtil.LoadPlayerCharacter(player)
	assert(
		typeof(player) == "Instance" and player:IsA("Player"),
		LocalConstants.ErrorMessages.InvalidArgument:format(
			1,
			"PlayerUtil.IsPlayerGameOwner()",
			"Player",
			typeof(player)
		)
	)

	if not player:HasAppearanceLoaded() then
		player.CharacterAppearanceLoaded:Wait()
	end

	player:LoadCharacter()

	return nil
end

function PlayerUtil.GetPlayerFriendsOnlineData(player, maxFriends)
	assert(
		typeof(player) == "Instance" and player:IsA("Player"),
		LocalConstants.ErrorMessages.InvalidArgument:format(
			1,
			"PlayerUtil.GetPlayerFriendsOnlineData()",
			"Player",
			typeof(player)
		)
	)
	assert(
		typeof(maxFriends) == "number" or maxFriends == nil,
		LocalConstants.ErrorMessages.InvalidArgument:format(
			2,
			"PlayerUtil.GetPlayerFriendsOnlineData()",
			"number or nil",
			typeof(maxFriends)
		)
	)

	if maxFriends ~= nil then
		maxFriends = math.clamp(maxFriends, 0, LocalConstants.MaxFriends)
	end

	local cachedResult = PlayerUtil._playerOnlineFriendsDataCache[player.UserId]

	if cachedResult and cachedResult[maxFriends] ~= nil then
		return cachedResult[maxFriends]
	end

	local wasSuccessFull, response = RetryPcall(nil, nil, {
		player.GetFriendsOnline,
		player,
	})

	if not wasSuccessFull then
		warn(("[PlayerUtil.GetPlayerFriendsOnlineData()]: Failed. Error: %s"):format(response))

		response = LocalConstants.DefaultPlayerOnlineFriendsData
	end

	PlayerUtil._playerOnlineFriendsDataCache[player.UserId] = PlayerUtil._playerOnlineFriendsDataCache[player.UserId]
		or {}
	PlayerUtil._playerOnlineFriendsDataCache[player.UserId][maxFriends] = response

	return response
end

function PlayerUtil.IsPlayerInGroup(player, groupId)
	assert(
		typeof(player) == "Instance" and player:IsA("Player"),
		LocalConstants.ErrorMessages.InvalidArgument:format(
			1,
			"PlayerUtil.IsPlayerInGroup()",
			"Player",
			typeof(player)
		)
	)

	assert(
		typeof(groupId) == "number",
		LocalConstants.ErrorMessages.InvalidArgument:format(
			2,
			"PlayerUtil.IsPlayerInGroup()",
			"number",
			typeof(groupId)
		)
	)

	local cachedResult = PlayerUtil._playerGroupsCache[player.UserId]

	if cachedResult and cachedResult[groupId] ~= nil then
		return cachedResult[groupId]
	end

	local wasSuccessFull, response = RetryPcall(nil, nil, {
		player.IsInGroup,
		player,
		groupId,
	})

	if not wasSuccessFull then
		warn(("[PlayerUtil.IsPlayerInGroup()]: Failed. Error: %s"):format(response))

		response = LocalConstants.IsPlayerInGroupByDefault
	end

	PlayerUtil._playerGroupsCache[player.UserId] = PlayerUtil._playerGroupsCache[player.UserId]
		or {}
	PlayerUtil._playerGroupsCache[player.UserId][groupId] = response

	return response
end

function PlayerUtil.IsPlayerFriendsWith(player, userId)
	assert(
		typeof(player) == "Instance" and player:IsA("Player"),
		LocalConstants.ErrorMessages.InvalidArgument:format(
			1,
			"PlayerUtil.IsPlayerFriendsWith()",
			"Player",
			typeof(player)
		)
	)

	assert(
		typeof(userId) == "number",
		LocalConstants.ErrorMessages.InvalidArgument:format(
			2,
			"PlayerUtil.IsPlayerFriendsWith()",
			"number",
			typeof(userId)
		)
	)

	local cachedResult = PlayerUtil._playerOnlineFriendsCache[player.UserId]

	if cachedResult and cachedResult[userId] ~= nil then
		return cachedResult[userId]
	end

	local wasSuccessFull, response = RetryPcall(nil, nil, {
		player.IsFriendsWith,
		player,
		userId,
	})

	if not wasSuccessFull then
		warn(("[PlayerUtil.IsPlayerInGroup()]: Failed. Error: %s"):format(response))

		response = LocalConstants.IsPlayerFriendsWithUserIdByDefault
	end

	PlayerUtil._playerOnlineFriendsCache[player.UserId] = PlayerUtil._playerOnlineFriendsCache[player.UserId]
		or {}
	PlayerUtil._playerOnlineFriendsCache[player.UserId][userId] = response

	return response
end

function PlayerUtil.RequestStreamAroundAsync(player, position, timeOut)
	assert(
		typeof(player) == "Instance" and player:IsA("Player"),
		LocalConstants.ErrorMessages.InvalidArgument:format(
			1,
			"PlayerUtil.RequestStreamAroundAsync()",
			"Player",
			typeof(player)
		)
	)

	assert(
		typeof(position) == "Vector3",
		LocalConstants.ErrorMessages.InvalidArgument:format(
			2,
			"PlayerUtil.RequestStreamAroundAsync()",
			"Vector3",
			typeof(position)
		)
	)

	assert(
		typeof(timeOut) == "number" or timeOut == nil,
		LocalConstants.ErrorMessages.InvalidArgument:format(
			3,
			"PlayerUtil.RequestStreamAroundAsync()",
			"number or nil",
			typeof(timeOut)
		)
	)

	timeOut = timeOut or LocalConstants.DefaultStreamAroundTimeout

	local cachedResult = PlayerUtil._playerStreamsCache[player.UserId]

	if cachedResult and cachedResult[position.Magnitude] ~= nil then
		return nil
	end

	local wasSuccessFull, response = RetryPcall(nil, nil, {
		player.RequestStreamAroundAsync,
		player,
		position,
		timeOut,
	})

	if not wasSuccessFull then
		warn(("[PlayerUtil.RequestStreamAroundAsync()]: Failed. Error: %s"):format(response))

		response = LocalConstants.IsPlayerFriendsWithUserIdByDefault
	end

	PlayerUtil._playerStreamsCache[player.UserId] = PlayerUtil._playerStreamsCache[player.UserId]
		or {}
	PlayerUtil._playerStreamsCache[player.UserId][position.Magnitude] = response

	return nil
end

return PlayerUtil