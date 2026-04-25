
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")

local Group = import("/lua/maui/group.lua").Group
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap

local ChatLineInterface = import("/lua/ui/game/chat/ChatLineInterface.lua").ChatLineInterface

local ChatModel = import("/lua/ui/game/chat/ChatModel.lua")
local ChatConfigModel = import("/lua/ui/game/chat/config/ChatConfigModel.lua")
local ChatUtils = import("/lua/ui/game/chat/ChatUtils.lua")

local LazyVarDerive = import("/lua/lazyvar.lua").Derive

local Layouter = LayoutHelpers.ReusedLayoutFor

--- Flip to `true` to overlay a semi-transparent coloured bitmap over the
--- control so its bounds are visible at runtime. Each chat interface uses a
--- distinct colour so overlapping controls can be told apart at a glance.
local Debug = false

--- Cap on how many feed rows are visible at once. Older rows above this
--- are dropped immediately when a new row pushes in — feed mode is for
--- glanceable awareness, not full scrollback.
local MaxFeedRows = 8

--- Length of the alpha fade-out near the end of a row's lifetime, in
--- seconds. Capped to half the configured `fade_time` so very short
--- timeouts still get a visible fade rather than a hard pop.
local FadeOutDuration = 2

--- Base alpha (0..1) of the per-row readability strip when the
--- `feed_background` option is on. Multiplied per-frame by `win_alpha`
--- and the row's fade progress, so the BG dims with the window opacity
--- and disappears together with the line as the row ages out.
local FeedBackgroundAlpha = 0.5

-------------------------------------------------------------------------------
-- A separate "feed" view of the chat history that surfaces messages while
-- the main chat window is hidden. Mounted as a sibling of the chat window
-- (so the window's `Show`/`Hide` cascade can't reach us), but pinned to the
-- window's line area via LazyVar bindings — drag/resize the chat window and
-- the feed tracks for free.
--
-- The feed is fully model-driven:
--   * `ChatModel.History` — incoming entries are appended as feed rows.
--   * `ChatModel.WindowVisible` — feed visible iff window hidden + we have rows.
-- Each row carries its own age timer ticked by `OnFrame`; rows past
-- `fade_time` destroy themselves. Pin (chrome-side toggle that suspends
-- the per-row fade) is the remaining piece that hasn't been wired yet.

---@class UIChatFeedRow
---@field Line  UIChatLineInterface   # exactly one wrapped chunk: header on the entry's first row, continuation on the rest
---@field BG    Bitmap                # solid-colour readability strip behind `Line`; only paints when `feed_background` is on
---@field Entry UIChatEntry           # the source message this line belongs to
---@field Time  number                # seconds since this row was added; each row ages and expires independently

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

        -- Seed the high-water mark to whatever's already in history so the
        -- initial fire of `HistoryObserver` doesn't replay every existing
        -- entry as a fresh feed line.
        self.LastHistoryLength = table.getn(model.History())

        -- Window visibility flips us in / out of feed mode. Opening the
        -- window throws away every active feed row — anything the user
        -- wanted to read is now in the main view, and a stale fade
        -- countdown lingering across an open/close cycle would just clutter
        -- the feed with content the user already saw. `UpdateVisibility`
        -- then hides us (rows == 0) and stops the frame ticker.
        self.WindowVisibleObserver = self.Trash:Add(
            LazyVarDerive(model.WindowVisible, function(lv)
                if lv() then
                    self:ClearAll()
                end
                self:UpdateVisibility()
            end)
        )

        -- New entries → push to the feed only while the window is hidden.
        -- Entries received with the window open are the user's to read in
        -- the main view; we still bump `LastHistoryLength` either way so
        -- they aren't replayed when the window later closes.
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
            -- One-way LazyVar bind to the chat window's line area. Drag /
            -- resize the chat window with the feed visible (during a
            -- transition, etc.) and the feed tracks for free; no observer
            -- glue, no model write — the dependency graph does it.
            ---@diagnostic disable-next-line: param-type-mismatch
            Layouter(self)
                :Left(self.Window.ChatLinesInterface.Left)
                :Right(self.Window.ChatLinesInterface.Right)
                :Top(self.Window.ChatLinesInterface.Top)
                :Bottom(self.Window.ChatLinesInterface.Bottom)
                :End()
        else
            -- Standalone debug fallback: anchor near the bottom-left of the
            -- frame so `Toggle()` from a dev hotkey still shows somewhere.
            Layouter(self)
                :AtLeftBottomIn(parent, 8, 60)
                :Width(420)
                :Height(160)
                :End()
        end

        -- Start hidden — `UpdateVisibility` reveals us when both conditions
        -- (window hidden + rows > 0) are met.
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

    --- Called whenever `ChatModel.History` fires dirty. Pushes entries that
    --- arrived since the last call onto the feed — but only while the chat
    --- window is hidden. Entries received while the window is open are the
    --- user's to read in the main view, not surfaced again on next close.
    --- We still bump `LastHistoryLength` either way so we never replay
    --- already-seen entries when the window later closes.
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

    --- Appends one feed row per wrapped chunk in `entry`. Each row carries
    --- its own `Time`, so capping and expiry act on individual lines
    --- rather than entry-blocks — when the cap kicks in mid-stream, only
    --- the single oldest row drops out instead of the entire block of
    --- chunks belonging to one wrapped entry.
    ---
    --- We force the wrap before reading `entry.WrappedText`. Both views
    --- observe the same `model.History` LazyVar, but `used_by` iteration
    --- order is unspecified — if we fire before the chat-lines observer
    --- the cache is empty and we'd degenerate to a single-line fallback.
    --- We borrow the chat panel's measure-line because it shares our row
    --- width exactly (LazyVar bind), so the wrap is valid here.
    ---@param self UIChatFeedInterface
    ---@param entry UIChatEntry
    AppendRow = function(self, entry)
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
            -- Per-chunk cap: a wrapped message pushes one row in for one
            -- row out, keeping the visible total at exactly `MaxFeedRows`.
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
            line:SetAlpha(1.0, true)

            -- Readability strip behind the row. Solid-black at full alpha;
            -- per-frame `SetAlpha` modulates the actual opacity by the
            -- window's `win_alpha`, the row's fade progress, and the
            -- `feed_background` toggle (off → alpha 0). Lives on the feed
            -- group (not the line) so we can drive its alpha independently
            -- and skip the line's text/icon depth ordering.
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

    --- Pins each row from the bottom up. The bottom-most row anchors to
    --- `AtBottomIn(self)`; every other row stacks `Above` the row that
    --- comes after it in `Rows`. Because `AppendRow` inserts an entry's
    --- chunks in reading order (header first, continuations after), the
    --- header still sits at the top of its block and continuations below.
    ---@param self UIChatFeedInterface
    LayoutRows = function(self)
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

    --- Removes the single oldest row from the head of `Rows`. With each
    --- row tracking its own `Time`, capping no longer cascades through a
    --- wrapped entry's chunks — a header at the head of the queue gets
    --- popped on its own, and its continuations stay until they age out
    --- on their own timers.
    ---@param self UIChatFeedInterface
    RemoveOldest = function(self)
        local oldest = self.Rows[1]
        if oldest then
            oldest.Line:Destroy()
            oldest.BG:Destroy()
            table.remove(self.Rows, 1)
        end
    end,

    --- Tears down every active row. Called when the user opens the chat
    --- window (non-persist semantics) and from `OnDestroy`.
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

    --- Computes whether we should currently be on screen and ticking.
    --- Feed visible iff: chat window is hidden AND we have at least one
    --- active row. `SetNeedsFrameUpdate` toggles in lockstep so we don't
    --- waste frame ticks while idle.
    ---@param self UIChatFeedInterface
    UpdateVisibility = function(self)
        local windowVisible = ChatModel.GetSingleton().WindowVisible()
        if not windowVisible and table.getn(self.Rows) > 0 then
            self:Show()
            self:SetNeedsFrameUpdate(true)
        else
            self:Hide()
            self:SetNeedsFrameUpdate(false)
        end
    end,

    --- Per-frame timer pass. Walks each row, advances its `Time`, applies
    --- alpha (per-row fade only for the line so the text stays crisp and
    --- readable regardless of the window's opacity setting; window-
    --- opacity × per-row fade × base intensity for the BG strip so the
    --- backdrop dims with the user's preference), and destroys the row
    --- once past `fade_time`. Each row ages independently — wrapped
    --- entries arrive at the same instant so their chunks usually expire
    --- together by virtue of starting from the same `Time = 0`, but the
    --- cap or a future selective drop can take individual rows without
    --- disturbing siblings. Re-evaluates visibility so the feed self-
    --- hides when the last row expires.
    ---@param self UIChatFeedInterface
    ---@param delta number   # seconds since the last frame
    OnFrame = function(self, delta)
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

    --- Empties our trash bag (destroying every derived observer) and
    --- destroys any remaining feed rows.
    ---@param self UIChatFeedInterface
    OnDestroy = function(self)
        self:ClearAll()
        self.Trash:Destroy()
    end,
}

-------------------------------------------------------------------------------
--#region Debugging

--- Owned and rebuilt by `ChatInterface`; touching the chat module after a
--- save here triggers the full chat-tree rebuild that picks up our changes.
function __moduleinfo.OnDirty()
    import(__moduleinfo.name)
end

--#endregion
