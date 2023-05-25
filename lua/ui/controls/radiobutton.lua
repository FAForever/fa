local Group = import("/lua/maui/group.lua").Group
local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Tooltip = import("/lua/ui/game/tooltip.lua")

---@class RadioButton : Group
RadioButton = ClassUI(Group) {
    -- title: A string displayed above the group. If nil, no textfield is created.
    -- buttons: A table of tables describing buttons. Only one key is required:
    --  Optional parameters are permitted:
    --  label: A string to display beside the button.
    --  texturePath: A string to be used as a directory offset relative to the object's texture path
    --               to find button-specific textures. If omitted, textures from relative "./default"
    --               are used instead.
    --
    --  The required texture names are:
    --  s_dis.png
    --  s_up.png
    --  s_over.png
    --  d_dis.png
    --  d_up.png
    --  d_over.png
    --
    --  key: An arbitrary piece of satellite data to be passed to onChoose when the corresponding
    --       item is selected
    --  tooltipID: A tooltip ID to add to the checkbox control for this elements
    --
    -- texturePath: The path from the style root to the texture directory for this radiobutton.
    --              Button-specific texture paths are relative to this path (and both are subject to
    --              the whims of the style engine.
    -- default: The index in the buttons array of the value to be selected by default.
    ---@param self RadioButton
    ---@param parent Control
    ---@param texturePath FileName
    ---@param buttons Button[]
    ---@param default any
    ---@param horizontal any
    ---@param labelRight any
    ---@param font string
    ---@param fontSize number
    ---@param fontColor Color
    __init = function(self, parent, texturePath, buttons, default, horizontal, labelRight, font, fontSize, fontColor)
        Group.__init(self, parent)

        if buttons then
            self:SetOptions(buttons, texturePath, default, horizontal, labelRight, font, fontSize, fontColor)
        end
    end,

    ---@param self RadioButton
    ---@param buttons Button[]
    ---@param texturePath FileName
    ---@param default any
    ---@param horizontal any
    ---@param labelRight any
    ---@param font string
    ---@param fontSize number
    ---@param fontColor Color
    SetOptions = function(self, buttons, texturePath, default, horizontal, labelRight, font, fontSize, fontColor)
        -- Destroy any existing contents.
        if self.mButtons then
            for k, v in self.mButtons do
                v:Destroy()
            end
        end
        self.mButtons = {}

        font = font or "Arial"
        fontSize = fontSize or 13
        fontColor = fontColor or UIUtil.fontColor

        local maxWidth = 0
        local height = 0

        -- get the buttons and do some setup
        self.mCurSelection = default

        -- set up all the buttons
        for index, button in buttons do
            local buttonTexturePath
            if button.texturePath then
                buttonTexturePath = texturePath .. button.texturePath .. '/'
            else
                buttonTexturePath = texturePath
            end

            local checkbox = UIUtil.CreateCheckbox(self, buttonTexturePath, button.label, labelRight)
            checkbox.radioKey = button.key
            if button.tooltipID then
                Tooltip.AddCheckboxTooltip(checkbox, button.tooltipID)
            end

            if button.label then
                checkbox.label:SetFont(font, fontSize)
                checkbox.label:SetColor(fontColor)
            end

            height = height + checkbox.Height()

            self.mButtons[index] = checkbox

            local thisWidth = checkbox.Width()
            if thisWidth > maxWidth then
                maxWidth = thisWidth
            end

            -- Copy for closure
            local optionIndex = index
            checkbox.OnClick = function(control, modifiers)
            -- Uncheck the currently selected one.
                self.mButtons[self.mCurSelection]:SetCheck(false)

                -- And select this one.
                control:SetCheck(true)

                self:OnChoose(optionIndex, control.radioKey)
                self.mCurSelection = optionIndex
            end
        end
        self.mButtons[default]:SetCheck(true)

        -- the group should be sized so we can click on the control if desired
        self.Height:Set(function() return height + 12 end)
        self.Width:Set(maxWidth + 12)
        LayoutHelpers.ResetBottom(self)
        LayoutHelpers.ResetRight(self)
        
        -- add the buttons to the layout
        local isFirst = true
        local lastButton
        for index, button in self.mButtons do
            if isFirst == true then
                isFirst = false
                LayoutHelpers.AtLeftTopIn(button, self)
            else
                if horizontal then
                    LayoutHelpers.AtTopIn(button, self)
                    LayoutHelpers.RightOf(button, lastButton, 25)
                else
                    LayoutHelpers.AtLeftIn(button, self)
                    LayoutHelpers.Below(button, lastButton)
                end
            end
            lastButton = button
        end
    end,

    ---@param self RadioButton
    Disable = function(self)
        for k, v in self.mButtons do
           v:Disable()
        end
    end,

    ---@param self RadioButton
    Enable = function(self)
        for k, v in self.mButtons do
            v:Enable()
        end
    end,

    ---@param self RadioButton
    ---@param index number
    SetSelected = function(self, index)
        self.mButtons[index]:OnClick()
    end,

    -- Overload this method to get events when item is chosen.
    ---@param self RadioButton
    ---@param index number
    ---@param key number
    OnChoose = function(self, index, key) end,
}
