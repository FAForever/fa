-- A combo box consists of a text control, a button to expand it, and a dropdown selectable list
-- this is a custom control as it its default has very game specific look to it
-- Combo box will need to have its width set, but height will be auto based on the bitmaps

local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local LazyVar = import("/lua/lazyvar.lua")
local UIMain = import("/lua/ui/uimain.lua")
local UIUtil = import("/lua/ui/uiutil.lua")
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local Group = import("/lua/maui/group.lua").Group
local ItemList = import("/lua/maui/itemlist.lua").ItemList


---@class ComboBitmaps
---@field button ComboButtonSideBitmaps
---@field list ComboBorderBitmaps

---@class ComboButtonSideBitmaps
---@field left ComboButtonBitmaps
---@field mid ComboButtonBitmaps
---@field right ComboButtonBitmaps

---@class ComboBorderBitmaps
---@field ul Lazy<FileName>
---@field um Lazy<FileName>
---@field ur Lazy<FileName>
---@field l Lazy<FileName>
---@field m Lazy<FileName>
---@field r Lazy<FileName>
---@field ll Lazy<FileName>
---@field lm Lazy<FileName>
---@field lr Lazy<FileName>

---@class ComboButtonBitmaps
---@field up Lazy<FileName>
---@field down Lazy<FileName>
---@field over Lazy<FileName>
---@field dis Lazy<FileName>


local defaultBitmaps = {
    button = {
        left = {
            up = UIUtil.SkinnableFile('/widgets/drop-down/drop_btn_up_l.dds'),
            down = UIUtil.SkinnableFile('/widgets/drop-down/drop_btn_down_l.dds'),
            over = UIUtil.SkinnableFile('/widgets/drop-down/drop_btn_over_l.dds'),
            dis = UIUtil.SkinnableFile('/widgets/drop-down/drop_btn_dis_l.dds'),
        },
        mid = {
            up = UIUtil.SkinnableFile('/widgets/drop-down/drop_btn_up_m.dds'),
            down = UIUtil.SkinnableFile('/widgets/drop-down/drop_btn_down_m.dds'),
            over = UIUtil.SkinnableFile('/widgets/drop-down/drop_btn_over_m.dds'),
            dis = UIUtil.SkinnableFile('/widgets/drop-down/drop_btn_dis_m.dds'),
        },
        right = {
            up = UIUtil.SkinnableFile('/widgets/drop-down/drop_btn_up_r.dds'),
            down = UIUtil.SkinnableFile('/widgets/drop-down/drop_btn_down_r.dds'),
            over = UIUtil.SkinnableFile('/widgets/drop-down/drop_btn_over_r.dds'),
            dis = UIUtil.SkinnableFile('/widgets/drop-down/drop_btn_dis_r.dds'),
        }
    },
    list = {
       ul = UIUtil.SkinnableFile('/widgets/drop-down/drop-box_brd_ul.dds'),
       um = UIUtil.SkinnableFile('/widgets/drop-down/drop-box_brd_horz_um.dds'),
       ur = UIUtil.SkinnableFile('/widgets/drop-down/drop-box_brd_ur.dds'),
       l = UIUtil.SkinnableFile('/widgets/drop-down/drop-box_brd_vert_l.dds'),
       m = UIUtil.SkinnableFile('/widgets/drop-down/drop-box_brd_m.dds'),
       r = UIUtil.SkinnableFile('/widgets/drop-down/drop-box_brd_vert_r.dds'),
       ll = UIUtil.SkinnableFile('/widgets/drop-down/drop-box_brd_ll.dds'),
       lm = UIUtil.SkinnableFile('/widgets/drop-down/drop-box_brd_lm.dds'),
       lr = UIUtil.SkinnableFile('/widgets/drop-down/drop-box_brd_lr.dds'),
    },
}


local activeCombo = nil



---@class Combo : Group
---@field _btnLeft Button
---@field _btnMid Button
---@field _btnRight Button
---@field _dropdown Group
---@field _list ItemList
---@field _scrollbar? Scrollbar
---@field _text Text
---
---@field _visibleItems LazyVar<number>
---
---@field buttonBitmaps ComboButtonSideBitmaps
---@field EnableColor? boolean if the default title color is used when the default item is selected
---@field mClickCue? string
---@field mItemCue string
---@field mRolloverCue? string
---@field _defaultIndex? number
---@field _listhidden boolean
---@field _maxVisibleItems number
---@field _scrollbarOffsetRight number defaults to -22
---@field _scrollbarOffsetBottom number defaults to -6
---@field _scrollbarOffsetTop number defaults to -6
---@field _staticTitle? boolean the title will not be set to the selected item when true
---@field _titleColor? Color
---@field _titleDefaultColor? Color the title color used when the default item is selected (and `EnableColor` is true)
Combo = ClassUI(Group) {
    ---@param self Combo
    ---@param parent Control
    ---@param pointSize? number defaults to 12
    ---@param maxVisibleItems? number defaults to 10
    ---@param staticTitle? boolean
    ---@param bitmaps? ComboBitmaps defaults to the bitmaps for `/widgets/drop-down/`
    ---@param rolloverCue? string
    ---@param clickCue? string
    ---@param itemCue? string defaults to `"UI_Tab_Click_01"`
    ---@param debugName? string defaults to `"Combo"`
    ---@param enableColor? boolean defaults to true
    __init = function(self, parent, pointSize, maxVisibleItems, staticTitle, bitmaps, rolloverCue, clickCue, itemCue, debugName, enableColor)
        pointSize = pointSize or 12
        maxVisibleItems = maxVisibleItems or 10
        bitmaps = bitmaps or defaultBitmaps
        itemCue = itemCue or "UI_Tab_Click_01"
        debugName = debugName or "Combo"
        if enableColor == nil then enableColor = true end

        Group.__init(self, parent)
        self:SetName(debugName)
        self.mRolloverCue = rolloverCue
        self.mClickCue = clickCue
        self.mItemCue = itemCue
        self.buttonBitmaps = bitmaps.button
        self.EnableColor = enableColor

        -- sets the offsets to the auto-attached scrollbar
        -- these are the better defaults for the FAF design
        self._scrollbarOffsetRight = -22
        self._scrollbarOffsetBottom = -6
        self._scrollbarOffsetTop = -6

        -- this sets if the title is fixed or changes when a new selection is made
        self._staticTitle = staticTitle

        self._btnLeft = Bitmap(self, bitmaps.button.left.up)
        self._btnRight = Bitmap(self, bitmaps.button.right.up)
        self._btnMid = Bitmap(self, bitmaps.button.mid.up)
        self._btnLeft:DisableHitTest()
        self._btnRight:DisableHitTest()
        self._btnMid:DisableHitTest()

        LayoutHelpers.AtLeftTopIn(self._btnLeft, self)
        LayoutHelpers.AtRightTopIn(self._btnRight, self)
        LayoutHelpers.AtTopIn(self._btnMid, self)
        LayoutHelpers.AnchorToRight(self._btnMid, self._btnLeft, -1)
        self._btnMid.Right:Set(self._btnRight.Left)

        self._text = UIUtil.CreateText(self._btnMid, "", pointSize, UIUtil.bodyFont)
        self._text:DisableHitTest()

        -- text control is height of text/font, and from left to button
        self.Height:Set(function()
            return math.max(self._text.Height(), self._btnMid.Height())
        end)
        self._text.Top:Set(self._btnMid.Top)
        LayoutHelpers.AtLeftIn(self._text, self._btnLeft, 5)
        LayoutHelpers.AtRightIn(self._text, self._btnMid, -5)
        self._text:SetClipToWidth(true)
        self._text:SetDropShadow(true)

        local dropdown = Group(self._text)
        dropdown.Top:Set(self.Bottom)
        dropdown.Right:Set(self.Right)
        dropdown.Width:Set(function()
            return self.Width() - LayoutHelpers.ScaleNumber(5)
        end)
        self._dropdown = dropdown

        local border = bitmaps.list
        local ddul = Bitmap(dropdown, border.ul)
        local ddum = Bitmap(dropdown, border.um)
        local ddur = Bitmap(dropdown, border.ur)
        local ddl = Bitmap(dropdown, border.l)
        local ddm = Bitmap(dropdown, border.m)
        local ddr = Bitmap(dropdown, border.r)
        local ddll = Bitmap(dropdown, border.ll)
        local ddlm = Bitmap(dropdown, border.lm)
        local ddlr = Bitmap(dropdown, border.lr)

        -- top part is fixed under self
        LayoutHelpers.AtLeftTopIn(ddul, dropdown)
        LayoutHelpers.AtRightTopIn(ddur, dropdown)
        LayoutHelpers.AtTopIn(ddum, dropdown)
        ddum.Left:Set(ddul.Right)
        ddum.Right:Set(ddur.Left)

        local list = ItemList(ddm)   -- make list depth over text so if you have them stacked, you see list
        list:SetFont(UIUtil.bodyFont, pointSize)
        list:SetColors(UIUtil.fontColor, "Black", UIUtil.fontColor, "Black")
        if staticTitle then
            list:ShowSelection(false)
        end
        list:ShowMouseoverItem(true)
        self._list = list

        -- middle part is fixed to width, set to height of item list
        ddl.Top:Set(ddul.Bottom)
        ddl.Left:Set(dropdown.Left)
        ddr.Top:Set(ddur.Bottom)
        ddr.Right:Set(dropdown.Right)
        ddm.Top:Set(ddum.Bottom)
        ddm.Left:Set(ddl.Right)
        ddm.Right:Set(ddr.Left)
        ddm.Height:Set(list.Height)
        ddl.Height:Set(list.Height)
        ddr.Height:Set(list.Height)
        ddll.Bottom:Set(dropdown.Bottom)
        ddll.Left:Set(dropdown.Left)
        ddlr.Bottom:Set(dropdown.Bottom)
        ddlr.Right:Set(dropdown.Right)
        ddlm.Bottom:Set(dropdown.Bottom)
        ddlm.Left:Set(ddll.Right)
        ddlm.Right:Set(ddlr.Left)

        -- list is always under the control and the width (scrollbar under button)
        list.Top:Set(ddm.Top)
        list.Left:Set(ddm.Left)
        list.Right:Set(ddm.Right)

        list.HandleEvent = function(_, event)
            if event.Type == 'MouseExit' then
                self:OnMouseExit()
            end
        end

        -- hide the list on creation
        self._listhidden = true
        dropdown:Hide()

        -- supress show when list is in hidden state
        dropdown.OnHide = function(self_dropdown, hidden)
            if not hidden and self._listhidden then
                return true
            end

            if self:IsDisabled() then
                self._listhidden = true
                activeCombo = nil
                return
            end

            local button_bitmap = self.buttonBitmaps
            if not hidden then
                self._btnLeft:SetTexture(button_bitmap.left.down)
                self._btnRight:SetTexture(button_bitmap.right.down)
                self._btnMid:SetTexture(button_bitmap.mid.down)
                self._text:SetColor("Black")
                self:OnMouseExit()
                if activeCombo and activeCombo ~= self then
                    activeCombo._listhidden = true
                    activeCombo._dropdown:SetHidden(true)
                end
                activeCombo = self
                self_dropdown.Depth:Set(self:GetRootFrame():GetTopmostDepth() + 1)
            else
                self._btnLeft:SetTexture(button_bitmap.left.up)
                self._btnRight:SetTexture(button_bitmap.right.up)
                self._btnMid:SetTexture(button_bitmap.mid.up)
                if self.EnableColor and self._list:GetSelection() + 1 == self._defaultIndex then
                    self._text:SetColor(self._titleDefaultColor or 'DBDBBA') -- Yellow
                else
                    self._text:SetColor(self._titleColor or UIUtil.fontColor)
                end
                activeCombo = nil
                self:OnHide()
            end
        end

        -- set the height of the list based on the number of items visible and the font metrics
        self._maxVisibleItems = maxVisibleItems
        self._visibleItems = LazyVar.Create()
        list.Height:Set(function()
            local text = self._text
            return self._visibleItems() * (text.FontAscent() + text.FontDescent() + text.FontExternalLeading()) + 1
        end)
        dropdown.Height:Set(function()
            return self._list.Height() + ddum.Height() + ddlm.Height()
        end)

        -- set up selection logic
        list.OnClick = function(self_list, row)
            self:SetItem(row + 1)
            self:OnClick(row + 1, self_list:GetItem(row))
            self._listhidden = true
            self._dropdown:SetHidden(true)
        end

        list.OnMouseoverItem = function(self_list, row)
            if self.mItemCue then
                PlaySound(Sound {
                    Cue = self.mItemCue,
                    Bank = "Interface",
                })
            end
            if row == -1 then
                self:OnOverItem(-1, nil)
            else
                self:OnOverItem(row + 1, self_list:GetItem(row))
            end
        end

        local OnGlobalMouseClick = function(event)
            if self._list and not self._listhidden then
                local rightCheck
                if self._scrollbar then
                    rightCheck = self._scrollbar.Right()
                else
                    rightCheck = self.Right()
                end
                local x, y = event.x, event.y
                if x < self.Left() or x > rightCheck or y < self.Top() or y > self._dropdown.Bottom() then
                    local new_state = not self._dropdown:IsHidden()
                    self._listhidden = new_state
                    self._dropdown:SetHidden(new_state)
                end
            end
        end

        UIMain.AddOnMouseClickedFunc(OnGlobalMouseClick)
        self._globalMouseClickFn = OnGlobalMouseClick -- keep for removal on destruction
    end,

    --- Adds an array of strings, and also sets the visible size
    ---@param self Combo
    ---@param textArray UnlocalizedString[]
    ---@param selectedIndex? integer defaults to 1
    ---@param defaultIndex? integer defaults to no default item
    AddItems = function(self, textArray, selectedIndex, defaultIndex)
        selectedIndex = selectedIndex or 1
        self._defaultIndex = defaultIndex

        local numItems = self._visibleItems() + table.getn(textArray)
        local visibleItems = math.min(numItems, self._maxVisibleItems)
        self._visibleItems:Set(visibleItems)
        local list = self._list

        if numItems > visibleItems then
            if not self._scrollbar then
                self._scrollbar = UIUtil.CreateVertScrollbarFor(list, self._scrollbarOffsetRight,
                        nil, self._scrollbarOffsetBottom, self._scrollbarOffsetTop)
            end
        elseif self._scrollbar then
            self._scrollbar:Destroy()
            self._scrollbar = nil
        end

        for i, text in ipairs(textArray) do
            local item = LOC(text)
            if i == defaultIndex then
                item = LOC("<LOC gameui_0010>%s (default)"):format(item)
            end
            list:AddItem(item)
        end

        self:SetItem(selectedIndex)
    end,

    -- helper function to (re)set scrollbar offsets for dialogs or UI parts using Vanila design (Replays, Multiplayer LAN, etc)
    ---@param self Combo
    ---@param offset_right number
    ---@param offset_bottom number
    ---@param offset_top number
    SetScrollBarOffsets = function(self, offset_right, offset_bottom, offset_top)
        self._scrollbarOffsetRight = offset_right or 0
        self._scrollbarOffsetBottom = offset_bottom or 0
        self._scrollbarOffsetTop = offset_top or 0
    end,

    ---@param self Combo
    ClearItems = function(self)
        self._visibleItems:Set(0)
        self._list:DeleteAllItems()
        self._text:SetText("")
        self._text:SetColor(UIUtil.fontColor) -- Gris
        if self._scrollbar then
            self._scrollbar:Destroy()
            self._scrollbar = nil
        end
    end,

    ---@param self Combo
    ---@param index number set the index selected (1 based!)
    SetItem = function(self, index)
        ItemList.OnClick(self._list, index - 1)
        if not self._staticTitle then
            self._text:SetText(self._list:GetItem(index - 1))
            if self.EnableColor and index == self._defaultIndex then
                self._text:SetColor(self._titleDefaultColor or 'DBDBBA') -- Yellow
            end
        end
    end,

    -- get the index selected (1 based!) and the item
    ---@param self Combo
    ---@return number
    ---@return number|nil
    GetItem = function(self)
        local sel = self._list:GetSelection()
        if sel >= 0 then
            return sel + 1, self._list:GetItem(sel)
        else
            return -1, nil
        end
    end,

    ---@param self Combo
    ---@param text string
    SetTitleText = function(self, text)
        self._text:SetText(text)
    end,

    ---@param self Combo
    ---@param color Color
    ---@param defaultColor? Color color use for when the default item is selected
    SetTitleTextColor = function(self, color, defaultColor)
        self._titleColor = color
        if defaultColor then
            self._titleDefaultColor = defaultColor
            if self._list:GetSelection() + 1 == self._defaultIndex then
                color = defaultColor
            end
        end
        self._text:SetColor(color)
    end,

    -- overload to get clicks
    ---@param self Combo
    ---@param index number
    ---@param text string
    OnClick = function(self, index, text)
        --if line.combo.EnableColor then line.combo:SetTitleTextColor('BADBBA') end -- Green
    end,

    ---@param self Combo
    OnEvent = function(self)
    end,

    ---@param self Combo
    OnMouseExit = function(self)
    end,

    -- overload to get rolled over item index
    ---@param self Combo
    ---@param index number
    ---@param text string
    OnOverItem = function(self, index, text)
    end,

    -- Triggered when the dropdown list is hidden
    OnHide = function()
    end,

    ---@param self Combo
    OnDisable = function(self)
        local button = self.buttonBitmaps
        self._btnLeft:SetTexture(button.left.dis)
        self._btnRight:SetTexture(button.right.dis)
        self._btnMid:SetTexture(button.mid.dis)
        if not self.EnableColor then
            self._text:SetColor(self._titleColor or UIUtil.fontColor)
        end
        self._dropdown:Hide()
    end,

    ---@param self Combo
    OnEnable = function(self)
        local button = self.buttonBitmaps
        self._btnLeft:SetTexture(button.left.up)
        self._btnRight:SetTexture(button.right.up)
        self._btnMid:SetTexture(button.mid.up)
        if not self.EnableColor then
            self._text:SetColor(self._titleColor or UIUtil.fontColor)
        end
    end,

    ---@param self Combo
    ---@param event Event
    ---@return boolean
    HandleEvent = function(self, event)
        local eventHandled = false

        if self:IsDisabled() then
            return eventHandled
        end

        local buttonBitmaps = self.buttonBitmaps
        if event.Type == 'MouseEnter' then
            if self._dropdown:IsHidden() then
                self._btnLeft:SetTexture(buttonBitmaps.left.over)
                self._btnRight:SetTexture(buttonBitmaps.right.over)
                self._btnMid:SetTexture(buttonBitmaps.mid.over)
                if not self.EnableColor then self._text:SetColor(self._titleColor or UIUtil.fontColor) end
                if self.mRolloverCue then
                    PlaySound(Sound {
                        Cue = self.mRolloverCue,
                        Bank = "Interface",
                    })
                end
            end
            eventHandled = true
        elseif event.Type == 'MouseExit' then
            if self._dropdown:IsHidden() then
                self._btnLeft:SetTexture(buttonBitmaps.left.up)
                self._btnRight:SetTexture(buttonBitmaps.right.up)
                self._btnMid:SetTexture(buttonBitmaps.mid.up)
                if not self.EnableColor then
                    self._text:SetColor(self._titleColor or UIUtil.fontColor)
                end
            end
            self:OnMouseExit()
            eventHandled = true
        elseif event.Type == 'ButtonPress' then
            self._listhidden = not self._dropdown:IsHidden()
            self._dropdown:SetHidden(not self._dropdown:IsHidden())
            if self.mClickCue then
                PlaySound(Sound {
                    Cue = self.mClickCue,
                    Bank = "Interface",
                })
            end
            eventHandled = true
        end
        self:OnEvent(event)

        return eventHandled
    end,

    ---@param self Combo
    OnDestroy = function(self)
        if self._globalMouseClickFn then
            UIMain.RemoveOnMouseClickedFunc(self._globalMouseClickFn)
            self._globalMouseClickFn = nil
        end
    end,
}

---------------------------------------------------------------------------------------------------------------------------------------- BITMAP COMBO
-- This combo is used when you have a few bitmaps you want to choose between, no scrollbar.
-- NOTE: At some point a flexible control combo that uses grid should be made so anything can be in it
-- bitmap array expects an array of bitmap names or colors
---@class BitmapCombo : Group
---@field ddm Bitmap
---@field _bitmap Bitmap
---@field _btnLeft Button
---@field _btnMid Bitmap
---@field _btnRight Button
---@field _dropdown Group
---@field _list? Group[]
---
---@field mRolloverCue? string
---@field mClickCue? string
---@field _array FileName[] | Color[]
---@field _bitmaps ComboBitmaps
---@field _curIndex number
---@field _ddhidden? boolean
---@field _globalMouseClickFn function
---@field _isColor? boolean
BitmapCombo = ClassUI(Group) {

    ---@param self BitmapCombo
    ---@param parent Group
    ---@param bitmapArray any
    ---@param defaultIndex any
    ---@param isColor any
    ---@param bitmaps ComboBitmaps
    ---@param rolloverCue any
    ---@param clickCue any
    ---@param debugName string
    __init = function(self, parent, bitmapArray, defaultIndex, isColor, bitmaps, rolloverCue, clickCue, debugName)
        bitmaps = bitmaps or defaultBitmaps
        debugName = debugName or "BitmapCombo"

        Group.__init(self, parent)
        self:SetName(debugName)

        self.mRolloverCue = rolloverCue
        self.mClickCue = clickCue
        self._bitmaps = bitmaps

        self._btnLeft = Bitmap(self, bitmaps.button.left.up)
        self._btnRight = Bitmap(self, bitmaps.button.right.up)
        self._btnMid = Bitmap(self, bitmaps.button.mid.up)
        self._btnLeft:DisableHitTest()
        self._btnRight:DisableHitTest()
        self._btnMid:DisableHitTest()

        self.Height:Set(self._btnMid.Height)

        LayoutHelpers.AtLeftTopIn(self._btnLeft, self)
        LayoutHelpers.AtRightTopIn(self._btnRight, self)
        LayoutHelpers.AtTopIn(self._btnMid, self)

        LayoutHelpers.AnchorToRight(self._btnMid, self._btnLeft, -1)
        self._btnMid.Right:Set(self._btnRight.Left)

        self._bitmap = Bitmap(self._btnMid)
        LayoutHelpers.AtTopIn(self._bitmap, self._btnMid, 2)
        LayoutHelpers.AtLeftIn(self._bitmap, self._btnLeft, 5)
        self._bitmap:DisableHitTest()

        self._dropdown = Group(self)
        LayoutHelpers.DepthOverParent(self._dropdown, self._bitmap, 1)
        self._dropdown:Hide()

        -- Create the dropdown background. It's a crude approximation to a nine-patch.
        local border = bitmaps.list
        local ddul = Bitmap(self._dropdown, border.ul)
        local ddum = Bitmap(self._dropdown, border.um)
        local ddur = Bitmap(self._dropdown, border.ur)
        local ddl = Bitmap(self._dropdown, border.l)
        self.ddm = Bitmap(self._dropdown)
        self.ddm:SetSolidColor("black")
        local ddr = Bitmap(self._dropdown, border.r)
        local ddll = Bitmap(self._dropdown, border.ll)
        local ddlm = Bitmap(self._dropdown, border.lm)
        local ddlr = Bitmap(self._dropdown, border.lr)

        -- top part is fixed under self
        LayoutHelpers.AnchorToBottom(ddul, self._btnMid)
        LayoutHelpers.AtLeftIn(ddul, self._btnLeft, 5)
        LayoutHelpers.AnchorToBottom(ddur, self._btnMid)
        LayoutHelpers.AtRightIn(ddur, self._btnRight)
        LayoutHelpers.AnchorToBottom(ddum, self._btnMid)
        LayoutHelpers.AnchorToRight(ddum, ddul)
        LayoutHelpers.AnchorToLeft(ddum, ddur)

        -- middle part is fixed to width, set to height of item list
        ddl.Top:Set(ddul.Bottom)
        ddl.Left:Set(ddul.Left)
        ddr.Top:Set(ddur.Bottom)
        ddr.Right:Set(ddur.Right)
        self.ddm.Top:Set(ddum.Bottom)
        self.ddm.Left:Set(ddl.Right)
        self.ddm.Right:Set(ddr.Left)
        LayoutHelpers.ResetHeight(self.ddm)
        ddl.Height:Set(self.ddm.Height)
        ddr.Height:Set(self.ddm.Height)

        LayoutHelpers.AnchorToBottom(ddll, ddl)
        LayoutHelpers.AtLeftIn(ddll, ddl)

        LayoutHelpers.AnchorToBottom(ddlr, ddr)
        LayoutHelpers.AtRightIn(ddlr, ddr)

        LayoutHelpers.AnchorToBottom(ddlm, self.ddm)
        LayoutHelpers.AnchorToRight(ddlm, ddl)
        LayoutHelpers.AnchorToLeft(ddlm, ddr)

        LayoutHelpers.FillParent(self._dropdown, self.ddm)

        -- Populate the dropdown with bitmaps.
        self:ChangeBitmapArray(bitmapArray, isColor)

        self:SetItem(defaultIndex)
        self._curIndex = defaultIndex


        self._dropdown.HandleEvent = function(_, event)
            if event.Type == 'MouseExit' then
                self:OnMouseExit()
            end
        end
        -- supress show when list is in hidden state
        self._dropdown.OnHide = function(_, hidden)
            if not hidden and self._ddhidden then
                return true
            end

            if self:IsDisabled() then
                self._ddhidden = true
                activeCombo = nil
                return
            end

            local bitmapButton = self._bitmaps.button
            if not hidden then
                self._btnLeft:SetTexture(bitmapButton.left.down)
                self._btnRight:SetTexture(bitmapButton.right.down)
                self._btnMid:SetTexture(bitmapButton.mid.down)
                if activeCombo and activeCombo ~= self then
                    activeCombo._ddhidden = true
                    activeCombo._dropdown:SetHidden(true)
                end
                activeCombo = self
            else
                self._btnLeft:SetTexture(bitmapButton.left.up)
                self._btnRight:SetTexture(bitmapButton.right.up)
                self._btnMid:SetTexture(bitmapButton.mid.up)
                activeCombo = nil
            end
        end

        local OnGlobalMouseClick = function(event)
            if self and self._dropdown and not self._ddhidden then
                local x, y = event.x, event.y
                if x < self.Left() or x > self.Right() or y < self.Top() or y > self._dropdown.Bottom() then
                    local new_state = not self._dropdown:IsHidden()
                    self._ddhidden = new_state
                    self._dropdown:SetHidden(new_state)
                end
            end
        end

        UIMain.AddOnMouseClickedFunc(OnGlobalMouseClick)
        self._globalMouseClickFn = OnGlobalMouseClick
    end,

    -- Nuke the old bitmap array and replace it
    ---@param self BitmapCombo
    ---@param bitmapArray BitmapCombo[]
    ---@param isColor boolean?
    ChangeBitmapArray = function(self, bitmapArray, isColor)
        if self._list then
            for k,v in self._list do
                v:Destroy()
            end
        end

        self._array = bitmapArray
        self._isColor = isColor
        self._list = {}

        local prev = nil
        local elementNum = 1
        for index, bmp in bitmapArray do
            local listUIElement = Group(self._dropdown)
            local newBitmap = Bitmap(listUIElement)
            LayoutHelpers.DepthOverParent(newBitmap, listUIElement, 2)   -- make room for highlight underneath
            listUIElement.Width:Set(self._dropdown.Width)
            listUIElement.Height:Set(function() return newBitmap.Height() + 4 end)
            self:SetBitmap(newBitmap, bmp)
            LayoutHelpers.AtLeftTopIn(newBitmap, listUIElement, 2, 2)

            local prevCtrl = prev   -- this gets the prev control into the closure of this iteration
            if elementNum == 1 then
                LayoutHelpers.AtLeftTopIn(listUIElement, self._dropdown)
            else
                LayoutHelpers.Below(listUIElement, prevCtrl, 1)
            end
            elementNum = elementNum + 1

            -- A white-ish highlight that appears around an element when it is moused-over.
            local highlight = Bitmap(listUIElement)
            LayoutHelpers.FillParent(highlight, listUIElement)
            highlight:SetSolidColor('00FFFFFF')

            -- The key in the input array with which the corresponding bitmap was associated.
            local elementIndex = index

            local mouseEventHandler = function(_, event)
                if event.Type == 'MouseEnter' then
                    highlight:SetSolidColor('44FFFFFF')
                    self:OnOverItem(elementIndex, self._array[elementIndex])
                    return true
                elseif event.Type == 'MouseExit' then
                    highlight:SetSolidColor('00FFFFFF')
                    return true
                elseif event.Type == 'ButtonPress' or event.Type == 'ButtonDClick' then
                    self:SetItem(elementIndex)
                    self._ddhidden = true
                    self._dropdown:SetHidden(true)
                    self:OnClick(elementIndex, self._array[elementIndex])
                    return true
                end

                return false
            end

            highlight.HandleEvent = mouseEventHandler
            newBitmap.HandleEvent = mouseEventHandler

            prev = listUIElement
            self._list[elementNum] = listUIElement
        end

        -- prev will be last control here
        self.ddm.Bottom:Set(prev.Bottom)

        if self._dropdown:IsHidden() then
            self._dropdown:Hide()
            self._ddhidden = true
        end
    end,

    ---@param self BitmapCombo
    ---@param bmp BitmapCombo
    ---@param name string
    SetBitmap = function(self, bmp, name)
        if self._isColor then
            bmp:SetSolidColor(name)

            -- Evil hack to make the coloured block appear wide enough.
            -- Handily, we only use this in one place, so it probably won't cause the world to end.
            -- TODO: Do this sanely using the layout system.
            LayoutHelpers.SetDimensions(bmp, 30, 12)
        else
            bmp:SetTexture(UIUtil.SkinnableFile(name))
        end
    end,

    -- set the index selected
    ---@param self BitmapCombo
    ---@param index number
    SetItem = function(self, index)
        self:SetBitmap(self._bitmap, self._array[index])
        self._curIndex = index
    end,

    ---@param self BitmapCombo
    ---@return number
    GetItem = function(self)
        return self._curIndex
    end,

    ---@param self BitmapCombo
    OnEvent = function(self)
    end,

    -- overload to get the selection
    ---@param self BitmapCombo
    ---@param index number
    ---@param name string
    OnClick = function(self, index, name)
    end,

    ---@param self BitmapCombo
    OnMouseExit = function(self)
    end,

    -- overload to get rolled over item index
    ---@param self BitmapCombo
    ---@param index number
    ---@param name string
    OnOverItem = function(self, index, name)
    end,

    ---@param self BitmapCombo
    OnDisable = function(self)
        local bitmap_button = self._bitmaps.button
        self._btnLeft:SetTexture(bitmap_button.left.dis)
        self._btnRight:SetTexture(bitmap_button.right.dis)
        self._btnMid:SetTexture(bitmap_button.mid.dis)
        self._dropdown:Hide()
    end,

    ---@param self BitmapCombo
    OnEnable = function(self)
        local bitmap_button = self._bitmaps.button
        self._btnLeft:SetTexture(bitmap_button.left.up)
        self._btnRight:SetTexture(bitmap_button.right.up)
        self._btnMid:SetTexture(bitmap_button.mid.up)
    end,

    -- set up control logic
    ---@param self BitmapCombo
    ---@param event Event
    ---@return boolean
    HandleEvent = function(self, event)
        if self:IsDisabled() then
            return
        end
        local eventHandled = false

        local bitmap_button = self._bitmaps.button
        if event.Type == 'MouseEnter' then
            if self._dropdown:IsHidden() then
                self._btnLeft:SetTexture(bitmap_button.left.over)
                self._btnRight:SetTexture(bitmap_button.right.over)
                self._btnMid:SetTexture(bitmap_button.mid.over)
                if self.mRolloverCue then
                    PlaySound(Sound {
                        Cue = self.mRolloverCue,
                        Bank = "Interface",
                    })
                end
            end
            eventHandled = true
        elseif event.Type == 'MouseExit' then
            if self._dropdown:IsHidden() then
                self._btnLeft:SetTexture(bitmap_button.left.up)
                self._btnRight:SetTexture(bitmap_button.right.up)
                self._btnMid:SetTexture(bitmap_button.mid.up)
            end
            eventHandled = true
        elseif event.Type == 'ButtonPress' then
            local new_state = not self._dropdown:IsHidden()
            self._ddhidden = new_state
            self._dropdown:SetHidden(new_state)
            if self.mClickCue then
                PlaySound(Sound {
                    Cue = self.mClickCue,
                    Bank = "Interface",
                })
            end
            eventHandled = true
        end
        self:OnEvent(event)

        return eventHandled
    end,

    ---@param self BitmapCombo
    OnDestroy = function(self)
        if self._globalMouseClickFn then
            UIMain.RemoveOnMouseClickedFunc(self._globalMouseClickFn)
            self._globalMouseClickFn = nil
        end
    end,
}

-- kept for mod backwards compatibility
local Text = import("/lua/maui/text.lua").Text
local Dragger = import("/lua/maui/dragger.lua").Dragger