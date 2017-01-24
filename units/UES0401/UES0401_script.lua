-----------------------------------------------------------------
-- File     :  /cdimage/units/UES0401/UES0401_script.lua
-- Author(s):  John Comes, David Tomandl
-- Summary  :  UEF Experimental Submersible Aircraft Carrier Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------
local TSeaUnit = import('/lua/terranunits.lua').TSeaUnit
local TANTorpedoAngler = import('/lua/terranweapons.lua').TANTorpedoAngler
local TSAMLauncher = import('/lua/terranweapons.lua').TSAMLauncher
local EffectUtil = import('/lua/EffectUtilities.lua')
local CreateBuildCubeThread = EffectUtil.CreateBuildCubeThread

UES0401 = Class(TSeaUnit) {
    BuildAttachBone = 'UES0401',
    
    Weapons = {
        Torpedo01 = Class(TANTorpedoAngler) {},
        Torpedo02 = Class(TANTorpedoAngler) {},
        Torpedo03 = Class(TANTorpedoAngler) {},
        Torpedo04 = Class(TANTorpedoAngler) {},
        MissileRack01 = Class(TSAMLauncher) {},
        MissileRack02 = Class(TSAMLauncher) {},
        MissileRack03 = Class(TSAMLauncher) {},
        MissileRack04 = Class(TSAMLauncher) {},
    },
	
	OnKilled = function(self, instigator, type, overkillRatio)
		TSeaUnit.OnKilled(self, instigator, type, overkillRatio)
	end,

    OnCreate = function(self)
        TSeaUnit.OnCreate(self)
        self.OpenAnimManips = {}
        self.OpenAnimManips[1] = CreateAnimator(self):PlayAnim('/units/ues0401/ues0401_aopen.sca'):SetRate(-1)
        for i = 2, 6 do
            self.OpenAnimManips[i] = CreateAnimator(self):PlayAnim('/units/ues0401/ues0401_aopen0' .. i .. '.sca'):SetRate(-1)
        end
        for k, v in self.OpenAnimManips do
            self.Trash:Add(v)
        end
        if self:GetCurrentLayer() == 'Water' then
            self:PlayAllOpenAnims(true)
        end
    end,

    StartBeingBuiltEffects = function(self, builder, layer)
		self:SetMesh(self:GetBlueprint().Display.BuildMeshBlueprint, true)
        if self:GetBlueprint().General.UpgradesFrom != builder:GetUnitId() then
			self:HideBone(0, true)        
            self.OnBeingBuiltEffectsBag:Add( self:ForkThread( CreateBuildCubeThread, builder, self.OnBeingBuiltEffectsBag ))
        end
    end,  

    PlayAllOpenAnims = function(self, open)
        for k, v in self.OpenAnimManips do
            if open then
                v:SetRate(1)
            else
                v:SetRate(-1)
            end
        end
    end,

    OnMotionVertEventChange = function( self, new, old )
        TSeaUnit.OnMotionVertEventChange(self, new, old)
        if new == 'Down' then
            self:PlayAllOpenAnims(false)
        elseif new == 'Top' then
            self:PlayAllOpenAnims(true)
        end
        
        if (new == 'Up' and old == 'Bottom') then --when starting to surface
            self.WatchDepth = false
        end
        if (new == 'Bottom' and old == 'Down') then --when finished diving
            self.WatchDepth = true
            if not self.DiverThread then
                self.DiverThread = self:ForkThread(self.DiveDepthThread)
            end
        end
    end,

    DiveDepthThread = function(self)
        -- takes the given location, adjusts the Y value to the surface height on that location, with an offset
        local Yoffset = 1.2 --the default (built in) offset appears to be 0.25 - if the place where thats set is found, that would be epic.
        -- 1.2 is for tempest to clear the torpedo tubes from most cases of ground clipping, keeping overall height minimal.
        while self.WatchDepth == true do
            local pos = self:GetPosition()
            local seafloor = GetTerrainHeight(pos[1], pos[3]) + GetTerrainTypeOffset(pos[1], pos[3]) --target depth, in this case the seabed
            --local difference = pos[2] - math.max((seafloor + Yoffset), self.elevation) -- saved for later, sets depth to elevation in bp
            local difference = math.max(((seafloor + Yoffset) - pos[2]), -0.5) --doesnt sink too much, just maneuveres the bed better.
            self.SinkSlider:SetSpeed(1)
            WARN(repr(self))
            
            self.SinkSlider:SetGoal(0, difference, 0)
            WaitSeconds(1)
        end
        self.SinkSlider:SetGoal(0, 0, 0) --reset the slider while we are not watching depth
        WaitFor(self.SinkSlider)-- we have to wait for it to finish before killing the thread or it stops
        
        KillThread(self.DiverThread)
    end,

    OnStopBeingBuilt = function(self,builder,layer)
        TSeaUnit.OnStopBeingBuilt(self,builder,layer)
        ChangeState(self, self.IdleState)
        
        if not self.SinkSlider then --setup the slider and get blueprint values
            self.SinkSlider = CreateSlider(self, 0, 0, 0, 0, 5, true) --create sink controller to overlay ontop of original collision detection
            self.Trash:Add(self.SinkSlider)
        end
        
        --local bp = self:GetBlueprint() -- saved for later, sets depth to elevation in bp
        --self.elevation = bp.Physics.Elevation -- saved for later, sets depth to elevation in bp
        self.WatchDepth = false
        
    end,

    OnFailedToBuild = function(self)
        TSeaUnit.OnFailedToBuild(self)
        ChangeState(self, self.IdleState)
    end,

    IdleState = State {
        Main = function(self)
            self:DetachAll(self.BuildAttachBone)
            self:SetBusy(false)
        end,

        OnStartBuild = function(self, unitBuilding, order)
            TSeaUnit.OnStartBuild(self, unitBuilding, order)
            self.UnitBeingBuilt = unitBuilding
            ChangeState(self, self.BuildingState)
        end,
    },

    BuildingState = State {
        Main = function(self)
            local unitBuilding = self.UnitBeingBuilt
            local bone = self.BuildAttachBone
            self:DetachAll(bone)
            unitBuilding:HideBone(0, true)
            self.UnitDoneBeingBuilt = false
        end,

        OnStopBuild = function(self, unitBeingBuilt)
            TSeaUnit.OnStopBuild(self, unitBeingBuilt)
            ChangeState(self, self.FinishedBuildingState)
        end,
    },

    FinishedBuildingState = State {
        Main = function(self)
            local unitBuilding = self.UnitBeingBuilt
            unitBuilding:DetachFrom(true)
            self:DetachAll(self.BuildAttachBone)
            if self:TransportHasAvailableStorage() then
                self:AddUnitToStorage(unitBuilding)
            else
                local worldPos = self:CalculateWorldPositionFromRelative({0, 0, -20})
                IssueMoveOffFactory({unitBuilding}, worldPos)
                unitBuilding:ShowBone(0,true)
            end
            self:RequestRefreshUI()
            ChangeState(self, self.IdleState)
        end,
    },
}

TypeClass = UES0401
