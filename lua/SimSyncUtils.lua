
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
    if recipient =='All' then
        Sync.ReceiveChatMessage = Sync.ReceiveChatMessage or { }
        table.insert(Sync.ReceiveChatMessage, message)
        return
    end

    if recipient == 'Allies' and IsAlly(message.From, GetFocusArmy()) then
        Sync.ReceiveChatMessage = Sync.ReceiveChatMessage or { }
        table.insert(Sync.ReceiveChatMessage, message)
        return
    end

    if recipient == GetFocusArmy() then
        Sync.ReceiveChatMessage = Sync.ReceiveChatMessage or { }
        table.insert(Sync.ReceiveChatMessage, message)
        return
    end

    WARN(string.format("Malformed chat message: %s", reprs(message)))
end

---@param message UIMessage
function SyncUIEventMessage(message)
    local recipient = message.To
    if recipient =='All' then
        Sync.ReceiveEventMessage = Sync.ReceiveEventMessage or { }
        table.insert(Sync.ReceiveEventMessage, message)
        return
    end

    if recipient == 'Allies' and IsAlly(message.From, GetFocusArmy()) then
        Sync.ReceiveEventMessage = Sync.ReceiveEventMessage or { }
        table.insert(Sync.ReceiveEventMessage, message)
        return
    end

    if recipient == GetFocusArmy() then
        Sync.ReceiveEventMessage = Sync.ReceiveEventMessage or { }
        table.insert(Sync.ReceiveEventMessage, message)
        return
    end

    WARN(string.format("Malformed event message: %s", reprs(message)))
end
