--*****************************************************************************
--* File: lua/ui/lobby/messagehandlers.lua
--* Summary: Incoming network message handlers (Accept/Handle pairs).
--*          Extracted from lobby.lua for maintainability.
--*****************************************************************************

-- Upvalues injected by lobby.lua via MessageHandlers.Init()
local gameInfo
local lobbyComm
local hostID
local localPlayerID
local localPlayerName
local singlePlayer
local GUI
local CPU_Benchmarks
local HostUtils
local Autobalance
local CPUBenchmark
local Mods
local Presets
local SetUtils
local FACTION_NAMES
local PlayerData
local GameInfo
local LobbyComm
local WatchedValueArray

-- Functions injected from lobby.lua
local FindIDForName
local FindNameForID
local FindSlotForID
local FindObserverSlotForID
local IsPlayer
local IsObserver
local IsLocallyOwned
local IsColorFree
local GetAvailableColor
local SetPlayerColor
local SetSlotInfo
local ClearSlotInfo
local UpdateGame
local UpdateFactionSelectorForPlayer
local UpdateClientModStatus
local EnableSlot
local SetPlayerOption
local AddChatText
local SendSystemMessage
local SendPersonalSystemMessage
local SendCompleteGameStateToPeer
local PossiblyAnnounceGameFull
local DoSlotSwap
local refreshObserverList
local SetWindowedLobby
local SyncModuleDeps
local UIUtil

-- Init is split into two halves because SupCom Lua limits a function to 32
-- upvalues; assigning all injected locals in a single function exceeds it.
local function InitA(deps)
    gameInfo                  = deps.gameInfo
    lobbyComm                 = deps.lobbyComm
    hostID                    = deps.hostID
    localPlayerID             = deps.localPlayerID
    localPlayerName           = deps.localPlayerName
    singlePlayer              = deps.singlePlayer
    GUI                       = deps.GUI
    CPU_Benchmarks            = deps.CPU_Benchmarks
    HostUtils                 = deps.HostUtils
    Autobalance               = deps.Autobalance
    CPUBenchmark              = deps.CPUBenchmark
    Mods                      = deps.Mods
    Presets                   = deps.Presets
    SetUtils                  = deps.SetUtils
    FACTION_NAMES             = deps.FACTION_NAMES
    PlayerData                = deps.PlayerData
    GameInfo                  = deps.GameInfo
    LobbyComm                 = deps.LobbyComm
    WatchedValueArray         = deps.WatchedValueArray
    UIUtil                    = deps.UIUtil
end

local function InitB(deps)
    FindIDForName             = deps.FindIDForName
    FindNameForID             = deps.FindNameForID
    FindSlotForID             = deps.FindSlotForID
    FindObserverSlotForID     = deps.FindObserverSlotForID
    IsPlayer                  = deps.IsPlayer
    IsObserver                = deps.IsObserver
    IsLocallyOwned            = deps.IsLocallyOwned
    IsColorFree               = deps.IsColorFree
    GetAvailableColor         = deps.GetAvailableColor
    SetPlayerColor            = deps.SetPlayerColor
    SetSlotInfo               = deps.SetSlotInfo
    ClearSlotInfo             = deps.ClearSlotInfo
    UpdateGame                = deps.UpdateGame
    UpdateFactionSelectorForPlayer = deps.UpdateFactionSelectorForPlayer
    UpdateClientModStatus     = deps.UpdateClientModStatus
    EnableSlot                = deps.EnableSlot
    SetPlayerOption           = deps.SetPlayerOption
    AddChatText               = deps.AddChatText
    SendSystemMessage         = deps.SendSystemMessage
    SendPersonalSystemMessage = deps.SendPersonalSystemMessage
    SendCompleteGameStateToPeer = deps.SendCompleteGameStateToPeer
    PossiblyAnnounceGameFull  = deps.PossiblyAnnounceGameFull
    DoSlotSwap                = deps.DoSlotSwap
    refreshObserverList       = deps.refreshObserverList
    SetWindowedLobby          = deps.SetWindowedLobby
    SyncModuleDeps            = deps.SyncModuleDeps
end

function Init(deps)
    InitA(deps)
    InitB(deps)
end

------------------------------------------------------------
-- Validator helpers (used as Accept predicates)
------------------------------------------------------------

local IsFromHost      = function(data) return data.SenderID == hostID end
local AmHost          = function(data) return lobbyComm:IsHost() end

local FromSubjectOrHost = function(data)
    if data.SenderID == hostID then
        return true
    end

    if data.PlayerName then
        return data.SenderID == FindIDForName(data.PlayerName)
    end

    if data.Slot and gameInfo.PlayerOptions[data.Slot] then
        return data.SenderID == FindIDForName(gameInfo.PlayerOptions[data.Slot].PlayerName)
    end

    return false
end

------------------------------------------------------------
-- Handler table
------------------------------------------------------------

-- Each entry has an optional Accept(data)->bool and a mandatory Handle(data).
-- An optional Reject(data) is called when Accept returns false.
Handlers = {
    -- Update player options. Either the host reconfiguring, or users tweaking their own settings.
    PlayerOptions = {
        Accept = function(data)
            for key, val in data.Options do
                if data.SenderID ~= hostID then
                    if key == 'Team' and gameInfo.GameOptions['AutoTeams'] ~= 'none' then
                        WARN("Attempt to set Team while Auto Teams are on.")
                        return false
                    elseif gameInfo.PlayerOptions[data.Slot].OwnerID ~= data.SenderID then
                        WARN("Attempt to set option on unowned slot.")
                        return false
                    end
                end
            end
            return true
        end,
        Handle = function(data)
            local options = data.Options

            for key, val in options do
                gameInfo.PlayerOptions[data.Slot][key] = val
                if lobbyComm:IsHost() then
                    local playerInfo = gameInfo.PlayerOptions[data.Slot]
                    if playerInfo.Human then
                        GpgNetSend('PlayerOption', playerInfo.OwnerID, key, val)
                    else
                        GpgNetSend('AIOption', playerInfo.PlayerName, key, val)
                    end

                    if key == "Ready" then
                        HostUtils.RefreshButtonEnabledness()
                    end
                end
            end

            SetSlotInfo(data.Slot, gameInfo.PlayerOptions[data.Slot])
        end
    },

    PublicChat = {
        Accept = function(data)
            return data.SenderName == FindNameForID(data.SenderID)
        end,
        Handle = function(data)
            AddChatText(data.Text, data.SenderID)
        end
    },

    PrivateChat = {
        Accept = function(data)
            return data.SenderName == FindNameForID(data.SenderID)
        end,
        Handle = function(data)
            AddChatText("<<"..LOCF("<LOC lobui_0442>From %s", data.SenderName)..">> "..data.Text)
        end
    },

    CPUBenchmark = {
        Accept = FromSubjectOrHost,
        Handle = function(data)
            local newInfo = false
            if data.PlayerName and CPU_Benchmarks[data.PlayerName] ~= data.Result then
                newInfo = true
            end

            local benchmarks = {}
            if data.PlayerName then
                benchmarks[data.PlayerName] = data.Result
            else
                benchmarks = data.Benchmarks
            end

            for name, result in benchmarks do
                CPU_Benchmarks[name] = result
                local id = FindIDForName(name)
                local slot = FindSlotForID(id)
                if slot then
                    CPUBenchmark.SetSlotCPUBar(slot, gameInfo.PlayerOptions[slot])
                else
                    refreshObserverList()
                end
            end

            -- Host re-broadcasts new CPU benchmark info for clients not yet directly connected.
            if lobbyComm:IsHost() and newInfo then
                lobbyComm:BroadcastData({Type='CPUBenchmark', Benchmarks=CPU_Benchmarks})
            end
        end
    },

    SetPlayerNotReady = {
        Accept = FromSubjectOrHost,
        Handle = function(data)
            EnableSlot(data.Slot)
            GUI.becomeObserver:Enable()
            SetPlayerOption(data.Slot, 'Ready', false)
            GUI.slots[data.Slot].ready:SetCheck(false)
        end
    },

    AutoTeams = {
        Accept = IsFromHost,
        Handle = function(data)
            gameInfo.AutoTeams[data.Slot] = data.Team
            gameInfo.PlayerOptions[data.Slot]['Team'] = data.Team
            SetSlotInfo(data.Slot, gameInfo.PlayerOptions[data.Slot])
            UpdateGame()
        end
    },

    ---@class LobbyAddPlayerData
    ---@field PlayerOptions PlayerData
    ---@field SenderId number
    ---@field SenderName string
    ---@field Type string
    AddPlayer = {
        ---@param data LobbyAddPlayerData
        Accept = function(data)
            if type(data.PlayerOptions.MEAN) != 'number' then return false end
            if type(data.PlayerOptions.NG) != 'number' then return false end
            if type(data.PlayerOptions.Faction) != 'number' then return false end
            if type(data.PlayerOptions.PlayerName) != 'string' then return false end

            local charactersInPlayerName = string.len(data.PlayerOptions.PlayerName)
            if charactersInPlayerName < 2 or charactersInPlayerName > 32 then return false end

            if data.PlayerOptions.PlayerClan then
                if type(data.PlayerOptions.PlayerClan) != 'string' then return false end
                if string.len(data.PlayerOptions.PlayerClan) > 6 then return false end
            end

            if not data.PlayerOptions.OwnerID then return false end
            if not (data.PlayerOptions.OwnerID == data.SenderID) then return false end
            if FindNameForID(data.SenderID) then return false end

            local hostVersion, hostGametype, hostCommit = import("/lua/version.lua").GetVersionData()
            local playerVersion = tostring(data.PlayerOptions.Version)
            local playerGameType = tostring(data.PlayerOptions.GameType)
            local playerCommit = tostring(data.PlayerOptions.Commit)
            if hostVersion ~= playerVersion or hostGametype ~= playerGameType or hostCommit ~= playerCommit then
                local playerName = data.PlayerOptions.PlayerName
                AddChatText(LOCF(
                    "<LOC lobui_666>Game version missmatch detected with %s. \r\n - host: %s (@%s)\r\n - %s: %s (@%s). \r\n\r\nTo prevent desyncs, %s is ejected automatically. It is possible that a new game version is released. If this keeps happening then it is better to rehost.",
                    playerName, hostVersion, hostCommit:sub(1, 8),
                    playerName, playerVersion, playerCommit:sub(1, 8),
                    playerName
                ))
                return false
            end

            return lobbyComm:IsHost()
        end,
        Reject = function(data)
            lobbyComm:EjectPeer(data.SenderID, "Game version missmatch or invalid player data.")
        end,
        Handle = function(data)
            SendCompleteGameStateToPeer(data.SenderID)

            if argv.isRehost then
                local rehostSlot = FindRehostSlotForID(data.SenderID) or 0
                if rehostSlot ~= 0 and gameInfo.PlayerOptions[rehostSlot] then
                    local occupyingPlayer = gameInfo.PlayerOptions[rehostSlot]
                    if not occupyingPlayer.Human then
                        HostUtils.RemoveAI(rehostSlot)
                        HostUtils.TryAddPlayer(data.SenderID, rehostSlot, PlayerData(data.PlayerOptions))
                    else
                        HostUtils.ConvertPlayerToObserver(rehostSlot, true)
                        HostUtils.TryAddPlayer(data.SenderID, rehostSlot, PlayerData(data.PlayerOptions))
                        HostUtils.ConvertObserverToPlayer(FindObserverSlotForID(occupyingPlayer.OwnerID))
                    end
                else
                    HostUtils.TryAddPlayer(data.SenderID, rehostSlot, PlayerData(data.PlayerOptions))
                end
            else
                HostUtils.TryAddPlayer(data.SenderID, 0, PlayerData(data.PlayerOptions))
            end

            if HasCommandLineArg('/gpgnet') then
                PlayVoice(Sound{Bank = 'XGG', Cue = 'XGG_Computer__04716'}, true)
            end
        end
    },

    MovePlayer = {
        Accept = AmHost,
        Handle = function(data)
            local CurrentSlot = FindSlotForID(data.SenderID)
            if gameInfo.PlayerOptions[CurrentSlot].Ready then
                return
            end
            HostUtils.MovePlayerToEmptySlot(CurrentSlot, data.RequestedSlot)
        end
    },

    RequestConvertToObserver = {
        Accept = AmHost,
        Handle = function(data)
            HostUtils.ConvertPlayerToObserver(FindSlotForID(data.SenderID))
        end
    },

    RequestConvertToPlayer = {
        Accept = AmHost,
        Handle = function(data)
            HostUtils.ConvertObserverToPlayer(FindObserverSlotForID(data.SenderID), data.PlayerSlot)
        end
    },

    RequestColor = {
        Accept = AmHost,
        Handle = function(data)
            local TargetSlot = FindSlotForID(data.SenderID)
            if IsColorFree(data.Color) then
                SetPlayerColor(gameInfo.PlayerOptions[TargetSlot], data.Color)
                lobbyComm:BroadcastData({ Type = 'SetColor', Color = data.Color, Slot = TargetSlot })
                SetSlotInfo(TargetSlot, gameInfo.PlayerOptions[TargetSlot])
            else
                lobbyComm:SendData(data.SenderID, {
                    Type = 'SetColor',
                    Color = gameInfo.PlayerOptions[TargetSlot].PlayerColor,
                    Slot = TargetSlot
                })
            end
        end
    },

    SetAvailableMods = {
        Accept = AmHost,
        Handle = function(data)
            availableMods[data.SenderID] = data.Mods
            HostUtils.UpdateMods(data.SenderID, data.Name)
        end
    },

    MissingMap = {
        Accept = AmHost,
        Handle = function(data)
            HostUtils.PlayerMissingMapAlert(data.SenderID)
        end
    },

    SystemMessage = {
        Handle = function(data)
            PrintSystemMessage(data.Id, data.Args)
        end
    },

    Peer_Really_Disconnected = {
        Handle = function(data)
            if data.Observ == false then
                gameInfo.PlayerOptions[data.Slot] = nil
            elseif data.Observ == true then
                gameInfo.Observers[data.Slot] = nil
            end
            AddChatText(LOCF("<LOC Engine0003>Lost connection to %s.", data.Options.PlayerName), "Engine0003")
            ClearSlotInfo(data.Slot)
            UpdateGame()
        end
    },

    SetAllPlayerNotReady = {
        Accept = IsFromHost,
        Handle = function(data)
            if not IsPlayer(localPlayerID) then
                return
            end
            local localSlot = FindSlotForID(localPlayerID)
            EnableSlot(localSlot)
            GUI.becomeObserver:Enable()
            SetPlayerOption(localSlot, 'Ready', false)
        end
    },

    GameOptions = {
        Accept = IsFromHost,
        Handle = function(data)
            for key, value in data.Options do
                gameInfo.GameOptions[key] = value
            end
            UpdateGame()
        end
    },

    ClearSlot = {
        Accept = IsFromHost,
        Handle = function(data)
            gameInfo.PlayerOptions[data.Slot] = nil
            ClearSlotInfo(data.Slot)
        end
    },

    ModsChanged = {
        Accept = IsFromHost,
        Handle = function(data)
            gameInfo.GameMods = data.GameMods
            UpdateClientModStatus(data.GameMods)
            UpdateGame()
            import("/lua/ui/lobby/modsmanager.lua").UpdateClientModStatus(gameInfo.GameMods)
        end
    },

    SlotClosed = {
        Accept = IsFromHost,
        Handle = function(data)
            gameInfo.ClosedSlots[data.Slot] = data.Closed
            gameInfo.SpawnMex[data.Slot] = false
            ClearSlotInfo(data.Slot)
            PossiblyAnnounceGameFull()
        end
    },

    SlotClosedSpawnMex = {
        Accept = IsFromHost,
        Handle = function(data)
            gameInfo.ClosedSlots[data.Slot] = data.ClosedSpawnMex
            gameInfo.SpawnMex[data.Slot] = data.ClosedSpawnMex
            ClearSlotInfo(data.Slot)
            PossiblyAnnounceGameFull()
        end
    },

    GameInfo = {
        Accept = IsFromHost,
        Handle = function(data)
            local hostFlatInfo = data.GameInfo
            gameInfo = GameInfo.CreateGameInfo(LobbyComm.maxPlayerSlots, hostFlatInfo)
            SyncModuleDeps()
            UpdateClientModStatus(gameInfo.GameMods, true)
            UpdateGame()
        end
    },

    SetColor = {
        Accept = IsFromHost,
        Handle = function(data)
            SetPlayerColor(gameInfo.PlayerOptions[data.Slot], data.Color)
            SetSlotInfo(data.Slot, gameInfo.PlayerOptions[data.Slot])
        end
    },

    ConvertObserverToPlayer = {
        Accept = IsFromHost,
        Handle = function(data)
            gameInfo.Observers[data.OldSlot] = nil
            gameInfo.PlayerOptions[data.NewSlot] = PlayerData(data.Options)
            SetSlotInfo(data.NewSlot, gameInfo.PlayerOptions[data.NewSlot])
            UpdateFactionSelectorForPlayer(gameInfo.PlayerOptions[data.NewSlot])
        end
    },

    ConvertPlayerToObserver = {
        Accept = IsFromHost,
        Handle = function(data)
            gameInfo.Observers[data.NewSlot] = PlayerData(data.Options)
            gameInfo.PlayerOptions[data.OldSlot] = nil
            ClearSlotInfo(data.OldSlot)
            UpdateFactionSelectorForPlayer(gameInfo.Observers[data.NewSlot])
        end
    },

    SlotAssigned = {
        Accept = IsFromHost,
        Handle = function(data)
            gameInfo.PlayerOptions[data.Slot] = PlayerData(data.Options)
            if HasCommandLineArg('/gpgnet') then
                PlayVoice(Sound{Bank = 'XGG', Cue = 'XGG_Computer__04716'}, true)
            end
            SetSlotInfo(data.Slot, gameInfo.PlayerOptions[data.Slot])
            UpdateFactionSelectorForPlayer(gameInfo.PlayerOptions[data.Slot])
            PossiblyAnnounceGameFull()
        end
    },

    SlotMove = {
        Accept = IsFromHost,
        Handle = function(data)
            gameInfo.PlayerOptions[data.OldSlot] = nil
            gameInfo.PlayerOptions[data.NewSlot] = PlayerData(data.Options)
            gameInfo.PlayerOptions[data.NewSlot].Ready = false
            ClearSlotInfo(data.OldSlot)
            SetSlotInfo(data.NewSlot, gameInfo.PlayerOptions[data.NewSlot])
            UpdateFactionSelectorForPlayer(gameInfo.PlayerOptions[data.NewSlot])
        end
    },

    SwapPlayers = {
        Accept = IsFromHost,
        Handle = function(data)
            DoSlotSwap(data.Slot1, data.Slot2)
        end
    },

    ObserverAdded = {
        Accept = IsFromHost,
        Handle = function(data)
            gameInfo.Observers[data.Slot] = PlayerData(data.Options)
            refreshObserverList()
        end
    },

    -- Start the game!
    Launch = {
        Accept = IsFromHost,
        Handle = function(data)
            local info = data.GameInfo
            info.GameMods = Mods.GetGameMods(info.GameMods)
            SetWindowedLobby(false)

            for index, player in info.PlayerOptions do
                if player.OwnerID == localPlayerID then
                    UIUtil.SetCurrentSkin(FACTION_NAMES[player.Faction])
                end
            end

            Presets.SaveLastGamePreset()
            lobbyComm:LaunchGame(info)
        end
    },
}

--- Dispatch an incoming message to the appropriate handler.
-- Called from lobbyComm.DataReceived in lobby.lua.
function Dispatch(data)
    if not Handlers[data.Type] then
        WARN("Unknown message type: " .. tostring(data.Type))
        return
    end

    if not Handlers[data.Type].Accept or Handlers[data.Type].Accept(data) then
        Handlers[data.Type].Handle(data)
    elseif Handlers[data.Type].Reject then
        Handlers[data.Type].Reject(data)
    else
        WARN("Rejected message of type " .. tostring(data.Type) .. " from " .. tostring(FindNameForID(data.SenderID)))
    end
end
