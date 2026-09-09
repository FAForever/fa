--- Intellisense helper class
---@class TargetPointerUnit : TargetPointerComponent, Unit

--- Component that allows disabling a unit's AI-controlling weapon so that it
--- doesn't stop at a distance when guarding another unit.
---@class TargetPointerComponent
---@field TargetPointer Weapon?
---@field TargetLayerCaps table<Layer, FireTargetCategory>?
---@field PointerEnabled boolean?
TargetPointerComponent = ClassSimple {
    --- Call this at the end of the unit's `OnStartBeingBuilt` function.
    ---@param self TargetPointerUnit
    InitializeTargetPointer = function(self)
        self.TargetPointer = self:GetWeapon(1)
        self.TargetLayerCaps = self.Blueprint.Weapon[1].FireTargetLayerCapsTable
        self.PointerEnabled = true
    end,

    --- Call this at the end of the unit's `OnLayerChange` function.
    ---@param self TargetPointerUnit
    OverrideTargetPointerLayerCaps = function(self)
        if not IsDestroyed(self.TargetPointer) then
            if self.PointerEnabled == false then
                -- Override the caps from default `weapon.lua` layer change behavior
                self.TargetPointer:SetFireTargetLayerCaps('None')
            end
        end
    end,

    --- Called by the `FlagShield` sim callback to disable the unit's AI
    --- stopping at a distance when guarding another unit.
    ---@param self TargetPointerUnit
    DisablePointer = function(self)
        if not IsDestroyed(self.TargetPointer) then
            self.TargetPointer:SetFireTargetLayerCaps('None') --this disables the stop feature - note that its reset on layer change!
            local thread = ForkThread(self.PointerRestart, self)
            self.Trash:Add(thread)
            self.PointerRestartThread = thread
        end
    end,

    --- Re-enables the AI when the unit stops guarding
    ---@package -- FIXME: Should be private but extension doesnt work with that
    ---@param self TargetPointerUnit
    PointerRestart = function(self)
        while self.PointerEnabled == false do
            WaitTicks(11)
            if IsDestroyed(self) or IsDestroyed(self.TargetPointer) then
                break
            end

            if not self:GetGuardedUnit() then
                self.PointerEnabled = true
                 -- this resets the stop feature - note that its reset on layer change!
                self.TargetPointer:SetFireTargetLayerCaps(self.TargetLayerCaps[self.Layer])
            end
        end
    end,


}
