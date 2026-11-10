local IsDestroyed = IsDestroyed
local WaitTicks = WaitTicks
local ForkThread = ForkThread

local UnitIsUnitState = moho.unit_methods.IsUnitState

--- Number of ticks between checks of the registered units
local CheckInterval = 1

--- Units with a target pointer, checked by the `TargetPointerThread`. An array so that iteration is deterministic.
---@type TargetPointerUnit[]
local TargetPointerUnits = {}
local TargetPointerUnitCount = 0

---@type thread?
local TargetPointerThreadInstance = nil

--- Intellisense helper class
---@class TargetPointerUnit : TargetPointerComponent, Unit

--- Disables the target pointer of units that are guarding, and re-enables it
--- for units that stopped guarding. The engine sets the `Guarding` state while
--- a guard (assist) order is the unit's current order.
local function TargetPointerThread()
    while TargetPointerUnitCount > 0 do
        local units = TargetPointerUnits
        local k = 1
        while k <= TargetPointerUnitCount do
            local unit = units[k]
            local targetPointer = unit.TargetPointer
            if IsDestroyed(unit) or IsDestroyed(targetPointer) then
                -- swap-remove the unit
                units[k] = units[TargetPointerUnitCount]
                units[TargetPointerUnitCount] = nil
                TargetPointerUnitCount = TargetPointerUnitCount - 1
            else
                ---@cast targetPointer -nil
                if UnitIsUnitState(unit, 'Guarding') then
                    if unit.PointerEnabled then
                        unit.PointerEnabled = false
                        -- this disables the stop feature - note that it's reset on layer change!
                        targetPointer:SetFireTargetLayerCaps('None')
                    end
                elseif not unit.PointerEnabled then
                    unit.PointerEnabled = true
                    -- this resets the stop feature - note that it's reset on layer change!
                    targetPointer:SetValidTargetsForCurrentLayer(unit.Layer)
                end
                k = k + 1
            end
        end

        WaitTicks(CheckInterval)
    end

    TargetPointerThreadInstance = nil
end

--- Component that allows disabling a unit's AI-controlling weapon so that it
--- doesn't stop at a distance when guarding another unit.
---@class TargetPointerComponent
---@field package TargetPointer Weapon?
---@field package PointerEnabled boolean?
TargetPointerComponent = ClassSimple {
    --- Call this at the end of the unit's `OnStopBeingBuilt` function.
    ---@param self TargetPointerUnit
    InitializeTargetPointer = function(self)
        local weapon = self.WeaponInstances[1]
        if weapon then
            self.TargetPointer = weapon
            self.PointerEnabled = true

            TargetPointerUnitCount = TargetPointerUnitCount + 1
            TargetPointerUnits[TargetPointerUnitCount] = self
            if not TargetPointerThreadInstance then
                TargetPointerThreadInstance = ForkThread(TargetPointerThread)
            end
        else
            self:DebugWarn('Does not have weapon for target pointer!')
        end
    end,

    --- Call this at the end of the unit's `OnLayerChange` function.
    ---@param self TargetPointerUnit
    OverrideTargetPointerLayerCaps = function(self)
        local targetPointer = self.TargetPointer
        if not IsDestroyed(targetPointer) then
            ---@cast targetPointer -nil
            if self.PointerEnabled == false then
                -- Override the caps from default `weapon.lua` layer change behavior
                targetPointer:SetFireTargetLayerCaps('None')
            end
        end
    end,
}
