local AIPlatoon = import("/lua/aibrains/platoons/platoon-base.lua").AIPlatoon

local WeakValue = { __mode = 'v' }

-- upvalue scope for performance
local ForkThread = ForkThread
local WaitTicks = WaitTicks
local IssueTactical = IssueTactical

local TableGetn = table.getn
local TableEmpty = table.empty
local TableRandom = table.random

---@class AIPlatoonSilo : AIPlatoon
---@field Targets EntityCategory
---@field ReadyToLaunch table<EntityId, Unit>
AIPlatoonSilo = Class(AIPlatoon) {

    AIBehaviorTacticalSimple = State {

        -- series of valid targets for the silo
        Targets = (categories.MASSEXTRACTION + categories.ENERGYPRODUCTION + categories.RESEARCH) *
            (categories.TECH2 + categories.TECH3),

        ---@param self AIPlatoonSilo
        Main = function(self)
            self.ReadyToLaunch = setmetatable({}, WeakValue)

            ---@type Unit | nil
            local target

            ---@type moho.aibrain_methods
            local brain = self:GetBrain()

            while not IsDestroyed(self) do

                -- find target
                if not target or IsDestroyed(target) then
                    local units = brain:GetUnitsAroundPoint(
                        self.Targets,
                        self:GetPlatoonPosition(),
                        100, -- TODO: determine range dynamically?
                        'Enemy'
                    )

                    -- choose a random target
                    if units and not TableEmpty(units) then
                        target = TableRandom(units)
                    end
                end

                -- fire at target
                local launchers = self.ReadyToLaunch
                if target and not IsDestroyed(target) and not TableEmpty(launchers) then

                    local health = target:GetHealth()
                    for _, unit in launchers do

                        -- unit should be destroyed at this point
                        if health < 0 then
                            target = nil
                            break
                        end

                        -- TODO: make this dynamic somehow
                        health = health - 5000

                        IssueTactical({unit}, target)

                        -- check ammo
                        if unit:GetTacticalSiloAmmoCount() <= 1 then
                            launchers[unit.EntityId] = nil
                        end
                    end

                    WaitTicks(20)
                else
                    WaitTicks(100)
                end
            end
        end,

        --- Initiates the search for a target, if we are not already searching for one
        ---@param self AIPlatoonSilo
        ---@param unit Unit
        ---@param weapon Weapon
        OnSiloBuildEnd = function(self, unit, weapon)
            self.ReadyToLaunch[unit.EntityId] = unit
        end,

        --- Pauses the silo if it is too damaged, to save on resources
        ---@param self AIPlatoon
        ---@param unit Unit
        ---@param new number
        ---@param old number
        OnHealthChanged = function(self, unit, new, old)
            -- pause the missile launcher when we're too damaged
            if new >= 0.75 then
                unit:SetPaused(false)
            else
                unit:SetPaused(true)
            end
        end,
    },
}

---@param data { Behavior: 'AIBehaviorTacticalSimple' }
---@param units Unit[]
DebugAssignToUnits = function(data, units)
    if units and not TableEmpty(units) then
        local brain = units[1].Brain
        local platoon = brain:MakePlatoon('', '') --[[@as AIPlatoonSilo]]
        setmetatable(platoon, AIPlatoonSilo)
        brain:AssignUnitsToPlatoon(platoon, units, 'Attack', 'None')
        platoon:ChangeState(data.Behavior)
    end
end
