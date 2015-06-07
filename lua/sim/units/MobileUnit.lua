local Unit = import('/lua/sim/Unit.lua').Unit
local EffectUtil = import('/lua/EffectUtilities.lua')

MobileUnit = Class(Unit) {
    -- Added for engymod. After creating an enhancement, units must re-check their build restrictions
    CreateEnhancement = function(self, enh)
        Unit.CreateEnhancement(self, enh)
        self:updateBuildRestrictions()
    end,

    -- Added for engymod. When created, units must re-check their build restrictions
    OnCreate = function(self)
        Unit.OnCreate(self)
        self:updateBuildRestrictions()
    end,

    OnKilled = function(self, instigator, type, overkillRatio)
    --Add unit's threat to our influence map
        local threat = 5
        local decay = 0.1
        local currentLayer = self:GetCurrentLayer()
        if instigator then
            local unit = false
            if IsUnit(instigator) then
                unit = instigator
            elseif IsProjectile(instigator) or IsCollisionBeam(instigator) then
                unit = instigator.unit
            end

            if unit then
                local unitPos = unit:GetCachePosition()
                if EntityCategoryContains(categories.STRUCTURE, unit) then
                    decay = 0.01
                end

                if unitPos then
                    if currentLayer == 'Sub' then
                        threat = self:GetAIBrain():GetThreatAtPosition(unitPos, 0, true, 'AntiSub')
                    elseif currentLayer == 'Air' then
                        threat = self:GetAIBrain():GetThreatAtPosition(unitPos, 0, true, 'AntiAir')
                    else
                        threat = self:GetAIBrain():GetThreatAtPosition(unitPos, 0, true, 'AntiSurface')
                    end
                    threat = threat / 2
                end
            end
        end

        if currentLayer == 'Sub' then
            self:GetAIBrain():AssignThreatAtPosition(self:GetPosition(), threat, decay*10, 'AntiSub')
        elseif currentLayer == 'Air' then
            self:GetAIBrain():AssignThreatAtPosition(self:GetPosition(), threat, decay, 'AntiAir')
        elseif currentLayer == 'Water' then
            self:GetAIBrain():AssignThreatAtPosition(self:GetPosition(), threat, decay*10, 'AntiSurface')
        else
            self:GetAIBrain():AssignThreatAtPosition(self:GetPosition(), threat, decay, 'AntiSurface')
        end

        Unit.OnKilled(self, instigator, type, overkillRatio)
    end,

    OnPaused = function(self)
        self:SetBlockCommandQueue(true)
        Unit.OnPaused(self)
    end,

    OnUnpaused = function(self)
        self:SetBlockCommandQueue(false)
        Unit.OnUnpaused(self)
    end,

    StartBeingBuiltEffects = function(self, builder, layer)
        Unit.StartBeingBuiltEffects(self, builder, layer)
        local bp = self:GetBlueprint()
        local FactionName = bp.General.FactionName

        if FactionName == 'UEF' then
            EffectUtil.CreateUEFUnitBeingBuiltEffects(self, builder, self.OnBeingBuiltEffectsBag)
        end
    end,

    CreateReclaimEffects = function( self, target )
        EffectUtil.PlayReclaimEffects( self, target, self:GetBlueprint().General.BuildBones.BuildEffectBones or {0,}, self.ReclaimEffectsBag )
    end,

    CreateReclaimEndEffects = function( self, target )
        EffectUtil.PlayReclaimEndEffects( self, target )
    end,

    CreateCaptureEffects = function( self, target )
        EffectUtil.PlayCaptureEffects( self, target, self:GetBlueprint().General.BuildBones.BuildEffectBones or {0,}, self.CaptureEffectsBag )
    end,
}
