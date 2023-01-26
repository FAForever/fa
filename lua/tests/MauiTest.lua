--
-- These tests are run via 'ScalpD MauiTestOne', etc.
--

local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local Text = import("/lua/maui/text.lua").Text
local Button = import("/lua/maui/button.lua").Button
local Border = import("/lua/maui/border.lua").Border
local Group = import("/lua/maui/group.lua").Group
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Edit = import("/lua/maui/edit.lua").Edit
local Checkbox = import("/lua/maui/checkbox.lua").Checkbox
local RadioButtons = import("/lua/maui/radiobuttons.lua").RadioButtons
local Dragger = import("/lua/maui/dragger.lua").Dragger
local ItemList = import("/lua/maui/itemlist.lua").ItemList
local Scrollbar = import("/lua/maui/scrollbar.lua").Scrollbar
local Slider = import("/lua/maui/slider.lua").Slider
local IntegerSlider = import("/lua/maui/slider.lua").IntegerSlider
local StatusBar = import("/lua/maui/statusbar.lua").StatusBar

function TestOne(root)

    LOG('Starting TestOne()')

    local center = Button(root,
                          '/textures/test/button_normal.png',
                          '/textures/test/button_active.png',
                          '/textures/test/button_highlight.png')
    center.Left:Set(function()
                        return math.floor(0.5 * (root.Width()-center.Width()))
                            end)
    center.Top:Set(function()
                       return math.floor(0.5 * (root.Height()-center.Height()))
                   end)

    local ul = Bitmap(root, '/textures/test/checker.png')
    ul.Left:Set(function() return root.Left() end)
    ul.Top:Set(function() return root.Top() end)

    local lr = Bitmap(root, '/textures/test/checker.png')
    lr.Right:Set(function() return root.Right() end)
    lr.Bottom:Set(function() return root.Bottom() end)

    local backdrop = Bitmap(root)

    local t = Text(root)
    t:SetFont("New Times Roman", 24)
    t:SetText("Look at the monkey!")
    t:SetColor("magenta")
    t.Left:Set(10)
    t.Top:Set(function() return math.floor(0.5 * (root.Height()-t.Height())) end)

    backdrop:SetSolidColor("yellow");
    backdrop.Left:Set(function() return t.Left() - 3 end)
    backdrop.Right:Set(function() return t.Right() + 3 end)
    backdrop.Top:Set(function() return t.Top() - 3 end)
    backdrop.Bottom:Set(function() return t.Bottom() + 3 end)
    backdrop.Depth:Set(function() return t.Depth() - 1 end)

    local b = Border(root)
    b:SetTextures('/textures/test/border_vert.png',
                  '/textures/test/border_horiz.png',
                  '/textures/test/border_ul.png',
                  '/textures/test/border_ur.png',
                  '/textures/test/border_ll.png',
                  '/textures/test/border_lr.png')
    b:LayoutAroundControl(t, 2)

    local phase = 0

    center.OnClick = function()
        phase = 1 - phase
        if phase == 0 then
            t:SetText('Look at the monkey!')
        else
            t:SetText('Where did it go?')
        end
    end

    LOG('Finished TestOne()')

end



function TestTwo(root)

    local itemlist = ItemList(root)
    local scrollbar = Scrollbar(root)
    scrollbar:SetTextures(
        '/textures/test/scroll-bg.png',
        '/textures/test/scroll-thumb-mid.png',
        '/textures/test/scroll-thumb-top.png',
        '/textures/test/scroll-thumb-bottom.png')

    itemlist:SetFont("New Times Roman", 16)
    for i,item in { "white", "gray", "red", "blue", "green", "cyan", "magenta", "yellow",
                    "ff8000", "ff0080", "ff8080", "ff80ff", "ffff80",
                    "800000", "800080", "8000ff",
                    "808000", "8080ff",
                    "80ff00", "80ff80", "80ffff",
                    "000080",
                    "008000", "008080", "0080ff",
                    "00ff80" } do
        itemlist:AddItem(item)
    end

    itemlist.Depth:Set(function() return root.Depth() + 100 end)
    LayoutHelpers.FromLeftIn(itemlist, root, .20)
    LayoutHelpers.FromRightIn(itemlist, root, .40)
    LayoutHelpers.FromTopIn(itemlist, root, .20)
    LayoutHelpers.FromBottomIn(itemlist, root, .40)

    scrollbar.Depth:Set(function() return root.Depth() + 99 end)
    scrollbar.Top:Set(itemlist.Top)
    scrollbar.Left:Set(itemlist.Right)
    scrollbar.Height:Set(itemlist.Height)
    scrollbar.Width:Set(20)

    scrollbar:SetScrollable(itemlist)

    local border = Border(root)
    border.Left:Set(function() return itemlist.Left() - 6 end)
    border.Right:Set(function() return scrollbar.Right() + 6 end)
    border.Top:Set(function() return itemlist.Top() - 6 end)
    border.Bottom:Set(function() return itemlist.Bottom() + 6 end)
    border:SetTextures('/textures/test/border_vert.png',
        '/textures/test/border_horiz.png',
        '/textures/test/border_ul.png',
        '/textures/test/border_ur.png',
        '/textures/test/border_ll.png',
        '/textures/test/border_lr.png')

    local text = Text(root)
    text:SetFont("New Times Roman", 24)
    text:SetText("Look at the monkey!")
    text.Left:Set(function () return math.floor(0.5 * (root.Width() - text.Width())) end)
    text.Bottom:Set(function () return math.floor(0.8 * (root.Top() + root.Bottom())) end)

    itemlist.OnClick = function(list, row)
        text:SetColor(list:GetItem(row))
        list:SetSelection(row)
    end

end

--* Layout Helper Test
function TestThree(root)
    SetUIControlsAlpha(0.5)

--*----------------------------------------------------------------------------
    local center = Bitmap(root)
    center:SetSolidColor("yellow")
    center.Width:Set(10)
    center.Height:Set(10)
    LayoutHelpers.AtCenterIn(center, root)

    local leftTop = Bitmap(root)
    leftTop:SetSolidColor("blue")
    leftTop.Width:Set(10)
    leftTop.Height:Set(10)
    LayoutHelpers.AtLeftIn(leftTop, root)
    LayoutHelpers.AtTopIn(leftTop, root)

    local rightTop = Bitmap(root)
    rightTop:SetSolidColor("blue")
    rightTop.Width:Set(10)
    rightTop.Height:Set(10)
    LayoutHelpers.AtRightIn(rightTop, root)
    LayoutHelpers.AtTopIn(rightTop, root)

    local leftBottom = Bitmap(root)
    leftBottom:SetSolidColor("blue")
    leftBottom.Width:Set(10)
    leftBottom.Height:Set(10)
    LayoutHelpers.AtLeftIn(leftBottom, root)
    LayoutHelpers.AtBottomIn(leftBottom, root)

    local rightBottom = Bitmap(root)
    rightBottom:SetSolidColor("blue")
    rightBottom.Width:Set(10)
    rightBottom.Height:Set(10)
    LayoutHelpers.AtRightIn(rightBottom, root)
    LayoutHelpers.AtBottomIn(rightBottom, root)

    local topCenter = Bitmap(root)
    topCenter:SetSolidColor("red")
    topCenter.Width:Set(10)
    topCenter.Height:Set(10)
    LayoutHelpers.AtTopIn(topCenter, root)
    LayoutHelpers.AtHorizontalCenterIn(topCenter, root)

    local leftCenter = Bitmap(root)
    leftCenter:SetSolidColor("red")
    leftCenter.Width:Set(10)
    leftCenter.Height:Set(10)
    LayoutHelpers.AtLeftIn(leftCenter, root)
    LayoutHelpers.AtVerticalCenterIn(leftCenter, root)

--*----------------------------------------------------------------------------
    local centerOffset = Bitmap(root)
    centerOffset:SetSolidColor("yellow")
    centerOffset.Width:Set(10)
    centerOffset.Height:Set(10)
    LayoutHelpers.AtCenterIn(centerOffset, root, 20, 20)

    local leftTopOffset = Bitmap(root)
    leftTopOffset:SetSolidColor("blue")
    leftTopOffset.Width:Set(10)
    leftTopOffset.Height:Set(10)
    LayoutHelpers.AtLeftIn(leftTopOffset, root, 20)
    LayoutHelpers.AtTopIn(leftTopOffset, root, 20)

    local rightTopOffset = Bitmap(root)
    rightTopOffset:SetSolidColor("blue")
    rightTopOffset.Width:Set(10)
    rightTopOffset.Height:Set(10)
    LayoutHelpers.AtRightIn(rightTopOffset, root, 20)
    LayoutHelpers.AtTopIn(rightTopOffset, root, 20)

    local leftBottomOffset = Bitmap(root)
    leftBottomOffset:SetSolidColor("blue")
    leftBottomOffset.Width:Set(10)
    leftBottomOffset.Height:Set(10)
    LayoutHelpers.AtLeftIn(leftBottomOffset, root, 20)
    LayoutHelpers.AtBottomIn(leftBottomOffset, root, 20)

    local rightBottomOffset = Bitmap(root)
    rightBottomOffset:SetSolidColor("blue")
    rightBottomOffset.Width:Set(10)
    rightBottomOffset.Height:Set(10)
    LayoutHelpers.AtRightIn(rightBottomOffset, root, 20)
    LayoutHelpers.AtBottomIn(rightBottomOffset, root, 20)

    local topCenterOffset = Bitmap(root)
    topCenterOffset:SetSolidColor("red")
    topCenterOffset.Width:Set(10)
    topCenterOffset.Height:Set(10)
    LayoutHelpers.AtTopIn(topCenterOffset, root)
    LayoutHelpers.AtHorizontalCenterIn(topCenterOffset, root, 20)

    local leftCenterOffset = Bitmap(root)
    leftCenterOffset:SetSolidColor("red")
    leftCenterOffset.Width:Set(10)
    leftCenterOffset.Height:Set(10)
    LayoutHelpers.AtLeftIn(leftCenterOffset, root)
    LayoutHelpers.AtVerticalCenterIn(leftCenterOffset, root, 20)

--*----------------------------------------------------------------------------

    for percent = 0.1, 0.9, 0.1 do
        local tlp = Bitmap(root)
        tlp:SetSolidColor("gray")
        tlp.Width:Set(10)
        tlp.Height:Set(10)
        tlp.Depth:Set(-1)
        LayoutHelpers.FromLeftIn(tlp, root, percent)
        LayoutHelpers.FromTopIn(tlp, root, percent)
    end

    for percent = 0.1, 0.9, 0.1 do
        local brp = Bitmap(root)
        brp:SetSolidColor("white")
        brp.Width:Set(10)
        brp.Height:Set(10)
        brp.Depth:Set(-1)
        LayoutHelpers.FromRightIn(brp, root, 1.0 - percent)
        LayoutHelpers.FromBottomIn(brp, root, percent)
    end

--*----------------------------------------------------------------------------

    local border = Border(root)
    border.Width:Set(100)
    border.Height:Set(100)
    LayoutHelpers.FromLeftIn(border, root, 0.1)
    LayoutHelpers.FromTopIn(border, root, 0.3)
    border:SetTextures('/textures/test/border_vert.png',
        '/textures/test/border_horiz.png',
        '/textures/test/border_ul.png',
        '/textures/test/border_ur.png',
        '/textures/test/border_ll.png',
        '/textures/test/border_lr.png')

    local fillparent = Bitmap(root)
    fillparent:SetSolidColor("green")
    LayoutHelpers.FillParent(fillparent, border)

    local fillparentrel = Bitmap(root)
    fillparentrel:SetSolidColor("blue")
    LayoutHelpers.FillParentRelativeBorder(fillparentrel, border, 0.10)

    local fillparentfixed = Bitmap(root)
    fillparentfixed:SetSolidColor("red")
    LayoutHelpers.FillParentFixedBorder(fillparentfixed, border, 30)


--*----------------------------------------------------------------------------

    local border = Border(root)
    border.Width:Set(100)
    border.Height:Set(100)
    LayoutHelpers.FromLeftIn(border, root, 0.80)
    LayoutHelpers.FromTopIn(border, root, 0.30)
    border:SetTextures('/textures/test/border_vert.png',
        '/textures/test/border_horiz.png',
        '/textures/test/border_ul.png',
        '/textures/test/border_ur.png',
        '/textures/test/border_ll.png',
        '/textures/test/border_lr.png')

    local percentin = Bitmap(root)
    percentin:SetSolidColor("red")
    LayoutHelpers.PercentIn(percentin, border, 0.10, 0.10, 0.30, 0.20)

    local offsetin = Bitmap(root)
    offsetin:SetSolidColor("green")
    LayoutHelpers.OffsetIn(offsetin, border, 50, 50, 70, 70)

--*----------------------------------------------------------------------------
    local centerSib = Button(root,
                          '/textures/test/button_normal.png',
                          '/textures/test/button_active.png',
                          '/textures/test/button_highlight.png')
    LayoutHelpers.FromBottomIn(centerSib, root, 0.20)
    LayoutHelpers.AtHorizontalCenterIn(centerSib, root)
    centerSib.Depth(100)

--[[
        centerSib.OnEnter = function()
        centerSib.Left:Set(function() return math.random(root.Width() - (centerSib.Width() * 2)) + centerSib.Width() end)
        centerSib.Top:Set(function() return math.random(root.Height() - (centerSib.Height() * 2)) + centerSib.Height() end)
        centerSib.Right:Set(function() return centerSib.Left() + centerSib.Width() end)
        centerSib.Bottom:Set(function() return centerSib.Top() + centerSib.Height() end)
    end
--]]

    local leftSib = Bitmap(root)
    leftSib:SetSolidColor("blue")
    leftSib.Width:Set(20)
    leftSib.Height:Set(20)
    LayoutHelpers.LeftOf(leftSib, centerSib)

    local rightSib = Bitmap(root)
    rightSib:SetSolidColor("blue")
    rightSib.Width:Set(20)
    rightSib.Height:Set(20)
    LayoutHelpers.RightOf(rightSib, centerSib)

    local topSib = Bitmap(root)
    topSib:SetSolidColor("blue")
    topSib.Width:Set(20)
    topSib.Height:Set(20)
    LayoutHelpers.Above(topSib, centerSib)

    local bottomSib = Bitmap(root)
    bottomSib:SetSolidColor("blue")
    bottomSib.Width:Set(20)
    bottomSib.Height:Set(20)
    LayoutHelpers.Below(bottomSib, centerSib)

    local leftSibOffset = Bitmap(root)
    leftSibOffset:SetSolidColor("blue")
    leftSibOffset.Width:Set(20)
    leftSibOffset.Height:Set(20)
    LayoutHelpers.LeftOf(leftSibOffset, centerSib, 30)

    local rightSibOffset = Bitmap(root)
    rightSibOffset:SetSolidColor("blue")
    rightSibOffset.Width:Set(20)
    rightSibOffset.Height:Set(20)
    LayoutHelpers.RightOf(rightSibOffset, centerSib, 30)

    local topSibOffset = Bitmap(root)
    topSibOffset:SetSolidColor("blue")
    topSibOffset.Width:Set(20)
    topSibOffset.Height:Set(20)
    LayoutHelpers.Above(topSibOffset, centerSib, 30)

    local bottomSibOffset = Bitmap(root)
    bottomSibOffset:SetSolidColor("blue")
    bottomSibOffset.Width:Set(20)
    bottomSibOffset.Height:Set(20)
    LayoutHelpers.Below(bottomSibOffset, centerSib, 30)

    centerSib.OnClick = function()
        if topSib:IsHidden() then topSib:Show() else topSib:Hide() end
        if topSibOffset:IsHidden() then topSibOffset:Show() else topSibOffset:Hide() end
    end

end

function TestEdit(root)
    local editLabel = Text(root)
    LayoutHelpers.AtLeftIn(editLabel, root, 5)
    LayoutHelpers.AtTopIn(editLabel, root, 5)
    editLabel:SetFont("Arial", 12)
    editLabel:SetText("Text edit")

    local editBorder = Border(root)
    editBorder.Width:Set(root.Width() * .8)
    editBorder.Height:Set(30)
    LayoutHelpers.Below(editBorder, editLabel)
    editBorder:SetTextures('/textures/test/border_vert.png',
        '/textures/test/border_horiz.png',
        '/textures/test/border_ul.png',
        '/textures/test/border_ur.png',
        '/textures/test/border_ll.png',
        '/textures/test/border_lr.png')

    local editControl = Edit(root)
    LayoutHelpers.FillParentFixedBorder(editControl, editBorder, 6)
    editControl.Depth:Set(function() return editBorder.Depth() + 1 end)

    local clearButton = Button(
                            root,
                            '/textures/test/clear.png',
                            '/textures/test/clear_down.png',
                            '/textures/test/clear_over.png')
    LayoutHelpers.Below(clearButton, editBorder, 10)

    clearButton.OnClick = function()
        editControl:ClearText()
    end

    scrollbar = Scrollbar(root)
    itemlist = ItemList(root)
    scrollbar:SetTextures(
        '/textures/test/scroll-bg.png',
        '/textures/test/scroll-thumb-mid.png',
        '/textures/test/scroll-thumb-top.png',
        '/textures/test/scroll-thumb-bottom.png')

    itemlist:SetFont("Microsoft Sans Serif", 16)
    for i,item in {
        "Bank Gothic Medium BT",
        "Arial",
        "Book Antiqua",
        "Bradley Hand ITC",
        "Castellar",
        "Comic Sans MS",
        "Courier New",
        "Curlz MT",
        "Edwardian Script ITC",
        "Fixedsys",
        "Franklin Gothic Book",
        "French Script MT",
        "Gill Sans MT Ext Condensed Bold",
        "Goudy Stout",
        "Imprint MT Shadow",
        "Lucida Console",
        "Maiandra GD",
        "Marlett",
        "Microsoft Sans Serif",
        "Modern",
        "Monotype Corsiva",
        "MS Reference Sans Serif",
        "MS Reference Specialty",
        "Papyrus",
        "Rage Italic",
        "Times New Roman",
        "Tw Cen MT",
        "VisualUI",
        "Webdings"
    } do
        itemlist:AddItem(item)
    end

    itemlist.Depth:Set(function() return root.Depth() + 100 end)
    LayoutHelpers.RightOf(itemlist, clearButton, 10)
    itemlist.Right:Set(function() return scrollbar.Left() end)
    itemlist.Bottom:Set(function() return root.Bottom() - 10 end)

    local scrollUp = Button(root,
        '/textures/test/scroll_button_up.png',
        '/textures/test/scroll_button_up_down.png',
        '/textures/test/scroll_button_up_over.png')

    scrollUp.Left:Set(itemlist.Right)
    scrollUp.Top:Set(itemlist.Top)
    scrollUp.Depth:Set(function() return root.Depth() + 99 end)

    local scrollDown = Button(root,
        '/textures/test/scroll_button_down.png',
        '/textures/test/scroll_button_down_down.png',
        '/textures/test/scroll_button_down_over.png')

    scrollDown.Left:Set(itemlist.Right)
    scrollDown.Bottom:Set(itemlist.Bottom)
    scrollDown.Depth:Set(function() return root.Depth() + 99 end)

    scrollbar.Depth:Set(function() return root.Depth() + 99 end)
    scrollbar.Top:Set(scrollUp.Bottom)
    scrollbar.Right:Set(editBorder.Right)
    scrollbar.Bottom:Set(scrollDown.Top)
    scrollbar.Width:Set(scrollUp.Width)

    scrollbar:SetScrollable(itemlist)
    scrollbar:AddButtons(scrollUp, scrollDown)

    local itemlistBorder = Border(root)
    itemlistBorder.Left:Set(function() return itemlist.Left() - 6 end)
    itemlistBorder.Right:Set(function() return scrollbar.Right() + 6 end)
    itemlistBorder.Top:Set(function() return itemlist.Top() - 6 end)
    itemlistBorder.Bottom:Set(function() return itemlist.Bottom() + 6 end)
    itemlistBorder:SetTextures('/textures/test/border_vert.png',
        '/textures/test/border_horiz.png',
        '/textures/test/border_ul.png',
        '/textures/test/border_ur.png',
        '/textures/test/border_ll.png',
        '/textures/test/border_lr.png')

    local numbersLabel = Text(root)
    LayoutHelpers.Below(numbersLabel, clearButton, 10)
    numbersLabel:SetFont("Arial", 12)
    numbersLabel:SetText("Numbers edit")

    local numbersEdit = Edit(root)
    LayoutHelpers.Below(numbersEdit, numbersLabel, 10)
    numbersEdit.Right:Set(function() return itemlist.Left() - 12 end)
    numbersEdit.Height:Set(numbersEdit:GetFontHeight())

    local numbersEditBorder = Border(root)
    numbersEditBorder.Left:Set(function() return numbersEdit.Left() - 6 end)
    numbersEditBorder.Right:Set(function() return numbersEdit.Right() + 6 end)
    numbersEditBorder.Top:Set(function() return numbersEdit.Top() - 6 end)
    numbersEditBorder.Bottom:Set(function() return numbersEdit.Bottom() + 6 end)
    numbersEditBorder:SetTextures('/textures/test/border_vert.png',
        '/textures/test/border_horiz.png',
        '/textures/test/border_ul.png',
        '/textures/test/border_ur.png',
        '/textures/test/border_ll.png',
        '/textures/test/border_lr.png')

    local outputLabel = Text(root)
    LayoutHelpers.Below(outputLabel, numbersEditBorder, 10)
    outputLabel:SetFont("Arial", 12)
    outputLabel:SetText("You just typed:")

    local output = Text(root)
    LayoutHelpers.Below(output, outputLabel, 10)
    output.Right:Set(itemlistBorder.Right)
    output:SetFont("Arial", 12)
    output:SetText("")

    local bgToggle = Checkbox(root, '/textures/test/unchecked.png', '/textures/test/checked.png')
    LayoutHelpers.Below(bgToggle, output, 10)

    local bgToggleState = Text(root)
    LayoutHelpers.Below(bgToggleState, bgToggle, 10)
    bgToggleState.Right:Set(itemlistBorder.Right)
    bgToggleState:SetFont("Arial", 12)
    if bgToggle:IsChecked() then
        bgToggleState:SetText("Checked")
    else
        bgToggleState:SetText("Not checked")
    end

--
--  Click behaviors
--
    numbersEdit.OnTextChanged = function(control, newText, oldText)
        local caretPos = control:GetCaretPosition()
        local numberString = string.gsub(newText, "[^0-9]", "")
        control:SetText(numberString)
    end

    editControl.OnEnterPressed = function(control, text)
       output:SetText(text)
    end

    itemlist.OnClick = function(item, row)
        editControl:SetFont(item:GetItem(row), 50)
        editBorder.Height:Set(editControl:GetFontHeight() + 12)
        item:SetSelection(row)
    end

    bgToggle.OnCheck = function(control, checked)
        if checked then
            bgToggleState:SetText("Checked")
        else
            bgToggleState:SetText("Not checked")
        end
    end
end

function TestRadio(root)
-- layout radio buttons
    local radio = RadioButtons(
        root,
        'Test Radio',
        {'foo', 'bar', 'moo'},
        'foo',
        'Arial', 12,
        '/textures/test/unchecked.png', '/textures/test/checked.png')

    radio.Left:Set(root.Left)
    radio.Top:Set(root.Top)

    local output = Text(root)
    LayoutHelpers.RightOf(output, radio, 10)
    output:SetFont("Arial", 24)

    radio.OnChoose = function(control, button)
        output:SetText('You selected: ' .. button)
    end

-- vertical slider
    local vslider = Slider(root, true, 0, 100, '/textures/test/slider-thumb.png', '/textures/test/slider-bg-vert.png')
    LayoutHelpers.RightOf(vslider, output, 10)

-- horizontal slider
    local hslider = IntegerSlider(root, false, 25, 50, 5, '/textures/test/slider-thumb.png', '/textures/test/slider-bg-horz.png')
    LayoutHelpers.Below(hslider, vslider, 10)

-- status bar
    hStatusBar = StatusBar(root, 25, 50, false, false, '/textures/test/statusbar-bg-horz.png', '/textures/test/statusbar-horz.png', true)
    LayoutHelpers.Below(hStatusBar, hslider, 10)

    vStatusBar = StatusBar(root, 0, 100, true, false, '/textures/test/statusbar-bg-vert.png', '/textures/test/statusbar-vert.png')
    LayoutHelpers.RightOf(vStatusBar, vslider, 10)

    hnStatusBar = StatusBar(root, 25, 50, false, true, '/textures/test/statusbar-bg-horz.png', '/textures/test/statusbar-horz.png')
    LayoutHelpers.Below(hnStatusBar, hStatusBar, 10)

    vnStatusBar = StatusBar(root, 0, 100, true, true, '/textures/test/statusbar-bg-vert.png', '/textures/test/statusbar-vert.png', true)
    LayoutHelpers.RightOf(vnStatusBar, vStatusBar, 10)

    local vOutput = Text(root)
    vOutput:SetFont("Arial", 18)
    LayoutHelpers.RightOf(vOutput, vnStatusBar, 10)

    local hOutput = Text(root)
    hOutput:SetFont("Arial", 18)
    LayoutHelpers.Below(hOutput, hnStatusBar, 10)

    vslider.OnValueSet = function(self, newValue)
        vOutput:SetText('Set to: ' .. newValue)
        vStatusBar:SetValue(newValue)
    end

    vslider.OnValueChanged = function(self, newValue)
        vStatusBar:SetValue(newValue)
        vnStatusBar:SetValue(newValue)
    end

    hslider.OnValueChanged = function(self, newValue)
        hOutput:SetText('Changed to: ' .. newValue)
        hStatusBar:SetValue(newValue)
        hnStatusBar:SetValue(newValue)
    end

-- alpha hit button
    local background = Bitmap(root, '/textures/test/128x128.png')
    LayoutHelpers.RightOf(background, hslider, 10)

    local alphaButton = Button(background,
        '/textures/test/alpha_button_normal.png',
        '/textures/test/alpha_button_active.png',
        '/textures/test/alpha_button_highlight.png')
    alphaButton:UseAlphaHitTest(true)
    LayoutHelpers.FillParent(alphaButton, background)

-- border from color
    local border = Border(root)
    LayoutHelpers.Below(border, radio, 10)
    border.Width:Set(32)
    border.Height:Set(32)
    border:SetSolidColor("yellow")
    border.InnerTop:Set(function() return border.Top() + 10 end)


-- This is code which allows us to move a control with the mouse
    radio.HandleEvent = function(control, event)
        local eventHandled = false
        if event.Type == 'ButtonPress' or event.Type == 'ButtonDClick' then
            local dragger = Dragger()
            dragger.OnMove = function(dragger, x, y)
                radio.Left:Set(x)
                radio.Top:Set(y)
            end
            PostDragger(nil,event.KeyCode,dragger)
            eventHandled = true
        end
        return eventHandled
    end

end

function TestAnim(root)
    local animation = Bitmap(root)
    animation:SetTexture({  '/textures/test/anim-0.png',
                            '/textures/test/anim-1.png',
                            '/textures/test/anim-2.png',
                            '/textures/test/anim-3.png',
                            '/textures/test/anim-4.png'})
    LayoutHelpers.AtLeftIn(animation, root)
    LayoutHelpers.AtTopIn(animation, root)


    local playButton =  Button(root,
        '/textures/test/button_play.png',
        '/textures/test/button_play_down.png',
        '/textures/test/button_play_over.png')
    LayoutHelpers.Below(playButton, animation, 10)


    local stopButton =  Button(root,
        '/textures/test/button_stop.png',
        '/textures/test/button_stop_down.png',
        '/textures/test/button_stop_over.png')
    LayoutHelpers.RightOf(stopButton, playButton, 10)


    local loopToggle = Checkbox(root, '/textures/test/unchecked.png', '/textures/test/checked.png')
    LayoutHelpers.RightOf(loopToggle, stopButton, 10)

    local loopToggleLabel = Text(root)
    loopToggleLabel:SetFont("Bank Gothic Medium BT", 16)
    loopToggleLabel:SetText("Loop")
    LayoutHelpers.CenteredRightOf(loopToggleLabel, loopToggle)

    local frameRateSelect = IntegerSlider(root, false, 1, 30, 1, '/textures/test/slider-thumb.png', '/textures/test/slider-bg-horz.png')
    LayoutHelpers.Below(frameRateSelect, playButton, 15)
    frameRateSelect:SetValue(12)

    local frameRateSelectLabel = Text(root)
    frameRateSelectLabel:SetFont("Bank Gothic Medium BT", 16)
    frameRateSelectLabel:SetText("FPS=")
    LayoutHelpers.RightOf(frameRateSelectLabel, frameRateSelect)

    local frameRateDisplay = Text(root)
    frameRateDisplay:SetFont("Bank Gothic Medium BT", 16)
    frameRateDisplay:SetText(frameRateSelect:GetValue())
    LayoutHelpers.RightOf(frameRateDisplay, frameRateSelectLabel)

    local frameSelect = IntegerSlider(root, false, 0, animation:GetNumFrames() - 1, 1, '/textures/test/slider-thumb.png', '/textures/test/slider-bg-horz.png')
    LayoutHelpers.Below(frameSelect, frameRateSelect, 15)

    local frameSelectLabel = Text(root)
    frameSelectLabel:SetFont("Bank Gothic Medium BT", 16)
    frameSelectLabel:SetText("Frame=")
    LayoutHelpers.RightOf(frameSelectLabel, frameSelect)

    local frameDisplay = Text(root)
    frameDisplay:SetFont("Bank Gothic Medium BT", 16)
    frameDisplay:SetText(frameSelect:GetValue())
    LayoutHelpers.RightOf(frameDisplay, frameSelectLabel)

    local selectPattern = RadioButtons(
        root,
        'Select Pattern',
        {'Forward', 'Backward', 'Ping Pong', 'Loop Ping Pong', 'Pattern'},
        'Forward',
        'Arial', 14, "blue",
        '/textures/test/unchecked.png', '/textures/test/checked.png')

    selectPattern.Left:Set(frameDisplay.Right)
    selectPattern.Top:Set(root.Top)

-- Operations
    animation.OnAnimationFrame = function(self, frameValue)
        frameSelect:SetValue(frameValue)
    end

    playButton.OnClick = function(self)
        animation:Play()
    end

    stopButton.OnClick = function(self)
        animation:Stop()
    end

    frameRateSelect.OnValueChanged = function(self, newValue)
        frameRateDisplay:SetText(newValue)
        animation:SetFrameRate(newValue)
    end

    frameSelect.OnValueChanged = function(self, newValue)
        animation:SetFrame(newValue)
        frameDisplay:SetText(newValue)
    end

    loopToggle.OnCheck = function(self, checked)
        animation:Loop(checked)
    end

    selectPattern.OnChoose = function(self, button)
        animation:SetFrame(0)
        if button == 'Forward' then
            animation:SetForwardPattern()
        elseif button == 'Backward' then
            animation:SetBackwardPattern()
        elseif button == 'Ping Pong' then
            animation:SetPingPongPattern()
        elseif button == 'Loop Ping Pong' then
            animation:SetLoopPingPongPattern()
        elseif button == 'Pattern' then
            animation:SetFramePattern({0,1,5,-1,3,4,2,1,1,2,2,2,1})
        end
        frameSelect:SetEndValue(animation:GetNumFrames() - 1)
    end
end
