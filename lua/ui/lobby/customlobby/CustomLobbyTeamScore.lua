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
-- Self-subscribes to the model: `GameOptions` (the `AutoTeams` mode), `ScenarioFile` (start
-- positions) and every slot's player (ratings). Reference data only — it never writes the model.

local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")

local Group = import("/lua/maui/group.lua").Group
local CustomLobbyLaunchModel = import("/lua/ui/lobby/customlobby/customlobbylaunchmodel.lua")
local CustomLobbyRules = import("/lua/ui/lobby/customlobby/customlobbyrules.lua")

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
---@field GameOptionsObserver LazyVar
---@field ScenarioObserver LazyVar
---@field PlayerObservers LazyVar[]
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

        local model = CustomLobbyLaunchModel.GetSingleton()
        self.GameOptionsObserver = self.Trash:Add(
            LazyVarDerive(model.GameOptions, function(lazy) lazy() self:Refresh() end))
        self.ScenarioObserver = self.Trash:Add(
            LazyVarDerive(model.ScenarioFile, function(lazy) lazy() self:Refresh() end))
        self.PlayerObservers = {}
        for slot = 1, CustomLobbyLaunchModel.MaxSlots do
            self.PlayerObservers[slot] = self.Trash:Add(
                LazyVarDerive(model.Players[slot], function(lazy) lazy() self:Refresh() end))
        end
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

    --- Recomputes the two side totals for the current auto-team mode, or hides the widget when the
    --- mode has no 2-side split (none / manual) or the sides can't be determined yet (no map).
    ---@param self UICustomLobbyTeamScore
    Refresh = function(self)
        if not self.Ready then
            return
        end
        local mode = CustomLobbyRules.AutoTeamMode()
        local labels = CustomLobbyRules.SideLabels(mode)
        if not labels then
            self:Hide()
            return
        end

        local totals = self:Totals()
        if not totals then
            self:Hide()
            return
        end

        self.LabelA:SetText(labels[1])
        self.ScoreA:SetText(tostring(totals[1]))
        self.LabelB:SetText(labels[2])
        self.ScoreB:SetText(tostring(totals[2]))
        self:Show()
    end,

    --- The accumulated rating per side `{ a, b }`, or nil if the split can't be determined yet (a
    --- positional mode with no map / start positions loaded). Each seated player is attributed by
    --- the shared side resolver, keyed on its start spot.
    ---@param self UICustomLobbyTeamScore
    ---@return number[] | nil
    Totals = function(self)
        local resolver, resolved = CustomLobbyRules.BuildSideResolver()
        if not (resolver and resolved) then
            return nil
        end

        local model = CustomLobbyLaunchModel.GetSingleton()
        local a, b = 0, 0
        for slot = 1, CustomLobbyLaunchModel.MaxSlots do
            local player = model.Players[slot]()
            if player then
                local rating = player.PL or 0
                local side = resolver(player.StartSpot)
                if side == 1 then
                    a = a + rating
                elseif side == 2 then
                    b = b + rating
                end
            end
        end
        return { math.floor(a), math.floor(b) }
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
