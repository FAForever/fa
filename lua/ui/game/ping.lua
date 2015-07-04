
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

    local mapGroup = import('/lua/ui/game/borders.lua').GetMapGroup()

    dialog = Bitmap(mapGroup, UIUtil.SkinnableFile('/dialogs/dialog_02/panel_bmp.dds'), "Marker Name Dialog")
    LayoutHelpers.AtCenterIn(dialog, mapGroup)
    dialog.Depth:Set(GetFrame(0):GetTopmostDepth() + 10)
    
    dialog.brackets = UIUtil.CreateDialogBrackets(dialog, 30, 36, 32, 34, true)
    
    local label = UIUtil.CreateText(dialog, "<LOC markers_0000>Enter Marker Name", 16, UIUtil.buttonFont)
    label.Top:Set(function() return dialog.Top() + 30 end)
    label.Left:Set(function() return dialog.Left() + 35 end)
    
    local cancelButton = UIUtil.CreateButtonStd(dialog, '/scx_menu/small-btn/small', "<LOC _CANCEL>", 14, 2)
    cancelButton.Top:Set(function() return dialog.Top() + 80 end)
    cancelButton.Left:Set(function() return dialog.Left() + (((dialog.Width() / 4) * 3) - (cancelButton.Width() / 2)) end)
    cancelButton.OnClick = function(self, modifiers)
        dialog:Destroy()
        dialog = false
    end

    --TODO this should be in layout
    local nameEdit = Edit(dialog)
    LayoutHelpers.AtLeftTopIn(nameEdit, dialog, 35, 60)
    nameEdit.Width:Set(283)
    nameEdit.Height:Set(nameEdit:GetFontHeight())
    nameEdit:ShowBackground(false)
    nameEdit:AcquireFocus()
    UIUtil.SetupEditStd(nameEdit, UIUtil.fontColor, nil, nil, nil, UIUtil.bodyFont, 16, 30)

    local firstTime = true

    local currentName = curName or ''

    dialog:SetNeedsFrameUpdate(true)
    dialog.OnFrame = function(self, elapsedTime)
        -- this works around the fact that wxWindows processes keys and then generates a wmChar message
        -- so if you don't set the text you'll see the hotkey that made this dialog
        if firstTime then
            nameEdit:SetText(currentName)
            firstTime = false
            self:SetNeedsFrameUpdate(false)
        end
    end

    local okButton = UIUtil.CreateButtonStd(dialog, '/scx_menu/small-btn/small', "<LOC _OK>", 14, 2)
    okButton.Top:Set(function() return dialog.Top() + 80 end)
    okButton.Left:Set(function() return dialog.Left() + (((dialog.Width() / 4) * 1) - (okButton.Width() / 2)) end)
    okButton.OnClick = function(self, modifiers)
        local newName = nameEdit:GetText()
        callback(newName)
        dialog:Destroy()
        dialog = false
    end
    
    nameEdit.OnEnterPressed = function(self, text)
        okButton.OnClick()
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
