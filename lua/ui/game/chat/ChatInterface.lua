local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")

local Window = import("/lua/maui/window.lua").Window
local Group = import("/lua/maui/group.lua").Group
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local Button = import("/lua/maui/button.lua").Button

local ChatLineInterface = import("/lua/ui/game/chat/ChatLineInterface.lua").ChatLineInterface
local ChatEditInterface = import("/lua/ui/game/chat/ChatEditInterface.lua").ChatEditInterface

local ChatModel = import("/lua/ui/game/chat/ChatModel.lua")
local ChatController = import("/lua/ui/game/chat/ChatController.lua")
local ChatConfigModel = import("/lua/ui/game/chat/config/ChatConfigModel.lua")

local MauiWrapText = import("/lua/maui/text.lua").WrapText
local LazyVarDerive = import("/lua/lazyvar.lua").Derive

local Layouter = LayoutHelpers.ReusedLayoutFor

--- Skin textures for the chat window frame. Mirrors the layout that
--- `/lua/ui/game/layouts/chat_layout.lua` applies to the legacy chat Window
--- so the new window matches the original visual style.
local WindowTextures = {
    tl          = UIUtil.UIFile('/game/chat_brd/chat_brd_ul.dds'),
    tr          = UIUtil.UIFile('/game/chat_brd/chat_brd_ur.dds'),
    tm          = UIUtil.UIFile('/game/chat_brd/chat_brd_horz_um.dds'),
    ml          = UIUtil.UIFile('/game/chat_brd/chat_brd_vert_l.dds'),
    m           = UIUtil.UIFile('/game/chat_brd/chat_brd_m.dds'),
    mr          = UIUtil.UIFile('/game/chat_brd/chat_brd_vert_r.dds'),
    bl          = UIUtil.UIFile('/game/chat_brd/chat_brd_ll.dds'),
    bm          = UIUtil.UIFile('/game/chat_brd/chat_brd_lm.dds'),
    br          = UIUtil.UIFile('/game/chat_brd/chat_brd_lr.dds'),
    borderColor = 'ff415055',
}

--- Corner grip textures for the four resize handles sticking out of the
--- window corners. Each handle carries `up` / `over` / `down` states that
--- the `RolloverHandler` swaps through during hover-and-resize.
local function DragHandleTextures(corner)
    return {
        up   = UIUtil.UIFile('/game/drag-handle/drag-handle-' .. corner .. '_btn_up.dds'),
        over = UIUtil.UIFile('/game/drag-handle/drag-handle-' .. corner .. '_btn_over.dds'),
        down = UIUtil.UIFile('/game/drag-handle/drag-handle-' .. corner .. '_btn_down.dds'),
    }
end

--- Default window rect, kept as a module local so `ResetPosition` can
--- restore it after the user has moved the window around.
local DefaultRect = { Left = 8, Top = 460, Right = 430, Bottom = 720 }

-------------------------------------------------------------------------------
-- The main chat window: a draggable, resizable frame hosting a dynamically
-- sized pool of chat line rows plus the edit area at the bottom.
--
-- This class owns four related concerns lifted from the legacy chat.lua:
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
-- Filtering (per-army / camera-link / feed mode) is stubbed via
-- `IsValidEntry` which always returns true for now — wiring it up to
-- `ChatConfigModel` is a follow-up step.

---@class UIChatInterface : Window
---@field Trash          TrashBag                            # owns every subscription-LazyVar we create
---@field LinesContainer Group
---@field Lines          UIChatLineInterface[]
---@field Edit           UIChatEditInterface
---@field Scrollbar      Scrollbar
---@field ScrollTop      number    # 1-based virtual position of the top visible row
---@field VirtualSize    number    # total wrapped lines across valid entries
---@field FontSize              number                       # current font size (from ChatOptions.font_size)
---@field DragTL               Bitmap                        # top-left corner resize grip
---@field DragTR               Bitmap                        # top-right corner resize grip
---@field DragBL               Bitmap                        # bottom-left corner resize grip
---@field DragBR               Bitmap                        # bottom-right corner resize grip
---@field ResetPositionBtn     Button                        # titlebar button that restores DefaultRect
---@field HistoryObserver       LazyVar<UIChatEntry[]>       # derived from ChatModel.History
---@field WindowVisibleObserver LazyVar<boolean>             # derived from ChatModel.WindowVisible
---@field OptionsObserver       LazyVar<UIChatOptions>       # derived from ChatConfigModel.Committed
local ChatInterface = ClassUI(Window) {

    ---@param self UIChatInterface
    ---@param parent Control
    __init = function(self, parent)
        Window.__init(self, parent, "", false, true, true, false, false, "chat_window_v2", DefaultRect, WindowTextures)
        self:SetMinimumResize(400, 160)

        self:SetupDragHandles()
        self:SetupResetPositionButton()

        local client = self:GetClientGroup()

        -- Single trash bag for everything we allocate that needs explicit
        -- destruction — currently just the derived observer LazyVars.
        -- Emptied in `OnDestroy`.
        self.Trash = TrashBag()

        -- Container for the line pool. Stays empty until __post_init can
        -- measure its laid-out height and build the pool from that.
        self.LinesContainer = Group(client, "ChatLinesContainer")

        self.Lines       = {}
        self.ScrollTop   = 1
        self.VirtualSize = 0
        self.FontSize    = ChatConfigModel.GetSingleton().Committed().font_size or 14

        -- Expose the scrollable interface on the container so
        -- `UIUtil.CreateVertScrollbarFor(LinesContainer)` binds correctly.
        -- The logic and state live on `self`; the container just delegates.
        self.LinesContainer.GetScrollValues = function(_, axis) return self:GetScrollValues(axis) end
        self.LinesContainer.ScrollLines     = function(_, axis, delta) self:ScrollLines(axis, delta) end
        self.LinesContainer.ScrollPages     = function(_, axis, delta) self:ScrollPages(axis, delta) end
        self.LinesContainer.ScrollSetTop    = function(_, axis, top) self:ScrollSetTop(axis, top) end
        self.LinesContainer.IsScrollable    = function(_, axis) return self:IsScrollable(axis) end

        -- The edit area sits at the bottom of the client region.
        self.Edit = ChatEditInterface(client)

        -- Reactive subscriptions use `LazyVarDerive` so each observer is a
        -- fresh LazyVar that reads from an upstream model field — setting
        -- our handler can never stomp another subscriber's (see the chat
        -- CLAUDE.md for the pattern).
        local model = ChatModel.GetSingleton()
        local configModel = ChatConfigModel.GetSingleton()

        -- History → wrap new entries, refresh size, stick to bottom. The
        -- initial firing happens before __post_init so the wrap call has
        -- no pool to measure against; that's fine — RewrapAll runs once
        -- the pool exists.
        self.HistoryObserver = self.Trash:Add(
            LazyVarDerive(
                model.History,
                function(lv)
                    self:OnHistoryChanged(lv()
                    )
                end
            )
        )

        -- Committed chat options → apply font size, rebuild the pool (line
        -- height tracks the font), rewrap all entries (wrap widths depend
        -- on font metrics), and re-render.
        self.OptionsObserver = self.Trash:Add(
            LazyVarDerive(
                configModel.Committed,
                function(lv)
                    self:ApplyOptions(lv()
                    )
                end
            )
        )

        -- Window visibility → show / hide the frame.
        self.WindowVisibleObserver = self.Trash:Add(
            LazyVarDerive(
                model.WindowVisible,
                function(lv)
                    if lv() then
                        self:Show()
                        self.Edit:AcquireFocus()
                    else
                        self:Hide()
                    end
                end
            )
        )
    end,

    --- Creates the four corner resize grips, wires the window's
    --- `RolloverHandler` to swap their textures on hover / press, and lays
    --- them out overhanging the window corners. Hit-test is disabled on the
    --- grips so resize events still reach the Window's own resize bitmaps.
    ---@param self UIChatInterface
    SetupDragHandles = function(self)
        self.DragTL = Bitmap(self, UIUtil.UIFile('/game/drag-handle/drag-handle-ul_btn_up.dds'))
        self.DragTR = Bitmap(self, UIUtil.UIFile('/game/drag-handle/drag-handle-ur_btn_up.dds'))
        self.DragBL = Bitmap(self, UIUtil.UIFile('/game/drag-handle/drag-handle-ll_btn_up.dds'))
        self.DragBR = Bitmap(self, UIUtil.UIFile('/game/drag-handle/drag-handle-lr_btn_up.dds'))

        self.DragTL.textures = DragHandleTextures('ul')
        self.DragTR.textures = DragHandleTextures('ur')
        self.DragBL.textures = DragHandleTextures('ll')
        self.DragBR.textures = DragHandleTextures('lr')

        for _, grip in { self.DragTL, self.DragTR, self.DragBL, self.DragBR } do
            grip:DisableHitTest()
        end

        Layouter(self.DragTL):AtLeftTopIn(self, -26, -8):Over(self, 5):End()
        Layouter(self.DragTR):AtRightTopIn(self, -22, -8):Over(self, 5):End()
        Layouter(self.DragBL):AtLeftBottomIn(self, -26, -8):Over(self, 5):End()
        Layouter(self.DragBR):AtRightBottomIn(self, -22, -8):Over(self, 5):End()

        -- Each `controlID` the Window delivers maps to the grip(s) that
        -- visually represent that edge: side edges light both adjacent
        -- corners.
        local controlMap = {
            tl = { self.DragTL },
            tr = { self.DragTR },
            bl = { self.DragBL },
            br = { self.DragBR },
            mr = { self.DragBR, self.DragTR },
            ml = { self.DragBL, self.DragTL },
            tm = { self.DragTL, self.DragTR },
            bm = { self.DragBL, self.DragBR },
        }
        self.RolloverHandler = function(_, event, xControl, yControl, cursor, controlID)
            if self._lockSize or self._sizeLock then return end
            local grips = controlMap[controlID]
            if event.Type == 'MouseEnter' then
                if grips then
                    for _, grip in grips do grip:SetTexture(grip.textures.over) end
                end
                GetCursor():SetTexture(UIUtil.GetCursor(cursor))
            elseif event.Type == 'MouseExit' then
                if grips then
                    for _, grip in grips do grip:SetTexture(grip.textures.up) end
                end
                GetCursor():Reset()
            elseif event.Type == 'ButtonPress' then
                if grips then
                    for _, grip in grips do grip:SetTexture(grip.textures.down) end
                end
                self.StartSizing(event, xControl, yControl)
                self._sizeLock = true
            end
        end
    end,

    --- Creates the reset-position button on the title strip (immediately to
    --- the left of the Window's built-in `_configBtn`). Clicking it snaps
    --- every rect edge back to `DefaultRect` and persists the location.
    ---@param self UIChatInterface
    SetupResetPositionButton = function(self)
        self.ResetPositionBtn = Button(self,
            UIUtil.SkinnableFile('/game/menu-btns/default_btn_up.dds'),
            UIUtil.SkinnableFile('/game/menu-btns/default_btn_down.dds'),
            UIUtil.SkinnableFile('/game/menu-btns/default_btn_over.dds'),
            UIUtil.SkinnableFile('/game/menu-btns/default_btn_dis.dds'))
        self.ResetPositionBtn.Depth:Set(function() return self.Depth() + 10 end)
        self.ResetPositionBtn.OnClick = function()
            local scaled = LayoutHelpers.ScaleNumber
            self.Left:Set(scaled(DefaultRect.Left))
            self.Top:Set(scaled(DefaultRect.Top))
            self.Right:Set(scaled(DefaultRect.Right))
            self.Bottom:Set(scaled(DefaultRect.Bottom))
            self:SaveWindowLocation()
        end

        Layouter(self.ResetPositionBtn)
            :LeftOf(self._configBtn)
            :End()
    end,

    ---@param self UIChatInterface
    ---@param parent Control
    __post_init = function(self, parent)
        local client = self:GetClientGroup()
        local pad = 4

        -- Full width, flush with the bottom of the client area. The edit
        -- group derives its own height (see ChatEditInterface.__post_init).
        Layouter(self.Edit)
            :AtLeftIn(client)
            :AtRightIn(client)
            :AtBottomIn(client)
            :Over(client)
            :End()

        -- Leave a ~20px gap on the right for the scrollbar, which sits
        -- anchored to the container's right edge (see below).
        Layouter(self.LinesContainer)
            :AtLeftIn(client, pad)
            :AtRightIn(client, 36)
            :AtTopIn(client, pad)
            :AnchorToTop(self.Edit, 12)
            :End()

        -- Create the vertical scrollbar. `CreateVertScrollbarFor` calls
        -- `Scrollbar:SetScrollable(control)` on the passed control, so the
        -- scrollable interface has to live on `LinesContainer` (as
        -- delegates to self — see __init).
        self.Scrollbar = UIUtil.CreateVertScrollbarFor(self.LinesContainer)

        -- Now that the container has a real size, build the pool and do
        -- a first wrap + render pass.
        self:RebuildPool()
        self:RewrapAll()
        self:ScrollToBottom()
    end,

    ---------------------------------------------------------------------------
    -- Pool sizing
    ---------------------------------------------------------------------------

    --- Rebuilds the line pool to fit the current container height. Adds rows
    --- at the bottom when the window grows, destroys the tail when it shrinks.
    --- Safe to call repeatedly; callers are expected to follow up with
    --- `CalcVisible` (and `RewrapAll` on a true resize).
    ---@param self UIChatInterface
    RebuildPool = function(self)
        local container = self.LinesContainer

        -- Need one line to establish the row height. The row's Height is a
        -- lazy function of the name-text font (see ChatLineInterface).
        if not self.Lines[1] then
            self.Lines[1] = ChatLineInterface(container)
            self.Lines[1]:SetFontSize(self.FontSize)
            Layouter(self.Lines[1])
                :AtLeftTopIn(container)
                :Right(container.Right)
                :End()
        end

        local rowHeight = self.Lines[1].Height()
        if rowHeight < 1 then rowHeight = 18 end -- safety fallback

        local neededLines = math.max(1, math.floor(container.Height() / rowHeight))
        local currentCount = table.getn(self.Lines)

        -- Grow: append rows below the previous one.
        for i = currentCount + 1, neededLines do
            self.Lines[i] = ChatLineInterface(container)
            self.Lines[i]:SetFontSize(self.FontSize)
            Layouter(self.Lines[i])
                :Below(self.Lines[i - 1])
                :AtLeftIn(container)
                :Right(container.Right)
                :End()
        end

        -- Shrink: destroy the surplus tail.
        for i = currentCount, neededLines + 1, -1 do
            self.Lines[i]:Destroy()
            self.Lines[i] = nil
        end
    end,

    ---------------------------------------------------------------------------
    -- Options application
    ---------------------------------------------------------------------------

    --- Applies a `UIChatOptions` snapshot to the window. Currently handles
    --- `font_size`; future options (colours, alpha, feed-mode flags) will
    --- extend this method.
    ---@param self UIChatInterface
    ---@param options UIChatOptions
    ApplyOptions = function(self, options)
        local size = options.font_size or 14
        if size ~= self.FontSize then
            self.FontSize = size
            for _, line in ipairs(self.Lines) do
                line:SetFontSize(size)
            end
            -- Row height tracks the font, so the pool may need resizing;
            -- wrap widths depend on font metrics, so rewrap all entries.
            self:RebuildPool()
            self:RewrapAll()
            self:CalcVisible()
        end
    end,

    ---------------------------------------------------------------------------
    -- Text wrapping
    ---------------------------------------------------------------------------

    --- Wraps a single entry's text to fit the current row width. Results are
    --- cached on the entry itself as `entry.WrappedText`. The first wrapped
    --- line reserves space for the name prefix; continuation lines span the
    --- wider area to the right of the team-colour column.
    ---@param self UIChatInterface
    ---@param entry UIChatEntry
    WrapEntry = function(self, entry)
        local measureLine = self.Lines[1]
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
    ---@param self UIChatInterface
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
    --- appear in `CalcVisible`. Stubbed: wiring the per-army filter and
    --- the camera-link filter to `ChatConfigModel.Committed` is a later step.
    ---@param self UIChatInterface
    ---@param entry UIChatEntry
    ---@return boolean
    IsValidEntry = function(self, entry)
        return entry ~= nil
    end,

    ---------------------------------------------------------------------------
    -- Scroll container
    ---------------------------------------------------------------------------

    --- Recomputes `VirtualSize` = total wrapped lines across all valid entries.
    ---@param self UIChatInterface
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
    ---@param self UIChatInterface
    ---@param axis string  # "Vert" or "Horz"
    GetScrollValues = function(self, axis)
        local poolSize = table.getn(self.Lines)
        local top = self.ScrollTop
        return 1, self.VirtualSize, top, math.min(top + poolSize, self.VirtualSize)
    end

    ,
    --- Scrolls by a number of rows (negative = toward older messages).
    ---@param self UIChatInterface
    ---@param axis string
    ---@param delta number
    ScrollLines = function(self, axis, delta)
        self:ScrollSetTop(axis, self.ScrollTop + math.floor(delta))
    end,

    --- Scrolls by a page (pool-size worth of rows).
    ---@param self UIChatInterface
    ---@param axis string
    ---@param delta number
    ScrollPages = function(self, axis, delta)
        self:ScrollSetTop(axis, self.ScrollTop + math.floor(delta) * table.getn(self.Lines))
    end,

    --- Jumps to an absolute virtual position, clamped to the valid range.
    --- Name and signature match the engine's `ScrollSetTop(axis, top)` contract
    --- so `Scrollbar:SetScrollable` can call it directly.
    ---@param self UIChatInterface
    ---@param axis string
    ---@param top number
    ScrollSetTop = function(self, axis, top)
        top = math.floor(top or 1)
        local poolSize = table.getn(self.Lines)
        local maxTop = math.max(1, self.VirtualSize - poolSize + 1)
        local clamped = math.max(1, math.min(maxTop, top))
        if clamped == self.ScrollTop then return end
        self.ScrollTop = clamped
        self:CalcVisible()
    end,

    --- Standard MAUI scrollable interface: whether scrolling is possible on
    --- the given axis.
    ---@param self UIChatInterface
    ---@param axis string
    ---@return boolean
    IsScrollable = function(self, axis)
        return true
    end,

    --- Snaps to the bottom of the virtual list.
    ---@param self UIChatInterface
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
    ---@param self UIChatInterface
    CalcVisible = function(self)
        if not self.Lines[1] then return end

        local history = ChatModel.GetSingleton().History()
        local historyCount = table.getn(history)
        local poolSize = table.getn(self.Lines)
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
            local line = self.Lines[poolIdx]
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
                    line:SetContinuation(wrappedText)
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
    ---@param self UIChatInterface
    ---@param history UIChatEntry[]
    OnHistoryChanged = function(self, history)
        for _, entry in ipairs(history) do
            if not entry.WrappedText then
                self:WrapEntry(entry)
            end
        end
        self:RefreshVirtualSize(history)
        if self.Lines[1] then
            self:ScrollToBottom()
        end
    end,

    ---------------------------------------------------------------------------
    -- Window event hooks
    ---------------------------------------------------------------------------

    --- Fired continuously during a resize drag. Keep it cheap: just resize
    --- the pool and re-render against existing wraps.
    OnResize = function(self, width, height, firstFrame)
        self:RebuildPool()
        self:CalcVisible()
    end,

    --- Fired when a resize drag ends. Rewrapping is expensive, so it only
    --- happens here rather than on every drag frame. Also snaps the corner
    --- grips back to their `up` texture — the RolloverHandler leaves them
    --- on `down` when StartSizing took over.
    OnResizeSet = function(self)
        self:RebuildPool()
        self:RewrapAll()
        self:CalcVisible()
        self.DragTL:SetTexture(self.DragTL.textures.up)
        self.DragTR:SetTexture(self.DragTR.textures.up)
        self.DragBL:SetTexture(self.DragBL.textures.up)
        self.DragBR:SetTexture(self.DragBR.textures.up)
    end,

    --- Mouse wheel over the window scrolls the chat. `rotation` is in wheel
    --- units (usually ±120 per notch); one notch ≈ one line.
    OnMouseWheel = function(self, rotation)
        self:ScrollLines(nil, -math.floor(rotation / 100))
    end,

    --- Engine-invoked when the user clicks the close button on the window frame.
    OnClose = function(self)
        ChatController.CloseWindow()
    end,

    --- Engine-invoked when the user clicks the config button on the window
    --- frame. Opens (or closes, if already open) the chat options dialog.
    OnConfigClick = function(self)
        import("/lua/ui/game/chat/config/ChatConfigInterface.lua").Toggle()
    end,

    --- Empties our trash bag so every derived observer we allocated is
    --- destroyed — no `OnDirty` can fire into a torn-down `self`.
    OnDestroy = function(self)
        self.Trash:Destroy()
    end,
}

-------------------------------------------------------------------------------
--  Module-level singleton and standalone entry points.

---@type UIChatInterface | nil
local Instance = nil

--- Shows the chat window, creating it on first call.
function Open()
    if not Instance then
        Instance = ChatInterface(GetFrame(0))
    end
    ChatController.OpenWindow()
end

--- Hides the chat window (the instance is kept around).
function Close()
    ChatController.CloseWindow()
end

--- Toggles the chat window, creating it on first call.
function Toggle()
    if not Instance then
        Instance = ChatInterface(GetFrame(0))
    end
    ChatController.ToggleWindow()
end

--- Scrolls the chat feed by `delta` rows (negative = toward older messages).
--- No-op if the window has never been opened.
---@param delta number
function ScrollLines(delta)
    if Instance then
        Instance:ScrollLines(nil, delta)
    end
end

--- Scrolls the chat feed by `delta` pages (negative = toward older messages).
--- No-op if the window has never been opened.
---@param delta number
function ScrollPages(delta)
    if Instance then
        Instance:ScrollPages(nil, delta)
    end
end

-------------------------------------------------------------------------------
--#region Debugging

--- Called by the module manager when this module is reloaded.
---@param newModule any
function __moduleinfo.OnReload(newModule)
    if Instance then
        newModule.Open()
    end
end

--- Called by the module manager when this module becomes dirty.
function __moduleinfo.OnDirty()
    if Instance then
        -- `OnDestroy` empties the trash bag, which in turn destroys every
        -- derived observer — no more `OnDirty` fires into a dead `self`.
        Instance:Destroy()
        Instance = nil
    end
    import(__moduleinfo.name)
end

--#endregion
