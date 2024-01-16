
---@param data SimCameraEvent
function SyncCameraRequest(data)
    local Sync = Sync
    Sync.CameraRequests = Sync.CameraRequests or { }
    table.insert(Sync.CameraRequests, data)
end

function SyncVoice(data)
    local Sync = Sync
    Sync.Voice = Sync.Voice or { }
    table.insert(Sync.Voice, data)
end

function SyncAIChat(data)
    local Sync = Sync
    Sync.AIChat = Sync.AIChat or { }
    table.insert(Sync.AIChat, data)
end

function SyncGameResult(data)
    local Sync = Sync
    Sync.GameResult = Sync.GameResult or { }
    table.insert(Sync.GameResult, data)
end

function SyncPlayerQuery(data)
    local Sync = Sync
    Sync.PlayerQueries = Sync.PlayerQueries or { }
    table.insert(Sync.PlayerQueries, data)
end

function SyncQueryResult(data)
    local Sync = Sync
    Sync.QueryResults = Sync.QueryResults or { }
    table.insert(Sync.QueryResults, data)
end

--- Sends 
---@param message UIMessage
function SyncUIChatMessage(message)
    local recipient = message.To

    -- see all messages
    if recipient == 'All' then
        Sync.ReceiveChatMessage = Sync.ReceiveChatMessage or { }
        table.insert(Sync.ReceiveChatMessage, message)
        return
    end

    -- see allied messages
    if recipient == 'Allies' and IsAlly(message.From, GetFocusArmy()) then
        Sync.ReceiveChatMessage = Sync.ReceiveChatMessage or { }
        table.insert(Sync.ReceiveChatMessage, message)
        return
    end

    -- see whispers
    if recipient == GetFocusArmy() then
        Sync.ReceiveChatMessage = Sync.ReceiveChatMessage or { }
        table.insert(Sync.ReceiveChatMessage, message)
        return
    end

    -- always see our own messages
    if message.From == GetFocusArmy() then
        Sync.ReceiveChatMessage = Sync.ReceiveChatMessage or { }
        table.insert(Sync.ReceiveChatMessage, message)
        return
    end
end

---@param message UIMessage
function SyncUIEventMessage(message)
    local recipient = message.To

    -- see messages for all
    if recipient =='All' then
        Sync.ReceiveEventMessage = Sync.ReceiveEventMessage or { }
        table.insert(Sync.ReceiveEventMessage, message)
        return
    end

    -- see allied messages
    if recipient == 'Allies' and IsAlly(message.From, GetFocusArmy()) then
        Sync.ReceiveEventMessage = Sync.ReceiveEventMessage or { }
        table.insert(Sync.ReceiveEventMessage, message)
        return
    end

    -- see whispers
    if recipient == GetFocusArmy() then
        Sync.ReceiveEventMessage = Sync.ReceiveEventMessage or { }
        table.insert(Sync.ReceiveEventMessage, message)
        return
    end

    -- always see our own messages
    if message.From == GetFocusArmy() then
        Sync.ReceiveEventMessage = Sync.ReceiveEventMessage or { }
        table.insert(Sync.ReceiveEventMessage, message)
        return
    end
end
