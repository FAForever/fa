
local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")

local Group = import("/lua/maui/group.lua").Group
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap

local ChatFactionBadge = import("/lua/ui/game/chat/ChatFactionBadge.lua").ChatFactionBadge

local UIMain = import("/lua/ui/uimain.lua")

local ChatModel = import("/lua/ui/game/chat/ChatModel.lua")
local ChatController = import("/lua/ui/game/chat/ChatController.lua")

local Layouter = LayoutHelpers.ReusedLayoutFor

--- Flip to `true` to overlay a semi-transparent coloured bitmap over the
--- control so its bounds are visible at runtime. Each chat interface uses a
--- distinct colour so overlapping controls can be told apart at a glance.
local Debug = false

---@class UIChatListEntry
---@field Text   Text
---@field BG     Bitmap
---@field Badge? ChatFactionBadge      # only present on player entries
---@field Target UIChatRecipient

-------------------------------------------------------------------------------
-- A popup recipient picker. Lists "All", "Allies", and one entry per
-- connected non-local human player (sourced from `GetSessionClients`, so
-- bots and disconnected players are excluded). Player rows show a small
-- faction + team-colour badge next to the name so the right recipient is
-- easy to spot. Clicking an entry calls `ChatController.SetRecipient` and
-- destroys the popup. Clicking anywhere outside also destroys the popup —
-- every open of the list rebuilds from fresh session state.

---@class UIChatListInterface : Group
---@field Entries UIChatListEntry[]
---@field LTBG    Bitmap
---@field RTBG    Bitmap
---@field RBBG    Bitmap
---@field RLBG    Bitmap
---@field LBG     Bitmap
---@field RBG     Bitmap
---@field TBG     Bitmap
---@field BBG     Bitmap
---@field DebugBG? Bitmap                # semi-transparent overlay shown when `Debug` is true
ChatListInterface = ClassUI(Group) {

    ---@param self UIChatListInterface
    ---@param parent Control
    __init = function(self, parent)
        Group.__init(self, parent, "ChatListInterface")
        self:DisableHitTest()

        -- Popups must sit above the chat window's inner content (line rows,
        -- edit area) to receive hover and click events. A plain +1 offset
        -- ties with the line rows, which default to ChatLinesInterface+1 —
        -- matching the list's default depth. +100 gives unambiguous headroom.
        LayoutHelpers.DepthOverParent(self, parent, 100)

        self.Entries = {}
        for _, def in ipairs(self:BuildTargetDefs()) do
            table.insert(self.Entries, self:CreateEntry(def))
        end

        self:CreateBorder()

        -- Close on any mouse click outside the popup.
        local function onOutsideClick() self:Destroy() end
        UIMain.AddOnMouseClickedFunc(onOutsideClick)

        self.OnDestroy = function(dself)
            UIMain.RemoveOnMouseClickedFunc(onOutsideClick)
            if dself._OnClosed then
                local cb = dself._OnClosed
                dself._OnClosed = nil
                cb()
            end
        end
    end,

    --- Builds the list of selectable targets: All, Allies, then one entry
    --- per connected human player. `GetSessionClients` naturally excludes
    --- bots (they are not session clients); we additionally skip the local
    --- client (you can't privately message yourself) and any disconnected
    --- player. A client's army is found by matching nickname — the target
    --- stays an army ID so the send path continues to work unchanged.
    ---@param self UIChatListInterface
    ---@return table[]
    BuildTargetDefs = function(self)
        local defs = {
            { Nickname = "All",    Target = ChatModel.RecipientAll },
            { Nickname = "Allies", Target = ChatModel.RecipientAllies },
        }

        local armies = GetArmiesTable().armiesTable
        for _, client in GetSessionClients() do
            if client.connected and not client['local'] then
                for armyID, armyData in armies do
                    if not armyData.civilian and armyData.nickname == client.name then
                        table.insert(defs, {
                            Nickname = client.name,
                            Target   = armyID,
                            Faction  = armyData.faction,
                            Color    = armyData.color,
                        })
                        break
                    end
                end
            end
        end

        return defs
    end,

    --- Creates a single row: text, highlight bitmap, optional faction badge,
    --- and a hover/click handler that dispatches to `ChatController` and
    --- closes the popup. Player rows carry a badge; All / Allies rows don't.
    ---@param self UIChatListInterface
    ---@param def table
    ---@return UIChatListEntry
    CreateEntry = function(self, def)
        local entry = {
            Target = def.Target,
            Text   = UIUtil.CreateText(self, def.Nickname, 12, "Arial"),
        }
        entry.Text:SetColor('ffffffff')
        entry.Text:DisableHitTest()

        entry.BG = Bitmap(entry.Text)
        entry.BG:SetSolidColor('ff000000')

        if def.Color then
            entry.Badge = ChatFactionBadge(self, def.Faction, def.Color)
        end

        -- Capture target in a local so each entry closes over its own value.
        local target = def.Target
        entry.BG.HandleEvent = function(bg, event)
            ChatController.NotifyActivity()
            if event.Type == 'MouseEnter' then
                bg:SetSolidColor('ff666666')
            elseif event.Type == 'MouseExit' then
                bg:SetSolidColor('ff000000')
            elseif event.Type == 'ButtonPress' then
                ChatController.SetRecipient(target)
                self:Destroy()
            end
        end

        return entry
    end,

    --- Creates the eight decorative border bitmaps that hug the outside of
    --- the popup. Layout is applied in `LayoutBorder` from `__post_init`.
    ---@param self UIChatListInterface
    CreateBorder = function(self)
        local function makeBitmap(file)
            local bmp = Bitmap(self, UIUtil.UIFile(file))
            bmp:DisableHitTest()
            return bmp
        end

        self.LTBG = makeBitmap('/game/chat_brd/drop-box_brd_ul.dds')
        self.RTBG = makeBitmap('/game/chat_brd/drop-box_brd_ur.dds')
        self.RBBG = makeBitmap('/game/chat_brd/drop-box_brd_lr.dds')
        self.RLBG = makeBitmap('/game/chat_brd/drop-box_brd_ll.dds')
        self.LBG  = makeBitmap('/game/chat_brd/drop-box_brd_vert_l.dds')
        self.RBG  = makeBitmap('/game/chat_brd/drop-box_brd_vert_r.dds')
        self.TBG  = makeBitmap('/game/chat_brd/drop-box_brd_horz_um.dds')
        self.BBG  = makeBitmap('/game/chat_brd/drop-box_brd_lm.dds')
    end,

    ---@param self UIChatListInterface
    ---@param parent Control
    __post_init = function(self, parent)
        -- Size self to fit the widest row and the stacked heights.
        local maxWidth = 0
        local totalHeight = 0
        for _, entry in ipairs(self.Entries) do
            local w = entry.Text.Width()
            if w > maxWidth then maxWidth = w end
            totalHeight = totalHeight + entry.Text.Height()
        end

        Layouter(self)
            :Width(maxWidth + 40)
            :Height(totalHeight)
            :End()

        -- Left indent reserves room for the faction badge on player rows
        -- and keeps All / Allies text aligned with the player names.
        local textIndent = 20

        -- Stack entries bottom-up: first at the bottom, each subsequent
        -- entry above the previous.
        for i, entry in ipairs(self.Entries) do
            local below = i > 1 and self.Entries[i - 1] or nil
            self:LayoutEntry(entry, below, textIndent)
        end

        self:LayoutBorder()

        if Debug then
            self.DebugBG = Bitmap(self)
            self.DebugBG:SetSolidColor('40ffff40')
            self.DebugBG:DisableHitTest()
            Layouter(self.DebugBG):Fill(self):Over(self, 100):End()
        end
    end,

    --- Lays out one row: the text anchored above `below` (or at the bottom
    --- if `below` is nil), an optional faction badge in the indent column,
    --- and a highlight bitmap whose bounds track the text row.
    ---@param self UIChatListInterface
    ---@param entry UIChatListEntry
    ---@param below UIChatListEntry | nil
    ---@param textIndent number
    LayoutEntry = function(self, entry, below, textIndent)
        if below then
            Layouter(entry.Text)
                :Above(below.Text)
                :AtLeftIn(self, textIndent)
                :Over(self, 1)
                :End()
        else
            Layouter(entry.Text)
                :AtBottomIn(self)
                :AtLeftIn(self, textIndent)
                :Over(self, 1)
                :End()
        end

        -- Badge (player rows only) sits in the reserved indent, centred
        -- vertically on the text row.
        if entry.Badge then
            Layouter(entry.Badge)
                :AtLeftIn(self, 3)
                :AtVerticalCenterIn(entry.Text)
                :Over(self, 2)
                :End()
        end

        -- The highlight bar spans the full row (including the badge area)
        -- and sits behind everything in the depth order. Direct LazyVar
        -- `:SetFunction` calls match the original `chat.lua` pattern and
        -- avoid Layouter's reused-state quirks. The pixel offsets need
        -- explicit scaling — the closures bypass Layouter's auto-scale.
        local text = entry.Text
        local bgInsetLeft = LayoutHelpers.ScaleNumber(6)
        local bgInsetWidth = LayoutHelpers.ScaleNumber(8)
        local onePxScaled = LayoutHelpers.ScaleNumber(1)
        ---@diagnostic disable: undefined-field
        entry.BG.Depth:SetFunction(function() return text.Depth() - 1 end)
        entry.BG.Left:SetFunction(function() return self.Left() - bgInsetLeft end)
        entry.BG.Top:SetFunction(function() return text.Top() - onePxScaled end)
        entry.BG.Width:SetFunction(function() return self.Width() + bgInsetWidth end)
        entry.BG.Bottom:SetFunction(function() return text.Bottom() + onePxScaled end)
        ---@diagnostic enable: undefined-field
    end,

    --- Pins the eight decorative border bitmaps to the outside of self.
    ---@param self UIChatListInterface
    LayoutBorder = function(self)
        Layouter(self.LTBG):Right(self.Left):Bottom(self.Top):End()
        Layouter(self.RTBG):Left(self.Right):Bottom(self.Top):End()
        Layouter(self.RBBG):Left(self.Right):Top(self.Bottom):End()
        Layouter(self.RLBG):Right(self.Left):Top(self.Bottom):End()
        Layouter(self.LBG):Right(self.Left):Top(self.Top):Bottom(self.Bottom):End()
        Layouter(self.RBG):Left(self.Right):Top(self.Top):Bottom(self.Bottom):End()
        Layouter(self.TBG):Left(self.Left):Right(self.Right):Bottom(self.Top):End()
        Layouter(self.BBG):Left(self.Left):Right(self.Right):Top(self.Bottom):End()
    end,

    --- Registers a callback that fires when the popup closes for any reason.
    ---@param self UIChatListInterface
    ---@param callback function
    SetOnClosed = function(self, callback)
        self._OnClosed = callback
    end,
}
