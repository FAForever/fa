-- Class methods:
-- Scrollbar:SetScrollable(scrollable) - set the scrollable item this controls
-- Scrollbar:SetNewTextures(background, thumbMiddle, thumbTop, thumbBottom)
-- ScrollBar:ScrollLines(float lines)
-- ScrollBar:ScrollPages(float pages)

local Control = import('control.lua').Control

ScrollAxis = {
    Vert = "Vert",
    Horz = "Horz"
}

---@class Scrollbar : moho.scrollbar_methods, Control
Scrollbar = Class(moho.scrollbar_methods, Control) {

    __init = function(self, parent, axis, debugname)
        InternalCreateScrollbar(self, parent, axis)
        if debugname then
            self:SetName(debugname)
        end
        self.Axis = axis

        local LazyVar = import('/lua/lazyvar.lua')

        self._bg = LazyVar.Create()
        self._bg.OnDirty = function(var)
            self:SetNewTextures(var(), nil, nil, nil)
        end

        self._tm = LazyVar.Create()
        self._tm.OnDirty = function(var)
            self:SetNewTextures(nil, var(), nil, nil)
        end

        self._tt = LazyVar.Create()
        self._tt.OnDirty = function(var)
            self:SetNewTextures(nil, nil, var(), nil)
        end

        self._tb = LazyVar.Create()
        self._tb.OnDirty = function(var)
            self:SetNewTextures(nil, nil, nil, var())
        end

    end,

    OnDestroy = function(self)
        self._bg:Destroy()
        self._bg = nil
        self._tm:Destroy()
        self._tm = nil
        self._tt:Destroy()
        self._tt = nil
        self._tb:Destroy()
        self._tb = nil
    end,

    AddButtons = function(self, button1, button2)
        if self.Axis == ScrollAxis.Vert then
            self.UpButton = button1
            self.DownButton = button2
        else
            self.RightButton = button1
            self.LeftButton = button2
        end
        button1.OnClick = function(bt)
            self:DoScrollLines(1)
        end
        button2.OnClick = function(bt)
            self:DoScrollLines(-1)
        end
    end,

    SetTextures = function(self, background, thumbMiddle, thumbTop, thumbBottom)
        if background and self._bg then self._bg:Set(background) end
        if thumbMiddle and self._tm then self._tm:Set(thumbMiddle) end
        if thumbTop and self._tt then self._tt:Set(thumbTop) end
        if thumbBottom and self._tb then self._tb:Set(thumbBottom) end
    end,
}

