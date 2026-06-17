--*****************************************************************************
--* File: lua/ui/lobby/maputils.lua
--* Summary: Map-preview rendering and start-position interaction helpers
--*          extracted from lobby.lua for maintainability.
--*****************************************************************************


-- Upvalues injected by lobby.lua via MapUtils.Init()
local gameInfo
local lobbyComm
local hostID
local localPlayerID
local GUI
local MapUtil
local HostUtils
local FindSlotForID
local FindObserverSlotForID
local IsPlayer
local IsObserver
local GetSanitisedLastFaction
local DoSlotBehavior
local SetSlotInfo
local UpdateGame
local GetLrgMap

-- Map-preview slot-swap state (host-side click-to-swap on the preview).
-- Owned by this module; only ever read/written by ConfigureMapListeners.
local mapPreviewSlotSwapFrom = 0
local mapPreviewSlotSwap = false

function Init(deps)
    gameInfo               = deps.gameInfo
    lobbyComm              = deps.lobbyComm
    hostID                 = deps.hostID
    localPlayerID          = deps.localPlayerID
    GUI                    = deps.GUI
    MapUtil                = deps.MapUtil
    HostUtils              = deps.HostUtils
    FindSlotForID          = deps.FindSlotForID
    FindObserverSlotForID  = deps.FindObserverSlotForID
    IsPlayer               = deps.IsPlayer
    IsObserver             = deps.IsObserver
    GetSanitisedLastFaction = deps.GetSanitisedLastFaction
    DoSlotBehavior         = deps.DoSlotBehavior
    SetSlotInfo            = deps.SetSlotInfo
    UpdateGame             = deps.UpdateGame
    GetLrgMap              = deps.GetLrgMap
end

function RefreshMapPosition(mapCtrl, slotIndex)

    local playerInfo = gameInfo.PlayerOptions[slotIndex]
    local notFixed = gameInfo.GameOptions['TeamSpawn'] ~= 'fixed'

    -- Evil autoteams voodoo.
    if gameInfo.GameOptions.AutoTeams and not gameInfo.AutoTeams[slotIndex] and lobbyComm:IsHost() then
        gameInfo.AutoTeams[slotIndex] = 1
    end

    -- The ACUButton instance representing this slot, if any.
    local marker = mapCtrl.startPositions[slotIndex]
    if marker then
        marker:SetClosed(gameInfo.ClosedSlots[slotIndex])
        if gameInfo.ClosedSlots[slotIndex] and gameInfo.SpawnMex[slotIndex] then
            marker:SetClosedSpawnMex()
        end
    end

    mapCtrl:UpdatePlayer(slotIndex, playerInfo, notFixed)

    -- Nothing more for us to do for a closed or missing slot.
    if gameInfo.ClosedSlots[slotIndex] or not marker then
        return
    end

    if gameInfo.GameOptions.AutoTeams then
        if gameInfo.GameOptions.AutoTeams == 'lvsr' then
            local midLine = mapCtrl.Left() + (mapCtrl.Width() / 2)
            if notFixed then
                local markerPos = marker.Left()
                if markerPos < midLine then
                    marker:SetTeam(2)
                else
                    marker:SetTeam(3)
                end
            end
        elseif gameInfo.GameOptions.AutoTeams == 'tvsb' then
            local midLine = mapCtrl.Top() + (mapCtrl.Height() / 2)
            if notFixed then
                local markerPos = marker.Top()
                if markerPos < midLine then
                    marker:SetTeam(2)
                else
                    marker:SetTeam(3)
                end
            end
        elseif gameInfo.GameOptions.AutoTeams == 'pvsi' then
            if notFixed then
                if math.mod(slotIndex, 2) ~= 0 then
                    marker:SetTeam(2)
                else
                    marker:SetTeam(3)
                end
            end
        elseif gameInfo.GameOptions.AutoTeams == 'manual' and notFixed then
            marker:SetTeam(gameInfo.AutoTeams[slotIndex] or 1)
        end
    end
end

--- Update a single slot in all displayed map controls.
function RefreshMapPositionForAllControls(slot)
    RefreshMapPosition(GUI.mapView, slot)
    local LrgMap = GetLrgMap()
    if LrgMap and not LrgMap.isHidden then
        RefreshMapPosition(LrgMap.content.mapPreview, slot)
    end
end

function ShowMapPositions(mapCtrl, scenario)
    local playerArmyArray = MapUtil.GetArmies(scenario)

    for inSlot, army in playerArmyArray do
        RefreshMapPosition(mapCtrl, inSlot)
    end
end

function ConfigureMapListeners(mapCtrl, scenario)
    local playerArmyArray = MapUtil.GetArmies(scenario)

    for inSlot, army in playerArmyArray do
        local slot = inSlot -- Closure copy.

        -- The ACUButton instance representing this slot.
        local marker = mapCtrl.startPositions[inSlot]

        marker.OnRollover = function(self, state)
            local slotName = GUI.slots[slot].name
            if state == 'enter' then
                slotName:HandleEvent({Type = 'MouseEnter'})
            elseif state == 'exit' then
                slotName:HandleEvent({Type = 'MouseExit'})
            end
        end

        marker.OnClick = function(self)
            if gameInfo.GameOptions['TeamSpawn'] == 'fixed' then
                if FindSlotForID(localPlayerID) ~= slot and gameInfo.PlayerOptions[slot] == nil then
                    if IsPlayer(localPlayerID) then
                        if lobbyComm:IsHost() then
                            HostUtils.MovePlayerToEmptySlot(FindSlotForID(localPlayerID), slot)
                        else
                            lobbyComm:SendData(hostID, {Type = 'MovePlayer', RequestedSlot = slot})
                        end
                        -- if first click is a not empty slot and second click is a empty slot: reset vars
                        if mapPreviewSlotSwap == true then
                            mapPreviewSlotSwap = false
                            mapPreviewSlotSwapFrom = 0
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
                else -- swap players on map preview
                    if lobbyComm:IsHost() and mapPreviewSlotSwap == false  then
                        mapPreviewSlotSwapFrom = slot
                        mapPreviewSlotSwap = true
                    elseif lobbyComm:IsHost() and mapPreviewSlotSwap == true and mapPreviewSlotSwapFrom ~= slot then
                        mapPreviewSlotSwap = false
                        DoSlotBehavior(mapPreviewSlotSwapFrom, 'move_player_to_slot' .. slot, '')
                        mapPreviewSlotSwapFrom = 0
                    end
                end
            else
                if gameInfo.GameOptions.AutoTeams and lobbyComm:IsHost() then
                    -- Handle the manual-mode reassignment of slots to teams.
                    if gameInfo.GameOptions.AutoTeams == 'manual' then
                        if not gameInfo.ClosedSlots[slot] and (gameInfo.PlayerOptions[slot] or gameInfo.GameOptions['TeamSpawn'] ~= 'fixed') then
                            local targetTeam
                            if gameInfo.AutoTeams[slot] == 7 then
                                -- 2 here corresponds to team 1, since a team value of 1 represents
                                -- "no team". Apparently GPG really, really didn't like zero.
                                targetTeam = 2
                            else
                                targetTeam = gameInfo.AutoTeams[slot] + 1
                            end

                            marker:SetTeam(targetTeam)
                            gameInfo.AutoTeams[slot] = targetTeam

                            lobbyComm:BroadcastData(
                                {
                                    Type = 'AutoTeams',
                                    Slot = slot,
                                    Team = gameInfo.AutoTeams[slot],
                                }
                            )
                            gameInfo.PlayerOptions[slot]['Team'] = gameInfo.AutoTeams[slot]
                            SetSlotInfo(slot, gameInfo.PlayerOptions[slot])
                            UpdateGame()
                        end
                    end
                end
            end
        end

        if lobbyComm:IsHost() then
            marker.OnRightClick = function(self)
                if gameInfo.SpawnMex[slot] then
                    HostUtils.SetSlotClosed(slot, false)
                elseif gameInfo.ClosedSlots[slot] then
                    if gameInfo.AdaptiveMap then
                        HostUtils.SetSlotClosedSpawnMex(slot)
                    else
                        HostUtils.SetSlotClosed(slot, false)
                    end
                else
                    HostUtils.SetSlotClosed(slot, true)
                end
            end
        end
    end
end

