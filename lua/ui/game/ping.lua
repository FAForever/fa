
local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Group = import("/lua/maui/group.lua").Group
local Text = import("/lua/maui/text.lua").Text
local Button = import("/lua/maui/button.lua").Button
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local Edit = import("/lua/maui/edit.lua").Edit

--- The dialog used to define marker-pings.
local dialog = false

--- The maximum number of marker-pings. Defined elsewhere and received through the sync.
MaxMarkers = false

-- Table of ping types
-- All of this data is sent to the sim and back to the UI for display on the world views
PingTypes = {
    alert = {Lifetime = 6, Mesh = 'alert_marker', Ring = '/game/marker/ring_yellow02-blur.dds', ArrowColor = 'yellow', Sound = 'UEF_Select_Radar'},
    move = {Lifetime = 6, Mesh = 'move', Ring = '/game/marker/ring_blue02-blur.dds', ArrowColor = 'blue', Sound = 'Cybran_Select_Radar'},
    attack = {Lifetime = 6, Mesh = 'attack_marker', Ring = '/game/marker/ring_red02-blur.dds', ArrowColor = 'red', Sound = 'Aeon_Select_Radar'},
    marker = {Lifetime = 5, Ring = '/game/marker/ring_yellow02-blur.dds', ArrowColor = 'yellow', Sound = 'UI_Main_IG_Click', Marker = true},
}

--- The original army that this player represents. Is populated else where during initialisation of the game.
OriginalFocusArmy = -1

--- List of marker-pings with text underneath.
local markers = {}

local clients = GetSessionClients()
local armies = GetArmiesTable().armiesTable

---comment
---@return table
local function GetAlliedAndObserverClients()

    local focusArmy = OriginalFocusArmy
    if focusArmy == -1 then
        return {}
    end

    local recipients = { }
    for k, client in clients do
        for l, source in client.authorizedCommandSources do
            if IsAlly(focusArmy, source) then
                recipients[source] = true
            end
        end
    end

    return table.keys(recipients)
end

--- Performs a ping operation.
-- @param pingType can be 'alert', 'move', 'attack' or 'marker'.
function DoPing(pingType)

    -- can't ping in replays
    if SessionIsReplay() or import("/lua/ui/game/gamemain.lua").supressExitDialog then 
        WARN("You can not ping in a replay.")
        return 
    end

    -- ... what?
    local position = GetMouseWorldPos()
    for _, v in position do
        local var = v
        if var ~= v then
            return
        end
    end

    -- observers can't ping
    local focusArmy = GetFocusArmy()
    if focusArmy == -1 then
        WARN("You can not ping as an observer.")
        return
    end

    -- you can only ping for your allies when you've changed armies 
    if not IsAlly(focusArmy, OriginalFocusArmy) then
        WARN("You can not ping for an opponent team.")
        return
    end

    -- prepare ping data
    local data = {
        Owner = OriginalFocusArmy - 1, 
        Type = pingType, 
        Location = position
    }

    data = table.merged(data, PingTypes[pingType])

    -- check if it is a marker ping
    if data.Marker then

        -- check if we ran out of marker-pings
        if markers[data.Owner] and table.getsize(markers[data.Owner]) >= MaxMarkers then
            UIUtil.QuickDialog(GetFrame(0), '<LOC markers_0001>You must delete an existing marker before making a new one.','<LOC _OK>', nil, nil, nil, nil, nil, true, {escapeButton = 1, enterButton = 1, worldCover = 1})

        -- do a marker ping
        else
            NamePing(function(name)
                data.Name = name
                local armies = GetArmiesTable()
                data.Color = armies.armiesTable[armies.focusArmy].color
                SimCallback({Func = 'SpawnPing', Args = data})

                -- carefully chosen settings at the given zoom (for full hd)
                local cameraSettings = GetCamera('WorldCamera'):SaveSettings()
                cameraSettings.Zoom = 211.12
                cameraSettings.Pitch = 1.2807490825653
                cameraSettings.Heading = 3.1415927410126
                cameraSettings.Focus = position

                SessionSendChatMessage(GetAlliedAndObserverClients(), {
                    to = 'allies',
                    text = tostring(name),
                    camera = cameraSettings,
                    Chat = true,
                })
            end)
        end

    -- typical ping, just do it
    else
        SimCallback({Func = 'SpawnPing', Args = data})
    end
end

--- Special ping with text underneath
-- @param callback The callback to perform when the dialog is complete.
-- @param curName the text of the marker.
function NamePing(callback, curName)
    
    -- do not make dialog on top of dialogs
    if dialog then return end

    -- localize for scope
    local cb = callback
    dialog = UIUtil.CreateInputDialog(
        GetFrame(0),                                    -- parent
        LOC("<LOC markers_0000>Enter Marker Name"),     -- text
        function(self, markerName)                      -- callback when dialog completes
            cb(markerName)
        end
    )

    -- when closed, allow us to start another
    dialog.OnClosed = function()
        dialog = nil
    end
end

--- Allows updating of special markers.
-- @param data The typical ping data as defined in DoPing.
function UpdateMarker(data)
    SimCallback({Func = 'UpdateMarker', Args = data})
end

--- Displays all pings in the table for each world view. The ping format is the same as defined in the DoPing function.
-- @param data A table where each element is data about a ping.
function DisplayPing(data)
    --Table of all map views to display pings in
    local views = import("/lua/ui/game/worldview.lua").GetWorldViews()

    -- for each ping
    for index, ping in data do

        -- for each world view (think about split-screen)
        for _, viewControl in views do

            -- perform the corresponding action
            if viewControl and ping.Action ~= 'renew' then
                if ping.Action then
                    viewControl:UpdatePing(ping)
                    if ping.Action == 'delete' then
                        markers[ping.Owner][ping.ID] = nil
                    elseif ping.Action == 'flush' then
                        markers = {}
                    end
                else
                    viewControl:DisplayPing(ping)
                    if ping.Marker then
                        if not markers[ping.Owner] then markers[ping.Owner] = {} end
                        markers[ping.Owner][ping.ID] = ping
                    end
                end
            end
        end

        -- for new pings we perform a sound
        if ping.Sound and not ping.Renew then
            PlaySound(Sound{Bank = 'Interface', Cue = ping.Sound})
        end
    end
end
