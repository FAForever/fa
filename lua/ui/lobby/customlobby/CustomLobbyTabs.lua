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

-- A generic tabbed panel: a strip of tab buttons over a content area. The active tab's content
-- component is **created when its tab is selected and destroyed when you switch away** — only one
-- panel is alive at a time, so churn is cheap and there's no hidden-panel bleed (the same model the
-- config interface uses).
--
-- Construct with a tab list `{ { Label = "Chat", Create = fn }, … }`, where `Create(parent)` builds
-- the content component (which may expose an `Initialize()` the container calls after sizing it).
-- An optional `OnSelect(index, label)` fires on every switch — used when a persistent sibling (e.g.
-- the map preview, which can't be churned) must be shown/hidden alongside a tab.
--
-- The **flexible** tabs divide the strip evenly across the available width. A tab may instead be
-- `Compact = true`: a fixed narrow width, excluded from the division (the flexible tabs share what's
-- left) — for a small utility tab. A tab may show an `Icon` (a texture) centred *instead* of its
-- label (paired with Compact, a tidy icon-only tab with no distracting text).
--
-- A flexible tab may carry an optional `Badge` LazyVar (a string): when non-empty it renders a small
-- grey count pill to the right of the label; and an optional `Action` (`{ Create, Visible? }`): a
-- small button the owner builds **inside the tab, left of the label** (e.g. a config gear that opens
-- that tab's editor). Its `Visible` LazyVar hides it (and collapses it out of the layout) when it
-- doesn't apply — e.g. for non-hosts. The action, label and pill are centred together as one
-- cluster, so nothing collides with the tab edge. The container only observes the LazyVars — the
-- owner decides what the count + action mean.
--
-- The parent sizes this control and calls `Initialize()` after mounting (so the first panel reads a
-- concrete height — three-phase init, /lua/ui/CLAUDE.md § 1).

local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")

local Group = import("/lua/maui/group.lua").Group
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap

local LazyVarDerive = import("/lua/lazyvar.lua").Derive
local Layouter = LayoutHelpers.ReusedLayoutFor

local TabHeight = 26
local TabGap = 2

local TabIdleColor = 'ff141a20'
local TabHoverColor = 'ff1f262e'
local TabActiveColor = 'ff2c3e48'

-- the count badge: a grey pill (rounded-look solid) with a number, sitting to the right of a label
local BadgeHeight = 16
local BadgeMinWidth = 18         -- keeps a single digit roughly square
local BadgePadH = 6              -- horizontal text padding inside the pill
local BadgeGap = 5               -- between cluster items (action / label / pill)
local BadgeColor = 'ff454c56'
local BadgeTextColor = 'ffd0d4d8'

-- the per-tab action button (e.g. a config gear), square, sitting left of the label
local ActionSize = 18

-- a compact (utility) tab: fixed narrow width, and the size of its centred icon
local CompactWidth = 28
local TabIconSize = 16

---@class UICustomLobbyTabAction
---@field Create fun(parent: Control): Control # builds the action control (the owner wires its click)
---@field Visible? LazyVar # boolean; false hides the action + collapses it from the cluster (default: always shown)

---@class UICustomLobbyTab
---@field Label string
---@field Create fun(parent: Control): Control
---@field Badge? LazyVar # optional count-badge text (a string; "" hides the pill)
---@field Action? UICustomLobbyTabAction # optional button inside the tab, left of the label
---@field Icon? FileName # optional centred icon (a UIFile path) shown instead of the label (tidy with Compact)
---@field Compact? boolean # fixed narrow width, excluded from the even division (a utility tab)

---@class UICustomLobbyTabsOptions
---@field Tabs UICustomLobbyTab[]
---@field OnSelect? fun(index: number, label: string)

---@class UICustomLobbyTabBadge : Group
---@field Bg Bitmap
---@field Text Text

---@class UICustomLobbyTabButton : Group
---@field Bg Bitmap
---@field Label? Text # present only for a text tab (absent when the tab uses an Icon)
---@field Icon? Bitmap # present only when the tab defines an Icon
---@field Badge? UICustomLobbyTabBadge # present only when the tab defines a Badge LazyVar
---@field Action? Control # present only when the tab defines an Action

---@class UICustomLobbyTabs : Group
---@field Trash TrashBag
---@field Tabs UICustomLobbyTab[]
---@field OnSelectCb? fun(index: number, label: string)
---@field TabStripArea Group
---@field TabContentArea Group
---@field TabButtons UICustomLobbyTabButton[]
---@field ActiveTab number
---@field CurrentPanel Control | false
local CustomLobbyTabs = ClassUI(Group) {

    ---@param self UICustomLobbyTabs
    ---@param parent Control
    ---@param options UICustomLobbyTabsOptions
    __init = function(self, parent, options)
        Group.__init(self, parent, "CustomLobbyTabs")

        self.Trash = TrashBag()
        self.Tabs = options.Tabs
        self.OnSelectCb = options.OnSelect
        -- open on the first non-compact tab — a compact utility tab (e.g. Logs) shouldn't be the
        -- default view just because it sits leftmost
        self.ActiveTab = 1
        for index = 1, table.getn(self.Tabs) do
            if not self.Tabs[index].Compact then
                self.ActiveTab = index
                break
            end
        end
        self.CurrentPanel = false

        self.TabStripArea = Group(self, "CustomLobbyTabsStrip")
        self.TabContentArea = Group(self, "CustomLobbyTabsContent")

        self.TabButtons = {}
        for index = 1, table.getn(self.Tabs) do
            self.TabButtons[index] = self:CreateTabButton(self.Tabs[index].Label, index)
        end
    end,

    ---@param self UICustomLobbyTabs
    __post_init = function(self)
        Layouter(self.TabStripArea):AtLeftIn(self):AtRightIn(self):AtTopIn(self):Height(TabHeight):End()
        Layouter(self.TabContentArea)
            :AtLeftIn(self):AtRightIn(self)
            :AnchorToBottom(self.TabStripArea, 6):AtBottomIn(self)
            :End()

        -- compact tabs take a fixed narrow width; the flexible tabs share what's left of the strip
        -- evenly. Width/Left are bound to the strip so they re-flow with the column.
        local count = table.getn(self.TabButtons)
        local flexCount = 0
        for index = 1, count do
            if not self.Tabs[index].Compact then
                flexCount = flexCount + 1
            end
        end

        -- the width of one flexible tab: the strip minus all gaps and all compact tabs, split evenly
        local function flexWidth()
            local gap = LayoutHelpers.ScaleNumber(TabGap)
            local compactW = LayoutHelpers.ScaleNumber(CompactWidth)
            local remaining = self.TabStripArea.Width() - gap * (count - 1) - compactW * (count - flexCount)
            if flexCount <= 0 then
                return 0
            end
            return remaining / flexCount
        end
        local function widthOf(index)
            return self.Tabs[index].Compact and LayoutHelpers.ScaleNumber(CompactWidth) or flexWidth()
        end

        for index = 1, count do
            local button = self.TabButtons[index]
            local slot = index
            Layouter(button):AtTopIn(self.TabStripArea):Height(TabHeight):End()
            button.Width:Set(function() return widthOf(slot) end)
            button.Left:Set(function()
                local gap = LayoutHelpers.ScaleNumber(TabGap)
                local x = self.TabStripArea.Left()
                for j = 1, slot - 1 do
                    x = x + widthOf(j) + gap
                end
                return x
            end)
            Layouter(button.Bg):Fill(button):End()
            self:LayoutButtonContent(button)
            button.Bg:SetSolidColor(index == self.ActiveTab and TabActiveColor or TabIdleColor)
        end
    end,

    --- Lays out a button's content — an optional action button, the label, and an optional count
    --- pill — centred together as one `[action] [label] [pill]` cluster, so nothing collides with
    --- the tab edge for a long label. Each side piece collapses (contributes 0 width) when absent
    --- or hidden, re-centring the rest. Private.
    ---@param self UICustomLobbyTabs
    ---@param button UICustomLobbyTabButton
    LayoutButtonContent = function(self, button)
        -- an icon tab is just a centred glyph (no label/action/pill cluster)
        if button.Icon then
            Layouter(button.Icon):AtCenterIn(button):Width(TabIconSize):Height(TabIconSize):End()
            return
        end

        local action = button.Action
        local badge = button.Badge

        -- vertical placement for every piece; the action's Width is owned by its visibility wiring
        -- (CreateTabButton), the pill's by its text. The action is hit-enabled and overlaps the
        -- tab's solid Bg, so lift it a depth above Bg — otherwise (equal default depth) the click
        -- could land on the tab background instead of the gear.
        Layouter(button.Label):AtVerticalCenterIn(button):End()
        if action then
            Layouter(action):AtVerticalCenterIn(button):Height(ActionSize):Over(button.Bg, 1):End()
        end
        if badge then
            Layouter(badge):AtVerticalCenterIn(button):Height(BadgeHeight):End()
            badge.Width:Set(function()
                local textWidth = badge.Text.Width()
                if textWidth <= 0 then
                    return 0
                end
                return math.max(LayoutHelpers.ScaleNumber(BadgeMinWidth), textWidth + LayoutHelpers.ScaleNumber(BadgePadH) * 2)
            end)
            Layouter(badge.Bg):Fill(badge):End()
            Layouter(badge.Text):AtCenterIn(badge):End()
        end

        -- cluster maths: each item contributes its width plus a leading gap only when it has width
        local function gapFor(width)
            return width > 0 and LayoutHelpers.ScaleNumber(BadgeGap) or 0
        end
        local function actionWidth()
            return action and action.Width() or 0
        end
        local function badgeWidth()
            return badge and badge.Width() or 0
        end
        local function clusterLeft()
            local cluster = actionWidth() + gapFor(actionWidth())
                + button.Label.Width()
                + gapFor(badgeWidth()) + badgeWidth()
            return button.Left() + (button.Width() - cluster) / 2
        end

        if action then
            action.Left:Set(function() return clusterLeft() end)
        end
        button.Label.Left:Set(function()
            return clusterLeft() + actionWidth() + gapFor(actionWidth())
        end)
        if badge then
            badge.Left:Set(function() return button.Label.Right() + gapFor(badgeWidth()) end)
        end
    end,

    --- Opens the initial tab. Called by the parent after it has sized this control (the content
    --- needs a concrete height — three-phase init).
    ---@param self UICustomLobbyTabs
    Initialize = function(self)
        self:SelectTab(self.ActiveTab)
    end,

    --- Switches tabs: destroys the current content, builds the chosen one into the content area,
    --- and recolours the buttons. Clicking the active tab again is a no-op.
    ---@param self UICustomLobbyTabs
    ---@param index number
    SelectTab = function(self, index)
        if self.ActiveTab == index and self.CurrentPanel then
            return
        end
        self.ActiveTab = index

        for i = 1, table.getn(self.TabButtons) do
            self.TabButtons[i].Bg:SetSolidColor(i == index and TabActiveColor or TabIdleColor)
        end

        if self.CurrentPanel then
            self.CurrentPanel:Destroy()
            self.CurrentPanel = false
        end

        local panel = self.Tabs[index].Create(self.TabContentArea)
        Layouter(panel):Fill(self.TabContentArea):End()
        if panel.Initialize then
            panel:Initialize()
        end
        self.CurrentPanel = panel

        if self.OnSelectCb then
            self.OnSelectCb(index, self.Tabs[index].Label)
        end
    end,

    --- Builds one clickable tab button (a tinted group + label, plus a count pill when the tab
    --- defines a `Badge` LazyVar). Private.
    ---@param self UICustomLobbyTabs
    ---@param label string
    ---@param index number
    ---@return UICustomLobbyTabButton
    CreateTabButton = function(self, label, index)
        local tab = self.Tabs[index]
        local button = Group(self.TabStripArea, "CustomLobbyTabButton")

        button.Bg = Bitmap(button)
        button.Bg:SetSolidColor(TabIdleColor)

        if tab.Icon then
            -- an icon tab: a centred glyph instead of the text label (and no badge/action cluster)
            button.Icon = UIUtil.CreateBitmap(button, tab.Icon)
            button.Icon:DisableHitTest()
            button.Bg.HandleEvent = self:MakeTabEvent(button, index)
            return button
        end

        button.Label = UIUtil.CreateText(button, label, 13, UIUtil.titleFont)
        button.Label:SetColor('ffc8ccd0')
        button.Label:DisableHitTest()

        -- optional count pill: created only when the tab supplies a Badge LazyVar; the container
        -- just mirrors that LazyVar's string (the owner decides what the count means)
        local badgeLazy = self.Tabs[index].Badge
        if badgeLazy then
            local badge = Group(button, "CustomLobbyTabBadge") --[[@as UICustomLobbyTabBadge]]
            badge:DisableHitTest()
            badge.Bg = Bitmap(badge)
            badge.Bg:SetSolidColor(BadgeColor)
            badge.Bg:DisableHitTest()
            badge.Text = UIUtil.CreateText(badge, "", 11, UIUtil.bodyFont)
            badge.Text:SetColor(BadgeTextColor)
            badge.Text:DisableHitTest()
            button.Badge = badge

            -- the badge Derive fires synchronously on creation (before TabButtons[index] is set),
            -- so operate on the captured `badge`, not a lookup by index
            self.Trash:Add(LazyVarDerive(badgeLazy, function(badgeTextLazy)
                self:SetBadge(badge, badgeTextLazy() or "")
            end))
        end

        -- optional per-tab action (e.g. a config gear): the owner builds it (and wires its click),
        -- the container places it and drives its visibility from the optional Visible LazyVar. The
        -- action's width is owned here — full when shown, 0 when hidden — so the cluster re-centres.
        local actionDef = self.Tabs[index].Action
        if actionDef then
            local action = actionDef.Create(button)
            button.Action = action
            if actionDef.Visible then
                -- fires synchronously on creation (before TabButtons[index] is set) — operate on
                -- the captured `action`, not a lookup by index
                self.Trash:Add(LazyVarDerive(actionDef.Visible, function(visibleLazy)
                    self:SetActionVisible(action, visibleLazy() and true or false)
                end))
            else
                action.Width:Set(LayoutHelpers.ScaleNumber(ActionSize))
            end
        end

        button.Bg.HandleEvent = self:MakeTabEvent(button, index)

        return button
    end,

    --- The tab background's event handler: click selects the tab, hover tints it (unless active).
    --- Shared by text and icon tabs. Private.
    ---@param self UICustomLobbyTabs
    ---@param button UICustomLobbyTabButton
    ---@param index number
    ---@return fun(control: Control, event: KeyEvent): boolean
    MakeTabEvent = function(self, button, index)
        return function(control, event)
            if event.Type == 'ButtonPress' then
                self:SelectTab(index)
                return true
            elseif event.Type == 'MouseEnter' then
                if self.ActiveTab ~= index then
                    button.Bg:SetSolidColor(TabHoverColor)
                end
                return true
            elseif event.Type == 'MouseExit' then
                if self.ActiveTab ~= index then
                    button.Bg:SetSolidColor(TabIdleColor)
                end
                return true
            end
            return false
        end
    end,

    --- Updates a count pill from its Badge LazyVar by setting its text. An empty string collapses
    --- the pill to width 0 (its `Width` binding returns 0 when the text has no width), so the cluster
    --- re-centres on the bare label and the grey `Bg` paints nothing.
    ---
    --- Drives *only* the text, never `Hide()`/`Show()`: the badge is often empty at construction
    --- (the model populates after) and a control hidden before it is laid out doesn't reliably come
    --- back on `Show()` — the hide-before-layout gotcha (see SetActionVisible / /lua/ui/CLAUDE.md).
    --- Private.
    ---@param self UICustomLobbyTabs
    ---@param badge UICustomLobbyTabBadge
    ---@param text string
    SetBadge = function(self, badge, text)
        badge.Text:SetText(text)
    end,

    --- Shows or hides an action button by collapsing its width to 0 (the label/pill cluster then
    --- re-centres as if the action weren't there) — used to drop a host-only action for clients.
    ---
    --- Deliberately drives *only* the width, never `Hide()`/`Show()`: this derive fires once at
    --- construction (in a real lobby `IsHost` is still false then, before `__post_init` lays the
    --- button out) and again when `IsHost` flips true. A `Button` hidden before it is laid out does
    --- not reliably come back on `Show()` (the Hide/Show-before-layout gotcha — see /lua/ui/CLAUDE.md),
    --- so the gear stayed invisible for the host. A 0-width button renders nothing and can't be
    --- clicked, so width alone is a complete collapse. Private.
    ---@param self UICustomLobbyTabs
    ---@param action Control
    ---@param shown boolean
    SetActionVisible = function(self, action, shown)
        action.Width:Set(shown and LayoutHelpers.ScaleNumber(ActionSize) or 0)
    end,

    ---@param self UICustomLobbyTabs
    OnDestroy = function(self)
        if self.CurrentPanel then
            self.CurrentPanel:Destroy()
            self.CurrentPanel = false
        end
        self.Trash:Destroy()
    end,
}

---@param parent Control
---@param options UICustomLobbyTabsOptions
---@return UICustomLobbyTabs
Create = function(parent, options)
    return CustomLobbyTabs(parent, options)
end
