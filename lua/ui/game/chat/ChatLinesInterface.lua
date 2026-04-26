
local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")

local Group = import("/lua/maui/group.lua").Group
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap

local ChatLineInterface = import("/lua/ui/game/chat/ChatLineInterface.lua").ChatLineInterface

local ChatModel = import("/lua/ui/game/chat/ChatModel.lua")
local ChatController = import("/lua/ui/game/chat/ChatController.lua")
local ChatConfigModel = import("/lua/ui/game/chat/config/ChatConfigModel.lua")
local ChatUtils = import("/lua/ui/game/chat/ChatUtils.lua")

local LazyVarDerive = import("/lua/lazyvar.lua").Derive

local Layouter = LayoutHelpers.ReusedLayoutFor

--- Flip to `true` to overlay a semi-transparent coloured bitmap over the
--- control so its bounds are visible at runtime. Each chat interface uses a
--- distinct colour so overlapping controls can be told apart at a glance.
local Debug = false

-- Reserve space on the right of the wrapper for the scrollbar widget.
-- Anything wider than the scrollbar bitmap (~17px) works; 20px gives a tiny
-- breathing margin between the line text and the scrollbar.
local ScrollbarReserve = 32

-------------------------------------------------------------------------------
-- A self-contained chat-lines panel: outer wrapper, inner pool of line rows,
-- and the vertical scrollbar — packaged so a parent can drop it in and size
-- it as one unit. Lifted out of `ChatInterface.lua` so the chat window only
-- has to lay this out alongside the edit area.
--
-- This class owns four related concerns that used to live on the window:
--
--   1. Pool sizing       (`RebuildPool`)            — line count follows
--                                                     the container height.
--   2. Text wrapping     (`WrapEntry` / `RewrapAll`) — wraps message text to
--                                                     the current row width;
--                                                     results cached on the
--                                                     entry itself.
--   3. Scroll container  (`GetScrollValues`, …)     — virtual size = total
--                                                     wrapped-line count
--                                                     across *valid* entries.
--   4. Visibility mapping (`CalcVisible`)            — projects the scroll
--                                                     position onto the pool.
--
-- Filtering currently gates on `ChatConfigModel.GetOptions().muted`;
-- camera-link filtering is still TODO.
--
-- Click hooks (`OnNameClicked`, `OnCameraClicked`) are overridable instance
-- fields with sensible defaults — name click is a no-op (window-level
-- concern), camera click jumps the world camera to the entry's hint.

---@class UIChatLinesInterface : Group
---@field Trash             TrashBag                            # owns every subscription-LazyVar we create
---@field Pool              Group                               # inner group hosting the line rows
---@field Scrollbar         Scrollbar
---@field ChatLineInterfaces UIChatLineInterface[]
---@field ScrollTop         number    # 1-based virtual position of the top visible row
---@field VirtualSize       number    # total wrapped lines across valid entries
---@field HistoryObserver   LazyVar<UIChatEntry[]>
---@field OptionsObserver   LazyVar<UIChatOptions>
---@field LineNameClicked   fun(line: UIChatLineInterface, entry: UIChatEntry)   # shared row-name click handler; captures `self` so pool lines don't allocate per-row closures
---@field LineCameraClicked fun(line: UIChatLineInterface, entry: UIChatEntry)   # shared cam-icon click handler; captures `self` for the same reason
---@field OnNameClicked     fun(entry: UIChatEntry)                              # overridable: replace to react to a sender-name click
---@field OnCameraClicked   fun(entry: UIChatEntry)                              # overridable: replace to override camera-link behaviour
---@field DebugBG?          Bitmap                                              # semi-transparent overlay shown when `Debug` is true
ChatLinesInterface = ClassUI(Group) {

    ---@param self UIChatLinesInterface
    ---@param parent Control
    __init = function(self, parent)
        Group.__init(self, parent, "ChatLinesInterface")

        self.Trash = TrashBag()
        self.ChatLineInterfaces = {}
        self.ScrollTop = 1
        self.VirtualSize = 0

        -- Pool holds the actual line rows. Sized in `__post_init` to stop
        -- short of our right edge so the scrollbar (anchored to Pool's
        -- right) sits inside our footprint.
        self.Pool = Group(self, "ChatLinesPool")

        -- Forward the scrollable interface from the Pool (which the
        -- scrollbar binds to via `Scrollbar:SetScrollable`) up to `self`,
        -- where the state lives.
        self.Pool.GetScrollValues = function(_, axis) return self:GetScrollValues(axis) end
        self.Pool.ScrollLines     = function(_, axis, delta) self:ScrollLines(axis, delta) end
        self.Pool.ScrollPages     = function(_, axis, delta) self:ScrollPages(axis, delta) end
        self.Pool.ScrollSetTop    = function(_, axis, top) self:ScrollSetTop(axis, top) end
        self.Pool.IsScrollable    = function(_, axis) return self:IsScrollable(axis) end

        -- Default click hooks. Replaced on the instance by callers that
        -- want different behaviour (e.g. the chat window re-points
        -- `OnNameClicked` to set the recipient + re-focus the edit box).
        self.OnNameClicked = function(entry) end
        self.OnCameraClicked = function(entry)
            local cam = GetCamera('WorldCamera')
            if entry.Location then
                if entry.Location.Area then
                    cam:MoveToRegion(entry.Location.Area, 0.5)
                elseif entry.Location.Position then
                    local settings = cam:SaveSettings()
                    settings.Focus = entry.Location.Position
                    cam:RestoreSettings(settings)
                end
            elseif entry.Camera then
                cam:RestoreSettings(entry.Camera)
            end
        end

        -- Built once per panel so every pool line can point its
        -- `OnNameClicked` / `OnCameraClicked` at the same reference — pool
        -- growth never allocates a per-row closure. Each forwarder reads
        -- `self.OnNameClicked` (etc.) on every invocation, so callers can
        -- replace the public hook at any time without re-wiring the rows.
        self.LineNameClicked   = function(_, entry) self.OnNameClicked(entry) end
        self.LineCameraClicked = function(_, entry) self.OnCameraClicked(entry) end

        -- History → wrap new entries, refresh size, stick to bottom. The
        -- initial firing happens before `__post_init` so the wrap call has
        -- no pool to measure against; that's fine — `RewrapAll` runs once
        -- the pool exists.
        local model = ChatModel.GetSingleton()
        self.HistoryObserver = self.Trash:Add(
            LazyVarDerive(
                model.History,
                function(lv)
                    self:OnHistoryChanged(lv())
                end
            )
        )

        -- `OptionsObserver` is wired in `__post_init`, not here — its
        -- initial fire triggers `ApplyOptions → RebuildPool`, which reads
        -- `self.ChatLineInterfaces[1].Height()` and so requires the pool layout to
        -- already be in place.
    end,

    ---@param self UIChatLinesInterface
    ---@param parent Control
    __post_init = function(self, parent)
        -- Pool fills the wrapper but stops `ScrollbarReserve` short of the
        -- right edge so the scrollbar (which the engine anchors to Pool's
        -- right) lands inside our footprint. These bindings are reactive —
        -- they don't evaluate to concrete pixels until the parent has laid
        -- us out, which is why pool / wrap / scroll work happens in
        -- `Initialize` below rather than here.
        Layouter(self.Pool)
            :AtLeftTopIn(self)
            :AtRightIn(self, ScrollbarReserve)
            :AtBottomIn(self)
            :End()

        -- `CreateVertScrollbarFor` calls `Scrollbar:SetScrollable(attachto)`
        -- so the scrollable methods have to live on `Pool` — see the
        -- forwarding stubs in `__init`. Anchoring the scrollbar is also
        -- reactive (it tracks `Pool.Right`), so this is safe pre-layout.
        self.Scrollbar = UIUtil.CreateVertScrollbarFor(self.Pool)
        self.Scrollbar:SetParent(self)

        if Debug then
            self.DebugBG = Bitmap(self)
            self.DebugBG:SetSolidColor('4040ff40')
            self.DebugBG:DisableHitTest()
            Layouter(self.DebugBG):Fill(self):Over(self, 100):End()
        end
    end,

    --- Called by the parent once it has laid out the lines panel. The
    --- initial `RebuildPool` reads `Pool.Height()` — which evaluates to
    --- zero until our outer rect is bound to something concrete — so the
    --- pool / rewrap / scroll work has to wait until the parent positions
    --- us. Wiring `OptionsObserver` here defers its initial fire (which
    --- calls `ApplyOptions → RebuildPool`) for the same reason.
    ---@param self UIChatLinesInterface
    Initialize = function(self)
        self:RebuildPool()
        self:RewrapAll()
        self:ScrollToBottom()

        self.OptionsObserver = self.Trash:Add(
            LazyVarDerive(
                ChatConfigModel.GetSingleton().Committed,
                function(lv) self:ApplyOptions(lv()) end
            )
        )
    end,

    ---------------------------------------------------------------------------
    -- Pool sizing
    ---------------------------------------------------------------------------

    --- Rebuilds the line pool to fit the current Pool height. Lines stack
    --- bottom-up: `ChatLineInterfaces[1]` pins to the pool's bottom and
    --- holds the newest visible message; subsequent slots stack above. When
    --- there are fewer messages than slots, the empty (and `Hide()`-flagged)
    --- slots sit at the top of the pool, so the chat reads bottom-anchored
    --- like Discord / Slack — and matches the feed's stacking direction so
    --- close ↔ open transitions look continuous. Safe to call repeatedly;
    --- callers are expected to follow up with `CalcVisible` (and `RewrapAll`
    --- on a true resize).
    ---@param self UIChatLinesInterface
    RebuildPool = function(self)
        local pool = self.Pool
        -- Read the live size straight from the config model so the pool
        -- always tracks the current option without a cached copy on `self`.
        local fontSize = ChatConfigModel.GetOptions().font_size or 14

        -- Need one line to establish the row height. The row's `Height` is
        -- a lazy function of the name-text font (see `ChatLineInterface`).
        if not self.ChatLineInterfaces[1] then
            self.ChatLineInterfaces[1] = ChatLineInterface(pool)
            self.ChatLineInterfaces[1]:SetFontSize(fontSize)
            self.ChatLineInterfaces[1].OnNameClicked   = self.LineNameClicked
            self.ChatLineInterfaces[1].OnCameraClicked = self.LineCameraClicked
            Layouter(self.ChatLineInterfaces[1])
                :AtLeftBottomIn(pool)
                :Right(pool.Right)
                :End()
        end

        local rowHeight = self.ChatLineInterfaces[1].Height()
        if rowHeight < 1 then rowHeight = 18 end -- safety fallback

        local neededLines = math.max(1, math.floor(pool.Height() / rowHeight))
        local currentCount = table.getn(self.ChatLineInterfaces)

        -- Grow: stack each new row above the previous one.
        for i = currentCount + 1, neededLines do
            self.ChatLineInterfaces[i] = ChatLineInterface(pool)
            self.ChatLineInterfaces[i]:SetFontSize(fontSize)
            self.ChatLineInterfaces[i].OnNameClicked   = self.LineNameClicked
            self.ChatLineInterfaces[i].OnCameraClicked = self.LineCameraClicked
            Layouter(self.ChatLineInterfaces[i])
                :Above(self.ChatLineInterfaces[i - 1])
                :AtLeftIn(pool)
                :Right(pool.Right)
                :End()
        end

        -- Shrink: destroy the surplus tail.
        for i = currentCount, neededLines + 1, -1 do
            self.ChatLineInterfaces[i]:Destroy()
            self.ChatLineInterfaces[i] = nil
        end
    end,

    ---------------------------------------------------------------------------
    -- Options application
    ---------------------------------------------------------------------------

    --- Applies a `UIChatOptions` snapshot. Handles `font_size` and the
    --- `muted` filter today; future options that affect line rendering
    --- (colours, link visibility) extend this method.
    ---
    --- Window-level options (`win_alpha`, default recipient, …) are the
    --- parent's responsibility — we deliberately don't touch them here.
    ---@param self UIChatLinesInterface
    ---@param options UIChatOptions
    ApplyOptions = function(self, options)
        local oldPoolSize = table.getn(self.ChatLineInterfaces)
        local size = options.font_size or 14
        for _, line in ipairs(self.ChatLineInterfaces) do
            line:SetFontSize(size)
        end
        -- Row height tracks the font, so the pool may need resizing;
        -- wrap widths depend on font metrics, so rewrap all entries.
        self:RebuildPool()
        self:RewrapAll()

        -- Filter-affecting options (muted, links) may have changed too.
        -- Recompute what's visible so entries newly excluded by
        -- `IsValidEntry` drop out of the feed immediately.
        self:RefreshVirtualSize()
        self:RecomputeScrollTopForPoolChange(oldPoolSize)
        self:CalcVisible()
    end,

    ---------------------------------------------------------------------------
    -- Text wrapping
    ---------------------------------------------------------------------------

    --- Wraps a single entry's text to fit the current row width, caching
    --- the result on the entry itself. Delegates to `ChatUtils.WrapEntry`
    --- so the feed view can wrap the same entries with the same logic
    --- (and same width — both panels share row metrics) without reaching
    --- back into us.
    ---@param self UIChatLinesInterface
    ---@param entry UIChatEntry
    WrapEntry = function(self, entry)
        ChatUtils.WrapEntry(entry, self.ChatLineInterfaces[1])
    end,

    --- Re-wraps every entry in the history. Used on resize (width change)
    --- and on option changes that affect the measuring font.
    ---@param self UIChatLinesInterface
    RewrapAll = function(self)
        local history = ChatModel.GetSingleton().History()
        for _, entry in ipairs(history) do
            self:WrapEntry(entry)
        end
        self:RefreshVirtualSize(history)
    end,

    ---------------------------------------------------------------------------
    -- Filtering
    ---------------------------------------------------------------------------

    --- Whether an entry counts toward the virtual scroll size and should
    --- appear in `CalcVisible`. Gates on:
    ---   * per-army mute map (`muted[ArmyID]` → drop) — per-game, set
    ---     via the config dialog or `/mute` / `/unmute`.
    ---   * `links` option (`Camera` or `Location` set + `links == false`
    ---     → drop) — mirrors the legacy filter at chat.legacy.lua:304-310.
    ---     Both `Camera` (full snapshot) and `Location` (sim-side point
    ---     or area hint) surface the camera-link affordance on the row,
    ---     so either field qualifies as a "link" message.
    ---@param self UIChatLinesInterface
    ---@param entry UIChatEntry
    ---@return boolean
    IsValidEntry = function(self, entry)
        if entry == nil then return false end
        local options = ChatConfigModel.GetOptions()
        if options.muted and entry.ArmyID and options.muted[entry.ArmyID] then
            return false
        end
        if (entry.Camera or entry.Location) and options.links == false then
            return false
        end
        return true
    end,

    ---------------------------------------------------------------------------
    -- Scroll container
    ---------------------------------------------------------------------------

    --- Recomputes `VirtualSize` = total wrapped lines across all valid entries.
    ---@param self UIChatLinesInterface
    ---@param history? UIChatEntry[]
    RefreshVirtualSize = function(self, history)
        history = history or ChatModel.GetSingleton().History()
        local size = 0
        for _, entry in ipairs(history) do
            if self:IsValidEntry(entry) then
                size = size + ((entry.WrappedText and table.getn(entry.WrappedText)) or 1)
            end
        end
        self.VirtualSize = size
    end,

    --- Standard MAUI scrollable interface: returns (rangeMin, rangeMax, visibleMin, visibleMax).
    ---@param self UIChatLinesInterface
    ---@param axis string  # "Vert" or "Horz"
    GetScrollValues = function(self, axis)
        local poolSize = table.getn(self.ChatLineInterfaces)
        local top = self.ScrollTop
        return 1, self.VirtualSize, top, math.min(top + poolSize, self.VirtualSize)
    end,

    --- Scrolls by a number of rows (negative = toward older messages).
    ---@param self UIChatLinesInterface
    ---@param axis string
    ---@param delta number
    ScrollLines = function(self, axis, delta)
        self:ScrollSetTop(axis, self.ScrollTop + math.floor(delta))
    end,

    --- Scrolls by a page (pool-size worth of rows).
    ---@param self UIChatLinesInterface
    ---@param axis string
    ---@param delta number
    ScrollPages = function(self, axis, delta)
        self:ScrollSetTop(axis, self.ScrollTop + math.floor(delta) * table.getn(self.ChatLineInterfaces))
    end,

    --- Jumps to an absolute virtual position, clamped to the valid range.
    --- Name and signature match the engine's `ScrollSetTop(axis, top)` contract
    --- so `Scrollbar:SetScrollable` can call it directly.
    ---@param self UIChatLinesInterface
    ---@param axis string
    ---@param top number
    ScrollSetTop = function(self, axis, top)
        ChatController.NotifyActivity()
        top = math.floor(top or 1)
        local poolSize = table.getn(self.ChatLineInterfaces)
        local maxTop = math.max(1, self.VirtualSize - poolSize + 1)
        local clamped = math.max(1, math.min(maxTop, top))
        if clamped == self.ScrollTop then return end
        self.ScrollTop = clamped
        self:CalcVisible()
    end,

    --- Standard MAUI scrollable interface: whether scrolling is possible on
    --- the given axis.
    ---@param self UIChatLinesInterface
    ---@param axis string
    ---@return boolean
    IsScrollable = function(self, axis)
        return true
    end,

    --- Adjusts `ScrollTop` to compensate for a change in pool size (window
    --- resize, font-size change). Keeps the bottom of the visible window —
    --- the entry currently rendered at `pool[1]` — pinned across the change:
    --- when the pool grows, the new slots above reveal *older* entries
    --- instead of staying blank, and an at-bottom view stays at the bottom.
    --- Caller is responsible for following up with `CalcVisible`.
    ---
    --- Without this step, growing the pool past the previous `visibleBottom`
    --- range leaves the new top slots stuck on the `currentVirtualPos < scrollTop`
    --- branch in `CalcVisible` — they Clear+Hide instead of being filled with
    --- older history. Scrolling later "fixes" it because `ScrollSetTop` writes
    --- a fresh `ScrollTop` that lets `CalcVisible` walk further back.
    ---@param self UIChatLinesInterface
    ---@param oldPoolSize number   # pool length before the resize / RebuildPool call
    RecomputeScrollTopForPoolChange = function(self, oldPoolSize)
        local oldVisibleBottom = math.min(self.ScrollTop + oldPoolSize - 1, self.VirtualSize)
        local newPoolSize = table.getn(self.ChatLineInterfaces)
        local newMaxTop = math.max(1, self.VirtualSize - newPoolSize + 1)
        local newScrollTop = math.max(1, oldVisibleBottom - newPoolSize + 1)
        self.ScrollTop = math.max(1, math.min(newMaxTop, newScrollTop))
    end,

    --- Snaps to the bottom of the virtual list.
    ---@param self UIChatLinesInterface
    ScrollToBottom = function(self)
        self:ScrollSetTop(nil, self.VirtualSize)
        -- ScrollSetTop short-circuits when the position doesn't change, but
        -- the pool still needs a render pass after a rebuild / rewrap.
        self:CalcVisible()
    end,

    --- True when `ScrollTop` is already pinned at the maximum legal value
    --- — i.e. the newest entry is in the bottom-most pool slot and no
    --- amount of "scroll down" would change anything. Useful for callers
    --- that want a "if already at bottom, do something else" two-stage
    --- behaviour (e.g. dismissing the window on a second jump-to-bottom).
    ---@param self UIChatLinesInterface
    ---@return boolean
    IsAtBottom = function(self)
        local poolSize = table.getn(self.ChatLineInterfaces)
        local maxTop = math.max(1, self.VirtualSize - poolSize + 1)
        return self.ScrollTop >= maxTop
    end,

    ---------------------------------------------------------------------------
    -- Visibility mapping
    ---------------------------------------------------------------------------

    --- Projects the visible virtual range onto the bottom-anchored line
    --- pool. `ChatLineInterfaces[1]` (bottom of the pool) shows the newest
    --- visible entry / wrapped chunk; subsequent slots walk back through
    --- history toward older content, matching the `Above`-stacked layout
    --- from `RebuildPool`. Skips filtered-out entries in either direction.
    --- When fewer entries fit than the pool can hold, the surplus slots
    --- (at the top of the pool) are cleared and hidden.
    ---@param self UIChatLinesInterface
    CalcVisible = function(self)
        if not self.ChatLineInterfaces[1] then return end

        local history = ChatModel.GetSingleton().History()
        local historyCount = table.getn(history)
        local poolSize = table.getn(self.ChatLineInterfaces)
        local scrollTop = self.ScrollTop

        -- The bottommost visible virtual position is the newest entry the
        -- user can currently see; pool[1] (the bottom row) renders it.
        -- `VirtualSize` reflects the post-filter count, so this stays
        -- correct when muted senders are hidden mid-feed.
        local visibleBottom = math.min(scrollTop + poolSize - 1, self.VirtualSize)

        -- Walk forward through history to find the entry + wrappedIdx that
        -- covers `visibleBottom`. Same scan as the legacy loop but anchored
        -- to the bottom of the visible window instead of its top.
        local entryIdx = 1
        local wrappedIdx = 1
        local virtualPos = 0

        while entryIdx <= historyCount and not self:IsValidEntry(history[entryIdx]) do
            entryIdx = entryIdx + 1
        end

        while entryIdx <= historyCount do
            local entry = history[entryIdx]
            local wrapCount = (entry.WrappedText and table.getn(entry.WrappedText)) or 1
            if virtualPos + wrapCount >= visibleBottom then
                wrappedIdx = visibleBottom - virtualPos
                if wrappedIdx < 1 then wrappedIdx = 1 end
                break
            end
            virtualPos = virtualPos + wrapCount
            entryIdx = entryIdx + 1
            while entryIdx <= historyCount and not self:IsValidEntry(history[entryIdx]) do
                entryIdx = entryIdx + 1
            end
        end

        -- Fill the pool from bottom (poolIdx 1) upward. Each step decrements
        -- the wrapped-line cursor; when a continuation chunk runs out, we
        -- hop back to the previous valid entry (walking past filtered ones).
        local currentVirtualPos = visibleBottom
        for poolIdx = 1, poolSize do
            local line = self.ChatLineInterfaces[poolIdx]
            local outOfRange = entryIdx < 1
                or entryIdx > historyCount
                or currentVirtualPos < scrollTop
                or currentVirtualPos < 1
            if outOfRange then
                line:Clear()
                line:Hide()
            else
                local entry = history[entryIdx]
                local wrapped = entry.WrappedText
                local wrappedText = (wrapped and wrapped[wrappedIdx]) or entry.Text or ''

                if wrappedIdx == 1 then
                    line:SetHeader(entry, wrappedText)
                else
                    line:SetContinuation(entry, wrappedText)
                end
                line:Show()

                currentVirtualPos = currentVirtualPos - 1
                if wrappedIdx > 1 then
                    wrappedIdx = wrappedIdx - 1
                else
                    entryIdx = entryIdx - 1
                    while entryIdx >= 1 and not self:IsValidEntry(history[entryIdx]) do
                        entryIdx = entryIdx - 1
                    end
                    if entryIdx >= 1 then
                        local prevEntry = history[entryIdx]
                        wrappedIdx = (prevEntry.WrappedText and table.getn(prevEntry.WrappedText)) or 1
                    end
                end
            end
        end
    end,

    ---------------------------------------------------------------------------
    -- Model reactions
    ---------------------------------------------------------------------------

    --- Called whenever `model.History` fires dirty. Wraps entries we haven't
    --- wrapped yet (new arrivals), refreshes the virtual size, and snaps to
    --- the bottom so the new line is visible.
    ---@param self UIChatLinesInterface
    ---@param history UIChatEntry[]
    OnHistoryChanged = function(self, history)
        for _, entry in ipairs(history) do
            if not entry.WrappedText then
                self:WrapEntry(entry)
            end
        end
        self:RefreshVirtualSize(history)
        if self.ChatLineInterfaces[1] then
            self:ScrollToBottom()
        end

        -- make sure chat messages stay hidden if window is hidden
        local windowVisible = ChatModel.GetSingleton().WindowVisible()
        if not windowVisible then
            self:Hide()
        end
    end,

    ---------------------------------------------------------------------------
    -- Resize hooks (driven by the parent window's resize events)
    ---------------------------------------------------------------------------

    ---@param self UIChatLinesInterface
    OnResizeLive = function(self)
        local oldPoolSize = table.getn(self.ChatLineInterfaces)
        self:RebuildPool()
        self:RewrapAll()
        self:RecomputeScrollTopForPoolChange(oldPoolSize)
        self:CalcVisible()
    end,

    ---@param self UIChatLinesInterface
    OnResizeFinished = function(self)
        local oldPoolSize = table.getn(self.ChatLineInterfaces)
        self:RebuildPool()
        self:RewrapAll()
        self:RecomputeScrollTopForPoolChange(oldPoolSize)
        self:CalcVisible()
    end,

    --- Empties our trash bag so every derived observer we allocated is
    --- destroyed — no `OnDirty` can fire into a torn-down `self`.
    ---@param self UIChatLinesInterface
    OnDestroy = function(self)
        self.Trash:Destroy()
    end,
}

-------------------------------------------------------------------------------
--#region Debugging

function __moduleinfo.OnDirty()
    import(__moduleinfo.name)
end

--#endregion
