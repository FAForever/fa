-- Class methods:
-- SetNewFont(family, pointsize)
-- SetNewColors(foreground, background, selected_foreground, selected_background)
-- item GetItem(index)
-- AddItem('newitem')
-- ModifyItem(index, string)
-- DeleteItem(index)
-- DeleteAllItems()
-- index GetSelection()
-- SetSelection(index)
-- int GetItemCount()
-- bool Empty()
-- ScrollToTop()
-- ScrollToBottom()
-- ShowItem(index)
-- int GetRowHeight()

local Control = import("/lua/maui/control.lua").Control
local Dragger = import("/lua/maui/dragger.lua").Dragger
local ScaleNumber = import("/lua/maui/layouthelpers.lua").ScaleNumber

---@class ItemList : moho.item_list_methods, Control, InternalObject
ItemList = ClassUI(moho.item_list_methods, Control) {

    __init = function(self, parent, debugname)
        InternalCreateItemList(self, parent)
        if debugname then
            self:SetName(debugname)
        end

        local LazyVar = import("/lua/lazyvar.lua")
        self._lockFontChanges = false
        self._font = {_family = LazyVar.Create(), _pointsize = LazyVar.Create()}
        self._font._family.OnDirty = function(var)
            self:_internalSetFont()
        end
        self._font._pointsize.OnDirty = function(var)
            self:_internalSetFont()
        end

        self._fg = LazyVar.Create()
        self._fg.OnDirty = function(var)
            self:SetNewColors(var(), nil, nil, nil, nil, nil)
        end

        self._bg = LazyVar.Create()
        self._bg.OnDirty = function(var)
            self:SetNewColors(nil, var(), nil, nil, nil, nil)
        end

        self._sfg = LazyVar.Create()
        self._sfg.OnDirty = function(var)
            self:SetNewColors(nil, nil, var(), nil, nil, nil)
        end

        self._sbg = LazyVar.Create()
        self._sbg.OnDirty = function(var)
            self:SetNewColors(nil, nil, nil, var(), nil, nil)
        end

        self._mofg = LazyVar.Create()
        self._mofg.OnDirty = function(var)
            self:SetNewColors(nil, nil, nil, nil, var(), nil)
        end

        self._mobg = LazyVar.Create()
        self._mobg.OnDirty = function(var)
            self:SetNewColors(nil, nil, nil, nil, nil, var())
        end
    end,

    -- lazy var support
    SetFont = function(self, family, pointsize)
        if self._font then
            self._lockFontChanges = true
            self._font._pointsize:Set(ScaleNumber(pointsize))
            self._font._family:Set(family)
            self._lockFontChanges = false
            self:_internalSetFont()
        end
    end,

    _internalSetFont = function(self)
        if not self._lockFontChanges then
            self:SetNewFont(self._font._family(), self._font._pointsize())
        end
    end,

    SetColors = function(self, foreground, background, selected_foreground, selected_background, mouseover_foreground, mouseover_background)
        if foreground and self._fg then self._fg:Set(foreground) end
        if background and self._bg then self._bg:Set(background) end
        if selected_foreground and self._sfg then self._sfg:Set(selected_foreground) end
        if selected_background and self._sbg then self._sbg:Set(selected_background) end
        if mouseover_foreground and self._mofg then self._mofg:Set(mouseover_foreground) end
        if mouseover_background and self._mobg then self._mobg:Set(mouseover_background) end
    end,

    OnDestroy = function(self)
        self._font._family:Destroy()
        self._font = nil
        self._fg:Destroy()
        self._fg = nil
        self._bg:Destroy()
        self._bg = nil
        self._sfg:Destroy()
        self._sfg = nil
        self._sbg:Destroy()
        self._sbg = nil
        self._mofg:Destroy()
        self._mofg = nil
        self._mobg:Destroy()
        self._mobg = nil
    end,

    -- default override methods, event has the whole event so you can get modifiers
    OnClick = function(self, row, event)
        self:SetSelection(row)
    end,

    OnDoubleClick = function(self, row, event)
        self:OnClick(row)
    end,

    -- The selection changed via keyboard (up,down,pageup,pagedown,home,end etc)
    OnKeySelect = function(self, row)
    end,

    -- updated when mouseover item changes, -1 when no mouseover
    OnMouseoverItem = function(self, row)
    end,
}

