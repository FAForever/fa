---@meta

---@class moho.item_list_methods : moho.control_methods
local CMauiItemList = {}

---@param text LocalizedString | number
function CMauiItemList:AddItem(text)
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

--- Get an item from the list, using 0-based indexing.
---@param index number
---@return LocalizedString | number
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

--- Returns the index of the currently selected item, using 0-based counting
---@return number
function CMauiItemList:GetSelection()
end

--- Gets the advance of a string using the same font as the control
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

--- Returns if a scrollbar is needed
---@return boolean
function CMauiItemList:NeedsScrollBar()
end

---
function CMauiItemList:ScrollToBottom()
end

---
function CMauiItemList:ScrollToTop()
end

--- Sets the alpha of a given item list's background, if children is true, also set children's alpha
---@param alpha number
---@param children? boolean
---@see ItemList.SetAlphaOfColors # Lua implementation that can set the alpha of the text in an item list.
function CMauiItemList:SetAlpha(alpha, children)
end

---
---@param foreground Color
---@param background Color
---@param selectedForeground Color
---@param selectedBackground Color
---@param mouseoverForeground Color
---@param mouseoverBackground Color
function CMauiItemList:SetNewColors(foreground, background, selectedForeground, selectedBackground, mouseoverForeground, mouseoverBackground)
end

--- Sets the font to use in this ItemList control
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

--- Enables or disables highlighting the row under the mouse. While enabled, the engine calls
--- `OnMouseoverItem` when the row under the mouse changes, with its 0-based index, or `-1` when the
--- mouse leaves the list.
---@see moho.item_list_methods.OnMouseoverItem # Called when the row under the mouse changes
---@param show boolean
function CMauiItemList:ShowMouseoverItem(show)
end

--- Enables or disables the highlighting of the selected item
---@param show boolean
function CMauiItemList:ShowSelection(show)
end

--- Called by the engine when the user clicks a row, with its 0-based index.
---@type nil | fun(self: ItemList, row: integer, event: KeyEvent)
CMauiItemList.OnClick = nil

--- Called by the engine when the user double-clicks a row, with its 0-based index.
---@type nil | fun(self: ItemList, row: integer, event: KeyEvent)
CMauiItemList.OnDoubleClick = nil

--- Called by the engine when the selection changes by keyboard (arrow keys, `Page Up`,
--- `Page Down`, `Home` or `End`), with the 0-based index of the newly selected row.
---@type nil | fun(self: ItemList, row: integer)
CMauiItemList.OnKeySelect = nil

--- Called by the engine when the row under the mouse changes, with its 0-based index or `-1`.
---@see moho.item_list_methods.ShowMouseoverItem # Enables this callback
---@type nil | fun(self: ItemList, row: integer)
CMauiItemList.OnMouseoverItem = nil

return CMauiItemList
