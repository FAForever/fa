-- This file contains the functions which deal with creating and updating ETA overlay for ACU upgrades

local FindClients = import('/lua/ui/game/chat.lua').FindClients
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local UIUtil = import('/lua/ui/uiutil.lua')
local Prefs = import('/lua/user/prefs.lua')
local AddChatCommand = import('/lua/ui/notify/commands.lua').AddChatCommand
local RegisterChatFunc = import('/lua/ui/game/gamemain.lua').RegisterChatFunc

local overlayDisabled
overlays = {}

function init()
    RegisterChatFunc(NotifyOverlay.processNotification, 'NotifyOverlay')
    AddChatCommand('enablenotifyoverlay', NotifyOverlay.toggleNotifyOverlay)
    AddChatCommand('disablenotifyoverlay', NotifyOverlay.toggleNotifyOverlay)

    local state = Prefs.GetFromCurrentProfile('Notify_Overlay_Disabled')
    if state == nil then
        Prefs.SetToCurrentProfile('Notify_Overlay_Disabled', false)
        state = false
    end

    setOverlayDisabled(state)
    Prefs.SavePreferences()
end

function setOverlayDisabled(bool)
    overlayDisabled = bool
    Prefs.SetToCurrentProfile('Notify_Overlay_Disabled', bool)
    Prefs.SavePreferences()
end

function getOverlayDisabled()
    return overlayDisabled
end

function toggleNotifyOverlay(args)
    if args[1] == 'enablenotifyoverlay' then
        overlayDisabled = false
        print 'Notify Overlay Enabled'
    elseif args[1] == 'disablenotifyoverlay' then
        overlayDisabled = true
        print 'Notify Overlay Disabled'
    end

    if not args[2] or args[2] ~= 'once' then
        Prefs.SetToCurrentProfile('Notify_Overlay_Disabled', overlayDisabled)
        Prefs.SavePreferences()
    end
end

-- This is called when we recieve a chat message from another player in the 'Notify' chat channel
-- These messages are generated below in generateEnhancementMessage or sendDestroyOverlayMessage
function processNotification(players, msg)
    local args = msg.data
    if not overlayDisabled then
        updateEnhancementOverlay(args)
    end
end

function round(num, idp)
    if not idp then
        return tonumber(string.format("%." .. (idp or 0) .. "f", num))
    else
          local mult = 10 ^ (idp or 0)
        return math.floor(num * mult + 0.5) / mult
      end
end

function createEnhancementOverlay(args)
    local overlay = Bitmap(GetFrame(0))

    overlay.Width:Set(100)
    overlay.Height:Set(50)
    overlay.id = args.id
    overlay.pos = args.pos
    overlay.eta = args.eta
    overlay.lastUpdate = GetGameTimeSeconds()

    overlay:SetNeedsFrameUpdate(true)
    overlay.OnFrame = function(self, delta)
        local seconds = GetGameTimeSeconds()
        if overlay.destroy or seconds - overlay.lastUpdate >= 4 then -- Timeout in case destroy message wasn't recieved
            overlays[overlay.id] = nil
            overlay:Destroy()
            return
        end

        local worldView = import('/lua/ui/game/worldview.lua').viewLeft
        local pos = worldView:Project(overlay.pos)

        LayoutHelpers.AtLeftTopIn(overlay, worldView, pos.x - overlay.Width() / 2, pos.y - overlay.Height() / 2 + 1)

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

    overlay.progress = UIUtil.CreateText(overlay, args.progress .. "%", 12, UIUtil.bodyFont)
    overlay.progress:SetColor('white')
    overlay.progress:SetDropShadow(true)
    LayoutHelpers.AtCenterIn(overlay.progress, overlay, 15, 0)

    overlay.etaText = UIUtil.CreateText(overlay, 'ETA', 10, UIUtil.bodyFont)
    overlay.etaText:SetColor('white')
    overlay.etaText:SetDropShadow(true)
    LayoutHelpers.AtCenterIn(overlay.etaText, overlay, -15, 0)

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
        overlay.progress:SetText(args.progress .. "%")
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
            msg.data = {id = data.id, progress = percent, eta = eta, pos = pos}
            SessionSendChatMessage(FindClients(), msg)
        end
    end

    data.last_tick = tick
    data.last_progress = progress
    data.last_percent = percent
end

function sendDestroyOverlayMessage(id)
    local msg = {to = 'allies', NotifyOverlay = true, data = {id = id, destroy = true}}
    SessionSendChatMessage(FindClients(), msg)
end