-- This file contains all functions governing the integrated Notify mod, which sends messages to allies
-- when you order and complete ACU upgrades

local AddChatCommand = import('/lua/ui/notify/commands.lua').AddChatCommand
local NotifyOverlay = import('/lua/ui/notify/notifyoverlay.lua')
local RegisterChatFunc = import('/lua/ui/game/gamemain.lua').RegisterChatFunc
local Prefs = import('/lua/user/prefs.lua')
local defaultMessages = import('/lua/ui/notify/defaultmessages.lua').defaultMessages
local FindClients = import('/lua/ui/game/chat.lua').FindClients
local EnhanceCommon = import('/lua/enhancementcommon.lua')

local chatDisabled
local overlayDisabled
local chatChannel = 'Notify'
local messages = {}

--[[
ACUs = {
    EntityID = {
        queue = {
            1 = enhancement
            2 = enhancement2
        }
        workingOn = enhancement
        thread = watcher
        startTime = <int>
    }
}
--]]
local ACUs = {}

function init(isReplay, parent)
    RegisterChatFunc(NotifyOverlay.processNotification, chatChannel)
    AddChatCommand('enablenotify', toggleNotify)
    AddChatCommand('disablenotify', toggleNotify)
    AddChatCommand('enablenotifychat', toggleNotifyChat)
    AddChatCommand('disablenotifychat', toggleNotifyChat)
    AddChatCommand('enablenotifyoverlay', toggleNotifyOverlay)
    AddChatCommand('disablenotifyoverlay', toggleNotifyOverlay)

    populateMessages()

    chatDisabled = Prefs.GetFromCurrentProfile('Notify_Chat_Disabled')
    overlayDisabled = Prefs.GetFromCurrentProfile('Notify_Overlay_Disabled')

    -- Enable Notify by default
    if chatDisabled == nil then
        Prefs.SetToCurrentProfile('Notify_Chat_Disabled', false)
        Prefs.SavePreferences()
    end

    if overlayDisabled == nil then
        Prefs.SetToCurrentProfile('Notify_Overlay_Disabled', false)
        Prefs.SavePreferences()
    end
end

function populateMessages()
    local prefsMessages = Prefs.GetFromCurrentProfile('Notify_Messages')
    if prefsMessages then
        messages = prefsMessages
    else
        messages = defaultMessages
        Prefs.SetToCurrentProfile('Notify_Messages', messages)
    end
end

function toggleNotify(args)
    if args[1] == 'enablenotify' then
        chatDisabled = false
        overlayDisabled = false
        print 'Notify Enabled'
    elseif args[1] == 'disablenotify' then
        chatDisabled = true
        overlayDisabled = true
        print 'Notify Disabled'
    end

    -- Set it permanently unless specified
    if not args[2] or args[2] ~= 'once' then
        Prefs.SetToCurrentProfile('Notify_Chat_Disabled', chatDisabled)
        Prefs.SetToCurrentProfile('Notify_Overlay_Disabled', overlayDisabled)
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

function round(num, idp)
	if not idp then
		return tonumber(string.format("%." .. (idp or 0) .. "f", num))
	else
  		local mult = 10 ^ (idp or 0)
		return math.floor(num * mult + 0.5) / mult
  	end
end

function onStartEnhancement(units, enhancement)
    if not messages[enhancement] then return end

    local msg = {to = 'allies', Chat = true, text = 'Upgrading ' .. messages[enhancement]}

    -- Only ACU orders can make it to this point, as other enhancements aren't found in messages
    -- Additionally you can't give orders to a group of an ACU mixed with any other bpid, so they're all one type of ACU
    for _, unit in units do
        -- Start by storing entity IDs for future use
        local id = unit:GetEntityId()
        if not ACUs[id] then
            ACUs[id] = {queue = {}, workingOn = false, watcher = false, startTime = 0}
        end

        local data = ACUs[id]
        data.startTime = GetGameTimeSeconds()

        if not chatDisabled then
            SessionSendChatMessage(FindClients(), msg)
        end

        -- If we're not already working, watch this one
        if not data.watcher then
            data.watcher = ForkThread(watchEnhancement, id, enhancement)
            data.workingOn = enhancement
            table.insert(data.queue, enhancement)
        else -- Something is already underway. Put this enhancement in the queue
            table.insert(data.queue, enhancement)
        end
    end
end

function onCancelledEnhancement(units)
    local msg = {to = 'allies', Chat = true}

    for _, unit in units do
        local data = ACUs[unit:GetEntityId()]
        if data and data.watcher then
            local enhancement = data.workingOn

            if not chatDisabled or not messages[enhancement] then
                msg.text = messages[enhancement] .. ' cancelled'
                SessionSendChatMessage(FindClients(), msg)
            end

            -- Kill the watcher and empty the queue
            KillThread(data.watcher)
            data.watcher = false
            data.queue = {}
            data.workingOn = false
        end
    end
end

-- Called from the enhancement watcher
function onCompletedEnhancement(id, enhancement)
    if not messages[enhancement] then return end

    local msg = {to = 'allies', Chat = true}

    local data = ACUs[id]
    if data then
        if not chatDisabled then
            msg.text = messages[enhancement] .. ' done! (' .. round(GetGameTimeSeconds() - data.startTime, 2) .. 's)'
            SessionSendChatMessage(FindClients(), msg)
        end

        KillThread(data.watcher)
        data.watcher = false
        data.workingOn = false

        -- Remove the completed enhancement from the queue
        for index, enh in data.queue do
            if enh == enhancement then
                table.remove(data.queue, index)
                break
            end
        end

        -- If there are further enhancements queued, watch the next one
        for _, enh in data.queue do
            local unit = GetUnitById(id)
            onStartEnhancement({unit}, enh)
            break
        end
    end
end

function watchEnhancement(id, enhancement)
    local data = {}
    data.unit = GetUnitById(id)
    data.pos = data.unit:GetPosition()
    data.buildTime = data.unit:GetBlueprint().Enhancements[enhancement].BuildTime
    data.msg = {to = 'allies', Notify = true}
    data.id = id

    while true do
        WaitSeconds(0.1)
        local currentEnhancements = EnhanceCommon.GetEnhancements(id)
        if currentEnhancements then
            for slot, enh in currentEnhancements do
                if enh == enhancement then
                    onCompletedEnhancement(id, enhancement)
                    return
                end
            end
        end

        -- Handle the overlay creation and broadcast
        if not overlayDisabled then
            NotifyOverlay.generateEnhancementMessage(data)
        end
    end
end
