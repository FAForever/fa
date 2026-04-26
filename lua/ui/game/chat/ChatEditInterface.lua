
local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Tooltip = import("/lua/ui/game/tooltip.lua")

local Group = import("/lua/maui/group.lua").Group
local Edit = import("/lua/maui/edit.lua").Edit
local Button = import("/lua/maui/button.lua").Button
local Checkbox = import("/lua/maui/checkbox.lua").Checkbox
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap

local ChatModel = import("/lua/ui/game/chat/ChatModel.lua")
local ChatController = import("/lua/ui/game/chat/ChatController.lua")
local ChatCompletion = import("/lua/ui/game/chat/ChatCompletion.lua")
local ChatUtils = import("/lua/ui/game/chat/ChatUtils.lua")
local ChatListInterface = import("/lua/ui/game/chat/ChatListInterface.lua").ChatListInterface
local ChatCommandHintInterface = import("/lua/ui/game/chat/ChatCommandHintInterface.lua").ChatCommandHintInterface

local LazyVarDerive = import("/lua/lazyvar.lua").Derive

local Layouter = LayoutHelpers.ReusedLayoutFor

--- Flip to `true` to overlay a semi-transparent coloured bitmap over the
--- control so its bounds are visible at runtime. Each chat interface uses a
--- distinct colour so overlapping controls can be told apart at a glance.
local Debug = false

--- Cap on the command-history ring (newest at the tail). Older entries
--- are dropped when the buffer overflows. 32 is comfortably more than the
--- handful a typical session generates while staying small enough that
--- linear walks stay free.
local MaxCommandHistorySize = 32

-------------------------------------------------------------------------------
-- The chat input area: a chat-bubble button, a recipient label, and an edit
-- box. Pressing Enter dispatches the text to the controller. Clicking the
-- chat-bubble button or the label opens the recipient picker (ChatListInterface).

---@class UIChatEditInterface : Group
---@field Trash             TrashBag                          # owns every derived subscription-LazyVar
---@field ChatBubble        Button
---@field RecipientLabel    Text
---@field EditBox           Edit
---@field CamCheckbox       Checkbox                          # toggle: attach world-camera state to the next message
---@field ChatListInterface UIChatListInterface | nil
---@field ChatCommandHintInterface UIChatCommandHintInterface | nil
---@field RecipientObserver LazyVar<UIChatRecipient>          # derived from ChatModel.Recipient
---@field Completion        UIChatCompletion | nil            # active Tab-cycle record, reset on text change
---@field SuppressCompletionReset boolean                     # true while our own SetText is running
---@field CommandHistory    string[]                          # ring of previously-sent message texts (oldest first); recalled via Up / Down when the hint is closed
---@field RecallEntry       number | nil                      # cursor into `CommandHistory` for the active recall walk; nil when no walk is in progress
---@field DebugBG?          Bitmap                            # semi-transparent overlay shown when `Debug` is true
ChatEditInterface = ClassUI(Group) {

    ---@param self UIChatEditInterface
    ---@param parent Control
    __init = function(self, parent)
        Group.__init(self, parent, "ChatEditInterface")

        -- Single trash bag for everything we allocate that needs explicit
        -- destruction — currently just the derived observer LazyVars.
        -- Emptied in `OnDestroy`.
        self.Trash = TrashBag()

        self.Completion = nil
        self.SuppressCompletionReset = false
        self.CommandHistory = {}
        self.RecallEntry = nil

        self.ChatBubble = Button(self,
            UIUtil.UIFile('/game/chat-box_btn/radio_btn_up.dds'),
            UIUtil.UIFile('/game/chat-box_btn/radio_btn_down.dds'),
            UIUtil.UIFile('/game/chat-box_btn/radio_btn_over.dds'),
            UIUtil.UIFile('/game/chat-box_btn/radio_btn_dis.dds'))
        self.ChatBubble.OnClick = function()
            self:ToggleList()
        end

        self.RecipientLabel = UIUtil.CreateText(self, "To All:", 14, 'Arial')
        self.RecipientLabel:SetDropShadow(true)

        -- Clicking the label also opens the recipient picker.
        self.RecipientLabel.HandleEvent = function(_, event)
            if event.Type == 'ButtonPress' then
                self:ToggleList()
            end
        end

        -- Camera-attach toggle. When checked, the next Send call snapshots
        -- the world camera and ships it on the message; recipients can click
        -- the resulting cam-icon on their chat line to jump to the view.
        self.CamCheckbox = Checkbox(self,
            UIUtil.SkinnableFile('/game/camera-btn/pinned_btn_up.dds'),
            UIUtil.SkinnableFile('/game/camera-btn/pinned_btn_down.dds'),
            UIUtil.SkinnableFile('/game/camera-btn/pinned_btn_over.dds'),
            UIUtil.SkinnableFile('/game/camera-btn/pinned_btn_over.dds'),
            UIUtil.SkinnableFile('/game/camera-btn/pinned_btn_dis.dds'),
            UIUtil.SkinnableFile('/game/camera-btn/pinned_btn_dis.dds'))
        Tooltip.AddCheckboxTooltip(self.CamCheckbox, 'chat_camera')

        self.EditBox = Edit(self)

        -- Placeholder bounds so that `SetupEditStd` below, which internally
        -- calls `SetFont` and reads the control's Left/Right, can evaluate
        -- the layout without tripping the default circular Left/Right/Width
        -- chain set up by `Control.ResetLayout`. `__post_init` replaces these
        -- with the real layout.
        Layouter(self.EditBox)
            :Left(0)
            :Top(0)
            :Width(200)
            :Height(20)
            :End()

        UIUtil.SetupEditStd(self.EditBox,
            "ff00ff00", nil, "ffffffff",
            UIUtil.highlightColor, UIUtil.bodyFont, 14, ChatUtils.MaxMessageLength)
        self.EditBox:SetDropShadow(true)
        self.EditBox:ShowBackground(false)
        self.EditBox:SetText('')

        -- Pressing Enter on an empty edit box closes the window — matches
        -- the legacy `chat.lua` shortcut where Enter serves as both "send"
        -- and "dismiss" depending on whether there's anything to send.
        -- Successful sends are appended to the command-history ring so
        -- Up / Down can recall them when the hint isn't open.
        self.EditBox.OnEnterPressed = function(_, text)
            ChatController.NotifyActivity()
            if text and text ~= '' then
                ChatController.Send(text, self.CamCheckbox:IsChecked())
                self:PushHistory(text)
            else
                ChatController.CloseWindow()
            end
            self:CloseCommandHint()
        end

        -- Drive the command-hint popup from the edit-box contents, and drop
        -- any in-flight Tab-completion cycle whenever the text changes from
        -- something other than our own `ApplyCompletion` call.
        self.EditBox.OnTextChanged = function(_, newText, _)
            ChatController.NotifyActivity()
            self:RefreshCommandHint(newText or '')
            if not self.SuppressCompletionReset then
                self.Completion = nil
            end
        end

        -- Tab runs completion (commands when text starts with '/' and the
        -- caret is in the first token, player nicknames otherwise). Repeat
        -- presses cycle through candidates; any other keystroke resets the
        -- cycle via `OnTextChanged`. `OnCharPressed` fires before insertion,
        -- so the `>=` beep catches the keystroke the cap is about to reject.
        self.EditBox.OnCharPressed = function(edit, charcode)
            if charcode == UIUtil.VK_TAB then
                self:HandleTabCompletion()
                return true
            end
            if STR_Utf8Len(edit:GetText()) >= edit:GetMaxChars() then
                PlaySound(Sound({ Cue = 'UI_Menu_Error_01', Bank = 'Interface' }))
            end
        end

        -- Escape priorities: (1) close an open command hint, (2) clear any
        -- text, (3) close the chat window.
        self.EditBox.OnEscPressed = function(_, text)
            if self.ChatCommandHintInterface then
                self:CloseCommandHint()
                return true
            end
            if text and text ~= '' then
                return false  -- let the engine clear the text box
            end
            ChatController.CloseWindow()
            return true
        end

        -- Page Up / Page Down scroll the chat feed. Three modes per key:
        --   * no modifier → 10 rows (page-ish)
        --   * Shift       → 1 row (fine grain)
        --   * Ctrl        → jump to the extreme; `Ctrl+PgDn` while already
        --                   at the bottom collapses the window.
        -- Matches the legacy chat.lua page-key binding so muscle memory
        -- carries over, with `Ctrl` covering the jump-to-extreme case that
        -- Home / End would normally serve — those are consumed by the Edit
        -- control for caret navigation before they reach this handler, so
        -- `OnNonTextKeyPressed` never sees them.
        -- Up / Down cycle the command-hint selection while the hint is open.
        -- Lazy import of ChatInterface avoids the import cycle: ChatInterface
        -- imports this module at load time, so the reverse edge has to defer.
        ---@param keycode number     # OS-level VK_* code; compare against `UIUtil.VK_*`
        ---@param event KeyEvent     # full input-event payload; modifiers live at `event.Modifiers`
        self.EditBox.OnNonTextKeyPressed = function(_, keycode, event)
            ChatController.NotifyActivity()
            local chatInterface = import("/lua/ui/game/chat/ChatInterface.lua")
            local mods = event and event.Modifiers
            local ctrl = mods and mods.Ctrl
            local step = (mods and mods.Shift) and 1 or 10
            if keycode == UIUtil.VK_PRIOR then
                if ctrl then
                    chatInterface.ScrollToTop()
                else
                    chatInterface.ScrollLines(-step)
                end
            elseif keycode == UIUtil.VK_NEXT then
                if ctrl then
                    chatInterface.ScrollToBottomOrClose()
                else
                    chatInterface.ScrollLines(step)
                end
            elseif keycode == UIUtil.VK_UP then
                -- Hint open → cycle the selection; closed → walk back
                -- through the command-history ring, oldest first.
                if self.ChatCommandHintInterface then
                    self.ChatCommandHintInterface:SelectNext()
                else
                    self:RecallPrevious()
                end
            elseif keycode == UIUtil.VK_DOWN then
                if self.ChatCommandHintInterface then
                    self.ChatCommandHintInterface:SelectPrev()
                else
                    self:RecallNext()
                end
            end
        end

        -- Keep the label in sync with the model. `LazyVarDerive` gives us a
        -- fresh per-subscriber LazyVar so we don't stomp any other observer
        -- of `model.Recipient` (see the chat CLAUDE.md for the pattern).
        local model = ChatModel.GetSingleton()
        self.RecipientObserver = self.Trash:Add(LazyVarDerive(model.Recipient, function(lv)
            self:RefreshRecipient(lv())
        end))
    end,

    ---@param self UIChatEditInterface
    ---@param parent Control
    __post_init = function(self, parent)
        Layouter(self.ChatBubble)
            :AtLeftIn(self, 6)
            :AtVerticalCenterIn(self)
            :End()

        Layouter(self.RecipientLabel)
            :AnchorToRight(self.ChatBubble, 6)
            :AtVerticalCenterIn(self)
            :End()

        -- Camera-attach toggle pinned to the right edge so the edit box can
        -- claim the remaining width.
        Layouter(self.CamCheckbox)
            :AtRightIn(self, 12)
            :AtVerticalCenterIn(self, -2)
            :End()

        -- Width must be re-derived from the now-anchored Left/Right.
        -- Without this it stays pinned at the literal `:Width(200)` placeholder
        -- set in `__init` (needed there so `SetupEditStd` can read the layout
        -- without tripping the default circular `Width = Right - Left` chain),
        -- and the visible typing area gets capped at 200 px regardless of
        -- where `Right` actually anchors — so the text box visibly fails to
        -- extend out toward the camera checkbox at higher UI scales or wider
        -- windows.
        Layouter(self.EditBox)
            :AnchorToRight(self.RecipientLabel, 4)
            :AnchorToLeft(self.CamCheckbox, 4)
            :AtVerticalCenterIn(self)
            :ResetWidth()  -- drop the `:Width(200)` from `__init`
            :Height(function() return self.EditBox:GetFontHeight() end)
            :End()

        if Debug then
            self.DebugBG = Bitmap(self)
            self.DebugBG:SetSolidColor('40ff40ff')
            self.DebugBG:DisableHitTest()
            Layouter(self.DebugBG):Fill(self):Over(self, 100):End()
        end
    end,

    --- Entry point for the Tab key. When the command hint is open, Tab
    --- commits the currently-selected command into the edit box (mirroring
    --- a click on the hint row). Otherwise it runs the in-box completion
    --- cycle for nicknames. Plays the error cue when there is nothing to
    --- complete so the user isn't left wondering whether the key was handled.
    ---@param self UIChatEditInterface
    HandleTabCompletion = function(self)
        if self.ChatCommandHintInterface then
            local hint = self.ChatCommandHintInterface --[[@as UIChatCommandHintInterface]]
            local cmd = hint:GetSelected()
            if cmd then
                self.EditBox:SetText('/' .. cmd.Name .. ' ')
                self:AcquireFocus()
                return
            end
        end

        if self.Completion then
            local c = self.Completion
            c.Index = math.mod(c.Index, table.getn(c.Candidates)) + 1
            self:ApplyCompletion()
            return
        end

        local text = self.EditBox:GetText() or ''
        local caret = self.EditBox:GetCaretPosition()
        local completion = ChatCompletion.Compute(text, caret)
        if not completion then
            PlaySound(Sound({ Cue = 'UI_Menu_Error_01', Bank = 'Interface' }))
            return
        end
        self.Completion = completion
        self:ApplyCompletion()
    end,

    --- Writes the current candidate into the edit box at the recorded anchor,
    --- overwriting the consumed word. `SuppressCompletionReset` guards the
    --- `OnTextChanged` branch that would otherwise clear the cycle state as
    --- a side-effect of our own edit.
    ---@param self UIChatEditInterface
    ApplyCompletion = function(self)
        if not self.Completion then return end
        local c = self.Completion --[[@as UIChatCompletion]]

        local text = self.EditBox:GetText() or ''
        local totalLen = STR_Utf8Len(text)
        local tailStart = c.Anchor + c.Consume
        local before = c.Anchor > 0 and STR_Utf8SubString(text, 1, c.Anchor) or ''
        local after = tailStart < totalLen
            and STR_Utf8SubString(text, tailStart + 1, totalLen - tailStart)
            or ''
        local replacement = c.Candidates[c.Index] .. c.Suffix
        local replacementLen = STR_Utf8Len(replacement)
        local newText = before .. replacement .. after

        self.SuppressCompletionReset = true
        self.EditBox:SetText(newText)
        self.EditBox:SetCaretPosition(c.Anchor + replacementLen)
        self.SuppressCompletionReset = false

        -- Advance the consumed span to match what we just wrote so the next
        -- cycle overwrites exactly this candidate, not the original word.
        c.Consume = replacementLen
    end,

    ---------------------------------------------------------------------------
    -- Command history recall

    --- Appends a successfully-sent message to the command-history ring and
    --- resets any active recall walk so the next Up press starts at the
    --- newest entry. Trims the ring to `MaxCommandHistorySize`.
    ---@param self UIChatEditInterface
    ---@param text string
    PushHistory = function(self, text)
        table.insert(self.CommandHistory, text)
        while table.getn(self.CommandHistory) > MaxCommandHistorySize do
            table.remove(self.CommandHistory, 1)
        end
        self.RecallEntry = nil
    end,

    --- Walks back toward older entries. Empty history is a no-op; the first
    --- press lands on the newest entry, subsequent presses move one step
    --- earlier each time and clamp at the oldest.
    ---@param self UIChatEditInterface
    RecallPrevious = function(self)
        local count = table.getn(self.CommandHistory)
        if count == 0 then return end
        if self.RecallEntry then
            self.RecallEntry = math.max(self.RecallEntry - 1, 1)
        else
            self.RecallEntry = count
        end
        self:ApplyRecall()
    end,

    --- Walks forward toward newer entries. After the newest, `RecallEntry`
    --- resets to nil so the next Down press blanks the edit (matching the
    --- legacy "step past the end clears the line" feel). Empty history
    --- with no active recall is a no-op; with no active recall but a
    --- non-empty history, blanks the edit so users have a quick "wipe what
    --- I'm typing" gesture.
    ---@param self UIChatEditInterface
    RecallNext = function(self)
        local count = table.getn(self.CommandHistory)
        if count == 0 then return end
        if self.RecallEntry then
            self.RecallEntry = math.min(self.RecallEntry + 1, count)
            self:ApplyRecall()
            if self.RecallEntry == count then
                self.RecallEntry = nil
            end
        else
            self.EditBox:SetText('')
        end
    end,

    --- Writes the entry at `RecallEntry` into the edit box and parks the
    --- caret at the end. No-op if `RecallEntry` doesn't reference a real
    --- entry — guards against being called between a destructive history
    --- mutation and the next nav keystroke.
    ---@param self UIChatEditInterface
    ApplyRecall = function(self)
        local entry = self.CommandHistory[self.RecallEntry or 0]
        if not entry then return end
        self.EditBox:SetText(entry)
        self.EditBox:SetCaretPosition(STR_Utf8Len(entry))
    end,

    --- Shows or hides the command hint based on the current edit-box text.
    --- Only opens when the text transitions to exactly `/` — so closing the
    --- hint via Escape leaves it closed while the user keeps typing past the
    --- slash. An already-open hint keeps refreshing as long as text starts
    --- with `/`.
    ---@param self UIChatEditInterface
    ---@param text string
    RefreshCommandHint = function(self, text)
        if self.ChatCommandHintInterface then
            if string.sub(text, 1, 1) == '/' then
                self.ChatCommandHintInterface:Refresh(text)
            else
                self:CloseCommandHint()
            end
        elseif text == '/' then
            self:OpenCommandHint()
            self.ChatCommandHintInterface:Refresh(text)
        end
    end,

    --- Creates the hint popup and anchors it directly above the edit box.
    ---@param self UIChatEditInterface
    OpenCommandHint = function(self)
        if self.ChatCommandHintInterface then return end

        -- Ensure the built-ins exist before the hint queries the registry;
        -- otherwise we'd only see the footer fallback on the first open.
        ChatController.RegisterBuiltinCommands()

        local hint = ChatCommandHintInterface(self, self.EditBox)
        self.ChatCommandHintInterface = hint
        LayoutHelpers.Above(hint, self.EditBox, 14)
        LayoutHelpers.AtLeftIn(hint, self.EditBox)
        hint:SetOnSelect(function(cmd)
            self.EditBox:SetText('/' .. cmd.Name .. ' ')
            self:AcquireFocus()
        end)
    end,

    --- Tears down the hint popup if it exists. Called when the user sends a
    --- message, clears the prefix, or otherwise leaves command-entry mode.
    ---@param self UIChatEditInterface
    CloseCommandHint = function(self)
        if not self.ChatCommandHintInterface then return end
        local hint = self.ChatCommandHintInterface --[[@as UIChatCommandHintInterface]]
        self.ChatCommandHintInterface = nil
        hint:Destroy()
    end,

    --- Opens the recipient picker popup, or closes it if it is already open.
    ---@param self UIChatEditInterface
    ToggleList = function(self)
        if self.ChatListInterface then
            local list = self.ChatListInterface --[[@as UIChatListInterface]]
            self.ChatListInterface = nil
            list:Destroy()
            self:AcquireFocus()
        else
            local list = ChatListInterface(self)
            self.ChatListInterface = list
            -- Position the popup above-left of the chat-bubble button.
            -- Depth is handled by the list itself (see ChatListInterface.__init).
            LayoutHelpers.Above(list, self.ChatBubble, 15)
            LayoutHelpers.AtLeftIn(list, self.ChatBubble, 15)
            list:SetOnClosed(function()
                self.ChatListInterface = nil
                self:AcquireFocus()
            end)
        end
    end,

    --- Updates the label from the current recipient value.
    ---@param self UIChatEditInterface
    ---@param recipient UIChatRecipient
    RefreshRecipient = function(self, recipient)
        if recipient == ChatModel.RecipientAll then
            self.RecipientLabel:SetText("To All:")
        elseif recipient == ChatModel.RecipientAllies then
            self.RecipientLabel:SetText("To Allies:")
        elseif type(recipient) == 'number' then
            local armies = GetArmiesTable()
            local army = armies and armies.armiesTable and armies.armiesTable[recipient]
            local name = army and army.nickname or tostring(recipient)
            self.RecipientLabel:SetText("To " .. name .. ":")
        end
    end,

    --- Moves keyboard focus into the edit box.
    ---@param self UIChatEditInterface
    AcquireFocus = function(self)
        self.EditBox:AcquireFocus()
    end,

    --- Moves keyboard focus out of the edit box.
    ---@param self UIChatEditInterface
    AbandonFocus = function(self)
        self.EditBox:AbandonFocus()
    end,

    --- Empties our trash bag so every derived observer we allocated is
    --- destroyed — no `OnDirty` can fire into a torn-down `self`.
    ---@param self UIChatEditInterface
    OnDestroy = function(self)
        self.Trash:Destroy()
    end,
}
