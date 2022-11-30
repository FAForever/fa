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
    table.insert(Sync.AIChat, )
end