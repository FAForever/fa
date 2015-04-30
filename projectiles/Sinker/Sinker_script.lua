local EffectTemplate = import('/lua/EffectTemplates.lua')
local EffectUtil = import('/lua/EffectUtilities.lua')
local explosion = import('/lua/defaultexplosions.lua')
local GetRandomFloat = import('/lua/utilities.lua').GetRandomFloat
local Projectile = import('/lua/sim/projectile.lua').Projectile
local rand = import('/lua/utilities.lua').GetRandomFloat

Sinker = Class(Projectile) {
    OnCreate = function(self, inWater)
        Projectile.OnCreate(self)

        self:SetVizToFocusPlayer('Never')
        self:SetVizToAllies('Never')
        self:SetVizToNeutrals('Never')
        self:SetStayUpright(false)
        self:SetCollideSurface(true)
    end,

    Attach = function(self, unit)
        local mult
        local acc
        local v1, v2, v3 = unit:GetVelocity()
        local layer = unit:GetCurrentLayer()

        if layer == 'Water' then
            mult = 6
            acc = -0.05
        else
            mult = 10
            acc = -4.90
        end

        unit:AttachBoneTo(0, self, 'anchor')
        self:SetVelocity(v1 * mult * rand(0.80, 1.20), v2 * mult * rand(0.80, 1.20), v3 * mult * rand(0.80, 1.20))

        local lv = math.max(v1, v2, v3) * mult * 0.2
        self:SetLocalAngularVelocity(rand(-lv, lv), rand(-lv, lv), rand(-lv, lv))
        self:SetBallisticAcceleration(acc)

        self.unit = unit
    end,

    OnImpact = function(self, targetType, targetEntity)
        self.unit:OnImpact(targetType)
        self:Destroy()
    end,

    OnEnterWater = function(self)
        self.unit:OnImpact('Water')
        self:StayUnderwater(true)

        local v1, v2, v3 = self:GetVelocity()
        self:SetVelocity(6*v1, 6*v2, 6*v3)

        ForkThread(function()
            while self:GetCurrentSpeed() > 0.1 do
                WaitSeconds(0.1)
                v1, v2, v3 = self:GetVelocity()
                self:SetVelocity(7*v1, 7*v2, 7*v3)
            end

            self:SetLocalAngularVelocity(0.1, 0.1, 0.1)
            self:SetBallisticAcceleration(-0.05 + GetRandomFloat(-0.02, 0.02))
        end)
    end,

    OnDestroy = function(self)
        self.unit:DetachAll(0)
        self:DetachAll('anchor')
        self.unit.StopSink = true
        self.unit:SetImmobile(false)
    end,
}
TypeClass = Sinker
