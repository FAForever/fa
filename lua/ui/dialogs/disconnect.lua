-----------------------------------------------------------------
-- File: lua/modules/ui/dialogs/disconnect.lua
-- Author: Chris Blackwell
-- Summary: handles multiplayer disconnects
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local Group = import("/lua/maui/group.lua").Group
local GameMain = import("/lua/ui/game/gamemain.lua")

local SessionClients = import("/lua/ui/override/sessionclients.lua")
local scenario = SessionGetScenarioInfo()

local parent = nil
local myIndex = ''

local function DestroyConnectivityDialog()
    SessionClients.ResetInterval()
    if parent then
        parent:Destroy()
        parent = false
    end
end

--- The public cleanup: /lua/ui/uimain.lua calls it on the old module when this one is reloaded.
function DestroyDialog()
    DestroyConnectivityDialog()
end

local function CreateDialog(clients)
    SessionClients.FastInterval()
    import("/lua/ui/game/worldview.lua").UnlockInput()
    import("/lua/ui/game/gamemain.lua").KillWaitingDialog()

    GetCursor():Show()
    DestroyConnectivityDialog()

    parent = Group(GetFrame(0), "diconnectDialogParentGroup")
    parent.Depth:Set(GetFrame(0):GetTopmostDepth() + 1)
    parent:SetNeedsFrameUpdate(true)
    parent.time = 0

    bg = Bitmap(parent, UIUtil.UIFile('/scx_menu/panel-brd/panel_brd_m.dds'))
    LayoutHelpers.FillParent(bg, parent)

    bg.border = UIUtil.CreateSCXMenuPanelBorder(bg)

    local dlgTitle = UIUtil.CreateText(bg, "<LOC UI_Disco0000>Connectivity", 18)
    LayoutHelpers.AtTopIn(dlgTitle, bg, -52)
    LayoutHelpers.AtHorizontalCenterIn(dlgTitle, parent)

    local slots = {}
    local previous = false

    for i,client in clients do
        local slot = Bitmap(bg, UIUtil.UIFile('/scx_menu/panel-brd/conn-bg.dds'),"clientSlotGroup " .. tostring(i))
        slots[i] = slot

        slot.index = i

        if client['local'] then -- Get my local index
            myIndex = i
        end

        if previous then
            LayoutHelpers.Below(slot, previous)
        else
            LayoutHelpers.AtTopIn(slot, parent)
            LayoutHelpers.AtHorizontalCenterIn(slot, parent)
        end
        previous = slot

        slot.id = UIUtil.CreateText(slot, slot.index, 20, UIUtil.fixedFont)
        slot.id:SetColor('ffffffff')
        LayoutHelpers.AtLeftTopIn(slot.id, slot, 5, 1)

        slot.name = UIUtil.CreateText(slot, client.name, 16, UIUtil.fixedFont)
        slot.name:SetColor('FFbadbdb')
        LayoutHelpers.AtLeftTopIn(slot.name, slot, 20, 4)

        slot.state = Bitmap(slot) -- Skull if the player is dead
        slot.state:SetTexture(UIUtil.UIFile('/game/unit-over/icon-skull_bmp.dds')) -- Skull bitmap
        slot.state:DisableHitTest()
        slot.state:Hide()
        LayoutHelpers.AtRightTopIn(slot.state, slot, 2, 2)

        slot.ping = UIUtil.CreateText(slot, "", 14, UIUtil.fixedFont)
        LayoutHelpers.AtLeftTopIn(slot.ping, slot, 5, 32)

        slot.quiet = UIUtil.CreateText(slot, "", 14, UIUtil.fixedFont)
        LayoutHelpers.AtLeftTopIn(slot.quiet, slot, 120, 32)

        slot.ejectedBy = UIUtil.CreateText(slot, '', 16, UIUtil.fixedFont)
        slot.ejectedBy:SetColor('FFbadbdb')
        LayoutHelpers.AtRightTopIn(slot.ejectedBy, slot, 5, 4)

        slot.eject = UIUtil.CreateButtonStd(slot, '/widgets02/small', "<LOC UI_Disco0005>Eject From Game", 12, 0)
        slot.eject.label:SetFont(UIUtil.bodyFont, 12)
        LayoutHelpers.AtLeftTopIn(slot.eject, slot, 248, 24)
        slot.eject.OnClick = function(self, modifiers) EjectSessionClient(slot.index) end
        slot.eject:Disable() -- Disable all temporarily so they can't be misclicked, then unlock a few seconds later
    end

    -- retrieve disconnection delay and reduce it by five (that is how long it takes for the window to show)
    local disconnectionDelay = 85
    if scenario.Options.DisconnectionDelay02 then 
        disconnectionDelay = tonumber(scenario.Options.DisconnectionDelay02) - 5
    end

    local canEject = false
    local canEjectTime = disconnectionDelay
    local forceEject = false
    local forceEjectTime = math.max(disconnectionDelay * 2, 85)

    parent.OnFrame = function(self, delta)
        self.time = self.time + delta
        if self.time > forceEjectTime then
            forceEject = true
        elseif self.time > canEjectTime then
            canEject = true
        end
    end

    parent.Width:Set(function() return slots[1].Width() - 100 end)
    parent.Height:Set(function() return slots[1].Height() * table.getsize(slots) - 34 end)

    LayoutHelpers.AtCenterIn(parent, GetFrame(0))

    function parent.Update(self, clients)
        for index, client in clients do
            local slot = slots[index]
            local armiesInfo = GetArmiesTable().armiesTable

            if client.connected then
                if client.quiet < 5000 then -- Nobody is lagging
                    if canEject then
                        slot.eject:Disable()
                    end
                    slot.ping:SetText(LOCF("%s: %d", "<LOC UI_Disco0003>Ping (ms)", client.ping))
                    slot.quiet:SetText('')
                    slot.ping:SetColor('FFbadbdb')
                    slot.quiet:SetColor('FFbadbdb')
                else -- Someone is lagging
                    if forceEject then -- Lag has been going on for more than forceEjectTime
                        EjectSessionClient(index)
                        slot.eject:Disable()
                        slot.eject:Hide()
                    elseif armiesInfo[myIndex].outOfGame and canEject then -- If I am Observer
                        EjectSessionClient(index) -- Autokick the lagging player
                        slot.eject:Disable()
                        slot.eject:Hide()
                    elseif canEject then -- Someone has been quite longer than canEjectTime
                        slot.eject:Enable()
                    end
                    slot.ping:SetText(LOCF("%s: ---", "<LOC UI_Disco0003>Ping (ms)"))
                    slot.ping:SetColor('FFe24f2d')
                    slot.quiet:SetColor('FFe24f2d')
                    local min = client.quiet / (1000 * 60)
                    local sec = math.mod(client.quiet / 1000, 60)
                    slot.quiet:SetText(LOCF("%s: %d:%02d", "<LOC UI_Disco0004>Quiet (m:s)",min,sec))
                end
            else
                slot.ping:SetText(LOC("<LOC connectivity_0003>Not Connected"))
                slot.ping:SetColor('FFff0000')
            end

            if armiesInfo[index].outOfGame then -- Show the skull if the player is dead
                slot.state:Show()
                LayoutHelpers.AtRightTopIn(slot.ejectedBy, slot, 34, 4)
            else
                LayoutHelpers.AtRightTopIn(slot.ejectedBy, slot, 5, 4)
                slot.state:Hide()
            end

            local ejectedBy = ''
            for k, v in client.ejectedBy do
                if ejectedBy != '' then
                    ejectedBy = ejectedBy .. ', ' .. tostring(v)
                else
                    ejectedBy = LOC('<LOC UI_Disco0006>Ejected by')..': '..tostring(v)
                end
            end
            slot.ejectedBy:SetText(ejectedBy)

            if client.connected and not client['local'] then
                if slot.eject:IsHidden() then slot.eject:Show() end
            else
                if not slot.eject:IsHidden() then slot.eject:Hide() end
            end
        end
    end
end

function Update()
    local needDialog = false
    local clients = GetSessionClients()
    local stillin = {}

    for index, client in clients do
        if client.connected then
            table.insert(stillin, index)
        end
    end

    local quietClients = {}
    for index, client in clients do
        if client.quiet > 5000 then
            table.insert(quietClients, client.name)
            needDialog = true
        end
        if client.connected then
            if not table.equal(client.ejectedBy, {}) then
                needDialog = true
            end
        else
            if not table.equal(table.sorted(client.ejectedBy), stillin) then
                needDialog = true
            end
        end
    end

    if needDialog then
        if not parent then
            -- Log disconnections so that occurance can be tracked when watching a replay
            WARN('Connection dialogue opening due to disconnection by players:')
            for k, v in quietClients do
                LOG(v)
            end

            CreateDialog(clients)
        end
        parent:Update(clients)
    else
        if parent then DestroyConnectivityDialog() end
    end

end

-- kept for mod backwards compatibility
local Text = import("/lua/maui/text.lua").Text
local Button = import("/lua/maui/button.lua").Button
local LazyVar = import("/lua/lazyvar.lua").Create

-- faf-re engine only: the rows of players taking a seat back (Draiget/faf-re#275).
-- GetEngineInfo exists only in faf-re, so on the original executable none of this runs.
if rawget(_G, 'GetEngineInfo') then
    -- Draiget/faf-re#275: while a player takes a seat back, the engine leaves `rejoinStage`
    -- (and `rejoinProgress` where the stage has a measure) in that player's
    -- GetSessionClients entry. While they are lost, the Connectivity dialog above is
    -- open as ever. From the moment they are on their way back the engine doesn't report
    -- them as quiet, so that dialog and its auto-eject go away, and this one takes its
    -- place: the same dialog to look at, whose row for that player says how far they have
    -- got and keeps an eject button. The player coming back has the screen in
    -- /lua/ui/uimain.lua instead. Without that field, which is every game where not all
    -- clients announced rejoin, this never shows. If a returning player stops reporting,
    -- the engine says "lost" again and the Connectivity dialog comes back. A player who
    -- is back gets the announcement a defeated player gets.

    do
        local UIUtil = import("/lua/ui/uiutil.lua")
        local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
        local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
        local Group = import("/lua/maui/group.lua").Group
        local SessionClients = import("/lua/ui/override/sessionclients.lua")

        local trackWidth = 236
        local dialog = false
        -- What this dialog keeps about each return, over a reload of this module too: while the new module
        -- loads, /lua/system/import.lua hands it the old one as `__moduleinfo.old`. Without that a reload would
        -- start each eject delay again and announce again a player who is already back.
        local previous = __moduleinfo.old and rawget(__moduleinfo.old, 'RejoinState')
        RejoinState = previous or {stages = {}, stageStarts = {}, returnStarts = {}, announcedBack = {}}
        local stages = RejoinState.stages
        local stageStarts = RejoinState.stageStarts
        local returnStarts = RejoinState.returnStarts
        local announcedBack = RejoinState.announcedBack

        -- The wait before a lagging player's eject button unlocks in `CreateDialog` above. A returning
        -- player's button waits as long from when their return began, so a click meant for the game
        -- can't land on it when the dialog opens.
        local function EjectDelay()
            local delay = SessionGetScenarioInfo().Options.DisconnectionDelay02
            if delay then
                return tonumber(delay) - 5
            end
            return 85
        end

        local function ElapsedText(seconds)
            return string.format("%d:%02d", math.floor(seconds / 60), math.mod(math.floor(seconds), 60))
        end

        local function PercentText(client)
            if client.rejoinProgress then
                return string.format(": %d%%", math.floor(client.rejoinProgress * 100))
            end
            return ''
        end

        --- A returning player reports every second. Loading a map can go quiet by itself.
        local function IsSilent(client)
            local allowed = 5
            if client.rejoinStage == 'loading' then
                allowed = 30
            end
            return client.rejoinSilent and client.rejoinSilent > allowed
        end

        --- What the row says for the stage the player is in.
        local function StageText(index, client)
            local stage = client.rejoinStage
            if stage == 'transfer' then
                return LOC("<LOC rejoin_0004>Step 1 of 3: receiving the game") .. PercentText(client)
            elseif stage == 'loading' then
                return LOC("<LOC rejoin_0005>Step 2 of 3: loading the map")
                    .. ' (' .. ElapsedText(GetSystemTimeSeconds() - stageStarts[index]) .. ')'
            elseif stage == 'catchingUp' then
                return LOC("<LOC rejoin_0006>Step 3 of 3: catching up") .. PercentText(client)
            end
            return ''
        end

        --- As /lua/ui/game/gameresult.lua tells of a defeated player: the announcement
        --- goes to that player's line on the score board. With no line to find (FAF's
        --- option to hide player names, or no score board), it still shows, from the top.
        local function AnnounceBack(client)
            LOG('REJOIN: showing ' .. client.name .. ' as back')

            local text
            if client['local'] then
                text = LOC("<LOC rejoin_0001>You are back in the game!")
            else
                text = LOCF("<LOC rejoin_0007>%s is back in the game!", client.name)
            end
            for army, info in GetArmiesTable().armiesTable do
                -- false: no line for that army. A score board that returns nothing showed it.
                if info.nickname == client.name and import("/lua/ui/game/score.lua").ArmyAnnounce(army, text) ~= false then
                    return
                end
            end
            import("/lua/ui/game/announcement.lua").CreateAnnouncement(text)
        end

        --- On their way back, which is when this dialog speaks for them.
        local function IsReturning(client)
            return client.connected and client.rejoinStage and client.rejoinStage != 'lost'
                and client.rejoinStage != 'back' and not client['local']
        end

        local function CreateSlot(bg, index, client)
            local slot = Bitmap(bg, UIUtil.UIFile('/scx_menu/panel-brd/conn-bg.dds'))

            slot.id = UIUtil.CreateText(slot, index, 20, UIUtil.fixedFont)
            slot.id:SetColor('ffffffff')
            LayoutHelpers.AtLeftTopIn(slot.id, slot, 5, 1)

            slot.name = UIUtil.CreateText(slot, client.name, 16, UIUtil.fixedFont)
            slot.name:SetColor('FFbadbdb')
            LayoutHelpers.AtLeftTopIn(slot.name, slot, 20, 4)

            slot.state = Bitmap(slot)
            slot.state:SetTexture(UIUtil.UIFile('/game/unit-over/icon-skull_bmp.dds'))
            slot.state:DisableHitTest()
            slot.state:Hide()
            LayoutHelpers.AtRightTopIn(slot.state, slot, 2, 2)

            slot.ping = UIUtil.CreateText(slot, '', 14, UIUtil.fixedFont)
            LayoutHelpers.AtLeftTopIn(slot.ping, slot, 5, 32)

            slot.ejectedBy = UIUtil.CreateText(slot, '', 16, UIUtil.fixedFont)
            slot.ejectedBy:SetColor('FFbadbdb')
            LayoutHelpers.AtRightTopIn(slot.ejectedBy, slot, 5, 4)

            slot.status = UIUtil.CreateText(slot, '', 13, UIUtil.bodyFont)
            slot.status:SetColor('FFbadbdb')
            LayoutHelpers.AtLeftTopIn(slot.status, slot, 5, 24)

            slot.track = Bitmap(slot)
            slot.track:SetSolidColor('ff303030')
            slot.track:DisableHitTest()
            LayoutHelpers.SetDimensions(slot.track, trackWidth, 8)
            LayoutHelpers.AtLeftTopIn(slot.track, slot, 5, 44)

            slot.fill = Bitmap(slot.track)
            slot.fill:SetSolidColor('ff4fa0e0')
            slot.fill:DisableHitTest()
            LayoutHelpers.SetDimensions(slot.fill, 1, 8)
            LayoutHelpers.AtLeftTopIn(slot.fill, slot.track, 0, 0)

            slot.eject = UIUtil.CreateButtonStd(slot, '/widgets02/small', "<LOC UI_Disco0005>Eject From Game", 12, 0)
            slot.eject.label:SetFont(UIUtil.bodyFont, 12)
            LayoutHelpers.AtLeftTopIn(slot.eject, slot, 248, 24)
            slot.eject.OnClick = function(self, modifiers)
                EjectSessionClient(index)
            end
            slot.eject:Disable()

            return slot
        end

        --- As `CreateDialog` above lays out the Connectivity dialog, so this one replaces it where it stood.
        local function CreateRejoinDialog(clients)
            SessionClients.FastInterval()
            GetCursor():Show()

            local group = Group(GetFrame(0))
            group.Depth:Set(GetFrame(0):GetTopmostDepth() + 1)

            local bg = Bitmap(group, UIUtil.UIFile('/scx_menu/panel-brd/panel_brd_m.dds'))
            LayoutHelpers.FillParent(bg, group)
            bg.border = UIUtil.CreateSCXMenuPanelBorder(bg)

            local title = UIUtil.CreateText(bg, "<LOC UI_Disco0000>Connectivity", 18)
            LayoutHelpers.AtTopIn(title, bg, -52)
            LayoutHelpers.AtHorizontalCenterIn(title, group)

            group.slots = {}
            local previous = false
            for index, client in clients do
                local slot = CreateSlot(bg, index, client)
                group.slots[index] = slot
                if previous then
                    LayoutHelpers.Below(slot, previous)
                else
                    LayoutHelpers.AtTopIn(slot, group)
                    LayoutHelpers.AtHorizontalCenterIn(slot, group)
                end
                previous = slot
            end

            group.Width:Set(function() return previous.Width() - 100 end)
            group.Height:Set(function() return previous.Height() * table.getsize(group.slots) - 34 end)
            LayoutHelpers.AtCenterIn(group, GetFrame(0))
            return group
        end

        local function DestroyRejoinDialog()
            if dialog then
                dialog:Destroy()
                dialog = false
                SessionClients.ResetInterval()
            end
        end

        --- A reload of this module closes the rejoin dialog too. `Update` above closes only the
        --- Connectivity dialog, so a return in progress keeps its dialog.
        local baseDestroyDialog = DestroyDialog
        function DestroyDialog()
            baseDestroyDialog()
            DestroyRejoinDialog()
        end

        local function UpdateSlot(slot, index, client, armies)
            if IsReturning(client) then
                slot.ping:Hide()
                slot.status:Show()
                slot.track:Show()
                if IsSilent(client) then
                    slot.status:SetText(LOCF("<LOC rejoin_0008>No response for %s", ElapsedText(client.rejoinSilent)))
                    slot.status:SetColor('FFe24f2d')
                    slot.fill:SetSolidColor('ff707070')
                    if not slot.silent then
                        slot.silent = true
                        LOG('REJOIN: showing ' .. client.name .. ' as not responding')
                    end
                else
                    slot.status:SetText(StageText(index, client))
                    slot.status:SetColor('FFbadbdb')
                    slot.fill:SetSolidColor('ff4fa0e0')
                    slot.silent = false
                end
                if IsSilent(client) then
                    -- The bar stays where it stopped.
                elseif client.rejoinProgress then
                    LayoutHelpers.AtLeftTopIn(slot.fill, slot.track, 0, 0)
                    LayoutHelpers.SetWidth(slot.fill, math.max(1, trackWidth * client.rejoinProgress))
                else
                    -- No measure: a block that travels, so it can't be read as a percentage.
                    local blockWidth = 60
                    local travelled = math.mod(GetSystemTimeSeconds() - stageStarts[index], 3) / 3
                    LayoutHelpers.AtLeftTopIn(slot.fill, slot.track, (trackWidth - blockWidth) * travelled, 0)
                    LayoutHelpers.SetWidth(slot.fill, blockWidth)
                end
                slot.eject:Show()
                if GetSystemTimeSeconds() - returnStarts[index] >= EjectDelay() then
                    if slot.eject:IsDisabled() then
                        slot.eject:Enable()
                    end
                elseif not slot.eject:IsDisabled() then
                    slot.eject:Disable()
                end
            else
                slot.status:Hide()
                slot.track:Hide()
                slot.eject:Hide()
                slot.ping:Show()
                if client.connected then
                    slot.ping:SetText(LOCF("%s: %d", "<LOC UI_Disco0003>Ping (ms)", client.ping))
                    slot.ping:SetColor('FFbadbdb')
                else
                    slot.ping:SetText(LOC("<LOC connectivity_0003>Not Connected"))
                    slot.ping:SetColor('FFff0000')
                end
            end

            if armies[index] and armies[index].outOfGame then
                slot.state:Show()
                LayoutHelpers.AtRightTopIn(slot.ejectedBy, slot, 34, 4)
            else
                slot.state:Hide()
                LayoutHelpers.AtRightTopIn(slot.ejectedBy, slot, 5, 4)
            end

            local ejectedBy = ''
            for _, by in client.ejectedBy do
                if ejectedBy != '' then
                    ejectedBy = ejectedBy .. ', ' .. tostring(by)
                else
                    ejectedBy = LOC('<LOC UI_Disco0006>Ejected by') .. ': ' .. tostring(by)
                end
            end
            slot.ejectedBy:SetText(ejectedBy)
        end

        local baseUpdate = Update
        local engineClients = GetSessionClients

        --- What the Connectivity dialog above goes by: it opens on any vote to eject, and a vote
        --- against a returning player shows on their row in this dialog instead. The engine's list
        --- is cached (/lua/ui/override/sessionclients.lua), and this dialog reads the votes from it,
        --- so the list it hands on is a copy.
        function GetSessionClients()
            local clients = engineClients() or {}
            local copy = {}
            for index, client in clients do
                if IsReturning(client) then
                    client = table.copy(client)
                    client.ejectedBy = {}
                end
                copy[index] = client
            end
            return copy
        end

        --- The rest of what opens the Connectivity dialog: see `Update` above.
        local function ConnectivityIsOpen(clients)
            local stillin = {}
            for index, client in clients do
                if client.connected then
                    table.insert(stillin, index)
                end
            end
            for _, client in clients do
                if client.quiet > 5000 then
                    return true
                end
                if client.connected then
                    if not IsReturning(client) and not table.equal(client.ejectedBy, {}) then
                        return true
                    end
                elseif not table.equal(table.sorted(client.ejectedBy), stillin) then
                    return true
                end
            end
            return false
        end

        function Update()
            baseUpdate()

            local clients = engineClients() or {}
            local anyReturning = false
            local connectivityOpen = ConnectivityIsOpen(clients)

            for index, client in clients do
                local stage = client.rejoinStage
                if stage == 'back' then
                    stages[index] = nil
                    returnStarts[index] = nil
                    if not announcedBack[index] then
                        announcedBack[index] = true
                        AnnounceBack(client)
                    end
                else
                    announcedBack[index] = nil
                    if client.connected and stage and not client['local'] then
                        if stages[index] != stage then
                            stages[index] = stage
                            stageStarts[index] = GetSystemTimeSeconds()
                            LOG('REJOIN: showing ' .. client.name .. ' as ' .. stage)
                        end
                    else
                        stages[index] = nil
                    end
                    if IsReturning(client) then
                        anyReturning = true
                        returnStarts[index] = returnStarts[index] or GetSystemTimeSeconds()
                    else
                        returnStarts[index] = nil
                    end
                end
            end

            if not anyReturning then
                DestroyRejoinDialog()
                return
            end

            if not dialog then
                dialog = CreateRejoinDialog(clients)
            end

            -- Another player can be lost meanwhile, with the Connectivity dialog back where this one stands.
            if dialog.belowTop != connectivityOpen then
                dialog.belowTop = connectivityOpen
                if connectivityOpen then
                    LayoutHelpers.AtTopIn(dialog, GetFrame(0), 90)
                else
                    LayoutHelpers.AtCenterIn(dialog, GetFrame(0))
                end
            end

            local armies = GetArmiesTable().armiesTable
            for index, client in clients do
                if dialog.slots[index] then
                    UpdateSlot(dialog.slots[index], index, client, armies)
                end
            end
        end
    end
end
