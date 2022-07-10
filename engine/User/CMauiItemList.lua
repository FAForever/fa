---@declare-global
---@class moho.item_list_methods : moho.control_methods
local CMauiItemList = {}

---
function CMauiItemList:AddItem()
end

---
---@return ItemList
function CMauiItemList:DeleteAllItems()
end

---
---@param index number
---@return ItemList
function CMauiItemList:DeleteItem(index)
end

---
---@return boolean
function CMauiItemList:Empty()
end

---
---@param index number
---@return number
function CMauiItemList:GetItem(index)
end

---
---@return number
function CMauiItemList:GetItemCount()
end

---
---@return number
function CMauiItemList:GetRowHeight()
end

---
---@return number
function CMauiItemList:GetSelection()
end

--- Get the advance of a string using the same font as the control
---@param text string
---@return number
function CMauiItemList:GetStringAdvance(text)
end

---
---@param index number
---@param string string
---@return ItemList
function CMauiItemList:ModifyItem(index, string)
end

--- Return true if a scrollbar is needed, else, false
---@return boolean
function CMauiItemList:NeedsScrollBar()
end

---
function CMauiItemList:ScrollToBottom()
end

---
function CMauiItemList:ScrollToTop()
end

---
---@param foreground string
---@param background string
---@param selectedForeground string
---@param selectedBackground string
function CMauiItemList:SetNewColors(foreground, background, selectedForeground, selectedBackground)
end

--- Set the font to use in this ItemList control
---@param family string
---@param pointsize number
function CMauiItemList:SetNewFont(family, pointsize)
end

---
---@param index number
function CMauiItemList:SetSelection(index)
end

---
---@param index number
function CMauiItemList:ShowItem(index)
end

--- Enable or disable the showing of the mouseover item
---@param show boolean
function CMauiItemList:ShowMouseoverItem(show)
end

--- Enable or disable the highlighting of the selected item
---@param show boolean
function CMauiItemList:ShowSelection(show)
end

return CMauiItemList
