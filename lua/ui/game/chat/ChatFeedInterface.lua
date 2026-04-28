
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")

local Group = import("/lua/maui/group.lua").Group
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap

local ChatLineInterface = import("/lua/ui/game/chat/ChatLineInterface.lua").ChatLineInterface

local ChatModel = import("/lua/ui/game/chat/ChatModel.lua")
local ChatConfigModel = import("/lua/ui/game/chat/config/ChatConfigModel.lua")
local ChatUtils = import("/lua/ui/game/chat/ChatUtils.lua")

local LazyVarDerive = import("/lua/lazyvar.lua").Derive

local Layouter = LayoutHelpers.ReusedLayoutFor

local Debug = false

local MaxFeedRows = 8

--- Capped to half `fade_time` so very short timeouts still fade rather
--- than pop.
local FadeOutDuration = 2

--- Base alpha for the readability strip when `feed_background` is on;
--- multiplied per-frame by `win_alpha` and the row's fade progress.
local FeedBackgroundAlpha = 0.5

-------------------------------------------------------------------------------
-- Feed view of the chat history shown while the main chat window is hidden.
-- Mounted as a sibling of the chat window (so its `Show`/`Hide` cascade
-- can't reach us), but pinned to the window's line area via LazyVars.
-- Each row carries its own age timer; rows past `fade_time` destroy
-- themselves.

--- One feed entry: a wrapped line, its readability strip, the source entry, and an independent age timer.
---@class UIChatFeedRow
---@field Line  UIChatLineInterface   # exactly one wrapped chunk: header on the entry's first row, continuation on the rest
---@field BG    Bitmap                # solid-colour readability strip behind `Line`; only paints when `feed_background` is on
---@field Entry UIChatEntry           # the source message this line belongs to
---@field Time  number                # seconds since this row was added; each row ages and expires independently

--- Sibling-of-the-window feed shown while the chat window is hidden; lines fade and self-destruct on age.
---@class UIChatFeedInterface : Group
---@field Trash                 TrashBag                            # owns every subscription-LazyVar we create
---@field Window                UIChatInterface | nil               # chat window we anchor to; nil for standalone debug
---@field Rows                  UIChatFeedRow[]                     # active feed rows, oldest first, newest last
---@field LastHistoryLength     number                              # high-water mark so we only feed in entries we haven't already seen
---@field WindowVisibleObserver LazyVar<boolean>                    # derived from ChatModel.WindowVisible
---@field HistoryObserver       LazyVar<UIChatEntry[]>              # derived from ChatModel.History
---@field DebugBG?              Bitmap                              # semi-transparent overlay shown when `Debug` is true
ChatFeedInterface = ClassUI(Group) {

    ---@param self UIChatFeedInterface
    ---@param parent Control
    ---@param window UIChatInterface | nil
    __init = function(self, parent, window)
        Group.__init(self, parent, "ChatFeedInterface")
        self:DisableHitTest()

        self.Trash = TrashBag()
        self.Window = window
        self.Rows = {}

        local model = ChatModel.GetSingleton()

        -- Seed so the initial `HistoryObserver` fire doesn't replay every
        -- existing entry as a fresh feed line.
        self.LastHistoryLength = table.getn(model.History())

        -- Opening the window discards active feed rows: anything worth
        -- reading is now in the main view, and a stale fade countdown
        -- across an open/close cycle would clutter content the user
        -- already saw.
        self.WindowVisibleObserver = self.Trash:Add(
            LazyVarDerive(model.WindowVisible, function(lv)
                if lv() then
                    self:ClearAll()
                end
                self:UpdateVisibility()
            end)
        )

        -- Push to feed only while the window is hidden; bump
        -- `LastHistoryLength` either way so we don't replay later.
        self.HistoryObserver = self.Trash:Add(
            LazyVarDerive(model.History, function(lv)
                self:OnHistoryChanged(lv())
            end)
        )
    end,

    ---@param self UIChatFeedInterface
    ---@param parent Control
    ---@param window UIChatInterface | nil
    __post_init = function(self, parent, window)
        if self.Window then
            -- One-way LazyVar bind to the chat window's line area; drag /
            -- resize tracks for free through the dependency graph.
            ---@diagnostic disable-next-line: param-type-mismatch
            Layouter(self)
                :Left(self.Window.ChatLinesInterface.Left)
                :Right(self.Window.ChatLinesInterface.Right)
                :Top(self.Window.ChatLinesInterface.Top)
                :Bottom(self.Window.ChatLinesInterface.Bottom)
                :End()
        else
            -- Standalone debug fallback for dev-hotkey `Toggle()`.
            Layouter(self)
                :AtLeftBottomIn(parent, 8, 60)
                :Width(420)
                :Height(160)
                :End()
        end

        self:Hide()
        self:UpdateVisibility()

        if Debug then
            self.DebugBG = Bitmap(self)
            self.DebugBG:SetSolidColor('40c040c0')
            self.DebugBG:DisableHitTest()
            Layouter(self.DebugBG):Fill(self):Over(self, 100):End()
        end
    end,

    ---------------------------------------------------------------------------
    -- History handling
    ---------------------------------------------------------------------------

    --- Reacts to history mutations: feeds in new entries while the chat window is hidden.
    ---@param self UIChatFeedInterface
    ---@param history UIChatEntry[]
    OnHistoryChanged = function(self, history)
        local newCount = table.getn(history)
        if not ChatModel.GetSingleton().WindowVisible() then
            for i = self.LastHistoryLength + 1, newCount do
                self:AppendRow(history[i])
            end
        end
        self.LastHistoryLength = newCount
    end,

    --- Appends one feed row per wrapped chunk of the entry.
    ---@param self UIChatFeedInterface
    ---@param entry UIChatEntry
    AppendRow = function(self, entry)
        -- Per-row `Time` means capping drops only the single oldest row,
        -- not an entry's whole block of continuations.
        --
        -- Forces the wrap before reading `entry.WrappedText` because both
        -- views observe `model.History` and `used_by` iteration order is
        -- unspecified. If we fire before the chat-lines observer the
        -- cache is empty. We borrow the chat panel's measure-line because
        -- it shares our row width by LazyVar bind.
        if not entry then return end

        if not entry.WrappedText and self.Window then
            ChatUtils.WrapEntry(entry, self.Window.ChatLinesInterface.ChatLineInterfaces[1])
        end

        local wrapped = entry.WrappedText
        if not wrapped or table.getn(wrapped) == 0 then
            wrapped = { entry.Text or '' }
        end

        local fontSize = ChatConfigModel.GetOptions().font_size or 14

        for i, chunk in ipairs(wrapped) do
            if table.getn(self.Rows) >= MaxFeedRows then
                self:RemoveOldest()
            end

            local line = ChatLineInterface(self)
            line:SetFontSize(fontSize)
            if i == 1 then
                line:SetHeader(entry, chunk)
            else
                line:SetContinuation(entry, chunk)
            end
            -- `SetHeader` calls `EnableHitTest` on the cam icon when the
            -- entry has a camera/location; disable hit-test last so
            -- nothing on the row swallows clicks meant for worldview.
            line:DisableHitTest(true)
            line:SetAlpha(1.0, true)

            -- Readability strip behind the row. Lives on the feed group
            -- (not the line) so we can drive its alpha independently of
            -- the line's text/icon depth ordering.
            local bg = Bitmap(self)
            bg:SetSolidColor('ff000000')
            bg:DisableHitTest()
            Layouter(bg):Fill(line):End()
            LayoutHelpers.DepthUnderParent(bg, line, 1)

            table.insert(self.Rows, { Line = line, BG = bg, Entry = entry, Time = 0 })
        end

        self:LayoutRows()
        self:UpdateVisibility()
    end,

    --- Lays out feed rows pinned from the bottom up.
    ---@param self UIChatFeedInterface
    LayoutRows = function(self)
        -- Header rows naturally end up at the top of their wrapped block
        -- because AppendRow inserts in reading order.
        local count = table.getn(self.Rows)
        for i = count, 1, -1 do
            local row = self.Rows[i]
            if i == count then
                Layouter(row.Line)
                    :AtBottomIn(self)
                    :AtLeftIn(self)
                    :AtRightIn(self)
                    :End()
            else
                Layouter(row.Line)
                    :Above(self.Rows[i + 1].Line)
                    :AtLeftIn(self)
                    :AtRightIn(self)
                    :End()
            end
        end
    end,

    --- Drops the oldest row to make room for a new one.
    ---@param self UIChatFeedInterface
    RemoveOldest = function(self)
        local oldest = self.Rows[1]
        if oldest then
            oldest.Line:Destroy()
            oldest.BG:Destroy()
            table.remove(self.Rows, 1)
        end
    end,

    --- Destroys every active feed row.
    ---@param self UIChatFeedInterface
    ClearAll = function(self)
        for _, row in ipairs(self.Rows) do
            row.Line:Destroy()
            row.BG:Destroy()
        end
        self.Rows = {}
    end,

    ---------------------------------------------------------------------------
    -- Visibility / lifecycle
    ---------------------------------------------------------------------------

    --- Updates visibility: visible iff the window is hidden AND we have at least one row.
    ---@param self UIChatFeedInterface
    UpdateVisibility = function(self)
        -- `SetNeedsFrameUpdate` toggles in lockstep so we don't tick idle.
        local windowVisible = ChatModel.GetSingleton().WindowVisible()
        if not windowVisible and table.getn(self.Rows) > 0 then
            self:Show()
            self:SetNeedsFrameUpdate(true)
        else
            self:Hide()
            self:SetNeedsFrameUpdate(false)
        end
    end,

    --- Per-frame: ages each row, fades the line text and BG strip,
    --- and destroys rows past `fade_time`.
    ---@param self UIChatFeedInterface
    ---@param delta number
    OnFrame = function(self, delta)
        -- Line text fades on the per-row fade only (it stays crisp
        -- regardless of `win_alpha`). BG strip alpha is modulated by
        -- `win_alpha` * fade * base intensity.
        local options  = ChatConfigModel.GetOptions()
        local fadeTime = options.fade_time or 15
        local winAlpha = options.win_alpha or 1.0
        local fadeOut  = math.min(FadeOutDuration, fadeTime / 2)
        local fadeStart = fadeTime - fadeOut
        local bgAlpha = options.feed_background and FeedBackgroundAlpha or 0

        local i = 1
        while i <= table.getn(self.Rows) do
            local row = self.Rows[i]
            row.Time = row.Time + delta
            if row.Time >= fadeTime then
                row.Line:Destroy()
                row.BG:Destroy()
                table.remove(self.Rows, i)
            else
                local fade = 1.0
                if row.Time > fadeStart then
                    fade = 1.0 - (row.Time - fadeStart) / fadeOut
                end
                row.Line:SetAlpha(fade, true)
                row.BG:SetAlpha(winAlpha * fade * bgAlpha, true)
                i = i + 1
            end
        end

        self:UpdateVisibility()
    end,

    --- Destroys every row plus the derived observers.
    ---@param self UIChatFeedInterface
    OnDestroy = function(self)
        self:ClearAll()
        self.Trash:Destroy()
    end,
}

-------------------------------------------------------------------------------
--#region Debugging

--- Owned by `ChatInterface`; re-importing the chat module triggers the
--- full chat-tree rebuild.
function __moduleinfo.OnDirty()
    import(__moduleinfo.name)
end

--#endregion
