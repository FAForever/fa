-- Class methods:
-- Destroy()
-- PostDragger(originFrame, keycode, dragger)

local DraggerMethods = moho.dragger_methods
local DraggerMethodsDestroy = DraggerMethods.Destroy

---@class Dragger : moho.dragger_methods, InternalObject, Destroyable
---@field Trash TrashBag
Dragger = ClassUI(DraggerMethods) {

    ---@param self Dragger
    __init = function(self)
        InternalCreateDragger(self)
        self.Trash = TrashBag()
    end,

    ---@param self Dragger
    Destroy = function(self)
        DraggerMethodsDestroy(self)
        self:OnDestroy()
    end,

    ---@param self Dragger
    OnDestroy = function(self)
        self.Trash:Destroy()
    end,

    ---@param self Dragger
    ---@param x number  # screen coordinates
    ---@param y number  # screen coordinates
    OnMove = function(self, x, y)
    end,

    ---@param self Dragger
    ---@param x number  # screen coordinates
    ---@param y number  # screen coordinates
    OnRelease = function(self, x, y)
        self:Destroy()
    end,

    ---@param self Dragger
    OnCancel = function(self)
        self:Destroy()
    end,
}
