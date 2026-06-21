
local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")

local Group = import("/lua/maui/group.lua").Group
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local FloatText = import("/lua/ui/controls/floattext.lua").FloatText

local ChatLineInterface = import("/lua/ui/game/chat/ChatLineInterface.lua").ChatLineInterface

local ChatModel = import("/lua/ui/game/chat/ChatModel.lua")
local ChatController = import("/lua/ui/game/chat/ChatController.lua")
local ChatConfigModel = import("/lua/ui/game/chat/config/ChatConfigModel.lua")
local ChatUtils = import("/lua/ui/game/chat/ChatUtils.lua")

local LazyVarDerive = import("/lua/lazyvar.lua").Derive

local Layouter = LayoutHelpers.ReusedLayoutFor

local Debug = false

-- Reserve space on the right of the wrapper for the scrollbar widget.
local ScrollbarReserve = 32

-------------------------------------------------------------------------------
-- A self-contained chat-lines panel: outer wrapper, inner pool of line rows,
-- and the vertical scrollbar.
--
-- Click hooks (`OnNameClicked`, `OnBodyClicked`, `OnCameraClicked`) are
-- overridable instance fields. Default `OnNameClicked` is a no-op
-- (window-level concern); default `OnBodyClicked` copies the entry text to
-- the clipboard on Ctrl+click; default `OnCameraClicked` jumps the world
-- camera to the entry's hint.

--- Wrapped chat panel: line-row pool, scrollbar, history/options observers. Owns wrap and scroll state.
---@class UIChatLinesInterface : Group
---@field Trash             TrashBag                            # owns every subscription-LazyVar we create
---@field Pool              Group                               # inner group hosting the line rows
---@field Scrollbar         Scrollbar
---@field ChatLineInterfaces UIChatLineInterface[]
---@field ScrollTop         number    # 1-based virtual position of the top visible row
---@field VirtualSize       number    # total wrapped lines across valid entries
---@field HistoryObserver   LazyVar<UIChatEntry[]>
---@field OptionsObserver   LazyVar<UIChatOptions>
---@field LineNameClicked   fun(line: UIChatLineInterface, entry: UIChatEntry, event: KeyEvent)  # shared row-name click handler; captures `self` so pool lines don't allocate per-row closures
---@field LineBodyClicked   fun(line: UIChatLineInterface, entry: UIChatEntry, event: KeyEvent)  # shared body click handler; captures `self` for the same reason
---@field LineCameraClicked fun(line: UIChatLineInterface, entry: UIChatEntry, event: KeyEvent)  # shared cam-icon click handler; captures `self` for the same reason
---@field OnNameClicked     fun(entry: UIChatEntry, event: KeyEvent)                             # overridable: replace to react to a sender-name click
---@field OnBodyClicked     fun(entry: UIChatEntry, event: KeyEvent)                             # overridable: replace to react to a body click (default copies on Ctrl+click)
---@field OnCameraClicked   fun(entry: UIChatEntry, event: KeyEvent)                             # overridable: replace to override camera-link behaviour
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

        self.Pool = Group(self, "ChatLinesPool")

        -- `Scrollbar:SetScrollable` binds to Pool, but the state lives
        -- on self. Forward each method up.
        self.Pool.GetScrollValues = function(_, axis) return self:GetScrollValues(axis) end
        self.Pool.ScrollLines     = function(_, axis, delta) self:ScrollLines(axis, delta) end
        self.Pool.ScrollPages     = function(_, axis, delta) self:ScrollPages(axis, delta) end
        self.Pool.ScrollSetTop    = function(_, axis, top) self:ScrollSetTop(axis, top) end
        self.Pool.IsScrollable    = function(_, axis) return self:IsScrollable(axis) end

        self.OnNameClicked = function(entry, event) end
        self.OnBodyClicked = function(entry, event)
            if event.Modifiers and event.Modifiers.Ctrl then
                if CopyToClipboard(entry.Text or '') then
                    -- Parent to the engine frame so the `event.MouseX/Y`
                    -- screen coords map straight to Left/Top without going
                    -- through the Layouter's `pixelScaleFactor` scaling.
                    -- `event.MouseX/Y` carry the actual click position.
                    -- `GetMouseScreenPos()` would freeze at the last
                    -- pre-UI-occlusion position.
                    local mouseX, mouseY = event.MouseX, event.MouseY
                    local toast = FloatText(GetFrame(0), "Copied to clipboard!")
                    -- Center horizontally on the cursor; the Width LazyVar
                    -- settles after the inner Text is measured.
                    toast.Left:SetFunction(function() return mouseX - toast.Width() / 2 end)
                    toast.Top:Set(mouseY - LayoutHelpers.ScaleNumber(30))
                    toast:Float()
                end
            end
        end
        self.OnCameraClicked = function(entry, event)
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

        -- Built once so pool growth never allocates a per-row closure.
        -- Each forwarder reads `self.OnXxxClicked` on every call, so
        -- replacing the hook later doesn't require re-wiring the rows.
        self.LineNameClicked   = function(_, entry, event) self.OnNameClicked(entry, event) end
        self.LineBodyClicked   = function(_, entry, event) self.OnBodyClicked(entry, event) end
        self.LineCameraClicked = function(_, entry, event) self.OnCameraClicked(entry, event) end

        local model = ChatModel.GetSingleton()
        self.HistoryObserver = self.Trash:Add(
            LazyVarDerive(
                model.History,
                function(lv)
                    self:OnHistoryChanged(lv())
                end
            )
        )

        -- `OptionsObserver` is wired in `Initialize`, not here. Its
        -- initial fire calls `ApplyOptions` then `RebuildPool`, which
        -- reads `Pool.Height()` and so requires layout to be in place.
    end,

    ---@param self UIChatLinesInterface
    ---@param parent Control
    __post_init = function(self, parent)
        Layouter(self.Pool)
            :AtLeftTopIn(self)
            :AtRightIn(self, ScrollbarReserve)
            :AtBottomIn(self)
            :End()

        self.Scrollbar = UIUtil.CreateVertScrollbarFor(self.Pool)
        self.Scrollbar:SetParent(self)

        if Debug then
            self.DebugBG = Bitmap(self)
            self.DebugBG:SetSolidColor('4040ff40')
            self.DebugBG:DisableHitTest()
            Layouter(self.DebugBG):Fill(self):Over(self, 100):End()
        end
    end,

    --- Called by the parent once it has laid out the lines panel.
    --- Builds the pool, rewraps history, scrolls to the bottom, and
    --- wires the options observer.
    ---@param self UIChatLinesInterface
    Initialize = function(self)
        -- `RebuildPool` reads `Pool.Height()`, which is zero until our
        -- outer rect is bound. Pool / rewrap / scroll work has to wait
        -- until the parent positions us.
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

    --- Rebuilds the line pool to fit Pool height. Safe to call repeatedly.
    --- Callers follow up with `CalcVisible` (and `RewrapAll` on a true resize).
    ---@param self UIChatLinesInterface
    RebuildPool = function(self)
        -- Lines stack bottom-up: `ChatLineInterfaces[1]` pins to the
        -- pool's bottom and holds the newest visible message. Empty
        -- slots sit at the top so the feed reads bottom-anchored.
        local pool = self.Pool
        local fontSize = ChatConfigModel.GetOptions().font_size or 14

        -- Need one line to establish the row height (a lazy function of
        -- the name-text font in `ChatLineInterface`).
        if not self.ChatLineInterfaces[1] then
            self.ChatLineInterfaces[1] = ChatLineInterface(pool)
            self.ChatLineInterfaces[1]:SetFontSize(fontSize)
            self.ChatLineInterfaces[1].OnNameClicked   = self.LineNameClicked
            self.ChatLineInterfaces[1].OnBodyClicked   = self.LineBodyClicked
            self.ChatLineInterfaces[1].OnCameraClicked = self.LineCameraClicked
            Layouter(self.ChatLineInterfaces[1])
                :AtLeftBottomIn(pool)
                :Right(pool.Right)
                :End()
        end

        local rowHeight = self.ChatLineInterfaces[1].Height()
        if rowHeight < 1 then rowHeight = 18 end

        local neededLines = math.max(1, math.floor(pool.Height() / rowHeight))
        local currentCount = table.getn(self.ChatLineInterfaces)

        for i = currentCount + 1, neededLines do
            self.ChatLineInterfaces[i] = ChatLineInterface(pool)
            self.ChatLineInterfaces[i]:SetFontSize(fontSize)
            self.ChatLineInterfaces[i].OnNameClicked   = self.LineNameClicked
            self.ChatLineInterfaces[i].OnBodyClicked   = self.LineBodyClicked
            self.ChatLineInterfaces[i].OnCameraClicked = self.LineCameraClicked
            Layouter(self.ChatLineInterfaces[i])
                :Above(self.ChatLineInterfaces[i - 1])
                :AtLeftIn(pool)
                :Right(pool.Right)
                :End()
        end

        for i = currentCount, neededLines + 1, -1 do
            self.ChatLineInterfaces[i]:Destroy()
            self.ChatLineInterfaces[i] = nil
        end
    end,

    ---------------------------------------------------------------------------
    -- Options application
    ---------------------------------------------------------------------------

    --- Applies a `UIChatOptions` snapshot. Window-level options
    --- (`win_alpha`, default recipient, ...) are the parent's responsibility.
    ---@param self UIChatLinesInterface
    ---@param options UIChatOptions
    ApplyOptions = function(self, options)
        local oldPoolSize = table.getn(self.ChatLineInterfaces)
        local size = options.font_size or 14
        for _, line in ipairs(self.ChatLineInterfaces) do
            line:SetFontSize(size)
        end
        -- Row height tracks the font, so the pool may need resizing.
        -- Wrap widths depend on font metrics, so rewrap.
        self:RebuildPool()
        self:RewrapAll()

        self:RefreshVirtualSize()
        self:RecomputeScrollTopForPoolChange(oldPoolSize)
        self:CalcVisible()
    end,

    ---------------------------------------------------------------------------
    -- Text wrapping
    ---------------------------------------------------------------------------

    --- Wraps an entry's text using the first pool line as the measurement source.
    ---@param self UIChatLinesInterface
    ---@param entry UIChatEntry
    WrapEntry = function(self, entry)
        ChatUtils.WrapEntry(entry, self.ChatLineInterfaces[1])
    end,

    --- Re-wraps every history entry. Called after a font, width, or font-metric change.
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

    --- Whether an entry counts toward the virtual scroll size.
    ---@param self UIChatLinesInterface
    ---@param entry UIChatEntry
    ---@return boolean
    IsValidEntry = function(self, entry)
        -- Gates on the per-army mute map and the `links` option. Camera
        -- or Location both qualify as "link" messages: either surfaces
        -- the camera-link affordance on the row.
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

    --- Recounts wrapped lines across non-filtered entries and stores the total in `VirtualSize`.
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

    --- Scrollbar contract: returns `(min, max, top, bottom)` of the visible range.
    ---@param self UIChatLinesInterface
    ---@param axis string  # "Vert" or "Horz"
    GetScrollValues = function(self, axis)
        local poolSize = table.getn(self.ChatLineInterfaces)
        local top = self.ScrollTop
        return 1, self.VirtualSize, top, math.min(top + poolSize, self.VirtualSize)
    end,

    --- Scrolls by a line count (negative = older).
    ---@param self UIChatLinesInterface
    ---@param axis string
    ---@param delta number   # negative = toward older messages
    ScrollLines = function(self, axis, delta)
        self:ScrollSetTop(axis, self.ScrollTop + math.floor(delta))
    end,

    --- Scrolls by `delta` pool-sized pages (negative = older).
    ---@param self UIChatLinesInterface
    ---@param axis string
    ---@param delta number   # in pool-size pages
    ScrollPages = function(self, axis, delta)
        self:ScrollSetTop(axis, self.ScrollTop + math.floor(delta) * table.getn(self.ChatLineInterfaces))
    end,

    --- Jumps to an absolute virtual position, clamped.
    ---@param self UIChatLinesInterface
    ---@param axis string
    ---@param top number
    ScrollSetTop = function(self, axis, top)
        -- Signature matches the engine's `ScrollSetTop(axis, top)`
        -- contract so the scrollbar can call it directly.
        ChatController.NotifyActivity()
        top = math.floor(top or 1)
        local poolSize = table.getn(self.ChatLineInterfaces)
        local maxTop = math.max(1, self.VirtualSize - poolSize + 1)
        local clamped = math.max(1, math.min(maxTop, top))
        if clamped == self.ScrollTop then return end
        self.ScrollTop = clamped
        self:CalcVisible()
    end,

    --- Scrollbar contract: chat is always scrollable on the requested axis.
    ---@param self UIChatLinesInterface
    ---@param axis string
    ---@return boolean
    IsScrollable = function(self, axis)
        return true
    end,

    --- Adjusts `ScrollTop` to keep the entry at `pool[1]` pinned across
    --- a pool-size change. Caller follows up with `CalcVisible`.
    ---@param self UIChatLinesInterface
    ---@param oldPoolSize number   # pool length before the resize / RebuildPool call
    RecomputeScrollTopForPoolChange = function(self, oldPoolSize)
        -- Without this, growing the pool past the previous `visibleBottom`
        -- leaves the new top slots stuck on Clear+Hide instead of
        -- revealing older history. The user has to scroll to "fix" it.
        local oldVisibleBottom = math.min(self.ScrollTop + oldPoolSize - 1, self.VirtualSize)
        local newPoolSize = table.getn(self.ChatLineInterfaces)
        local newMaxTop = math.max(1, self.VirtualSize - newPoolSize + 1)
        local newScrollTop = math.max(1, oldVisibleBottom - newPoolSize + 1)
        self.ScrollTop = math.max(1, math.min(newMaxTop, newScrollTop))
    end,

    --- Scrolls to the newest entry and forces a render pass.
    ---@param self UIChatLinesInterface
    ScrollToBottom = function(self)
        self:ScrollSetTop(nil, self.VirtualSize)
        -- ScrollSetTop short-circuits when the position doesn't change,
        -- but the pool still needs a render pass after rebuild / rewrap.
        self:CalcVisible()
    end,

    --- Whether the newest entry is currently visible.
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

    --- Projects the visible virtual range onto the bottom-anchored line pool.
    ---@param self UIChatLinesInterface
    CalcVisible = function(self)
        -- `ChatLineInterfaces[1]` shows the newest visible chunk.
        -- Subsequent slots walk back through history. Surplus slots at
        -- the top are cleared and hidden.
        if not self.ChatLineInterfaces[1] then return end

        local history = ChatModel.GetSingleton().History()
        local historyCount = table.getn(history)
        local poolSize = table.getn(self.ChatLineInterfaces)
        local scrollTop = self.ScrollTop

        -- pool[1] (bottom row) renders `visibleBottom`. `VirtualSize` is
        -- post-filter so this stays correct mid-feed.
        local visibleBottom = math.min(scrollTop + poolSize - 1, self.VirtualSize)

        -- Walk forward to find the entry + wrappedIdx covering visibleBottom.
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

        -- Fill the pool bottom-up; on continuation exhaustion, hop back to
        -- the previous valid entry (skipping filtered ones).
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

    --- Wraps new arrivals, refreshes virtual size, snaps to bottom.
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

        local windowVisible = ChatModel.GetSingleton().WindowVisible()
        if not windowVisible then
            self:Hide()
        end
    end,

    ---------------------------------------------------------------------------
    -- Resize hooks (driven by the parent window's resize events)
    ---------------------------------------------------------------------------

    --- Per-frame during a window resize: rebuilds the pool and rewraps in real time.
    ---@param self UIChatLinesInterface
    OnResizeLive = function(self)
        local oldPoolSize = table.getn(self.ChatLineInterfaces)
        self:RebuildPool()
        self:RewrapAll()
        self:RecomputeScrollTopForPoolChange(oldPoolSize)
        self:CalcVisible()
    end,

    --- Final pass after a window resize: rebuilds the pool and rewraps once more.
    ---@param self UIChatLinesInterface
    OnResizeFinished = function(self)
        local oldPoolSize = table.getn(self.ChatLineInterfaces)
        self:RebuildPool()
        self:RewrapAll()
        self:RecomputeScrollTopForPoolChange(oldPoolSize)
        self:CalcVisible()
    end,

    --- Destroys derived observers so dangling OnDirty callbacks don't fire into a dead self.
    ---@param self UIChatLinesInterface
    OnDestroy = function(self)
        self.Trash:Destroy()
    end,
}

-------------------------------------------------------------------------------
--#region Debugging

--- Hot-reload hook: re-imports this module on save.
function __moduleinfo.OnDirty()
    import(__moduleinfo.name)
end

--#endregion
