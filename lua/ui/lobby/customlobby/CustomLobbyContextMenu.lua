--******************************************************************************************************
--** Copyright (c) 2026 FAForever
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

-- A generic, content-agnostic context menu: hand it a list of entries and a screen
-- position and it draws a framed vertical list, runs the chosen entry's action, and
-- dismisses itself (item click, click-outside, or Esc). It knows nothing about the
-- lobby — what the entries are and when they apply lives in CustomLobbyMenus.lua, so
-- adding or state-gating an item never touches this file.
--
-- Framed like the rest of the lobby (chat-config border + dark fill). Singleton on
-- GetFrame(0); each Show rebuilds it for the given entries.

local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local EscapeHandler = import("/lua/ui/dialogs/eschandler.lua")

local Group = import("/lua/maui/group.lua").Group
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap

local Layouter = LayoutHelpers.ReusedLayoutFor

local ItemHeight = 22
local MenuPad = 4
local LabelPadX = 10
local MinWidth = 130
local FontSize = 13

--- One row in a context menu.
---@class UICustomLobbyContextMenuItem
---@field label string
---@field action fun()        # run on click
---@field enabled? boolean    # default true; a disabled item is greyed and inert

-------------------------------------------------------------------------------

---@class UICustomLobbyContextMenuRow : Group
---@field Surface Bitmap
---@field Label Text

---@class UICustomLobbyContextMenu : Group
---@field Border Bitmap
---@field Background Bitmap
---@field Rows UICustomLobbyContextMenuRow[]
local CustomLobbyContextMenu = ClassUI(Group) {

    ---@param self UICustomLobbyContextMenu
    ---@param parent Control
    ---@param entries UICustomLobbyContextMenuItem[]
    __init = function(self, parent, entries)
        Group.__init(self, parent, "CustomLobbyContextMenu")

        self.Border = Bitmap(self)
        self.Border:SetSolidColor('ff415055')
        self.Border:DisableHitTest()

        self.Background = Bitmap(self)
        self.Background:SetSolidColor('f0101418')
        self.Background:DisableHitTest()

        self.Rows = {}
        for i = 1, table.getn(entries) do
            self.Rows[i] = self:CreateRow(entries[i])
        end
    end,

    --- Builds one clickable row. The surface bitmap both catches the mouse and is the
    --- hover highlight; the label draws on top with hit-testing off.
    ---@param self UICustomLobbyContextMenu
    ---@param entry UICustomLobbyContextMenuItem
    ---@return UICustomLobbyContextMenuRow
    CreateRow = function(self, entry)
        local enabled = entry.enabled ~= false

        ---@type UICustomLobbyContextMenuRow
        local row = Group(self)

        row.Surface = Bitmap(row)
        row.Surface:SetSolidColor('ffffffff')
        row.Surface:SetAlpha(0.0)

        row.Label = UIUtil.CreateText(row, entry.label, FontSize, UIUtil.bodyFont)
        row.Label:SetColor(enabled and 'ffffffff' or 'ff666666')
        row.Label:DisableHitTest()

        if enabled then
            row.Surface.HandleEvent = function(control, event)
                if event.Type == 'MouseEnter' then
                    control:SetAlpha(0.12)
                    return true
                elseif event.Type == 'MouseExit' then
                    control:SetAlpha(0.0)
                    return true
                elseif event.Type == 'ButtonPress' then
                    -- close first, so an action that opens another dialog isn't undone
                    Hide()
                    entry.action()
                    return true
                end
                return false
            end
        else
            row.Surface:DisableHitTest()
        end

        return row
    end,

    ---@param self UICustomLobbyContextMenu
    __post_init = function(self)
        local rowCount = table.getn(self.Rows)

        -- width = widest label (+ padding), floored at a minimum
        local widest = 0
        for i = 1, rowCount do
            local w = self.Rows[i].Label.Width()
            if w > widest then
                widest = w
            end
        end
        self.Width:Set(math.max(LayoutHelpers.ScaleNumber(MinWidth), widest + LayoutHelpers.ScaleNumber(LabelPadX * 2)))
        self.Height:Set(LayoutHelpers.ScaleNumber(MenuPad * 2 + rowCount * ItemHeight))

        Layouter(self.Border):Fill(self):End()
        Layouter(self.Background)
            :AtLeftIn(self, 1):AtRightIn(self, 1):AtTopIn(self, 1):AtBottomIn(self, 1)
            :End()

        for i = 1, rowCount do
            local row = self.Rows[i]
            local top = MenuPad + (i - 1) * ItemHeight
            Layouter(row)
                :AtLeftIn(self, MenuPad):AtRightIn(self, MenuPad):Height(ItemHeight)
                :Top(function() return self.Top() + LayoutHelpers.ScaleNumber(top) end)
                :End()
            Layouter(row.Surface):Fill(row):End()
            Layouter(row.Label):AtLeftIn(row, LabelPadX - MenuPad):AtVerticalCenterIn(row):End()
        end
    end,
}

-------------------------------------------------------------------------------
-- Singleton + show / hide

local ModuleTrash = TrashBag()

---@type UICustomLobbyContextMenu | false
local Instance = false
---@type Bitmap | false
local Cover = false

--- A full-screen invisible catcher behind the menu: a click anywhere off the menu
--- dismisses it.
---@return Bitmap
local function CreateCover()
    local cover = Bitmap(GetFrame(0))
    cover:SetSolidColor('00000000')
    cover.HandleEvent = function(control, event)
        if event.Type == 'ButtonPress' then
            Hide()
            return true
        end
        return false
    end
    Layouter(cover):Fill(GetFrame(0)):End()
    return cover
end

--- Opens a context menu at the screen point, populated with `entries` (no-op for an
--- empty list). Replaces any menu already open.
---@param entries UICustomLobbyContextMenuItem[]
---@param x number
---@param y number
function Show(entries, x, y)
    Hide()
    if not entries or table.empty(entries) then
        return
    end

    local frame = GetFrame(0)

    -- The slot rows raise their hit area with `Over(self, ...)`, so a default-depth
    -- overlay sits *under* them and never catches the click. Pin the cover and the
    -- menu above everything (the popup.lua pattern) so click-outside actually fires.
    local baseDepth = frame:GetTopmostDepth()

    Cover = CreateCover()
    Cover.Depth:Set(baseDepth + 10)

    Instance = CustomLobbyContextMenu(frame, entries)
    Instance.Depth:Set(baseDepth + 20)
    ModuleTrash:Add(Instance)

    -- keep the menu fully on-screen
    local left = math.min(x, frame.Right() - Instance.Width())
    local top = math.min(y, frame.Bottom() - Instance.Height())
    Instance.Left:Set(math.max(0, left))
    Instance.Top:Set(math.max(0, top))

    -- Esc closes the menu before it would reach the lobby's leave handler
    EscapeHandler.PushEscapeHandler(function() Hide() end)
end

--- Closes the open menu (if any).
function Hide()
    if not Instance then
        return
    end
    EscapeHandler.PopEscapeHandler()
    Instance:Destroy()
    Instance = false
    if Cover then
        Cover:Destroy()
        Cover = false
    end
end

-------------------------------------------------------------------------------
--#region Debugging

function __moduleinfo.OnDirty()
    Hide()
    ModuleTrash:Destroy()
end

--#endregion
