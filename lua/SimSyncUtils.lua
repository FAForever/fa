---@param data SimCameraEvent
function SyncCameraRequest(data)
    local Sync = Sync
    Sync.CameraRequests = Sync.CameraRequests or { }
    table.insert(Sync.CameraRequests, data)
end

---comment
---@param data any
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