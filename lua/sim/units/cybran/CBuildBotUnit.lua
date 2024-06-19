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

local DummyUnit = import('/lua/sim/unit.lua').DummyUnit
local DummyUnitOnCreate = DummyUnit.OnCreate

local UnitSetConsumptionActive = DummyUnit.SetConsumptionActive

-- pre-import for performance
local ExplosionSmallAir = import("/lua/effecttemplates.lua").ExplosionSmallAir

-- upvalue scope for performance
local TrashBag = TrashBag
local TrashBagDestroy = TrashBag.Destroy

local IssueToUnitStop = IssueToUnitStop
local CreateLightParticle = CreateLightParticle
local CreateEmitterAtEntity = CreateEmitterAtEntity

--- The build bot class for drones. It removes a lot of the basic functionality of a unit to save on performance.
---@class CBuildBotUnit : DummyUnit
---@field Trash TrashBag
CBuildBotUnit = ClassDummyUnit(DummyUnit) {

    -- Keep track of the builder that made the bot
    SpawnedBy = false,

    ---@param self CBuildBotUnit
    OnPreCreate = function(self)
        self.Trash = TrashBag()
    end,

    ---@param self CBuildBotUnit
    OnCreate = function(self)
        DummyUnit.OnCreate(self)

        -- prevent drone from consuming anything
        UnitSetConsumptionActive(self, false)
    end,

    ---@param self CBuildBotUnit
    OnDestroy = function(self)
        TrashBagDestroy(self.Trash)

        local spawnedBy = self.SpawnedBy
        if spawnedBy then
            spawnedBy.BuildBotsNext = spawnedBy.BuildBotsNext - 1
        end
    end,

    ---@param self CBuildBotUnit
    Kill = function(self)
        local army = self.Army

        -- create a small flash
        CreateLightParticle(
            self,
            -1,
            army,
            1,
            8,
            'glow_03',
            'ramp_flare_02'
        )

        -- create small air explosion
        for _, effect in ExplosionSmallAir do
            CreateEmitterAtEntity(self, army, effect)
        end

        -- create a bit of debris
        local vx, vy, vz = self:GetVelocity()
        self:CreateProjectile(
            '/effects/entities/DebrisMisc04/DebrisMisc04_proj.bp',
            0, 0, 0,
            vx, vy, vz
        )

        self:PlayUnitSound('Destroyed')

        -- flatout destroy the drone
        self:Destroy()
    end,

    ---@param self CBuildBotUnit
    ---@param target Unit unused
    OnStartCapture = function(self, target)
        -- Do not allow this unit to assist in a capture order
        IssueToUnitStop(self)
    end,

    ---@param self CBuildBotUnit
    ---@param target Unit unused
    OnStartReclaim = function(self, target)
        -- Do not allow this unit to assist in a reclaim order
        IssueToUnitStop(self)
    end,

    --- short cut - just get destroyed
    ---@param self CBuildBotUnit
    ---@param with any unused
    OnImpact = function(self, with)
        -- make it sound boom
        self:PlayUnitSound('Destroyed')

        -- make it gone
        self:Destroy()
    end,
}
