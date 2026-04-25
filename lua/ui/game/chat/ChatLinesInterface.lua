
local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")

local Group = import("/lua/maui/group.lua").Group
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap

local ChatLineInterface = import("/lua/ui/game/chat/ChatLineInterface.lua").ChatLineInterface

local ChatModel = import("/lua/ui/game/chat/ChatModel.lua")
local ChatController = import("/lua/ui/game/chat/ChatController.lua")
local ChatConfigModel = import("/lua/ui/game/chat/config/ChatConfigModel.lua")

local MauiWrapText = import("/lua/maui/text.lua").WrapText
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

    --- Rebuilds the line pool to fit the current Pool height. Adds rows at
    --- the bottom when we grow, destroys the tail when we shrink. Safe to
    --- call repeatedly; callers are expected to follow up with `CalcVisible`
    --- (and `RewrapAll` on a true resize).
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
                :AtLeftTopIn(pool)
                :Right(pool.Right)
                :End()
        end

        local rowHeight = self.ChatLineInterfaces[1].Height()
        if rowHeight < 1 then rowHeight = 18 end -- safety fallback

        local neededLines = math.max(1, math.floor(pool.Height() / rowHeight))
        local currentCount = table.getn(self.ChatLineInterfaces)

        -- Grow: append rows below the previous one.
        for i = currentCount + 1, neededLines do
            self.ChatLineInterfaces[i] = ChatLineInterface(pool)
            self.ChatLineInterfaces[i]:SetFontSize(fontSize)
            self.ChatLineInterfaces[i].OnNameClicked   = self.LineNameClicked
            self.ChatLineInterfaces[i].OnCameraClicked = self.LineCameraClicked
            Layouter(self.ChatLineInterfaces[i])
                :Below(self.ChatLineInterfaces[i - 1])
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
        self:CalcVisible()
    end,

    ---------------------------------------------------------------------------
    -- Text wrapping
    ---------------------------------------------------------------------------

    --- Wraps a single entry's text to fit the current row width. Results are
    --- cached on the entry itself as `entry.WrappedText`. The first wrapped
    --- line reserves space for the name prefix; continuation lines span the
    --- wider area to the right of the team-colour column.
    ---@param self UIChatLinesInterface
    ---@param entry UIChatEntry
    WrapEntry = function(self, entry)
        local measureLine = self.ChatLineInterfaces[1]
        if not measureLine then
            entry.WrappedText = { entry.Text or '' }
            return
        end

        local name = entry.Name or ''
        local lines = MauiWrapText(entry.Text or '',
            function(lineIndex)
                if lineIndex == 1 then
                    return measureLine.Right()
                        - (measureLine.Name.Left() + measureLine.Name:GetStringAdvance(name) + 4)
                else
                    return measureLine.Right()
                        - (measureLine.Name.Left() + 4)
                end
            end,
            function(textChunk)
                return measureLine.Text:GetStringAdvance(textChunk)
            end)

        if table.empty(lines) then lines = { '' } end
        entry.WrappedText = lines
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
    --- appear in `CalcVisible`. Currently gates on the per-army mute map
    --- from `ChatConfigModel.Committed`; camera-link filtering is still TODO.
    ---@param self UIChatLinesInterface
    ---@param entry UIChatEntry
    ---@return boolean
    IsValidEntry = function(self, entry)
        if entry == nil then return false end
        local muted = ChatConfigModel.GetOptions().muted
        if muted and entry.ArmyID and muted[entry.ArmyID] then
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

    --- Snaps to the bottom of the virtual list.
    ---@param self UIChatLinesInterface
    ScrollToBottom = function(self)
        self:ScrollSetTop(nil, self.VirtualSize)
        -- ScrollSetTop short-circuits when the position doesn't change, but
        -- the pool still needs a render pass after a rebuild / rewrap.
        self:CalcVisible()
    end,

    ---------------------------------------------------------------------------
    -- Visibility mapping
    ---------------------------------------------------------------------------

    --- Projects `[ScrollTop, ScrollTop + poolSize)` in virtual space onto the
    --- line pool. Skips over filtered-out entries, uses `SetHeader` for the
    --- first wrapped line of an entry and `SetContinuation` for the rest.
    ---@param self UIChatLinesInterface
    CalcVisible = function(self)
        if not self.ChatLineInterfaces[1] then return end

        local history = ChatModel.GetSingleton().History()
        local historyCount = table.getn(history)
        local poolSize = table.getn(self.ChatLineInterfaces)
        local scrollTop = self.ScrollTop

        -- Walk to the entry + wrapped-line that covers virtual position `scrollTop`.
        local entryIdx = 1
        local wrappedIdx = 1
        local virtualPos = 0

        while entryIdx <= historyCount and not self:IsValidEntry(history[entryIdx]) do
            entryIdx = entryIdx + 1
        end

        while entryIdx <= historyCount do
            local entry = history[entryIdx]
            local wrapCount = (entry.WrappedText and table.getn(entry.WrappedText)) or 1
            if virtualPos + wrapCount >= scrollTop then
                wrappedIdx = scrollTop - virtualPos
                if wrappedIdx < 1 then wrappedIdx = 1 end
                break
            end
            virtualPos = virtualPos + wrapCount
            entryIdx = entryIdx + 1
            while entryIdx <= historyCount and not self:IsValidEntry(history[entryIdx]) do
                entryIdx = entryIdx + 1
            end
        end

        -- Fill each pool row; advance the cursor through wrapped lines and
        -- skip filtered entries as we go.
        for poolIdx = 1, poolSize do
            local line = self.ChatLineInterfaces[poolIdx]
            if entryIdx > historyCount then
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

                local wrapCount = (wrapped and table.getn(wrapped)) or 1
                if wrappedIdx < wrapCount then
                    wrappedIdx = wrappedIdx + 1
                else
                    wrappedIdx = 1
                    entryIdx = entryIdx + 1
                    while entryIdx <= historyCount and not self:IsValidEntry(history[entryIdx]) do
                        entryIdx = entryIdx + 1
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
    end,

    ---------------------------------------------------------------------------
    -- Resize hooks (driven by the parent window's resize events)
    ---------------------------------------------------------------------------

    --- Cheap resize pass: rebuild the pool to the new height and re-render
    --- against existing wraps. Wrap widths are width-dependent but rewrapping
    --- every drag frame is too expensive — see `OnResizeFinished`.
    ---@param self UIChatLinesInterface
    OnResizeLive = function(self)
        self:RebuildPool()
        self:CalcVisible()
    end,

    --- Expensive resize pass: rebuild + rewrap + re-render. Call once when
    --- the user finishes a resize drag.
    ---@param self UIChatLinesInterface
    OnResizeFinished = function(self)
        self:RebuildPool()
        self:RewrapAll()
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
