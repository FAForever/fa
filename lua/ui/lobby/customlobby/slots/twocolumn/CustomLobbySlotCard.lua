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

-- The fat slot presentation: a half-width, double-height card used by the two-column team layout.
-- The same data as the thin row, reflowed onto two lines so it reads in a narrow column —
--
--   left column                 right column (mirrored, via SetMirrored)
--   ┌──────────────────────────┐ ┌──────────────────────────┐
--   │ ▣  PlayerName       ready │ │ ready       PlayerName  ▣ │   line 1: swatch · name · ready
--   │ Cybran · T1       1.4k ▢  │ │  ▢ 1.4k       T1 · Cybran │   line 2: faction · team · cpu
--   └──────────────────────────┘ └──────────────────────────┘
--
-- The right column is laid out mirrored so the two teams face each other (the leading edge —
-- swatch + name, faction — sits on the inner side).
--
-- It is pure arrangement over CustomLobbySlotBase: it builds the standard named controls and lays
-- them out; the base paints them and owns all behaviour (subscriptions, CPU math, drag-to-swap,
-- intents).

local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")

local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local CustomLobbySlotBase = import("/lua/ui/lobby/customlobby/slots/customlobbyslotbase.lua").SlotBase

local Layouter = LayoutHelpers.ReusedLayoutFor

--- Restores a control's Left/Right to the default circular relationship, clearing whichever edge a
--- previous layout pass pinned. Re-mirroring re-anchors the *opposite* horizontal edge, so without
--- this the old pin survives and the control stays stuck to its old side. Leaves Width/Height alone
--- (unlike Control.ResetLayout), so a Text keeps its intrinsic auto-width.
---@param control Control
local function ResetHorizontalEdges(control)
    control.Left:Set(function() return control.Right() - control.Width() end)
    control.Right:Set(function() return control.Left() + control.Width() end)
end

---@class UICustomLobbySlotCard : UICustomLobbySlotBase
---@field Avatar Bitmap
---@field ColorSwatch Bitmap
---@field Name Text
---@field Flag Bitmap
---@field Ready Text
---@field FactionIcons Group
---@field Team Text
---@field Rating Text
---@field Cpu Text
---@field CpuIndicator Bitmap
---@field CpuHover Bitmap
---@field ColorZone Bitmap
---@field FactionZone Bitmap
---@field TeamZone Bitmap
---@field Mirrored boolean   # right-column cards lay out mirrored so the two teams face each other
local CustomLobbySlotCard = Class(CustomLobbySlotBase) {

    ---@param self UICustomLobbySlotCard
    CreateContents = function(self)
        self.Mirrored = false

        -- a reserved avatar placeholder (a dim box for now; a real FAF avatar lands later)
        self.Avatar = Bitmap(self)
        self.Avatar:SetSolidColor('33ffffff')
        self.Avatar:SetAlpha(0.0)
        self.Avatar:DisableHitTest()

        self.ColorSwatch = Bitmap(self)
        self.ColorSwatch:SetSolidColor('00000000')
        self.Name = UIUtil.CreateText(self, "", 14, UIUtil.bodyFont)

        -- the player's country flag (hidden until a country resolves)
        self.Flag = Bitmap(self)
        self.Flag:SetAlpha(0.0)
        self.Flag:DisableHitTest()

        self.Ready = UIUtil.CreateText(self, "", 12, UIUtil.bodyFont)
        -- the selected factions as a small icon strip (Random icon when the full set is allowed)
        self:CreateFactionIcons()
        self.Team = UIUtil.CreateText(self, "", 12, UIUtil.bodyFont)

        self.Rating = UIUtil.CreateText(self, "", 12, UIUtil.bodyFont)
        self.Rating:SetColor('ffc8ccd0')

        self.Cpu = UIUtil.CreateText(self, "", 12, UIUtil.bodyFont)
        self.CpuIndicator = Bitmap(self)
        self.CpuIndicator:SetSolidColor('ff7ad97a')
        self.CpuIndicator:SetAlpha(0.0)
        self.CpuIndicator:DisableHitTest()

        -- a hover zone over the CPU score; the base routes enter/exit/press
        self.CpuHover = Bitmap(self)
        self.CpuHover:SetSolidColor('00000000')
        self.CpuHover.HandleEvent = function(control, event)
            return self:HandleCpuHoverEvent(event)
        end

        -- click zones over the editable elements (colour / faction / team); the base opens the matching
        -- picker when the seat is editable, else falls through to the normal row press
        self.ColorZone = self:CreateEditZone("color")
        self.FactionZone = self:CreateEditZone("faction")
        self.TeamZone = self:CreateEditZone("team")

        -- the host-only close/open button (shown only on an empty / closed seat)
        self:CreateSlotButton()
    end,

    --- Lays the card out, mirrored for a right-column card so the leading edge (swatch + name,
    --- faction) is on the *inner* side and the two teams face each other. Texts auto-size their
    --- width, so anchoring the opposite edge right-aligns them — no manual measuring needed.
    ---@param self UICustomLobbySlotCard
    LayoutContents = function(self)
        -- clear any horizontal edge a previous (opposite-orientation) pass pinned, so only the new
        -- anchor binds each control (the vertical anchors don't change between orientations)
        for _, control in { self.Avatar, self.ColorSwatch, self.Name, self.Flag, self.Ready, self.FactionIcons, self.Team, self.Rating, self.Cpu, self.CpuIndicator } do
            ResetHorizontalEdges(control)
        end

        if self.Mirrored then
            -- line 1 (top): ready … name · swatch · avatar
            Layouter(self.Avatar):AtRightIn(self, 6):AtTopIn(self, 6):Width(16):Height(16):End()
            Layouter(self.ColorSwatch):AnchorToLeft(self.Avatar, 6):AtVerticalCenterIn(self.Avatar):Width(14):Height(14):End()
            Layouter(self.Name):AnchorToLeft(self.ColorSwatch, 6):AtVerticalCenterIn(self.ColorSwatch):End()
            Layouter(self.Ready):AtLeftIn(self, 6):AtVerticalCenterIn(self.ColorSwatch):End()

            -- line 2 (bottom): cpu [indicator] · rating … team · faction · flag
            Layouter(self.Flag):AtRightIn(self, 6):AtBottomIn(self, 8):Width(18):Height(12):End()
            Layouter(self.FactionIcons):AnchorToLeft(self.Flag, 6):AtVerticalCenterIn(self.Flag):End()
            Layouter(self.Team):AnchorToLeft(self.FactionIcons, 8):AtVerticalCenterIn(self.Flag):End()
            Layouter(self.Cpu):AtLeftIn(self, 6):AtVerticalCenterIn(self.Flag):End()
            Layouter(self.CpuIndicator):AnchorToRight(self.Cpu, 5):AtVerticalCenterIn(self.Flag):Width(8):Height(12):End()
            Layouter(self.Rating):AnchorToRight(self.CpuIndicator, 8):AtVerticalCenterIn(self.Flag):End()
        else
            -- line 1 (top): avatar · swatch · name … ready
            Layouter(self.Avatar):AtLeftIn(self, 6):AtTopIn(self, 6):Width(16):Height(16):End()
            Layouter(self.ColorSwatch):AnchorToRight(self.Avatar, 6):AtVerticalCenterIn(self.Avatar):Width(14):Height(14):End()
            Layouter(self.Name):AnchorToRight(self.ColorSwatch, 6):AtVerticalCenterIn(self.ColorSwatch):End()
            Layouter(self.Ready):AtRightIn(self, 6):AtVerticalCenterIn(self.ColorSwatch):End()

            -- line 2 (bottom): flag · faction · team … rating · [indicator] cpu
            Layouter(self.Flag):AtLeftIn(self, 6):AtBottomIn(self, 8):Width(18):Height(12):End()
            Layouter(self.FactionIcons):AnchorToRight(self.Flag, 6):AtVerticalCenterIn(self.Flag):End()
            Layouter(self.Team):AnchorToRight(self.FactionIcons, 8):AtVerticalCenterIn(self.Flag):End()
            Layouter(self.Cpu):AtRightIn(self, 6):AtVerticalCenterIn(self.Flag):End()
            Layouter(self.CpuIndicator):AnchorToLeft(self.Cpu, 5):AtVerticalCenterIn(self.Flag):Width(8):Height(12):End()
            Layouter(self.Rating):AnchorToLeft(self.CpuIndicator, 8):AtVerticalCenterIn(self.Flag):End()
        end
        self:LayoutFactionIcons()

        Layouter(self.CpuHover):Fill(self.Cpu):Over(self, 20):End()
        Layouter(self.ColorZone):Fill(self.ColorSwatch):Over(self, 20):End()
        Layouter(self.FactionZone):Fill(self.FactionIcons):Over(self, 20):End()
        Layouter(self.TeamZone):Fill(self.Team):Over(self, 20):End()

        -- centred so it reads cleanly on an empty / closed card, regardless of mirror
        Layouter(self.SlotButton):AtCenterIn(self):Width(60):Height(18):Over(self, 20):End()
        self:LayoutSlotButton()
    end,

    --- Sets the mirror state (the two-column layout calls this per the card's column) and re-lays the
    --- contents if it changed.
    ---@param self UICustomLobbySlotCard
    ---@param mirrored boolean
    SetMirrored = function(self, mirrored)
        mirrored = mirrored or false
        if self.Mirrored == mirrored then
            return
        end
        self.Mirrored = mirrored
        self:LayoutContents()
    end,
}

---@param parent Control
---@param slotIndex number
---@param coordinator UICustomLobbySlotCoordinator
---@return UICustomLobbySlotCard
Create = function(parent, slotIndex, coordinator)
    return CustomLobbySlotCard(parent, slotIndex, coordinator)
end
