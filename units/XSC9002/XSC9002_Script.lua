#****************************************************************************
#**
#**  File     :  /cdimage/units/XSC9002/XSC9002_script.lua
#**  Author   :  Greg Kohne
#**  Summary  :  Jamming Crystal
#**
#**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************
local SStructureUnit = import('/lua/seraphimunits.lua').SStructureUnit
local SSJammerCrystalAmbient = import('/lua/EffectTemplates.lua').SJammerCrystalAmbient


XSC9002 = Class(SStructureUnit) {

    OnCreate = function(self, builder, layer)
        ###SEnergyCreationUnit.OnStopBeingBuilt(self, builder, layer)
        ####self.Trash:Add(CreateRotator(self, 'Orb', 'y', nil, 0, 15, 80 + Random(0, 20)))

        ###Place emitters on certain light bones on the mesh.
        for k, v in SSJammerCrystalAmbient do
            CreateAttachedEmitter(self, 'XSC9002', self:GetArmy(), v)
        end

        self:ForkThread(self.LandBlipThread)
        self:ForkThread(self.AirBlipThread)

        # Make unit uncapturable
        self:SetCapturable(false)

        SStructureUnit.OnCreate(self)
    end,

    LandBlipThread = function(self)
        local position = self:GetPosition()

        while not self:IsDead() do
            --Spawn land blips
            self.landChildUnit = CreateUnitHPR('XSC9010', self:GetArmy(), position[1], position[2], position[3], 0, 0, 0)
            self.landChildUnit.parentCrystal = self

            WaitSeconds(Random(7,13))

            self.landChildUnit:Destroy()
            self.landChildUnit = nil

            #WaitSeconds(Random(2,7))
        end
    end,

    AirBlipThread = function(self)
        local position = self:GetPosition()

        while not self:IsDead() do
            --Spawn air blips
            self.airChildUnit = CreateUnitHPR('XSC9011', self:GetArmy(), position[1], position[2], position[3], 0, 0, 0)
            self.airChildUnit.parentCrystal = self

            IssuePatrol({self.airChildUnit}, {position[1] + Random(-10, 10), position[2], position[3] + Random(-10, 10)})
            IssuePatrol({self.airChildUnit}, {position[1] + Random(-10, 10), position[2], position[3] + Random(-10, 10)})
            IssuePatrol({self.airChildUnit}, {position[1] + Random(-10, 10), position[2], position[3] + Random(-10, 10)})
            IssuePatrol({self.airChildUnit}, {position[1] + Random(-10, 10), position[2], position[3] + Random(-10, 10)})

            WaitSeconds(Random(7,13))

            self.airChildUnit:Destroy()
            self.airChildUnit = nil

            #WaitSeconds(Random(2,7))
        end
    end,

    OnKilled = function(self, instigator, type, excessDamageRatio)
        if self.airChildUnit then self.airChildUnit:Destroy() end
        if self.landChildUnit then self.landChildUnit:Destroy() end

        SStructureUnit.OnKilled(self, instigator, type, excessDamageRatio)
    end,

}


TypeClass = XSC9002


