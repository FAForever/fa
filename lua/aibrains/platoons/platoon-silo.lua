local AIPlatoon = import("/lua/aibrains/platoons/platoon-base.lua").AIPlatoon

-- upvalue scope for performance
local ForkThread = ForkThread
local WaitTicks = WaitTicks
local IssueTactical = IssueTactical
local TableEmpty = table.empty
local TableRandom = table.random

---@class AIPlatoonSilo : AIPlatoon
---@field Base AIBase
---@field Brain AIBrain
---@field Targets EntityCategory
---@field TargetScanningThread thread
AIPlatoonSilo = Class(AIPlatoon) {

    AIBehaviorTactical = State {

        -- series of valid targets for the silo
        Targets = (categories.MASSEXTRACTION + categories.ENERGYPRODUCTION + categories.RESEARCH) *
            (categories.TECH2 + categories.TECH3),

        ---@param self AIPlatoonSilo
        Main = function(self)
        end,

        --- Scans the surrounding of the silo for targets. Assumes to be running in a thread
        ---@param self AIPlatoonSilo
        ---@param unit Unit
        ---@param weapon Weapon
        TargetScanning = function(self, unit, weapon)
            -- local scope for performance
            local brain = self:GetBrain()

            while unit:GetTacticalSiloAmmoCount() > 0 do

                -- search for a target
                local units = brain:GetUnitsAroundPoint(
                    self.Targets,
                    unit:GetPosition(),
                    weapon.Blueprint.MaxRadius,
                    'Enemy'
                )

                if units and not TableEmpty(units) then
                    IssueTactical({ unit }, TableRandom(units))
                end

                WaitTicks(100)
            end

            self.TargetScanningThread = nil
        end,

        --- Initiates the search for a target, if we are not already searching for one
        ---@param self AIPlatoonSilo
        ---@param unit Unit
        ---@param weapon Weapon
        OnSiloBuildEnd = function(self, unit, weapon)
            if not self.TargetScanningThread then
                local targetScanningThread = ForkThread(self.TargetScanning, self, unit, weapon)
                self.Trash:Add(targetScanningThread)
                self.TargetScanningThread = targetScanningThread
            end
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

---@param data { Behavior: 'AIBehaviorTactical' }
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
