
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

local Debug = false

local MaxCommandHistorySize = 32

-------------------------------------------------------------------------------
-- The chat input area: a chat-bubble button, a recipient label, and an edit
-- box. Pressing Enter dispatches the text to the controller. Clicking the
-- chat-bubble button or the label opens the recipient picker (ChatListInterface).

--- Chat input area: edit box, recipient label, recipient picker, camera toggle, command hint, recall ring.
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

        self.RecipientLabel.HandleEvent = function(_, event)
            if event.Type == 'ButtonPress' then
                self:ToggleList()
            end
        end

        self.CamCheckbox = Checkbox(self,
            UIUtil.SkinnableFile('/game/camera-btn/pinned_btn_up.dds'),
            UIUtil.SkinnableFile('/game/camera-btn/pinned_btn_down.dds'),
            UIUtil.SkinnableFile('/game/camera-btn/pinned_btn_over.dds'),
            UIUtil.SkinnableFile('/game/camera-btn/pinned_btn_over.dds'),
            UIUtil.SkinnableFile('/game/camera-btn/pinned_btn_dis.dds'),
            UIUtil.SkinnableFile('/game/camera-btn/pinned_btn_dis.dds'))
        Tooltip.AddCheckboxTooltip(self.CamCheckbox, 'chat_camera')

        self.EditBox = Edit(self)

        -- `SetupEditStd` below reads the control's bounds before
        -- `__post_init` runs. Seed placeholder values to avoid tripping
        -- the default circular Left/Right/Width chain.
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

        -- Enter on an empty box closes the window; otherwise sends and
        -- pushes onto the command-history ring for Up/Down recall.
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

        -- Drop any in-flight Tab-completion cycle whenever the text changes
        -- from something other than our own `ApplyCompletion`.
        self.EditBox.OnTextChanged = function(_, newText, _)
            ChatController.NotifyActivity()
            self:RefreshCommandHint(newText or '')
            if not self.SuppressCompletionReset then
                self.Completion = nil
            end
        end

        -- `OnCharPressed` fires before insertion. `>=` catches the
        -- keystroke the cap is about to reject.
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

        -- Page Up/Down: no mod = 10 rows, Shift = 1 row, Ctrl = jump to
        -- the extreme (Ctrl+PgDn at bottom collapses the window). Home/End
        -- are consumed by Edit for caret nav before they reach here.
        -- Up/Down cycle the command-hint when open, otherwise walk
        -- command history. Lazy import of ChatInterface breaks an import
        -- cycle.
        ---@param keycode number     # OS-level VK_* code
        ---@param event KeyEvent
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

        Layouter(self.CamCheckbox)
            :AtRightIn(self, 12)
            :AtVerticalCenterIn(self, -2)
            :End()

        -- `ResetWidth` drops the `:Width(200)` placeholder set in `__init`
        -- (needed there so `SetupEditStd` could read the layout without
        -- tripping the default circular Width chain). Without this reset,
        -- the typing area stays capped at 200 px regardless of where Right
        -- anchors.
        Layouter(self.EditBox)
            :AnchorToRight(self.RecipientLabel, 4)
            :AnchorToLeft(self.CamCheckbox, 4)
            :AtVerticalCenterIn(self)
            :ResetWidth()
            :Height(function() return self.EditBox:GetFontHeight() end)
            :End()

        if Debug then
            self.DebugBG = Bitmap(self)
            self.DebugBG:SetSolidColor('40ff40ff')
            self.DebugBG:DisableHitTest()
            Layouter(self.DebugBG):Fill(self):Over(self, 100):End()
        end
    end,

    --- Tab key. With the hint open, commits the selected command;
    --- otherwise runs the in-box nickname completion cycle. Plays the
    --- error cue when there is nothing to complete.
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

    --- Writes the current candidate at the recorded anchor.
    ---@param self UIChatEditInterface
    ApplyCompletion = function(self)
        -- `SuppressCompletionReset` keeps the `OnTextChanged` branch from
        -- clearing the cycle state as a side-effect of our own edit.
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

        -- Advance the consumed span so the next cycle overwrites this
        -- candidate, not the original word.
        c.Consume = replacementLen
    end,

    ---------------------------------------------------------------------------
    -- Command history recall

    --- Pushes a sent message onto the recall ring, dropping the oldest if the
    --- ring is full. Resets any in-progress recall walk.
    ---@param self UIChatEditInterface
    ---@param text string
    PushHistory = function(self, text)
        table.insert(self.CommandHistory, text)
        while table.getn(self.CommandHistory) > MaxCommandHistorySize do
            table.remove(self.CommandHistory, 1)
        end
        self.RecallEntry = nil
    end,

    --- Walks toward older entries; first press lands on the newest, then
    --- moves one step earlier per press and clamps at the oldest.
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

    --- Walks toward newer entries. Past the newest, `RecallEntry` resets
    --- to nil and the next Down blanks the edit ("wipe what I'm typing").
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
    --- caret at the end. Guarded against `RecallEntry` going stale between
    --- a destructive history mutation and the next nav keystroke.
    ---@param self UIChatEditInterface
    ApplyRecall = function(self)
        local entry = self.CommandHistory[self.RecallEntry or 0]
        if not entry then return end
        self.EditBox:SetText(entry)
        self.EditBox:SetCaretPosition(STR_Utf8Len(entry))
    end,

    --- Refreshes (or opens) the command-hint popup based on the current text.
    ---@param self UIChatEditInterface
    ---@param text string
    RefreshCommandHint = function(self, text)
        -- Only opens when the text transitions to exactly `/`. Closing
        -- the hint via Escape leaves it closed while the user keeps typing.
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

    --- Mounts the slash-command hint popup above the edit box. No-op if open.
    ---@param self UIChatEditInterface
    OpenCommandHint = function(self)
        -- Ensure the built-ins exist before the hint queries the registry.
        if self.ChatCommandHintInterface then return end

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

    --- Tears down the slash-command hint popup if it is open.
    ---@param self UIChatEditInterface
    CloseCommandHint = function(self)
        if not self.ChatCommandHintInterface then return end
        local hint = self.ChatCommandHintInterface --[[@as UIChatCommandHintInterface]]
        self.ChatCommandHintInterface = nil
        hint:Destroy()
    end,

    --- Opens or closes the recipient picker popup, returning focus to the edit box.
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
            LayoutHelpers.Above(list, self.ChatBubble, 15)
            LayoutHelpers.AtLeftIn(list, self.ChatBubble, 15)
            list:SetOnClosed(function()
                self.ChatListInterface = nil
                self:AcquireFocus()
            end)
        end
    end,

    --- Updates the recipient label to match the current send target.
    ---@param self UIChatEditInterface
    ---@param recipient UIChatRecipient
    RefreshRecipient = function(self, recipient)
        local descriptor = ChatUtils.ToStrings[recipient]
        if descriptor then
            self.RecipientLabel:SetText(LOC(descriptor.caps) --[[@as string]])
        elseif type(recipient) == 'number' then
            local armies = GetArmiesTable()
            local army = armies and armies.armiesTable and armies.armiesTable[recipient]
            local name = army and army.nickname or tostring(recipient)
            self.RecipientLabel:SetText(string.format("%s %s:", LOC(ChatUtils.ToStrings.to.caps), name))
        end
    end,

    --- Gives keyboard focus to the edit box.
    ---@param self UIChatEditInterface
    AcquireFocus = function(self)
        self.EditBox:AcquireFocus()
    end,

    --- Releases keyboard focus from the edit box.
    ---@param self UIChatEditInterface
    AbandonFocus = function(self)
        self.EditBox:AbandonFocus()
    end,

    --- Destroys derived observers so dangling OnDirty callbacks don't fire into a dead self.
    ---@param self UIChatEditInterface
    OnDestroy = function(self)
        self.Trash:Destroy()
    end,
}
