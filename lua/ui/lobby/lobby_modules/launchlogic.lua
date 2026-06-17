--*****************************************************************************
--* File: lua/ui/lobby/launchlogic.lua
--* Summary: Game launch / refresh orchestration extracted from lobby.lua.
--*          Contains UpdateGame (the central lobby refresh), TryLaunch (the
--*          pre-launch validation + launch sequence) and AlertHostMapMissing.
--*
--* Note: TryLaunch reassigns the central gameInfo (flatten step). Because this
--*       module captured its own copy of gameInfo via Init(), it must write the
--*       new value back through the injected SetGameInfo(), which updates
--*       lobby.lua and re-runs SyncModuleDeps() (refreshing this module's
--*       gameInfo upvalue mid-launch).
--*****************************************************************************


-- Upvalues injected by lobby.lua via LaunchLogic.Init()
local gameInfo
local GUI
local lobbyComm
local hostID
local localPlayerID
local singlePlayer
local MapUtil
local UIUtil
local LobbyComm
local Prefs
local Tooltip
local Mods
local Presets
local GameInfo
local utils
local Autobalance
local AIUtils
local MapUtils
local HostUtils
local FACTION_NAMES

local GetPlayersNotReady
local AddChatText
local EveryoneHasEstablishedConnections
local IsObserver
local FindSlotForID
local UpdateFactionSelector
local GetPlayerCount
local UpdateAvailableSlots
local UpdateSlotBackground
local SetSlotInfo
local ClearSlotInfo
local RefreshOptionDisplayData
local RefreshLobbyBackground
local RefreshLargeMap
local SetRuleTitleText
local SetGameTitleText
local AssignRandomFactions
local FixFactionIndexes
local autoMap
local SetWindowedLobby

-- Setters for state that lobby.lua owns and that TryLaunch needs to reassign.
local SetGameInfo
local SetNumberOfPlayers
local SetAutoRandMap

-- Init is split into two halves because SupCom Lua limits a function to 32
-- upvalues; assigning all injected locals in a single function exceeds it.
local function InitA(deps)
    gameInfo                       = deps.gameInfo
    GUI                            = deps.GUI
    lobbyComm                      = deps.lobbyComm
    hostID                         = deps.hostID
    localPlayerID                  = deps.localPlayerID
    singlePlayer                   = deps.singlePlayer
    MapUtil                        = deps.MapUtil
    UIUtil                         = deps.UIUtil
    LobbyComm                      = deps.LobbyComm
    Prefs                          = deps.Prefs
    Tooltip                        = deps.Tooltip
    Mods                           = deps.Mods
    Presets                        = deps.Presets
    GameInfo                       = deps.GameInfo
    utils                          = deps.utils
    Autobalance                    = deps.Autobalance
    AIUtils                        = deps.AIUtils
    MapUtils                       = deps.MapUtils
    HostUtils                      = deps.HostUtils
    FACTION_NAMES                  = deps.FACTION_NAMES
end

local function InitB(deps)
    GetPlayersNotReady             = deps.GetPlayersNotReady
    AddChatText                    = deps.AddChatText
    EveryoneHasEstablishedConnections = deps.EveryoneHasEstablishedConnections
    IsObserver                     = deps.IsObserver
    FindSlotForID                  = deps.FindSlotForID
    UpdateFactionSelector          = deps.UpdateFactionSelector
    GetPlayerCount                 = deps.GetPlayerCount
    UpdateAvailableSlots           = deps.UpdateAvailableSlots
    UpdateSlotBackground           = deps.UpdateSlotBackground
    SetSlotInfo                    = deps.SetSlotInfo
    ClearSlotInfo                  = deps.ClearSlotInfo
    RefreshOptionDisplayData       = deps.RefreshOptionDisplayData
    RefreshLobbyBackground         = deps.RefreshLobbyBackground
    RefreshLargeMap                = deps.RefreshLargeMap
    SetRuleTitleText               = deps.SetRuleTitleText
    SetGameTitleText               = deps.SetGameTitleText
    AssignRandomFactions           = deps.AssignRandomFactions
    FixFactionIndexes              = deps.FixFactionIndexes
    autoMap                        = deps.autoMap
    SetWindowedLobby               = deps.SetWindowedLobby

    SetGameInfo                    = deps.SetGameInfo
    SetNumberOfPlayers             = deps.SetNumberOfPlayers
    SetAutoRandMap                 = deps.SetAutoRandMap
end

function Init(deps)
    InitA(deps)
    InitB(deps)
end

function TryLaunch(skipNoObserversCheck)
    if not singlePlayer then
        local notReady = GetPlayersNotReady()
        if notReady then
            for k,v in notReady do
                AddChatText(LOCF("<LOC lobui_0203>%s isn't ready.",v))
            end
            return
        end
    end

    local teamsPresent = {}

    -- make sure there are some players (could all be observers?)
    -- Also count teams. There needs to be at least 2 teams (or all FFA) represented
    local numPlayers = 0
    local numHumanPlayers = 0
    local numTeams = 0
    for slot, player in gameInfo.PlayerOptions:pairs() do
        if player then
            numPlayers = numPlayers + 1

            if player.Human then
                numHumanPlayers = numHumanPlayers + 1
            end

            -- Make sure to increment numTeams for people in the special "-" team, represented by 1.
            if not teamsPresent[player.Team] or player.Team == 1 then
                teamsPresent[player.Team] = true
                numTeams = numTeams + 1
            end
        end
    end

    -- Ensure, for a non-sandbox game, there are some teams to fight.
    if gameInfo.GameOptions['Victory'] ~= 'sandbox' and numTeams < 2 then
        --AddChatText(LOC("<LOC lobui_0241>There must be more than one player or team or the Victory Condition must be set to Sandbox."))
        -- In case we start a game as single player we set the game temporarily to Sandbox mode. This will not change the lobby option itself!
        SPEW('GameOptions[\'Victory\'] changed temporarily from "'..gameInfo.GameOptions['Victory']..'" to "sandbox"')
        gameInfo.GameOptions['Victory'] = 'sandbox'
    end

    if numPlayers == 0 then
        AddChatText(LOC("<LOC lobui_0233>There are no players assigned to player slots, can not continue"))
        return
    end

    if not gameInfo.GameOptions.AllowObservers then

        -- if observers are not allowed, and team spawn is set to penguin_autobalance, and there are
        -- an odd number of players, then make the last player an observer now if human
        -- (before the check(s)/prompt(s) for having observer(s) when they're not allowed)
        if gameInfo.GameOptions.TeamSpawn == 'penguin_autobalance' then
            if math.mod(numPlayers, 2) == 1 then
                for i = 16, 1, -1 do
                    -- this gets the last occupied slot
                    if gameInfo.PlayerOptions[i] then
                        LOG(gameInfo.PlayerOptions[i].Human)
                        if gameInfo.PlayerOptions[i].Human then
                            HostUtils.ConvertPlayerToObserver(i)
                        end
                        break
                    end
                end
            end
        end

        local hostIsObserver = false
        local anyOtherObservers = false
        for k, observer in gameInfo.Observers:pairs() do
            if observer.OwnerID == localPlayerID then
                hostIsObserver = true
            else
                anyOtherObservers = true
            end
        end

        if hostIsObserver then
            AddChatText(LOC("<LOC lobui_0277>Cannot launch if the host isn't assigned a slot and observers are not allowed."))
            return
        end

        if anyOtherObservers and not skipNoObserversCheck then
            UIUtil.QuickDialog(GUI, "<LOC lobui_0278>Launching will kick observers because \"allow observers\" is disabled.  Continue?",
                                    "<LOC _Yes>", function() TryLaunch(true) end,
                                    "<LOC _No>", nil, nil, nil, true,
                                    {worldCover = false, enterButton = 1, escapeButton = 2})
            return
        end

        HostUtils.KickObservers("GameLaunched")
    end

    if not EveryoneHasEstablishedConnections(gameInfo.GameOptions.AllowObservers) then
        return
    end

    SetNumberOfPlayers(numPlayers)
    local function LaunchGame()

        if gameInfo.GameOptions.TeamSpawn == 'penguin_autobalance' then
            GUI.PenguinAutoBalance.OnClick()
        end

        -- These two things must happen before the flattening step, mostly for terrible reasons.
        -- This isn't ideal, as it leads to redundant UI repaints :/
        Autobalance.AssignAutoTeams()

        -- Force observers to start with the UEF skin to prevent them from launching as "random".
        if IsObserver(localPlayerID) then
            UIUtil.SetCurrentSkin("uef")
        end

        -- Eliminate the WatchedValue structures.
        SetGameInfo(GameInfo.Flatten(gameInfo))

        if gameInfo.GameOptions['RandomMap'] ~= 'Off' then
            SetAutoRandMap(true)
            autoMap()
        end

        SetFrontEndData('NextOpBriefing', nil)
        -- assign random factions just as game is launched
        AssignRandomFactions()
        -- fix faction indexes
        FixFactionIndexes()
        Autobalance.AssignRandomStartSpots()
        Autobalance.AssignAINames()
        local allRatings = {}
        local clanTags = {}
        for k, player in gameInfo.PlayerOptions do
            if player.PL then
                allRatings[player.PlayerName] = player.PL
                clanTags[player.PlayerName] = player.PlayerClan

                if not player.Human then
                    allRatings[player.PlayerName] = AIUtils.ComputeAIRating(gameInfo.GameOptions, player.AILobbyProperties)
                end
            end

            if player.OwnerID == localPlayerID then
                UIUtil.SetCurrentSkin(FACTION_NAMES[player.Faction])
            end
        end
        gameInfo.GameOptions['Ratings'] = allRatings
        gameInfo.GameOptions['ClanTags'] = clanTags

        local scenarioInfo = MapUtil.LoadScenario(gameInfo.GameOptions.ScenarioFile)

        -- Load in the default map options if they are not set manually

        -- Not all maps have options
        if scenarioInfo.options then

            -- If we don't validate them first then the people using the default
            -- as a value instead of the index of the value will mess us up
            MapUtil.ValidateScenarioOptions(scenarioInfo.options)

            -- For every option, if it's not set yet then add its default value
            for _, option in scenarioInfo.options do
                if not gameInfo.GameOptions[option.key] then
                    -- When the value data of the option is formatted as:
                    -- values = {
                    --     { text = "Easy", help = "We'll have sufficient time to start building up our defense strategy.", key = 1, },
                    --     { text = "Normal", help = "There's sufficient time - but we'll need to hurry up.", key = 2, },
                    --     { text = "Heroic", help = "There's little time - no space for errors.", key = 3, },
                    --     { text = "Legendary", help = "We're being dropped in the middle of it - we knew it was a suicide mission when we signed up for it.", key = 4, },
                    -- },
                    local keyVersion = option.values[option.default].key

                    -- When the value data of the option is formatted as:
                    -- values = {
                    --     '1','2','3','4','5','6','7','8','9','10','11','12','13','14','15','16','17','18','19','20'
                    -- }
                    local valueVersion = option.values[option.default]

                    -- Expect a key version, fall back on a value version
                    gameInfo.GameOptions[option.key] = keyVersion or valueVersion

                    -- Can be removed once this code leaves the develop branch
                    SPEW("Loading default map option: " .. tostring (option.key) .. " = " .. tostring (gameInfo.GameOptions[option.key]))
                end
            end
        end

        if scenarioInfo.AdaptiveMap then
            gameInfo.GameOptions["SpawnMex"] = gameInfo.SpawnMex
        end
        if gameInfo.GameOptions["CheatsEnabled"] == "true" and singlePlayer then
            gameInfo.GameOptions["GameSpeed"] = "adjustable"
        end

        HostUtils.SendArmySettingsToServer()

        -- Tell everyone else to launch and then launch ourselves.
        -- TODO: Sending gamedata here isn't necessary unless lobbyComm is fucking stupid and allows
        -- out-of-order message delivery.
        -- Downlord: I use this in clients now to store the rehost preset. So if you're going to remove this, please
        -- check if rehosting still works for non-host players.
        lobbyComm:BroadcastData({ Type = 'Launch', GameInfo = gameInfo })

        -- set the mods
        gameInfo.GameMods = Mods.GetGameMods(gameInfo.GameMods)

        SetWindowedLobby(false)

        Presets.SaveLastGamePreset()

        -- launch the game
        lobbyComm:LaunchGame(gameInfo)


    end

    LaunchGame()
end

function AlertHostMapMissing()
    if lobbyComm:IsHost() then
        HostUtils.PlayerMissingMapAlert(localPlayerID)
    else
        lobbyComm:SendData(hostID, {Type = 'MissingMap'})
    end
end

function UpdateGame()
    -- This allows us to assume the existence of UI elements throughout.
    if not GUI.uiCreated then
        WARN(debug.traceback(nil, "UpdateGame() pointlessly called before UI creation!"))
        return
    end

    local scenarioInfo

    if gameInfo.GameOptions.ScenarioFile and (gameInfo.GameOptions.ScenarioFile ~= "") then
        scenarioInfo = MapUtil.LoadScenario(gameInfo.GameOptions.ScenarioFile)

        -- update AI rating as game settings change
        for k = 1, 16 do
            local playerOptions = gameInfo.PlayerOptions[k]
            if playerOptions then
                if not playerOptions.Human then
                    playerOptions.PL = AIUtils.ComputeAIRating(gameInfo.GameOptions, playerOptions.AILobbyProperties);
                    playerOptions.MEAN = playerOptions.PL
                    playerOptions.DEV = 0
                end
            end
        end

        if scenarioInfo and scenarioInfo.map and scenarioInfo.map ~= '' then
            GUI.mapView:SetScenario(scenarioInfo)
            MapUtils.ShowMapPositions(GUI.mapView, scenarioInfo)
            MapUtils.ConfigureMapListeners(GUI.mapView, scenarioInfo)

            -- Briefing button takes priority over the patch notes if the map has a briefing
            if scenarioInfo.hasBriefing then
                GUI.briefingButton:Show()
                GUI.patchnotesButton:Hide()
            else
                GUI.briefingButton:Hide()
                GUI.patchnotesButton:Show()
            end

            -- contains information that is available during blueprint loading
            local preGameData = {}

            -- MAP ASSETS LOADING --

            -- store the (selected) map directory so that we can load individual blueprints from it
            preGameData.CurrentMapDir = Dirname(gameInfo.GameOptions.ScenarioFile)

            -- STRATEGIC ICON REPLACEMENT --

            -- icon replacements
            local iconReplacements = { }

            -- retrieve all (selected) mods
            local allMods = Mods.AllMods()
            local selectedMods = Mods.GetSelectedMods()

            -- loop over selected mods identifiers
            for uid, _ in selectedMods do

                -- get the mod, determine path to icon configuration file
                local mod = allMods[uid]

                -- check for mod integrity
                if not (mod.name and mod.author) then
                    WARN("Unable to load icons from mod '" .. uid .. "', the mod_info.lua file is not properly defined. It needs a name and author field.")
                end

                -- path to configuration file
                local iconConfigurationPath = mod.location .. "/mod_icons.lua"

                -- see if it exists
                if DiskGetFileInfo(iconConfigurationPath) then

                    -- see if we can import it
                    local ok, msg = pcall(
                        function()

                            -- attempt to load the file
                            local env = { }
                            doscript(iconConfigurationPath, env)

                            -- syntax errors are caught internally and instead it just returns the table untouched
                            if not (env.UnitIconAssignments or env.ScriptedIconAssignments) then
                                error("Lobby.lua - can not import the icon configuration file at '" .. iconConfigurationPath .. "'. This could be due to missing functionality functionality or a parsing error.")
                            end
                        end
                    )

                    -- if it passes this basic check, then continue
                    if ok then
                        local info = { }
                        info.Name = mod.name
                        info.Author = mod.author
                        info.Location = mod.location
                        info.Identifier = string.lower(utils.StringSplit(mod.location, '/')[2])
                        info.UID = uid
                        table.insert(iconReplacements, info)
                    -- tell us (and then spam the author, not the dev) if it failed
                    else
                        WARN("Unable to load icons from mod '" .. tostring(mod.name) .. "' with uid '" .. tostring(uid) .. "'. Please inform the author: " .. tostring(mod.author))
                        WARN(msg)
                    end
                end
            end

            preGameData.IconReplacements = iconReplacements

            -- try and set the preferences - it may crash when running multiple instances on a single machine that all try and start at the same time.
            local ok, msg = pcall(
                function()
                    -- store in preferences so that we can retrieve it during blueprint loading
                    SetPreference('PreGameData', preGameData)
                end
            )

            if not ok then
                WARN("Unable to update preferences. Are you running multiple instances on the same machine?" )
                WARN(msg)
            end

            -- PREFETCHING --

            -- Note that the PreGameData is not properly updated,
            -- hence we can not rely on mod and / or lobby option
            -- changes to be present.

            -- local mods = Mods.GetGameMods(gameInfo.GameMods)
            -- PrefetchSession(scenarioInfo.map, mods, true)

        else
            AlertHostMapMissing()
            GUI.mapView:Clear()
        end
    end

    local isHost = lobbyComm:IsHost()

    local localPlayerSlot = FindSlotForID(localPlayerID)
    if localPlayerSlot then
        local playerOptions = gameInfo.PlayerOptions[localPlayerSlot]

        -- Disable some controls if the user is ready.
        local notReady = not playerOptions.Ready

        UIUtil.setEnabled(GUI.becomeObserver, notReady)
        UIUtil.setEnabled(GUI.briefingButton, notReady)
        -- This button is enabled for all non-host players to view the configuration, and for the
        -- host to select presets (rather confusingly, one object represents both potential buttons)
        UIUtil.setEnabled(GUI.restrictedUnitsOrPresetsBtn, not isHost or notReady)

        UIUtil.setEnabled(GUI.factionSelector, notReady)
        if notReady then
            UpdateFactionSelector()
        end
    else
        UIUtil.setEnabled(GUI.factionSelector, false)
    end

    gameInfo.AdaptiveMap = scenarioInfo.AdaptiveMap

    local numPlayers = GetPlayerCount()

    local numAvailStartSpots = LobbyComm.maxPlayerSlots
    if scenarioInfo then
        local armyTable = MapUtil.GetArmies(scenarioInfo)
        if armyTable then
            numAvailStartSpots = table.getn(armyTable)
        end
    end

    UpdateAvailableSlots(numAvailStartSpots, scenarioInfo)

    -- Update all slots.
    for i = 1, LobbyComm.maxPlayerSlots do
        if gameInfo.ClosedSlots[i] then
            UpdateSlotBackground(i)
        else
            if gameInfo.PlayerOptions[i] then
                SetSlotInfo(i, gameInfo.PlayerOptions[i])
            else
                ClearSlotInfo(i)
            end
        end
    end

    if isHost then
        HostUtils.RefreshButtonEnabledness()
    end
    RefreshOptionDisplayData(scenarioInfo)

    -- Update the map background to reflect the possibly-changed map.
    if Prefs.GetFromCurrentProfile('LobbyBackground') == 4 then
        RefreshLobbyBackground()
    end

    -- Set the map name at the top right corner in lobby
    if scenarioInfo.name then
        GUI.MapNameLabel:StreamText(scenarioInfo.name, 20)
    end

    -- Add Tooltip info on Map Name Label
    if scenarioInfo then
        local TTips_map_version = scenarioInfo.map_version or "1"
        local TTips_army = table.getsize(scenarioInfo.Configurations.standard.teams[1].armies)
        local TTips_sizeX = scenarioInfo.size[1] / 51.2
        local TTips_sizeY = scenarioInfo.size[2] / 51.2

        local mapTooltip = {
            text = scenarioInfo.name,
            body = '- '..LOC("<LOC lobui_0759>Map version")..' : '..TTips_map_version..'\n '..
                   '- '..LOC("<LOC lobui_0760>Max Players")..' : '..TTips_army..' max'..'\n '..
                   '- '..LOC("<LOC lobui_0761>Map Size")..' : '..TTips_sizeX..'km x '..TTips_sizeY..'km'
        }

        Tooltip.AddControlTooltip(GUI.MapNameLabel, mapTooltip)
        Tooltip.AddControlTooltip(GUI.GameQualityLabel, mapTooltip)
    end

    -- If the large map is shown, update it.
    RefreshLargeMap()

    SetRuleTitleText(gameInfo.GameOptions.GameRules or "")
    SetGameTitleText(gameInfo.GameOptions.Title or LOC("<LOC lobui_0427>FAF Game Lobby"))

    if isHost and GUI.autoTeams then
        GUI.autoTeams:SetState(gameInfo.GameOptions.AutoTeams,true)
        Tooltip.DestroyMouseoverDisplay()
    end
end

