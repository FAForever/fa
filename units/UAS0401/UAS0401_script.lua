#****************************************************************************
#**
#**  File     :  /cdimage/units/UAS0401/UAS0401_script.lua
#**  Author(s):  John Comes
#**
#**  Summary  :  Aeon Experimental Sub
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

local ASubUnit = import('/lua/aeonunits.lua').ASubUnit
local ASeaUnit = import('/lua/aeonunits.lua').ASeaUnit
local WeaponsFile = import('/lua/aeonweapons.lua')
local ADFCannonOblivionWeapon = WeaponsFile.ADFCannonOblivionWeapon02
local AANChronoTorpedoWeapon = WeaponsFile.AANChronoTorpedoWeapon
local AIFQuasarAntiTorpedoWeapon = WeaponsFile.AIFQuasarAntiTorpedoWeapon

UAS0401 = Class(ASeaUnit) {
    Weapons = {
        MainGun = Class(ADFCannonOblivionWeapon) {},
        Torpedo01 = Class(AANChronoTorpedoWeapon) {},
        Torpedo02 = Class(AANChronoTorpedoWeapon) {},
        Torpedo03 = Class(AANChronoTorpedoWeapon) {},
        Torpedo04 = Class(AANChronoTorpedoWeapon) {},
        Torpedo05 = Class(AANChronoTorpedoWeapon) {},
        Torpedo06 = Class(AANChronoTorpedoWeapon) {},
        AntiTorpedo01 = Class(AIFQuasarAntiTorpedoWeapon) {},
        AntiTorpedo02 = Class(AIFQuasarAntiTorpedoWeapon) {},
    },


    BuildAttachBone = 'Attachpoint01',

    OnStopBeingBuilt = function(self,builder,layer)
        self:SetWeaponEnabledByLabel('MainGun', true)
        ASeaUnit.OnStopBeingBuilt(self,builder,layer)
        if layer == 'Water' then
            self:RestoreBuildRestrictions()
            self:RequestRefreshUI()
        else
            self:AddBuildRestriction(categories.ALLUNITS)
            self:RequestRefreshUI()
        end
        ChangeState(self, self.IdleState)
    end,

    OnFailedToBuild = function(self)
        ASeaUnit.OnFailedToBuild(self)
        ChangeState(self, self.IdleState)
    end,

    OnMotionVertEventChange = function( self, new, old )
        ASeaUnit.OnMotionVertEventChange(self, new, old)
        if new == 'Top' then
            self:RestoreBuildRestrictions()
            self:RequestRefreshUI()
            self:SetWeaponEnabledByLabel('MainGun', true)
            self:PlayUnitSound('Open')
        elseif new == 'Down' then
            self:SetWeaponEnabledByLabel('MainGun', false)
            self:AddBuildRestriction(categories.ALLUNITS)
            self:RequestRefreshUI()
            self:PlayUnitSound('Close')
        end
    end,

    IdleState = State {
        Main = function(self)
            self:DetachAll(self.BuildAttachBone)
            self:SetBusy(false)
        end,

        OnStartBuild = function(self, unitBuilding, order)
            ASeaUnit.OnStartBuild(self, unitBuilding, order)
            self.UnitBeingBuilt = unitBuilding
            ChangeState(self, self.BuildingState)
        end,
    },

    BuildingState = State {
        Main = function(self)
            local unitBuilding = self.UnitBeingBuilt
            self:SetBusy(true)
            local bone = self.BuildAttachBone
            self:DetachAll(bone)
            if not self.UnitBeingBuilt:IsDead() then
                unitBuilding:AttachBoneTo( -2, self, bone )
                if EntityCategoryContains( categories.ENGINEER + categories.uas0102 + categories.uas0103, unitBuilding ) then
                    unitBuilding:SetParentOffset( {0,0,1} )
                elseif EntityCategoryContains( categories.TECH2 - categories.ENGINEER, unitBuilding ) then
                    unitBuilding:SetParentOffset( {0,0,3} )
                elseif EntityCategoryContains( categories.uas0203, unitBuilding ) then
                    unitBuilding:SetParentOffset( {0,0,1.5} )
                else
                    unitBuilding:SetParentOffset( {0,0,2.5} )
                end
            end
            self.UnitDoneBeingBuilt = false
        end,

        OnStopBuild = function(self, unitBeingBuilt)
            ASeaUnit.OnStopBuild(self, unitBeingBuilt)
            ChangeState(self, self.FinishedBuildingState)
        end,
    },

    FinishedBuildingState = State {
        Main = function(self)
            self:SetBusy(true)
            local unitBuilding = self.UnitBeingBuilt
            unitBuilding:DetachFrom(true)
            self:DetachAll(self.BuildAttachBone)
            local worldPos = self:CalculateWorldPositionFromRelative({0, 0, -20})
            IssueMoveOffFactory({unitBuilding}, worldPos)
            self:SetBusy(false)
            ChangeState(self, self.IdleState)
        end,
    },
	
	OnKilled = function(self, instigator, type, overkillRatio)
		local nrofBones = self:GetBoneCount() -1
		local watchBone = self:GetBlueprint().WatchBone or 0
		LOG(self:GetBlueprint().Description, " watchbone is ", watchBone)

 		self:ForkThread(function()
			-- LOG("Sinker thread created")
			local pos = self:GetPosition()
			local seafloor = GetTerrainHeight(pos[1], pos[3]) + GetTerrainTypeOffset(pos[1], pos[3])
			while self:GetPosition(watchBone)[2] > seafloor do
				WaitSeconds(0.1)
				-- LOG("Sinker: ", repr(self:GetPosition()))
			end
			#CreateScaledBoom(self, overkillRatio, watchBone)
			self:CreateWreckage(overkillRatio, instigator)
			self:Destroy()
		end)
         
        local layer = self:GetCurrentLayer()
        self:DestroyIdleEffects()
        if (layer == 'Water' or layer == 'Seabed' or layer == 'Sub') then
            self.SinkExplosionThread = self:ForkThread(self.ExplosionThread)
            self.SinkThread = self:ForkThread(self.SinkingThread)
        end
		ASeaUnit.OnKilled(self, instigator, type, overkillRatio)
    end
}

TypeClass = UAS0401