
local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")

local Group = import("/lua/maui/group.lua").Group
local Edit = import("/lua/maui/edit.lua").Edit

local ChatModel = import("/lua/ui/game/chat/ChatModel.lua")
local ChatController = import("/lua/ui/game/chat/ChatController.lua")

local Layouter = LayoutHelpers.ReusedLayoutFor

local MaxChars = 200

-------------------------------------------------------------------------------
-- The chat input area: a recipient label followed by an edit box. Pressing
-- Enter dispatches the text to the controller.

---@class UIChatEditInterface : Group
---@field RecipientLabel Text
---@field EditBox        Edit
ChatEditInterface = ClassUI(Group) {

    ---@param self UIChatEditInterface
    ---@param parent Control
    __init = function(self, parent)
        Group.__init(self, parent, "ChatEditInterface")

        self.RecipientLabel = UIUtil.CreateText(self, "To All:", 14, 'Arial')
        self.RecipientLabel:SetDropShadow(true)

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
        end

        -- Keep the label in sync with the model.
        local model = ChatModel.GetSingleton()
        model.Recipient.OnDirty = function(lv)
            self:RefreshRecipient(lv())
        end
        self:RefreshRecipient(model.Recipient())
    end,

    ---@param self UIChatEditInterface
    ---@param parent Control
    __post_init = function(self, parent)
        Layouter(self.RecipientLabel)
            :AtLeftIn(self, 2)
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
}

-------------------------------------------------------------------------------
--#region Debugging

function __moduleinfo.OnDirty()
    import(__moduleinfo.name)
end

--#endregion
