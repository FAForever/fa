--******************************************************************************************************
--** Copyright (c) 2022  Willem 'Jip' Wijnia
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
--******************************************************************************************************

local TIFTacticalNuke = import("/lua/terranprojectiles.lua").TIFTacticalNuke
local EffectTemplate = import("/lua/effecttemplates.lua")

local VisionMarkerOpti = import("/lua/sim/vizmarker.lua").VisionMarkerOpti

-- upvalue scope for performance
local WaitTicks = WaitTicks
local ForkThread = ForkThread
local DamageArea = DamageArea

--- used by uel0001
---@class TIFMissileNukeCDR : TIFTacticalNuke
---@field Armed boolean
TIFMissileNukeCDR = ClassProjectile(TIFTacticalNuke) {
    -- BeamName = '/effects/emitters/missile_exhaust_fire_beam_01_emit.bp',
    BeamName = '/effects/emitters/missile_exhaust_fire_beam_06_emit.bp',
    InitialEffects = { '/effects/emitters/nuke_munition_launch_trail_02_emit.bp', },
    ThrustEffects = { '/effects/emitters/nuke_munition_launch_trail_04_emit.bp', },
    LaunchEffects = {
        '/effects/emitters/nuke_munition_launch_trail_03_emit.bp',
        '/effects/emitters/nuke_munition_launch_trail_05_emit.bp',
    },

    DebrisBlueprints = {
        '/effects/Entities/TacticalDebris02/TacticalDebris02_proj.bp',
    },

    -- reduce due to distance
    LaunchTicks = 6,
    HeightDistanceFactor = 7,
    FinalBoostAngle = 30,

    ---@param self TIFMissileNukeCDR
    ---@param inWater boolean
    OnCreate = function(self, inWater)
        TIFMissileNuke.OnCreate(self)
        if not inWater then
            self:SetDestroyOnWater(true)
        end
    
        self.MoveThread = self.Trash:Add(ForkThread(self.MovementThread, self))
        self.effectEntityPath = '/effects/Entities/UEFNukeEffectController02/UEFNukeEffectController02_proj.bp'
        self:LauncherCallbacks()
        self.Armed = false

        local army = self.Army
        local trash = self.Trash
        for _, effect in self.InitialEffects do
            trash:Add(CreateAttachedEmitter(self, -1, army, effect))
        end

        local launchEffects = {}
        for _, effect in self.ThrustEffects do
            table.insert(launchEffects, trash:Add(CreateAttachedEmitter(self, -1, army, effect)))
        end

        for _, effect in self.LaunchEffects do
            table.insert(launchEffects, trash:Add(CreateAttachedEmitter(self, -1, army, effect)))
        end

        trash:Add(ForkThread(self.ArmMissileThread, self, launchEffects))
    end,

    ---@param self TIFMissileNukeCDR
    OnExitWater = function(self)
        TIFMissileNuke.OnExitWater(self)
        self:SetDestroyOnWater(true)
    end,

    ---@param self TIFMissileNukeCDR
    ---@param launchEffects moho.IEffect[]
    ArmMissileThread = function(self, launchEffects)
        WaitTicks(7)
        for k, effect in ipairs(launchEffects) do
            effect:ScaleEmitter(0.9)
        end

        WaitTicks(7)
        for k, effect in ipairs(launchEffects) do
            effect:ScaleEmitter(0.7)
        end

        WaitTicks(7)
        for k, effect in ipairs(launchEffects) do
            effect:ScaleEmitter(0.5)
        end

        WaitTicks(7)
        for k, effect in ipairs(launchEffects) do
            effect:ScaleEmitter(0.3)
        end

        -- indicates to the player(s) that the billy is now armed
        self:CreateDebris()

        self.Armed = true
    end,

    ---@param self TIFMissileNukeCDR
    ---@param targetType string
    ---@param targetEntity Prop|Unit
    OnImpact = function(self, targetType, targetEntity)
        local position = self:GetPosition()

        if self.Armed then
            -- create vision
            local marker = VisionMarkerOpti({ Owner = self })
            marker:UpdatePosition(position[1], position[3])
            marker:UpdateDuration(9)
            marker:UpdateIntel(self.Army, 12, 'Vision', true)

            if EntityCategoryContains(categories.AEON * categories.PROJECTILE * categories.ANTIMISSILE, targetEntity) then
                self:Destroy()
            else
                TIFTacticalNuke.OnImpact(self, targetType, targetEntity)
            end
        else
            -- default tactical explosion
            self:CreateDebris()
            self:Destroy()
        end
    end,

    --- Called by Lua to process the overriden damage logic of TIFMissileNukeCDR.
    -- Similar to nuke damage logic, except it does not bypass shields.
    -- @param self TIFMissileNukeCDR
    -- @param instigator The launcher, and if it doesn't exist, the projectile itself
    -- @param DamageData The damage data passed by the weapon
    -- @param targetEntity The entity we hit, is nil if we hit terrain
    -- @param cachedPosition A cached position that is passed to prevent table allocations, can not be used in fork threads and / or after a yield statement
    ---@param self TIFMissileNukeCDR
    ---@param instigator UEL0001 | TIFMissileNukeCDR
    ---@param DamageData table
    ---@param targetEntity Unit | Prop
    ---@param cachedPosition Vector
    DoDamage = function(self, instigator, DamageData, targetEntity, cachedPosition)
        local InnerRing = self.InnerRing
        local OuterRing = self.OuterRing
        DamageArea(instigator, cachedPosition, InnerRing.Radius, InnerRing.Damage, 'Normal', true, true)
        DamageArea(instigator, cachedPosition, OuterRing.Radius, OuterRing.Radius, 'Normal', true, true)
    end,
}
TypeClass = TIFMissileNukeCDR
