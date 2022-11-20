
local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Group = import("/lua/maui/group.lua").Group
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local Tooltip = import("/lua/ui/game/tooltip.lua")
local Prefs = import("/lua/user/prefs.lua")

local factionData = {
    {name = '<LOC _UEF>', icon = '/dialogs/logo-btn/logo-uef', key = 'uef', color = 'ff00d7ff', sound = 'UI_UEF_Rollover'},
    {name = '<LOC _Aeon>', icon = '/dialogs/logo-btn/logo-aeon', key = 'aeon', color = 'ffb5ff39', sound = 'UI_AEON_Rollover'},
    {name = '<LOC _Cybran>', icon = '/dialogs/logo-btn/logo-cybran', key = 'cybran', color = 'ffff0000', sound = 'UI_Cybran_Rollover'}
}
    
function RequestPlayerFaction()
    GetCursor():Show()
    function Callback(faction)
        SimCallback({Func = 'FactionSelection', Args = {Faction = faction}})
    end
    local parent = GetFrame(0)
    local top = Bitmap(parent, UIUtil.UIFile('/dialogs/game-select-faction-panel/panel_bmp.dds'))
    LayoutHelpers.AtCenterIn(top, parent, -80)
    top.Depth:Set(parent:GetTopmostDepth() + 10000)
    
    local bg = Bitmap(top)
    bg:SetSolidColor('aa000000')
    bg.Depth:Set(function() return top.Depth() - 1 end)
    LayoutHelpers.FillParent(bg, parent)
    
    local title = UIUtil.CreateText(top, "<LOC sel_faction_0000>Select Your Faction", 18)
    LayoutHelpers.AtCenterIn(title, top, -45)
    
    local buttons = {}
    for index, data in factionData do
        local key = data.key
        buttons[index] = UIUtil.CreateButton(top,
            data.icon..'_btn_up.dds',
            data.icon..'_btn_sel.dds',
            data.icon..'_btn_over.dds',
            data.icon..'_btn_dis.dds')
        Tooltip.AddButtonTooltip(buttons[index], 'faction_select_'..data.key)
        buttons[index].cue = data.sound
        buttons[index].OnRolloverEvent = function(self, event)
            if event == 'enter' then
                PlaySound(Sound({Bank = 'Interface', Cue = self.cue}))
            end
        end
        buttons[index].OnClick = function(self, modifiers)
            GetCursor():Hide()
            PlaySound(Sound({Bank = 'Interface', Cue = 'UI_Menu_MouseDown'}))
            if Prefs.GetOption('skin_change_on_start') != 'no' then
                local factions = import("/lua/factions.lua")
                if factions.Factions[factions.FactionIndexMap[key]].DefaultSkin then
                    UIUtil.SetCurrentSkin(factions.Factions[factions.FactionIndexMap[key]].DefaultSkin)
                end
            end
            top:Destroy()
            Callback(key)
        end
    end
    LayoutHelpers.AtCenterIn(buttons[2], top, 7)
    LayoutHelpers.LeftOf(buttons[1], buttons[2], 5)
    LayoutHelpers.RightOf(buttons[3], buttons[2], 5)
    UIUtil.MakeInputModal(top)
end