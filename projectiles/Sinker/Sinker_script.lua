local EffectTemplate = import('/lua/EffectTemplates.lua')
local EffectUtil = import('/lua/EffectUtilities.lua')
local explosion = import('/lua/defaultexplosions.lua')
local GetRandomFloat = import('/lua/utilities.lua').GetRandomFloat
local Projectile = import('/lua/sim/projectile.lua').Projectile

Sinker = Class(Projectile) {
    OnCreate = function(self, inWater)
        Projectile.OnCreate(self)

        self:SetVizToFocusPlayer('Never')
        self:SetVizToAllies('Never')
        self:SetVizToNeutrals('Never')
        self:SetStayUpright(false)
    end,

    PassData = function(self, data)
        if not self.Data then
            if not data.TargetBone or not data.TargetEntity then
                return
            end

            self.Data = data
            self:Sink_Effects()
            return true
        end

        return false
    end,

    Sink_Effects = function(self)
        local target = self.Data.TargetEntity

        if not target:IsDead() or target:BeenDestroyed() then
            self:Destroy()
            return
        end

        if not target:IsValidBone(self.Data.TargetBone) then
            target:Destroy()
            self:Destroy()
            return
        end

        Warp( self, target:CalculateWorldPositionFromRelative({0, 0, 0}) , target:GetOrientation() )
        target:AttachBoneTo(self.Data.TargetBone, self, 'anchor')
    end,

    Start = function( self, delay)
        if delay and delay > 0 then
            self:ForkThread( function(self, delay) WaitTicks( delay) if self then self:StartSinking() end end, delay)
        else
            self:StartSinking()
        end
    end,

    StartSinking = function( self)
        if self and not self:BeenDestroyed() and self.Data.TargetEntity and not self.Data.TargetEntity:BeenDestroyed() then
            local bp = self:GetBlueprint()
            local acc = -bp.Physics.SinkSpeed or -0.05
            self:SetBallisticAcceleration( acc + GetRandomFloat(-0.02, 0.02) )
        end
    end,

    OnImpact = function(self, targetType, targetEntity)
        if targetType == 'Terrain' then
            self.Data.ImpactedWith = 'Seabed'
            self.Data.TargetEntity.StopSink = true
            self:Destroy()
        end
    end,
}
TypeClass = Sinker