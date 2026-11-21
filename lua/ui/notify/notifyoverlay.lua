-- This file contains the functions which deal with creating and updating ETA overlay for ACU upgrades

local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local defaultMessages = import("/lua/ui/notify/defaultmessages.lua").defaultMessages
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local UIUtil = import("/lua/ui/uiutil.lua")
local Prefs = import("/lua/user/prefs.lua")
local AddChatCommand = import("/lua/ui/notify/commands.lua").AddChatCommand

local overlayDisabled
local overlayLockedOut
local overlayTextSize
local overlayEtaSize
local categoryOverlayDisabled = {}
local categoryDisabled = {}
local customMessagesDisabled = {}
local selfOnly = {}
local notificationCategories = {'acus', 'experimentals', 'tech', 'other'}
local factions = import("/lua/factions.lua").FactionIndexMap
overlays = {}

local function getNotificationCategory(category)
    if factions[category] then
        return 'acus'
    end
    return category
end

function init()
    import("/lua/ui/game/gamemain.lua").RegisterChatFunc(processNotification, 'NotifyOverlay') -- Imported here to avoid loading the file before the game is fully initialized
    AddChatCommand('enablenotifyoverlay', toggleOverlayTemporary)
    AddChatCommand('disablenotifyoverlay', toggleOverlayTemporary)

    local state = Prefs.GetFromCurrentProfile('Notify_overlay_disabled')
    if state == nil then
        Prefs.SetToCurrentProfile('Notify_overlay_disabled', false)
        state = false
    end
    overlayDisabled = state

    local legacyCustomDisabled = Prefs.GetFromCurrentProfile('Notify_custom_disabled') or false
    for _, category in notificationCategories do
        categoryDisabled[category] = Prefs.GetFromCurrentProfile('Notify_' .. category .. '_disabled') or false

        local overlayFlag = 'Notify_' .. category .. '_overlay_disabled'
        state = Prefs.GetFromCurrentProfile(overlayFlag)
        if state == nil then
            state = overlayDisabled
            Prefs.SetToCurrentProfile(overlayFlag, state)
        end
        categoryOverlayDisabled[category] = state

        customMessagesDisabled[category] = Prefs.GetFromCurrentProfile('Notify_' .. category .. '_custom_disabled')
        if customMessagesDisabled[category] == nil then
            customMessagesDisabled[category] = legacyCustomDisabled
        end

        selfOnly[category] = Prefs.GetFromCurrentProfile('Notify_' .. category .. '_self_only') or false
    end
    -- The former global preference only seeds the category preferences above.
    -- Keep the runtime global available for chat commands, but do not let a stale
    -- global value override the new per-category controls.
    overlayDisabled = false
    Prefs.SetToCurrentProfile('Notify_overlay_disabled', false)

    overlayLockedOut = Prefs.GetFromCurrentProfile('Notify_all_disabled')

    overlayTextSize = math.max(6, math.min(24, Prefs.GetFromCurrentProfile('Notify_overlay_text_size') or 12))
    overlayEtaSize = math.max(6, math.min(24, Prefs.GetFromCurrentProfile('Notify_overlay_eta_size') or 10))
    Prefs.SetToCurrentProfile('Notify_overlay_text_size', overlayTextSize)
    Prefs.SetToCurrentProfile('Notify_overlay_eta_size', overlayEtaSize)
end

function setOverlayTextSize(size)
    overlayTextSize = math.max(6, math.min(24, math.floor(size)))
    Prefs.SetToCurrentProfile('Notify_overlay_text_size', overlayTextSize)
    for _, overlay in overlays do
        if overlay.progress then
            overlay.progress:SetFont(UIUtil.bodyFont, overlayTextSize)
        end
    end
end

function setOverlayEtaSize(size)
    overlayEtaSize = math.max(6, math.min(24, math.floor(size)))
    Prefs.SetToCurrentProfile('Notify_overlay_eta_size', overlayEtaSize)
    for _, overlay in overlays do
        if overlay.etaText then
            overlay.etaText:SetFont(UIUtil.bodyFont, overlayEtaSize)
        end
    end
end

function destroyOverlays()
    if overlayDisabled or overlayLockedOut then
        for _, overlay in overlays do
            overlay.destroy = true
        end
    end
end

-- Called from notify.lua after the main button permanently disables things
-- Also from the toggle button for temporary changes
function toggleOverlay(bool, lockout)
    if lockout then
        overlayLockedOut = bool
    else
        overlayDisabled = bool
        Prefs.SetToCurrentProfile('Notify_overlay_disabled', bool)
        if not overlayDisabled then
            print 'Notify Overlay Enabled'
        elseif overlayDisabled then
            print 'Notify Overlay Disabled'
        end
    end

    destroyOverlays()
end

-- Called only by the chat commands
function toggleOverlayTemporary(args)
    if args[1] == 'enablenotifyoverlay' then
        overlayDisabled = false
        print 'Notify Overlay Enabled'
    elseif args[1] == 'disablenotifyoverlay' then
        overlayDisabled = true
        print 'Notify Overlay Disabled'
    end

    destroyOverlays()
end

function toggleCustomMessages(category, bool)
    customMessagesDisabled[category] = bool
    for _, overlay in overlays do
        if getNotificationCategory(overlay.category) ~= category then
            continue
        end
        if bool then
            overlay.name = defaultMessages[overlay.category][overlay.source]
        else
            overlay.name = overlay.customName
        end
    end
end

-- This is called when we recieve a chat message from another player in the 'NotifyOverlay' chat channel
-- These messages are generated below in generateEnhancementMessage or sendDestroyOverlayMessage
function processNotification(players, msg)
    local category = getNotificationCategory(msg.data.category)
    if overlayDisabled or overlayLockedOut or categoryDisabled[category] or categoryOverlayDisabled[category] then
        return
    end
    if selfOnly[category] and msg.notifyFrom ~= GetFocusArmy() then
        return
    end
    updateEnhancementOverlay(msg.data)
end

function toggleCategoryOverlay(category, bool)
    categoryOverlayDisabled[category] = bool
    Prefs.SetToCurrentProfile('Notify_' .. category .. '_overlay_disabled', bool)
    if bool then
        for _, overlay in overlays do
            if getNotificationCategory(overlay.category) == category then
                overlay.destroy = true
            end
        end
    end
end

function toggleCategory(category)
    categoryDisabled[category] = not categoryDisabled[category]
    if categoryDisabled[category] then
        for _, overlay in overlays do
            if getNotificationCategory(overlay.category) == category then
                overlay.destroy = true
            end
        end
    end
end

function toggleSelfOnly(category)
    selfOnly[category] = not selfOnly[category]
end

function round(num, idp)
    if not idp then
        return tonumber(string.format("%." .. (idp or 0) .. "f", num))
    else
          local mult = math.pow(10, (idp or 0))
        return math.floor(num * mult + 0.5) / mult
      end
end

function createEnhancementOverlay(args)
    local overlay = Bitmap(GetFrame(0))

    LayoutHelpers.SetDimensions(overlay, 100, 50)
    overlay.customName = args.text
    overlay.category = args.category
    overlay.source = args.source
    overlay.isACU = factions[overlay.category] ~= nil
    overlay.showName = overlay.isACU or overlay.category == 'tech' or overlay.category == 'other'
    overlay.showETA = overlay.isACU or overlay.category == 'experimentals'
    overlay.id = args.id
    overlay.pos = args.pos
    overlay.eta = args.eta
    overlay.siloStatus = args.siloStatus ~= nil
    overlay.lastUpdate = GetGameTimeSeconds()

    if customMessagesDisabled[getNotificationCategory(overlay.category)] then
        overlay.name = defaultMessages[overlay.category][overlay.source]
    else
        overlay.name = overlay.customName
    end

    overlay:SetNeedsFrameUpdate(true)
    overlay.OnFrame = function(self, delta)
        local seconds = GetGameTimeSeconds()
        if overlay.destroy or seconds - overlay.lastUpdate >= 4 then -- Timeout in case destroy message wasn't recieved
            overlays[overlay.id] = nil
            overlay:Destroy()
            return
        end

        local worldView = import("/lua/ui/game/worldview.lua").viewLeft
        local pos = worldView:Project(overlay.pos)

        if pos.x < 0 or pos.y < 0 or pos.x > worldView.Width() or pos.y > worldView:Height() then
            self:Hide()
        else
            self:Show()
        end

        LayoutHelpers.AtLeftTopIn(overlay, worldView, (pos.x - overlay.Width() / 2) / LayoutHelpers.GetPixelScaleFactor(), (pos.y - overlay.Height() / 2 + 1) / LayoutHelpers.GetPixelScaleFactor())

        if overlay.showETA and not overlay.siloStatus then
            local timeRemaining = math.ceil(overlay.eta - seconds)
            if timeRemaining ~= overlay.lastTimeRemaining then
                if timeRemaining >= 0 then
                    overlay.etaText:SetText("ETA " .. string.format("%.2d:%.2d", timeRemaining / 60, math.mod(timeRemaining, 60)))
                else
                    overlay.etaText:SetText("ETA --:--")
                end
                overlay.lastTimeRemaining = timeRemaining
            end
        end
    end

    local progressText = args.siloStatus or args.progress .. "%"
    if overlay.showName and not args.siloStatus then
        progressText = overlay.name .. " " .. progressText
    end
    overlay.progress = UIUtil.CreateText(overlay, progressText, overlayTextSize, UIUtil.bodyFont)
    overlay.progress:SetColor('white')
    overlay.progress:SetDropShadow(true)
    local progressOffset = overlay.isACU and -15 or overlay.showETA and -7 or 0
    LayoutHelpers.AtCenterIn(overlay.progress, overlay, progressOffset, 0)

    overlay.etaText = UIUtil.CreateText(overlay, 'ETA', overlayEtaSize, UIUtil.bodyFont)
    overlay.etaText:SetColor('white')
    overlay.etaText:SetDropShadow(true)
    LayoutHelpers.AtCenterIn(overlay.etaText, overlay, overlay.isACU and 15 or 7, 0)
    if not overlay.showETA or overlay.siloStatus then
        overlay.etaText:SetText('')
    end

    return overlay
end

function updateEnhancementOverlay(args)
    local destroy = args.destroy
    local id = args.id

    if not overlays[id] and not destroy then
        ForkThread(
            function()
                overlays[id] = createEnhancementOverlay(args)
            end
        )
        return
    end

    local overlay = overlays[id]

    -- Update an existing overlay
    if overlay then
        if destroy then
            overlay.destroy = destroy
            return
        end
        overlay.siloStatus = args.siloStatus ~= nil
        if overlay.siloStatus then
            overlay.progress:SetText(args.siloStatus)
            overlay.etaText:SetText('')
        elseif overlay.showName then
            overlay.progress:SetText(overlay.name .. " " .. args.progress .. "%")
        else
            overlay.progress:SetText(args.progress .. "%")
            if not overlay.showETA then
                overlay.etaText:SetText('')
            end
        end
        overlay.eta = args.eta
        overlay.pos = args.pos
        overlay.lastUpdate = GetGameTimeSeconds()
    end
end

function generateEnhancementMessage(data)
    local unit = data.unit
    local msg = data.msg
    local lastTick = data.last_tick
    local lastProgress = data.last_progress
    local lastPercent = data.last_percent
    local lastMessage = data.last_message
    local lastSiloStatus = data.last_silo_status

    local tick = GameTick()
    local seconds = GetGameTimeSeconds()

    if tick == lastTick then
        return
    end

    local progress
    local siloStatus
    if data.siloComplete then
        local missileInfo = unit:GetMissileInfo()
        local stored
        local building
        if msg.data.source == 'nuke' then
            stored = missileInfo.nukeSiloStorageCount
            building = missileInfo.nukeSiloBuildCount
        else
            stored = missileInfo.tacticalSiloStorageCount
            building = missileInfo.tacticalSiloBuildCount
        end

        if stored > 0 then
            siloStatus = string.format('%d', stored)
            progress = 0
        else
            progress = building > 0 and unit:GetWorkProgress() or 0
            siloStatus = string.format('%d%%', math.floor(progress * 100))
        end
    elseif msg.data.category == 'tech' or msg.data.category == 'experimentals' or msg.data.source == 'nuke' or msg.data.source == 'smd' or msg.data.source == 'arty' then
        progress = unit:GetFractionComplete()
    else
        progress = unit:GetWorkProgress()
    end
    local percent = math.floor(progress * 100)
    if lastTick then
        local eta = -1
        if progress > lastProgress then
            eta = seconds + ((tick - lastTick) / 10) * ((1 - progress) / (progress - lastProgress))
        end

        local pos = unit:GetPosition()

        if lastMessage and (seconds - lastMessage >= 3) or math.abs(eta - data.eta) > 1 or VDist3Sq(pos, data.pos) > 0.0001 or percent ~= lastPercent or siloStatus ~= lastSiloStatus then
            data.eta = eta
            data.pos = pos
            data.last_message = seconds
            msg.data = table.merged(msg.data, {progress = percent, eta = eta, pos = pos, siloStatus = siloStatus})
            import("/lua/ui/notify/notify.lua").sendMessage(msg)
        end
    end

    data.last_tick = tick
    data.last_progress = progress
    data.last_percent = percent
    data.last_silo_status = siloStatus
end

function sendDestroyOverlayMessage(id)
    local msg = {to = 'allies', NotifyOverlay = true, data = {id = id, destroy = true}}
    import("/lua/ui/notify/notify.lua").sendMessage(msg)
end
