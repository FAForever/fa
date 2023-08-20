-----------------------------------------------------------------
-- File     :  /cdimage/units/UES0401/UES0401_script.lua
-- Author(s):  John Comes, David Tomandl
-- Summary  :  UEF Experimental Submersible Aircraft Carrier Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

local AircraftCarrier = import("/lua/defaultunits.lua").AircraftCarrier
local TANTorpedoAngler = import("/lua/terranweapons.lua").TANTorpedoAngler
local TSAMLauncher = import("/lua/terranweapons.lua").TSAMLauncher
local EffectUtil = import("/lua/effectutilities.lua")
local CreateBuildCubeThread = EffectUtil.CreateBuildCubeThread

local ExternalFactoryComponent = import("/lua/defaultcomponents.lua").ExternalFactoryComponent

---@class UES0401 : AircraftCarrier, ExternalFactoryComponent
UES0401 = ClassUnit(AircraftCarrier, ExternalFactoryComponent) {
    BuildAttachBone = 'Attachpoint08',
    FactoryAttachBone = 'ExternalFactoryPoint',
    Weapons = {
        Torpedo01 = ClassWeapon(TANTorpedoAngler) {},
        Torpedo02 = ClassWeapon(TANTorpedoAngler) {},
        Torpedo03 = ClassWeapon(TANTorpedoAngler) {},
        Torpedo04 = ClassWeapon(TANTorpedoAngler) {},
        MissileRack01 = ClassWeapon(TSAMLauncher) {},
        MissileRack02 = ClassWeapon(TSAMLauncher) {},
        MissileRack03 = ClassWeapon(TSAMLauncher) {},
        MissileRack04 = ClassWeapon(TSAMLauncher) {},
    },

    OnKilled = function(self, instigator, type, overkillRatio)
        AircraftCarrier.OnKilled(self, instigator, type, overkillRatio)
        ExternalFactoryComponent.OnKilled(self, instigator, type, overkillRatio)
    end,

    OnCreate = function(self)
        AircraftCarrier.OnCreate(self)
        self.OpenAnimManips = {}
        self.OpenAnimManips[1] = CreateAnimator(self):PlayAnim('/units/ues0401/ues0401_aopen.sca'):SetRate(-1)
        for i = 2, 3 do
            self.OpenAnimManips[i] = CreateAnimator(self):PlayAnim('/units/ues0401/ues0401_aopen0' .. i .. '.sca'):SetRate(-1)
        end

        for k, v in self.OpenAnimManips do
            self.Trash:Add(v)
        end

        if self.Layer == 'Water' then
            self:PlayAllOpenAnims(true)
        end
    end,

    OnPaused = function(self)
        AircraftCarrier.OnPaused(self)
        ExternalFactoryComponent.OnPaused(self)
    end,

    OnUnpaused = function(self)
        AircraftCarrier.OnUnpaused(self)
        ExternalFactoryComponent.OnUnpaused(self)
    end,

    StartBeingBuiltEffects = function(self, builder, layer)
        self:SetMesh(self:GetBlueprint().Display.BuildMeshBlueprint, true)
        if self:GetBlueprint().General.UpgradesFrom ~= builder.UnitId then
            self:HideBone(0, true)
            self.OnBeingBuiltEffectsBag:Add(self:ForkThread(CreateBuildCubeThread, builder, self.OnBeingBuiltEffectsBag))
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

    OnMotionVertEventChange = function(self, new, old)
        AircraftCarrier.OnMotionVertEventChange(self, new, old)

        if new == 'Down' then
            self:PlayAllOpenAnims(false)
        elseif new == 'Top' then
            self:PlayAllOpenAnims(true)
        end

        if new == 'Up' and old == 'Bottom' then -- When starting to surface
            self.WatchDepth = false
        end

        if new == 'Bottom' and old == 'Down' then -- When finished diving
            self.WatchDepth = true
            if not self.DiverThread then
                self.DiverThread = self:ForkThread(self.DiveDepthThread)
            end
        end
    end,

    DiveDepthThread = function(self)
        -- Takes the given location, adjusts the Y value to the surface height on that location, with an offset
        local Yoffset = 1.2 -- The default (built in) offset appears to be 0.25 - if the place where thats set is found, that would be epic.
        -- 1.2 is for tempest to clear the torpedo tubes from most cases of ground clipping, keeping overall height minimal.
        while self.WatchDepth == true do
            local pos = self:GetPosition()
            local seafloor = GetTerrainHeight(pos[1], pos[3]) + GetTerrainTypeOffset(pos[1], pos[3]) -- Target depth, in this case the seabed
            local difference = math.max(((seafloor + Yoffset) - pos[2]), -0.5) -- Doesnt sink too much, just maneuveres the bed better.
            self.SinkSlider:SetSpeed(1)

            self.SinkSlider:SetGoal(0, difference, 0)
            WaitSeconds(1)
        end

        self.SinkSlider:SetGoal(0, 0, 0) -- Reset the slider while we are not watching depth
        WaitFor(self.SinkSlider)-- We have to wait for it to finish before killing the thread or it stops

        KillThread(self.DiverThread)
    end,

    OnStopBeingBuilt = function(self,builder,layer)
        AircraftCarrier.OnStopBeingBuilt(self,builder,layer)
        ExternalFactoryComponent.OnStopBeingBuilt(self, builder, layer)
        ChangeState(self, self.IdleState)

        if not self.SinkSlider then -- Setup the slider and get blueprint values
            self.SinkSlider = CreateSlider(self, 0, 0, 0, 0, 5, true) -- Create sink controller to overlay ontop of original collision detection
            self.Trash:Add(self.SinkSlider)
        end

        self.WatchDepth = false
    end,

    OnFailedToBuild = function(self)
        AircraftCarrier.OnFailedToBuild(self)
        ChangeState(self, self.IdleState)
    end,

    ---@param self UEL0401
    ---@param new Layer
    ---@param old Layer
    OnLayerChange = function(self, new, old)
        AircraftCarrier.OnLayerChange(self, new, old)
    end,

    IdleState = State {
        Main = function(self)
            self:DetachAll(self.BuildAttachBone)
            self:SetBusy(false)
            self.OnIdle(self)
        end,

        OnStartBuild = function(self, unitBuilding, order)
            AircraftCarrier.OnStartBuild(self, unitBuilding, order)
            self.UnitBeingBuilt = unitBuilding
            ChangeState(self, self.BuildingState)
        end,
    },

    BuildingState = State {
        Main = function(self)
            local unitBuilding = self.UnitBeingBuilt
            local bone = self.BuildAttachBone
            self:DetachAll(bone)
            unitBuilding:AttachTo(self, bone)
            unitBuilding:HideBone(0, true)
            self.UnitDoneBeingBuilt = false
        end,

        OnStopBuild = function(self, unitBeingBuilt)
            AircraftCarrier.OnStopBuild(self, unitBeingBuilt)
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
