-----------------------------------------------------------------
-- File     :  /cdimage/units/UAS0401/UAS0401_script.lua
-- Author(s):  John Comes
-- Summary  :  Aeon Experimental Sub
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

local ASubUnit = import("/lua/aeonunits.lua").ASubUnit
local ASeaUnit = import("/lua/aeonunits.lua").ASeaUnit
local WeaponsFile = import("/lua/aeonweapons.lua")
local ADFCannonOblivionWeapon = WeaponsFile.ADFCannonOblivionWeapon02
local AANChronoTorpedoWeapon = WeaponsFile.AANChronoTorpedoWeapon
local AIFQuasarAntiTorpedoWeapon = WeaponsFile.AIFQuasarAntiTorpedoWeapon

local AeonBuildBeams01 = import("/lua/effecttemplates.lua").AeonBuildBeams01
local AeonBuildBeams02 = import("/lua/effecttemplates.lua").AeonBuildBeams02

local CreateAeonTempestBuildingEffects = import("/lua/effectutilities.lua").CreateAeonTempestBuildingEffects

local ExternalFactoryComponent = import("/lua/defaultcomponents.lua").ExternalFactoryComponent

---@class UAS0401 : ASeaUnit, ExternalFactoryComponent
UAS0401 = ClassUnit(ASeaUnit, ExternalFactoryComponent) {
    BuildAttachBone = 'Attachpoint01',
    FactoryAttachBone = 'ExternalFactoryPoint',
    Weapons = {
        MainGun = ClassWeapon(ADFCannonOblivionWeapon) {},
        Torpedo01 = ClassWeapon(AANChronoTorpedoWeapon) {},
        Torpedo02 = ClassWeapon(AANChronoTorpedoWeapon) {},
        Torpedo03 = ClassWeapon(AANChronoTorpedoWeapon) {},
        Torpedo04 = ClassWeapon(AANChronoTorpedoWeapon) {},
        Torpedo05 = ClassWeapon(AANChronoTorpedoWeapon) {},
        Torpedo06 = ClassWeapon(AANChronoTorpedoWeapon) {},
        AntiTorpedo01 = ClassWeapon(AIFQuasarAntiTorpedoWeapon) {},
        AntiTorpedo02 = ClassWeapon(AIFQuasarAntiTorpedoWeapon) {},
    },

    StartBeingBuiltEffects = function(self, builder, layer)
        ASeaUnit.StartBeingBuiltEffects(self, builder, layer)
        CreateAeonTempestBuildingEffects(self)
    end,

    CreateBuildEffects = function(self, unitBeingBuilt, order)
        local army = self.Army
        local buildEffectsBag = self.BuildEffectsBag

        -- add build effect
        local sx = unitBeingBuilt.Blueprint.SizeX
        local sz = unitBeingBuilt.Blueprint.SizeX
        local emitter = CreateEmitterOnEntity(unitBeingBuilt, army, '/effects/emitters/aeon_being_built_ambient_02_emit.bp')
        emitter:SetEmitterCurveParam('X_POSITION_CURVE', 0, sx * 1.5)
        emitter:SetEmitterCurveParam('Z_POSITION_CURVE', 0, sz * 1.5)
        buildEffectsBag:Add(emitter)

        -- create beam builder -> target
        for _, effect in AeonBuildBeams01 do
            buildEffectsBag:Add(AttachBeamEntityToEntity(self, "Wake_Right", unitBeingBuilt, -1, army, effect))
            buildEffectsBag:Add(AttachBeamEntityToEntity(self, "Wake_Left", unitBeingBuilt, -1, army, effect))
        end
    end,

    OnStopBeingBuilt = function(self, builder, layer)
        self:SetWeaponEnabledByLabel('MainGun', true)
        ASeaUnit.OnStopBeingBuilt(self, builder, layer)
        ExternalFactoryComponent.OnStopBeingBuilt(self, builder, layer)

        if layer == 'Water' then
            self:RestoreBuildRestrictions()
            self:RequestRefreshUI()
        else
            self:AddBuildRestriction(categories.ALLUNITS)
            self:RequestRefreshUI()
        end

        ChangeState(self, self.IdleState)

        if not self.SinkSlider then -- Setup the slider and get blueprint values
            self.SinkSlider = CreateSlider(self, 0, 0, 0, 0, 5, true) -- Create sink controller to overlay ontop of original collision detection
            self.Trash:Add(self.SinkSlider)
        end

        self.WatchDepth = false
    end,

    OnFailedToBuild = function(self)
        ASeaUnit.OnFailedToBuild(self)
        ChangeState(self, self.IdleState)
    end,

    OnMotionVertEventChange = function(self, new, old)
        ASeaUnit.OnMotionVertEventChange(self, new, old)
        if new == 'Top' then
            self:RestoreBuildRestrictions()
            self:RequestRefreshUI()
            self:SetWeaponEnabledByLabel('MainGun', true)
            self:PlayUnitSound('Open')

            self.ExternalFactory:RestoreBuildRestrictions()
            self.ExternalFactory:RequestRefreshUI()
        elseif new == 'Down' then
            self:SetWeaponEnabledByLabel('MainGun', false)
            self:AddBuildRestriction(categories.ALLUNITS)
            self:RequestRefreshUI()
            self:PlayUnitSound('Close')

            self.ExternalFactory:AddBuildRestriction(categories.ALLUNITS)
            self.ExternalFactory:RequestRefreshUI()
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

    ---@param self UAS0401
    ---@param new Layer
    ---@param old Layer
    OnLayerChange = function(self, new, old)
        ASeaUnit.OnLayerChange(self, new, old)
    end,

    OnPaused = function(self)
        ASeaUnit.OnPaused(self)
        ExternalFactoryComponent.OnPaused(self)
    end,

    OnUnpaused = function(self)
        ASeaUnit.OnUnpaused(self)
        ExternalFactoryComponent.OnUnpaused(self)
    end,

    RolloffBody = function(self)
    end,

    ---@param self ExternalFactoryUnit
    RollOffUnit = function(self)
    end,

    DiveDepthThread = function(self)
        -- Takes the given location, adjusts the Y value to the surface height on that location, with an offset
        local Yoffset = 1.2 -- The default (built in) offset appears to be 0.25 - if the place where thats set is found, that would be epic.
        -- 1.2 is for Tempest to clear the torpedo tubes from most cases of ground clipping, keeping overall height minimal.
        while self.WatchDepth == true do
            local pos = self:GetPosition()
            local seafloor = GetTerrainHeight(pos[1], pos[3]) + GetTerrainTypeOffset(pos[1], pos[3]) -- Target depth, in this case the seabed
            local difference = math.max(((seafloor + Yoffset) - pos[2]), -0.5) -- Doesnt sink too much, just maneuveres the bed better.
            self.SinkSlider:SetSpeed(1)

            self.SinkSlider:SetGoal(0, difference, 0)
            WaitSeconds(0.2)
        end

        self.SinkSlider:SetGoal(0, 0, 0) -- Reset the slider while we are not watching depth
        WaitFor(self.SinkSlider)-- We have to wait for it to finish before killing the thread or it stops

        KillThread(self.DiverThread)
    end,

    IdleState = State {
        Main = function(self)
            self:DetachAll(self.BuildAttachBone)
            self:SetBusy(false)
            self:OnIdle()
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
            local bone = self.BuildAttachBone
            self:DetachAll(bone)
            if not self.UnitBeingBuilt.Dead then
                unitBuilding:AttachBoneTo(-2, self, bone)
                if EntityCategoryContains(categories.ENGINEER + categories.uas0102 + categories.uas0103, unitBuilding) then
                    unitBuilding:SetParentOffset({0, 0, 1})
                elseif EntityCategoryContains(categories.TECH2 - categories.ENGINEER, unitBuilding) then
                    unitBuilding:SetParentOffset({0, 0, 3})
                elseif EntityCategoryContains(categories.uas0203, unitBuilding) then
                    unitBuilding:SetParentOffset({0, 0, 1.5})
                else
                    unitBuilding:SetParentOffset({0, 0, 2.5})
                end
            end
            self.UnitDoneBeingBuilt = false
        end,

        ---@param self UAS0401
        ---@param unitBeingBuilt Unit
        OnStopBuild = function(self, unitBeingBuilt)
            ASeaUnit.OnStopBuild(self, unitBeingBuilt)

            local blueprint = unitBeingBuilt.Blueprint
            local distance = math.max(blueprint.SizeX, blueprint.SizeZ, 6)
            local worldPos = self:CalculateWorldPositionFromRelative({0, 0, - 2 * distance})
            IssueMoveOffFactoryToUnit(unitBeingBuilt, worldPos)
            ChangeState(self, self.RollingOffState)
        end,
    },

    RollingOffState = State {
        Main = function(self)
            local unitBuilding = self.UnitBeingBuilt
            unitBuilding:DetachFrom(true)
            self:DetachAll(self.BuildAttachBone)

            WaitTicks(21)

            ChangeState(self, self.IdleState)
        end,
    },

    OnKilled = function(self, instigator, type, overkillRatio)
        ExternalFactoryComponent.OnKilled(self, instigator, type, overkillRatio)
        local watchBone = self:GetBlueprint().WatchBone or 0

        self:ForkThread(function()
            local pos = self:GetPosition()
            local seafloor = GetTerrainHeight(pos[1], pos[3]) + GetTerrainTypeOffset(pos[1], pos[3]) - 1
            while self:GetPosition(watchBone)[2] > seafloor do
                WaitSeconds(0.1)
            end

            self:CreateWreckage(overkillRatio, instigator)
            self:Destroy()
        end)

        local layer = self.Layer
        self:DestroyIdleEffects()
        if layer == 'Water' or layer == 'Seabed' or layer == 'Sub' then
            self.SinkExplosionThread = self:ForkThread(self.ExplosionThread)
            self.SinkThread = self:ForkThread(self.SinkingThread)
        end

        ASeaUnit.OnKilled(self, instigator, type, overkillRatio)
    end
}

TypeClass = UAS0401
