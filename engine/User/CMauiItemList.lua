--- Class CMauiItemList
-- @classmod User.CMauiItemList

---
--  itemlist = ItemList:DeleteAllItems()
function CMauiItemList:DeleteAllItems()
end

---
--  itemlist = ItemList:DeleteItem(index)
function CMauiItemList:DeleteItem(index)
end

---
--  bool ItemList:Empty()
function CMauiItemList:Empty()
end

---
--  item = ItemList:GetItem(index)
function CMauiItemList:GetItem(index)
end

---
--  int ItemList:GetItemCount()
function CMauiItemList:GetItemCount()
end

---
--  float ItemList:GetRowHeight()
function CMauiItemList:GetRowHeight()
end

---
--  index = ItemList:GetSelection()
function CMauiItemList:GetSelection()
end

---
--  number ItemList:GetAdvance(string) - get the advance of a string using the same font as the control
function CMauiItemList:GetStringAdvance()
end

---
--  itemlist = ItemList:ModifyItem(index, string)
function CMauiItemList:ModifyItem(index,  string)
end

---
--  bool NeedsScrollBar() - returns true if a scrollbar is needed, else false
function CMauiItemList:NeedsScrollBar()
end

---
--  ItemList:ScrollToBottom()
function CMauiItemList:ScrollToBottom()
end

---
--  ItemList:ScrollToTop()
function CMauiItemList:ScrollToTop()
end

---
--  ItemList:SetNewColors(foreground, background, selected_foreground, selected_background)
function CMauiItemList:SetNewColors(foreground,  background,  selected_foreground,  selected_background)
end

---
--  ItemList:SetNewFont(family, pointsize) -- set the font to use in this ItemList control
function CMauiItemList:SetNewFont(family,  pointsize)
end

---
--  ItemList:SetSelection(index)
function CMauiItemList:SetSelection(index)
end

---
--  ItemList:ShowItem(index)
function CMauiItemList:ShowItem(index)
end

---
--  ShowMouseoverItem(bool) - enable or disable the showing of the mouseover item
function CMauiItemList:ShowMouseoverItem(bool)
end

---
--  ShowSelection(bool) - enable or disable the highlighting of the selected item
function CMauiItemList:ShowSelection(bool)
end

---
--  derived from CMauiControl
function CMauiItemList:base()
end

---
--
function CMauiItemList:moho.item_list_methods()
end

