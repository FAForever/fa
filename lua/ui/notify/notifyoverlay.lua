-- This file contains the functions which deal with creating and updating ETA overlay for ACU upgrades

local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local defaultMessages = import("/lua/ui/notify/defaultmessages.lua").defaultMessages
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local UIUtil = import("/lua/ui/uiutil.lua")
local Prefs = import("/lua/user/prefs.lua")
local AddChatCommand = import("/lua/ui/notify/commands.lua").AddChatCommand

local overlayDisabled
local overlayLockedOut
local customMessagesDisabled
overlays = {}

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

    customMessagesDisabled = Prefs.GetFromCurrentProfile('Notify_custom_disabled')

    overlayLockedOut = Prefs.GetFromCurrentProfile('Notify_all_disabled')
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
        Prefs.SavePreferences()
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

function toggleCustomMessages(bool)
    customMessagesDisabled = bool
    for _, overlay in overlays do
        if customMessagesDisabled then
            overlay.name = defaultMessages[overlay.category][overlay.source]
        else
            overlay.name = overlay.customName
        end
    end
end

-- This is called when we recieve a chat message from another player in the 'NotifyOverlay' chat channel
-- These messages are generated below in generateEnhancementMessage or sendDestroyOverlayMessage
function processNotification(players, msg)
    if not overlayDisabled and not overlayLockedOut then
        updateEnhancementOverlay(msg.data)
    end
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
    overlay.id = args.id
    overlay.pos = args.pos
    overlay.eta = args.eta
    overlay.lastUpdate = GetGameTimeSeconds()

    if customMessagesDisabled then
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

    overlay.progress = UIUtil.CreateText(overlay, overlay.name .. " " .. args.progress .. "%", 12, UIUtil.bodyFont)
    overlay.progress:SetColor('white')
    overlay.progress:SetDropShadow(true)
    LayoutHelpers.AtCenterIn(overlay.progress, overlay, -15, 0)

    overlay.etaText = UIUtil.CreateText(overlay, 'ETA', 10, UIUtil.bodyFont)
    overlay.etaText:SetColor('white')
    overlay.etaText:SetDropShadow(true)
    LayoutHelpers.AtCenterIn(overlay.etaText, overlay, 15, 0)

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
        overlay.progress:SetText(overlay.name .. " " .. args.progress .. "%")
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

    local tick = GameTick()
    local seconds = GetGameTimeSeconds()

    if tick == lastTick then
        return
    end

    local progress = unit:GetWorkProgress()
    local percent = math.floor(progress * 100)
    if lastTick then
        local eta = -1
        if progress > lastProgress then
            eta = seconds + ((tick - lastTick) / 10) * ((1 - progress) / (progress - lastProgress))
        end

        local pos = unit:GetPosition()

        if lastMessage and (seconds - lastMessage >= 3) or math.abs(eta - data.eta) > 1 or VDist3Sq(pos, data.pos) > 0.0001 or percent ~= lastPercent then
            data.eta = eta
            data.pos = pos
            data.last_message = seconds
            msg.data = table.merged(msg.data, {progress = percent, eta = eta, pos = pos})
            import("/lua/ui/notify/notify.lua").sendMessage(msg)
        end
    end

    data.last_tick = tick
    data.last_progress = progress
    data.last_percent = percent
end

function sendDestroyOverlayMessage(id)
    local msg = {to = 'allies', NotifyOverlay = true, data = {id = id, destroy = true}}
    import("/lua/ui/notify/notify.lua").sendMessage(msg)
end