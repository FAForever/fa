
local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")

local Window = import("/lua/maui/window.lua").Window
local Group = import("/lua/maui/group.lua").Group

local ChatLineInterface = import("/lua/ui/game/chat/ChatLineInterface.lua").ChatLineInterface
local ChatEditInterface = import("/lua/ui/game/chat/ChatEditInterface.lua").ChatEditInterface

local ChatModel = import("/lua/ui/game/chat/ChatModel.lua")
local ChatController = import("/lua/ui/game/chat/ChatController.lua")

local MauiWrapText = import("/lua/maui/text.lua").WrapText

local Layouter = LayoutHelpers.ReusedLayoutFor

--- Skin textures for the chat window frame. Mirrors the layout that
--- `/lua/ui/game/layouts/chat_layout.lua` applies to the legacy chat Window
--- so the new window matches the original visual style.
local WindowTextures = {
    tl = UIUtil.UIFile('/game/chat_brd/chat_brd_ul.dds'),
    tr = UIUtil.UIFile('/game/chat_brd/chat_brd_ur.dds'),
    tm = UIUtil.UIFile('/game/chat_brd/chat_brd_horz_um.dds'),
    ml = UIUtil.UIFile('/game/chat_brd/chat_brd_vert_l.dds'),
    m  = UIUtil.UIFile('/game/chat_brd/chat_brd_m.dds'),
    mr = UIUtil.UIFile('/game/chat_brd/chat_brd_vert_r.dds'),
    bl = UIUtil.UIFile('/game/chat_brd/chat_brd_ll.dds'),
    bm = UIUtil.UIFile('/game/chat_brd/chat_brd_lm.dds'),
    br = UIUtil.UIFile('/game/chat_brd/chat_brd_lr.dds'),
    borderColor = 'ff415055',
}

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
---@field LinesContainer Group
---@field Lines          UIChatLineInterface[]
---@field Edit           UIChatEditInterface
---@field ScrollTop      number    # 1-based virtual position of the top visible row
---@field VirtualSize    number    # total wrapped lines across valid entries
local ChatInterface = ClassUI(Window) {

    ---@param self UIChatInterface
    ---@param parent Control
    __init = function(self, parent)
        Window.__init(self, parent, "", false, true, true, false, false, "chat_window_v2", {
            Left = 8, Top = 460, Right = 430, Bottom = 720,
        }, WindowTextures)

        local client = self:GetClientGroup()

        -- Container for the line pool. Stays empty until __post_init can
        -- measure its laid-out height and build the pool from that.
        self.LinesContainer = Group(client, "ChatLinesContainer")

        self.Lines       = {}
        self.ScrollTop   = 1
        self.VirtualSize = 0

        -- The edit area sits at the bottom of the client region.
        self.Edit = ChatEditInterface(client)

        -- Reactive: history → wrap new entries, refresh size, stick to
        -- bottom. The initial firing happens before __post_init so the
        -- wrap call has no pool to measure against; that's fine —
        -- RewrapAll runs once the pool exists.
        local model = ChatModel.GetSingleton()
        model.History.OnDirty = function(lv)
            self:OnHistoryChanged(lv())
        end
        self:OnHistoryChanged(model.History())

        -- Reactive: window visibility → show / hide the frame.
        model.WindowVisible.OnDirty = function(lv)
            if lv() then
                self:Show()
                self.Edit:AcquireFocus()
            else
                self:Hide()
            end
        end
        if model.WindowVisible() then
            self:Show()
        else
            self:Hide()
        end
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

        Layouter(self.LinesContainer)
            :AtLeftIn(client, pad)
            :AtRightIn(client, pad)
            :AtTopIn(client, pad)
            :AnchorToTop(self.Edit, pad)
            :End()

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
            Layouter(self.Lines[1])
                :AtLeftTopIn(container)
                :Right(container.Right)
                :End()
        end

        local rowHeight = self.Lines[1].Height()
        if rowHeight < 1 then rowHeight = 18 end  -- safety fallback

        local neededLines = math.max(1, math.floor(container.Height() / rowHeight))
        local currentCount = table.getn(self.Lines)

        -- Grow: append rows below the previous one.
        for i = currentCount + 1, neededLines do
            self.Lines[i] = ChatLineInterface(container)
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
    -- Text wrapping
    ---------------------------------------------------------------------------

    --- Wraps a single entry's text to fit the current row width. Results are
    --- cached on the entry itself as `entry.wrappedText`. The first wrapped
    --- line reserves space for the name prefix; continuation lines span the
    --- wider area to the right of the team-colour column.
    ---@param self UIChatInterface
    ---@param entry UIChatEntry
    WrapEntry = function(self, entry)
        local measureLine = self.Lines[1]
        if not measureLine then
            entry.wrappedText = { entry.text or '' }
            return
        end

        local name = entry.name or ''
        local lines = MauiWrapText(entry.text or '',
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
        entry.wrappedText = lines
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
                size = size + ((entry.wrappedText and table.getn(entry.wrappedText)) or 1)
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
        self:SetScrollTop(self.ScrollTop + math.floor(delta))
    end,

    --- Scrolls by a page (pool-size worth of rows).
    ---@param self UIChatInterface
    ---@param axis string
    ---@param delta number
    ScrollPages = function(self, axis, delta)
        self:SetScrollTop(self.ScrollTop + math.floor(delta) * table.getn(self.Lines))
    end,

    --- Jumps to an absolute virtual position, clamped to the valid range.
    ---@param self UIChatInterface
    ---@param top number
    SetScrollTop = function(self, top)
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
        self:SetScrollTop(self.VirtualSize)
        -- SetScrollTop short-circuits when the position doesn't change, but
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
            local wrapCount = (entry.wrappedText and table.getn(entry.wrappedText)) or 1
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
                local wrapped = entry.wrappedText
                local wrappedText = (wrapped and wrapped[wrappedIdx]) or entry.text or ''

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
            if not entry.wrappedText then
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
    --- happens here rather than on every drag frame.
    OnResizeSet = function(self)
        self:RebuildPool()
        self:RewrapAll()
        self:CalcVisible()
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
        -- Clear subscriptions to avoid dangling callbacks into a destroyed view.
        local model = ChatModel.GetSingleton()
        model.History.OnDirty = nil
        model.WindowVisible.OnDirty = nil

        Instance:Destroy()
        Instance = nil
    end
    import(__moduleinfo.name)
end

--#endregion
