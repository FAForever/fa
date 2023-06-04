-- LazyVars exposed from C++:
--   BorderWidth - how wide to draw the side borders.
--   BorderHeight - how high to draw the top and bottom borders.
--
-- Methods exposed from C++:
--   SetNewTextures(vertical, horizontal, upperLeft, upperRight, lowerLeft, lowerRight)
--   SetSolidColor(color)

-- Note: Border textures assume a texture border of 1.
-- Note: Adjacent corner textures must have matching witdhs and heights
-- Note: SetTextures will set the BorderWidth and BorderHeight lazy
-- vars.  You can change 'em afterwards if you want to stretch your
-- border textures.

local Control = import("/lua/maui/control.lua").Control

---@class MauiBorder : moho.border_methods, Control, InternalObject
---@field BorderWidth LazyVar
---@field BorderHeight LazyVar
Border = ClassUI(moho.border_methods, Control) {

    __init = function(self, parent, debugname)
        InternalCreateBorder(self, parent)
        if debugname then
            self:SetName(debugname)
        end

        local LazyVar = import("/lua/lazyvar.lua")
        self._v = LazyVar.Create()
        self._v.OnDirty = function(var)
            self:SetNewTextures(var(), nil, nil, nil, nil, nil)
        end

        self._h = LazyVar.Create()
        self._h.OnDirty = function(var)
            self:SetNewTextures(nil, var(), nil, nil, nil, nil)
        end

        self._ul = LazyVar.Create()
        self._ul.OnDirty = function(var)
            self:SetNewTextures(nil, nil, var(), nil, nil, nil)
        end

        self._ur = LazyVar.Create()
        self._ur.OnDirty = function(var)
            self:SetNewTextures(nil, nil, nil, var(), nil, nil)
        end

        self._ll = LazyVar.Create()
        self._ll.OnDirty = function(var)
            self:SetNewTextures(nil, nil, nil, nil, var(), nil)
        end

        self._lr = LazyVar.Create()
        self._lr.OnDirty = function(var)
            self:SetNewTextures(nil, nil, nil, nil, nil, var())
        end
    end,

    SetTextures = function(self, vertical, horizontal, upperLeft, upperRight, lowerLeft, lowerRight)
        if vertical and self._v then self._v:Set(vertical) end
        if horizontal and self._h then self._h:Set(horizontal) end
        if upperLeft and self._ul then self._ul:Set(upperLeft) end
        if upperRight and self._ur then self._ur:Set(upperRight) end
        if lowerLeft and self._ll then self._ll:Set(lowerLeft) end
        if lowerRight and self._lr then self._lr:Set(lowerRight) end
    end,

    OnDestroy = function(self)
        self._v:Destroy()
        self._v = nil
        self._h:Destroy()
        self._h = nil
        self._ul:Destroy()
        self._ul = nil
        self._ur:Destroy()
        self._ur = nil
        self._ll:Destroy()
        self._ll = nil
        self._lr:Destroy()
        self._lr = nil
    end,

    -- Cause the border to be positioned around the given control.
    LayoutAroundControl = function(self, control, extra)
        extra = extra or 0
        self.Left:Set(function() return control.Left() - self.BorderWidth() - extra end)
        self.Right:Set(function() return control.Right() + self.BorderWidth() + extra end)
        self.Top:Set(function() return control.Top() - self.BorderHeight() - extra end)
        self.Bottom:Set(function() return control.Bottom() + self.BorderHeight() + extra end)
    end,

    -- Cause the border to be positioned around the inside of the control.
    LayoutInsideControl = function(self, control)
        self.Left:Set(function() return control.Left() + self.BorderWidth() / 2 end)
        self.Right:Set(function() return control.Right() - self.BorderWidth() / 2 end)
        self.Top:Set(function() return control.Top() + self.BorderHeight() / 2 end)
        self.Bottom:Set(function() return control.Bottom() - self.BorderHeight() / 2 end)
    end,

    -- Cause the control to be positioned just inside the border.
    LayoutControlInside = function(self, control, extra)
        extra = extra or 0
        control.Left:Set(function() return self.Left() + self.BorderWidth() + extra end)
        control.Right:Set(function() return self.Right() - self.BorderWidth() - extra end)
        control.Top:Set(function() return self.Top() + self.BorderHeight() + extra end)
        control.Bottom:Set(function() return self.Bottom() - self.BorderHeight() - extra end)
    end,

}

