function openOfflineLobby(mapFolderName)
    local playerName = import("/lua/user/prefs.lua").GetCurrentProfile().Name or "Unknown"
    local scenarioFilePath = createScenarioFilePath(mapFolderName)
    local lobby = import("/lua/ui/lobby/lobby.lua")
    lobby.CreateLobby('None', 0, playerName, nil, nil, GetFrame(0), function() ExitApplication() end)
    lobby.HostGame(playerName .. "'s Skirmish", scenarioFilePath, true)
end

function createScenarioFilePath(mapFolderName)
    return "/maps/" .. mapFolderName .. "/" .. removeVersionNumber(mapFolderName) .. "_scenario.lua"
end

function removeVersionNumber(mapFolderName)
    return string.gsub(mapFolderName, ".v%d%d%d%d", "", 1)
end