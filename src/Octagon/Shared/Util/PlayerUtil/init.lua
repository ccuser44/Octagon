-- SilentsReplacement
-- PlayerUtil
-- September 02, 2021

--[[
	PlayerUtil.ClearCaches() --> nil []
	PlayerUtil.ClearPlayerCache(player : Player) --> nil []
	PlayerUtil.SetPlayerNetworkOwner(player : Player) --> nil []
	PlayerUtil.GetPlayerNetworkOwner(player : Player) --> player | nil [PlayerNetworkOwner]
	PlayerUtil.GetPlayerSeatPart(player : Player) --> Seat | VehicleSeat | nil [PlayerSeatPart]
	PlayerUtil.GetPlayerRankInGroup(player : Player, groupId : number) --> number [groupRank]
	PlayerUtil.GetPlayerRoleInGroup(player : Player, groupId : number) --> string [groupRole]
	PlayerUtil.IsPlayerInGroup(player : Player, groupId : number) --> boolean [IsPlayerInGroup]
	PlayerUtil.GetPlayerPolicyInfo(player : Player) --> table [policyInfo]
	PlayerUtil.GetPlayerCountryRegionCode(player : Player) --> string [region code]
	PlayerUtil.DoesPlayerOwnGamePass(playerUserId : number, gamePassId : number) --> boolean [DoesPlayerOwnGamePass]
	PlayerUtil.GetPlayerFromInstance(instance : ?) --> Player | nil []
	PlayerUtil.IsPlayerGameOwner(player : Player) --> boolean [IsPlayerGameOwner]
	PlayerUtil.LoadPlayerCharacter(player : Player) --> nil []
	PlayerUtil.GetPlayerOnlineFriendsData(player : Player, maxFriends : number | nil) --> table | nil [FriendsOnlineData]
	PlayerUtil.IsPlayerInGroup(player : Player, groupId : number) --> boolean [IsPlayerInGroup]
	PlayerUtil.IsPlayerFriendsWith(player : Player, userId : number) --> boolean [IsPlayerFriendsWith]
	PlayerUtil.RequestStreamAroundAsync(player : Player, position : Vector3, timeOut : number | nil) --> nil []
	PlayerUtil.GetPlayerFriends(playerUserId : number) --> Instance | nil [PlayerFriends]
]]

local PlayerUtil = {
	PlayerStreamsCache = {},
	PlayerFriendsCache = {},
	_isInit = false,
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
	DefaultPlayerCountryRegionCode = "N/A",
	DefaultPlayerPolicyInfo = {
		ArePaidRandomItemsRestricted = false,
		AllowedExternalLinkReferences = {},
		IsPaidItemTradingAllowed = false,
		IsSubjectToChinaPolicies = true,
	},

	MaxPlayerFriends = 200,
	DefaultPlayerOnlineFriendsData = {},
	DoesPlayerOwnGamePassByDefault = false,
	IsPlayerInGroupByDefault = false,
	IsPlayerFriendsWithUserIdByDefault = false,
}

function PlayerUtil.ClearCaches()
	for key, _ in pairs(PlayerUtil) do
		PlayerUtil[key] = nil
	end

	return nil
end

function PlayerUtil.ClearPlayerCache(player)
	assert(
		typeof(player) == "Instance" and player:IsA("Player"),
		LocalConstants.ErrorMessages.InvalidArgument:format(
			1,
			"PlayerUtil.ClearPlayerCache()",
			"Player",
			typeof(player)
		)
	)

	for _, value in pairs(PlayerUtil) do
		if typeof(value) == "table" and value[player.UserId] then
			value[player.UserId] = nil
		end
	end

	return nil
end

function PlayerUtil.GetPlayerRankInGroup(player, groupId)
	assert(
		typeof(player) == "Instance" and player:IsA("Player"),
		LocalConstants.ErrorMessages.InvalidArgument:format(
			1,
			"PlayerUtil.GetPlayerRankInGroup()",
			"Player",
			typeof(player)
		)
	)

	assert(
		typeof(groupId) == "number",
		LocalConstants.ErrorMessages.InvalidArgument:format(
			2,
			"PlayerUtil.GetPlayerRankInGroup()",
			"number",
			typeof(groupId)
		)
	)

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
		warn(("[PlayerUtil.GetPlayerRankInGroup()]: Failed. Error: %s"):format(response))
		response = LocalConstants.DefaultPlayerGroupRank
	end

	return response
end

function PlayerUtil.GetPlayerRoleInGroup(player, groupId)
	assert(
		typeof(player) == "Instance" and player:IsA("Player"),
		LocalConstants.ErrorMessages.InvalidArgument:format(
			1,
			"PlayerUtil.GetPlayerRoleInGroup()",
			"Player",
			typeof(player)
		)
	)

	assert(
		typeof(groupId) == "number",
		LocalConstants.ErrorMessages.InvalidArgument:format(
			2,
			"PlayerUtil.GetPlayerRoleInGroup()",
			"number",
			typeof(groupId)
		)
	)

	local wasSuccessFull, response = RetryPcall(nil, nil, {
		player.GetRoleInGroup,
		player,
		groupId,
	})

	if not wasSuccessFull then
		warn(("[PlayerUtil.GetPlayerRoleInGroup()]: Failed. Error: %s"):format(response))
		response = LocalConstants.DefaultPlayerGroupRole
	end

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

	local wasSuccessFull, response = RetryPcall(nil, nil, {
		PolicyService.GetPolicyInfoForPlayerAsync,
		PolicyService,
		player,
	})

	if not wasSuccessFull then
		warn(("[PlayerUtil.GetPolicyInfoForPlayer()]: Failed. Error: %s"):format(response))
		response = LocalConstants.DefaultPlayerPolicyInfo
	end

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

	return response
end

function PlayerUtil.GetPlayerCountryRegionCode(player)
	assert(
		typeof(player) == "Instance" and player:IsA("Player"),
		LocalConstants.ErrorMessages.InvalidArgument:format(
			1,
			"PlayerUtil.GetPlayerCountryRegionCode()",
			"Player",
			typeof(player)
		)
	)

	local wasSuccessFull, response = RetryPcall(nil, nil, {
		LocalizationService.GetCountryRegionForPlayerAsync,
		LocalizationService,
		player,
	})

	if not wasSuccessFull then
		warn(("[PlayerUtil.GetPlayerCountryRegionCode()]: Failed. Error: %s"):format(response))

		response = LocalConstants.DefaultPlayerCountryRegionCode
	end

	return response
end

function PlayerUtil.GetPlayerFromInstance(instance)
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
		isPlayerGameOwner = select(2, PlayerUtil.GetPlayerRankInGroup(player, game.CreatorId))
			== LocalConstants.OwnerGroupRank
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

	-- The recommended way to load a player's character is to first wait for their character's appearance to load,
	-- told by a Roblox engineer:

	if not player:HasAppearanceLoaded() then
		player.CharacterAppearanceLoaded:Wait()
	end

	player:LoadCharacter()

	return nil
end

function PlayerUtil.GetPlayerSeatPart(player)
	assert(
		typeof(player) == "Instance" and player:IsA("Player"),
		LocalConstants.ErrorMessages.InvalidArgument:format(
			1,
			"PlayerUtil.GetPlayerSeatPart()",
			"Player",
			typeof(player)
		)
	)
	local humanoid = player.Character and player.Character:FindFirstChildWhichIsA("Humanoid")

	return humanoid and humanoid.SeatPart or nil
end

function PlayerUtil.GetPlayerFriends(playerUserId)
	assert(
		typeof(playerUserId) == "number",
		LocalConstants.ErrorMessages.InvalidArgument:format(
			1,
			"PlayerUtil.GetPlayerFriends()",
			"number",
			typeof(playerUserId)
		)
	)

	local cachedResult = PlayerUtil.PlayerFriendsCache[playerUserId]

	if cachedResult ~= nil then
		return cachedResult
	end

	local wasSuccessFull, response = RetryPcall(nil, nil, {
		Players.GetFriendsAsync,
		Players,
		playerUserId,
	})

	if not wasSuccessFull then
		warn(("[PlayerUtil.GetPlayerFriends()]: Failed. Error: %s"):format(response))
	else
		PlayerUtil.PlayerFriendsCache[playerUserId] = response
	end

	return response
end

function PlayerUtil.GetPlayerNetworkOwner(player)
	assert(
		typeof(player) == "Instance" and player:IsA("Player"),
		LocalConstants.ErrorMessages.InvalidArgument:format(
			1,
			"PlayerUtil.GetPlayerNetworkOwner()",
			"Player",
			typeof(player)
		)
	)

	if not player.Character or not player.Character.PrimaryPart then
		return nil
	end

	return player.Character.PrimaryPart:GetNetworkOwner()
end

function PlayerUtil.SetPlayerNetworkOwner(player, networkOwner)
	assert(
		typeof(player) == "Instance" and player:IsA("Player"),
		LocalConstants.ErrorMessages.InvalidArgument:format(
			1,
			"PlayerUtil.SetPlayerNetworkOwner()",
			"Player",
			typeof(player)
		)
	)

	assert(
		networkOwner == player or networkOwner == nil,
		LocalConstants.ErrorMessages.InvalidArgument:format(
			2,
			"PlayerUtil.SetPlayerNetworkOwner()",
			"Player or nil",
			typeof(networkOwner)
		)
	)

	if not player.Character or not player.Character.PrimaryPart then
		return nil
	end

	local canSetNetworkOwnership, response =
		player.Character.PrimaryPart:CanSetNetworkOwnership()

	if canSetNetworkOwnership then
		player.Character.PrimaryPart:SetNetworkOwner(networkOwner)
	else
		warn(("[PlayerUtil.SetPlayerNetworkOwner()]: Failed. Error: %s"):format(response))
	end
end

function PlayerUtil.GetPlayerOnlineFriendsData(player, maxFriends)
	assert(
		typeof(player) == "Instance" and player:IsA("Player"),
		LocalConstants.ErrorMessages.InvalidArgument:format(
			1,
			"PlayerUtil.GetPlayerOnlineFriendsData()",
			"Player",
			typeof(player)
		)
	)
	assert(
		typeof(maxFriends) == "number" or maxFriends == nil,
		LocalConstants.ErrorMessages.InvalidArgument:format(
			2,
			"PlayerUtil.GetPlayerOnlineFriendsData()",
			"number or nil",
			typeof(maxFriends)
		)
	)

	if maxFriends ~= nil then
		maxFriends = math.clamp(maxFriends, 0, LocalConstants.MaxPlayerFriends)
	end

	local wasSuccessFull, response = RetryPcall(nil, nil, {
		player.GetFriendsOnline,
		player,
		maxFriends,
	})

	if not wasSuccessFull then
		warn(("[PlayerUtil.GetPlayerOnlineFriendsData()]: Failed. Error: %s"):format(response))
	end

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

	local wasSuccessFull, response = RetryPcall(nil, nil, {
		player.IsInGroup,
		player,
		groupId,
	})

	if not wasSuccessFull then
		warn(("[PlayerUtil.IsPlayerInGroup()]: Failed. Error: %s"):format(response))
		response = LocalConstants.IsPlayerInGroupByDefault
	end

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

	local wasSuccessFull, response = RetryPcall(nil, nil, {
		player.IsFriendsWith,
		player,
		userId,
	})

	if not wasSuccessFull then
		warn(("[PlayerUtil.IsPlayerFriendsWith()]: Failed. Error: %s"):format(response))
		response = LocalConstants.IsPlayerFriendsWithUserIdByDefault
	end

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

	local cachedResult = PlayerUtil.PlayerStreamsCache[player.UserId]

	if (cachedResult and cachedResult[position.Magnitude]) ~= nil then
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
	else
		PlayerUtil.PlayerStreamsCache[player.UserId][position.Magnitude] = true
	end

	return nil
end

function PlayerUtil._playerAdded(player)
	PlayerUtil.PlayerStreamsCache[player.UserId] = {}

	return nil
end

function PlayerUtil._playerRemoved(player)
	PlayerUtil.ClearPlayerCache(player)

	return nil
end

function PlayerUtil._init()
	PlayerUtil._isInit = true
	Players.PlayerAdded:Connect(PlayerUtil._playerAdded)
	Players.PlayerRemoving:Connect(PlayerUtil._playerRemoved)

	-- Get current players in game if the script runs late due to deferred signal behaviour. Roblox hasn't
	-- released a fix for this incoming behavior:
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(PlayerUtil._playerAdded, player)
	end

	return nil
end

if not PlayerUtil._isInit then
	PlayerUtil._init()
end

return PlayerUtil
