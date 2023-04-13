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

---@class UES0401 : AircraftCarrier
UES0401 = ClassUnit(AircraftCarrier) {
    BuildAttachBone = 'UES0401',

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
    end,

    OnCreate = function(self)
        AircraftCarrier.OnCreate(self)
        local openAnim = self.OpenAnimManips

        openAnim = {}
        openAnim[1] = CreateAnimator(self):PlayAnim('/units/ues0401/ues0401_aopen.sca'):SetRate(-1)
        for i = 2, 6 do
            openAnim[i] = CreateAnimator(self):PlayAnim('/units/ues0401/ues0401_aopen0' .. i .. '.sca'):
                SetRate(-1)
        end

        for k, v in openAnim do
            self.Trash:Add(v)
        end

        if self.Layer == 'Water' then
            self:PlayAllOpenAnims(true)
        end
    end,

    StartBeingBuiltEffects = function(self, builder, layer)
        self:SetMesh(self.Blueprint.Display.BuildMeshBlueprint, true)
        if self.Blueprint.General.UpgradesFrom ~= builder.UnitId then
            self:HideBone(0, true)
            self.OnBeingBuiltEffectsBag:Add(self.Trash:Add(ForkThread(CreateBuildCubeThread, builder, self.OnBeingBuiltEffectsBag,self)))
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

        if new == 'Up' and old == 'Bottom' then
            self.WatchDepth = false
        end

        if new == 'Bottom' and old == 'Down' then
            self.WatchDepth = true
            if not self.DiverThread then
                self.DiverThread = self.Trash:Add(ForkThread(self.DiveDepthThread,self))
            end
        end
    end,

    DiveDepthThread = function(self)
        local Yoffset = 1.2
        while self.WatchDepth == true do
            local pos = self:GetPosition()
            local seafloor = GetTerrainHeight(pos[1], pos[3]) + GetTerrainTypeOffset(pos[1], pos[3])
            local difference = math.max(((seafloor + Yoffset) - pos[2]), -0.5)
            self.SinkSlider:SetSpeed(1)
            self.SinkSlider:SetGoal(0, difference, 0)
            WaitTicks(11)
        end
        self.SinkSlider:SetGoal(0, 0, 0)
        WaitFor(self.SinkSlider)
        KillThread(self.DiverThread)
    end,

    OnStopBeingBuilt = function(self, builder, layer)
        AircraftCarrier.OnStopBeingBuilt(self, builder, layer)
        ChangeState(self, self.IdleState)
        if not self.SinkSlider then
            self.SinkSlider = CreateSlider(self, 0, 0, 0, 0, 5, true)
            self.Trash:Add(self.SinkSlider)
        end
        self.WatchDepth = false
    end,

    OnFailedToBuild = function(self)
        AircraftCarrier.OnFailedToBuild(self)
        ChangeState(self, self.IdleState)
    end,

    IdleState = State {
        Main = function(self)
            self:DetachAll(self.BuildAttachBone)
            self:SetBusy(false)
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
                local worldPos = self:CalculateWorldPositionFromRelative({ 0, 0, -20 })
                IssueMoveOffFactory({ unitBuilding }, worldPos)
                unitBuilding:ShowBone(0, true)
            end

            self:RequestRefreshUI()
            ChangeState(self, self.IdleState)
        end,
    },
}

TypeClass = UES0401
