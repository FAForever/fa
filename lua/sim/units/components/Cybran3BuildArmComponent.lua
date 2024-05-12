--**********************************************************************************
--** Copyright (c) 2023 FAForever
--**
--** Permission is hereby granted, free of charge, to any person obtaining a copy
--** of this software and associated documentation files (the "Software"), to deal
--** in the Software without restriction, including without limitation the rights
--** to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
--** copies of the Software, and to permit persons to whom the Software is
--** furnished to do so, subject to the following conditions:
--**
--** The above copyright notice and this permission notice shall be included in all
--** copies or substantial portions of the Software.
--**
--** THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
--** IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
--** FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
--** AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
--** LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
--** OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
--** SOFTWARE.
--**********************************************************************************

local Entity = import("/lua/sim/entity.lua").Entity

local BeamBuildEmtBp = '/effects/emitters/build_beam_02_emit.bp'
local CybranBuildSparks01 = import("/lua/effecttemplates.lua").CybranBuildSparks01
local CybranBuildFlash01 = import("/lua/effecttemplates.lua").CybranBuildFlash01

-- upvalue scope for performance
local Warp = Warp
local Random = Random
local WaitFor = WaitFor
local WaitTicks = WaitTicks
local CreateSlider = CreateSlider
local AttachBeamEntityToEntity = AttachBeamEntityToEntity
local CreateEmitterOnEntity = CreateEmitterOnEntity

local TrashBagAdd = TrashBag.Add

local SliderSetGoal = moho.SlideManipulator.SetGoal
local SliderSetSpeed = moho.SlideManipulator.SetSpeed

---@class Cybran3BuildArmComponent
---@field ArmSlider1 moho.SlideManipulator
---@field ArmSlider3 moho.SlideManipulator
---@field ArmSlider2 moho.SlideManipulator
---@field ArmBeamEnd1 Entity
---@field ArmBeamEnd2 Entity
---@field ArmBeamEnd3 Entity
Cybran3BuildArmComponent = ClassSimple {

    ArmBone1 = false,
    ArmOffset1 = 0,

    ArmBone2 = false,
    ArmOffset2 = 0,

    ArmBone3 = false,
    ArmOffset3 = 0,

    ---@param self Cybran3BuildArmComponent | FactoryUnit
    OnCreate = function(self)
        local trash = self.Trash

        self.ArmSlider1 = TrashBagAdd(trash, CreateSlider(self, self.ArmBone1, 0, 0, 0, 0, true))
        self.ArmSlider2 = TrashBagAdd(trash, CreateSlider(self, self.ArmBone2, 0, 0, 0, 0, true))
        self.ArmSlider3 = TrashBagAdd(trash, CreateSlider(self, self.ArmBone3, 0, 0, 0, 0, true))

        local entitySpecs = { Owner = self }
        self.ArmBeamEnd1 = TrashBagAdd(trash, Entity(entitySpecs))
        self.ArmBeamEnd2 = TrashBagAdd(trash, Entity(entitySpecs))
        self.ArmBeamEnd3 = TrashBagAdd(trash, Entity(entitySpecs))
    end,

    ---@param self Cybran3BuildArmComponent | FactoryUnit
    MovingArmsThread = function(self)
        -- local scope for performance
        local armSlider1 = self.ArmSlider1
        local armOffset1 = self.ArmOffset1
        local armSlider2 = self.ArmSlider2
        local armOffset2 = self.ArmOffset2
        local armSlider3 = self.ArmSlider3
        local armOffset3 = self.ArmOffset3

        -- determine slide distance based on what we're building
        local unitBeingBuiltBlueprint = self.UnitBeingBuilt.Blueprint
        local slideDistance = 0.20 * (unitBeingBuiltBlueprint.Physics.MeshExtentsZ or unitBeingBuiltBlueprint.SizeZ or 6
            )
        if slideDistance < 0.6 then
            slideDistance = 0.6
        elseif slideDistance > 2 then
            slideDistance = 2
        end

        -- define speed of slider based on the distance that we cover
        SliderSetSpeed(armSlider1, 1)
        SliderSetSpeed(armSlider2, 1)
        SliderSetSpeed(armSlider3, 1)

        armOffset1 = armOffset1 - slideDistance
        armOffset2 = armOffset2
        armOffset3 = armOffset3 + slideDistance

        SliderSetGoal(armSlider2, armOffset2, 0, 0)

        while true do
            -- the factor 0.5 is to stay away from the build arm in the center
            SliderSetGoal(armSlider1, armOffset1 - slideDistance + 0.5, 0, 0)
            SliderSetGoal(armSlider3, armOffset3 + slideDistance - 0.5, 0, 0)
            WaitFor(armSlider3)
            SliderSetGoal(armSlider1, armOffset1 + slideDistance - 0.5, 0, 0)
            SliderSetGoal(armSlider3, armOffset3 - slideDistance + 0.5, 0, 0)
            WaitFor(armSlider3)

            -- make sure we always wait or the sim may get stuck
            WaitTicks(1)
        end
    end,

    ---@param self Cybran3BuildArmComponent | FactoryUnit
    StopArmsMoving = function(self)
        -- local scope for performance
        local armSlider1 = self.ArmSlider1
        local armSlider2 = self.ArmSlider2
        local armSlider3 = self.ArmSlider3

        SliderSetGoal(armSlider1, 0, 0, 0)
        SliderSetGoal(armSlider2, 0, 0, 0)
        SliderSetGoal(armSlider3, 0, 0, 0)
    end,

    ---@param self Cybran3BuildArmComponent | FactoryUnit
    ---@param unitBeingBuilt FactoryUnit
    ---@param order string
    CreateBuildEffects = function(self, unitBeingBuilt, order)
        -- delay slightly so that the unit is orientated properly
        WaitTicks(2)

        -- local scope for performance
        local army = self.Army
        local buildEffectsBag = self.BuildEffectsBag
        local armBeamEnd1 = self.ArmBeamEnd1
        local armBeamEnd2 = self.ArmBeamEnd2
        local armBeamEnd3 = self.ArmBeamEnd3

        local armBone1 = self.ArmBone1
        local armBone2 = self.ArmBone2
        local armBone3 = self.ArmBone3

        -- create the beams
        local buildEffectBones = self.BuildEffectBones
        TrashBagAdd(buildEffectsBag,
            AttachBeamEntityToEntity(self, buildEffectBones[1], armBeamEnd3, -1, army, BeamBuildEmtBp))
        TrashBagAdd(buildEffectsBag,
            AttachBeamEntityToEntity(self, buildEffectBones[2], armBeamEnd2, -1, army, BeamBuildEmtBp))
        TrashBagAdd(buildEffectsBag,
            AttachBeamEntityToEntity(self, buildEffectBones[3], armBeamEnd1, -1, army, BeamBuildEmtBp))

        -- create the sparks/flashes
        TrashBagAdd(buildEffectsBag, CreateEmitterOnEntity(armBeamEnd1, army, CybranBuildSparks01))
        TrashBagAdd(buildEffectsBag, CreateEmitterOnEntity(armBeamEnd1, army, CybranBuildFlash01))
        TrashBagAdd(buildEffectsBag, CreateEmitterOnEntity(armBeamEnd2, army, CybranBuildSparks01))
        TrashBagAdd(buildEffectsBag, CreateEmitterOnEntity(armBeamEnd2, army, CybranBuildFlash01))
        TrashBagAdd(buildEffectsBag, CreateEmitterOnEntity(armBeamEnd3, army, CybranBuildSparks01))
        TrashBagAdd(buildEffectsBag, CreateEmitterOnEntity(armBeamEnd3, army, CybranBuildFlash01))

        -- determine build area
        local unitBeingBuiltBlueprint = self.UnitBeingBuilt.Blueprint
        local sx = (unitBeingBuiltBlueprint.Physics.MeshExtentsX or unitBeingBuiltBlueprint.SizeX or 1)
        local sy = (unitBeingBuiltBlueprint.Physics.MeshExtentsY or unitBeingBuiltBlueprint.SizeY or 1)
        local sz = (unitBeingBuiltBlueprint.Physics.MeshExtentsZ or unitBeingBuiltBlueprint.SizeZ or 1)
        local sxp = 0.5 * sx
        local syp = sy
        local szp = 0.25
        local r1, r2, r3, az, pz
        local position = { 0, 0, 0 }
        local ux, uy, uz = unitBeingBuilt:GetPositionXYZ()

        -- local scope for performance
        local Warp = Warp
        local Random = Random
        local WaitTicks = WaitTicks
        local GetPositionXYZ = self.GetPositionXYZ

        while not self.Dead do

            -- get a few random numbers
            r1, r2, r3 = 0.5 - Random(), 0.5 - Random(), 0.5 - Random()

            -- warp the welding point around. We make sure that the z coordinate is
            -- always in the mesh/collision box of the unit that we're building

            _, _, az = GetPositionXYZ(self, armBone1)
            position[1] = ux + r1 * sxp
            position[2] = uy + (0.5 + r2) * syp
            pz = az + r3 * szp
            if pz > uz + 0.5 * sz then
                pz = uz + 0.3 * sz
            elseif pz < uz - 0.5 * sz then
                pz = uz - 0.3 * sz
            end
            position[3] = pz
            Warp(armBeamEnd1, position)

            _, _, az = GetPositionXYZ(self, armBone2)
            position[1] = ux + r2 * sxp
            position[2] = uy + (0.5 + r3) * syp
            pz = az + r1 * szp
            if pz > uz + 0.5 * sz then
                pz = uz + 0.3 * sz
            elseif pz < uz - 0.5 * sz then
                pz = uz - 0.3 * sz
            end
            position[3] = pz
            Warp(armBeamEnd2, position)

            _, _, az = GetPositionXYZ(self, armBone3)
            position[1] = ux + r3 * sxp
            position[2] = uy + (0.5 + r1) * syp
            pz = az + r2 * szp
            if pz > uz + 0.3 * sz then
                pz = uz + 0.3 * sz
            elseif pz < uz - 0.3 * sz then
                pz = uz - 0.3 * sz
            end
            position[3] = pz
            Warp(armBeamEnd3, position)

            WaitTicks(3)
        end
    end,
}
