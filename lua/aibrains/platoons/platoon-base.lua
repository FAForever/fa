
local AIPlatoonMoho = moho.platoon_methods

-- upvalue scope for performance
local IsDestroyed = IsDestroyed

local TableGetn = table.getn

---@type Vector
local BaseDirectionForAngles = { 0, 0, 1 }

---@class AIPlatoon : moho.platoon_methods
---@field BuilderData table
---@field Units Unit[]
---@field Brain moho.aibrain_methods
---@field Trash TrashBag
---@field PlatoonUnits
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

    -----------------------------------------------------------------
    -- platoon functions

    ---@param self AIPlatoon
    ---@param units Unit[] | nil
    ---@param origin Vector | nil
    ---@param waypoint Vector
    ---@param formation UnitFormations | 'GrowthFormation' | nil
    ---@return SimCommand
    IssueFormMoveToWaypoint = function(self, units, origin, waypoint, formation)
        -- default values
        units = units or self:GetPlatoonUnits()
        origin = origin or self:GetPlatoonPosition()
        formation = formation or 'GrowthFormation'

        -- compute normalized direction
        local dx = waypoint[1] - origin[1]
        local dz = waypoint[3] - origin[3]
        local di = 1 / math.sqrt(dx * dx + dz * dz)
        dx = di * dx
        dz = di * dz

        -- compute radians
        local rads = math.acos(dz)
        if dx < 0 then
            rads = 2 * 3.14159 - rads
        end

        -- convert to degrees
        local degrees = 57.2958279 * rads

        return IssueFormMove(units, waypoint, formation, degrees)
    end,

    -----------------------------------------------------------------
    -- platoon states

    ---@param self AIPlatoon
    ---@param name string
    ChangeState = function(self, name)
        LOG(tostring(self) .. " - Changing state to: " .. name)

        WaitTicks(1)

        if not IsDestroyed(self) then
            ChangeState(self, self[name])
        end
    end,

    Start = State {
        ---@param self AIPlatoon
        Main = function(self)
            LOG(tostring(self) .. " - Start")
            self:ChangeState('Error')
        end,
    },

    Error = State {
        ---@param self AIPlatoon
        Main = function(self)
            LOG(tostring(self) .. " - Error")

            -- tell the developer that something went wrong
            while not IsDestroyed(self) do
                DrawCircle(self:GetPlatoonPosition(), 10, 'ff0000')
                WaitTicks(1)
            end
        end,
    },

    -----------------------------------------------------------------
    -- brain events

    ---@param self AIPlatoon
    ---@param units Unit[]
    OnUnitsAddedToAttackSquad = function(self, units)
        LOG("OnUnitsAddedToAttackSquad")
    end,

    ---@param self AIPlatoon
    ---@param units Unit[]
    OnUnitsAddedToScoutSquad = function(self, units)
        LOG("OnUnitsAddedToScoutSquad")
    end,

    ---@param self AIPlatoon
    ---@param units Unit[]
    OnUnitsAddedToArtillerySquad = function(self, units)
        LOG("OnUnitsAddedToArtillerySquad")
    end,

    ---@param self AIPlatoon
    ---@param units Unit[]
    OnUnitsAddedToSupportSquad = function(self, units)
        LOG("OnUnitsAddedToSupportSquad")
    end,

    ---@param self AIPlatoon
    ---@param units Unit[]
    OnUnitsAddedToGuardSquad = function(self, units)
        LOG("OnUnitsAddedToGuardSquad")
    end,

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

    -----------------------------------------------------------------
    -- hooks

    --- Returns all units that are part of this platoon.
    ---@param self AIPlatoon
    ---@return Unit[]   # Table of alive (non-destroyed) units
    ---@return number   # Number of units
    GetPlatoonUnits = function(self)

        -- this function is hooked because the cfunction returns units
        -- that are destroyed. We filter those out and return the remainder

        local units = AIPlatoonMoho.GetPlatoonUnits(self)

        -- populate the cache
        local head = 1
        for k, unit in units do
            if not IsDestroyed(unit) then
                units[head] = unit
                head = head + 1
            end
        end

        -- discard remaining elements of the cache
        local count = TableGetn(units)
        if count >= head then
            for k = head, count do
                units[k] = nil
            end
        end

        return units, head - 1
    end,

}