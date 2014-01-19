# a benign and untargetable unit that does nothing. Used during UEF teleport as an avatar

local MohoUnitMethods = moho.unit_methods

AvatarUnit = Class(MohoUnitMethods) {    
    OnCreate = function(self)
        self:SetImmobile(true)
        self:SetIsValidTarget(false)
        self:SetDoNotTarget(true)
        self:SetReclaimable(false)
    end,
}

TypeClass = AvatarUnit