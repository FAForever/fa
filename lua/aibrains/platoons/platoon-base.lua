
---@class AIPlatoon : moho.platoon_methods
---@field BuilderData table
---@field Units Unit[]
---@field Brain moho.aibrain_methods
---@field Trash TrashBag
AIPlatoon = Class(moho.platoon_methods) {

    ---@see `AIBrain:MakePlatoon`
    ---@param self AIPlatoon
    ---@param plan string
    OnCreate = function(self, plan)
        LOG("OnCreate")
        self.Trash = TrashBag()
        self.Brain = self:GetBrain()
        self.TrashState = TrashBag()
    end,

    ---@param self AIPlatoon
    OnDestroy = function(self)
        LOG("OnDestroy")
        self.Trash:Destroy()
    end,

    ---@param self AIPlatoon
    OnUnitsAddedToPlatoon = function(self)
        LOG("OnUnitsAddedToPlatoon")
        local units = self:GetPlatoonUnits()
        self.Units = units
        for k, unit in units do
            unit.AIPlatoonReference = self
        end
    end,

    ---@param self AIPlatoon
    PlatoonDisband = function(self)
        LOG("PlatoonDisband")
    end,

    ---@param self AIPlatoon
    ---@param name string
    ChangeState = function(self, name)
        LOG("ChangeState: " .. name)
        ChangeState(self, self[name])
    end,

    Blank = State {
        ---@param self AIPlatoon
        Main = function(self)
        end,
    },

    -----------------------------------------------------------------
    -- unit events

    --- Called as a unit of this platoon is killed
    ---@param self AIPlatoon
    ---@param unit Unit
    ---@param instigator Unit | Projectile | nil
    ---@param type DamageType
    ---@param overkillRatio number
    OnKilled = function(self, unit, instigator, type, overkillRatio)
    end,

    --- Called as a unit of this platoon starts building
    ---@param self AIPlatoon
    ---@param unit Unit
    ---@param target Unit
    ---@param order string
    OnStartBuild = function(self, unit, target, order)
    end,

    --- Called as a unit of this platoon stops building
    ---@param self AIPlatoon
    ---@param unit Unit
    ---@param target Unit
    OnStopBuild = function(self, unit, target)
    end,

    --- Called as a unit of this platoon starts repairing
    ---@param self AIPlatoon
    ---@param unit Unit
    ---@param target Unit
    OnStartRepair = function(self, unit, target)
    end,

    --- Called as a unit of this platoon stops repairing
    ---@param self AIPlatoon
    ---@param unit Unit
    ---@param target Unit
    OnStopRepair = function(self, unit, target)
    end,

    --- Called as a unit of this platoon starts reclaiming
    ---@param self AIPlatoon
    ---@param unit Unit
    ---@param target Unit | Prop
    OnStartReclaim = function(self, unit, target)
    end,

    --- Called as a unit of this platoon stops reclaiming
    ---@param self AIPlatoon
    ---@param unit Unit
    ---@param target Unit | Prop | nil      # is nil when the prop or unit is completely reclaimed
    OnStopReclaim = function(self, unit, target)
    end,

    --- Called as a unit of this platoon gains or loses health, fixed at intervals of 25%
    ---@param self AIPlatoon
    ---@param unit Unit
    ---@param new number
    ---@param old number
    OnHealthChanged = function(self, unit, new, old)
    end,

    --- Called as a unit of this platoon starts building a missile
    ---@param self AIPlatoon
    ---@param unit Unit
    ---@param weapon Weapon
    OnSiloBuildStart = function(self, unit, weapon)
    end,

    --- Called as a unit of this platoon stops building a missile
    ---@param self AIPlatoon
    ---@param unit Unit
    ---@param weapon Weapon
    OnSiloBuildEnd = function(self, unit, weapon)
    end,

    --- Called as a unit of this platoon starts working on an enhancement
    ---@param self AIPlatoon
    ---@param unit Unit
    ---@param work string
    OnWorkBegin = function(self, unit, work)
    end,

    --- Called as a unit of this platoon stops working on an enhancement
    ---@param self AIPlatoon
    ---@param unit Unit
    ---@param work string
    OnWorkEnd = function(self, unit, work)
    end,

    --- Called as a missile launched by a unit of this platoon is intercepted
    ---@param self AIPlatoon
    ---@param target Unit
    ---@param defense Unit
    ---@param position Vector
    OnMissileIntercepted = function(self, unit, target, defense, position)
    end,

    --- Called as a missile launched by a unit of this platoon hits a shield
    ---@param self AIPlatoon
    ---@param target Unit
    ---@param shield Unit
    ---@param position Vector
    OnMissileImpactShield = function(self, unit, target, shield, position)
    end,

    --- Called as a missile launched by a unit of this platoon impacts with the terrain
    ---@param self AIPlatoon
    ---@param target Unit
    ---@param position Vector
    OnMissileImpactTerrain = function(self, unit, target, position)
    end,

    --- Called as a shield of a unit of this platoon is enabled
    ---@param self AIPlatoon
    ---@param unit Unit
    OnShieldEnabled = function(self, unit)
    end,

    --- Called as a shield of a unit of this platoon is disabled
    ---@param self AIPlatoon
    ---@param unit Unit
    OnShieldDisabled = function(self, unit)
    end,

}