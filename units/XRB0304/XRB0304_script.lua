-----------------------------------------------------------------
-- File     :  /cdimage/units/XRB0304/XRB0304_script.lua
-- Author(s):  Dru Staltman, Gordon Duclos
-- Summary  :  Cybran Engineering tower
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------
local CConstructionStructureUnit = import("/lua/cybranunits.lua").CConstructionStructureUnit

---@class XRB0304 : CConstructionStructureUnit
XRB0304 = ClassUnit(CConstructionStructureUnit) {
    OnStartBeingBuilt = function(self, builder, layer)
        CConstructionStructureUnit.OnStartBeingBuilt(self, builder, layer)

        local target = self.Blueprint.General.UpgradesFrom

        -- Check if we're really being built on top of another unit (as an upgrade).
        -- We might be being rebuild by the slightly bugtacular SCU REBUILDER behaviour, in which
        -- case we want to show all our bones anyway.
        local upos = self:GetPosition()
        local candidates = GetUnitsInRect(upos[1], upos[3], upos[1], upos[3])
        for k, v in candidates do
            if target == v.Blueprint.BlueprintId then
                self:HideBone('xrb0304', true)
                self:ShowBone('TurretT3', true)
                self:ShowBone('Door3_B03', true)
                self:ShowBone('B03', true)
                self:ShowBone('Attachpoint03', true)
                return
            end
        end
    end,
}

TypeClass = XRB0304
