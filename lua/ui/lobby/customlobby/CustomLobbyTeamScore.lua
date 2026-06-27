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

-- The accumulated team rating shown at the top of the lobby — `Side A  3150  ·  3025  Side B`.
--
-- It is shown ONLY for the binary auto-team formations, where the two sides are well-defined:
--
--   tvsb → Top  / Bottom    (by start-position Y)
--   lvsr → Left / Right     (by start-position X)
--   pvsi → Odd  / Even      (by start-spot parity — needs no map)
--
-- For `none` / `manual` there's no reliable 2-side split, so the whole widget hides. The split
-- mirrors how auto-teams actually resolve at launch (start position), so the score reads true to
-- the map; the positional modes hide until a map (with start spots) is selected.
--
-- It reads the resolved split from the slots derived model's **team aggregate** (`GetTeams`): mode,
-- side labels, whether the split is resolved, and the per-side rating totals — all computed once
-- there. So this widget is a single subscription with no logic of its own; it never writes the model.

local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")

local Group = import("/lua/maui/group.lua").Group
local CustomLobbySlotsDerivedModel = import("/lua/ui/lobby/customlobby/models/derived/customlobbyslotsderivedmodel.lua")

local LazyVarDerive = import("/lua/lazyvar.lua").Derive
local Layouter = LayoutHelpers.ReusedLayoutFor

---@class UICustomLobbyTeamScore : Group
---@field Trash TrashBag
---@field LabelA Text
---@field ScoreA Text
---@field Sep Text
---@field ScoreB Text
---@field LabelB Text
---@field Ready boolean
---@field TeamsObserver LazyVar
local CustomLobbyTeamScore = ClassUI(Group) {

    ---@param self UICustomLobbyTeamScore
    ---@param parent Control
    __init = function(self, parent)
        Group.__init(self, parent, "CustomLobbyTeamScore")

        self.Trash = TrashBag()
        self.Ready = false

        self.LabelA = UIUtil.CreateText(self, "", 14, UIUtil.titleFont)
        self.LabelA:SetColor('ff9aa0a8')
        self.LabelA:DisableHitTest()
        self.ScoreA = UIUtil.CreateText(self, "", 16, UIUtil.titleFont)
        self.ScoreA:DisableHitTest()
        self.Sep = UIUtil.CreateText(self, "·", 16, UIUtil.titleFont)
        self.Sep:SetColor('ff5a606a')
        self.Sep:DisableHitTest()
        self.ScoreB = UIUtil.CreateText(self, "", 16, UIUtil.titleFont)
        self.ScoreB:DisableHitTest()
        self.LabelB = UIUtil.CreateText(self, "", 14, UIUtil.titleFont)
        self.LabelB:SetColor('ff9aa0a8')
        self.LabelB:DisableHitTest()

        -- one subscription: the slots derived model's team aggregate already resolved the side split
        -- and summed the per-side ratings (and re-fires only when those move)
        self.TeamsObserver = self.Trash:Add(
            LazyVarDerive(CustomLobbySlotsDerivedModel.GetTeamsVar(), function(lazy) lazy() self:Refresh() end))
    end,

    ---@param self UICustomLobbyTeamScore
    __post_init = function(self)
        -- centred row: LabelA  ScoreA  ·  ScoreB  LabelB
        Layouter(self.Sep):AtHorizontalCenterIn(self):AtVerticalCenterIn(self):End()
        Layouter(self.ScoreA):AnchorToLeft(self.Sep, 10):AtVerticalCenterIn(self):End()
        Layouter(self.LabelA):AnchorToLeft(self.ScoreA, 8):AtVerticalCenterIn(self):End()
        Layouter(self.ScoreB):AnchorToRight(self.Sep, 10):AtVerticalCenterIn(self):End()
        Layouter(self.LabelB):AnchorToRight(self.ScoreB, 8):AtVerticalCenterIn(self):End()
    end,

    --- Builds the score after the parent has placed the widget (kept symmetric with the panels).
    ---@param self UICustomLobbyTeamScore
    Initialize = function(self)
        self.Ready = true
        self:Refresh()
    end,

    --- Paints the two side totals from the slots model's team aggregate, or hides the widget when the
    --- mode has no 2-side split (none / manual) or the sides can't be determined yet (no map).
    ---@param self UICustomLobbyTeamScore
    Refresh = function(self)
        if not self.Ready then
            return
        end
        local teams = CustomLobbySlotsDerivedModel.GetTeams()
        if not (teams.Labels and teams.Resolved) then
            self:Hide()
            return
        end

        self.LabelA:SetText(teams.Labels[1])
        self.ScoreA:SetText(tostring(teams.Totals[1]))
        self.LabelB:SetText(teams.Labels[2])
        self.ScoreB:SetText(tostring(teams.Totals[2]))
        self:Show()
    end,

    ---@param self UICustomLobbyTeamScore
    OnDestroy = function(self)
        self.Trash:Destroy()
    end,
}

---@param parent Control
---@return UICustomLobbyTeamScore
Create = function(parent)
    return CustomLobbyTeamScore(parent)
end
