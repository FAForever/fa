local Group = import('/lua/maui/group.lua').Group
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local UIUtil = import('/lua/ui/uiutil.lua')
local Prefs = import('/lua/user/prefs.lua')
local CheckBox = import('/lua/maui/checkbox.lua').Checkbox
local LayoutFor = import('/lua/maui/layouthelpers.lua').ReusedLayoutFor

---@class PlayerItem : Bitmap
---@field _bg MauiCheckbox
---@field _name Text
---@field _list PlayerMuteList
PlayerItem = Class(Bitmap)
{
    ---@param self PlayerItem
    ---@param parent PlayerMuteList
    __init = function(self, parent, id)
        Bitmap.__init(self, parent)

        self._list = parent
        self._id = id

        self._bg = CheckBox(self,
            UIUtil.SkinnableFile('/MODS/blank.dds'),
            UIUtil.SkinnableFile('/MODS/single.dds'),
            UIUtil.SkinnableFile('/MODS/single.dds'),
            UIUtil.SkinnableFile('/MODS/double.dds'),
            UIUtil.SkinnableFile('/MODS/disabled.dds'),
            UIUtil.SkinnableFile('/MODS/disabled.dds'),
            'UI_Tab_Click_01', 'UI_Tab_Rollover_01')

        self._name = UIUtil.CreateText(self, '', 14, UIUtil.bodyFont, true)

        self._bg.OnCheck = function(bg, checked)
            self._list:SetPlayerState(self._id, checked)
        end

    end,

    __post_init = function(self, parent)
        self:InitLayout(parent)
    end,

    InitLayout = function(self, parent)

        LayoutFor(self._bg)
            :Fill(self)
            :Over(self)

        LayoutFor(self._name)
            :Color('FFE9ECE9')
            :DisableHitTest()
            :AtLeftIn(self, 5)
            :AtVerticalCenterIn(self)

        LayoutFor(self)
            :Color("99000000")
    end,

    ---@param self PlayerItem
    ---@param name string
    SetPlayerName = function(self, name)
        self._name:SetText(name)
    end,

    ---@param self PlayerItem
    ---@param color Color
    SetPlayerColor = function(self, color)
        self._name:SetColor(color)
    end,

    ---@param self PlayerItem
    SetPlayerEnabled = function(self, state)
        self._bg:SetCheck(state, true)
    end

}

---@class PlayerMuteData
---@field name string
---@field color Color
---@field id integer
---@field enabled boolean


---@class PlayerMuteList : Group
---@field _callback fun(id:integer, state:boolean)
PlayerMuteList = Class(Group)
{
    ---@param self PlayerMuteList
    ---@param parent Control
    ---@param callback fun(id:integer, state:boolean)
    __init = function(self, parent, callback)
        Group.__init(self, parent)

        self._callback = callback
    end,

    ---@param self PlayerMuteList
    ---@param data PlayerMuteData[]
    InitStates = function(self, data)
        local prev = nil
        for _, item in data do
            ---@type PlayerItem
            local playerItem = PlayerItem(self, item.id)
            playerItem:SetPlayerName(item.name)
            playerItem:SetPlayerColor(item.color)
            playerItem:SetPlayerEnabled(item.enabled)

            if prev then
                LayoutFor(playerItem)
                    :Below(prev, 5)
                    :Width(200)
                    :Height(30)
                    :Over(self)
            else
                LayoutFor(playerItem)
                    :AtLeftTopIn(self)
                    :Width(200)
                    :Height(30)
                    :Over(self)
            end
            prev = playerItem
        end

    end,

    ---@param self PlayerMuteList
    ---@param id integer
    ---@param state boolean
    SetPlayerState = function(self, id, state)
        self._callback(id, state)
    end,
}
