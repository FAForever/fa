-- This file contains all functions governing the integrated Notify mod, which sends messages to allies
-- when you order and complete ACU upgrades

local AddChatCommand = import('/lua/ui/notify/commands.lua').AddChatCommand
local RegisterChatFunc = import('/lua/ui/game/gamemain.lua').RegisterChatFunc
local Prefs = import('/lua/user/prefs.lua')
local defaultMessages = import('/lua/ui/notify/defaultmessages.lua').defaultMessages
local FindClients = import('/lua/ui/game/chat.lua').FindClients

local chatDisabled
local overlayDisabled
local chatChannel = 'Notify'
local messages = {}
local startTime = 0

function init(isReplay, parent)
    RegisterChatFunc(processNotification, chatChannel)
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

function processNotification(players, msg)
    local args = {}

    for word in string.gfind(msg.text, "%S+") do
        table.insert(args, word)
    end

    for _, k in {1, 3, 4, 5, 6, 7} do
        args[k] = tonumber(args[k])
    end

    updateEnhancementOverlay(args)
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

function enhancementCompleted(enh)
    if chatDisabled or not messages[enh] then return end

    msg = {to = 'allies', Chat = true, text = messages[enh] .. ' done! (' .. round(GetGameTimeSeconds() - startTime, 2) .. 's)'}
    SessionSendChatMessage(FindClients(), msg)
end