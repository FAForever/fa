local Group = import('/lua/maui/group.lua').Group
local StackPanel = import('./stackpanel.lua').StackPanel
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local UIUtil = import('/lua/ui/uiutil.lua')

ItemsControl = Class(Group) {
    Items = false,                     -- All items in the list
    FirstVisibleItem = false,           -- The first visible item index in the list (= value of the scrollbar)
    VisibleItemCount = false,           -- The number of visible items
    Panel = false,                  -- The panel containing the items
    DeferRefresh = false,           -- Block the refresh of the list when items are added/removed. Set to true when you add many items and call Refresh when done
    Padding = false,            -- A padding between the items and the external border of the control (Top/right/bottom/left)
    ScrollBarsSize = false,       -- The sizes of the scrollbars (Right/Bottom)
    Orientation = false,              -- The stack orientation, vertical or horizontal
    DefaultItemMargin = false,  -- A margin around each single item (Top/right/bottom/left)
    BackColor = false,


    __init = function(self, Parent, Options)
        Group.__init(self, Parent)

        -- Properties init
        self.Items = {}
        self.FirstVisibleItem = 1
        self.VisibleItemCount = 0
        self.DeferRefresh = false
        self.Padding = {3,3,3,3}
        self.ScrollBarsSize = 14
        self.Orientation = "V"
        self.DefaultItemMargin = {0,0,0,0}
        self.BackColor = '00000000'
        if Options then for Name, Value in Options do self[Name] = Value end end

        -- Panel
        self.Panel = StackPanel(self, {Orientation = self.Orientation})
        self.Panel.Top:Set(function() return self.Top() + self.Padding[1] end)
        if self.Orientation == "V" then
            self.Panel.Right:Set(function() return self.Right() - self.Padding[2] - self.ScrollBarsSize end) 
            self.Panel.Bottom:Set(function() return self.Bottom() - self.Padding[3] end)
        else
            self.Panel.Right:Set(function() return self.Right() - self.Padding[2] end) 
            self.Panel.Bottom:Set(function() return self.Bottom() - self.Padding[3] - self.ScrollBarsSize end)
        end
        self.Panel.Left:Set(function() return self.Left() + self.Padding[4] end)

        -- Background
        self.BG = Bitmap(self)
        LayoutHelpers.FillParent(self.BG, self)


        -- Scrollbar
        self.IsScrollable = function(self, axis)
            return true
        end     
        self.GetScrollValues = function(self, axis)
            -- First item, Last item, First visible item, Last visible item
            return 1, table.getn(self.Items), self.FirstVisibleItem, self.FirstVisibleItem + self.VisibleItemCount - 1
        end 
        -- called when the scrollbar wants to set a new visible top line
        self.ScrollSetTop = function(self, axis, top)
            top = math.floor(top)
            -- Test top value
            if top < 1 then top = 1 end
            if top > table.getn(self.Items) - self.Panel:Count() + 1 then top = table.getn(self.Items) - self.Panel:Count() + 1 end
            if top == self.FirstVisibleItem then return end
            -- Set new top and refresh the list
            self.FirstVisibleItem = top
            self:Refresh()
        end         
        self.ScrollLines = function(self, axis, delta)
            self:ScrollSetTop(axis, self.FirstVisibleItem + math.floor(delta))
        end
        self.ScrollPages = function(self, axis, delta)
            self:ScrollSetTop(axis, self.FirstVisibleItem + math.floor(delta) * self.Panel:Count())
        end
        self.HandleEvent = function(self, event)
            if event.Type == 'WheelRotation' then
                if event.WheelRotation > 0 then
                    self:ScrollLines(nil, -1)
                else
                    self:ScrollLines(nil, 1)
                end

            end
        end 
        self.ScrollToBottom = function(self)
            -- Because the items has not all the same size (number of visible items can change), we need to test if we are really on bottom
            while not self:IsScrolledToBottom() do
                self:ScrollSetTop(nil, table.getn(self.Items) - self.Panel:Count() + 1)
            end        
        end
        self.IsScrolledToBottom = function(self)
            local LastVisibleItem = self.FirstVisibleItem + self.Panel:Count() - 1
            return LastVisibleItem >= table.getn(self.Items)
        end
        if self.Orientation == "V" then
            self.Scroll = UIUtil.CreateLobbyVertScrollbar(self, -self.ScrollBarsSize)
        else
            -- Horizontal scrollbar doesn't exist in UIUtil
            --self.Scroll = UIUtil.CreateLobbyVertScrollbar(self, -self.ScrollBarsSize)
        end
        LayoutHelpers.DepthOverParent(self.Scroll, self, 2)


    end,

    AddItem = function(self, Item, Index)
        -- Check Index
        if not Index then 
            -- If index is ommited, the item is added at the end of the list
            Index = table.getn(self.Items) + 1 
        elseif Index < 1 or Index > table.getn(self.Items) + 1 then
            -- If index is out of the list range, we just return
            return
        end
        -- Default margin to item
        if not Item.Margin then Item.Margin = self.DefaultItemMargin end
        -- Add the item to the list
        table.insert(self.Items, Index, Item)
        Item:SetParent(self)
        Item:Hide() 
        -- We refresh the list
        if not self.DeferRefresh then self:Refresh() end
        return Index
    end,

    RemoveAt = function(self, Index)
        if not Index then 
            -- If index is ommited, the last item of the list is removed
            Index = table.getn(self.Items) 
        elseif Index < 1 or Index > table.getn(self.Items) then
            -- If index is out of the list range, we just return
            return
        end
        -- Remove the item from the list
        local Item = table.remove(self.Items, Index)
        Item:Hide() 
        -- We refresh the list
        if not self.DeferRefresh then self:Refresh() end
        return Item
    end,

    IndexOf = function(self, Item)
        for Index, ListItem in self.Items do
            if Item == ListItem then return Index end
        end
        return 0
    end,

    RemoveItem = function(self, Item)
        local Index = self.IndexOf(Item)
        if Index > 0 then
            self:RemoveAt(Index)
            return Index
        end        
    end,

    Clear = function(self)
        self.DeferRefresh = true
        local Count = table.getn(self.Items)
        for i = Count, 1 do 
            self:RemoveAt(i)
        end
        self:Refresh()
    end,

    Count = function(self) 
        return table.getn(self.Items)
    end,

    Refresh = function(self)
        -- A call to Refresh cancels the DeferRefresh
        self.DeferRefresh = false

        -- We hide all current visible items
        self.Panel:Clear()
        self.VisibleItemCount = 0
        
        -- We place and display the items that must be displayed
        -- Iterate from the first visible item to the last item in the list
        Count = table.getn(self.Items)
        for i = self.FirstVisibleItem, Count do 
            local Item = self.Items[i]

            self.Panel:AddItem(Item)

            if Item.Bottom() > self.Panel.Bottom() then
                -- This item's bottom is outside of the display area, this item should not be visible
                self.Panel:RemoveAt() -- Removes the last item when no index is given
                return  -- The refresh is done
            end

            self.VisibleItemCount = self.VisibleItemCount + 1
        end   
             
    end,
}
