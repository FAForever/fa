
local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")

local Group = import("/lua/maui/group.lua").Group
local Edit = import("/lua/maui/edit.lua").Edit
local Button = import("/lua/maui/button.lua").Button

local ChatModel = import("/lua/ui/game/chat/ChatModel.lua")
local ChatController = import("/lua/ui/game/chat/ChatController.lua")
local ChatListInterface = import("/lua/ui/game/chat/ChatListInterface.lua").ChatListInterface
local ChatCommandHintInterface = import("/lua/ui/game/chat/ChatCommandHintInterface.lua").ChatCommandHintInterface

local LazyVarDerive = import("/lua/lazyvar.lua").Derive

local Layouter = LayoutHelpers.ReusedLayoutFor

local MaxChars = 200

-------------------------------------------------------------------------------
-- The chat input area: a chat-bubble button, a recipient label, and an edit
-- box. Pressing Enter dispatches the text to the controller. Clicking the
-- chat-bubble button or the label opens the recipient picker (ChatListInterface).

---@class UIChatEditInterface : Group
---@field Trash             TrashBag                          # owns every derived subscription-LazyVar
---@field ChatBubble        Button
---@field RecipientLabel    Text
---@field EditBox           Edit
---@field ChatList          UIChatListInterface | nil
---@field CommandHint       UIChatCommandHintInterface | nil
---@field RecipientObserver LazyVar<UIChatRecipient>  # derived from ChatModel.Recipient
ChatEditInterface = ClassUI(Group) {

    ---@param self UIChatEditInterface
    ---@param parent Control
    __init = function(self, parent)
        Group.__init(self, parent, "ChatEditInterface")

        -- Single trash bag for everything we allocate that needs explicit
        -- destruction — currently just the derived observer LazyVars.
        -- Emptied in `OnDestroy`.
        self.Trash = TrashBag()

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
            UIUtil.highlightColor, UIUtil.bodyFont, 14, MaxChars)
        self.EditBox:SetDropShadow(true)
        self.EditBox:ShowBackground(false)
        self.EditBox:SetText('')

        self.EditBox.OnEnterPressed = function(edit, text)
            if text and text ~= '' then
                ChatController.Send(text)
                edit:SetText('')
            end
            self:CloseCommandHint()
        end

        -- Drive the command-hint popup from the edit-box contents.
        -- `OnTextChanged` fires after every insertion, deletion, or `SetText`,
        -- so we don't need to poll each frame.
        self.EditBox.OnTextChanged = function(_, newText, _)
            self:RefreshCommandHint(newText or '')
        end

        -- Keep the label in sync with the model. `LazyVarDerive` gives us a
        -- fresh per-subscriber LazyVar so we don't stomp any other observer
        -- of `model.Recipient` (see the chat CLAUDE.md for the pattern).
        local model = ChatModel.GetSingleton()
        self.RecipientObserver = self.Trash:Add(LazyVarDerive(model.Recipient, function(lv)
            self:RefreshRecipient(lv())
        end))
    end,

    --- Shows or hides the command hint based on the current edit-box text.
    ---@param self UIChatEditInterface
    ---@param text string
    RefreshCommandHint = function(self, text)
        if string.sub(text, 1, 1) == '/' then
            if not self.CommandHint then
                self:OpenCommandHint()
            end
            local hint = self.CommandHint --[[@as UIChatCommandHintInterface]]
            hint:Refresh(text)
        else
            self:CloseCommandHint()
        end
    end,

    --- Creates the hint popup and anchors it directly above the edit box.
    ---@param self UIChatEditInterface
    OpenCommandHint = function(self)
        if self.CommandHint then return end

        -- Ensure the built-ins exist before the hint queries the registry;
        -- otherwise we'd only see the footer fallback on the first open.
        ChatController.RegisterBuiltinCommands()

        local hint = ChatCommandHintInterface(self, self.EditBox)
        self.CommandHint = hint
        LayoutHelpers.Above(hint, self.EditBox, 4)
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
        if not self.CommandHint then return end
        local hint = self.CommandHint --[[@as UIChatCommandHintInterface]]
        self.CommandHint = nil
        hint:Destroy()
    end,

    ---@param self UIChatEditInterface
    ---@param parent Control
    __post_init = function(self, parent)
        Layouter(self.ChatBubble)
            :AtLeftIn(self, 3)
            :AtVerticalCenterIn(self)
            :End()

        Layouter(self.RecipientLabel)
            :AnchorToRight(self.ChatBubble, 2)
            :AtVerticalCenterIn(self)
            :End()

        Layouter(self.EditBox)
            :AnchorToRight(self.RecipientLabel, 4)
            :AtRightIn(self, 2)
            :AtVerticalCenterIn(self)
            :Height(function() return self.EditBox:GetFontHeight() end)
            :End()

        -- The group sizes itself to the edit's font height; the parent
        -- positions it (Left/Right/Bottom) and leaves Height alone. This
        -- mirrors the original `group.Height:Set(function() return group.edit.Height() end)`.
        Layouter(self)
            :Height(function() return self.EditBox.Height() end)
            :End()
    end,

    --- Opens the recipient picker popup, or closes it if it is already open.
    ---@param self UIChatEditInterface
    ToggleList = function(self)
        if self.ChatList then
            local list = self.ChatList --[[@as UIChatListInterface]]
            self.ChatList = nil
            list:Destroy()
            self:AcquireFocus()
        else
            local list = ChatListInterface(self)
            self.ChatList = list
            -- Position the popup above-left of the chat-bubble button.
            -- Depth is handled by the list itself (see ChatListInterface.__init).
            LayoutHelpers.Above(list, self.ChatBubble, 15)
            LayoutHelpers.AtLeftIn(list, self.ChatBubble, 15)
            list:SetOnClosed(function()
                self.ChatList = nil
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

    --- Empties our trash bag so every derived observer we allocated is
    --- destroyed — no `OnDirty` can fire into a torn-down `self`.
    ---@param self UIChatEditInterface
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
