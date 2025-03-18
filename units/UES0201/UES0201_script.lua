--****************************************************************************
--**
--**  File     :  /cdimage/units/UES0201/UES0201_script.lua
--**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
--**
--**  Summary  :  Terran Destroyer Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local TSeaUnit = import("/lua/terranunits.lua").TSeaUnit
local TSeaUnitOnStopBeingBuilt = TSeaUnit.OnStopBeingBuilt
local TSeaUnitOnKilled = TSeaUnit.OnKilled

local TAALinkedRailgun = import("/lua/terranweapons.lua").TAALinkedRailgun
local TDFGaussCannonWeapon = import("/lua/terranweapons.lua").TDFGaussCannonWeapon
local TANTorpedoAngler = import("/lua/terranweapons.lua").TANTorpedoAngler
local TIFSmartCharge = import("/lua/terranweapons.lua").TIFSmartCharge

-- upvalue scope for performance
local Random = Random
local CreateRotator = CreateRotator

local TrashBagAdd = TrashBag.Add

local RotateSetTargetSpeed = moho.RotateManipulator.SetTargetSpeed
local RotateSetAccel = moho.RotateManipulator.SetAccel

---@class UES0201 : TSeaUnit
---@field Spinner01 moho.RotateManipulator
---@field Spinner02 moho.RotateManipulator
UES0201 = ClassUnit(TSeaUnit) {
    Weapons = {
        FrontTurret01 = ClassWeapon(TDFGaussCannonWeapon) {},
        BackTurret01 = ClassWeapon(TDFGaussCannonWeapon) {},
        FrontTurret02 = ClassWeapon(TAALinkedRailgun) {},
        Torpedo01 = ClassWeapon(TANTorpedoAngler) {},
        AntiTorpedo = ClassWeapon(TIFSmartCharge) {},
    },

    ---@param self UES0201
    ---@param builder Unit
    ---@param layer Layer
    OnStopBeingBuilt = function(self, builder, layer)
        TSeaUnitOnStopBeingBuilt(self, builder, layer)

        local trash = self.Trash
        self.Spinner01 = TrashBagAdd(trash, CreateRotator(self, 'Spinner01', 'y', nil, 180, 0, 180))
        self.Spinner02 = TrashBagAdd(trash, CreateRotator(self, 'Spinner02', 'y', nil, 180, 0, 180))

        -- hide the back turret, as the weapon is not used
        self:HideBone('Back_Turret02', true)
    end,

    ---@param self UES0201
    ---@param instigator Unit
    ---@param type DamageType
    ---@param overkillRatio number
    OnKilled = function(self, instigator, type, overkillRatio)
        TSeaUnitOnKilled(self, instigator, type, overkillRatio)

        if self:GetFractionComplete() >= 1.0 then
            local spinner

            spinner = self.Spinner01
            RotateSetTargetSpeed(spinner, 0)
            RotateSetAccel(spinner, -20)

            spinner = self.Spinner02
            RotateSetTargetSpeed(spinner, 0)
            RotateSetAccel(spinner, -20)

            -- create sparkles
            local emit
            local army = self.Army
            local trash = self.Trash

            emit = TrashBagAdd(trash,
                CreateAttachedEmitter(self, 'Spinner01', army, '/effects/emitters/sparks_11_emit.bp'))
            emit:SetEmitterParam('REPEATTIME', Random(20, 40))

            emit = TrashBagAdd(trash,
                CreateAttachedEmitter(self, 'Spinner02', army, '/effects/emitters/sparks_11_emit.bp'))
            emit:SetEmitterParam('REPEATTIME', Random(20, 40))

            -- create a short debrish-isch flash, as if the dishes explode
            CreateLightParticleIntel(self, 'Spinner01', army, 0.15 + 0.05 * Random(2, 4), Random(3, 6), 'debris_alpha_03'
                , 'ramp_antimatter_01')
            CreateLightParticleIntel(self, 'Spinner02', army, 0.15 + 0.05 * Random(2, 4), Random(3, 6), 'debris_alpha_03'
                , 'ramp_antimatter_01')
        end
    end,
}

TypeClass = UES0201
