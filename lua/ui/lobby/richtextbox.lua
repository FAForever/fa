local ItemsControl = import('./itemscontrol.lua').ItemsControl
local StackPanel = import('./stackpanel.lua').StackPanel
local Text = import('/lua/maui/text.lua').Text

RichTextBox = Class(ItemsControl) {

    Texts = nil,
    DefaultTextOptions = nil,
    DefaultLineOptions = nil,

    __init = function(self, Parent, Options)
        -- Properties init
        self.Texts = {}
        self.DefaultTextOptions = {ForeColor = "ffffffff", BackColor = "00000000", FontName = "Arial", FontSize = 12, Padding = {0,0,0,0}, Margin = {0,0,0,0}, DropShadow = false}
        self.DefaultLineOptions = {BackColor = "00000000", Padding = {0,0,0,0}, Margin = {0,0,0,0}}

        -- Init base class
        ItemsControl.__init(self, Parent, Options)

        -- AdvanceFunction
        self.TestTextBlock = Text(self)
        self.TestTextBlock:Hide()
        self.CreateAdvanceFunction = function(self, TextOptions)
            local TextBlock = self.TestTextBlock
            TextBlock:SetFont(TextOptions.FontName, TextOptions.FontSize)
            return function(text)
                TextBlock:SetText(text)
                return TextBlock:Width()
            end
        end
    end,

    AppendText = function(self, String, NewLine, TextOptions, LineOptions)

        local TextWrapper = import('/lua/maui/text.lua')
        local DeferRefresh = self.DeferRefresh
        self.DeferRefresh = true -- We defer the refresh while new lines are added. Refresh is callad at the end

        -- Set text options
        if not TextOptions then TextOptions = {} end
        for Name, Value in self.DefaultTextOptions do
            if not TextOptions[Name] then TextOptions[Name] = Value end
        end 

        -- Set line options
        if not LineOptions then LineOptions = {} end
        for Name, Value in self.DefaultLineOptions do
            if not LineOptions[Name] then LineOptions[Name] = Value end
        end 

        -- Save the text entry
        table.insert(self.Texts, {String, NewLine, TextOptions, LineOptions})

        -- Get available space per line
        local LineWidth = self.Panel.Width()
        local GetLineWidth = function(LineNumber)
            if LineNumber == 1 and not NewLine and table.getn(self.Items) > 0 then 
                -- Return the remaining space on the last line
                return LineWidth - self.Items[table.getn(self.Items)].UsedSpace
            end
            return LineWidth
        end

        -- Get the per line wrapped text
        local wrapped = TextWrapper.WrapText(String, GetLineWidth, self:CreateAdvanceFunction(TextOptions))

        -- Create the lines
        for i, line in wrapped do

            -- Create the TextLine
            local TextLine = nil
            if i == 1 and not NewLine and table.getn(self.Items) > 0 then
                -- Take the previous line
                TextLine = self.Items[table.getn(self.Items)]
            else
                -- We need a new line {BackColor = "00000000", Padding = {0,0,0,0}, Margin = {0,0,0,0}}
                TextLine = StackPanel(self, {Orientation = "H"})
                TextLine.BG:SetSolidColor(LineOptions.BackColor)
                TextLine.Margin = LineOptions.Margin
                TextLine.Padding = LineOptions.Padding
                -- Set a height or it wont work
                TextLine.Height:Set(1)
                TextLine.UsedSpace = 0
                self:AddItem(TextLine)
            end

            -- Create the TextBlock {ForeColor = "ffffffff", BackColor = "00000000", FontName = "Arial", FontSize = 12, Padding = {0,0,0,0}, Margin = {0,0,0,0}}
            local TextBlock = Text(self)
            TextBlock:SetFont(TextOptions.FontName, TextOptions.FontSize)
            TextBlock:SetColor(TextOptions.ForeColor)
            TextBlock:SetDropShadow(TextOptions.DropShadow)
            TextBlock.Margin = TextOptions.Margin
            TextBlock.Padding = TextOptions.Padding
            TextBlock:SetText(line)

            -- Set the TextLine height
            local Height = TextBlock.Height() + TextOptions.Margin[1] + TextOptions.Margin[3] + LineOptions.Margin[1] + LineOptions.Margin[3] + LineOptions.Padding[1] + LineOptions.Margin[3]
            if Height > TextLine.Height() then
                TextLine.Height:Set(Height)
            end

            -- Add the TextBlock to the TextLine
            TextLine:AddItem(TextBlock)
            TextLine.UsedSpace = TextLine.UsedSpace + TextBlock.Width()

        end

        -- Refresh the list when all lines are added
        if not DeferRefresh then
            self:Refresh()
        end
  
    end,
}