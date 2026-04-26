local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")

local Window = import("/lua/maui/window.lua").Window
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local Button = import("/lua/maui/button.lua").Button

local ChatLinesInterface = import("/lua/ui/game/chat/ChatLinesInterface.lua").ChatLinesInterface
local ChatEditInterface = import("/lua/ui/game/chat/ChatEditInterface.lua").ChatEditInterface
local ChatFeedInterface = import("/lua/ui/game/chat/ChatFeedInterface.lua").ChatFeedInterface

local ChatModel = import("/lua/ui/game/chat/ChatModel.lua")
local ChatController = import("/lua/ui/game/chat/ChatController.lua")
local ChatConfigModel = import("/lua/ui/game/chat/config/ChatConfigModel.lua")

local LazyVarDerive = import("/lua/lazyvar.lua").Derive

local Layouter = LayoutHelpers.ReusedLayoutFor

--- Flip to `true` to overlay a semi-transparent coloured bitmap over the
--- control so its bounds are visible at runtime. Each chat interface uses a
--- distinct colour so overlapping controls can be told apart at a glance.
local Debug = false

--- Skin textures for the chat window frame. `SkinnableFile` returns a
--- callable that resolves the path against the current skin every time
--- it's read — so the border bitmaps automatically pick up the user's
--- skin choice when bound through MAUI's LazyVar machinery, instead of
--- being frozen at module-load time the way `UIFile` would freeze them.
local WindowTextures = {
    tl          = UIUtil.SkinnableFile('/game/chat_brd/chat_brd_ul.dds'),
    tr          = UIUtil.SkinnableFile('/game/chat_brd/chat_brd_ur.dds'),
    tm          = UIUtil.SkinnableFile('/game/chat_brd/chat_brd_horz_um.dds'),
    ml          = UIUtil.SkinnableFile('/game/chat_brd/chat_brd_vert_l.dds'),
    m           = UIUtil.SkinnableFile('/game/chat_brd/chat_brd_m.dds'),
    mr          = UIUtil.SkinnableFile('/game/chat_brd/chat_brd_vert_r.dds'),
    bl          = UIUtil.SkinnableFile('/game/chat_brd/chat_brd_ll.dds'),
    bm          = UIUtil.SkinnableFile('/game/chat_brd/chat_brd_lm.dds'),
    br          = UIUtil.SkinnableFile('/game/chat_brd/chat_brd_lr.dds'),
    borderColor = 'ff415055',
}

--- Corner grip textures for the four resize handles sticking out of the
--- window corners. Each handle carries `up` / `over` / `down` states that
--- the `RolloverHandler` swaps through during hover-and-resize.
--- `SkinnableFile` again so the grips follow the active skin.
---
--- The concatenated path strings widen to `string` rather than the
--- language server's `FileName` alias, which `SkinnableFile`'s parameter
--- annotation requires; suppress the resulting noise rather than littering
--- each line with a cast.
---@diagnostic disable: param-type-mismatch
local function DragHandleTextures(corner)
    return {
        up   = UIUtil.SkinnableFile('/game/drag-handle/drag-handle-' .. corner .. '_btn_up.dds'),
        over = UIUtil.SkinnableFile('/game/drag-handle/drag-handle-' .. corner .. '_btn_over.dds'),
        down = UIUtil.SkinnableFile('/game/drag-handle/drag-handle-' .. corner .. '_btn_down.dds'),
    }
end
---@diagnostic enable: param-type-mismatch

--- Default window rect, kept as a module local so `ResetPosition` can
--- restore it after the user has moved the window around.
local DefaultRect = { Left = 8, Top = 460, Right = 430, Bottom = 720 }

-------------------------------------------------------------------------------
-- The main chat window: a draggable, resizable frame hosting a
-- `ChatLinesInterface` (line pool + scrollbar) and a `ChatEditInterface`
-- (input area).
--
-- The window owns three concerns; the rest is delegated:
--
--   1. Window chrome       — drag handles, reset-position button, close /
--                            config buttons, resize bookkeeping.
--   2. Visibility          — observes `model.WindowVisible` to show/hide.
--   3. Window-level options — `win_alpha` (cascades to descendants).
--
-- Pool sizing, text wrapping, scrolling, filtering, and the per-row click
-- forwarding all live on `ChatLinesInterface` — see that file.

---@class UIChatInterface : Window
---@field Trash                 TrashBag                      # owns every subscription-LazyVar we create
---@field ChatLinesInterface    UIChatLinesInterface          # the wrapped panel containing line rows + scrollbar
---@field ChatEditInterface     UIChatEditInterface
---@field DragTL                Bitmap                        # top-left corner resize grip
---@field DragTR                Bitmap                        # top-right corner resize grip
---@field DragBL                Bitmap                        # bottom-left corner resize grip
---@field DragBR                Bitmap                        # bottom-right corner resize grip
---@field DragHandleControlMap  table<string, Bitmap[]>       # resize-bitmap id → grips to highlight
---@field ResetPositionBtn      Button                        # titlebar button that restores DefaultRect
---@field WindowVisibleObserver LazyVar<boolean>              # derived from ChatModel.WindowVisible
---@field OptionsObserver       LazyVar<UIChatOptions>        # derived from ChatConfigModel.Committed (window-level options only)
---@field ChatFeedInterface     UIChatFeedInterface           # sibling feed view; visible while the window is hidden
---@field DebugBG?              Bitmap                        # semi-transparent overlay shown when `Debug` is true
local ChatInterface = ClassUI(Window) {

    ---@param self UIChatInterface
    ---@param parent Control
    __init = function(self, parent)
        Window.__init(self, parent, "Chat dialog", false, true, true, false, false, "chat_window_v2", DefaultRect, WindowTextures)
        self:SetMinimumResize(400, 160)

        self:SetupDragHandles()
        self:SetupResetPositionButton()

        -- Single trash bag for everything we allocate that needs explicit
        -- destruction — currently just the derived observer LazyVars.
        -- Emptied in `OnDestroy`.
        self.Trash = TrashBag()

        -- The lines panel and edit area. Both are laid out in `__post_init`
        -- once the client area has a real size to anchor against.
        self.ChatLinesInterface = ChatLinesInterface(self)
        self.ChatEditInterface = ChatEditInterface(self)

        -- Feed view: a sibling control on the same parent frame so our own
        -- `Show`/`Hide` cascade can't reach it. Pinned via LazyVars to our
        -- line-area rect, so dragging or resizing the window carries the
        -- feed along automatically. Destroyed in our `OnDestroy`.
        self.ChatFeedInterface = ChatFeedInterface(parent, self)

        -- Override the lines panel's name-click hook to set the chat
        -- recipient and re-focus the edit box. `OnCameraClicked` keeps the
        -- panel's default behaviour (jump the world camera). Ignore clicks
        -- on your own name — whispering yourself is pointless and the
        -- picker would still route it as a private message.
        self.ChatLinesInterface.OnNameClicked = function(entry)
            if entry.ArmyID and entry.ArmyID ~= GetFocusArmy() then
                ChatController.SetRecipient(entry.ArmyID)
                self.ChatEditInterface:AcquireFocus()
            end
        end

        -- Reactive subscriptions use `LazyVarDerive` so each observer is a
        -- fresh LazyVar that reads from an upstream model field — setting
        -- our handler can never stomp another subscriber's (see the chat
        -- CLAUDE.md for the pattern).
        local model = ChatModel.GetSingleton()

        -- Window visibility → show / hide the frame, gate the idle timer.
        -- `SetNeedsFrameUpdate(true)` is what makes `OnFrame` actually fire;
        -- toggling it with visibility avoids ticking while hidden. Showing
        -- the window stamps `LastActivity` so the user gets a fresh full
        -- `fade_time` window before auto-close kicks in.
        self.WindowVisibleObserver = self.Trash:Add(
            LazyVarDerive(
                model.WindowVisible,
                function(lv)
                    if lv() then
                        self:Show()
                        self.ChatEditInterface:AcquireFocus()
                        ChatController.NotifyActivity()
                        self:SetNeedsFrameUpdate(true)
                    else
                        self:SetNeedsFrameUpdate(false)
                        self.ChatEditInterface:AbandonFocus()
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
        self.DragHandleControlMap = {
            tl = { self.DragTL },
            tr = { self.DragTR },
            bl = { self.DragBL },
            br = { self.DragBR },
            mr = { self.DragBR, self.DragTR },
            ml = { self.DragBL, self.DragTL },
            tm = { self.DragTL, self.DragTR },
            bm = { self.DragBL, self.DragBR },
        }

        -- Window calls the instance field `self.RolloverHandler(control, ...)`
        -- as a plain function (no method syntax) — install a thin forwarder
        -- here that binds `self` and dispatches to `OnRollover`. The class
        -- method deliberately uses a different name: sharing `RolloverHandler`
        -- would let the instance field shadow the class method, so
        -- `self:RolloverHandler(...)` from within the forwarder would recurse.
        self.RolloverHandler = function(_, event, xControl, yControl, cursor, controlID)
            self:OnRollover(event, xControl, yControl, cursor, controlID)
        end
    end,

    --- Handles a rollover / press event delivered through the Window's
    --- resize bitmaps (tl / tm / tr / ml / mr / bl / bm / br). Lights the
    --- matching corner grip(s) and hands off to `StartSizing` on press.
    ---@param self UIChatInterface
    ---@param event KeyEvent
    ---@param xControl? LazyVar<number>  # Left or Right LazyVar to drive on drag
    ---@param yControl? LazyVar<number>  # Top or Bottom LazyVar to drive on drag
    ---@param cursor string               # cursor-kind id (e.g. 'NW_SE')
    ---@param controlID string            # id of the resize bitmap (e.g. 'tl')
    OnRollover = function(self, event, xControl, yControl, cursor, controlID)
        if self._lockSize or self._sizeLock then return end
        local grips = self.DragHandleControlMap[controlID]
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
            self:OnResizeSet()
        end

        Layouter(self.ResetPositionBtn)
            :LeftOf(self._configBtn)
            :End()
    end,

    ---@param self UIChatInterface
    ---@param parent Control
    __post_init = function(self, parent)
        local client = self:GetClientGroup()

        -- Full width, flush with the bottom of the client area. The edit
        -- group derives its own height (see ChatEditInterface.__post_init).
        Layouter(self.ChatEditInterface)
            :AtLeftIn(self)
            :AtRightIn(self)
            :AtBottomIn(self, 6)
            :Height(19)
            :Over(client)
            :End()

        -- The lines panel fills the rest of the client area above the edit
        -- box. The scrollbar is its own concern — `ChatLinesInterface`
        -- reserves the space inside its right edge for the scrollbar
        -- widget, so the parent only has to allocate a single rect.
        local paddingHorizontal = 8
        local paddingVertical = 2
        Layouter(self.ChatLinesInterface)
            :AtTopIn(client, paddingVertical)
            :AtLeftIn(client, paddingHorizontal)
            :AtRightIn(client, paddingHorizontal)
            :AnchorToTop(self.ChatEditInterface, 4)
            :End()

        -- Now that the lines panel has a real rect, let it build its pool
        -- and wire its options observer (the initial fire reads the laid-
        -- out `Pool.Height()`).
        self.ChatLinesInterface:Initialize()

        -- Committed chat options → window-level concerns only. Pool sizing,
        -- font, and filter changes are owned by the lines panel; we just
        -- handle `win_alpha` here. `SetAlpha(_, true)` cascades so chrome,
        -- edit, and scrollbar all dim uniformly. The chat-line *text* is
        -- then forced back to full opacity by re-cascading from `Pool`
        -- (which only contains the line rows) — the scrollbar is a sibling
        -- of `Pool` on `ChatLinesInterface`, not a child, so this reset
        -- doesn't touch it. Net effect: text stays crisp at low alpha,
        -- everything else still fades.
        self.OptionsObserver = self.Trash:Add(
            LazyVarDerive(
                ChatConfigModel.GetSingleton().Committed,
                function(lv)
                    self:SetAlpha(lv().win_alpha or 1.0, true)
                    self.ChatLinesInterface.Pool:SetAlpha(1.0, true)
                end
            )
        )

        if Debug then
            self.DebugBG = Bitmap(self)
            self.DebugBG:SetSolidColor('40ff4040')
            self.DebugBG:DisableHitTest()
            Layouter(self.DebugBG):Fill(self):Over(self, 100):End()
        end
    end,

    ---------------------------------------------------------------------------
    -- Idle / fade timer
    ---------------------------------------------------------------------------

    --- Engine-driven frame tick. Only fires while `SetNeedsFrameUpdate(true)`
    --- is set; the visibility observer toggles that with the window so we
    --- don't tick while hidden. The timer is fully model-driven: any caller
    --- that wants to count as activity calls `ChatController.NotifyActivity()`
    --- to stamp `model.LastActivity`. Once the elapsed time since that stamp
    --- crosses `fade_time`, ask the controller to close — closing flips
    --- `model.WindowVisible`, which in turn disables further frame ticks.
    --- Pinning the title-bar checkbox short-circuits the check entirely so
    --- the user can keep the window up through long stretches of silence.
    ---@param self UIChatInterface
    ---@param delta number   # seconds since the last frame, unused (we read absolute time)
    OnFrame = function(self, delta)
        local model = ChatModel.GetSingleton()
        if model.Pinned() then return end
        local fadeTime = ChatConfigModel.GetOptions().fade_time or 15
        local elapsed = GetSystemTimeSeconds() - model.LastActivity()
        if elapsed >= fadeTime then
            ChatController.CloseWindow()
        end
    end,

    --- Engine-invoked when the user toggles the title-bar pin checkbox.
    --- Forwards to the controller, which writes `model.Pinned`. Refocuses
    --- the edit box because clicking the checkbox steals focus.
    ---@param self UIChatInterface
    ---@param checked boolean
    OnPinCheck = function(self, checked)
        ChatController.SetPinned(checked)
        self.ChatEditInterface:AcquireFocus()
    end,

    ---------------------------------------------------------------------------
    -- Window event hooks
    ---------------------------------------------------------------------------

    --- Fired continuously during a resize drag. Keep it cheap: just resize
    --- the pool and re-render against existing wraps.
    OnResize = function(self, width, height, firstFrame)
        ChatController.NotifyActivity()
        self.ChatLinesInterface:OnResizeLive()
    end,

    --- Fired when a resize drag ends. Rewrapping is expensive, so it only
    --- happens here rather than on every drag frame. Also snaps the corner
    --- grips back to their `up` texture — the RolloverHandler leaves them
    --- on `down` when StartSizing took over.
    OnResizeSet = function(self)
        ChatController.NotifyActivity()
        self.ChatLinesInterface:OnResizeFinished()
        self.DragTL:SetTexture(self.DragTL.textures.up)
        self.DragTR:SetTexture(self.DragTR.textures.up)
        self.DragBL:SetTexture(self.DragBL.textures.up)
        self.DragBR:SetTexture(self.DragBR.textures.up)
    end,

    --- Engine-invoked when the user finishes dragging the window. The drag
    --- handler steals focus mid-move, so re-acquire it so the user can keep
    --- typing without a second click on the edit box.
    OnMoveSet = function(self)
        ChatController.NotifyActivity()
        self.ChatEditInterface:AcquireFocus()
    end,

    --- Mouse wheel over the window scrolls the chat. `rotation` is in wheel
    --- units (usually ±120 per notch); one notch ≈ one line.
    OnMouseWheel = function(self, rotation)
        ChatController.NotifyActivity()
        self.ChatLinesInterface:ScrollLines(nil, -math.floor(rotation / 100))
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

    --- Tears down the sibling feed view (it lives outside our control tree
    --- so `Hide`/`Destroy` cascades don't reach it) and empties our trash
    --- bag — destroying every derived observer so no `OnDirty` can fire
    --- into a torn-down `self`.
    OnDestroy = function(self)
        if self.ChatFeedInterface then
            self.ChatFeedInterface:Destroy()
            self.ChatFeedInterface = nil
        end
        self.Trash:Destroy()
    end,
}

-------------------------------------------------------------------------------
--  Module-level singleton and standalone entry points.

---@type UIChatInterface | nil
local Instance = nil

--- Builds the chat window (and its sibling feed view) if they don't
--- already exist. Doesn't change visibility — `model.WindowVisible`
--- starts `false`, so the chat stays hidden until something flips it.
---
--- `ChatController.Init` calls this at game start so the feed is alive
--- in time to surface messages that arrive before the user first opens
--- the chat dialog. Open / Toggle also call it as a safety net for
--- entry points that bypass `Init` (mods, debug helpers).
function EnsureInstance()
    if not Instance then
        Instance = ChatInterface(GetFrame(0))
    end
end

--- Shows the chat window, creating it on first call.
function Open()
    EnsureInstance()
    ChatController.OpenWindow()
end

--- Hides the chat window (the instance is kept around).
function Close()
    ChatController.CloseWindow()
end

--- Toggles the chat window, creating it on first call.
function Toggle()
    EnsureInstance()
    ChatController.ToggleWindow()
end

--- Scrolls the chat feed by `delta` rows (negative = toward older messages).
--- No-op if the window has never been opened.
---@param delta number
function ScrollLines(delta)
    if Instance then
        Instance.ChatLinesInterface:ScrollLines(nil, delta)
    end
end

--- Scrolls the chat feed by `delta` pages (negative = toward older messages).
--- No-op if the window has never been opened.
---@param delta number
function ScrollPages(delta)
    if Instance then
        Instance.ChatLinesInterface:ScrollPages(nil, delta)
    end
end

--- Snaps the chat feed to the oldest visible entry. No-op if the window
--- has never been opened. Not bound to a default key — the Edit control
--- consumes Home for caret navigation before `OnNonTextKeyPressed` fires
--- — but exposed for keymap entries (`UI_Lua import("/lua/ui/game/chat/ChatInterface.lua").ScrollToTop()`)
--- and for mods that want a programmatic jump-to-top.
function ScrollToTop()
    if Instance then
        Instance.ChatLinesInterface:ScrollSetTop(nil, 1)
    end
end

--- Two-stage "jump to bottom" handler. If the chat is already pinned to
--- the newest entry, collapses the window — same intent as the legacy
--- "press End again to dismiss" feel without sneaking in a separate
--- toggle. Otherwise snaps to the bottom. No-op if the window has never
--- been opened. Not bound to a default key (see `ScrollToTop` for the
--- reason); exposed for keymap entries and mods.
function ScrollToBottomOrClose()
    if not Instance then return end
    local lines = Instance.ChatLinesInterface
    if lines:IsAtBottom() then
        ChatController.CloseWindow()
    else
        lines:ScrollToBottom()
    end
end

--- Opens the chat window (creating it on first call) and scrolls the feed
--- by `delta` rows. Entry point for the global PgUp / PgDn key bindings —
--- so pressing PgUp with the window hidden both reveals it and starts
--- scrolling toward older messages.
---@param delta number
function OpenAndScrollLines(delta)
    Open()
    ScrollLines(delta)
end

-------------------------------------------------------------------------------
--#region Debugging

--- Called by the module manager when this module is reloaded.
---@param newModule any
function __moduleinfo.OnReload(newModule)
    newModule.Open()
end

--- Called by the module manager when this module becomes dirty.
function __moduleinfo.OnDirty()
    if Instance then
        -- `OnDestroy` empties the trash bag, which in turn destroys every
        -- derived observer — no more `OnDirty` fires into a dead `self`.
        Instance:Destroy()
        Instance = nil
    end

    ForkThread(
        function()
            WaitFrames(2)
            import(__moduleinfo.name)
        end
    )
end

--#endregion
