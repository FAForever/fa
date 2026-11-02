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
local LazyVarCreate = import("/lua/lazyvar.lua").Create
local MultiplyAlpha = import("/lua/shared/color.lua").MultiplyAlpha

---@class ItemList : moho.item_list_methods, Control, InternalObject
ItemList = ClassUI(moho.item_list_methods, Control) {

    __init = function(self, parent, debugname)
        InternalCreateItemList(self, parent)
        if debugname then
            self:SetName(debugname)
        end

        self._lockFontChanges = false
        self._font = {_family = LazyVarCreate(), _pointsize = LazyVarCreate()}
        local onFontChanged = function(var)
            self:_internalSetFont()
        end
        self._font._family.OnDirty = onFontChanged
        self._font._pointsize.OnDirty = onFontChanged

        self._alpha = LazyVarCreate(1)
        self._alpha.OnDirty = function(var)
            local alpha = var()
            self:SetNewColors(
                self._fg() ~= 0 and MultiplyAlpha(self._fg(), alpha) or nil,
                self._bg() ~= 0 and MultiplyAlpha(self._bg(), alpha) or nil,
                self._sfg() ~= 0 and MultiplyAlpha(self._sfg(), alpha) or nil,
                self._sbg() ~= 0 and MultiplyAlpha(self._sbg(), alpha) or nil,
                self._mofg() ~= 0 and MultiplyAlpha(self._mofg(), alpha) or nil,
                self._mobg() ~= 0 and MultiplyAlpha(self._mobg(), alpha) or nil
            )
        end

        self._fg = LazyVarCreate()
        self._fg.OnDirty = function(var)
            self:SetNewColors(MultiplyAlpha(var(), self._alpha()), nil, nil, nil, nil, nil)
        end

        self._bg = LazyVarCreate()
        self._bg.OnDirty = function(var)
            self:SetNewColors(nil, MultiplyAlpha(var(), self._alpha()), nil, nil, nil, nil)
        end

        self._sfg = LazyVarCreate()
        self._sfg.OnDirty = function(var)
            self:SetNewColors(nil, nil, MultiplyAlpha(var(), self._alpha()), nil, nil, nil)
        end

        self._sbg = LazyVarCreate()
        self._sbg.OnDirty = function(var)
            self:SetNewColors(nil, nil, nil, MultiplyAlpha(var(), self._alpha()), nil, nil)
        end

        self._mofg = LazyVarCreate()
        self._mofg.OnDirty = function(var)
            self:SetNewColors(nil, nil, nil, nil, MultiplyAlpha(var(), self._alpha()), nil)
        end

        self._mobg = LazyVarCreate()
        self._mobg.OnDirty = function(var)
            self:SetNewColors(nil, nil, nil, nil, nil, MultiplyAlpha(var(), self._alpha()))
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

    SetAlphaOfColors = function(self, alpha)
        if alpha and self._alpha then self._alpha:Set(alpha) end
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

    ---@param self ItemList
    ---@return LocalizedString[]
    GetAllItems = function(self)
        local items = {}
        for i = 0, self:GetItemCount() - 1 do
            items[i] = self:GetItem(i)
        end
        return items
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
