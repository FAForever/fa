-- The global sync table is copied from the sim layer every time the main and sim threads are
-- synchronized on the sim beat (which is like a tick but happens even when the game is paused)
Sync = {}

-- The PreviousSync table holds just what you'd expect it to, the sync table from the previous
-- beat.
PreviousSync = {}

-- Unit specific data that's been sync'd. Data changes are accumulated by merging
-- the Sync.UnitData table into this table each sync (if there's new data)
UnitData = {}

local reclaim = import('/lua/ui/game/reclaim.lua')
local UpdateReclaim = reclaim.UpdateReclaim
local sendEnhancementMessage = import('/lua/ui/notify/notify.lua').sendEnhancementMessage
local SetPlayableArea = reclaim.SetPlayableArea

-- Here's an opportunity for user side script to examine the Sync table for the new tick
function OnSync()
    if Sync.RequestingExit then
        ExitGame()
    end

    if not table.empty(Sync.UnitData) then
        UnitData = table.merged(UnitData,Sync.UnitData)
    end

    for id, v in Sync.ReleaseIds do
        UnitData[id] = nil
    end

    --Play Sounds
    for k, v in Sync.Sounds do
        PlaySound(Sound{ Bank=v.Bank, Cue=v.Cue })
    end

    if Sync.ToggleGamePanels then
        ConExecute('UI_ToggleGamePanels')
    end

    if Sync.ToggleLifeBarsOff then
        ConExecute('UI_RenderUnitBars false')
    end

    if Sync.ToggleLifeBarsOn then
        ConExecute('UI_RenderUnitBars true')
    end

    if not table.empty(Sync.AIChat) then
        for k, v in Sync.AIChat do
            import('/lua/AIChatSorian.lua').AIChat(v.group, v.text, v.sender)
        end
    end

    if Sync.UserConRequests then
        for num, execRequest in Sync.UserConRequests do
            ConExecute(execRequest)
        end
    end

    if Sync.NukeLaunchData then
        import('/lua/ui/game/nukelaunchping.lua').DoNukePing(Sync.NukeLaunchData)
    end

    -- Each sync, update the user-side data for any prop created, damaged, or destroyed
    if not table.empty(Sync.Reclaim) then
        UpdateReclaim(Sync.Reclaim)
    end

    if Sync.Teamkill and not SessionIsReplay() then
        local armies, clients = GetArmiesTable().armiesTable, GetSessionClients()
        local victim, instigator = Sync.Teamkill.victim, Sync.Teamkill.instigator
        local data = {time=Sync.Teamkill.killTime, victim={}, instigator={}}

        for k, army in {victim=victim, instigator=instigator} do
            data[k].name = armies[army] and armies[army].nickname or "-"
            data[k].id = clients[army] and clients[army].uid or 0
        end

        GpgNetSend('TeamkillHappened', data.time, data.victim.id, data.victim.name,  data.instigator.id, data.instigator.name)
        WARN(string.format("TEAMKILL: %s KILLED BY %s, TIME: %s", data.victim.name, data.instigator.name, data.time))

        if GetFocusArmy() == victim then
            import('/lua/ui/dialogs/teamkill.lua').CreateDialog(data)
        end
    end

    if Sync.EnforceRating then
        GpgNetSend('EnforceRating')
    end

    if Sync.EnhanceMessage and not table.empty(Sync.EnhanceMessage) then
        for _, messageTable in Sync.EnhanceMessage do
            sendEnhancementMessage(messageTable)
        end
    end

    if Sync.NewPlayableArea then
        SetPlayableArea(Sync.NewPlayableArea)
    end

    if Sync.StartPositions then
        import('/lua/ui/game/worldview.lua').MarkStartPositions(Sync.StartPositions)
    end

    if Sync.GameEnded then
        GpgNetSend('GameEnded')
    end
end
