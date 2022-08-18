-- Class methods:
-- Scrollbar:SetScrollable(scrollable) - set the scrollable item this controls
-- Scrollbar:SetNewTextures(background, thumbMiddle, thumbTop, thumbBottom)
-- ScrollBar:ScrollLines(float lines)
-- ScrollBar:ScrollPages(float pages)

local LazyVar = import('/lua/lazyvar.lua')

local Control = import('/lua/maui/control.lua').Control

---@alias ScrollAxis "Horz" | "Vert"
ScrollAxis = {
    Vert = "Vert",
    Horz = "Horz",
}

---@alias ScrollPolicy "Never" | "AsNeeded" | "Always"
ScrollPolicy = {
    Never = "Never",
    AsNeeded = "AsNeeded",
    Always = "Always",
}

---@class Scrollbar : moho.scrollbar_methods, Control
Scrollbar = Class(moho.scrollbar_methods, Control) {

    __init = function(self, parent, axis, debugname)
        axis = axis or "Vert"
        InternalCreateScrollbar(self, parent, axis)
        if debugname then
            self:SetName(debugname)
        end
        self.Axis = axis

        local LazyVarCreate = LazyVar.Create

        local bg = LazyVarCreate()
        bg.OnDirty = function(var)
            self:SetNewTextures(var(), nil, nil, nil)
        end
        self._bg = bg

        local tm = LazyVarCreate()
        tm.OnDirty = function(var)
            self:SetNewTextures(nil, var(), nil, nil)
        end
        self._tm = tm

        local tt = LazyVarCreate()
        tt.OnDirty = function(var)
            self:SetNewTextures(nil, nil, var(), nil)
        end
        self._tt = tt

        local tb = LazyVarCreate()
        tb.OnDirty = function(var)
            self:SetNewTextures(nil, nil, nil, var())
        end
        self._tb = tb
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
        button1.OnClick = function()
            self:DoScrollLines(1)
        end
        button2.OnClick = function()
            self:DoScrollLines(-1)
        end
    end,

    SetTextures = function(self, background, thumbMiddle, thumbTop, thumbBottom)
        local bg = self._bg
        local tm = self._tm
        local tt = self._tt
        local tb = self._tb

        -- don't activate the `OnDirty` methods so we can consolidate the `SetNewTextures` calls
        if background then
            if bg then
                bg:SelfCleanSet(background)
                background = bg()
            else
                bg = nil
            end
        end
        if thumbMiddle then
            if tm then
                tm:SelfCleanSet(thumbMiddle)
                thumbMiddle = tm()
            else
                thumbMiddle = nil
            end
        end
        if thumbTop then
            if tt then
                tt:SelfCleanSet(thumbTop)
                thumbTop = tt()
            else
                thumbTop = nil
            end
        end
        if thumbBottom then
            if tb then
                tb:SelfCleanSet(thumbBottom)
                thumbBottom = tb()
            else
                thumbBottom = nil
            end
        end

        self:SetNewTextures(background, thumbMiddle, thumbTop, thumbBottom)
    end,
}

