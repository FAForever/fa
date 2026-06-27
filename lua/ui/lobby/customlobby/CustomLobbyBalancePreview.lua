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

-- The auto-balance **preview**: a host-only modal that shows the proposed two-team split (and the
-- resulting match quality) BEFORE anything is re-seated, with Apply / Cancel — so the host commits a
-- balance on purpose (USER_STORIES § R: "an opti team preview"). It is a transient picker, owns no
-- synced state: it reads the current lobby snapshot, runs the pure CustomLobbyBalancer kernel, and on
-- Apply hands the proposed arrangement to the host-authoritative `RequestApplyBalance` intent.
--
-- Built to the preset dialog's shape (areas layout, three-phase init, Popup singleton).

local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")

local Group = import("/lua/maui/group.lua").Group
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local Popup = import("/lua/ui/controls/popups/popup.lua").Popup
local ItemList = import("/lua/maui/itemlist.lua").ItemList

local CustomLobbyLaunchModel = import("/lua/ui/lobby/customlobby/models/customlobbylaunchmodel.lua")
local CustomLobbySessionModel = import("/lua/ui/lobby/customlobby/models/customlobbysessionmodel.lua")
local CustomLobbyScenarioDerivedModel = import("/lua/ui/lobby/customlobby/models/derived/customlobbyscenarioderivedmodel.lua")
local CustomLobbyRules = import("/lua/ui/lobby/customlobby/customlobbyrules.lua")
local CustomLobbyBalancer = import("/lua/ui/lobby/customlobby/customlobbybalancer.lua")
local CustomLobbyController = import("/lua/ui/lobby/customlobby/customlobbycontroller.lua")

local Layouter = LayoutHelpers.ReusedLayoutFor

local Debug = false

local DialogWidth = 520
local DialogHeight = 420
local Pad = 12
local ColumnGap = 16
local TitleHeight = 30
local StatusHeight = 24
local ActionHeight = 52
local ScrollbarInset = 20
local ButtonGap = 8

local LabelColor = 'ffc8ccd0'
local HeaderColor = 'ffd9c97a'

--- Creates an invisible layout area (tinted while Debug is on).
---@param parent Control
---@param name string
---@param color string
---@return Group
local function CreateArea(parent, name, color)
    local area = Group(parent, name)
    local bg = Bitmap(area)
    bg:SetSolidColor(color)
    bg:SetAlpha(Debug and 0.18 or 0.0)
    bg:DisableHitTest()
    Layouter(bg):Fill(area):End()
    return area
end

--- Gathers the current lobby snapshot and runs the balancer. Reads the models (a transient picker
--- may); the kernel itself stays pure.
---@return UICustomLobbyBalanceResult
local function ComputeForCurrentLobby()
    local launch = CustomLobbyLaunchModel.GetSingleton()
    local session = CustomLobbySessionModel.GetSingleton()

    local players = {}
    for slot = 1, CustomLobbyLaunchModel.MaxSlots do
        local player = launch.Players[slot]()
        if player then
            players[slot] = player
        end
    end

    local mode = CustomLobbyRules.AutoTeamMode(launch.GameOptions())
    local resolver, resolved = CustomLobbyRules.BuildSideResolver(mode, CustomLobbyScenarioDerivedModel.GetScenario())

    return CustomLobbyBalancer.ComputeBalance({
        players = players,
        lockedSlots = session.LockedSlots(),
        slotCount = session.SlotCount(),
        closedSlots = session.ClosedSlots(),
        sideResolver = resolver,
        resolved = resolved,
        labels = CustomLobbyRules.SideLabels(mode) or { "Team 1", "Team 2" },
    })
end

--- One player's row in a team column: "name · rating" (rating omitted for AI / unrated).
---@param player UICustomLobbyPlayer
---@return string
local function PlayerRow(player)
    local name = player.PlayerName or "?"
    if player.PL then
        return name .. "  ·  " .. tostring(player.PL)
    end
    return name
end

---@class UICustomLobbyBalancePreview : Group
---@field Trash TrashBag
---@field OnCloseCb fun()
---@field Result UICustomLobbyBalanceResult
---@field TitleArea Group
---@field ColumnAArea Group
---@field ColumnBArea Group
---@field StatusArea Group
---@field ActionArea Group
---@field Title Text
---@field HeaderA Text
---@field HeaderB Text
---@field ListA ItemList
---@field ListB ItemList
---@field Status Text
---@field ApplyButton Button
---@field CancelButton Button
---@field Ready boolean
local CustomLobbyBalancePreview = ClassUI(Group) {

    ---@param self UICustomLobbyBalancePreview
    ---@param parent Control
    ---@param options { onClose: fun() }
    __init = function(self, parent, options)
        Group.__init(self, parent, "CustomLobbyBalancePreview")

        self.Trash = TrashBag()
        self.OnCloseCb = options.onClose
        self.Ready = false

        -- compute the proposal up front (pure read of the current snapshot; no layout involved)
        self.Result = ComputeForCurrentLobby()

        self.TitleArea = CreateArea(self, "TitleArea", 'ffcc4040')
        self.ColumnAArea = CreateArea(self, "ColumnAArea", 'ff4060cc')
        self.ColumnBArea = CreateArea(self, "ColumnBArea", 'ff40cc60')
        self.StatusArea = CreateArea(self, "StatusArea", 'ffcc40cc')
        self.ActionArea = CreateArea(self, "ActionArea", 'ff808080')

        self.Title = UIUtil.CreateText(self.TitleArea, "Balance preview", 22, UIUtil.titleFont)
        self.Title:DisableHitTest()

        local labels = self.Result.labels or { "Team 1", "Team 2" }
        self.HeaderA = UIUtil.CreateText(self.ColumnAArea, labels[1], 14, UIUtil.titleFont)
        self.HeaderA:SetColor(HeaderColor)
        self.HeaderA:DisableHitTest()
        self.HeaderB = UIUtil.CreateText(self.ColumnBArea, labels[2], 14, UIUtil.titleFont)
        self.HeaderB:SetColor(HeaderColor)
        self.HeaderB:DisableHitTest()

        self.ListA = ItemList(self.ColumnAArea)
        self.ListA:SetFont(UIUtil.bodyFont, 14)
        self.ListA:SetColors(LabelColor, "00000000")
        self.ListA:DisableHitTest()
        self.ListB = ItemList(self.ColumnBArea)
        self.ListB:SetFont(UIUtil.bodyFont, 14)
        self.ListB:SetColors(LabelColor, "00000000")
        self.ListB:DisableHitTest()

        self.Status = UIUtil.CreateText(self.StatusArea, "", 14, UIUtil.bodyFont)
        self.Status:SetColor(LabelColor)
        self.Status:DisableHitTest()

        self.ApplyButton = UIUtil.CreateButtonWithDropshadow(self.ActionArea, '/BUTTON/medium/', "Apply")
        self.ApplyButton.OnClick = function()
            self:ApplyAndClose()
        end

        self.CancelButton = UIUtil.CreateButtonWithDropshadow(self.ActionArea, '/BUTTON/medium/', "<LOC _Cancel>Cancel")
        self.CancelButton.OnClick = function()
            self.OnCloseCb()
        end
    end,

    ---@param self UICustomLobbyBalancePreview
    __post_init = function(self)
        self.Width:Set(LayoutHelpers.ScaleNumber(DialogWidth))
        self.Height:Set(LayoutHelpers.ScaleNumber(DialogHeight))

        Layouter(self.TitleArea):AtLeftIn(self, Pad):AtRightIn(self, Pad):AtTopIn(self, Pad):Height(TitleHeight):End()
        Layouter(self.ActionArea):AtLeftIn(self, Pad):AtRightIn(self, Pad):AtBottomIn(self, Pad):Height(ActionHeight):End()
        Layouter(self.StatusArea):AtLeftIn(self, Pad):AtRightIn(self, Pad):AnchorToTop(self.ActionArea, Pad):Height(StatusHeight):End()

        -- two equal columns between the title and the status line
        local columnWidth = function() return (self.Width() - LayoutHelpers.ScaleNumber(2 * Pad + ColumnGap)) / 2 end
        Layouter(self.ColumnAArea)
            :AtLeftIn(self, Pad):Width(columnWidth)
            :AnchorToBottom(self.TitleArea, Pad):AnchorToTop(self.StatusArea, Pad)
            :End()
        Layouter(self.ColumnBArea)
            :AtRightIn(self, Pad):Width(columnWidth)
            :AnchorToBottom(self.TitleArea, Pad):AnchorToTop(self.StatusArea, Pad)
            :End()

        Layouter(self.Title):AtHorizontalCenterIn(self.TitleArea):AtVerticalCenterIn(self.TitleArea):End()

        Layouter(self.HeaderA):AtLeftIn(self.ColumnAArea):AtTopIn(self.ColumnAArea):End()
        Layouter(self.HeaderB):AtLeftIn(self.ColumnBArea):AtTopIn(self.ColumnBArea):End()

        Layouter(self.ListA):AtLeftIn(self.ColumnAArea):AnchorToBottom(self.HeaderA, 4):AtBottomIn(self.ColumnAArea):End()
        self.ListA.Right:Set(function() return self.ColumnAArea.Right() - LayoutHelpers.ScaleNumber(ScrollbarInset) end)
        Layouter(self.ListB):AtLeftIn(self.ColumnBArea):AnchorToBottom(self.HeaderB, 4):AtBottomIn(self.ColumnBArea):End()
        self.ListB.Right:Set(function() return self.ColumnBArea.Right() - LayoutHelpers.ScaleNumber(ScrollbarInset) end)

        Layouter(self.Status):AtLeftIn(self.StatusArea):AtVerticalCenterIn(self.StatusArea):End()

        Layouter(self.CancelButton):AtRightIn(self.ActionArea):AtVerticalCenterIn(self.ActionArea):End()
        Layouter(self.ApplyButton):AnchorToLeft(self.CancelButton, ButtonGap):AtVerticalCenterIn(self.ActionArea):End()
    end,

    --- Post-mount render (the opener calls this after Popup centres the dialog, so the lists read
    --- concrete geometry).
    ---@param self UICustomLobbyBalancePreview
    Initialize = function(self)
        self.Ready = true
        self:Render()
    end,

    --- Paints the two columns + status line from the computed proposal, and enables Apply only when
    --- there is something to apply.
    ---@param self UICustomLobbyBalancePreview
    Render = function(self)
        local result = self.Result
        local labels = result.labels or { "Team 1", "Team 2" }

        self.HeaderA:SetText(labels[1] .. "   " .. tostring(result.totals[1]))
        self.HeaderB:SetText(labels[2] .. "   " .. tostring(result.totals[2]))

        self.ListA:DeleteAllItems()
        for _, player in ipairs(result.sides[1]) do
            self.ListA:AddItem(PlayerRow(player))
        end
        self.ListB:DeleteAllItems()
        for _, player in ipairs(result.sides[2]) do
            self.ListB:AddItem(PlayerRow(player))
        end

        -- status line: the reason it can't balance, else the match quality (+ any odd one left out)
        local status
        if result.reason then
            status = result.reason
        elseif result.quality then
            status = "Match quality: " .. tostring(result.quality) .. "%"
        else
            status = "Match quality: —"
        end
        if result.unassigned then
            status = status .. "   ·   " .. (result.unassigned.PlayerName or "?") .. " stays put (odd count)"
        end
        self.Status:SetText(status)

        if result.feasible then
            self.ApplyButton:Enable()
        else
            self.ApplyButton:Disable()
        end
    end,

    --- Commits the proposed arrangement (host-authoritative) and closes.
    ---@param self UICustomLobbyBalancePreview
    ApplyAndClose = function(self)
        if self.Result.feasible then
            CustomLobbyController.RequestApplyBalance(self.Result.arrangement)
        end
        self.OnCloseCb()
    end,

    ---@param self UICustomLobbyBalancePreview
    OnDestroy = function(self)
        self.Trash:Destroy()
    end,
}

-------------------------------------------------------------------------------
--#region Singleton + open / close

---@type Popup | false
local Instance = false

--- Opens the balance preview over `parent` (host-only entry point — the slots header's balance button).
---@param parent? Control
function Open(parent)
    parent = parent or GetFrame(0)

    if Instance then
        Instance:Close()
    end

    local popup
    local content = CustomLobbyBalancePreview(parent, {
        onClose = function()
            if popup then
                popup:Close()
            end
        end,
    })

    popup = Popup(parent, content)
    local baseOnClosed = popup.OnClosed
    popup.OnClosed = function(self)
        baseOnClosed(self)
        Instance = false
    end
    Instance = popup

    -- Popup has mounted + centred the content; now it's safe to populate the lists
    content:Initialize()
end

--- Closes the dialog if open.
function Close()
    if Instance then
        Instance:Close()
        Instance = false
    end
end

--#endregion

-------------------------------------------------------------------------------
--#region Debugging

function __moduleinfo.OnDirty()
    Close()
end

--#endregion
