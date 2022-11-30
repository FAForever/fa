---@param data SimCameraEvent
function SyncCameraRequest(data)
    local Sync = Sync
    Sync.CameraRequests = Sync.CameraRequests or { }
    table.insert(Sync.CameraRequests, data)
end