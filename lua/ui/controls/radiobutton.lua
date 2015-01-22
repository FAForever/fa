local Group = import('/lua/maui/group.lua').Group
local UIUtil = import('/lua/ui/uiutil.lua')
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')

RadioButton = Class(Group) {
    -- title: A string displayed above the group. If nil, no textfield is created.
    -- buttons: A table of tables describing buttons. Only one key is required:
    --  Optional parameters are permitted:
    --  label: A string to display beside the button.
    --  texturePath: A string to be used as a directory offset relative to the object's texture path
    --  to find button-specific textures. If omitted, textures from relative "./default" are used instead.
    --
    --  The required texture names are:
    --  s_dis.png
    --  s_up.png
    --  s_over.png
    --  d_dis.png
    --  d_up.png
    --  d_over.png
    -- texturePath: The path from the style root to the texture directory for this radiobutton.
    --              Button-specific texture paths are relative to this path (and both are subject to
    --              the whims of the style engine.
    -- default: The index in the buttons array of the value to be selected by default.
    __init = function(self, parent, texturePath, buttons, default, horizontal, labelRight, font, fontSize, fontColor)
        Group.__init(self, parent)
        font = font or "Arial"
        fontSize = fontSize or 13
        fontColor = fontColor or UIUtil.fontColor

        -- get the buttons and do some setup
        local maxWidth = 0
        local height = 0
        self.mButtons = {}
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

                self:OnChoose(optionIndex)
                self.mCurSelection = optionIndex
            end
        end
        self.mButtons[default]:SetCheck(true)

        -- the group should be sized so we can click on the control if desired
        self.Height:Set(function() return height + 12 end)
        self.Width:Set(maxWidth + 12)
        self.Right:Set(function() return self.Left() + self.Width() end)
        self.Bottom:Set(function() return self.Top() + self.Height() end)

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

    Disable = function(self)
        for k, v in self.mButtons do
           v:Disable()
        end
    end,

    Enable = function(self)
        for k, v in self.mButtons do
            v:Enable()
        end
    end,

    SetSelected = function(self, index)
        self.mButtons[index]:OnClick()
    end,

    -- Overload this method to get events when item is chosen.
    OnChoose = function(self, index) end,
}
