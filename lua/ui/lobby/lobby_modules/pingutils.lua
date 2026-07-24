--*****************************************************************************
--* File: lua/ui/lobby/pingutils.lua
--* Summary: Connection-status calculation and ping tooltip helpers extracted
--*          from lobby.lua.
--*
--* Note: The connection-tracking tables (connectedTo, CurrentConnection,
--*       ConnectionEstablished) remain owned by lobby.lua. They are injected
--*       here by reference and only ever mutated in place (table.insert /
--*       table.remove / index assignment), so lobby.lua and this module share
--*       the same underlying tables. ConnectToPeer/DisconnectFromPeer stay in
--*       lobby.lua.
--*****************************************************************************


-- Upvalues injected by lobby.lua via PingUtils.Init()
local lobbyComm
local gameInfo
local GUI
local localPlayerID
local FindSlotForID
local GetPlayerDisplayName
local IsLocallyOwned
local AddChatText
local Tooltip

-- Connection-tracking tables (owned by lobby.lua, shared by reference).
local connectedTo
local CurrentConnection
local ConnectionEstablished

local ConnectionStatusInfo = {
    '<LOC lobui_0454>Player is not connected to someone',
    '<LOC lobui_0455>Connected',
    '<LOC lobui_0456>Not Connected',
    '<LOC lobui_0457>No connection info available',
}

function Init(deps)
    lobbyComm            = deps.lobbyComm
    gameInfo             = deps.gameInfo
    GUI                  = deps.GUI
    localPlayerID        = deps.localPlayerID
    FindSlotForID        = deps.FindSlotForID
    GetPlayerDisplayName = deps.GetPlayerDisplayName
    IsLocallyOwned       = deps.IsLocallyOwned
    AddChatText          = deps.AddChatText
    Tooltip              = deps.Tooltip

    connectedTo          = deps.connectedTo
    CurrentConnection    = deps.CurrentConnection
    ConnectionEstablished = deps.ConnectionEstablished
end

function wasConnected(peer)
    for _,v in pairs(connectedTo) do
        if v == peer then
            return true
        end
    end
    return false
end

--- Return a status code representing the status of our connection to a peer.
-- @param peer, native table as returned by lobbyComm:GetPeer()
-- @return A value describing the connectivity to given peer.
-- 1 means no connectivity, 2 means they haven't reported that they can talk to us, 3 means
--
-- @todo: This function has side effects despite the naming suggesting that it shouldn't.
--        These need to go away.
function CalcConnectionStatus(peer)
    if peer.status ~= 'Established' then
        return 3
    else
        if not wasConnected(peer.id) then
            local peerSlot = FindSlotForID(peer.id)
            local slot = GUI.slots[peerSlot]
            local playerInfo = gameInfo.PlayerOptions[peerSlot]

            slot.name:SetTitleText(GetPlayerDisplayName(playerInfo))
            slot.name._text:SetFont('Arial Gras', 15)
            if not table.find(ConnectionEstablished, peer.name) then
                if playerInfo.Human and not IsLocallyOwned(peerSlot) then
                    table.insert(ConnectionEstablished, peer.name)
                    for k, v in CurrentConnection do -- Remove PlayerName in this Table
                        if v == peer.name then
                            CurrentConnection[k] = nil
                            break
                        end
                    end
                end
            end

            table.insert(connectedTo, peer.id)
        end
        if not table.find(peer.establishedPeers, lobbyComm:GetLocalPlayerID()) then
            -- they haven't reported that they can talk to us?
            return 1
        end

        local peers = lobbyComm:GetPeers()
        for k,v in peers do
            if v.id ~= peer.id and v.status == 'Established' then
                if not table.find(peer.establishedPeers, v.id) then
                    -- they can't talk to someone we can talk to.
                    return 1
                end
            end
        end
        return 2
    end
end

function EveryoneHasEstablishedConnections(check_observers)
    local important = {}
    for slot, player in gameInfo.PlayerOptions:pairs() do
        if not table.find(important, player.OwnerID) then
            table.insert(important, player.OwnerID)
        end
    end

    if check_observers then
        for slot,observer in gameInfo.Observers:pairs() do
            if not table.find(important, observer.OwnerID) then
                table.insert(important, observer.OwnerID)
            end
        end
    end

    local result = true
    for k, id in important do
        if id ~= localPlayerID then
            local peer = lobbyComm:GetPeer(id)
            for k2, other in important do
                if id ~= other and not table.find(peer.establishedPeers, other) then
                    result = false
                    AddChatText(LOCF("<LOC lobui_0299>%s doesn't have an established connection to %s",
                                     peer.name,
                                     lobbyComm:GetPeer(other).name
                    ))
                end
            end
        end
    end
    return result
end

function Ping_AddControlTooltip(control, delay, slotNumber)
    --This function creates the Ping tooltip for a slot along with necessary mouseover function.
    --It is called during the UI creation.
    --    control: The control to which the tooltip is to be added.
    --    delay: Amount of time to delay before showing tooltip.  See Tooltip.CreateMouseoverDisplay for info.
    --  slotNumber: The slot number associated with the control.
    local pingText = function()
        local pingInfo
        if GUI.slots[slotNumber].pingStatus.PingActualValue then
            pingInfo = GUI.slots[slotNumber].pingStatus.PingActualValue
        else
            pingInfo = LOC('<LOC lobui_0458>UnKnown')
        end
        return LOC('<LOC lobui_0452>Ping: ') .. pingInfo
    end
    local pingBody = function()
        local conInfo
        if GUI.slots[slotNumber].pingStatus.ConnectionStatus then
            conInfo = GUI.slots[slotNumber].pingStatus.ConnectionStatus
        else
            conInfo = 4
        end
        return LOC('<LOC lobui_0453>Only shows when > 500') .. '\n\n' .. LOC(ConnectionStatusInfo[conInfo])
    end
    Tooltip.AddAutoUpdatedControlTooltip(control, pingText, pingBody, delay)
end

