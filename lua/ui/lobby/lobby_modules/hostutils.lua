--*****************************************************************************
--* File: lua/ui/lobby/hostutils.lua
--* Summary: Host-only lobby utilities (slot management, player/observer
--*          conversion, mod checking, army settings, etc.).
--*          Extracted from lobby.lua for maintainability.
--*
--* Note: lobby.lua calls InitHostUtils() only when lobbyComm:IsHost() is true.
--*       Calling any function here on a non-host client is a programming error
--*       and will produce a hard crash – this is intentional.
--*****************************************************************************

-- Upvalues injected by lobby.lua via HostUtils.Init()
local gameInfo
local lobbyComm
local hostID
local localPlayerID
local localPlayerName
local singlePlayer
local numOpenSlots
local GUI
local CPU_Benchmarks
local selectedSimMods
local selectedUIMods
local availableMods
local UIUtil
local Mods
local SetUtils
local ModBlacklist
local LobbyComm
local WatchedValueArray
local Autobalance

-- Functions injected from lobby.lua
local FindSlotForID
local FindObserverSlotForID
local FindNameForID
local IsLocallyOwned
local IsColorFree
local GetAvailableColor
local SetPlayerColor
local SetSlotInfo
local ClearSlotInfo
local UpdateGame
local UpdateFactionSelectorForPlayer
local EnableSlot
local SetPlayerOption
local GetPlayersNotReady
local IsObserver
local AddChatText
local SendSystemMessage
local SendPersonalSystemMessage
local PossiblyAnnounceGameFull
local GetAIPlayerData
local PrivateChat
local DoSlotSwap
local KeepSameFactionOrRandom
local refreshObserverList
local OnModsChanged
local CheckModCompatability
local WarnIncompatibleMods
local SendPlayerOption

-- Init is split into two halves because SupCom Lua limits a function to 32
-- upvalues; assigning all injected locals in a single function exceeds it.
local function InitA(deps)
    gameInfo                  = deps.gameInfo
    lobbyComm                 = deps.lobbyComm
    hostID                    = deps.hostID
    localPlayerID             = deps.localPlayerID
    localPlayerName           = deps.localPlayerName
    singlePlayer              = deps.singlePlayer
    numOpenSlots              = deps.numOpenSlots
    GUI                       = deps.GUI
    CPU_Benchmarks            = deps.CPU_Benchmarks
    selectedSimMods           = deps.selectedSimMods
    selectedUIMods            = deps.selectedUIMods
    availableMods             = deps.availableMods
    UIUtil                    = deps.UIUtil
    Mods                      = deps.Mods
    SetUtils                  = deps.SetUtils
    ModBlacklist              = deps.ModBlacklist
    LobbyComm                 = deps.LobbyComm
    WatchedValueArray         = deps.WatchedValueArray
    Autobalance               = deps.Autobalance
end

local function InitB(deps)
    FindSlotForID             = deps.FindSlotForID
    FindObserverSlotForID     = deps.FindObserverSlotForID
    FindNameForID             = deps.FindNameForID
    IsLocallyOwned            = deps.IsLocallyOwned
    IsColorFree               = deps.IsColorFree
    GetAvailableColor         = deps.GetAvailableColor
    SetPlayerColor            = deps.SetPlayerColor
    SetSlotInfo               = deps.SetSlotInfo
    ClearSlotInfo             = deps.ClearSlotInfo
    UpdateGame                = deps.UpdateGame
    UpdateFactionSelectorForPlayer = deps.UpdateFactionSelectorForPlayer
    EnableSlot                = deps.EnableSlot
    SetPlayerOption           = deps.SetPlayerOption
    GetPlayersNotReady        = deps.GetPlayersNotReady
    IsObserver                = deps.IsObserver
    AddChatText               = deps.AddChatText
    SendSystemMessage         = deps.SendSystemMessage
    SendPersonalSystemMessage = deps.SendPersonalSystemMessage
    PossiblyAnnounceGameFull  = deps.PossiblyAnnounceGameFull
    GetAIPlayerData           = deps.GetAIPlayerData
    PrivateChat               = deps.PrivateChat
    DoSlotSwap                = deps.DoSlotSwap
    KeepSameFactionOrRandom   = deps.KeepSameFactionOrRandom
    refreshObserverList       = deps.refreshObserverList
    OnModsChanged             = deps.OnModsChanged
    CheckModCompatability     = deps.CheckModCompatability
    WarnIncompatibleMods      = deps.WarnIncompatibleMods
    SendPlayerOption          = deps.SendPlayerOption
end

function Init(deps)
    InitA(deps)
    InitB(deps)
end

------------------------------------------------------------
-- Public API
------------------------------------------------------------

--- Cause a player's ready box to become unchecked.
-- @param slot The slot number of the target player.
function SetPlayerNotReady(slot)
    local slotOptions = gameInfo.PlayerOptions[slot]
    if slotOptions.Ready then
        if not IsLocallyOwned(slot) then
            lobbyComm:SendData(slotOptions.OwnerID, {Type = 'SetPlayerNotReady', Slot = slot})
        end
        slotOptions.Ready = false
    end
end

function SetSlotClosed(slot, closed)
    -- Don't close an occupied slot.
    if gameInfo.PlayerOptions[slot] then
        return
    end

    lobbyComm:BroadcastData(
        {
            Type   = 'SlotClosed',
            Slot   = slot,
            Closed = closed
        }
    )

    gameInfo.ClosedSlots[slot] = closed
    gameInfo.SpawnMex[slot]    = false
    ClearSlotInfo(slot)
    PossiblyAnnounceGameFull()
end

function SetSlotClosedSpawnMex(slot)
    -- Don't close an occupied slot.
    if gameInfo.PlayerOptions[slot] then
        return
    end

    lobbyComm:BroadcastData(
        {
            Type           = 'SlotClosedSpawnMex',
            Slot           = slot,
            ClosedSpawnMex = true
        }
    )

    gameInfo.ClosedSlots[slot] = true
    gameInfo.SpawnMex[slot]    = true
    ClearSlotInfo(slot)
    PossiblyAnnounceGameFull()
end

function ConvertPlayerToObserver(playerSlot, ignoreMsg)
    if not gameInfo.PlayerOptions[playerSlot] then
        WARN("HostUtils.ConvertPlayerToObserver for nonexistent player in slot " .. tostring(playerSlot))
        return
    end

    local index = 1
    while gameInfo.Observers[index] do
        index = index + 1
    end

    SetPlayerNotReady(playerSlot)
    local ownerID = gameInfo.PlayerOptions[playerSlot].OwnerID
    gameInfo.Observers[index] = gameInfo.PlayerOptions[playerSlot]
    gameInfo.PlayerOptions[playerSlot] = nil

    if lobbyComm:IsHost() then
        GpgNetSend('PlayerOption', ownerID, 'Team',      -1)
        GpgNetSend('PlayerOption', ownerID, 'Army',      -1)
        GpgNetSend('PlayerOption', ownerID, 'StartSpot', -index)
    end

    ClearSlotInfo(playerSlot)

    lobbyComm:BroadcastData(
        {
            Type    = 'ConvertPlayerToObserver',
            OldSlot = playerSlot,
            NewSlot = index,
            Options = gameInfo.Observers[index]:AsTable(),
        }
    )

    if not ignoreMsg then
        -- %s has switched from a player to an observer.
        SendSystemMessage("lobui_0226", gameInfo.Observers[index].PlayerName)
    end

    UpdateGame()
end

function ConvertObserverToPlayer(fromObserverSlot, toPlayerSlot, ignoreMsg)
    if not toPlayerSlot or toPlayerSlot < 1 or toPlayerSlot > numOpenSlots then
        toPlayerSlot = FindEmptySlot()

        if toPlayerSlot < 1 then
            for i = 1, numOpenSlots do
                local slot = gameInfo.PlayerOptions[i]
                if slot and not slot.Human then
                    RemoveAI(i)
                    toPlayerSlot = i
                    break
                end
            end

            if toPlayerSlot < 1 and gameInfo.Observers[fromObserverSlot] then
                SendPersonalSystemMessage(gameInfo.Observers[fromObserverSlot].OwnerID, "lobui_0608")
                return
            end
        end
    end

    if not gameInfo.Observers[fromObserverSlot] then
        return
    elseif gameInfo.PlayerOptions[toPlayerSlot] then
        return
    elseif gameInfo.ClosedSlots[toPlayerSlot] then
        return
    end

    local incomingPlayer = gameInfo.Observers[fromObserverSlot]

    if not IsColorFree(incomingPlayer.PlayerColor) then
        SetPlayerColor(incomingPlayer, GetAvailableColor())
    end

    gameInfo.PlayerOptions[toPlayerSlot]    = incomingPlayer
    gameInfo.Observers[fromObserverSlot]    = nil

    lobbyComm:BroadcastData(
        {
            Type    = 'ConvertObserverToPlayer',
            OldSlot = fromObserverSlot,
            NewSlot = toPlayerSlot,
            Options = gameInfo.PlayerOptions[toPlayerSlot]:AsTable(),
        }
    )

    if not ignoreMsg then
        -- %s has switched from an observer to player.
        SendSystemMessage("lobui_0227", incomingPlayer.PlayerName)
    end

    SetSlotInfo(toPlayerSlot, gameInfo.PlayerOptions[toPlayerSlot])

    -- This is far from optimally efficient, as it will SetSlotInfo twice when autoteams is enabled.
    Autobalance.AssignAutoTeams()

    UpdateFactionSelectorForPlayer(gameInfo.PlayerOptions[toPlayerSlot])
end

function RemoveAI(slot)
    if gameInfo.PlayerOptions[slot].Human then
        WARN('Use EjectPlayer to remove humans')
        return
    end

    gameInfo.PlayerOptions[slot] = nil
    ClearSlotInfo(slot)
    lobbyComm:BroadcastData(
        {
            Type = 'ClearSlot',
            Slot = slot,
        }
    )
end

--- Returns false if there is an obvious reason why a slot movement will fail.
-- @param moveFrom Slot number to move from.
-- @param moveTo   Slot number to move to.
function SanityCheckSlotMovement(moveFrom, moveTo)
    if moveTo == moveFrom then
        return false
    end

    if gameInfo.ClosedSlots[moveTo] then
        LOG("HostUtils.MovePlayerToEmptySlot: requested slot " .. moveTo .. " is closed")
        return false
    end

    if moveTo > numOpenSlots or moveTo < 1 then
        LOG("HostUtils.MovePlayerToEmptySlot: requested slot " .. moveTo .. " is out of range")
        return false
    end

    if moveFrom > numOpenSlots or moveFrom < 1 then
        LOG("HostUtils.MovePlayerToEmptySlot: target slot " .. moveFrom .. " is out of range")
        return false
    end

    return true
end

--- Move a player from one slot to another, unoccupied one.
-- Is a no-op if the requested slot is occupied, closed, or out of range.
-- @param currentSlot   The slot currently occupied by the player.
-- @param requestedSlot The slot to move this player to.
function MovePlayerToEmptySlot(currentSlot, requestedSlot)
    if not SanityCheckSlotMovement(currentSlot, requestedSlot) then
        return
    end

    if gameInfo.PlayerOptions[requestedSlot] then
        LOG("HostUtils.MovePlayerToEmptySlot: requested slot " .. requestedSlot .. " already occupied")
        return false
    end

    local player = gameInfo.PlayerOptions[currentSlot]

    KeepSameFactionOrRandom(currentSlot, requestedSlot, player)

    gameInfo.PlayerOptions[requestedSlot] = gameInfo.PlayerOptions[currentSlot]
    gameInfo.PlayerOptions[currentSlot]   = nil
    ClearSlotInfo(currentSlot)
    SetSlotInfo(requestedSlot, gameInfo.PlayerOptions[requestedSlot])

    lobbyComm:BroadcastData(
        {
            Type    = 'SlotMove',
            OldSlot = currentSlot,
            NewSlot = requestedSlot,
            Options = gameInfo.PlayerOptions[requestedSlot]:AsTable(),
        }
    )

    -- This is far from optimally efficient, as it will SetSlotInfo twice when autoteams is enabled.
    Autobalance.AssignAutoTeams()
end

--- Swap the players in the two given slots.
-- If the target slot is unoccupied, the player in the first slot is moved there.
-- If the target slot is closed, this is a no-op.
function SwapPlayers(slot1, slot2)
    if not SanityCheckSlotMovement(slot1, slot2) then
        return
    end

    local player1 = gameInfo.PlayerOptions[slot1]
    local player2 = gameInfo.PlayerOptions[slot2]

    if not player2 then
        MovePlayerToEmptySlot(slot1, slot2)
        return
    end

    DoSlotSwap(slot1, slot2)

    lobbyComm:BroadcastData(
        {
            Type  = 'SwapPlayers',
            Slot1 = slot1,
            Slot2 = slot2,
        }
    )

    -- %s has switched with %s
    SendSystemMessage("lobui_0417", player1.PlayerName, player2.PlayerName)
end

--- Add an observer to the game.
-- @param senderID    Peer ID of the incoming observer.
-- @param observerData A PlayerData object representing the observer.
function TryAddObserver(senderID, observerData)
    local index = 1
    while gameInfo.Observers[index] do
        index = index + 1
    end

    gameInfo.Observers[index] = observerData

    lobbyComm:BroadcastData(
        {
            Type    = 'ObserverAdded',
            Slot    = index,
            Options = observerData:AsTable(),
        }
    )

    -- %s has joined as an observer.
    SendSystemMessage("lobui_0202", observerData.PlayerName)
    refreshObserverList()
end

--- Attempt to add a player to a slot. Falls back to observer if no slot is available.
-- @param senderID   Peer ID of the player to add.
-- @param slot       The desired slot (< 1 means "any available slot").
-- @param playerData A PlayerData object representing the player.
function TryAddPlayer(senderID, slot, playerData)
    if playerData.Human and not singlePlayer then
        lobbyComm:SendData(senderID, {Type = 'CPUBenchmark', Benchmarks = CPU_Benchmarks})
    end

    local newSlot = slot

    if not slot or slot < 1 or newSlot > numOpenSlots then
        newSlot = FindEmptySlot()
    end

    if newSlot == -1 then
        PrivateChat(senderID, LOC("<LOC lobui_0237>No slots available, attempting to make you an observer"))
        if playerData.Human then
            TryAddObserver(senderID, playerData)
        end
        return
    end

    if not IsColorFree(playerData.PlayerColor, slot) then
        SetPlayerColor(playerData, GetAvailableColor())
    end

    gameInfo.PlayerOptions[newSlot] = playerData
    lobbyComm:BroadcastData(
        {
            Type    = 'SlotAssigned',
            Slot    = newSlot,
            Options = playerData:AsTable(),
        }
    )

    SetSlotInfo(newSlot, gameInfo.PlayerOptions[newSlot])
    -- This is far from optimally efficient, as it will SetSlotInfo twice when autoteams is enabled.
    Autobalance.AssignAutoTeams()
    PossiblyAnnounceGameFull()
end

--- Add an AI to the game in the given slot.
-- @param name        Display name for this AI.
-- @param personality The personality key (e.g. "adaptive", "easy").
-- @param slot        Target slot (optional; defaults to first empty slot).
function AddAI(name, personality, slot)
    TryAddPlayer(hostID, slot, GetAIPlayerData(name, personality, slot))
end

function PlayerMissingMapAlert(id)
    local slot = FindSlotForID(id)
    local name
    local needMessage = false

    if slot then
        name = gameInfo.PlayerOptions[slot].PlayerName
        if not gameInfo.PlayerOptions[slot].BadMap then
            needMessage = true
        end
        gameInfo.PlayerOptions[slot].BadMap = true
    else
        slot = FindObserverSlotForID(id)
        if slot then
            name = gameInfo.Observers[slot].PlayerName
            if not gameInfo.Observers[slot].BadMap then
                needMessage = true
            end
            gameInfo.Observers[slot].BadMap = true
        end
    end

    if needMessage then
        -- %s is missing map %s.
        SendSystemMessage("lobui_0330", name, gameInfo.GameOptions.ScenarioFile)
        LOG('>> ' .. name .. ' is missing map ' .. gameInfo.GameOptions.ScenarioFile)
        if name == localPlayerName then
            LOG('>> ' .. gameInfo.GameOptions.ScenarioFile .. ' replaced with ' .. UIUtil.defaultScenario)
            SetGameOption('ScenarioFile', UIUtil.defaultScenario)
        end
    end
end

--- Send army settings to the sim server. Must be called once, just before launch.
-- Army numbers are assigned incrementally in slot order.
function SendArmySettingsToServer()
    local armyIdx = 1
    local MAXSLOT = 16
    for slotNum = 1, MAXSLOT do
        local playerInfo = gameInfo.PlayerOptions[slotNum]
        if playerInfo ~= nil then
            LOG('>> SendArmySettingsToServer: Setting army ' .. armyIdx .. ' for slot ' .. slotNum)
            SendPlayerOption(playerInfo, 'Army', armyIdx)
            armyIdx = armyIdx + 1
        else
            LOG('>> SendArmySettingsToServer: Slot ' .. slotNum .. ' empty')
        end
    end
end

--- Send faction/colour/team/start-spot for a single slot to the sim server.
function SendPlayerSettingsToServer(slotNum)
    local playerInfo = gameInfo.PlayerOptions[slotNum]
    SendPlayerOption(playerInfo, 'Faction',   playerInfo.Faction)
    SendPlayerOption(playerInfo, 'Color',     playerInfo.PlayerColor)
    SendPlayerOption(playerInfo, 'Team',      playerInfo.Team)
    SendPlayerOption(playerInfo, 'StartSpot', slotNum)
end

--- Update button enabled states based on player readiness.
function RefreshButtonEnabledness()
    local playerNotReady = GetPlayersNotReady() ~= false

    local hostObserves = false
    if not playerNotReady and IsObserver(localPlayerID) then
        hostObserves = true
    end

    local buttonState = hostObserves or playerNotReady

    UIUtil.setEnabled(GUI.gameoptionsButton,          buttonState)
    UIUtil.setEnabled(GUI.defaultOptions,             buttonState)
    UIUtil.setEnabled(GUI.randMap,                    buttonState)
    UIUtil.setEnabled(GUI.autoTeams,                  buttonState)
    UIUtil.setEnabled(GUI.restrictedUnitsOrPresetsBtn, buttonState)

    UIUtil.setEnabled(GUI.launchGameButton, singlePlayer or hostObserves or not playerNotReady)

    local noOtherTeams = true
    for i, player in gameInfo.PlayerOptions:pairs() do
        -- Team numbers are 1 higher on the backend
        if player.Team > 3 then
            noOtherTeams = false
            break
        end
    end
    UIUtil.setEnabled(GUI.PenguinAutoBalance, noOtherTeams and buttonState)
end

--- Update gameInfo.GameMods from the selected mod sets and notify other clients.
-- @param newPlayerID   (optional) Peer ID of an incoming player to check mod availability for.
-- @param newPlayerName (optional) Name used in kick messages when newPlayerID is set.
function UpdateMods(newPlayerID, newPlayerName)
    local newmods      = {}
    local missingmods  = {}

    local bannedMods = CheckModCompatability()
    if not table.empty(bannedMods) then
        WarnIncompatibleMods()

        selectedSimMods = SetUtils.Subtract(selectedSimMods, bannedMods)
        selectedUIMods  = SetUtils.Subtract(selectedUIMods,  bannedMods)
        OnModsChanged(selectedSimMods, selectedUIMods)

        return
    end

    for modId, _ in selectedSimMods do
        if IsModAvailable(modId) then
            newmods[modId] = true
        else
            table.insert(missingmods, modId)
        end
    end

    if not table.equal(gameInfo.GameMods, newmods) and not newPlayerID then
        gameInfo.GameMods = newmods
        lobbyComm:BroadcastData { Type = "ModsChanged", GameMods = gameInfo.GameMods }

        local nummods = 0
        local uids    = ""
        for k in gameInfo.GameMods do
            nummods = nummods + 1
            uids = (uids == "") and k or string.format("%s %s", uids, k)
        end

        GpgNetSend('GameMods', "activated", nummods)
        if nummods > 0 then
            GpgNetSend('GameMods', "uids", uids)
        end

    elseif not table.equal(gameInfo.GameMods, newmods) and newPlayerID then
        local modnames    = ""
        local totalMissing = table.getn(missingmods)
        local totalListed  = 0

        if totalMissing > 0 then
            for index, id in missingmods do
                for k, mod in Mods.GetGameMods() do
                    if mod.uid == id then
                        totalListed = totalListed + 1
                        if totalMissing == totalListed then
                            modnames = modnames .. " " .. mod.name
                        else
                            modnames = modnames .. " " .. mod.name .. " + "
                        end
                    end
                end
            end
        end

        local reason = LOCF(
            '<LOC lobui_0588>You were automaticly removed from the lobby because you don\'t have the following mod(s):\n%s \nPlease, install the mod before you join the game lobby',
            modnames
        )

        if FindNameForID(newPlayerID) then
            AddChatText(FindNameForID(newPlayerID) .. LOC('<LOC lobui_0700> kicked because he does not have this mod: ') .. modnames)
        elseif newPlayerName then
            AddChatText(newPlayerName .. LOC('<LOC lobui_0700> kicked because he does not have this mod: ') .. modnames)
        else
            AddChatText(LOC('<LOC lobui_0701>The last player is kicked because he does not have this mod: ') .. modnames)
        end

        lobbyComm:EjectPeer(newPlayerID, reason)
    end
end

--- Find and return the index of an unoccupied, open slot.
-- @return The slot index, or -1 if none is available.
function FindEmptySlot()
    for i = 1, numOpenSlots do
        if not gameInfo.PlayerOptions[i] and not gameInfo.ClosedSlots[i] then
            return i
        end
    end
    return -1
end

function KickObservers(reason)
    for k, observer in gameInfo.Observers:pairs() do
        lobbyComm:EjectPeer(observer.OwnerID, reason or "KickedByHost")
    end
    gameInfo.Observers = WatchedValueArray(LobbyComm.maxPlayerSlots)
end
