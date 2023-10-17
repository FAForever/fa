
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

local TIFMissileNuke = import("/lua/terranprojectiles.lua").TIFMissileNuke
local TacticalMissileComponent = import('/lua/sim/DefaultProjectiles.lua').TacticalMissileComponent

--- used by uel0001
---@class TIFMissileNukeCDR : TIFMissileNuke, TacticalMissileComponent
TIFMissileNukeCDR = ClassProjectile(TIFMissileNuke, TacticalMissileComponent) {
    BeamName = '/effects/emitters/missile_exhaust_fire_beam_06_emit.bp',
    InitialEffects = { '/effects/emitters/nuke_munition_launch_trail_02_emit.bp', },
    LaunchEffects = {
        '/effects/emitters/nuke_munition_launch_trail_03_emit.bp',
        '/effects/emitters/nuke_munition_launch_trail_05_emit.bp',
    },
    ThrustEffects = { '/effects/emitters/nuke_munition_launch_trail_04_emit.bp', },

    -- reduce due to distance
    LaunchTicks = 6,
    HeightDistanceFactor = 7,
    FinalBoostAngle = 30,

    MovementThread = TacticalMissileComponent.MovementThread,

    ---@param self TIFMissileNukeCDR
    OnCreate = function(self)
        TIFMissileNuke.OnCreate(self)
        self.MoveThread = self.Trash:Add(ForkThread(self.MovementThread, self))
        self.effectEntityPath = '/effects/Entities/UEFNukeEffectController02/UEFNukeEffectController02_proj.bp'
        self:LauncherCallbacks()

        self:CreateEffects(self.InitialEffects, self.Army, 1)
        self:CreateEffects(self.LaunchEffects, self.Army, 1)
        self:CreateEffects(self.ThrustEffects, self.Army, 1)
    end,

    OnEnterWater = function(self)
        TIFMissileNuke.OnEnterWater(self)
        self:SetDestroyOnWater(true)
    end,
}
TypeClass = TIFMissileNukeCDR
