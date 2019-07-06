-----------------------------------------------------------------
-- File     :  /cdimage/units/XRB0204/XRB0204_script.lua
-- Author(s):  Dru Staltman, Gordon Duclos
-- Summary  :  Cybran Engineering tower
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

local CConstructionStructureUnit = import('/lua/cybranunits.lua').CConstructionStructureUnit

XRB0204 = Class(CConstructionStructureUnit) {
    OnStartBeingBuilt = function(self, builder, layer)
        CConstructionStructureUnit.OnStartBeingBuilt(self, builder, layer)
        local target = self:GetBlueprint().General.UpgradesFrom

        -- Check if we're really being built on top of another unit (as an upgrade).
        -- We might be being rebuild by the slightly bugtacular SCU REBUILDER behaviour, in which
        -- case we want to show all our bones anyway.
        local upos = self:GetPosition()
        local candidates = GetUnitsInRect(Rect(upos[1], upos[3], upos[1], upos[3]))
        for k, v in candidates do
            if target == v:GetBlueprint().BlueprintId then
                self:HideBones({'xrb0304'}, true)
                self:ShowBones({'TurretT2',
                                'Door2_B02',
                                'B02',
                                'Attachpoint02'},
                                true)
                return
            end
        end
    end,

    OnStopBeingBuilt = function(self, builder, layer)
        CConstructionStructureUnit.OnStopBeingBuilt(self, builder, layer)

        self:ShowBones({'xrb0304'}, true)
    end,

    OnStartBuild = function(self, unitBeingBuilt, order)
        if not self.AnimationManipulator then
            self.AnimationManipulator = CreateAnimator(self)
            self.Trash:Add(self.AnimationManipulator)
        end
        self.AnimationManipulator:PlayAnim(self:GetBlueprint().Display.AnimationOpen, false):SetRate(1)

        CConstructionStructureUnit.OnStartBuild(self, unitBeingBuilt, order)
    end,

    OnStopBuild = function(self, unitBeingBuilt)
        CConstructionStructureUnit.OnStopBuild(self, unitBeingBuilt)

        if not self.AnimationManipulator then
            self.AnimationManipulator = CreateAnimator(self)
            self.Trash:Add(self.AnimationManipulator)
        end
        self.AnimationManipulator:SetRate(-1)
    end,
}
TypeClass = XRB0204
