local oldResetSyncTable = ResetSyncTable

UnitData = {}

ResetSyncTable = function()
    oldResetSyncTable()

    -- A list of camera control operations that we'd like the user layer to perform.
    Sync.CameraRequests = {}
    Sync.Sounds = {}
    Sync.Voice = {}

    -- contains the current score for each army
    Sync.Score = {}
      Sync.ScoreAccum = {}

    -- Table of army indices set to "victory" or "defeat".
    -- It's the user layer's job to determine if any UI needs to be shown
    -- for the focus army.
    Sync.GameResult = {}

    -- Player to player queries that can affect the Sim
    Sync.PlayerQueries = {}
    Sync.QueryResults = {}

    Sync.Reclaim = {}
end

SimUnitEnhancements = {}

function AddUnitEnhancement(unit, enhancement, slot)
    if not slot then return end
    local id = unit.EntityId
    SimUnitEnhancements[id] = SimUnitEnhancements[id] or {}
    SimUnitEnhancements[id][slot] = enhancement
    SyncUnitEnhancements()
end

function RemoveUnitEnhancement(unit, enhancement)
    if not unit or unit.Dead then return end
    local id = unit.EntityId
    local slots = SimUnitEnhancements[id]
    if not slots then return end
    local key = nil
    for k, v in slots do
        if v == enhancement then
            key = k
            break
        end
    end

    if not key then return end
    SimUnitEnhancements[id][key] = nil
    if table.getsize(slots) == 0 then
        SimUnitEnhancements[id] = nil
    end
    SyncUnitEnhancements()
end

function RemoveAllUnitEnhancements(unit)
    local id = unit.EntityId
    if not SimUnitEnhancements[id] then return end
    SimUnitEnhancements[id] = nil
    SyncUnitEnhancements()
end

function SyncUnitEnhancements()
    import('/lua/enhancementcommon.lua').SetEnhancementTable(SimUnitEnhancements)
    local sync = {}

    for id, slots in SimUnitEnhancements do
        local unit = GetEntityById(id)
        local me = GetFocusArmy()
        if unit and (me == -1 or IsAlly(me, unit.Army)) then
            sync[id] = slots
        end
    end

    Sync.UserUnitEnhancements = sync
end

function DebugMoveCamera(x0,y0,x1,y1)
    local Camera = import('/lua/SimCamera.lua').SimCamera
    local cam = Camera("WorldCamera")
--    cam:ScaleMoveVelocity(0.02)
    cam:MoveTo(Rect(x0,y0,x1,y1),5.0)
end

function SyncPlayableRect(rect)
    local Camera = import('/lua/SimCamera.lua').SimCamera
    local cam = Camera("WorldCamera")
    cam:SyncPlayableRect(rect)
end

function LockInput()
    Sync.LockInput = true
end

function UnlockInput()
    Sync.UnlockInput = true
end

function OnPostLoad()
    local focus = GetFocusArmy()
    for entityID, data in UnitData do
        if data.OwnerArmy == focus or focus == -1 then
            Sync.UnitData[entityID] = data.Data
        end
    end
    Sync.IsSavedGame = true
end

function NoteFocusArmyChanged(new, old)
    --LOG('NoteFocusArmyChanged(new=' .. repr(new) .. ', old=' .. repr(old) .. ')')
    import('/lua/SimPing.lua').OnArmyChange()
    for entityID, data in UnitData do
        if new == -1 or data.OwnerArmy == new then
            Sync.UnitData[entityID] = data.Data
        elseif old == -1 or data.OwnerArmy == old then
            Sync.ReleaseIds[entityID] = true
        else
        end
    end
    SyncUnitEnhancements()
    Sync.FocusArmyChanged = {new = new, old = old}
end

function FloatingEntityText(entityId, text)
    if not entityId and text then
        WARN('Trying to float entity text with no entityId or no text.')
        return false
    else
        if GetEntityById(entityId).Army == GetFocusArmy() then
            if not Sync.FloatingEntityText then Sync.FloatingEntityText = {} end
            table.insert(Sync.FloatingEntityText, {entity = entityId, text = text})
        end
    end
end

function StartCountdown(entityId, duration)
    cdDuration = duration or 5
    if not entityId then
        WARN('Trying to start countdown text with no entityId.')
        return false
    else
        if GetEntityById(entityId).Army == GetFocusArmy() then
            if not Sync.StartCountdown then Sync.StartCountdown = {} end
            table.insert(Sync.StartCountdown, {entity = entityId, duration = cdDuration})
        end
    end
end

function CancelCountdown(entityId)
    if not entityId then
        WARN('Trying to Cancel Countdown text with no entityId.')
        return false
    else
        if GetEntityById(entityId).Army == GetFocusArmy() then
            if not Sync.CancelCountdown then Sync.CancelCountdown = {} end
            table.insert(Sync.CancelCountdown, {entity = entityId})
        end
    end
end

function HighlightUIPanel(panel)
    if not Sync.HighlightUIPanel then Sync.HighlightUIPanel = {} end
    table.insert(Sync.HighlightUIPanel, panel)
end

function ChangeCameraZoom(newMult)
    Sync.ChangeCameraZoom = newMult
end

function CreateCameraMarker(position)
    return import('/lua/simcameramarkers.lua').AddCameraMarker(position)
end

function EndDemo()
    Sync.EndDemo = true
end

function PrintText(text, fontSize, fontColor, duration, location)
    if not text and location then
        WARN('Trying to print text with no string or no location.')
        return false
    else
        if not Sync.PrintText then Sync.PrintText = {} end
        table.insert(Sync.PrintText, {text = text, size = fontSize, color = fontColor, duration = duration, location = location})
    end
end

function CreateDialogue(text, buttonText, position)
    return import('/lua/SimDialogue.lua').Create(text, buttonText, position)
end
