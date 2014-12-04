-- A benign and untargetable unit that does nothing. Used during UEF teleport as an avatar

local MohoUnitMethods = moho.unit_methods

AvatarUnit = Class(MohoUnitMethods) {    
    OnCreate = function(self)
        self:SetImmobile(true)
        self:SetIsValidTarget(false)
        self:SetDoNotTarget(true)
        self:SetReclaimable(false)

        self:SetIntelRadius('Omni', 0)
        self:SetIntelRadius('Radar', 0)
        self:SetIntelRadius('Sonar', 0)
        self:SetIntelRadius('Vision', 0)
        self:SetIntelRadius('WaterVision', 0)

        self:DisableIntel('Omni')
        self:DisableIntel('Radar')
        self:DisableIntel('Sonar')
        self:DisableIntel('Vision')
        self:DisableIntel('WaterVision')

        self:SetVizToAllies('Intel')
        self:SetVizToEnemies('Intel')
        self:SetVizToFocusPlayer('Intel')
        self:SetVizToNeutrals('Intel')
    end,
}

TypeClass = AvatarUnit