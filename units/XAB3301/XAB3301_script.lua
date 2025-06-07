--****************************************************************************
--**
--**  File     :  /data/units/XAB3301/XAB3301_script.lua
--**  Author(s):  Jessica St. Croix, Ted Snook, Dru Staltman
--**
--**  Summary  :  Aeon Quantum Optics Facility Script
--**
--**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local AStructureUnit = import("/lua/aeonunits.lua").AStructureUnit

local AQuantumGateAmbient = import("/lua/effecttemplates.lua").AQuantumGateAmbient

-- Setup as RemoteViewing child of AStructureUnit
local RemoteViewing = import("/lua/remoteviewing.lua").RemoteViewing
---@diagnostic disable-next-line: cast-local-type
AStructureUnit = RemoteViewing(AStructureUnit)

---@class XAB3301: AStructureUnit, RemoteViewingUnit
---@field Animator moho.AnimationManipulator
---@field RotatorBot moho.RotateManipulator
---@field RotatorTop moho.RotateManipulator
---@field RotatorOrbX moho.RotateManipulator
---@field RotatorOrbY moho.RotateManipulator
---@field RotatorOrbZ moho.RotateManipulator
---@field TrashAmbientEffects TrashBag
---@field ScryEnabled boolean
XAB3301 = ClassUnit(AStructureUnit) {
    ---@param self XAB3301
    OnCreate = function(self)
        AStructureUnit.OnCreate(self)

        local animator = self.Trash:Add(CreateAnimator(self))
        animator:PlayAnim("/units/xab3301/XAB3301_activate.sca"):SetRate(0):Disable()
        self.Animator = animator

        local rotatorOrbX = self.Trash:Add(CreateRotator(self, 'spin02', 'x', nil, 0, 15, 60 + Random(0, 20)))
        local rotatorOrbY = self.Trash:Add(CreateRotator(self, 'spin02', 'y', nil, 0, 15, 60 + Random(0, 20)))
        local rotatorOrbZ = self.Trash:Add(CreateRotator(self, 'spin02', 'z', nil, 0, 15, 60 + Random(0, 20)))
        rotatorOrbX:Disable()
        rotatorOrbY:Disable()
        rotatorOrbZ:Disable()
        self.RotatorOrbX = rotatorOrbX
        self.RotatorOrbY = rotatorOrbY
        self.RotatorOrbZ = rotatorOrbZ

        local rotatorBot = CreateRotator(self, 'spin01', 'y', nil, 0, 3, 6)
        local rotatorTop = CreateRotator(self, 'spin03', 'y', nil, 0, -2, -4)
        rotatorBot:Disable()
        rotatorTop:Disable()
        self.RotatorBot = rotatorBot
        self.RotatorTop = rotatorTop

        self.TrashAmbientEffects = TrashBag()
    end,

    ---@param self XAB3301
    ---@param builder Unit
    ---@param layer Layer
    OnStopBeingBuilt = function(self, builder, layer)
        AStructureUnit.OnStopBeingBuilt(self, builder, layer)

        self.Animator:Enable()
        self.RotatorOrbX:Enable()
        self.RotatorOrbY:Enable()
        self.RotatorOrbZ:Enable()
        self.RotatorBot:Enable()
        self.RotatorTop:Enable()
    end,

    ---@param self XAB3301
    CreateVisibleEntity = function(self)
        AStructureUnit.CreateVisibleEntity(self)

        if self.RemoteViewingData.VisibleLocation and self.RemoteViewingData.DisableCounter == 0 and self.RemoteViewingData.IntelButton then

            if self.ScryEnabled then
                CreateLightParticle(self, "spin02", self.Army, 1, 20, 'glow_02', 'ramp_blue_16')
            else
                CreateLightParticle(self, "spin02", self.Army, 10, 20, 'glow_02', 'ramp_blue_22')
            end

            if not self.ScryEnabled then
                self.ScryEnabled = true

                self.Animator:SetRate(1)
                self.RotatorBot:SetTargetSpeed(12)
                self.RotatorTop:SetTargetSpeed(-8)

                for k, v in AQuantumGateAmbient do
                    self.TrashAmbientEffects:Add(CreateAttachedEmitter(self, 'spin02', self.Army, v):ScaleEmitter(0.6))
                end
            end
        end

    end,

    ---@param self XAB3301
    DisableVisibleEntity = function(self)
        AStructureUnit.DisableVisibleEntity(self)

        self.Animator:SetRate(-1)
        self.RotatorBot:SetTargetSpeed(6)
        self.RotatorTop:SetTargetSpeed(-4)

        self.TrashAmbientEffects:Destroy()
        self.ScryEnabled = false
    end,
}

TypeClass = XAB3301
