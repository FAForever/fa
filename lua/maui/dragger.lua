-- Class methods:
-- Destroy()
-- PostDragger(originFrame, keycode, dragger)

---@class Dragger : moho.dragger_methods, InternalObject
Dragger = ClassUI(moho.dragger_methods) {
    ---@param self Dragger
    __init = function(self)
        InternalCreateDragger(self)
    end,

    ---@param self Dragger
    ---@param x number
    ---@param y number
    OnMove = function(self, x, y)
    end,

    ---@param self Dragger
    ---@param x number
    ---@param y number
    OnRelease = function(self, x, y)
        self:Destroy()
    end,

    ---@param self Dragger
    OnCancel = function(self)
        self:Destroy()
    end,
}
