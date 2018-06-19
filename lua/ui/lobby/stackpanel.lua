local Group = import('/lua/maui/group.lua').Group
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap

StackPanel = Class(Group) {

    Items = false,
    Orientation = false,
    Padding = false,
    DefaultItemMargin = false,
    ItemParent = nil,

    __init = function(self, Parent, Options)
        Group.__init(self, Parent)

        -- Properties init
        self.Items = {}
        self.Orientation = "V"
        self.Padding = {0,0,0,0}
        self.DefaultItemMargin = {0,0,0,0}
        if Options then for Name, Value in Options do self[Name] = Value end end

        -- The panel hisself doesn't need hit test
        self:DisableHitTest()   

        -- Background
        self.BG = Bitmap(self)
        LayoutHelpers.FillParent(self.BG, self)
        ItemParent = Parent
    end,

    AddItem = function(self, Item, Index)
        if not Index then 
            -- If index is ommited, the item is added at the end of the list
            Index = table.getn(self.Items) + 1 
        elseif Index < 1 or Index > table.getn(self.Items) + 1 then
            -- If index is out of the list range, we just return
            return
        end
        if not Item.Margin then Item.Margin = self.DefaultItemMargin end
        
        table.insert(self.Items, Index, Item)
        Item:SetParent(self)
        --Item.Depth:Set(self.Depth()+1)
        
        LayoutHelpers.DepthOverParent(Item, ItemParent, 1)
        
        if self:IsHidden() then
            Item:Hide()
        else
            Item:Show()
        end

        if self.Orientation == "V" then
           
            Item.Left:Set(function() return self.Left() + self.Padding[4] + Item.Margin[4] end)
            Item.Right:Set(function() return self.Right() - self.Padding[2] - Item.Margin[2] end)
            Item.Width:Set(function() return Item.Right() - Item.Left() end)

            if Index == 1 then
                -- It's the first item, his top is set to parent top
                Item.Top:Set(function() return self.Top() + self.Padding[1] + Item.Margin[1] end)
            else
                -- It's not the first item, his top is set to previous item's bottom
                local PrevItem = self.Items[Index-1]
                Item.Top:Set(function() return PrevItem.Bottom() + PrevItem.Margin[3] + Item.Margin[1] + 1 end)
            end

            if self.Items[Index + 1] then
                -- There is a item after this one, need top update the next item's top
                local NextItem = self.Items[Index + 1]
                NextItem.Top:Set(function() return Item.Bottom() + Item.Margin[3] + NextItem.Margin[1] + 1 end)
            end

        else
            Item.Top:Set(function() return self.Top() + self.Padding[1] + Item.Margin[1] end)
            Item.Bottom:Set(function() return self.Bottom() - self.Padding[3] - Item.Margin[3] end)
            Item.Height:Set(function() return Item.Bottom() - Item.Top() end)

            if Index == 1 then
                -- It's the first item, his left is set to parent left
                Item.Left:Set(function() return self.Left() + self.Padding[4] + Item.Margin[4] end)
            else
                -- It's not the first item, his left is set to previous item's right
                local PrevItem = self.Items[Index-1]
                Item.Left:Set(function() return PrevItem.Right() + PrevItem.Margin[2] + Item.Margin[4] + 1 end)
            end

            if self.Items[Index + 1] then
                -- There is a item after this one, need top update the next item's left
                local NextItem = self.Items[Index + 1]
                NextItem.Left:Set(function() return Item.Right() + Item.Margin[2] + NextItem.Margin[4] + 1 end)
            end

        end
        return Index
    end,

    RemoveAt = function(self, Index)
        local RemovedItem = table.remove(self.Items, Index)
        
        if not RemovedItem then
            return -- There is no item to remove
        end
        
        RemovedItem:Hide()
        local Item = self.Items[Index]
        
        if not Item then
            return -- Couldn't find the item after the removed one
        end
        
        if self.Orientation == "V" then
            -- Update next item's top
            if Index == 1 then
                -- It's the first item, new first item's top is set to parent top
                Item.Top:Set(function() return self.Top() + self.Padding[1] + Item.Margin[1]  end)
            else
                -- It's not the first item, his top is set to previous item's bottom
                local PrevItem = self.Items[index-1]
                Item.Top:Set(function() return PrevItem.Bottom() + PrevItem.Margin[3] + Item.Margin[1] + 1  end)
            end
        else
            -- Update next item's left
            if Index == 1 then
                -- It's the first item, new first item's left is set to parent left
                Item.Left:Set(function() return self.Left() + self.Padding[4] + Item.Margin[4]  end)
            else
                -- It's not the first item, his left is set to previous item's right
                local PrevItem = self.Items[index-1]
                Item.Left:Set(function() return PrevItem.Right() + PrevItem.Margin[2] + Item.Margin[4] + 1  end)
            end
        end
        return RemovedItem
    end,

    RemoveItem = function(self, Item)
        local Index = self.IndexOf(Item)
        if Index > 0 then
            self.RemoveAt(Index)
            return Index
        end
    end,

    Count = function(self) 
        return table.getn(self.Items)
    end,

    IndexOf = function(self, Item)
        for Index, ListItem in self.Items do
            if Item == ListItem then return Index end
        end
        return 0
    end,

    Clear = function(self)
        local Count = table.getn(self.Items)
        for i = 1, Count do 
            local Item = table.remove(self.Items)
            Item:Hide()
        end
    end,

}