-- This file contains all functions governing the integrated Notify mod, which sends messages to allies
-- when you order and complete ACU upgrades

local RegisterChatFunc = import('/lua/ui/game/gamemain.lua').RegisterChatFunc
local Prefs = import('/lua/user/prefs.lua')
local FindClients = import('/lua/ui/game/chat.lua').FindClients
local defaultMessages = import('/lua/ui/notify/defaultmessages.lua').defaultMessages
local AddChatCommand = import('/lua/ui/notify/commands.lua').AddChatCommand
local NotifyOverlay = import('/lua/ui/notify/notifyoverlay.lua')
local setOverlayDisabled = NotifyOverlay.setOverlayDisabled

local chatDisabled
local chatChannel = 'Notify'
local messages = {}
local ACUs = {}

function init(isReplay, parent)
    RegisterChatFunc(NotifyOverlay.processNotification, chatChannel)
    AddChatCommand('enablenotify', toggleNotify)
    AddChatCommand('disablenotify', toggleNotify)
    AddChatCommand('enablenotifychat', toggleNotifyChat)
    AddChatCommand('disablenotifychat', toggleNotifyChat)
    AddChatCommand('enablenotifyoverlay', NotifyOverlay.toggleNotifyOverlay)
    AddChatCommand('disablenotifyoverlay', NotifyOverlay.toggleNotifyOverlay)

    populateMessages()

    chatDisabled = Prefs.GetFromCurrentProfile('Notify_Chat_Disabled')
    local overlayDisabled = Prefs.GetFromCurrentProfile('Notify_Overlay_Disabled')

    -- Enable Notify by default
    if chatDisabled == nil then
        Prefs.SetToCurrentProfile('Notify_Chat_Disabled', false)
        Prefs.SavePreferences()
    end

    if overlayDisabled == nil then
        overlayDisabled = false
        Prefs.SetToCurrentProfile('Notify_Overlay_Disabled', false)
        Prefs.SavePreferences()
    end

    setOverlayDisabled(overlayDisabled)
end

function populateMessages()
    local prefsMessages = Prefs.GetFromCurrentProfile('Notify_Messages')
    if prefsMessages then
        messages = prefsMessages
    else
        messages = defaultMessages2
        Prefs.SetToCurrentProfile('Notify_Messages', messages)
    end
end

function toggleNotify(args)
    if args[1] == 'enablenotify' then
        chatDisabled = false
        setOverlayDisabled(false)
        print 'Notify Enabled'
    elseif args[1] == 'disablenotify' then
        chatDisabled = true
        setOverlayDisabled(true)
        print 'Notify Disabled'
    end

    -- Set it permanently unless specified
    if not args[2] or args[2] ~= 'once' then
        Prefs.SetToCurrentProfile('Notify_Chat_Disabled', chatDisabled)
        Prefs.SetToCurrentProfile('Notify_Overlay_Disabled', NotifyOverlay.getOverlayDisabled)
        Prefs.SavePreferences()
    end
end

function toggleNotifyChat(args)
    if args[1] == 'enablenotifychat' then
        chatDisabled = false
        print 'Notify Chat Enabled'
    elseif args[1] == 'disablenotifychat' then
        chatDisabled = true
        print 'Notify Chat Disabled'
    end

    if not args[2] or args[2] ~= 'once' then
        Prefs.SetToCurrentProfile('Notify_Chat_Disabled', chatDisabled)
        Prefs.SavePreferences()
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

function sendEnhancementMessage(messageTable)
    local enh = messageTable.enh
    local faction = messageTable.faction
    if not messages[faction][enh] then return end

    local id = messageTable.id
    local trigger = messageTable.trigger

    if trigger == 'started' then
        onStartEnhancement(id, faction, enh)
    elseif trigger == 'cancelled' then
        onCancelledEnhancement(id, faction, enh)
    elseif trigger == 'completed' then
        onCompletedEnhancement(id, faction, enh)
    end
end

function onStartEnhancement(id, faction, enh)
    local msg = {to = 'allies', Chat = true, text = 'Upgrading ' .. messages[faction][enh]}

    -- Start by storing entity IDs for future use
    if not ACUs[id] then
        ACUs[id] = {watcher = false, startTime = 0}
    end

    local data = ACUs[id]
    data.startTime = GetGameTimeSeconds()

    if not chatDisabled then
        SessionSendChatMessage(FindClients(), msg)
    end

    -- If we're not already working, watch this one
    if not data.watcher then
        data.watcher = ForkThread(watchEnhancement, id, enh)
    end
end

function onCancelledEnhancement(id, faction, enh)
    local msg = {to = 'allies', Chat = true, text = messages[faction][enh] .. ' cancelled'}

    local data = ACUs[id]
    if data then
        if not chatDisabled then
            SessionSendChatMessage(FindClients(), msg)
        end

        killWatcher(data)
        NotifyOverlay.sendDestroyOverlayMessage(id)
    end
end

-- Called from the enhancement watcher
function onCompletedEnhancement(id, faction, enh)
    local msg = {to = 'allies', Chat = true}

    local data = ACUs[id]
    if data then
        if not chatDisabled then
            msg.text = messages[faction][enh] .. ' done! (' .. round(GetGameTimeSeconds() - data.startTime, 2) .. 's)'
            SessionSendChatMessage(FindClients(), msg)
        end

        killWatcher(data)
        NotifyOverlay.sendDestroyOverlayMessage(id)
    end
end

function killWatcher(data)
    if data.watcher then
        KillThread(data.watcher)
        data.watcher = false
    end
end

function watchEnhancement(id, enh)
    local overlayData = {}
    overlayData.unit = GetUnitById(id)
    overlayData.pos = overlayData.unit:GetPosition()
    overlayData.msg = {to = 'allies', Notify = true}
    overlayData.id = id
    overlayData.eta = -1

    while true do
        NotifyOverlay.generateEnhancementMessage(overlayData)
        WaitSeconds(0.1)
    end
end
