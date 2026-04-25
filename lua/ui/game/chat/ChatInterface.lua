local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")

local Window = import("/lua/maui/window.lua").Window
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local Button = import("/lua/maui/button.lua").Button

local ChatLinesInterface = import("/lua/ui/game/chat/ChatLinesInterface.lua").ChatLinesInterface
local ChatEditInterface = import("/lua/ui/game/chat/ChatEditInterface.lua").ChatEditInterface

local ChatModel = import("/lua/ui/game/chat/ChatModel.lua")
local ChatController = import("/lua/ui/game/chat/ChatController.lua")
local ChatConfigModel = import("/lua/ui/game/chat/config/ChatConfigModel.lua")

local LazyVarDerive = import("/lua/lazyvar.lua").Derive

local Layouter = LayoutHelpers.ReusedLayoutFor

--- Flip to `true` to overlay a semi-transparent coloured bitmap over the
--- control so its bounds are visible at runtime. Each chat interface uses a
--- distinct colour so overlapping controls can be told apart at a glance.
local Debug = false

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
---@field Lines                 UIChatLinesInterface          # the wrapped panel containing line rows + scrollbar
---@field Edit                  UIChatEditInterface
---@field DragTL                Bitmap                        # top-left corner resize grip
---@field DragTR                Bitmap                        # top-right corner resize grip
---@field DragBL                Bitmap                        # bottom-left corner resize grip
---@field DragBR                Bitmap                        # bottom-right corner resize grip
---@field DragHandleControlMap  table<string, Bitmap[]>       # resize-bitmap id → grips to highlight
---@field ResetPositionBtn      Button                        # titlebar button that restores DefaultRect
---@field WindowVisibleObserver LazyVar<boolean>              # derived from ChatModel.WindowVisible
---@field OptionsObserver       LazyVar<UIChatOptions>        # derived from ChatConfigModel.Committed (window-level options only)
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

        -- The lines panel and edit area. Both are laid out in `__post_init`
        -- once the client area has a real size to anchor against.
        self.Lines = ChatLinesInterface(client)
        self.Edit = ChatEditInterface(client)

        -- Override the lines panel's name-click hook to set the chat
        -- recipient and re-focus the edit box. `OnCameraClicked` keeps the
        -- panel's default behaviour (jump the world camera). Ignore clicks
        -- on your own name — whispering yourself is pointless and the
        -- picker would still route it as a private message.
        self.Lines.OnNameClicked = function(entry)
            if entry.ArmyID and entry.ArmyID ~= GetFocusArmy() then
                ChatController.SetRecipient(entry.ArmyID)
                self.Edit:AcquireFocus()
            end
        end

        -- Reactive subscriptions use `LazyVarDerive` so each observer is a
        -- fresh LazyVar that reads from an upstream model field — setting
        -- our handler can never stomp another subscriber's (see the chat
        -- CLAUDE.md for the pattern).
        local model = ChatModel.GetSingleton()

        -- Window visibility → show / hide the frame.
        self.WindowVisibleObserver = self.Trash:Add(
            LazyVarDerive(
                model.WindowVisible,
                function(lv)
                    if lv() then
                        self:Show()
                        self.Edit:AcquireFocus()
                    else
                        self.Edit:AbandonFocus()
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
            :Height(22)
            :Over(client)
            :End()

        -- The lines panel fills the rest of the client area above the edit
        -- box. The scrollbar is its own concern — `ChatLinesInterface`
        -- reserves the space inside its right edge for the scrollbar
        -- widget, so the parent only has to allocate a single rect.
        Layouter(self.Lines)
            :AtLeftIn(client, pad)
            :AtRightIn(client, pad)
            :AtTopIn(client, pad)
            :AnchorToTop(self.Edit, 12)
            :End()

        -- Committed chat options → window-level concerns only. Pool sizing,
        -- font, and filter changes are owned by the lines panel; we just
        -- handle `win_alpha` here. `SetAlpha(_, true)` cascades so chrome,
        -- lines, edit, and scrollbar all dim uniformly.
        self.OptionsObserver = self.Trash:Add(
            LazyVarDerive(
                ChatConfigModel.GetSingleton().Committed,
                function(lv)
                    self:SetAlpha(lv().win_alpha or 1.0, true)
                end
            )
        )
    end,

    ---------------------------------------------------------------------------
    -- Window event hooks
    ---------------------------------------------------------------------------

    --- Fired continuously during a resize drag. Keep it cheap: just resize
    --- the pool and re-render against existing wraps.
    OnResize = function(self, width, height, firstFrame)
        self.Lines:OnResizeLive()
    end,

    --- Fired when a resize drag ends. Rewrapping is expensive, so it only
    --- happens here rather than on every drag frame. Also snaps the corner
    --- grips back to their `up` texture — the RolloverHandler leaves them
    --- on `down` when StartSizing took over.
    OnResizeSet = function(self)
        self.Lines:OnResizeFinished()
        self.DragTL:SetTexture(self.DragTL.textures.up)
        self.DragTR:SetTexture(self.DragTR.textures.up)
        self.DragBL:SetTexture(self.DragBL.textures.up)
        self.DragBR:SetTexture(self.DragBR.textures.up)
    end,

    --- Engine-invoked when the user finishes dragging the window. The drag
    --- handler steals focus mid-move, so re-acquire it so the user can keep
    --- typing without a second click on the edit box.
    OnMoveSet = function(self)
        self.Edit:AcquireFocus()
    end,

    --- Mouse wheel over the window scrolls the chat. `rotation` is in wheel
    --- units (usually ±120 per notch); one notch ≈ one line.
    OnMouseWheel = function(self, rotation)
        self.Lines:ScrollLines(nil, -math.floor(rotation / 100))
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
        Instance.Lines:ScrollLines(nil, delta)
    end
end

--- Scrolls the chat feed by `delta` pages (negative = toward older messages).
--- No-op if the window has never been opened.
---@param delta number
function ScrollPages(delta)
    if Instance then
        Instance.Lines:ScrollPages(nil, delta)
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
