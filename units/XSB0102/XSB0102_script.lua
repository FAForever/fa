--****************************************************************************
--**
--**  File     :  /units/XSB0102/XSB0102_script.lua
--**
--**  Summary  :  Seraphim T1 Air FactoryScript
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
local SAirFactoryUnit = import("/lua/seraphimunits.lua").SAirFactoryUnit

local EffectTemplate = import("/lua/effecttemplates.lua")
local SeraphimBuildBeams01 = EffectTemplate.SeraphimBuildBeams01

local BuildEffectBaseEmitters = {
    '/effects/emitters/seraphim_being_built_ambient_01_emit.bp',
}

local BuildEffectsEmitters = {
    '/effects/emitters/seraphim_being_built_ambient_02_emit.bp',
    '/effects/emitters/seraphim_being_built_ambient_03_emit.bp',
    '/effects/emitters/seraphim_being_built_ambient_04_emit.bp',
    '/effects/emitters/seraphim_being_built_ambient_05_emit.bp',
}

---@class XSB0102 : SAirFactoryUnit
XSB0102 = ClassUnit(SAirFactoryUnit) {

    RollOffBones = { 'Pod01',},

    AimBones = { 'Arm04' },
    MuzzleBones = { 'Muzzle04'},

    StartBuildFx = function(self, unitBeingBuilt)
        SAirFactoryUnit.StartBuildFx(self, unitBeingBuilt)

        local bag = self.BuildEffectsBag
        local army = self.Army

        local CreateAttachedEmitter = CreateAttachedEmitter
        for _, bone in self.MuzzleBones do
            bag:Add(CreateAttachedEmitter(self, bone, army, '/effects/emitters/seraphim_build_01_emit.bp'))
            for _, effect in SeraphimBuildBeams01 do
                bag:Add(AttachBeamEntityToEntity(self, bone, unitBeingBuilt, -1, army, effect))
            end
        end

        for _, bone in self.AimBones do
            local rotator = CreateRotator(self, bone, 'x')
            rotator:SetFollowBone('Attachpoint')
            rotator:SetAccel(25)
            rotator:SetTargetSpeed(25)
            rotator:SetSpeed(25)
            bag:Add(rotator)
        end

    end,

    OnCreate = function(self)
        SAirFactoryUnit.OnCreate(self)
        self.Rotator1 = CreateRotator(self, 'Pod01', 'y', nil, 5, 0, 0)
        self.Trash:Add(self.Rotator1)
    end,

    OnKilled = function(self, instigator, type, overkillRatio)
        self.Rotator1:SetSpeed(0)
        SAirFactoryUnit.OnKilled(self, instigator, type, overkillRatio)
    end,

}

TypeClass = XSB0102
