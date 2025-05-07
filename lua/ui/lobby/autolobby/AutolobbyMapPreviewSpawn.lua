--******************************************************************************************************
--** Copyright (c) 2024 Willem 'Jip' Wijnia
--**
--** Permission is hereby granted, free of charge, to any person obtaining a copy
--** of this software and associated documentation files (the "Software"), to deal
--** in the Software without restriction, including without limitation the rights
--** to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
--** copies of the Software, and to permit persons to whom the Software is
--** furnished to do so, subject to the following conditions:
--**
--** The above copyright notice and this permission notice shall be included in all
--** copies or substantial portions of the Software.
--**
--** THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
--** IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
--** FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
--** AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
--** LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
--** OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
--** SOFTWARE.
--******************************************************************************************************

local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")

local Bitmap = import("/lua/maui/bitmap.lua").Bitmap

---@class UIAutolobbyMapPreviewSpawn : Bitmap
---@field Icon Bitmap
---@field Faction? number
local AutolobbyMapPreviewSpawn = ClassUI(Bitmap) {

    BorderPath = "/textures/ui/common/scx_menu/gameselect/map-slot_bmp.dds",
    EmptyPath = "/textures/ui/common/dialogs/mapselect02/commander_alpha.dds",
    UnknownIconPath = "/textures/ui/common/faction_icon-sm/random_ico.dds",
    FactionIconPaths = {
        -- faction_icon-lg
        -- D:\SteamLibrary\steamapps\common\Supreme Commander Forged Alliance\gamedata\textures\textures\ui\common\dialogs\logo-btn
        "/textures/ui/common/faction_icon-lg/uef_med.dds",
        "/textures/ui/common/faction_icon-lg/aeon_med.dds",
        "/textures/ui/common/faction_icon-lg/cybran_med.dds",
        "/textures/ui/common/faction_icon-lg/seraphim_med.dds",
    },

    ---@param self UIAutolobbyMapPreviewSpawn
    ---@param parent Control
    __init = function(self, parent)
        Bitmap.__init(self, parent, self.EmptyPath)

        self.Faction = nil
        self:Hide()
    end,

    ---@param self UIAutolobbyMapPreviewSpawn
    ---@param parent Control
    __post_init = function(self, parent)
        LayoutHelpers.ReusedLayoutFor(self)
            :Width(32)
            :Height(32)
            :Over(parent, 32)
            :End()
    end,

    ---@param self UIAutolobbyMapPreviewSpawn
    Reset = function(self)
        self.Faction = nil
        self:Hide()
    end,

    ---@param self Control
    ---@param event KeyEvent
    ---@return boolean
    HandleEvent = function(self, event)
        if event.Type == 'MouseEnter' then
            self:SetAlpha(0.25)
        elseif event.Type == 'MouseExit' then
            self:SetAlpha(1.0)
        end

        return true
    end,

    ---@param self UIAutolobbyMapPreviewSpawn
    Show = function(self)
        if self.Faction then
            Bitmap.Show(self)
        else
            self:Hide()
        end
    end,

    ---@param self UIAutolobbyMapPreviewSpawn
    ---@param faction number
    Update = function(self, faction)
        local factionIcon = self.FactionIconPaths[faction]
        if factionIcon then
            self.Faction = faction
            self:SetTexture(UIUtil.UIFile(factionIcon))
            self:Show()
        end
    end,
}

---@param parent Control
---@return UIAutolobbyMapPreviewSpawn
Create = function(parent)
    return AutolobbyMapPreviewSpawn(parent)
end
