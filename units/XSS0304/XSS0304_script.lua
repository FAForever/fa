--****************************************************************************
--**
--**  File     :  /data/units/xss0304/xss0304_script.lua
--**  Author(s):  Greg Kohne, Dru Staltman, Gordon DUclos
--**
--**  Summary  :  Seaphim Submarine Hunter Script
--**
--**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
local SSubUnit = import("/lua/seraphimunits.lua").SSubUnit
local SANUallCavitationTorpedo = import("/lua/seraphimweapons.lua").SANUallCavitationTorpedo
local SDFAjelluAntiTorpedoDefense = import("/lua/seraphimweapons.lua").SDFAjelluAntiTorpedoDefense
local SAALosaareAutoCannonWeapon = import("/lua/seraphimweapons.lua").SAALosaareAutoCannonWeaponSeaUnit

---@class XSS0304 : SSubUnit
XSS0304 = ClassUnit(SSubUnit) {
    DeathThreadDestructionWaitTime = 0,
    Weapons = {
        TorpedoFront = ClassWeapon(SANUallCavitationTorpedo) {},
        AntiTorpedoLeft = ClassWeapon(SDFAjelluAntiTorpedoDefense) {},
        AntiTorpedoRight = ClassWeapon(SDFAjelluAntiTorpedoDefense) {},
        AutoCannon = ClassWeapon(SAALosaareAutoCannonWeapon) {},
    },
    
    OnStopBeingBuilt = function(self,builder,layer)
        SSubUnit.OnStopBeingBuilt(self,builder,layer)
        if layer == 'Water' then
            ChangeState( self, self.OpenState )
        else
            ChangeState( self, self.ClosedState )
        end
    end,

    OnLayerChange = function( self, new, old )
        SSubUnit.OnLayerChange(self, new, old)
        if new == 'Water' then
            ChangeState( self, self.OpenState )
        elseif new == 'Sub' then
            ChangeState( self, self.ClosedState )
        end
    end,
    
    OpenState = State() {
        Main = function(self)
            if not self.CannonAnim then
                self.CannonAnim = CreateAnimator(self)
                self.Trash:Add(self.CannonAnim)
            end
            local bp = self:GetBlueprint()
            self.CannonAnim:PlayAnim(bp.Display.CannonOpenAnimation)
            self.CannonAnim:SetRate(bp.Display.CannonOpenRate or 1)
            WaitFor(self.CannonAnim)
            self:SetWeaponEnabledByLabel('AutoCannon', true)
        end,
    },
    
    ClosedState = State() {
        Main = function(self)
            self:SetWeaponEnabledByLabel('AutoCannon', false)
            if self.CannonAnim then
                local bp = self:GetBlueprint()
                self.CannonAnim:SetRate( -1 * ( bp.Display.CannonOpenRate or 1 ) )
                WaitFor(self.CannonAnim)
            end
        end,
    },
}
TypeClass = XSS0304