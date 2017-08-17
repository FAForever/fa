
local UIUtil = import('/lua/ui/uiutil.lua')
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Group = import('/lua/maui/group.lua').Group
local Text = import('/lua/maui/text.lua').Text
local Button = import('/lua/maui/button.lua').Button
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local Edit = import('/lua/maui/edit.lua').Edit

local dialog = false
MaxMarkers = false

--Table of ping types
--All of this data is sent to the sim and back to the UI for display on the world views
PingTypes = {
    alert = {Lifetime = 6, Mesh = 'alert_marker', Ring = '/game/marker/ring_yellow02-blur.dds', ArrowColor = 'yellow', Sound = 'UEF_Select_Radar'},
    move = {Lifetime = 6, Mesh = 'move', Ring = '/game/marker/ring_blue02-blur.dds', ArrowColor = 'blue', Sound = 'Cybran_Select_Radar'},
    attack = {Lifetime = 6, Mesh = 'attack_marker', Ring = '/game/marker/ring_red02-blur.dds', ArrowColor = 'red', Sound = 'Aeon_Select_Radar'},
    marker = {Lifetime = 5, Ring = '/game/marker/ring_yellow02-blur.dds', ArrowColor = 'yellow', Sound = 'UI_Main_IG_Click', Marker = true},
}

local markers = {}

function DoPing(pingType)
    if SessionIsReplay() or import('/lua/ui/game/gamemain.lua').supressExitDialog then return end
    local position = GetMouseWorldPos()
    for _, v in position do
        local var = v
        if var ~= v then
            return
        end
    end
    local army = GetArmiesTable().focusArmy - 1
    if GetFocusArmy() == -1 then
        return
    end
    local data = {Owner = army, Type = pingType, Location = position, Type = pingType}
    data = table.merged(data, PingTypes[pingType])
    if data.Marker then
        if markers[data.Owner] and table.getsize(markers[data.Owner]) >= MaxMarkers then
            UIUtil.QuickDialog(GetFrame(0), '<LOC markers_0001>You must delete an existing marker before making a new one.','<LOC _OK>', nil, nil, nil, nil, nil, true, {escapeButton = 1, enterButton = 1, worldCover = 1})
        else
            NamePing(function(name)
                data.Name = name
                local armies = GetArmiesTable()
                data.Color = armies.armiesTable[armies.focusArmy].color
                SimCallback({Func = 'SpawnPing', Args = data})
            end)
        end
    else
        SimCallback({Func = 'SpawnPing', Args = data})
    end
end

function NamePing(callback, curName)
    -- Dialog already showing? Don't show another one
    if dialog then return end

    local cb = callback
    dialog = UIUtil.CreateInputDialog(GetFrame(0), LOC("<LOC markers_0000>Enter Marker Name"),
        function(self, markerName)
            cb(markerName)
        end
)

    dialog.OnClosed = function()
        dialog = nil
    end
end

function DisplayPing(data)
    --Table of all map views to display pings in
    local views = import('/lua/ui/game/worldview.lua').GetWorldViews()
    for index, ping in data do
        for _, viewControl in views do
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
        if ping.Sound and not ping.Renew then
            PlaySound(Sound{Bank = 'Interface', Cue = ping.Sound})
        end
    end
end

function UpdateMarker(data)
    SimCallback({Func = 'UpdateMarker', Args = data})
end
