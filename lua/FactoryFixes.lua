#****************************************************************************
#**
#**  File     :  /lua/FactoryFixes.lua
#**  Author(s):  Brute51
#**
#**  Summary  :  Additional code for factory structures (not mobile units).
#**
#****************************************************************************
#**
#** A bug fix and a feature in here. Do not use for mobile factories!
#** The new feature is rolloff delay. Read documentation before using this!
#**
#****************************************************************************

local StructureUnit = import('/lua/defaultunits.lua').StructureUnit

function FactoryFixes( FactoryClass )

    # Do not use for mobile factories!
    return Class(FactoryClass) {

         OnKilled = function(self, instigator, type, overkillRatio)
            StructureUnit.OnKilled(self, instigator, type, overkillRatio) # bypassing factoryunit onkilled event
            # added by brute51 - check if we're building a unit before destroying it [114]
            if self.UnitBeingBuilt and not self.UnitBeingBuilt:BeenDestroyed() and self.UnitBeingBuilt:GetFractionComplete() != 1 then
                self.UnitBeingBuilt:Destroy()
            end
        end,

        # rolloff delay. See miscellaneous.txt file for more info
        OnStopBuild = function(self, unitBeingBuilt, order )
            local bp = self:GetBlueprint()
            if bp.General.RolloffDelay and bp.General.RolloffDelay > 0 and not self.FactoryBuildFailed then
                self:ForkThread(self.PauseThread, unitBeingBuilt, order)
            else
                FactoryClass.OnStopBuild(self, unitBeingBuilt, order)
            end
        end,

        PauseThread = function(self, unitBeingBuilt, order)
            # adds a pause between unit productions
            self:StopBuildFx()
            local productionpause = self:GetBlueprint().General.RolloffDelay
            if productionpause and productionpause > 0 then
                self:SetBusy(true) 
                self:SetBlockCommandQueue(true) 
                WaitSeconds(productionpause)
                self:SetBusy(false) 
                self:SetBlockCommandQueue(false) 
            end
            FactoryClass.OnStopBuild(self, unitBeingBuilt, order)
        end,

    }
end
