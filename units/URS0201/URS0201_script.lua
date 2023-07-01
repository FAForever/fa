-----------------------------------------------------------------
-- File     :  /cdimage/units/URS0201/URS0201_script.lua
-- Author(s):  David Tomandl, Jessica St. Croix
-- Summary  :  Cybran Destroyer Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------
local CWalkingLandUnit = import("/lua/cybranunits.lua").CWalkingLandUnit
local CSeaUnit = import("/lua/cybranunits.lua").CSeaUnit
local CybranWeapons = import("/lua/cybranweapons.lua")
local CAAAutocannon = CybranWeapons.CAAAutocannon
local CDFProtonCannonWeapon = CybranWeapons.CDFProtonCannonWeapon
local CANNaniteTorpedoWeapon = import("/lua/cybranweapons.lua").CANNaniteTorpedoWeapon
local CIFSmartCharge = import("/lua/cybranweapons.lua").CIFSmartCharge

---@class URS0201 : CSeaUnit
URS0201 = ClassUnit(CSeaUnit) {
    SwitchAnims = true,
    Walking = false,
    IsWaiting = false,

    Weapons = {
        ParticleGun = ClassWeapon(CDFProtonCannonWeapon) {},
        AAGun = ClassWeapon(CAAAutocannon) {},
        TorpedoR = ClassWeapon(CANNaniteTorpedoWeapon) {},
        TorpedoL = ClassWeapon(CANNaniteTorpedoWeapon) {},
        AntiTorpedoF = ClassWeapon(CIFSmartCharge) {},
        AntiTorpedoB = ClassWeapon(CIFSmartCharge) {},
    },

    OnMotionHorzEventChange = function(self, new, old)
        CSeaUnit.OnMotionHorzEventChange(self, new, old)
        if self.Dead then return end

        if not self.IsWaiting then
            if self.Walking then
                if old == 'Stopped' then
                    if self.SwitchAnims then
                        self.SwitchAnims = false
                        self.AnimManip:PlayAnim(self.Blueprint.Display.AnimationWalk, true):SetRate(self.Blueprint.Display
                            .AnimationWalkRate or 1.1)
                    else
                        self.AnimManip:SetRate(2.8)
                    end
                elseif new == 'Stopped' then
                    self.AnimManip:SetRate(0)
                end
            end
        end
    end,

    ShallSink = function(self)
        return true
    end,

    LayerChangeTrigger = function(self, new, old)
        local bp = self.Blueprint or self:GetBlueprint()
        if new == 'Land' then
            self:DisableUnitIntel('Layer', 'Sonar')
            self:SetSpeedMult(bp.Physics.LandSpeedMultiplier)
        elseif new == 'Water' then
            self:EnableUnitIntel('Layer', 'Sonar')
            self:SetSpeedMult(1)
        end

        if old ~= 'None' or new == 'Land' then
            if self.AT1 then
                self.AT1:Destroy()
            end
            self.AT1 = self.Trash:Add(ForkThread(self.TransformThread, self, new == 'Land'))
        end
    end,

    TransformThread = function(self, land)
        local bp = self.Blueprint
        local scale = bp.Display.UniformScale or 1
        local WaitFor = WaitFor

        local animManip = self.AnimManip
        if (not animManip) or IsDestroyed(animManip) then
            animManip = CreateAnimator(self)
            self.Trash:Add(animManip)
            self.AnimManip = animManip
        end

        if land then
            self:SetImmobile(true)
            animManip:PlayAnim(self.Blueprint.Display.AnimationTransform)
            animManip:SetRate(2)
            self.IsWaiting = true
            WaitFor(animManip)
            self:SetCollisionShape('Box', bp.CollisionOffsetX or 0, (bp.CollisionOffsetY + (bp.SizeY * 1.0)) or 0,
                bp.CollisionOffsetZ or 0, bp.SizeX * scale, bp.SizeY * scale, bp.SizeZ * scale)
            self.IsWaiting = false
            self:SetImmobile(false)
            self.SwitchAnims = true
            self.Walking = true
        else
            self:SetImmobile(true)
            animManip:PlayAnim(self.Blueprint.Display.AnimationTransform)
            animManip:SetAnimationFraction(1)
            animManip:SetRate(-2)
            self.IsWaiting = true
            WaitFor(animManip)
            self:SetCollisionShape('Box', bp.CollisionOffsetX or 0, (bp.CollisionOffsetY + (bp.SizeY * 0.5)) or 0,
                bp.CollisionOffsetZ or 0, bp.SizeX * scale, bp.SizeY * scale, bp.SizeZ * scale)
            self.IsWaiting = false
            animManip:Destroy()
            self.AnimManip = nil
            self:SetImmobile(false)
            self.Walking = false
        end
    end,

    OnKilled = function(self, instigator, type, overkillRatio)
        self.Trash:Destroy()
        self.Trash = TrashBag()
        if self.Layer ~= 'Water' and not self.IsWaiting then
            self.Blueprint.Display.AnimationDeath = self.Blueprint.Display.LandAnimationDeath
        else
            self.Blueprint.Display.AnimationDeath = self.Blueprint.Display.WaterAnimationDeath
        end

        CSeaUnit.OnKilled(self, instigator, type, overkillRatio)
    end,

    DeathThread = function(self, overkillRatio)
        if self.Layer ~= 'Water' and not self.IsWaiting then
            self:PlayUnitSound('Destroyed')
            if self.PlayDestructionEffects then
                self:CreateDestructionEffects(self, overkillRatio)
            end

            if self.ShowUnitDestructionDebris and overkillRatio then
                if overkillRatio <= 1 then
                    self:CreateUnitDestructionDebris(true, true, false)
                elseif overkillRatio <= 2 then
                    self:CreateUnitDestructionDebris(true, true, false)
                elseif overkillRatio <= 3 then
                    self:CreateUnitDestructionDebris(true, true, true)
                else
                    self:CreateUnitDestructionDebris(true, true, true)
                end
            end
            WaitTicks(21)

            if self.PlayDestructionEffects then
                self:CreateDestructionEffects(self, overkillRatio)
            end
            WaitTicks(11)

            if self.PlayDestructionEffects then
                self:CreateDestructionEffects(self, overkillRatio)
            end
            self:CreateWreckage(0)
            self:Destroy()
        else
            CSeaUnit.DeathThread(self, overkillRatio)
        end
    end,

    OnStopBeingBuilt = function(self, builder, layer)
        CSeaUnit.OnStopBeingBuilt(self, builder, layer)

        if self:GetAIBrain().BrainType == 'Human' and self.Layer ~= 'Land' then
            self:SetScriptBit('RULEUTC_WeaponToggle', true)
        end
    end,

    OnScriptBitSet = function(self, bit)
        CSeaUnit.OnScriptBitSet(self, bit)
        if bit == 1 then
            if self.Layer ~= 'Land' then
                self:GetStat("h1_SetSalemAmph", 0)
            else
                self:SetScriptBit('RULEUTC_WeaponToggle', false)
            end
        end
    end,

    OnScriptBitClear = function(self, bit)
        CSeaUnit.OnScriptBitClear(self, bit)
        if bit == 1 then
            self:GetStat("h1_SetSalemAmph", 1)
        end
    end,
}

TypeClass = URS0201
