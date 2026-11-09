-- LocalScript inside StarterPlayerScripts
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")

-- CONFIGURATION
-- Add your target Group IDs, their abbreviations, and the minimum required rank number.
-- Note: Rank 0 means not in group, guest rank is usually 1, and owner is 255.
local SOUND_ID = "rbxassetid://138039736146643"

local TARGET_GROUPS = {
	[32749380] = { Abbreviation = "DEV", MinRank = 95 }, -- Replace with Group ID, abbreviation, and min rank
	[35234854] = { Abbreviation = "2NIA", MinRank = 1 }, -- Replace with Group ID, abbreviation, and min rank
    [35937797] = { Abbreviation = "MODS", MinRank = 1 },
}

local notificationSound = Instance.new("Sound")
notificationSound.SoundId = SOUND_ID
notificationSound.Volume = 0.5 -- Adjust volume between 0 and 1
notificationSound.Parent = game:GetService("SoundService")

-- FUNCTION TO SEND THE NOTIFICATION & PLAY AUDIO
local function sendNotification(playerName, abbreviation)
	-- Play the sound instantly when a match is found
	if SOUND_ID ~= "rbxassetid://0" and notificationSound.IsLoaded then
		notificationSound:Play()
	end

	local success = false
	while not success do
		success = pcall(function()
			StarterGui:SetCore("SendNotification", {
				Title = "Group Member Detected!",
				Text = string.format("[%s] %s is in the server.", abbreviation, playerName),
				Duration = 5,
			})
		end)
		if not success then
			task.wait(1)
		end
	end
end

-- FUNCTION TO CHECK A SINGLE PLAYER
local function checkPlayer(player)
	if player == Players.LocalPlayer then return end

	for groupId, data in pairs(TARGET_GROUPS) do
		local success, currentRank = pcall(function()
			return player:GetRankInGroup(groupId)
		end)

		if success and currentRank >= data.MinRank then
			sendNotification(player.Name, data.Abbreviation)
			break 
		end
	end
end

-- INITIAL SCAN
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(checkPlayer, player)
end

-- ACTIVE SCAN
Players.PlayerAdded:Connect(function(player)
	task.wait(1) 
	checkPlayer(player)
end)
