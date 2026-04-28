local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Tooltip = import("/lua/ui/game/tooltip.lua")

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

local Debug = false

--- Skin textures for the chat window frame. `SkinnableFile` resolves
--- against the current skin on each read, so the bitmaps follow skin
--- changes (unlike `UIFile`, which freezes the path at module-load time).
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

--- Corner grip textures for the four resize handles. Each handle carries
--- `up`/`over`/`down` states the `RolloverHandler` swaps through.
---
--- The concatenated path strings widen to `string` rather than the
--- language server's `FileName` alias that `SkinnableFile` annotates.
---@diagnostic disable: param-type-mismatch
local function DragHandleTextures(corner)
    return {
        up   = UIUtil.SkinnableFile('/game/drag-handle/drag-handle-' .. corner .. '_btn_up.dds'),
        over = UIUtil.SkinnableFile('/game/drag-handle/drag-handle-' .. corner .. '_btn_over.dds'),
        down = UIUtil.SkinnableFile('/game/drag-handle/drag-handle-' .. corner .. '_btn_down.dds'),
    }
end
---@diagnostic enable: param-type-mismatch

local DefaultRect = { Left = 8, Top = 460, Right = 430, Bottom = 720 }

-------------------------------------------------------------------------------
-- The main chat window: a draggable, resizable frame hosting a
-- `ChatLinesInterface` (line pool + scrollbar) and a `ChatEditInterface`
-- (input area). The window owns chrome, visibility, and window-level
-- options (`win_alpha`); pool sizing, wrapping, scrolling, and filtering
-- live on `ChatLinesInterface`.

--- Main chat window: chrome, drag/resize handles, idle-fade timer, sibling feed; hosts lines + edit panels.
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
---@field PinnedObserver        LazyVar<boolean>              # derived from ChatModel.Pinned; swaps the pin tooltip
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

        self.Trash = TrashBag()

        self.ChatLinesInterface = ChatLinesInterface(self)
        self.ChatEditInterface = ChatEditInterface(self)

        -- Feed view: sibling on the parent frame so our `Show`/`Hide`
        -- cascade can't reach it. Pinned to our line-area rect via LazyVars
        -- so drag / resize carries it along.
        self.ChatFeedInterface = ChatFeedInterface(parent, self)

        -- Whispering yourself is pointless; ignore clicks on your own name.
        self.ChatLinesInterface.OnNameClicked = function(entry)
            if entry.ArmyID and entry.ArmyID ~= GetFocusArmy() then
                ChatController.SetRecipient(entry.ArmyID)
                self.ChatEditInterface:AcquireFocus()
            end
        end

        local model = ChatModel.GetSingleton()

        -- `SetNeedsFrameUpdate` toggles in lockstep with visibility so we
        -- don't tick while hidden. Showing stamps `LastActivity` so the
        -- user gets a full `fade_time` window before auto-close fires.
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

        -- Pin tooltip wording swaps reactively so it matches the next
        -- click's effect. `_closeBtn` / `_configBtn` / `_pinBtn` are
        -- owned by `Window` but not in its declared class fields.
        ---@diagnostic disable: undefined-field
        Tooltip.AddButtonTooltip(self._closeBtn, 'chat_close')
        Tooltip.AddButtonTooltip(self._configBtn, 'chat_config')
        self.PinnedObserver = self.Trash:Add(
            LazyVarDerive(
                model.Pinned,
                function(lv)
                    Tooltip.AddCheckboxTooltip(self._pinBtn, lv() and 'chat_pinned' or 'chat_pin')
                end
            )
        )
        ---@diagnostic enable: undefined-field
    end,

    --- Creates the four corner resize grips and wires `RolloverHandler` to
    --- swap their textures on hover/press. Grips disable hit-test so
    --- resize events still reach the Window's own resize bitmaps.
    ---@param self UIChatInterface
    SetupDragHandles = function(self)
        self.DragTL = Bitmap(self)
        self.DragTR = Bitmap(self)
        self.DragBL = Bitmap(self)
        self.DragBR = Bitmap(self)

        self.DragTL.textures = DragHandleTextures('ul')
        self.DragTR.textures = DragHandleTextures('ur')
        self.DragBL.textures = DragHandleTextures('ll')
        self.DragBR.textures = DragHandleTextures('lr')

        -- Seed with the skinnable texture, not a frozen `UIFile` path.
        -- Otherwise the bitmaps stay on the module-load skin until the
        -- first hover-exit hands `SetTexture` the live value.
        for _, grip in { self.DragTL, self.DragTR, self.DragBL, self.DragBR } do
            grip:DisableHitTest()
            grip:SetTexture(grip.textures.up)
        end

        Layouter(self.DragTL):AtLeftTopIn(self, -26, -8):Over(self, 5):End()
        Layouter(self.DragTR):AtRightTopIn(self, -22, -8):Over(self, 5):End()
        Layouter(self.DragBL):AtLeftBottomIn(self, -26, -8):Over(self, 5):End()
        Layouter(self.DragBR):AtRightBottomIn(self, -22, -8):Over(self, 5):End()

        -- Side edges light both adjacent corners.
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

        -- Window calls `self.RolloverHandler(control, ...)` as a plain
        -- function (no method syntax). The class method is named differently
        -- (`OnRollover`). Sharing the name would shadow the class method
        -- and recurse.
        self.RolloverHandler = function(_, event, xControl, yControl, cursor, controlID)
            self:OnRollover(event, xControl, yControl, cursor, controlID)
        end
    end,

    --- Handles a rollover/press from the Window's resize bitmaps. Lights
    --- the matching corner grip(s) and hands off to `StartSizing` on press.
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

    --- Creates the reset-position button left of `_configBtn`. Clicking
    --- snaps every rect edge to `DefaultRect` and persists the location.
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

        Tooltip.AddButtonTooltip(self.ResetPositionBtn, 'chat_reset')
    end,

    ---@param self UIChatInterface
    ---@param parent Control
    __post_init = function(self, parent)
        local client = self:GetClientGroup()

        Layouter(self.ChatEditInterface)
            :AtLeftIn(self)
            :AtRightIn(self)
            :AtBottomIn(self, 6)
            :Height(19)
            :Over(client)
            :End()

        local paddingHorizontal = 8
        local paddingVertical = 2
        Layouter(self.ChatLinesInterface)
            :AtTopIn(client, paddingVertical)
            :AtLeftIn(client, paddingHorizontal)
            :AtRightIn(client, paddingHorizontal)
            :AnchorToTop(self.ChatEditInterface, 4)
            :End()

        -- Build the pool now that we have a real rect. `Initialize`
        -- reads `Pool.Height()` for fixed-count sizing.
        self.ChatLinesInterface:Initialize()

        -- Window-level options only (`win_alpha`). `SetAlpha(_, true)`
        -- cascades to chrome / edit / scrollbar. Re-cascading 1.0 from
        -- `Pool` keeps the line text crisp. `Pool` doesn't contain the
        -- scrollbar (it's a sibling), so the reset stays scoped.
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

    --- Idle-fade timer. Closes the window once the user has been idle for
    --- `fade_time` seconds. While `Pinned` is true the check is skipped.
    ---@param self UIChatInterface
    ---@param delta number   # unused, we read absolute time
    OnFrame = function(self, delta)
        -- Only fires while `SetNeedsFrameUpdate(true)` is set. The
        -- visibility observer toggles that with the window.
        local model = ChatModel.GetSingleton()
        if model.Pinned() then return end
        local fadeTime = ChatConfigModel.GetOptions().fade_time or 15
        local elapsed = GetSystemTimeSeconds() - model.LastActivity()
        if elapsed >= fadeTime then
            ChatController.CloseWindow()
        end
    end,

    --- Title-bar pin checkbox handler.
    ---@param self UIChatInterface
    ---@param checked boolean
    OnPinCheck = function(self, checked)
        -- Refocuses the edit box because clicking the checkbox steals
        -- focus.
        ChatController.SetPinned(checked)
        self.ChatEditInterface:AcquireFocus()
    end,

    ---------------------------------------------------------------------------
    -- Window event hooks
    ---------------------------------------------------------------------------

    --- Per-frame during a resize drag.
    OnResize = function(self, width, height, firstFrame)
        -- Resizes the pool only. Rewrap happens once on `OnResizeSet`.
        ChatController.NotifyActivity()
        self.ChatLinesInterface:OnResizeLive()
    end,

    --- Resize finished. Snaps grips back to `up`.
    OnResizeSet = function(self)
        -- `StartSizing` takes over from RolloverHandler so the grips
        -- would otherwise stay on `down`.
        ChatController.NotifyActivity()
        self.ChatLinesInterface:OnResizeFinished()
        self.DragTL:SetTexture(self.DragTL.textures.up)
        self.DragTR:SetTexture(self.DragTR.textures.up)
        self.DragBL:SetTexture(self.DragBL.textures.up)
        self.DragBR:SetTexture(self.DragBR.textures.up)
    end,

    --- Per-frame during a title-bar drag.
    OnMove = function(self)
        -- Stamps activity so a long drag can't trip the idle auto-close.
        ChatController.NotifyActivity()
    end,

    --- Drag finished. Re-acquires edit-box focus that the drag handler stole.
    OnMoveSet = function(self)
        ChatController.NotifyActivity()
        self.ChatEditInterface:AcquireFocus()
    end,

    --- `rotation` is in wheel units (usually ±120 per notch).
    OnMouseWheel = function(self, rotation)
        ChatController.NotifyActivity()
        self.ChatLinesInterface:ScrollLines(nil, -math.floor(rotation / 100))
    end,

    --- Title-bar close button. Routes through the controller so the model is
    --- the source of truth for visibility.
    OnClose = function(self)
        ChatController.CloseWindow()
    end,

    --- Title-bar config button. Toggles the chat options dialog.
    OnConfigClick = function(self)
        import("/lua/ui/game/chat/config/ChatConfigInterface.lua").Toggle()
    end,

    --- Tears down the sibling feed and empties the trash bag.
    OnDestroy = function(self)
        -- The feed lives outside our control tree, so a Destroy cascade
        -- doesn't reach it.
        if self.ChatFeedInterface then
            self.ChatFeedInterface:Destroy()
            self.ChatFeedInterface = nil
        end
        self.Trash:Destroy()
    end,
}

-------------------------------------------------------------------------------
--  Module-level singleton and standalone entry points.

--- Singleton handle; nil until `EnsureInstance` builds the window for the first time.
---@type UIChatInterface | nil
local Instance = nil

--- Builds the chat window and its sibling feed if they don't already
--- exist. Does not change visibility (`model.WindowVisible` starts false).
--- `ChatController.Init` calls this at game start so the feed is alive
--- before the user opens the dialog.
function EnsureInstance()
    if not Instance then
        Instance = ChatInterface(GetFrame(0))
    end
end

--- Standalone entry point: ensures the window exists and shows it.
function Open()
    EnsureInstance()
    ChatController.OpenWindow()
end

--- Standalone entry point: hides the chat window if it exists.
function Close()
    ChatController.CloseWindow()
end

--- Standalone entry point: ensures the window exists and flips its visibility.
function Toggle()
    EnsureInstance()
    ChatController.ToggleWindow()
end

--- Scrolls the line pool by `delta` rows; no-op if the window hasn't been built yet.
---@param delta number   # negative = toward older messages
function ScrollLines(delta)
    if Instance then
        Instance.ChatLinesInterface:ScrollLines(nil, delta)
    end
end

--- Scrolls the line pool by `delta` pages; no-op if the window hasn't been built yet.
---@param delta number   # negative = toward older messages
function ScrollPages(delta)
    if Instance then
        Instance.ChatLinesInterface:ScrollPages(nil, delta)
    end
end

--- Jumps to the oldest visible entry. Exposed for keymap entries and mods.
function ScrollToTop()
    -- Not bound to a default key because Edit consumes Home for caret
    -- nav before `OnNonTextKeyPressed` fires.
    if Instance then
        Instance.ChatLinesInterface:ScrollSetTop(nil, 1)
    end
end

--- Two-stage jump: snaps to bottom, or closes the window if already there.
--- Mirrors the legacy "press End again to dismiss" feel.
function ScrollToBottomOrClose()
    if not Instance then return end
    local lines = Instance.ChatLinesInterface
    if lines:IsAtBottom() then
        ChatController.CloseWindow()
    else
        lines:ScrollToBottom()
    end
end

--- Entry point for global PgUp / PgDn bindings: opens the window if needed
--- and scrolls in one step.
---@param delta number
function OpenAndScrollLines(delta)
    Open()
    ScrollLines(delta)
end

-------------------------------------------------------------------------------
--#region Debugging

--- Hot-reload hook: reopens the window on the freshly loaded module.
---@param newModule any
function __moduleinfo.OnReload(newModule)
    newModule.Open()
end

--- Hot-reload hook: tears down the old instance and re-imports this module.
function __moduleinfo.OnDirty()
    if Instance then
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
