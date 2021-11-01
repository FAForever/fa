-----------------------------------------------------------------
-- File     :  /cdimage/units/URS0201/URS0201_script.lua
-- Author(s):  David Tomandl, Jessica St. Croix
-- Summary  :  Cybran Destroyer Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

-- Automatically upvalued moho functions for performance
local CAnimationManipulatorMethods = _G.moho.AnimationManipulator
local CAnimationManipulatorMethodsPlayAnim = CAnimationManipulatorMethods.PlayAnim
local CAnimationManipulatorMethodsSetAnimationFraction = CAnimationManipulatorMethods.SetAnimationFraction
local CAnimationManipulatorMethodsSetRate = CAnimationManipulatorMethods.SetRate

local EntityMethods = _G.moho.entity_methods
local EntityMethodsSetCollisionShape = EntityMethods.SetCollisionShape

local UnitMethods = _G.moho.unit_methods
local UnitMethodsGetStat = UnitMethods.GetStat
local UnitMethodsSetImmobile = UnitMethods.SetImmobile
local UnitMethodsSetScriptBit = UnitMethods.SetScriptBit
local UnitMethodsSetSpeedMult = UnitMethods.SetSpeedMult
-- End of automatically upvalued moho functions

local CWalkingLandUnit = import('/lua/cybranunits.lua').CWalkingLandUnit
local CSeaUnit = import('/lua/cybranunits.lua').CSeaUnit
local CybranWeapons = import('/lua/cybranweapons.lua')
local CAAAutocannon = CybranWeapons.CAAAutocannon
local CDFProtonCannonWeapon = CybranWeapons.CDFProtonCannonWeapon
local CANNaniteTorpedoWeapon = import('/lua/cybranweapons.lua').CANNaniteTorpedoWeapon
local CIFSmartCharge = import('/lua/cybranweapons.lua').CIFSmartCharge

URS0201 = Class(CSeaUnit)({
    SwitchAnims = true,
    Walking = false,
    IsWaiting = false,

    Weapons = {
        ParticleGun = Class(CDFProtonCannonWeapon)({}),
        AAGun = Class(CAAAutocannon)({}),
        TorpedoR = Class(CANNaniteTorpedoWeapon)({}),
        TorpedoL = Class(CANNaniteTorpedoWeapon)({}),
        AntiTorpedoF = Class(CIFSmartCharge)({}),
        AntiTorpedoB = Class(CIFSmartCharge)({}),
    },

    OnMotionHorzEventChange = function(self, new, old)
        CSeaUnit.OnMotionHorzEventChange(self, new, old)

        if self.Dead then
            return
        end

        if not self.IsWaiting then
            if self.Walking then
                if old == 'Stopped' then
                    if self.SwitchAnims then
                        self.SwitchAnims = false
                        CAnimationManipulatorMethodsPlayAnim(self.AnimManip, self:GetBlueprint().Display.AnimationWalk, true)
                        CAnimationManipulatorMethodsSetRate(self.AnimManip, self:GetBlueprint().Display.AnimationWalkRate or 1.1)
                    else
                        CAnimationManipulatorMethodsSetRate(self.AnimManip, 2.8)
                    end
                elseif new == 'Stopped' then
                    CAnimationManipulatorMethodsSetRate(self.AnimManip, 0)
                else

                end
            end
        end
    end,

    -- Override ShallSink to have Salem animate properly when it dies on land
    ShallSink = function(self)
        return true
    end,

    LayerChangeTrigger = function(self, new, old)
        local bp = self:GetBlueprint()
        -- Enable sonar on water only, apply speed multiplier on land
        if new == 'Land' then
            self:DisableUnitIntel('Layer', 'Sonar')
            UnitMethodsSetSpeedMult(self, bp.Physics.LandSpeedMultiplier)
        elseif new == 'Water' then
            self:EnableUnitIntel('Layer', 'Sonar')
            UnitMethodsSetSpeedMult(self, 1)
        else

        end

        -- Can only be built in water so transformthread only needs to be run
        -- when actually changing layer or when spawned on land
        if old ~= 'None' or new == 'Land' then
            if self.AT1 then
                self.AT1:Destroy()
            end
            self.AT1 = self:ForkThread(self.TransformThread, new == 'Land')
        end
    end,

    TransformThread = function(self, land)
        if not self.AnimManip then
            self.AnimManip = CreateAnimator(self)
        end

        local bp = self:GetBlueprint()
        local scale = bp.Display.UniformScale or 1
        if land then
            UnitMethodsSetImmobile(self, true)
            CAnimationManipulatorMethodsPlayAnim(self.AnimManip, self:GetBlueprint().Display.AnimationTransform)
            CAnimationManipulatorMethodsSetRate(self.AnimManip, 2)
            self.IsWaiting = true
            WaitFor(self.AnimManip)
            EntityMethodsSetCollisionShape(self, 'Box', bp.CollisionOffsetX or 0, bp.CollisionOffsetY + bp.SizeY * 1.0 or 0, bp.CollisionOffsetZ or 0, bp.SizeX * scale, bp.SizeY * scale, bp.SizeZ * scale)
            self.IsWaiting = false
            UnitMethodsSetImmobile(self, false)
            self.SwitchAnims = true
            self.Walking = true
            self.Trash:Add(self.AnimManip)
        else
            UnitMethodsSetImmobile(self, true)
            CAnimationManipulatorMethodsPlayAnim(self.AnimManip, self:GetBlueprint().Display.AnimationTransform)
            CAnimationManipulatorMethodsSetAnimationFraction(self.AnimManip, 1)
            CAnimationManipulatorMethodsSetRate(self.AnimManip, -2)
            self.IsWaiting = true
            WaitFor(self.AnimManip)
            EntityMethodsSetCollisionShape(self, 'Box', bp.CollisionOffsetX or 0, bp.CollisionOffsetY + bp.SizeY * 0.5 or 0, bp.CollisionOffsetZ or 0, bp.SizeX * scale, bp.SizeY * scale, bp.SizeZ * scale)
            self.IsWaiting = false
            self.AnimManip:Destroy()
            self.AnimManip = nil
            UnitMethodsSetImmobile(self, false)
            self.Walking = false
        end
    end,

    OnKilled = function(self, instigator, type, overkillRatio)
        self.Trash:Destroy()
        self.Trash = TrashBag()
        if self.Layer ~= 'Water' and not self.IsWaiting then
            self:GetBlueprint().Display.AnimationDeath = self:GetBlueprint().Display.LandAnimationDeath
        else
            self:GetBlueprint().Display.AnimationDeath = self:GetBlueprint().Display.WaterAnimationDeath
        end

        CSeaUnit.OnKilled(self, instigator, type, overkillRatio)
    end,

    DeathThread = function(self, overkillRatio)
        if self.Layer ~= 'Water' and not self.IsWaiting then
            self:PlayUnitSound('Destroyed')
            if self.PlayDestructionEffects then
                self:CreateDestructionEffects(self, overkillRatio)
            end

            -- Create Initial explosion effects
            if self.ShowUnitDestructionDebris and overkillRatio then
                if overkillRatio <= 1 then
                    self.CreateUnitDestructionDebris(self, true, true, false)
                elseif overkillRatio <= 2 then
                    self.CreateUnitDestructionDebris(self, true, true, false)
                elseif overkillRatio <= 3 then
                    self.CreateUnitDestructionDebris(self, true, true, true)
                else
                    -- VAPORIZED
                    self.CreateUnitDestructionDebris(self, true, true, true)
                end
            end
            WaitSeconds(2)

            if self.PlayDestructionEffects then
                self:CreateDestructionEffects(self, overkillRatio)
            end
            WaitSeconds(1)

            if self.PlayDestructionEffects then
                self:CreateDestructionEffects(self, overkillRatio)
            end
            self:CreateWreckage(0.1)
            self:Destroy()
        else
            CSeaUnit.DeathThread(self, overkillRatio)
        end
    end,

    OnStopBeingBuilt = function(self, builder, layer)
        CSeaUnit.OnStopBeingBuilt(self, builder, layer)

        if self:GetAIBrain().BrainType == 'Human' and self.Layer ~= 'Land' then
            UnitMethodsSetScriptBit(self, 'RULEUTC_WeaponToggle', true)
        end
    end,

    -- Disable amphibious mode
    OnScriptBitSet = function(self, bit)
        CSeaUnit.OnScriptBitSet(self, bit)
        if bit == 1 then
            if self.Layer ~= 'Land' then
                UnitMethodsGetStat(self, "h1_SetSalemAmph", 0)
            else
                UnitMethodsSetScriptBit(self, 'RULEUTC_WeaponToggle', false)
            end
        end
    end,

    -- Enable amphibious mode
    OnScriptBitClear = function(self, bit)
        CSeaUnit.OnScriptBitClear(self, bit)
        if bit == 1 then
            UnitMethodsGetStat(self, "h1_SetSalemAmph", 1)
        end
    end,
})

TypeClass = URS0201
