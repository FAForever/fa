local StructureUnit = import('/lua/sim/units/StructureUnit.lua').StructureUnit

ShieldStructureUnit = Class(StructureUnit) {
    UpgradingState = State(StructureUnit.UpgradingState) {
        Main = function(self)
            StructureUnit.UpgradingState.Main(self)
        end,

        OnFailedToBuild = function(self)
            StructureUnit.UpgradingState.OnFailedToBuild(self)
        end,
    }
}
