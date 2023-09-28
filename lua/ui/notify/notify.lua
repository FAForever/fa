-- This file contains all functions governing the integrated Notify mod, which sends messages to allies
-- when you order and complete ACU upgrades

local Prefs = import("/lua/user/prefs.lua")
local FindClients = import("/lua/ui/game/chat.lua").FindClients
local defaultMessages = import("/lua/ui/notify/defaultmessages.lua").defaultMessages
local AddChatCommand = import("/lua/ui/notify/commands.lua").AddChatCommand
local NotifyOverlay = import("/lua/ui/notify/notifyoverlay.lua")

local toggleOverlay = NotifyOverlay.toggleOverlay
local factions = import("/lua/factions.lua").FactionIndexMap
local UTF =  import("/lua/utf.lua")

local categoriesDisabled = {}
local messages
local ACUs = {}
local messageCounts = {}
local messageLimits = {tech = 1, other = 1, experimentals = 1}
local customMessagesDisabled

local focusArmy
local observer
local localClient

function init(isReplay, parent, notifyMessages)
    messages = notifyMessages
    focusArmy = GetFocusArmy()
    observer = isReplay or focusArmy == -1

    local clients = GetSessionClients()
    for index, client in clients do
        if client['local'] then
            localClient = index
            break
        end
    end

    AddChatCommand('enablenotify', toggleNotifyTemporary)
    AddChatCommand('disablenotify', toggleNotifyTemporary)

    setupStartDisables()
end

-- Populate the disables table according to the last session
function setupStartDisables()
    local state
    local messagesTable = messages()
    for key, data in messagesTable do
        local category = key
        if factions[category] then -- Don't make a disabler per-faction
            category = 'acus'
        end

        local flag = 'Notify_' .. category .. '_disabled'
        state = Prefs.GetFromCurrentProfile(flag)

        -- Handle categories that don't have a prefs entry yet
        if state == nil then
            if category == 'acus' then -- ACU messages on by default when loading for the first time
                Prefs.SetToCurrentProfile(flag, false)
                state = false
            else
                Prefs.SetToCurrentProfile(flag, true) -- Everything else to off by default
                state = true
            end
        end
        categoriesDisabled[category] = state
    end

    state = Prefs.GetFromCurrentProfile('Notify_all_disabled')
    if state == nil then
        Prefs.SetToCurrentProfile('Notify_all_disabled', false)
        state = false
    end
    categoriesDisabled.All = state

    state = Prefs.GetFromCurrentProfile('Notify_custom_disabled')
    if state == nil then
        Prefs.SetToCurrentProfile('Notify_custom_disabled', false)
        state = false
    end
    customMessagesDisabled = state

    Prefs.SavePreferences()
end

-- This function is called from chat.lua when a player receives a message from another player flagged as Notify = true. Generated below.
function processIncomingMessage(sender, msg)
    local category = msg.data.category
    local source = msg.data.source
    local trigger = msg.data.trigger

    -- Don't touch invalid messages
    if not category or not source then
        return true
    end

    if import("/lua/ui/game/gamemain.lua").IsNISMode() or categoriesDisabled.All or categoriesDisabled[category] or factions[category] and categoriesDisabled['acus'] then
        return false
    end

    if messageLimits[category] then
        if not messageCounts[sender] then
            messageCounts[sender] = {}
        end
        if not messageCounts[sender][category] then
            messageCounts[sender][category] = {}
        end
        if not messageCounts[sender][category][source] then
            messageCounts[sender][category][source] = {}
        end

        if trigger == 'cancelled' then
            local count = (messageCounts[sender][category][source]['started'] or 0) - 1
            messageCounts[sender][category][source]['started'] = count
            if count >= messageLimits[category] then
                return false
            end
        else
            local count = (messageCounts[sender][category][source][trigger] or 0) + 1
            messageCounts[sender][category][source][trigger] = count
            if count > messageLimits[category] then
                return false
            end
        end
    end

    if customMessagesDisabled then
        local message = defaultMessages[category][source]
        if trigger == 'started' then
            msg.text = LOC('<LOC notify_starting>') .. message
        elseif trigger == 'cancelled' then
            msg.text = message .. LOC('<LOC notify_cancelled>')
        elseif trigger == 'completed' then
            local time = msg.data.time
            if time then
                msg.text = string.format("%s %s (%.2fs)", message, LOC('<LOC notify_done>'), time)
            else
                msg.text = message .. LOC('<LOC notify_done>')
            end
        else
            msg.text = LOC('<LOC notify_abnormal>') .. message
        end
    end
    return true
end


-- This function is used to toggle ALL ASPECTS of notify functionality, and is saved
-- It is accessed by the button
-- This overrides the individual category filters
function toggleNotifyPermanent(bool)
    categoriesDisabled.All = bool
    toggleOverlay(bool, true)

    if bool then
        print 'Notify Disabled'
    else
        print 'Notify Enabled'
    end

    Prefs.SetToCurrentProfile('Notify_all_disabled', bool)
    Prefs.SavePreferences()
end

-- This function is used to toggle ALL ASPECTS of notify functionality, but only for the current session
-- This overrides the individual category filters
function toggleNotifyTemporary(args)
    if args[1] == 'enablenotify' then
        categoriesDisabled.All = false
        toggleOverlay(false, true)
        print 'Notify Enabled For Session'
    elseif args[1] == 'disablenotify' then
        categoriesDisabled.All = true
        toggleOverlay(true, true)
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

    msg = category .. ' ' .. msg .. '!'
    print(msg)

    local flag = 'Notify_' .. category .. '_disabled'
    Prefs.SetToCurrentProfile(flag, categoriesDisabled[category])
    Prefs.SavePreferences()
end

-- Toggles between allowing custom messages or showing the defaults instead
function toggleCustomMessages(bool)
    customMessagesDisabled = bool
    Prefs.SetToCurrentProfile('Notify_custom_disabled', bool)
    NotifyOverlay.toggleCustomMessages(bool)
    if customMessagesDisabled then
        print 'Custom Messages Disabled'
    elseif not customMessagesDisabled then
        print 'Custom Messages Enabled'
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

function focusArmyChanged()
    focusArmy = GetFocusArmy()
    observer = observer or focusArmy == -1

    if focusArmy ~= -1 then
        for _, data in ACUs do
            if data.army ~= focusArmy then
                killWatcher(data)
            end
        end
    end
end

function sendMessage(msg)
    if observer then
        SessionSendChatMessage(localClient, msg)
    else
        SessionSendChatMessage(FindClients(), msg)
    end
end

-- This function processes messages sent from the sim from unit.lua and defaultunits.lua
function sendEnhancementMessage(messageTable)
    local source = messageTable.source
    local category = messageTable.category
    if not messages or not messages()[category][source] then return end

    local id = messageTable.id
    local army = messageTable.army
    local trigger = messageTable.trigger

    if trigger == 'started' then
        onStartEnhancement(id, army, category, source)
    elseif trigger == 'cancelled' then
        onCancelledEnhancement(id, category, source)
    elseif trigger == 'completed' then
        onCompletedEnhancement(id, category, source)
    end
end

function onStartEnhancement(id, army, category, source)
    local msg = {to = 'notify', Chat = true, text = 'Starting ' .. messages()[category][source], data = {category = category, source = source, trigger = 'started'}}

    -- Start by storing ACU IDs for future use
    if id and (focusArmy == -1 or army == focusArmy) then
        if not ACUs[id] then
            ACUs[id] = {id = id, army = army, watcher = false, startTime = 0}
        end

        local data = ACUs[id]
        data.startTime = GetGameTimeSeconds()

        -- If we're not already working, watch this one
        if not data.watcher then
            data.watcher = ForkThread(watchEnhancement, id, messages()[category][source], category, source)
        end
    end

    sendMessage(msg)
end

function onCancelledEnhancement(id, category, source)
    local msg = {to = 'notify', Chat = true, text = messages()[category][source] .. ' cancelled', data = {category = category, source = source, trigger = 'cancelled'}}

    if id then
        local data = ACUs[id]
        if data then
            killWatcher(data)
        end
    end

    sendMessage(msg)
end

-- Called from the enhancement watcher
function onCompletedEnhancement(id, category, source)
    local msg = {to = 'notify', Chat = true, text = messages()[category][source] .. ' done!', data = {category = category, source = source, trigger = 'completed'}}

    if id then
        local data = ACUs[id]
        if data then
            local time = round(GetGameTimeSeconds() - data.startTime, 2)
            msg.text = string.format("%s %s (%.2fs)", messages()[category][source], LOC('<LOC notify_done>'), time)
            msg.data.time = time
            killWatcher(data)
        end
    end

    sendMessage(msg)
end

function killWatcher(data)
    if data.watcher then
        KillThread(data.watcher)
        data.watcher = false
        NotifyOverlay.sendDestroyOverlayMessage(data.id)
    end
end

function watchEnhancement(id, text, category, source)
    local overlayData = {}
    overlayData.unit = GetUnitById(id)
    overlayData.pos = overlayData.unit:GetPosition()
    overlayData.msg = {to = 'allies', NotifyOverlay = true, data = {id = id, text = text, category = category, source = source}}
    overlayData.eta = -1

    while true do
        NotifyOverlay.generateEnhancementMessage(overlayData)
        WaitSeconds(0.1)
    end
end
