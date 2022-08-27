-- Class methods:
-- Destroy()
-- PostDragger(originFrame, keycode, dragger)

---@class Dragger : moho.dragger_methods
Dragger = Class(moho.dragger_methods) {

    __init = function(self)
        InternalCreateDragger(self)
    end,

    OnMove = function(self, x, y)
    end,

    OnRelease = function(self, x, y)
        self:Destroy()
    end,

    OnCancel = function(self)
        self:Destroy()
    end,

}

