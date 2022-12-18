local function RemoveMapVersionNumber(mapFolderName)
    return string.gsub(mapFolderName, ".v%d%d%d%d", "", 1)
end

local function CreateScenarioFilePath(mapFolderName)
    return "/maps/" .. mapFolderName .. "/" .. RemoveMapVersionNumber(mapFolderName) .. "_scenario.lua"
end

function OpenOfflineLobby()
    local mapFolderName = GetCommandLineArg("/mapFolderName", 1)
    if not mapFolderName then
        error("No /mapFolderName arg")
    end
    local playerName = import("/lua/user/prefs.lua").GetCurrentProfile().Name or "Unknown"
    local scenarioFilePath = CreateScenarioFilePath(mapFolderName[1])
    local onExitButtonClicked = function ()
        ExitApplication()
    end

    local lobby = import("/lua/ui/lobby/lobby.lua")
    lobby.CreateLobby('None', 0, playerName, nil, nil, GetFrame(0), onExitButtonClicked)
    lobby.HostGame(playerName .. "'s Skirmish", scenarioFilePath, true)
end