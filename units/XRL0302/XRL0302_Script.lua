local CBP_oldXRL0302 = XRL0302
XRL0302 = Class(CBP_oldXRL0302) {
    OnProductionPaused = function(self)
        local wep = self:GetWeapon(1)
        wep.OnFire(wep)
    end,
}
TypeClass = XRL0302