local IsDestroyed = IsDestroyed
local WaitTicks = WaitTicks

--- Intellisense helper class
---@class TargetPointerUnit : TargetPointerComponent, Unit

--- Component that allows disabling a unit's AI-controlling weapon so that it
--- doesn't stop at a distance when guarding another unit.
---@class TargetPointerComponent
---@field package TargetPointer Weapon?
---@field package PointerEnabled boolean?
TargetPointerComponent = ClassSimple {
    --- Call this at the end of the unit's `OnStartBeingBuilt` function.
    ---@param self TargetPointerUnit
    InitializeTargetPointer = function(self)
        local weapon = self.WeaponInstances[1]
        if weapon then
            self.TargetPointer = weapon
            self.PointerEnabled = true
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

    --- Called by the `FlagShield` sim callback to disable the unit's AI
    --- stopping at a distance when guarding another unit.
    ---@param self TargetPointerUnit
    DisablePointer = function(self)
        local targetPointer = self.TargetPointer
        if not IsDestroyed(targetPointer) then
            ---@cast targetPointer -nil
            targetPointer:SetFireTargetLayerCaps('None') --this disables the stop feature - note that its reset on layer change!
            self.PointerRestartThread = self:ForkThread(self.PointerRestart, self)
        end
    end,

    --- Re-enables the AI when the unit stops guarding
    ---@package -- FIXME: Should be private but extension doesnt work with that
    ---@param self TargetPointerUnit
    PointerRestart = function(self)
        local targetPointer = self.TargetPointer
        while self.PointerEnabled == false do
            WaitTicks(11)
            if IsDestroyed(self) or IsDestroyed(targetPointer) then
                return
            end
            ---@cast targetPointer -nil

            if not self:GetGuardedUnit() then
                self.PointerEnabled = true
                -- this resets the stop feature - note that its reset on layer change!
                targetPointer:SetValidTargetsForCurrentLayer(self.Layer)
                return
            end
        end
    end,


}
