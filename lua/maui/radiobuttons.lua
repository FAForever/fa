local Group = import("/lua/maui/group.lua").Group
local Checkbox = import("/lua/maui/checkbox.lua").Checkbox
local Text = import("/lua/maui/text.lua").Text
local Border = import("/lua/maui/border.lua").Border
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")

---@class RadioButtons : Group
RadioButtons = ClassUI(Group) {
    -- title is a string that will get displayed above the group
    -- buttons is a table of strings that represent a button
    -- default is the string that will be selected on start
    -- font is the name of the font to use for the labels
    -- fontsize is the size of the label font
    -- unselected is the file name of the bitmap for the unselected buttons
    -- selected is the file name of the bitmap for the selected buttons
    __init = function(self, parent, title, buttons, default, font, fontsize, fontcolor, unselected, selected, overUn, overSel, disabledUn, disabledSel, debugname)
        Group.__init(self, parent)
        self:SetName(debugname or "radiobuttons")

        -- get the buttons and do some setup
        local maxWidth = 0
        local height = 0
        self.mButtons = {}
        self.mCurSelection = default

        -- set up all the buttons
        for index, button in buttons do
            self.mButtons[button] = {checkbox = Checkbox(self, unselected, selected, overUn, overSel, disabledUn, disabledSel),
                                     label = Text(self)}
            self.mButtons[button].label:SetFont(font, fontsize)
            self.mButtons[button].label:SetColor(fontcolor)
            self.mButtons[button].label:SetText(button)
            LayoutHelpers.CenteredRightOf(self.mButtons[button].label, self.mButtons[button].checkbox)
            local thisWidth = self.mButtons[button].checkbox.Width() + self.mButtons[button].label.Width()
            if thisWidth > maxWidth then maxWidth = thisWidth end
            height = height + math.max(self.mButtons[button].checkbox.Height(), self.mButtons[button].label.Height())            
            
            if button == default then
                self.mButtons[button].checkbox:SetCheck(true)
            end
            
            -- label should forward all click events to checkbox for it to handle
            self.mButtons[button].label.HandleEvent = function(control, event)
                if event.Type == 'ButtonPress' or event.Type == 'ButtonDClick' then
                    for button in self.mButtons do
                        if control == self.mButtons[button].label then
                            self.mButtons[button].checkbox:HandleEvent(event)
                            break
                        end
                    end
                end
            end

            self.mButtons[button].checkbox.HandleEvent = function(control, event)
                if event.Type == 'ButtonPress' or event.Type == 'ButtonDClick' then
                    for button in self.mButtons do
                        if control == self.mButtons[button].checkbox then
                            if self.mCurSelection != button then
                                self.mButtons[self.mCurSelection].checkbox:SetCheck(false)
                                self.mCurSelection = button
                                control:SetCheck(true)
                                self:OnChoose(button)
                            end
                            break
                        end
                    end
                end
            end
        end

        -- calculate the layout once the buttons are all set up
        self.mTitle = Text(self)
        self.mTitle:SetFont(font, fontsize)
        self.mTitle:SetColor(fontcolor)
        self.mTitle:SetText(title)
        self.mTitle.Top:Set(self.Top)
        self.mTitle.Left:Set(self.Left)

        -- make sure we fit the text label
        if maxWidth < self.mTitle.Width() then maxWidth = self.mTitle.Width() end

        self.mBorder = Border(self)
        self.mBorder.Height:Set(height + 12)
        self.mBorder.Width:Set(maxWidth + 12)
        self.mBorder.Top:Set(self.mTitle.Bottom)
        self.mBorder.Left:Set(self.mTitle.Left)

        -- the group should be sized so we can click on the control if desired
        self.Height:Set(function() return self.mBorder.Height() + self.mTitle.Height() end)
        self.Width:Set(self.mBorder.Width)
        self.Right:Set(function() return self.Left() + self.Width() end)
        self.Bottom:Set(function() return self.Top() + self.Height() end)

        -- add the buttons to the layout
        local isFirst = true
        local lastButton
        for index, button in buttons do
            if isFirst == true then
                isFirst = false
                lastButton = button
                self.mButtons[button].checkbox.Left:Set(function() return self.mBorder.Left() + 6 end)
                self.mButtons[button].checkbox.Top:Set(function() return self.mBorder.Top() + 6 end)
            else
                self.mButtons[button].checkbox.Left:Set(self.mButtons[lastButton].checkbox.Left)
                self.mButtons[button].checkbox.Top:Set(self.mButtons[lastButton].checkbox.Bottom)
                lastButton = button
            end
        end
    end,
    
    -- overload this method to get events when item is choosen
    OnChoose = function(self, button) end,
}