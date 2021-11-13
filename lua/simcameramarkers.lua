local ipairs = ipairs
local tableGetsize = table.getsize
local next = next
local tableInsert = table.insert

local markers = {}

function AddCameraMarker(position)
    local index = tableGetsize(markers) + 1
    local marker = {}
    marker.callbacks = {}
    marker.id = index
    
    marker.OnScreen = function(self)
        for _, func in self.callbacks do
            func(self)
        end
    end
    
    marker.AddCallback = function(self, cb)
        tableInsert(self.callbacks, cb)
    end
    
    marker.Destroy = function(self)
        if not Sync.RemoveCameraMarkers then Sync.RemoveCameraMarkers = {} end
        tableInsert(Sync.RemoveCameraMarkers, self.id)
    end
    
    if not Sync.AddCameraMarkers then Sync.AddCameraMarkers = {} end
    tableInsert(Sync.AddCameraMarkers, {id = index, position = position})
    
    markers[index] = marker
    return markers[index]
end

function MarkerOnScreen(id)
    if markers[id] then
        markers[id]:OnScreen()
    end
end