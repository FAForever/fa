--*****************************************************************************
--* File: lua/modules/ui/lobby/lobby.lua
--* Author: Chris Blackwell
--* Summary: Game selection UI
--*
--* Copyright © 2005 Gas Powered Games, Inc. All rights reserved.
--*****************************************************************************
local GameVersion = import("/lua/version.lua").GetVersion
local UIUtil = import("/lua/ui/uiutil.lua")
local MenuCommon = import("/lua/ui/menus/menucommon.lua")
local Prefs = import("/lua/user/prefs.lua")
local MapUtil = import("/lua/ui/maputil.lua")
local Group = import("/lua/maui/group.lua").Group
local RadioButton = import("/lua/ui/controls/radiobutton.lua").RadioButton
local ResourceMapPreview = import("/lua/ui/controls/resmappreview.lua").ResourceMapPreview
local Popup = import("/lua/ui/controls/popups/popup.lua").Popup
local Slider = import("/lua/maui/slider.lua").Slider
local PlayerData = import("/lua/ui/lobby/data/playerdata.lua").PlayerData
local GameInfo = import("/lua/ui/lobby/data/gamedata.lua")
local WatchedValueArray = import("/lua/ui/lobby/data/watchedvalue/watchedvaluearray.lua").WatchedValueArray
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local Button = import("/lua/maui/button.lua").Button
local ToggleButton = import("/lua/ui/controls/togglebutton.lua").ToggleButton
local ChatHandler = import("/lua/ui/lobby/lobby_modules/chathandler.lua")
local Edit = import("/lua/maui/edit.lua").Edit
local LobbyComm = import("/lua/ui/lobby/lobbycomm.lua")
local Tooltip = import("/lua/ui/game/tooltip.lua")
local Mods = import("/lua/mods.lua")
local FactionData = import("/lua/factions.lua")
local TextArea = import("/lua/ui/controls/textarea.lua").TextArea
local Presets = import("/lua/ui/lobby/presets.lua")

-- Extracted from lobby.lua for maintainability.
local Autobalance = import("/lua/ui/lobby/lobby_modules/autobalance.lua")
local CPUBenchmark = import("/lua/ui/lobby/lobby_modules/cpubenchmark.lua")
local MessageHandlers = import("/lua/ui/lobby/lobby_modules/messagehandlers.lua")
local HostUtils_Module = import("/lua/ui/lobby/lobby_modules/hostutils.lua")
local SlotMenu = import("/lua/ui/lobby/lobby_modules/slotmenu.lua")
local AIUtils = import("/lua/ui/lobby/lobby_modules/aiutils.lua")
local MapUtils = import("/lua/ui/lobby/lobby_modules/maputils.lua")
local LaunchLogic = import("/lua/ui/lobby/lobby_modules/launchlogic.lua")
local PingUtils = import("/lua/ui/lobby/lobby_modules/pingutils.lua")
local OptionsDialog = import("/lua/ui/lobby/lobby_modules/optionsdialog.lua")
local CreateUI_Module = import("/lua/ui/lobby/lobby_modules/createui.lua")

local utils = import("/lua/system/utils.lua")

local Trueskill = import("/lua/ui/lobby/trueskill.lua")
local Player = Trueskill.Player
local Rating = Trueskill.Rating
local ModBlacklist = import("/etc/faf/blacklist.lua").Blacklist
local Teams = Trueskill.Teams
local EscapeHandler = import("/lua/ui/dialogs/eschandler.lua")
local CountryTooltips = import("/lua/ui/help/tooltips-country.lua").tooltip
local SetUtils = import("/lua/system/setutils.lua")
local JSON = import("/lua/system/dkson.lua").json
local UTF =  import("/lua/utf.lua")
-- AI type tables now live in aiutils.lua. Load them once at startup.
AIUtils.RefreshAITypes()

--This is a special table that allows us to pass data to blueprints.lua, before the rest of the game is loaded.
-- do not use this for anything that doesnt do blueprint modding, use GameOptions for that instead, which will load it into sim.

local IsSyncReplayServer = false

local AddUnicodeCharToEditText = import("/lua/utf.lua").AddUnicodeCharToEditText

if HasCommandLineArg("/syncreplay") and HasCommandLineArg("/gpgnet") then
    IsSyncReplayServer = true
end

local globalOpts = import("/lua/ui/lobby/lobbyoptions.lua").globalOpts
local teamOpts = import("/lua/ui/lobby/lobbyoptions.lua").teamOptions
local AIOpts = import("/lua/ui/lobby/lobbyoptions.lua").AIOpts
local gameColors = import("/lua/gamecolors.lua").GameColors

local numOpenSlots = LobbyComm.maxPlayerSlots

-- Add lobby options from AI mods (logic lives in aiutils.lua).
AIUtils.ImportModAIOptions(AIOpts)

-- Maps faction identifiers to their names.
local FACTION_NAMES = {[1] = "uef", [2] = "aeon", [3] = "cybran", [4] = "seraphim", [5] = "random" }

local rehostPlayerOptions = {} -- Player options loaded from preset, used for rehosting

-- formattedOptions / nonDefaultFormattedOptions now live in optionsdialog.lua.
local LrgMap = false

local HostUtils
-- mapPreviewSlotSwap state now lives in maputils.lua (ConfigureMapListeners).

teamIcons = {
    '/lobby/team_icons/team_no_icon.dds',
    '/lobby/team_icons/team_1_icon.dds',
    '/lobby/team_icons/team_2_icon.dds',
    '/lobby/team_icons/team_3_icon.dds',
    '/lobby/team_icons/team_4_icon.dds',
    '/lobby/team_icons/team_5_icon.dds',
    '/lobby/team_icons/team_6_icon.dds',
    '/lobby/team_icons/team_7_icon.dds',
    '/lobby/team_icons/team_8_icon.dds',
}

DebugEnabled = Prefs.GetFromCurrentProfile('LobbyDebug') or ''
local HideDefaultOptions = Prefs.GetFromCurrentProfile('LobbyHideDefaultOptions') == 'true'

local connectedTo = {} -- by UID
CurrentConnection = {} -- by Name
ConnectionEstablished = {} -- by Name
ConnectedWithProxy = {} -- by UID


allAvailableFactionsList = {}

local availableMods = {} -- map from peer ID to set of available mods; each set is a map from "mod id"->true
local selectedSimMods = {} -- Similar map for activated sim mods
local selectedUIMods = {} -- Similar map for activated UI mods

local CPU_Benchmarks = {} -- Stores CPU benchmark data

local function parseCommandlineArguments()
    -- Set of all possible command line option keys.
    -- The client sometimes gives us empty-string as some args, which gets interpreted as that key
    -- having as value the name of the next key. This set lets us interpret that case using the
    -- default option.
    local CMDLINE_ARGUMENT_KEYS = {
        ["/init"] = true,
        ["/country"] = true,
        ["/numgames"] = true,
        ["/mean"] = true,
        ["/clan"] = true,
        ["/deviation"] = true,
        ["/joincustom"] = true,
        ["/gpgnet"] = true,
    }

    local function GetCommandLineArgOrDefault(argname, default)
        local arg = GetCommandLineArg(argname, 1)
        if arg and not CMDLINE_ARGUMENT_KEYS[arg[1]] then
            return arg[1]
        end

        return default
    end

    return {
        PrefLanguage = tostring(string.lower(GetCommandLineArgOrDefault("/country", "world"))),
        isRehost = HasCommandLineArg("/rehost"),
        initName = GetCommandLineArgOrDefault("/init", ""),
        numGames = tonumber(GetCommandLineArgOrDefault("/numgames", 0)),
        playerMean = tonumber(GetCommandLineArgOrDefault("/mean", 1500)),
        playerClan = tostring(GetCommandLineArgOrDefault("/clan", "")),
        playerDeviation = tonumber(GetCommandLineArgOrDefault("/deviation", 500)),
        debugLobby = HasCommandLineArg("/debugLobby"), -- Used by LaunchFAInstances script to set players as ready by default
    }
end
local argv = parseCommandlineArguments()

local playerRating = math.floor(Trueskill.round2((argv.playerMean - 3 * argv.playerDeviation) / 100.0) * 100)

local Strings = LobbyComm.Strings

---@type LobbyComm
local lobbyComm = false
local localPlayerName = ""
local gameName = ""
local hostID = false
local singlePlayer = false
---@type Group
local GUI = false
local localPlayerID = false
---@type GameData | WatchedGameData
local gameInfo = false
local lastKickMessage = UTF.UnescapeString(Prefs.GetFromCurrentProfile('lastKickMessage') or "")

local defaultMode =(HasCommandLineArg("/windowed") and "windowed") or Prefs.GetFromCurrentProfile('options').primary_adapter
local windowedMode = defaultMode == "windowed" or (HasCommandLineArg("/windowed"))

function SetWindowedLobby(windowed)
    -- Dont change resolution if user already using windowed mode
    if windowed == windowedMode or defaultMode == 'windowed' then
        return
    end

    if windowed then
        ConExecute('SC_PrimaryAdapter windowed')
    else
        ConExecute('SC_PrimaryAdapter ' .. tostring(defaultMode))
    end

    windowedMode = windowed
end

function GetNumAvailStartSpots()
    local numAvailStartSpots = nil
    local scenarioInfo = nil
    if gameInfo.GameOptions.ScenarioFile and (gameInfo.GameOptions.ScenarioFile ~= "") then
        scenarioInfo = MapUtil.LoadScenario(gameInfo.GameOptions.ScenarioFile)
    end
    if scenarioInfo then
        local armyTable = MapUtil.GetArmies(scenarioInfo)
        if armyTable then
            if gameInfo.GameOptions['RandomMap'] == 'Off' then
                numAvailStartSpots = table.getn(armyTable)
            else
                numAvailStartSpots = numberOfPlayers
            end
        end
    else
        WARN("Can't assign random start spots, no scenario selected.")
    end
    return numAvailStartSpots
end

-- Slot state labels, sourced from the extracted SlotMenu module.
local slotMenuStrings = SlotMenu.GetStrings()

--- Thin wrapper around the extracted SlotMenu module. Gathers the lobby-local
--- state (ready status, AI label tables, slot counts) and delegates the actual
--- menu construction to slotmenu.lua.
local function GetSlotMenuTables(stateKey, hostKey, slotNum)
    local isPlayerReady = false
    local localPlayerSlot = FindSlotForID(localPlayerID)
    if localPlayerSlot then
        if gameInfo.PlayerOptions[localPlayerSlot].Ready then
            isPlayerReady = true
        end
    end

    return SlotMenu.Build(stateKey, hostKey, {
        adaptiveMap   = gameInfo.AdaptiveMap,
        slotNum       = slotNum,
        numOpenSlots  = numOpenSlots,
        isPlayerReady = isPlayerReady,
        AIKeys        = AIUtils.GetKeys(),
        AIStrings     = AIUtils.GetStrings(),
        AITooltips    = AIUtils.GetTooltips(),
    })
end

--- Get the value of the LastColor, sanitised in case it's an unsafe value.
-- In case a new patch removes a color
function GetSanitisedLastColor()
    local lastColor = Prefs.GetFromCurrentProfile('LastColorFAF') or 1
    if lastColor > table.getn(gameColors.PlayerColors) or lastColor < 1 then
        lastColor = 1
    end

    return lastColor
end

--- Get the value of the LastFaction, sanitised in case it's an unsafe value.
--
-- This means when some retarded mod (*cough*Nomads*cough*) writes a large number to LastFaction, we
-- don't catch fire.
function GetSanitisedLastFaction()
    local lastFaction = Prefs.GetFromCurrentProfile('LastFaction') or 1
    if lastFaction > table.getn(FactionData.Factions) + 1 or lastFaction < 1 then
        lastFaction = 1
    end

    return lastFaction
end

--- Get a PlayerData object for the local player, configured using data from their profile.
function GetLocalPlayerData()

    local version, gametype, commit = import("/lua/version.lua").GetVersionData()

    return PlayerData(
        {
            PlayerName = localPlayerName,
            OwnerID = localPlayerID,
            Human = true,
            PlayerColor = GetSanitisedLastColor(),
            Faction = GetSanitisedLastFaction(),
            PlayerClan = argv.playerClan,
            PL = playerRating,
            NG = argv.numGames,
            MEAN = argv.playerMean,
            DEV = argv.playerDeviation,
            Country = argv.PrefLanguage,

            Version = version,
            GameType = gametype,
            Commit = commit,

            Ready = argv.debugLobby,
        }
)
end

local function DoSlotBehavior(slot, key, name)
    if key == 'open' then
        HostUtils.SetSlotClosed(slot, false)
    elseif key == 'close' then
        HostUtils.SetSlotClosed(slot, true)
    elseif key == 'close_spawn_mex' then
        HostUtils.SetSlotClosedSpawnMex(slot)
    elseif key == 'occupy' then
        if IsPlayer(localPlayerID) and not gameInfo.PlayerOptions[FindSlotForID(localPlayerID)].Ready then
            if lobbyComm:IsHost() then
                HostUtils.MovePlayerToEmptySlot(FindSlotForID(localPlayerID), slot)
            else
                lobbyComm:SendData(hostID, {Type = 'MovePlayer', RequestedSlot = slot})
            end
        elseif IsObserver(localPlayerID) then
            if lobbyComm:IsHost() then
                local requestedFaction = GetSanitisedLastFaction()
                HostUtils.ConvertObserverToPlayer(FindObserverSlotForID(localPlayerID), slot)
            else
                lobbyComm:SendData(
                    hostID,
                    {
                        Type = 'RequestConvertToPlayer',
                        ObserverSlot = FindObserverSlotForID(localPlayerID),
                        PlayerSlot = slot
                    }
                )
            end
        end
        UpdateFactionSelector()
    elseif key == 'pm' then
        if gameInfo.PlayerOptions[slot].Human then
            GUI.chatEdit:SetText(string.format("/whisper %s ", gameInfo.PlayerOptions[slot].PlayerName))
        end
    -- Handle the various "Move to slot X" options.
    elseif string.sub(key, 1, 19) == 'move_player_to_slot' then
        HostUtils.SwapPlayers(slot, tonumber(string.sub(key, 20)))
    elseif key == 'remove_to_observer' then
        local playerInfo = gameInfo.PlayerOptions[slot]
        if playerInfo.Human then
            HostUtils.ConvertPlayerToObserver(slot)
        end
    elseif key == 'remove_to_kik' then
        if gameInfo.PlayerOptions[slot].Human then
            local kickMessage = function(self, str)
                local msg

                msg = "\n Kicked by host. \n Reason: " .. str

                SendSystemMessage("lobui_0756", gameInfo.PlayerOptions[slot].PlayerName)
                lobbyComm:EjectPeer(gameInfo.PlayerOptions[slot].OwnerID, msg)

                -- Save message for next time
                Prefs.SetToCurrentProfile('lastKickMessage', UTF.EscapeString(str))
                lastKickMessage = str
            end

            CreateInputDialog(GUI, "<LOC lobui_0166>Are you sure?", kickMessage, lastKickMessage)
        else
            HostUtils.RemoveAI(slot)
        end
    else
        -- We're adding an AI of some sort.
        if lobbyComm:IsHost() then
            HostUtils.AddAI(name, key, slot)
        end
    end
end

local function IsModAvailable(modId)
    for k,v in availableMods do
        if not v[modId] then
            return false
        end
    end
    return true
end


function Reset()
    lobbyComm = false
    localPlayerName = ""
    gameName = ""
    hostID = false
    singlePlayer = false
    GUI = false
    localPlayerID = false
    availableMods = {}
    selectedUIMods = Mods.GetSelectedUIMods()
    selectedSimMods = Mods.GetSelectedSimMods()
    numOpenSlots = LobbyComm.maxPlayerSlots
    gameInfo = GameInfo.CreateGameInfo(LobbyComm.maxPlayerSlots)
    SyncModuleDeps()
end

-- NOTE: InitLobbyComm and its lobbyComm.* callbacks are deliberately NOT
-- extracted into a lobby_modules/ file, unlike the other UI/logic sections.
--
-- Unlike the extracted modules (which only *read* lobby state pushed in via
-- SyncModuleDeps), these callbacks *reassign* lobby.lua's own locals:
--   lobbyComm -> nil/false (ConnectionFailed, Ejected, GameLaunched)
--   GUI       -> false      (GameLaunched)
--   hostID, localPlayerID, localPlayerName (ConnectionToHostEstablished, Hosting)
-- In a separate module those assignments would land in the module's environment
-- instead of here, so every one of them would have to be rerouted through an
-- injected setter plus a SyncModuleDeps() to keep the other modules in sync.
--
-- Worse, KeepAliveThreadFunc below loops on `while lobbyComm do`: it relies on
-- lobbyComm being a live upvalue so it exits the moment lobbyComm is cleared.
-- A re-injected copy could miss that clear and spin forever.
--
-- The payoff would be organisational only, the risk (reassignment desync +
-- the keep-alive thread) is high, and this code is verified working, so it is
-- intentionally left in place.
function InitLobbyComm(protocol, localPort, desiredPlayerName, localPlayerUID, natTraversalProvider)
    lobbyComm = LobbyComm.CreateLobbyComm(protocol, localPort, desiredPlayerName, localPlayerUID, natTraversalProvider)

    if not lobbyComm then
        error('Failed to create lobby using port ' .. tostring(localPort))
    end

    lobbyComm.ConnectionFailed = function(self, reason)
        LOG("CONNECTION FAILED " .. reason)
        GUI.connectionFailedDialog = UIUtil.ShowInfoDialog(GUI.panel, LOCF(Strings.ConnectionFailed, Strings[reason] or reason),
                                                           "<LOC _OK>", ReturnToMenu)

        lobbyComm:Destroy()
        lobbyComm = nil
    end

    lobbyComm.LaunchFailed = function(self,reasonKey)
        AddChatText(LOC(Strings[reasonKey] or reasonKey))
    end

    lobbyComm.Ejected = function(self,reason)
        LOG("EJECTED " .. reason)

        GUI.connectionFailedDialog = UIUtil.ShowInfoDialog(GUI, LOCF(Strings.Ejected, Strings[reason] or reason), "<LOC _OK>", ReturnToMenu)
        lobbyComm:Destroy()
        lobbyComm = nil
    end

    lobbyComm.ConnectionToHostEstablished = function(self,myID,myName,theHostID)
        LOG("CONNECTED TO HOST")
        hostID = theHostID
        localPlayerID = myID
        localPlayerName = myName

        lobbyComm:SendData(hostID, { Type = 'SetAvailableMods', Mods = Mods.GetLocallyAvailableMods(), Name = localPlayerName})

        lobbyComm:SendData(hostID,
            {
                Type = 'AddPlayer',
                PlayerOptions = GetLocalPlayerData():AsTable()
            }
        )

        -- Update, if needed, and broadcast, your CPU benchmark value.
        if not singlePlayer then
            ForkThread(function() CPUBenchmark.UpdateBenchmark() end)
        end

        local function KeepAliveThreadFunc()
            local threshold = LobbyComm.quietTimeout
            local active = true
            local prev = 0
            while lobbyComm do
                local host = lobbyComm:GetPeer(hostID)
                if active and host.quiet > threshold then
                    active = false
                    local function OnRetry()
                        host = lobbyComm:GetPeer(hostID)
                        threshold = host.quiet + LobbyComm.quietTimeout
                        active = true
                    end
                    UIUtil.QuickDialog(GUI, "<LOC lobui_0266>Connection to host timed out.",
                                            "<LOC lobui_0267>Keep Trying", OnRetry,
                                            "<LOC lobui_0268>Give Up", ReturnToMenu,
                                            nil, nil,
                                            true,
                                            {worldCover = false, escapeButton = 2})
                elseif host.quiet < prev then
                    threshold = LobbyComm.quietTimeout
                end
                prev = host.quiet
                WaitSeconds(1)
            end
        end -- KeepAliveThreadFunc

        GUI.keepAliveThread = ForkThread(KeepAliveThreadFunc)
        CreateUI(LobbyComm.maxPlayerSlots)
    end

    --- Called by the engine when we receive data from other players. There is no checking to see if the data is legitimate, these need to be done in Lua.
    ---
    --- Data can be sent via `BroadcastData` and/or `SendData`.
    ---@param self UILobbyCommunication
    ---@param data UILobbyReceivedMessage
    lobbyComm.DataReceived = function(self, data)
        -- make it more convenient to debug malicious traffic
        SPEW(string.format("Received data of type %s from %s (%s)", tostring(data.Type), tostring(data.SenderID), tostring(data.SenderName)))

        -- Decide if we should just drop the packet. Violations here are usually people using a
        -- modified lobby.lua to try to do stupid shit.
        if not MessageHandlers[data.Type] then
            WARN("Unknown message type: " .. tostring(data.Type))
            return
        end

        -- No defined validator is taken to be always-accept.
        if not MessageHandlers[data.Type].Accept or MessageHandlers[data.Type].Accept(data) then
            MessageHandlers[data.Type].Handle(data)
        elseif MessageHandlers[data.Type].Reject then
            MessageHandlers[data.Type].Reject(data)
        else
            WARN("Rejected message of type " .. tostring(data.Type) .. " from " .. tostring(FindNameForID(data.SenderID)))
        end
    end

    lobbyComm.SystemMessage = function(self, text)
        AddChatText(text)
    end

    lobbyComm.GameLaunched = function(self)
        local player = lobbyComm:GetLocalPlayerID()
        for i, v in gameInfo.PlayerOptions do
            if v.Human and v.OwnerID == player then
                Prefs.SetToCurrentProfile('LoadingFaction', v.Faction)
                break
            end
        end

        GpgNetSend('GameState', 'Launching')
        if GUI.pingThread then
            KillThread(GUI.pingThread)
        end
        if GUI.keepAliveThread then
            KillThread(GUI.keepAliveThread)
        end
        GUI:Destroy()
        GUI = false
        MenuCommon.MenuCleanup()
        lobbyComm:Destroy()
        lobbyComm = false

        -- determine if cheat keys should be mapped
        if not DebugFacilitiesEnabled() then
            IN_ClearKeyMap()
            IN_AddKeyMapTable(import("/lua/keymap/keymapper.lua").GetKeyMappings(gameInfo.GameOptions['CheatsEnabled']=='true'))
        end
    end

    lobbyComm.Hosting = function(self)
        InitHostUtils()

        localPlayerID = lobbyComm:GetLocalPlayerID()
        hostID = localPlayerID
        HostUtils.UpdateMods()

        --- Returns true if the given option has the given key as a valid setting.
        local function keyIsValidForOption(option, key)
            for k, v in option.values do
                if v.key == key or v == key then
                    return true
                end
            end
            return false
        end

        -- Given an option key, find the value stored in the profile (if any) and assign either it,
        -- or that option's default value, to the current game state.
        local setOptionsFromPref = function(option)
            local defValue = Prefs.GetFromCurrentProfile("LobbyOpt_" .. option.key)

            -- Do the slightly stupid thing to check if the option we found in the profile is
            -- a valid key for this option. Some mods muck about with the possibilities, so we
            -- need to make sure we use a sane default if that's happened.
            if defValue == nil or not keyIsValidForOption(option, defValue) then
                -- Exception to make AllowObservers work because the engine requires
                -- the keys to be bool. Custom options should use 'True' or 'False'
                if option.key == 'AllowObservers' then
                    defValue = option.values[option.default].key
                else
                    defValue = option.values[option.default].key or option.values[option.default]
                end
            end

            SetGameOption(option.key, defValue, true)
        end

        -- Give myself the first slot
        local myPlayerData = GetLocalPlayerData()

        gameInfo.PlayerOptions[1] = myPlayerData

        -- set default lobby values
        for index, option in globalOpts do
            setOptionsFromPref(option)
        end

        for index, option in teamOpts do
            setOptionsFromPref(option)
        end

        for index, option in AIOpts do
            setOptionsFromPref(option)
        end

        -- The key, LastScenario, is referred to from GPG code we don't hook.
        if not self.desiredScenario or self.desiredScenario == "" then
            self.desiredScenario = Prefs.GetFromCurrentProfile("LastScenario")
        end
        local scenarioInfo = MapUtil.LoadScenario(self.desiredScenario)
        if not scenarioInfo or scenarioInfo.type != UIUtil.requiredType then
            self.desiredScenario = UIUtil.defaultScenario
        end
        SetGameOption('ScenarioFile', self.desiredScenario, true)

        GUI.keepAliveThread = ForkThread(
        -- Eject players who haven't sent a heartbeat in a while
        function()
            while true and lobbyComm do
                local peers = lobbyComm:GetPeers()
                for k,peer in peers do
                    if peer.quiet > LobbyComm.quietTimeout then
                        lobbyComm:EjectPeer(peer.id,'TimedOutToHost')
                        -- %s timed out.
                        SendSystemMessage("lobui_0205", peer.name)

                        -- Search and Remove the peer disconnected
                        for k, v in CurrentConnection do
                            if v == peer.name then
                                CurrentConnection[k] = nil
                                break
                            end
                        end
                        for k, v in ConnectionEstablished do
                            if v == peer.name then
                                ConnectionEstablished[k] = nil
                                break
                            end
                        end
                        for k, v in ConnectedWithProxy do
                            if v == peer.id then
                                ConnectedWithProxy[k] = nil
                                break
                            end
                        end
                    end
                end
                WaitSeconds(1)
            end
        end
        )

        CreateUI(LobbyComm.maxPlayerSlots)
        ForkThread(function() CPUBenchmark.UpdateBenchmark(false) end)

        if argv.isRehost then
            local settings = Presets.GetLastGameSettings()
            if not settings then
                ApplyGameSettings(settings)
            end

            local rehostSlot = FindRehostSlotForID(localPlayerID)
            if rehostSlot then
                HostUtils.MovePlayerToEmptySlot(1, rehostSlot)
            end

            for index, playerInfo in ipairs(rehostPlayerOptions) do
                if not playerInfo.Human then
                    HostUtils.AddAI(playerInfo.PlayerName, playerInfo.AIPersonality, playerInfo.StartSpot)
                end
            end
        end

        UpdateGame()
    end

    lobbyComm.PeerDisconnected = function(self,peerName,peerID)

         -- Search and Remove the peer disconnected
        for k, v in CurrentConnection do
            if v == peerName then
                CurrentConnection[k] = nil
                break
            end
        end
        for k, v in ConnectionEstablished do
            if v == peerName then
                ConnectionEstablished[k] = nil
                break
            end
        end
        for k, v in ConnectedWithProxy do
            if v == peerID then
                ConnectedWithProxy[k] = nil
                break
            end
        end

        if IsPlayer(peerID) then
            local slot = FindSlotForID(peerID)
            if slot and lobbyComm:IsHost() then
                if HasCommandLineArg('/gpgnet') then
                    PlayVoice(Sound{Bank = 'XGG',Cue = 'XGG_Computer__04717'}, true)
                end
                lobbyComm:BroadcastData(
                {
                    Type = 'Peer_Really_Disconnected',
                    Options =  gameInfo.PlayerOptions[slot]:AsTable(),
                    Slot = slot,
                    Observ = false,
                }
                )
                ClearSlotInfo(slot)
                gameInfo.PlayerOptions[slot] = nil
                UpdateGame()
            end
        elseif IsObserver(peerID) then
            local slot2 = FindObserverSlotForID(peerID)
            if slot2 and lobbyComm:IsHost() then
                lobbyComm:BroadcastData(
                {
                    Type = 'Peer_Really_Disconnected',
                    Options =  gameInfo.Observers[slot2]:AsTable(),
                    Slot = slot2,
                    Observ = true,
                }
                )
                gameInfo.Observers[slot2] = nil
                UpdateGame()
            end
        end

        availableMods[peerID] = nil
        if HostUtils.UpdateMods then
            HostUtils.UpdateMods()
        end
    end

    lobbyComm.GameConfigRequested = function(self)
        return {
            Options = gameInfo.GameOptions,
            HostedBy = localPlayerName,
            PlayerCount = GetPlayerCount(),
            GameName = gameName,
            ProductCode = import("/lua/productcode.lua").productCode,
        }
    end
end

--- Create a new, unconnected lobby.
function ReallyCreateLobby(protocol, localPort, desiredPlayerName, localPlayerUID, natTraversalProvider, over, exitBehavior, playerHasSupcom)
    Reset()

    -- Among other things, this clears uimain's override escape handler, allowing our escape
    -- handler manager to work.
    MenuCommon.MenuCleanup()

    if GUI then
        WARN('CreateLobby called twice for UI construction (Should be unreachable)')
        GUI:Destroy()
        return
    end

    -- Make sure we have a profile
    if not GetPreference("profile.current") then
        Prefs.CreateProfile("FAF_"..desiredPlayerName)
    end

    GUI = UIUtil.CreateScreenGroup(over, "CreateLobby ScreenGroup")

    GUI.exitBehavior = exitBehavior

    GUI.optionControls = {}
    GUI.slots = {}

    -- Set up the base escape handler first: want this one at the bottom of the stack.
    GUI.exitLobbyEscapeHandler = function()
        GUI.chatEdit:AbandonFocus()
        local quitDialog = UIUtil.QuickDialog(GUI,
            "<LOC lobby_0000>Exit game lobby?",
            "<LOC _Yes>", function()
                EscapeHandler.PopEscapeHandler()
                if HasCommandLineArg("/gpgnet") then
                    -- Quit to desktop
                    EscapeHandler.SafeQuit()
                else
                    -- Back to main menu
                    ReturnToMenu(false)
                end
            end,

            -- Fight to keep our focus on the chat input box, to prevent keybinding madness.
            "<LOC _Cancel>", function()
                GUI.chatEdit:AcquireFocus()
            end,
            nil, nil,
            true,
            {escapeButton = 2, enterButton = 1, worldCover = true}
        )
    end
    EscapeHandler.PushEscapeHandler(GUI.exitLobbyEscapeHandler)

    GUI.connectdialog = UIUtil.ShowInfoDialog(GUI, Strings.TryingToConnect, Strings.AbortConnect, ReturnToMenu)
    -- Prevent the dialog from being closed due to user action.
    GUI.connectdialog.OnEscapePressed = function() end
    GUI.connectdialog.OnShadowClicked = function() end

    InitLobbyComm(protocol, localPort, desiredPlayerName, localPlayerUID, natTraversalProvider)

    -- Store off the validated playername
    localPlayerName = lobbyComm:GetLocalPlayerName()
    local Prefs = import("/lua/user/prefs.lua")
    local windowed = Prefs.GetFromCurrentProfile('WindowedLobby') or 'false'
    SetWindowedLobby(windowed == 'true')
    SyncModuleDeps()

end

-- A map from message types to functions that process particular message types.
local MESSAGE_HANDLERS = {
    -- TODO: Finalise signature and semantics.
    ConnectivityState = function()
    end
}

--- Handle an incoming message from the FAF client via the GPGNet protocol.
--
-- @param jsonBlob A JSON string containing the message to process.
-- Messages are JSON strings containing two fields:
-- command_id: A string identifying the type of message. This string is used as a key into
--             MESSAGE_HANDLERS to find the function to use to process this message.
-- arguments: An array of arguments that should be passed to the handler function.
function HandleGPGNetMessage(jsonBlob)
    local jsonObj = JSON.decode(jsonBlob)
    table.print(jsonObj)
    local handler = MESSAGE_HANDLERS[jsonObj.command_id]
    if not handler then
        WARN("Incomprehensible JSON message: \n" .. jsonBlob)
        return
    end

    handler(unpack(jsonObj.arguments))
end

--- Start a synchronous replay session
--
-- @param replayID The ID of the replay to download and play.
function StartSyncReplaySession(replayID)
    SetFrontEndData('syncreplayid', replayID)
    local dl = UIUtil.QuickDialog(GetFrame(0), "Downloading the replay file...")
    LaunchReplaySession('gpgnet://' .. GetCommandLineArg('/gpgnet',1)[1] .. '/' .. import("/lua/user/prefs.lua").GetFromCurrentProfile('Name'))
    dl:Destroy()
    UIUtil.QuickDialog(GetFrame(0), "You dont have this map.", "Exit", function() ExitApplication() end)
end

--- Create a new unconnected lobby/Entry point for processing messages sent from the FAF lobby.
--
-- This function is called exactly once by the game when a new lobby should be created.
-- @see ReallyCreateLobby
--
-- This function is called whenever the FAF lobby sends a message into the game, with the message
-- in the desiredPlayerName parameter as a JSON string with a length no greater than 4061 bytes.
-- This madness is justified by this being one of the smallish number of functions we can have
-- called from outside.
-- @see HandleGPGNetMessage
--
-- This function is also called by the sync replay server when a session should be started. (this
-- should probably be refactored to use the JSON messenger protocol)
-- @see StartSyncReplaySession
function CreateLobby(protocol, localPort, desiredPlayerName, localPlayerUID, natTraversalProvider, over, exitBehavior, playerHasSupcom)
    -- Is this an incoming GPGNet message?
    if localPort == -1 then
        HandleGPGNetMessage(desiredPlayerName)
        return
    end

    -- Special-casing for sync-replay.
    -- TODO: Consider replacing this with a gpgnet message type.
    if IsSyncReplayServer then
        StartSyncReplaySession(localPlayerUID)
        return
    end

    -- Okay, so we actually are creating a lobby, instead of doing some ridiculous hack.
    ReallyCreateLobby(protocol, localPort, desiredPlayerName, localPlayerUID, natTraversalProvider, over, exitBehavior, playerHasSupcom)
end

-- create the lobby as a host
function HostGame(desiredGameName, scenarioFileName, inSinglePlayer)
    singlePlayer = inSinglePlayer
    gameName = lobbyComm:MakeValidGameName(desiredGameName)
    lobbyComm.desiredScenario = string.gsub(scenarioFileName, ".v%d%d%d%d_scenario.lua", "_scenario.lua")
    lobbyComm:HostGame()
end

-- join an already existing lobby
function JoinGame(address, asObserver, playerName, uid)
    lobbyComm:JoinGame(address, playerName, uid)
end

function ConnectToPeer(addressAndPort,name,uid)
    if not string.find(addressAndPort, '127.0.0.1') then
        LOG("ConnectToPeer (name=" .. name .. ", uid=" .. uid .. ", address=" .. addressAndPort ..")")
    else
        DisconnectFromPeer(uid)
        LOG("ConnectToPeer (name=" .. name .. ", uid=" .. uid .. ", address=" .. addressAndPort ..", USE PROXY)")
        table.insert(ConnectedWithProxy, uid)
    end
    lobbyComm:ConnectToPeer(addressAndPort,name,uid)
end

function DisconnectFromPeer(uid)
    LOG("DisconnectFromPeer (uid=" .. uid ..")")
    if PingUtils.wasConnected(uid) then
        table.remove(connectedTo, uid)
    end
    GpgNetSend('Disconnected', string.format("%d", uid))
    lobbyComm:DisconnectFromPeer(uid)
end

function SetHasSupcom(cmd)
    -- TODO: Refactor SyncReplayServer gubbins to use generalised JSON protocol.
    if IsSyncReplayServer then
        if cmd == 0 then
            SessionResume()
        elseif cmd == 1 then
            SessionRequestPause()
        end
    end
end

function SetHasForgedAlliance(speed)
    if IsSyncReplayServer then
        if GetGameSpeed() ~= speed then
            SetGameSpeed(speed)
        end
    end
end

-- TODO: These functions are dumb. We have these things called "hashmaps".
function FindSlotForID(id)
    for k, player in gameInfo.PlayerOptions:pairs() do
        if player.OwnerID == id and player.Human then
            return k
        end
    end
    return nil
end

function FindRehostSlotForID(id)
    for index, player in ipairs(rehostPlayerOptions) do
        if player.OwnerID == id and player.Human then
            return player.StartSpot
        end
    end
    return nil
end

function FindNameForID(id)
    if (IsObserver(id)) then
        return (FindObserverNameForID(id))
    end

    for k, player in gameInfo.PlayerOptions:pairs() do
        if player.OwnerID == id and player.Human then
            return player.PlayerName
        end
    end
    return nil
end

function FindIDForName(name)
    for k, player in gameInfo.PlayerOptions:pairs() do
        if player.PlayerName == name and player.Human then
            return player.OwnerID
        end
    end
    return nil
end

function FindObserverSlotForID(id)
    for k, observer in gameInfo.Observers:pairs() do
        if observer.OwnerID == id then
            return k
        end
    end

    return nil
end

function FindObserverNameForID(id)
    for k, observer in gameInfo.Observers:pairs() do
        if observer.OwnerID == id then
            return observer.PlayerName
        end
    end
    return nil
end

function IsLocallyOwned(slot)
    return gameInfo.PlayerOptions[slot].OwnerID == localPlayerID
end

function IsPlayer(id)
    return FindSlotForID(id) ~= nil
end

function IsObserver(id)
    return FindObserverSlotForID(id) ~= nil
end

function UpdateSlotBackground(slotIndex)
    if gameInfo.ClosedSlots[slotIndex] then
        GUI.slots[slotIndex].SlotBackground:SetTexture(UIUtil.UIFile('/SLOT/slot-dis.dds'))
    else
        if gameInfo.PlayerOptions[slotIndex] then
            GUI.slots[slotIndex].SlotBackground:SetTexture(UIUtil.UIFile('/SLOT/slot-player.dds'))
        else
            GUI.slots[slotIndex].SlotBackground:SetTexture(UIUtil.UIFile('/SLOT/slot-player_other.dds'))
        end
    end
end

function GetPlayerDisplayName(playerInfo)
    local playerName = playerInfo.PlayerName
    local displayName = ""
    if playerInfo.PlayerClan ~= "" then
        return string.format("[%s] %s", playerInfo.PlayerClan, playerInfo.PlayerName)
    else
        return playerInfo.PlayerName
    end
end

-- Refresh (with a sledgehammer) all the items in the observer list.
local function refreshObserverList()
    GUI.observerList:DeleteAllItems()

    -- create the table that will hold the data for displaying team rating information
    local teamRatings = {}
    local numTeams = 0
    -- calculate/display team ratings if spawns are fixed
    if gameInfo.GameOptions['TeamSpawn'] == 'fixed' then

        -- cycle through each player
        for i, player in gameInfo.PlayerOptions:pairs() do

            -- get the team number (which is 1 higher on the backend)
            local team = player.Team - 1
            -- add the player's rating information if the player is on a team
            if team > 0 then
                -- make sure the team is included in the teamRatings table
                if teamRatings[team] == nil  then
                    -- initialize the team's rating in this table as having 0 mean and 0 deviation, respectively
                    teamRatings[team] = {0, 0}
                end
                -- add the player's rating information (mean and deviation) to the its team's totals
                teamRatings[team] = {teamRatings[team][1] + player.MEAN, teamRatings[team][2] + player.DEV}
            end
        end

        for i, team in teamRatings do
            numTeams = numTeams + 1
        end

        -- if there are 1 or 2 teams, list them before observers
        if numTeams == 1 or numTeams == 2 then
            if not lobbyComm:IsHost() then
                GUI.observerList:AddItem(LOC('<LOC lobui_0702>Team Ratings:'))
            end
            for i, rating in teamRatings do
                GUI.observerList:AddItem(
                    LOCF('<LOC lobui_0703>Team %d: %d (%d+/-%d)', i, math.round(rating[1] - rating[2] * 3), math.round(rating[1]), math.round(rating[2] * 3))
                )
            end
            if not lobbyComm:IsHost() then
                GUI.observerList:AddItem('')
            end
        end
    end


    local observers = false

    for slot, observer in gameInfo.Observers:pairs() do

        if not observers then
           observers = true
            if not lobbyComm:IsHost() then
                GUI.observerList:AddItem(LOC('<LOC lobui_0275>Observers')..':')
            end
        end

        observer.ObserverListIndex = GUI.observerList:GetItemCount() -- Pin-head William made this zero-based

        -- Create a label for this observer of the form:
        -- PlayerName (R:xxx, P:xxx, C:xxx)
        -- Such conciseness is necessary as the field in the UI is rather narrow...
        local observer_label = observer.PlayerName .. " (R:" .. observer.PL

        -- Add the ping only if this entry refers to a different client.
        if observer and (observer.OwnerID ~= localPlayerID) and observer.ObserverListIndex then
            local peer = lobbyComm:GetPeer(observer.OwnerID)

            local ping = 0
            if peer.ping ~= nil then
                ping = math.floor(peer.ping)
            end

            observer_label = observer_label .. ", P:" .. ping
        end

        -- Add the CPU score if one is available.
        local score_CPU = CPU_Benchmarks[observer.PlayerName]
        if score_CPU then
            observer_label = observer_label .. ", C:" .. score_CPU
        end
        observer_label = observer_label .. ")"

        GUI.observerList:AddItem(observer_label)
    end

    -- if there are more than 2 teams (and slots are fixed), list them after observers
    if numTeams > 2 then
        if not lobbyComm:IsHost() then
            GUI.observerList:AddItem('')
            GUI.observerList:AddItem(LOC('<LOC lobui_0702>Team Ratings:'))
        end
        for i, rating in teamRatings do
            GUI.observerList:AddItem(
                LOCF('<LOC lobui_0703>Team %d: %d (%d+/-%d)', i, math.round(rating[1] - rating[2] * 3), math.round(rating[1]), math.round(rating[2] * 3))
            )
        end
    end
end

--- Pushes the current lobby state into the extracted Autobalance/CPUBenchmark
--- modules.
---
--- Why this exists: gameInfo, GUI, lobbyComm, localPlayerID, localPlayerName,
--- and HostUtils are all *reassigned* (not just mutated in place) at several
--- points in this file. Autobalance.lua/cpubenchmark.lua captured their own
--- copies of these values via Init(), so they no longer share lobby.lua's
--- upvalues directly -- reassigning a local here does NOT automatically
--- update the module's view of it like it did before the extraction. Call
--- this function after any such reassignment to keep the modules in sync.
-- Notify the server when the lobby has no empty, non-closed slots left.
-- (Restored from the original lobby.lua; it was lost during module extraction.)
function PossiblyAnnounceGameFull()
    -- Search for an empty non-closed slot.
    for i = 1, numOpenSlots do
        if not gameInfo.ClosedSlots[i] then
            if not gameInfo.PlayerOptions[i] then
                return
            end
        end
    end

    -- Game is full, let's tell the client.
    GpgNetSend("GameFull")
end

-- SyncModuleDeps is split into one wrapper per module: a single function that
-- referenced every injected local would exceed SupCom Lua's 32-upvalue limit.
local function _syncCPUBenchmark()
    CPUBenchmark.Init{
        GUI                   = GUI,
        lobbyComm             = lobbyComm,
        localPlayerName       = localPlayerName,
        localPlayerID         = localPlayerID,
        gameInfo              = gameInfo,
        CPU_Benchmarks        = CPU_Benchmarks,
        FindIDForName         = FindIDForName,
        FindSlotForID         = FindSlotForID,
        FindObserverSlotForID = FindObserverSlotForID,
        refreshObserverList   = refreshObserverList,
    }
end

local function _syncAIUtils()
    AIUtils.Init{
        gameInfo          = gameInfo,
        MapUtil           = MapUtil,
        LobbyComm         = LobbyComm,
        hostID            = hostID,
        PlayerData        = PlayerData,
        IsColorFree       = IsColorFree,
        GetAvailableColor = GetAvailableColor,
    }
end

local function _syncMapUtils()
    MapUtils.Init{
        gameInfo                = gameInfo,
        lobbyComm               = lobbyComm,
        hostID                  = hostID,
        localPlayerID           = localPlayerID,
        GUI                     = GUI,
        MapUtil                 = MapUtil,
        HostUtils               = HostUtils,
        FindSlotForID           = FindSlotForID,
        FindObserverSlotForID   = FindObserverSlotForID,
        IsPlayer                = IsPlayer,
        IsObserver              = IsObserver,
        GetSanitisedLastFaction = GetSanitisedLastFaction,
        DoSlotBehavior          = DoSlotBehavior,
        SetSlotInfo             = SetSlotInfo,
        UpdateGame              = UpdateGame,
        GetLrgMap               = function() return LrgMap end,
    }
end

local function _syncLaunchLogic()
    LaunchLogic.Init{
        gameInfo                          = gameInfo,
        GUI                               = GUI,
        lobbyComm                         = lobbyComm,
        hostID                            = hostID,
        localPlayerID                     = localPlayerID,
        singlePlayer                      = singlePlayer,
        MapUtil                           = MapUtil,
        UIUtil                            = UIUtil,
        LobbyComm                         = LobbyComm,
        Prefs                             = Prefs,
        Tooltip                           = Tooltip,
        Mods                              = Mods,
        Presets                           = Presets,
        GameInfo                          = GameInfo,
        utils                             = utils,
        Autobalance                       = Autobalance,
        AIUtils                           = AIUtils,
        MapUtils                          = MapUtils,
        HostUtils                         = HostUtils,
        FACTION_NAMES                     = FACTION_NAMES,
        GetPlayersNotReady                = GetPlayersNotReady,
        AddChatText                       = AddChatText,
        EveryoneHasEstablishedConnections = PingUtils.EveryoneHasEstablishedConnections,
        IsObserver                        = IsObserver,
        FindSlotForID                     = FindSlotForID,
        UpdateFactionSelector             = UpdateFactionSelector,
        GetPlayerCount                    = GetPlayerCount,
        UpdateAvailableSlots              = UpdateAvailableSlots,
        UpdateSlotBackground              = UpdateSlotBackground,
        SetSlotInfo                       = SetSlotInfo,
        ClearSlotInfo                     = ClearSlotInfo,
        RefreshOptionDisplayData          = OptionsDialog.RefreshOptionDisplayData,
        RefreshLobbyBackground            = RefreshLobbyBackground,
        RefreshLargeMap                   = RefreshLargeMap,
        SetRuleTitleText                  = SetRuleTitleText,
        SetGameTitleText                  = SetGameTitleText,
        AssignRandomFactions              = AssignRandomFactions,
        FixFactionIndexes                 = FixFactionIndexes,
        autoMap                           = autoMap,
        SetWindowedLobby                  = SetWindowedLobby,
        SetGameInfo                       = function(gi) gameInfo = gi; SyncModuleDeps() end,
        SetNumberOfPlayers                = function(n) numberOfPlayers = n end,
        SetAutoRandMap                    = function(b) autoRandMap = b end,
    }
end

local function _syncPingUtils()
    PingUtils.Init{
        lobbyComm             = lobbyComm,
        gameInfo              = gameInfo,
        GUI                   = GUI,
        localPlayerID         = localPlayerID,
        FindSlotForID         = FindSlotForID,
        GetPlayerDisplayName  = GetPlayerDisplayName,
        IsLocallyOwned        = IsLocallyOwned,
        AddChatText           = AddChatText,
        Tooltip               = Tooltip,
        connectedTo           = connectedTo,
        CurrentConnection     = CurrentConnection,
        ConnectionEstablished = ConnectionEstablished,
    }
end

local function _syncOptionsDialog()
    OptionsDialog.Init{
        gameInfo               = gameInfo,
        GUI                    = GUI,
        MapUtil                = MapUtil,
        Mods                   = Mods,
        singlePlayer           = singlePlayer,
        AddChatText            = AddChatText,
        Group                  = Group,
        Popup                  = Popup,
        LayoutHelpers          = LayoutHelpers,
        UIUtil                 = UIUtil,
        Prefs                  = Prefs,
        RadioButton            = RadioButton,
        Slider                 = Slider,
        Tooltip                = Tooltip,
        RefreshLobbyBackground = RefreshLobbyBackground,
        SetWindowedLobby       = SetWindowedLobby,
        defaultMode            = defaultMode,
    }
end

local function _syncAutobalance()
    Autobalance.Init{
        gameInfo              = gameInfo,
        GUI                   = GUI,
        LobbyComm             = LobbyComm,
        SetPlayerOption       = SetPlayerOption,
        SetSlotInfo           = SetSlotInfo,
        GetNumAvailStartSpots = GetNumAvailStartSpots,
        HostUtils             = HostUtils,
        Trueskill             = Trueskill,
        Player                = Player,
        Rating                = Rating,
        Teams                 = Teams,
        FactionData           = FactionData,
    }
end


function UpdateClientModStatus(newHostSimMods)
    -- Apply the new game mods from the host, but don't touch our UI mod configuration.
    selectedSimMods = newHostSimMods

    -- Make sure none of our selected UI mods are blacklisted
    local bannedMods = CheckModCompatability()
    if not table.empty(bannedMods) then
        WarnIncompatibleMods()
        selectedUIMods = SetUtils.Subtract(selectedUIMods, bannedMods)
    end

    Mods.SetSelectedMods(SetUtils.Union(selectedSimMods, selectedUIMods))
end

function SendCompleteGameStateToPeer(peerId)
    lobbyComm:SendData(peerId, {
        Type = 'GameInfo',
        GameInfo = GameInfo.Flatten(gameInfo)
    })
end

local function _syncMessageHandlers()
    MessageHandlers.Init{
        gameInfo                       = gameInfo,
        lobbyComm                      = lobbyComm,
        hostID                         = hostID,
        localPlayerID                  = localPlayerID,
        localPlayerName                = localPlayerName,
        singlePlayer                   = singlePlayer,
        GUI                            = GUI,
        CPU_Benchmarks                 = CPU_Benchmarks,
        HostUtils                      = HostUtils,
        Autobalance                    = Autobalance,
        CPUBenchmark                   = CPUBenchmark,
        Mods                           = Mods,
        Presets                        = Presets,
        SetUtils                       = SetUtils,
        FACTION_NAMES                  = FACTION_NAMES,
        PlayerData                     = PlayerData,
        GameInfo                       = GameInfo,
        LobbyComm                      = LobbyComm,
        WatchedValueArray              = WatchedValueArray,
        UIUtil                         = UIUtil,
        FindIDForName                  = FindIDForName,
        FindNameForID                  = FindNameForID,
        FindSlotForID                  = FindSlotForID,
        FindObserverSlotForID          = FindObserverSlotForID,
        IsPlayer                       = IsPlayer,
        IsObserver                     = IsObserver,
        IsLocallyOwned                 = IsLocallyOwned,
        IsColorFree                    = IsColorFree,
        GetAvailableColor              = GetAvailableColor,
        SetPlayerColor                 = SetPlayerColor,
        SetSlotInfo                    = SetSlotInfo,
        ClearSlotInfo                  = ClearSlotInfo,
        UpdateGame                     = UpdateGame,
        UpdateFactionSelectorForPlayer = UpdateFactionSelectorForPlayer,
        UpdateClientModStatus          = UpdateClientModStatus,
        EnableSlot                     = EnableSlot,
        SetPlayerOption                = SetPlayerOption,
        AddChatText                    = AddChatText,
        SendSystemMessage              = SendSystemMessage,
        SendPersonalSystemMessage      = SendPersonalSystemMessage,
        SendCompleteGameStateToPeer    = SendCompleteGameStateToPeer,
        PossiblyAnnounceGameFull       = PossiblyAnnounceGameFull,
        DoSlotSwap                     = DoSlotSwap,
        refreshObserverList            = refreshObserverList,
        SetWindowedLobby               = SetWindowedLobby,
        SyncModuleDeps                 = SyncModuleDeps,
    }
end

local function _syncChatHandler()
    ChatHandler.Init{
        GUI                = GUI,
        lobbyComm          = lobbyComm,
        gameInfo           = gameInfo,
        localPlayerID      = localPlayerID,
        FACTION_NAMES      = FACTION_NAMES,
        GetLocalPlayerData = GetLocalPlayerData,
        FindNameForID      = FindNameForID,
        FindIDForName      = FindIDForName,
    }
end

-- HostUtils sync (nur relevant wenn lobbyComm:IsHost())
local function _syncHostUtils()
    if HostUtils then
        HostUtils_Module.Init{
            gameInfo                       = gameInfo,
            lobbyComm                      = lobbyComm,
            hostID                         = hostID,
            localPlayerID                  = localPlayerID,
            localPlayerName                = localPlayerName,
            singlePlayer                   = singlePlayer,
            numOpenSlots                   = numOpenSlots,
            GUI                            = GUI,
            CPU_Benchmarks                 = CPU_Benchmarks,
            selectedSimMods                = selectedSimMods,
            selectedUIMods                 = selectedUIMods,
            availableMods                  = availableMods,
            UIUtil                         = UIUtil,
            Mods                           = Mods,
            SetUtils                       = SetUtils,
            ModBlacklist                   = ModBlacklist,
            LobbyComm                      = LobbyComm,
            WatchedValueArray              = WatchedValueArray,
            Autobalance                    = Autobalance,
            FindSlotForID                  = FindSlotForID,
            FindObserverSlotForID          = FindObserverSlotForID,
            FindNameForID                  = FindNameForID,
            IsLocallyOwned                 = IsLocallyOwned,
            IsColorFree                    = IsColorFree,
            GetAvailableColor              = GetAvailableColor,
            SetPlayerColor                 = SetPlayerColor,
            SetSlotInfo                    = SetSlotInfo,
            ClearSlotInfo                  = ClearSlotInfo,
            UpdateGame                     = UpdateGame,
            UpdateFactionSelectorForPlayer = UpdateFactionSelectorForPlayer,
            EnableSlot                     = EnableSlot,
            SetPlayerOption                = SetPlayerOption,
            GetPlayersNotReady             = GetPlayersNotReady,
            IsObserver                     = IsObserver,
            AddChatText                    = AddChatText,
            SendSystemMessage              = SendSystemMessage,
            SendPersonalSystemMessage      = SendPersonalSystemMessage,
            PossiblyAnnounceGameFull       = PossiblyAnnounceGameFull,
            GetAIPlayerData                = AIUtils.GetAIPlayerData,
            PrivateChat                    = PrivateChat,
            DoSlotSwap                     = DoSlotSwap,
            KeepSameFactionOrRandom        = KeepSameFactionOrRandom,
            refreshObserverList            = refreshObserverList,
            OnModsChanged                  = OnModsChanged,
            CheckModCompatability          = CheckModCompatability,
            WarnIncompatibleMods           = WarnIncompatibleMods,
            SendPlayerOption               = SendPlayerOption,
        }
    end
end

function SetPlayerOptions(slot, options, ignoreRefresh)
    if not IsLocallyOwned(slot) and not lobbyComm:IsHost() then
        WARN("Hey you can't set a player option on a slot you don't own:")
        for key, val in options do
            WARN("(slot:"..tostring(slot).." / key:"..tostring(key).." / val:"..tostring(val)..")")
        end
        return
    end

    for key, val in options do
        gameInfo.PlayerOptions[slot][key] = val
    end

    lobbyComm:BroadcastData(
    {
        Type = 'PlayerOptions',
        Options = options,
        Slot = slot,
    })

    if not ignoreRefresh then
        UpdateGame()
    end
end

function SetPlayerOption(slot, key, val, ignoreRefresh)
    local options = {}
    options[key] = val
    SetPlayerOptions(slot, options, ignoreRefresh)
    refreshObserverList()
end

function SetGameOptions(options, ignoreRefresh)
    if not lobbyComm:IsHost() then
        WARN('Attempt to set game option by a non-host')
        return
    end

    for key, val in options do
        Prefs.SetToCurrentProfile('LobbyOpt_' .. key, val)
        gameInfo.GameOptions[key] = val

        -- don't want to send all restricted categories to gpgnet, so just send bool
        -- note if more things need to be translated to gpgnet, a translation table would be a better implementation
        -- but since there's only one, we'll call it out here
        if key == 'RestrictedCategories' then
            local restrictionsEnabled = false
            if val ~= nil then
                if not table.empty(val) then
                    restrictionsEnabled = true
                end
            end
            GpgNetSend('GameOption', key, restrictionsEnabled)
        elseif key == 'ScenarioFile' then
            -- Special-snowflake the LastScenario key (used by GPG code).
            Prefs.SetToCurrentProfile('LastScenario', val)
            GpgNetSend('GameOption', key, val)
            if gameInfo.GameOptions.ScenarioFile and (gameInfo.GameOptions.ScenarioFile ~= '') then
                -- Warn about attempts to load nonexistent maps.
                if not DiskGetFileInfo(gameInfo.GameOptions.ScenarioFile) then
                    AddChatText(LOC('<LOC lobui_0399>The selected map does not exist.'))
                else
                    local scenarioInfo = MapUtil.LoadScenario(gameInfo.GameOptions.ScenarioFile)
                    if scenarioInfo and scenarioInfo.map and (scenarioInfo.map ~= '') then
                        GpgNetSend('GameOption', 'Slots', table.getsize(scenarioInfo.Configurations.standard.teams[1].armies))
                    end
                end
            end
        else
            GpgNetSend('GameOption', key, val)
        end
    end

    lobbyComm:BroadcastData {
        Type = 'GameOptions',
        Options = options
    }

    if not ignoreRefresh then
        UpdateGame()
    end
end

function SetGameOption(key, val, ignoreRefresh)
    local options = {}
    options[key] = val
    SetGameOptions(options, ignoreRefresh)
end

-- createui.lua references lobby's state and helpers as plain globals; push them
-- into its environment. Functions that are lobby globals (UpdateGame, SetSlotInfo,
-- ...) resolve at call time so they are not upvalues here; only lobby locals
-- (state, DoSlotBehavior, imported modules) and the sibling-module functions
-- count against the upvalue budget.
local function _syncCreateUI()
    CreateUI_Module.Init{
        -- mutable lobby state
        GUI                      = GUI,
        lobbyComm                = lobbyComm,
        gameInfo                 = gameInfo,
        localPlayerID            = localPlayerID,
        localPlayerName          = localPlayerName,
        singlePlayer             = singlePlayer,
        FACTION_NAMES            = FACTION_NAMES,
        numOpenSlots             = numOpenSlots,
        hostID                   = hostID,
        availableMods            = availableMods,
        argv                     = argv,
        HostUtils                = HostUtils,
        -- lobby-local helpers / tables
        DoSlotBehavior           = DoSlotBehavior,
        OptionUtils              = OptionUtils,
        gameColors               = gameColors,
        SetUtils                 = SetUtils,
        MapUtil                  = MapUtil,
        Autobalance              = Autobalance,
        -- lobby global helpers
        UpdateGame               = UpdateGame,
        SetPlayerOption          = SetPlayerOption,
        SetPlayerColor           = SetPlayerColor,
        SetSlotInfo              = SetSlotInfo,
        SetGameOption            = SetGameOption,
        SetGameOptions           = SetGameOptions,
        FindSlotForID            = FindSlotForID,
        FindIDForName            = FindIDForName,
        FindObserverSlotForID    = FindObserverSlotForID,
        IsPlayer                 = IsPlayer,
        IsObserver               = IsObserver,
        IsColorFree              = IsColorFree,
        GetPlayerCount           = GetPlayerCount,
        GetSlotFactionIndex      = GetSlotFactionIndex,
        GetSanitisedLastFaction  = GetSanitisedLastFaction,
        GetNumAvailStartSpots    = GetNumAvailStartSpots,
        EnableSlot               = EnableSlot,
        DisableSlot              = DisableSlot,
        ClearBadMapFlags         = ClearBadMapFlags,
        AddChatText              = AddChatText,
        SendSystemMessage        = SendSystemMessage,
        ShowTitleDialog          = ShowTitleDialog,
        ShowRuleDialog           = ShowRuleDialog,
        RefreshLobbyBackground   = RefreshLobbyBackground,
        CreateBigPreview         = CreateBigPreview,
        OnModsChanged            = OnModsChanged,
        teamIcons                = teamIcons,
        -- AI dropdown data (computed by AIUtils)
        AIKeys                   = AIUtils.GetKeys(),
        AIStrings                = AIUtils.GetStrings(),
        AITooltips               = AIUtils.GetTooltips(),
        -- helpers that live in sibling modules
        RefreshOptionDisplayData = OptionsDialog.RefreshOptionDisplayData,
        ShowLobbyOptionsDialog   = OptionsDialog.ShowLobbyOptionsDialog,
        GetFormattedOptions      = OptionsDialog.GetFormattedOptions,
        GetNonDefaultFormattedOptions = OptionsDialog.GetNonDefaultFormattedOptions,
        setupChatEdit            = ChatHandler.setupChatEdit,
        TryLaunch                = LaunchLogic.TryLaunch,
        Ping_AddControlTooltip   = PingUtils.Ping_AddControlTooltip,
        CalcConnectionStatus     = PingUtils.CalcConnectionStatus,
        -- allAvailableFactionsList is shared with lobby.lua: write through to its
        -- global (createui populates it, lobby reads it) instead of letting each
        -- side keep a divergent copy.
        SetAllAvailableFactionsList = function(v) allAvailableFactionsList = v end,
        GetAllAvailableFactionsList = function() return allAvailableFactionsList end,
    }
end

function SyncModuleDeps()
    _syncCPUBenchmark()
    _syncAIUtils()
    _syncMapUtils()
    _syncLaunchLogic()
    _syncPingUtils()
    _syncOptionsDialog()
    _syncAutobalance()
    _syncMessageHandlers()
    _syncChatHandler()
    _syncHostUtils()
    _syncCreateUI()
end

local WVT = import("/lua/ui/lobby/data/watchedvalue/watchedvaluetable.lua")

-- update the data in a player slot
-- TODO: With lazyvars, this function should be eliminated. Lazy-value-callbacks should be used
-- instead to incrementaly update things.
function SetSlotInfo(slotNum, playerInfo)
    -- Remove the ConnectDialog. It probably makes more sense to do this when we get the game state.
    if GUI.connectdialog then
        GUI.connectdialog:Close()
        GUI.connectdialog = nil

        -- ChangelogDialog, if necessary.
        local changelogDialogManager = import("/lua/ui/lobby/changelog/changelogdialog.lua")
        if changelogDialogManager.ShouldOpenChangelog() then
            changelogDialogManager.CreateChangelogDialog(GetFrame(0))
        end
    end

    playerInfo.StartSpot = slotNum

    local slot = GUI.slots[slotNum]
    local isHost = lobbyComm:IsHost()
    local isLocallyOwned = IsLocallyOwned(slotNum)

    -- Set enabledness of controls according to host privelage etc.
    -- Yeah, we set it twice. No, it's not brilliant. Blurgh.
    local facColEnabled = isLocallyOwned or (isHost and not playerInfo.Human)
    UIUtil.setEnabled(slot.faction, facColEnabled)
    UIUtil.setEnabled(slot.color, facColEnabled)

    -- Possibly override it due to the ready box.
    if isLocallyOwned then
        if playerInfo.Ready and playerInfo.Human then
            DisableSlot(slotNum, true)
        else
            EnableSlot(slotNum)
        end
    else
        DisableSlot(slotNum)
    end

    --- Returns true if the team selector for this slot should be enabled.
    --
    -- The predicate was getting unpleasantly long to read.
    local function teamSelectionEnabled(autoTeams, ready, locallyOwned, isHost)
        -- If autoteams has control, no selector for you.
        if autoTeams ~= 'none' then
            return false
        end

        if isHost and not playerInfo.Human then
            return true
        end

        -- You can control your own one when you're not ready.
        if locallyOwned then
            return not ready
        end

        if isHost then
            -- The host can control the team of others, provided he's not ready himself.
            local slot = FindSlotForID(localPlayerID)
            local is_ready = slot and gameInfo.PlayerOptions[slot].Ready -- could be observer

            return not is_ready
        end
    end

    -- Disable team selection if "auto teams" is controlling it. Moderatelty ick.
    local autoTeams = gameInfo.GameOptions.AutoTeams
    UIUtil.setEnabled(slot.team, teamSelectionEnabled(autoTeams, playerInfo.Ready, isLocallyOwned, isHost))

    local hostKey
    if isHost then
        hostKey = 'host'
    else
        hostKey = 'client'
    end

    -- These states are used to select the appropriate strings with GetSlotMenuTables.
    local slotState
    if not playerInfo.Human then
        slot.ratingText:Hide()
        slotState = 'ai'
    elseif not isLocallyOwned then
        slotState = 'player'
    else
        slotState = nil
    end

    slot.name:ClearItems()

    if slotState then
        slot.name:Enable()
        local slotKeys, slotStrings, slotTooltips = GetSlotMenuTables(slotState, hostKey, slotNum)
        slot.name.slotKeys = slotKeys

        if not table.empty(slotKeys) then
            slot.name:AddItems(slotStrings)
            slot.name:Enable()
            Tooltip.AddComboTooltip(slot.name, slotTooltips)
        else
            slot.name.slotKeys = nil
            slot.name:Disable()
            Tooltip.RemoveComboTooltip(slot.name)
        end
    else
        -- no slotState indicate this must be ourself, and you can't do anything to yourself
        slot.name.slotKeys = nil
        slot.name:Disable()
    end

    slot.ratingText:Show()
    slot.ratingText:SetText(playerInfo.PL)
    slot.ratingText:SetColor("ffffffff")

    -- dynamic tooltip to show rating and deviation for each player
    local tooltipText = {}
    tooltipText['text'] = LOC("<LOC lobui_0750>Rating")
    tooltipText['body'] = LOCF("<LOC lobui_0768>%s's TrueSkill Rating is %s +/- %s", playerInfo.PlayerName, math.round(playerInfo.MEAN), math.ceil(playerInfo.DEV * 3))
    slot.tooltiprating = Tooltip.AddControlTooltip(slot.ratingText, tooltipText)

    slot.numGamesText:Show()
    slot.numGamesText:SetText(playerInfo.NG)

    slot.name:Show()
    -- Change name colour according to the state of the slot.
    if slotState == 'ai' then
        slot.name:SetTitleTextColor("dbdbb9") -- Beige Color for AI
        slot.name._text:SetFont('Arial Gras', 12)
    elseif FindSlotForID(hostID) == slotNum then
        slot.name:SetTitleTextColor("ffc726") -- Orange Color for Host
        slot.name._text:SetFont('Arial Gras', 15)
    elseif slotState == 'player' then
        slot.name:SetTitleTextColor("64d264") -- Green Color for Players
        slot.name._text:SetFont('Arial Gras', 15)
    elseif isLocallyOwned then
        slot.name:SetTitleTextColor("6363d2") -- Blue Color for You
        slot.name._text:SetFont('Arial Gras', 15)
    else
        slot.name:SetTitleTextColor(UIUtil.fontColor) -- Normal Color for Other
        slot.name._text:SetFont('Arial Gras', 12)
    end

    local playerName = playerInfo.PlayerName
    if PingUtils.wasConnected(playerInfo.OwnerID) or isLocallyOwned or not playerInfo.Human then
        slot.name:SetTitleText(GetPlayerDisplayName(playerInfo))
        slot.name._text:SetFont('Arial Gras', 15)
        if not table.find(ConnectionEstablished, playerName) then
            if playerInfo.Human and not isLocallyOwned then
                AddChatText(LOCF("<LOC Engine0004>Connection to %s established.", playerName))

                table.insert(ConnectionEstablished, playerName)
                for k, v in CurrentConnection do
                    if v == playerName then
                        CurrentConnection[k] = nil
                        break
                    end
                end
            end
        end
    else
        slot.name:SetTitleText(LOCF('<LOC Engine0005>Connecting to %s...', playerName))
        slot.name._text:SetFont('Arial Gras', 11)
    end

    slot.faction:Show()

    -- Check if faction is possible for that slot, if not set to random
    -- For example: AIs always start with faction 5, so that needs to be adjusted to fit in slot.Faction
    if table.getn(slot.AvailableFactions) < playerInfo.Faction then
        playerInfo.Faction = table.getn(slot.AvailableFactions)
    end
    slot.faction:SetItem(playerInfo.Faction)

    slot.color:Show()
    Check_Availaible_Color(slotNum)

    slot.team:Show()
    slot.team:SetItem(playerInfo.Team)

    -- Send team data to the server
    if isHost then
        HostUtils.SendPlayerSettingsToServer(slotNum)
    end

    UIUtil.setVisible(slot.ready, playerInfo.Human and not singlePlayer)
    slot.ready:SetCheck(playerInfo.Ready, true)

    if isLocallyOwned and playerInfo.Human then
        Prefs.SetToCurrentProfile('LastColorFAF', playerInfo.PlayerColor)
        Prefs.SetToCurrentProfile('LastFaction', playerInfo.Faction)
    end

    -- Show the player's nationality
    if not playerInfo.Country then
        slot.KinderCountry:Hide()
    else
        slot.KinderCountry:Show()
        slot.KinderCountry:SetTexture(UIUtil.UIFile('/countries/'..playerInfo.Country..'.dds'))

        Tooltip.AddControlTooltip(slot.KinderCountry, {text=LOC("<LOC lobui_0413>Country"), body=LOC(CountryTooltips[playerInfo.Country])})
    end

    UpdateSlotBackground(slotNum)

    -- Set the CPU bar
    CPUBenchmark.SetSlotCPUBar(slotNum, playerInfo)

    ShowGameQuality()
    MapUtils.RefreshMapPositionForAllControls(slotNum)

    if isHost then
        HostUtils.RefreshButtonEnabledness()
    end
    refreshObserverList()
end

function ClearSlotInfo(slotIndex)
    local slot = GUI.slots[slotIndex]

    local hostKey
    if lobbyComm:IsHost() then
        GpgNetSend('ClearSlot', slotIndex)
        hostKey = 'host'
    else
        hostKey = 'client'
    end

    local stateKey
    local stateText
    if gameInfo.ClosedSlots[slotIndex] and gameInfo.SpawnMex[slotIndex] and gameInfo.AdaptiveMap then
        stateKey = 'closed_spawn_mex'
        stateText = slotMenuStrings.closed_spawn_mex
    elseif gameInfo.ClosedSlots[slotIndex] then
        gameInfo.SpawnMex[slotIndex] = false
        stateKey = 'closed'
        stateText = slotMenuStrings.closed
    else
        stateKey = 'open'
        stateText = slotMenuStrings.open
    end

    local slotKeys, slotStrings, slotTooltips = GetSlotMenuTables(stateKey, hostKey)

    -- set the text appropriately
    slot.name:ClearItems()
    slot.name:SetTitleText(LOC(stateText))
    if not table.empty(slotKeys) then
        slot.name.slotKeys = slotKeys
        slot.name:AddItems(slotStrings)
        Tooltip.AddComboTooltip(slot.name, slotTooltips)
        slot.name:Enable()
    else
        slot.name.slotKeys = nil
        slot.name:Disable()
        Tooltip.RemoveComboTooltip(slot.name)
    end

    slot.name._text:SetFont('Arial Gras', 12)
    if stateKey == 'closed' then
        slot.name:SetTitleTextColor("Crimson")
    elseif stateKey == 'closed_spawn_mex' then
        slot.name:SetTitleTextColor("2c7f33")
    else
        slot.name:SetTitleTextColor('B9BFB9')
    end

    slot:HideControls()

    UpdateSlotBackground(slotIndex)
    ShowGameQuality()
    MapUtils.RefreshMapPositionForAllControls(slotIndex)
    Check_Availaible_Color()
    refreshObserverList()
end

function IsColorFree(colorIndex, currentSlotNumber)
    for id, player in gameInfo.PlayerOptions:pairs() do
        if player.PlayerColor == colorIndex then
            if currentSlotNumber then
                if player.StartSpot != currentSlotNumber then
                    return false
                end
            else
                return false
            end
        end
    end

    return true
end

function GetPlayerCount()
    local numPlayers = 0
    for k,player in gameInfo.PlayerOptions:pairs() do
        if player then
            numPlayers = numPlayers + 1
        end
    end
    return numPlayers
end

-- Global (not local) so the earlier-defined SyncModuleDeps can capture it for
-- injection into HostUtils / LaunchLogic. A top-level `local function` declared
-- after SyncModuleDeps cannot be seen by it as an upvalue.
function GetPlayersNotReady()
    local notReady = false
    for k,v in gameInfo.PlayerOptions:pairs() do
        if v.Human and not v.Ready then
            if not notReady then
                notReady = {}
            end
            table.insert(notReady, v.PlayerName)
        end
    end

    return notReady
end

local function GetRandomFactionIndex(slotNumber)
    local randomfaction = nil
    local counter = 50
    while counter > 0 do
        counter = (counter - 1)
        randomfaction = math.random(1, table.getn(GUI.slots[slotNumber].AvailableFactions) - 1)
    end
    return randomfaction
end

-- Global so SyncModuleDeps can inject it into LaunchLogic (see GetPlayersNotReady note).
function AssignRandomFactions()
    for index, player in gameInfo.PlayerOptions do
        -- No random if there is only 1 option
        if table.getn(GUI.slots[index].AvailableFactions) >= 2 then
            local randomFactionID = table.getn(GUI.slots[index].AvailableFactions)
            -- note that this doesn't need to be aware if player has supcom or not since they would only be able to select
            -- the random faction ID if they have supcom
            if player.Faction >= randomFactionID then
                player.Faction = GetRandomFactionIndex(index)
            end
        end
    end
end

-- Convert the local (slot dependend) faction indexes to the global faction indexes
-- Global so SyncModuleDeps can inject it into LaunchLogic (see GetPlayersNotReady note).
function FixFactionIndexes()
    for index, player in gameInfo.PlayerOptions do
        local playerFaction = GUI.slots[index].AvailableFactions[player.Faction]
        for i,v in allAvailableFactionsList do
            if v == playerFaction then
                player.Faction = i
                continue
            end
        end
    end

end

-- call this whenever the lobby needs to exit and not go in to the game
function ReturnToMenu(reconnect)
    if lobbyComm then
        lobbyComm:Destroy()
        lobbyComm = false
    end

    local exitfn = GUI.exitBehavior

    GUI:Destroy()
    GUI = false
    SyncModuleDeps()

    if not reconnect then
        exitfn()
    else
        local ipnumber = GetCommandLineArg("/joincustom", 1)[1]
        import("/lua/ui/uimain.lua").StartJoinLobbyUI("UDP", ipnumber, localPlayerName)
    end
end

function PrintSystemMessage(id, parameters)
    AddChatText(LOCF("<LOC "..id..">Unknown system message. Check localisation file", unpack(parameters)))
end

function SendSystemMessage(id, ...)
    local data = {
        Type = "SystemMessage",
        Id = id,
        Args = arg
    }

    lobbyComm:BroadcastData(data)
    PrintSystemMessage(id, arg)
end

function SendPersonalSystemMessage(targetID, id, ...)
    if targetID ~= localPlayerID then
        local data = {
            Type = "SystemMessage",
            Id = id,
            Args = arg
        }

        lobbyComm:SendData(targetID, data)
    end
end

function AddChatText(text, playerID, scrollToBottom)
    ChatHandler.AddChatText(text, playerID, scrollToBottom)
end

function PublicChat(text)
    ChatHandler.PublicChat(text)
end

function PrivateChat(targetID, text)
    ChatHandler.PrivateChat(targetID, text)
end

function UpdateAvailableSlots(numAvailStartSpots, scenario)
    if numAvailStartSpots > LobbyComm.maxPlayerSlots then
        WARN("Lobby requests " .. numAvailStartSpots .. " but there are only " .. LobbyComm.maxPlayerSlots .. " available")
    end

    for i = 1, numAvailStartSpots do
        local availableFactionsForSpotI = FACTION_NAMES
        if scenario.Configurations.standard.factions then
            availableFactionsForSpotI = scenario.Configurations.standard.factions[i]
        end

        local factionBmps = {}
        local factionTooltips = {}
        local factionList = {}
        for index, factionKey in availableFactionsForSpotI do
            for _, tbl in FactionData.Factions do
                if factionKey == tbl.Key then
                    factionBmps[index] = tbl.SmallIcon
                    factionTooltips[index] = tbl.TooltipID
                    factionList[index] = tbl.Key
                    break
                end
            end
        end
        if table.getn(factionBmps) > 1 then
            table.insert(factionBmps, "/faction_icon-sm/random_ico.dds")
            table.insert(factionTooltips, 'lob_random')
            table.insert(factionList, 'random')
        end

        local oldAvailableFactions = GUI.slots[i].AvailableFactions
        GUI.slots[i].AvailableFactions = factionList

        local diff = table.getn(factionList) ~= table.getn(oldAvailableFactions)
        for k = 1,table.getn(factionList) do
            if oldAvailableFactions[k] ~= factionList[k] then
                diff = true
                break
            end
        end
        if not diff then
            continue
        end

        GUI.slots[i].faction:ChangeBitmapArray(factionBmps)
        Tooltip.AddComboTooltip(GUI.slots[i].faction, factionTooltips)

        if gameInfo.PlayerOptions[i] then
            local playerFactionIndex = table.getn(factionList)
            for index,key in factionList do
                if key == oldAvailableFactions[gameInfo.PlayerOptions[i].Faction] then
                    playerFactionIndex = index
                    break
                end
            end
            if FindSlotForID(localPlayerID) == i then
                local fact = factionList[playerFactionIndex]
                for index,value in allAvailableFactionsList do
                    if fact == value then
                        GUI.factionSelector:SetSelected(index)
                        break
                    end
                end
                UpdateFactionSelector()
            else
                GUI.slots[i].faction:SetItem(playerFactionIndex)
                gameInfo.PlayerOptions[i].Faction = playerFactionIndex
            end
        end
    end

    -- if number of available slots has changed, update it
    if gameInfo.firstUpdateAvailableSlotsDone and numOpenSlots == numAvailStartSpots then
        -- Remove closed_spawn_mex if necessary
        if not gameInfo.AdaptiveMap then
            for i = 1, numAvailStartSpots do
                if gameInfo.ClosedSlots[i] and gameInfo.SpawnMex[i] then
                    ClearSlotInfo(i)
                    gameInfo.SpawnMex[i] = nil
                end
            end
        end
        return
    end

    -- reopen slots in case the new map has more startpositions then the previous map.
    if numOpenSlots < numAvailStartSpots then
        for i = numOpenSlots + 1, numAvailStartSpots do
            gameInfo.ClosedSlots[i] = nil
            gameInfo.SpawnMex[i] = nil
            GUI.slots[i]:Show()
            ClearSlotInfo(i)
            DisableSlot(i)
        end
    end
    numOpenSlots = numAvailStartSpots

    for i = 1, numAvailStartSpots do
        if gameInfo.ClosedSlots[i] then
            GUI.slots[i]:Show()
            if not gameInfo.PlayerOptions[i] then
                ClearSlotInfo(i)
            end
            if not gameInfo.PlayerOptions[i].Ready then
                EnableSlot(i)
            end
        end
    end

    for i = numAvailStartSpots + 1, LobbyComm.maxPlayerSlots do
        if lobbyComm:IsHost() and gameInfo.PlayerOptions[i] then
            local info = gameInfo.PlayerOptions[i]
            if info.Human then
                HostUtils.ConvertPlayerToObserver(i)
            else
                HostUtils.RemoveAI(i)
            end
        end
        DisableSlot(i)
        GUI.slots[i]:Hide()
        gameInfo.ClosedSlots[i] = true
        gameInfo.SpawnMex[i] = nil
    end

    gameInfo.firstUpdateAvailableSlotsDone = true
end

-- TryLaunch, AlertHostMapMissing and UpdateGame now live in launchlogic.lua.
-- UpdateGame keeps a thin GLOBAL wrapper here so its many in-file callers and
-- the SyncModuleDeps injections (which capture it by name) stay unchanged.
function UpdateGame()
    return LaunchLogic.UpdateGame()
end

--- Update the game quality display
function ShowGameQuality()
    GUI.GameQualityLabel:SetText("")

    -- Can't compute a game quality for random spawns!
    if gameInfo.GameOptions.TeamSpawn ~= 'fixed' then
        return
    end

    local teams = Teams.create()

    -- Everything catches fire if the teams aren't numbered sequentially from 1.
    -- I hope it is not the case that everything catches fire when there are >2 teams, but in
    -- principle that should work...

    -- Start by creating a map from each *used* team to an element from an ascending set of integers.
    local tsTeam = 1
    local teamMap = {}
    for i = 1, LobbyComm.maxPlayerSlots do
        local playerOptions = gameInfo.PlayerOptions[i]
        -- Team 1 represents "No team", so these people are all singleton teams.
        if playerOptions and (teamMap[playerOptions.Team] == nil or playerOptions.Team == 1) then
            teamMap[playerOptions.Team] = tsTeam
            tsTeam = tsTeam + 1
        end
    end

    -- Now we just use the map to relate real teams to trueSkill teams.
    for i = 1, LobbyComm.maxPlayerSlots do
        local playerOptions = gameInfo.PlayerOptions[i]
        if playerOptions then
            -- Can't do it for AI, either, not sensibly.
            if not playerOptions.Human and (playerOptions.MEAN or 0) == 0 then
                return
            end

            local player = Player.create(
                playerOptions.PlayerName,
                Rating.create(playerOptions.MEAN, playerOptions.DEV)
            )

            teams:addPlayer(teamMap[playerOptions.Team], player)
        end
    end

    -- Rating only meaningful in games with 2 teams
    if table.getsize(teams:getTeams()) ~= 2 then
        return
    end

    local quality = Trueskill.computeQuality(teams)

    if quality > 0 then
        gameInfo.GameOptions.Quality = quality
        GUI.GameQualityLabel:StreamText(LOCF("<LOC lobui_0418>Game quality: %s%%", string.format("%.2f",quality)), 20)
    end
end

-- Holds some utility functions to do with game option management.
-- Global (not local) so _syncCreateUI (defined earlier) can inject it into
-- createui.lua, which calls OptionUtils.SetDefaults().
OptionUtils = {
    -- Set all game options to their default values.
    SetDefaults = function()
        local options = {}
        for index, option in teamOpts do
            options[option.key] = option.values[option.default].key or option.values[option.default]
        end
        for index, option in globalOpts do
            -- Exception to make AllowObservers work because the engine requires
            -- the keys to be bool. Custom options should use 'True' or 'False'
            if option.key == 'AllowObservers' then
                options[option.key] = option.values[option.default].key
            else
                options[option.key] = option.values[option.default].key or option.values[option.default]
            end
        end

        for index, option in AIOpts do
            options[option.key] = option.values[option.default].key or option.values[option.default]
        end

        options.RestrictedCategories = {}

        SetGameOptions(options)
    end
}

-- callback when Mod Manager dialog finishes (modlist==nil on cancel)
-- FIXME: The mod manager should be given a list of game mods set by the host, which
-- clients can look at but not changed, and which don't get saved in our local prefs.
function OnModsChanged(simMods, UIMods, ignoreRefresh)
    -- We depend upon ModsManager to not allow the user to change mods they shouldn't be able to
    selectedSimMods = simMods
    selectedUIMods = UIMods

    Mods.SetSelectedMods(SetUtils.Union(selectedSimMods, selectedUIMods))
    if lobbyComm:IsHost() then
        HostUtils.UpdateMods()
    end

    if not ignoreRefresh then
        -- reload AI types in case we have enable or disable an AI mod.
        AIUtils.RefreshAITypes()
        GUI.AIFillCombo:ClearItems()
        GUI.AIFillCombo:AddItems(AIUtils.GetStrings())
        GUI.AIFillCombo:SetTitleText(LOC('<LOC lobui_0461>Choose AI for autofilling'))
        UpdateGame()
    end
end

function GetAvailableColor()
    for i = 1, LobbyComm.maxPlayerSlots do
        if IsColorFree(gameColors.LobbyColorOrder[i]) then
            return gameColors.LobbyColorOrder[i]
        end
    end
    WARN('Error: No available colors found.')
end

--- This function is retarded.
-- Unfortunately, we're stuck with it.
-- The game requires both ArmyColor and PlayerColor be set. We don't want to have to write two fields
-- all the time, and the magic that makes PlayerData work precludes adding member functions to it.
-- So, we have this. Tough shit. :P
function SetPlayerColor(playerData, newColor)
    playerData.ArmyColor = newColor
    playerData.PlayerColor = newColor
end

function autoMap()
    local randomAutoMap
    if gameInfo.GameOptions['RandomMap'] == 'Official' then
        randomAutoMap = import("/lua/ui/dialogs/mapselect.lua").randomAutoMap(true)
    else
        randomAutoMap = import("/lua/ui/dialogs/mapselect.lua").randomAutoMap(false)
    end
end

function ClientsMissingMap()
    local ret = nil

    for index, player in gameInfo.PlayerOptions:pairs() do
        if player.BadMap then
            if not ret then ret = {} end
            table.insert(ret, player.PlayerName)
        end
    end

    for index, observer in gameInfo.Observers:pairs() do
        if observer.BadMap then
            if not ret then ret = {} end
            table.insert(ret, observer.PlayerName)
        end
    end

    return ret
end

function ClearBadMapFlags()
    for index, player in gameInfo.PlayerOptions:pairs() do
        player.BadMap = false
    end

    for index, observer in gameInfo.Observers:pairs() do
        observer.BadMap = false
    end
end

function EnableSlot(slot)
    GUI.slots[slot].team:Enable()
    GUI.slots[slot].color:Enable()
    GUI.slots[slot].faction:Enable()
    GUI.slots[slot].ready:Enable()
end

function DisableSlot(slot, exceptReady)
    GUI.slots[slot].team:Disable()
    GUI.slots[slot].color:Disable()
    GUI.slots[slot].faction:Disable()
    if not exceptReady then
        GUI.slots[slot].ready:Disable()
    end
end

-- Used for the quick-swap feature
local playersToSwap = false

-- set up player "slots" which is the line representing a player and player specific options
function CreateSlotsUI(makeLabel)
    return CreateUI_Module.CreateSlotsUI(makeLabel)
end

-- create UI won't typically be called directly by another module
function CreateUI(maxPlayers)
    -- Refresh createui.lua's injected globals first: it is invoked from the
    -- Hosting / ConnectionToHostEstablished callbacks after lobbyComm,
    -- localPlayerID and hostID have been (re)assigned, and those callbacks do
    -- not otherwise re-run SyncModuleDeps.
    SyncModuleDeps()
    return CreateUI_Module.CreateUI(maxPlayers)
end

-- Faction selector
function CreateUI_Faction_Selector(lastFaction)
    return CreateUI_Module.CreateUI_Faction_Selector(lastFaction)
end

function UpdateFactionSelectorForPlayer(playerInfo)
    if playerInfo.OwnerID == localPlayerID then
        UpdateFactionSelector()
    end
end

function UpdateFactionSelector()
    local playerSlotID = FindSlotForID(localPlayerID)
    local playerSlot = GUI.slots[playerSlotID]
    if not playerSlot or not playerSlot.AvailableFactions or gameInfo.PlayerOptions[playerSlotID].Ready then
        UIUtil.setEnabled(GUI.factionSelector, false)
        return
    end
    local enabledList = {}
    for index,button in GUI.factionSelector.mButtons do
        enabledList[index] = false
        for i,value in playerSlot.AvailableFactions do
            if value == allAvailableFactionsList[index] then
                if gameInfo.PlayerOptions[playerSlotID].Faction == i then
                    GUI.factionSelector:SetCheck(index)
                end
                enabledList[index] = true
                break
            end
        end
    end
    GUI.factionSelector:EnableSpecificButtons(enabledList)
end

function GetSlotFactionIndex(factionIndex)
    local localSlot = GUI.slots[FindSlotForID(localPlayerID)]
    local actualFaction = allAvailableFactionsList[factionIndex]
    for index,value in localSlot.AvailableFactions do
        if value == actualFaction then
            return index
        end
    end
end

function RefreshLobbyBackground(faction)
    local LobbyBackground = Prefs.GetFromCurrentProfile('LobbyBackground') or 1
    if GUI.background then
        GUI.background:Destroy()
    end
    if LobbyBackground == 1 then -- Factions
        faction = faction or GetSanitisedLastFaction()
        if FACTION_NAMES[faction] then
            GUI.background = Bitmap(GUI, "/textures/ui/common/BACKGROUND/faction/faction-background-paint_" .. FACTION_NAMES[faction] .. "_bmp.dds")
        else
            return
        end
    elseif LobbyBackground == 2 then -- Concept art
        GUI.background = Bitmap(GUI, "/textures/ui/common/BACKGROUND/art/art-background-paint0" .. math.random(1, 5) .. "_bmp.dds")
    elseif LobbyBackground == 3 then -- Screenshot
        GUI.background = Bitmap(GUI, "/textures/ui/common/BACKGROUND/scrn/scrn-background-paint" .. math.random(1, 14) .. "_bmp.dds")
    elseif LobbyBackground == 4 then -- Map
        local MapPreview = import("/lua/ui/controls/mappreview.lua").MapPreview
        GUI.background = MapPreview(GUI) -- Background map
        if gameInfo.GameOptions.ScenarioFile and (gameInfo.GameOptions.ScenarioFile ~= '') then
            local scenarioInfo = MapUtil.LoadScenario(gameInfo.GameOptions.ScenarioFile)
            if scenarioInfo and scenarioInfo.map and (scenarioInfo.map ~= '') and scenarioInfo.preview then
                if not GUI.background:SetTexture(scenarioInfo.preview) then
                    GUI.background:SetTextureFromMap(scenarioInfo.map)
                end
            end
        end
    elseif LobbyBackground == 5 then -- None
        return
    end

    local LobbyBackgroundStretch = Prefs.GetFromCurrentProfile('LobbyBackgroundStretch') or 'true'
    LayoutHelpers.AtCenterIn(GUI.background, GUI)
    LayoutHelpers.DepthUnderParent(GUI.background, GUI.panel)
    if LobbyBackgroundStretch == 'true' then
        LayoutHelpers.FillParent(GUI.background, GUI)
    else
        LayoutHelpers.FillParentPreserveAspectRatio(GUI.background, GUI)
    end
end

---Applies new game settings, including map, mods
---@param settings WatchedGameData
function ApplyGameSettings(settings)
    SetGameOptions(settings.GameOptions, true)

    rehostPlayerOptions = settings.PlayerOptions
    selectedSimMods = settings.GameMods
    HostUtils.UpdateMods()

    UpdateGame()
end
---Returns the current game settings
---@return WatchedGameData
function GetGameSettings()
    return gameInfo
end

--- Delegate to UIUtil's CreateInputDialog, adding the ridiculus chatEdit hack.
function CreateInputDialog(parent, title, listener, str)
    UIUtil.CreateInputDialog(parent, title, listener, GUI.chatEdit, str)
end

function SetGameTitleText(title)
    GUI.titleText:SetColor("B9BFB9")
    if title == '' then
        title = LOC("<LOC lobui_0427>FAF Game Lobby")
    end
    GUI.titleText:SetText(title)
end

function ShowTitleDialog()
    CreateInputDialog(GUI, "<LOC lobui_0465>Game Title",
        function(self, text)
            -- remove new lines from the text
            text = text:gsub("\r", "")
            text = text:gsub("\n", "")

            SetGameOption("Title", text, true)
            SetGameTitleText(text)
        end, gameInfo.GameOptions.Title
)
end

-- Rule title
function SetRuleTitleText(rule)
    GUI.RuleLabel:SetColors("B9BFB9")
    if rule == '' then
        if lobbyComm:IsHost() then
            GUI.RuleLabel:SetColors("FFCC00")
            rule = LOC("<LOC lobui_0420>No Rules: Click to add rules")
        else
            rule = "No rules."
        end
    end

    GUI.RuleLabel:SetText(rule)
end

-- Show the rule change dialog.
function ShowRuleDialog()
    CreateInputDialog(GUI, "<LOC lobui_0464>Game Rules",
        function(self, text)
            SetGameOption("GameRules", text, true)
            SetRuleTitleText(text)
        end, gameInfo.GameOptions.GameRules
)
end

-- Update the combobox for the given slot so it correctly shows the set of available colours.
-- causes a new availableColours to be populated for each occupied slot
-- if a slot is specified, that slot's displayed color will be made consistent with its coded color
function Check_Availaible_Color(slot)
    -- generate a table of used colors
    local UsedColours = {}
    for i = 1, LobbyComm.maxPlayerSlots do
        -- Skips empty slots.
        if gameInfo.PlayerOptions[i] then
            table.insert(UsedColours, gameInfo.PlayerOptions[i].PlayerColor)
        end
    end

    -- generate a table of unused colors
    local unusedColours = {}
    for i, color in gameColors.PlayerColors do
        if not table.find(UsedColours, i) then
            unusedColours[i] = color
        end
    end

    for i = 1, LobbyComm.maxPlayerSlots do
        -- Skips empty slots.
        if gameInfo.PlayerOptions[i] then
            local availableColours = {}
            -- deepcopy the unused colors because using them by reference causes problems with the displayed color list/ChangeBitmapArray
            for c, color in unusedColours do
                availableColours[c] = color
            end
            -- add this slot's color to its availableColours (you get a nil lazyvar error if it's not included)
            availableColours[ gameInfo.PlayerOptions[i].PlayerColor] = gameColors.PlayerColors[gameInfo.PlayerOptions[i].PlayerColor]
            -- set the list of available colors for this slot
            GUI.slots[i].color:ChangeBitmapArray(availableColours, true)
        end
    end

    -- if a slot was entered, set the displayed color for that slot to the coded color for that slot
    if slot then
        GUI.slots[slot].color:SetItem(gameInfo.PlayerOptions[slot].PlayerColor)
    end
end

function CheckModCompatability()
    local blacklistedMods = {}
    for modId, _ in SetUtils.Union(selectedSimMods, selectedUIMods) do
        if ModBlacklist[modId] then
            blacklistedMods[modId] = ModBlacklist[modId]
        end
    end

    return blacklistedMods
end

function WarnIncompatibleMods()
    UIUtil.QuickDialog(GUI,
        "<LOC uimod_0031>Some of your enabled mods are known to cause malfunctions with FAF, so have been disabled. See the mod manager for details - some mods may have newer versions which work.",
        "<LOC _Ok>")
end

function DoSlotSwap(slot1, slot2)

    -- retrieve player info
    local player1 = gameInfo.PlayerOptions[slot1]
    local player2 = gameInfo.PlayerOptions[slot2]

    -- unready players in the player options
    player1.Ready = false 
    player2.Ready = false

    -- swap teams
    local team_bucket = player1.Team
    player1.Team = player2.Team
    player2.Team = team_bucket

    --Handle faction availability
    KeepSameFactionOrRandom(slot1, slot2, player1)
    KeepSameFactionOrRandom(slot2, slot1, player2)

    -- swap the slots
    gameInfo.PlayerOptions[slot2] = player1
    gameInfo.PlayerOptions[slot1] = player2

    -- update slot info
    SetSlotInfo(slot2, player1)
    SetSlotInfo(slot1, player2)

    -- update faction selector
    UpdateFactionSelectorForPlayer(player1)
    UpdateFactionSelectorForPlayer(player2)

    UpdateGame()
end

function KeepSameFactionOrRandom(slotFrom, slotTo, player)
    local playerFactionKey = GUI.slots[slotFrom].AvailableFactions[player.Faction]
    --intialize to random, incase oldFaction isn't available
    player.Faction = table.getn(GUI.slots[slotTo].AvailableFactions)
    for index,faction in GUI.slots[slotTo].AvailableFactions do
        if faction == playerFactionKey then
            player.Faction = index
        end
    end
end

-- Global so the earlier-defined SyncModuleDeps can capture it for injection into
-- HostUtils (a local function here would be injected as nil). See GetPlayersNotReady note.
function SendPlayerOption(playerInfo, key, value)
    if playerInfo.Human then
        GpgNetSend('PlayerOption', playerInfo.OwnerID, key, value)
    else
        GpgNetSend('AIOption', playerInfo.PlayerName, key, value)
    end
end

--- Create the HostUtils object, containing host-only functions. By not assigning this for non-host
-- players, we ensure a hard crash should a non-host somehow end up trying to call them, simplifying
-- debugging somewhat (as well as reducing the number of toplevel definitions a fair bit).
-- This is clearly not a security feature.
function InitHostUtils()
    if not lobbyComm:IsHost() then
        WARN(debug.traceback(nil, "Attempt to create HostUtils by non-host."))
        return
    end
    -- Modul initialisieren und HostUtils auf das Modul zeigen lassen
    HostUtils = HostUtils_Module
    SyncModuleDeps()
end

function CreateBigPreview(parent)
    local scenarioInfo = MapUtil.LoadScenario(gameInfo.GameOptions.ScenarioFile)
    if scenarioInfo.hidePreviewMarkers then
        return
    end

    if LrgMap then
        LrgMap.isHidden = false
        RefreshLargeMap()
        LrgMap:Show()
        return
    end

    -- Size of the map preview to generate.
    local MAP_PREVIEW_SIZE = 721

    -- The size of the mass/hydrocarbon icons
    local HYDROCARBON_ICON_SIZE = 14
    local MASS_ICON_SIZE = 10

    local dialogContent = Group(parent)
    LayoutHelpers.SetDimensions(dialogContent, MAP_PREVIEW_SIZE + 10, MAP_PREVIEW_SIZE + 10)

    LrgMap = Popup(parent, dialogContent)

    -- The LrgMap shouldn't be destroyed due to issues related to texture pooling. Evil hack ensues.
    local onTryMapClose = function()
        LrgMap:Hide()
        LrgMap.isHidden = true
    end
    LrgMap.OnEscapePressed = onTryMapClose
    LrgMap.OnShadowClicked = onTryMapClose

    -- Create the map preview
    local mapPreview = ResourceMapPreview(dialogContent, MAP_PREVIEW_SIZE, MASS_ICON_SIZE, HYDROCARBON_ICON_SIZE)
    dialogContent.mapPreview = mapPreview
    LayoutHelpers.AtCenterIn(mapPreview, dialogContent)

    local closeBtn = UIUtil.CreateButtonStd(dialogContent, '/dialogs/close_btn/close')
    LayoutHelpers.AtRightTopIn(closeBtn, dialogContent, 1, 1)
    closeBtn.OnClick = onTryMapClose

    -- Keep the close button on top of the border (which is itself on top of the map preview)
    LayoutHelpers.DepthOverParent(closeBtn, mapPreview, 2)

    RefreshLargeMap()
end

-- Refresh the large map preview (so it can update if something changes while it's open)
function RefreshLargeMap()
    if not LrgMap or LrgMap.isHidden then
        return
    end

    local scenarioInfo = MapUtil.LoadScenario(gameInfo.GameOptions.ScenarioFile)
    LrgMap.content.mapPreview:SetScenario(scenarioInfo, true)
    MapUtils.ConfigureMapListeners(LrgMap.content.mapPreview, scenarioInfo)
    MapUtils.ShowMapPositions(LrgMap.content.mapPreview, scenarioInfo)
end
