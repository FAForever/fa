
---@class AIPlatoon : moho.platoon_methods
---@field BuilderData table
---@field Trash TrashBag
AIPlatoon = Class(moho.platoon_methods) {

    ---@see `AIBrain:MakePlatoon`
    ---@param self AIPlatoon
    ---@param plan string
    OnCreate = function(self, plan)
        self.Trash = TrashBag()
        self.Plan = plan
    end,

    OnDestroy = function(self)
        self.Trash:Destroy()
    end,


    OnUnitsAddedToPlatoon = function(self)

    end,

    PlatoonDisband = function(self)

    end,

}