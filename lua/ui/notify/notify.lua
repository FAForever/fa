-- This file contains all functions governing the integrated Notify mod, which sends messages to allies
-- when you order and complete ACU upgrades

local Prefs = import('/lua/user/prefs.lua')
local RegisterChatFunc = import('/lua/ui/game/gamemain.lua').RegisterChatFunc
local FindClients = import('/lua/ui/game/chat.lua').FindClients
local defaultMessages = import('/lua/ui/notify/defaultmessages.lua').defaultMessages
local AddChatCommand = import('/lua/ui/notify/commands.lua').AddChatCommand
local NotifyOverlay = import('/lua/ui/notify/notifyoverlay.lua')
local toggleOverlayPermanent = NotifyOverlay.toggleOverlayPermanent
local factions = import('/lua/factions.lua').FactionIndexMap

local categoriesDisabled = {}
local messages = {}
local ACUs = {}

function init(isReplay, parent)
    RegisterChatFunc(NotifyOverlay.processNotification, 'Notify')
    AddChatCommand('enablenotify', toggleNotifyTemporary)
    AddChatCommand('disablenotify', toggleNotifyTemporary)

    populateMessages()
    setupStartDisables()
end

-- Populate the disables table according to the last session
function setupStartDisables()
    local state

    for key, data in messages do
        local category = key
        if factions[category] then -- Don't make a disabler per-faction
            category = 'acus'
        end

        local flag = 'Notify_' .. category .. '_Disabled'
        state = Prefs.GetFromCurrentProfile(flag)

        -- Handle categories that don't have a prefs entry yet
        if state == nil then
            if flag == 'acus' then -- ACU messages on by default when loading for the first time
                Prefs.SetToCurrentProfile(flag, false)
                state = false
            else
                Prefs.SetToCurrentProfile(flag, true) -- Everything else to off by default
                state = true
            end
        end
        categoriesDisabled.category = state
    end

    state = Prefs.GetFromCurrentProfile('Notify_all_disabled')
    if state == nil then
        Prefs.SetToCurrentProfile('Notify_all_disabled', false)
        state = false
    end

    categoriesDisabled.All = state
    Prefs.SavePreferences()
end

function processIncomingMessage(players, msg)
    if not categoriesDisabled.All or not categoriesDisabled[msg.data.category] then
        local army = GetFocusArmy()
        msg.Notify = false
        msg.Chat = true
        msg.to = army

        SessionSendChatMessage(FindClients(army), msg)
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

-- This function is used to toggle ALL ASPECTS of notify functionality, and is saved
-- It is accessed by the button
-- This overrides the individual category filters
function toggleNotifyPermanent(bool)
    categoriesDisabled.All = bool
    toggleOverlayPermanent(true, bool)

    if bool then
        print 'Notify Disabled'
    else
        print 'Notify Enabled'
    end

    Prefs.SetToCurrentProfile('Notify', bool)
    Prefs.SetToCurrentProfile('Notify', bool)
    Prefs.SavePreferences()
end

-- This function is used to toggle ALL ASPECTS of notify functionality, but only for the current session
-- This overrides the individual category filters
function toggleNotifyTemporary(args)
    if args[1] == 'enablenotify' then
        categoriesDisabled.All = false
        toggleOverlayPermanent(false, false)
        print 'Notify Enabled For Session'
    elseif args[1] == 'disablenotify' then
        categoriesDisabled.All = true
        toggleOverlayPermanent(false, true)
        print 'Notify Disabled For Session'
    end
end

-- Toggles the printing of received messages
-- Called from the various buttons in the customiser
function toggleCategoryChat(category)
    local msg
    categoriesDisabled[category] = not categoriesDisabled[category]
    
    -- Messages seem backwards at first because categoriesDisabled true == disabled feature
    if categoriesDisabled[category] then
        msg = 'Disabled'
    else
        msg = 'Enabled'
    end

    msg = category .. msg .. '!'
    print(msg)
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
    local source = messageTable.source
    local category = messageTable.category
    if not messages[category][source] then return end

    local id = messageTable.id
    local trigger = messageTable.trigger

    if trigger == 'started' then
        onStartEnhancement(id, category, source)
    elseif trigger == 'cancelled' then
        onCancelledEnhancement(id, category, source)
    elseif trigger == 'completed' then
        onCompletedEnhancement(id, category, source)
    end
end

function onStartEnhancement(id, category, source)
    local msg = {to = 'allies', Notify = true, data = {category = category, text = 'Starting ' .. messages[category][source]}}

    -- Start by storing ACU IDs for future use
    if id then
        if not ACUs[id] then
            ACUs[id] = {watcher = false, startTime = 0}
        end

        local data = ACUs[id]
        data.startTime = GetGameTimeSeconds()

        -- If we're not already working, watch this one
        if not data.watcher then
            data.watcher = ForkThread(watchEnhancement, id, source)
        end
    end

    SessionSendChatMessage(FindClients(), msg)
end

function onCancelledEnhancement(id, category, source)
    local msg = {to = 'allies', Notify = true, data = {category = category, text = messages[category][source] .. ' cancelled'}}

    if id then
        local data = ACUs[id]
        if data then
            killWatcher(data)
            NotifyOverlay.sendDestroyOverlayMessage(id)
        end
    end
    
    SessionSendChatMessage(FindClients(), msg)
end

-- Called from the enhancement watcher
function onCompletedEnhancement(id, category, source)
    local msg = {to = 'allies', Notify = true, data = {category = category, text = messages[category][source] .. ' done!'}}

    if id then
        local data = ACUs[id]
        if data then
            msg.data.text = messages[category][source] .. ' done! (' .. round(GetGameTimeSeconds() - data.startTime, 2) .. 's)'
            killWatcher(data)
            NotifyOverlay.sendDestroyOverlayMessage(id)
        end
    end
    
    SessionSendChatMessage(FindClients(), msg)
end

function killWatcher(data)
    if data.watcher then
        KillThread(data.watcher)
        data.watcher = false
    end
end

function watchEnhancement(id, source)
    local overlayData = {}
    overlayData.unit = GetUnitById(id)
    overlayData.pos = overlayData.unit:GetPosition()
    overlayData.msg = {to = 'allies', NotifyOverlay = true}
    overlayData.id = id
    overlayData.eta = -1

    while true do
        NotifyOverlay.generateEnhancementMessage(overlayData)
        WaitSeconds(0.1)
    end
end
