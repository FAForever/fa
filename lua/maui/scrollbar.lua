-- Class methods:
-- Scrollbar:SetScrollable(scrollable) - set the scrollable item this controls
-- Scrollbar:SetNewTextures(background, thumbMiddle, thumbTop, thumbBottom)
-- ScrollBar:ScrollLines(float lines)
-- ScrollBar:ScrollPages(float pages)

local Control = import("/lua/maui/control.lua").Control

---@alias ScrollAxis "Horz" | "Vert"

ScrollAxis = {
    Vert = "Vert",
    Horz = "Horz",
}

---@class Scrollbar : moho.scrollbar_methods, Control, InternalObject
---@field _bg LazyVar<FileName>
---@field _tm LazyVar<FileName>
---@field _tt LazyVar<FileName>
---@field _tb LazyVar<FileName>
---@field UpButton? Button
---@field DownButton? Button
Scrollbar = ClassUI(moho.scrollbar_methods, Control) {
    ---@param self Scrollbar
    ---@param parent Control
    ---@param axis ScrollAxis
    ---@param debugname? string
    __init = function(self, parent, axis, debugname)
        InternalCreateScrollbar(self, parent, axis)
        if debugname then
            self:SetName(debugname)
        end

        local LazyVar = import("/lua/lazyvar.lua").Create
        self._bg = LazyVar()
        self._tm = LazyVar()
        self._tt = LazyVar()
        self._tb = LazyVar()

        self._bg.OnDirty = function(var)
            self:SetNewTextures(var(), nil, nil, nil)
        end
        self._tm.OnDirty = function(var)
            self:SetNewTextures(nil, var(), nil, nil)
        end
        self._tt.OnDirty = function(var)
            self:SetNewTextures(nil, nil, var(), nil)
        end
        self._tb.OnDirty = function(var)
            self:SetNewTextures(nil, nil, nil, var())
        end
    end,

    ---@param self Scrollbar
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

    ---@param self Scrollbar
    ---@param upButton Button
    ---@param downButton Button
    AddButtons = function(self, upButton, downButton)
        self.UpButton = upButton
        self.DownButton = downButton

        upButton.OnClick = function(upButton)
            self:DoScrollLines(-1)
        end
        downButton.OnClick = function(downButton)
            self:DoScrollLines(1)
        end
    end,

    ---@param self Scrollbar
    ---@param background  Lazy<FileName> | nil
    ---@param thumbMiddle Lazy<FileName> | nil
    ---@param thumbTop    Lazy<FileName> | nil
    ---@param thumbBottom Lazy<FileName> | nil
    SetTextures = function(self, background, thumbMiddle, thumbTop, thumbBottom)
        if background and self._bg then self._bg:Set(background) end
        if thumbMiddle and self._tm then self._tm:Set(thumbMiddle) end
        if thumbTop and self._tt then self._tt:Set(thumbTop) end
        if thumbBottom and self._tb then self._tb:Set(thumbBottom) end
    end,
}

