-- File     :  /cdimage/units/UAB0203/UAB0203_script.lua
-- Author(s):  John Comes, David Tomandl
-- Summary  :  Aeon Unit Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------
local SSeaFactoryUnit = import("/lua/seraphimunits.lua").SSeaFactoryUnit
---@class XSB0203 : SSeaFactoryUnit
XSB0203 = ClassUnit(SSeaFactoryUnit) {
    OnCreate = function(self)
        SSeaFactoryUnit.OnCreate(self)
        self.Rotator1 = CreateRotator(self, 'Pod01', 'y', nil, 5, 0, 0)
        self.Trash:Add(self.Rotator1)
        self.Rotator2 = CreateRotator(self, 'Pod02', 'y', nil, 8, 0, 0)
        self.Trash:Add(self.Rotator2)
    end,

    OnKilled = function(self, instigator, type, overkillRatio)
        self.Rotator1:SetSpeed(0)
        self.Rotator2:SetSpeed(0)
        SSeaFactoryUnit.OnKilled(self, instigator, type, overkillRatio)
    end,
	
	PlayAnimationThread = function(self, anim, rate)
        local bp = self.Blueprint.Display[anim]
        if bp then
            local animBlock = self:ChooseAnimBlock(bp)

            -- for determining wreckage offset after dying with an animation
            if anim == 'AnimationDeath' then
                self.DeathHitBox = animBlock.HitBox
            end

            if animBlock.Mesh then
                self:SetMesh(animBlock.Mesh)
            end
            if animBlock.Animation and (self:ShallSink() or not EntityCategoryContains(categories.NAVAL * categories.MOBILE, self)) then
                local sinkAnim = CreateAnimator(self)
                self.DeathAnimManip = sinkAnim
                sinkAnim:PlayAnim(animBlock.Animation)
                rate = rate or 1
                if animBlock.AnimationRateMax and animBlock.AnimationRateMin then
                    rate = animBlock.AnimationRateMin + Random() * (animBlock.AnimationRateMax - animBlock.AnimationRateMin)
                end
                sinkAnim:SetRate(rate)
                self.Trash:Add(sinkAnim)
                WaitFor(sinkAnim)
                self.StopSink = true
            end
        end
    end,	
}

TypeClass = XSB0203