local Unit = import('/lua/sim/Unit.lua').Unit

--- A non-unit. Unclear if this is actually still useful.
DummyUnit = Class(Unit) {
    OnStopBeingBuilt = function(self)
        self:Destroy()
    end,
}
