-----------------------------------------------------------------
-- File     :  /cdimage/units/XRB2205/XRB2205_script.lua
-- Author(s):  Jessica St. Croix, Gordon Duclos
-- Summary  :  Cybran Heavy Torpedo Launcher Script
-- Copyright ? 2007 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

local CStructureUnit = import("/lua/cybranunits.lua").CStructureUnit
local CKrilTorpedoLauncherWeapon = import("/lua/cybranweapons.lua").CKrilTorpedoLauncherWeapon
local utilities = import("/lua/utilities.lua")

---@class XRB2308 : CStructureUnit
XRB2308 = ClassUnit(CStructureUnit) {
    Weapons = {
        Turret01 = ClassWeapon(CKrilTorpedoLauncherWeapon) {},
    },

    OnStopBeingBuilt = function(self, builder, layer)
        CStructureUnit.OnStopBeingBuilt(self, builder, layer)

        local pos = self:GetPosition()
        local armySelf = self.Army
        local health = self:GetHealth()
        local armies = ListArmies()
        local spottedByArmy = {}
        local fireState = self:GetFireState()

        for _, army in armies do
            if not IsAlly(armySelf, army) then
                local blip = self:GetBlip(army)

                if blip and blip:IsSeenEver(army) then
                    table.insert(spottedByArmy, ScenarioInfo.ArmySetup[army].ArmyIndex)
                end
            end
        end

        if not self:IsIdleState() then
            self.Trash:Add(ForkThread(self.CreateNewHarmsWithDelay, armySelf, pos, spottedByArmy, fireState,self))
        else
            self:Destroy()
            local newHARMS = CreateUnitHPR('XRB2309', armySelf, pos[1], pos[2], pos[3], 0, 0, 0)
            newHARMS:SetHealth(newHARMS, health)
            newHARMS.SpottedByArmy = spottedByArmy
            newHARMS:SetFireState(fireState)
        end
    end,

    CreateNewHarmsWithDelay = function(self, armySelf, pos, spottedByArmy, fireState)
        WaitTicks(1)
        if not self.Dead then
            local health = self:GetHealth()
            local target = self:GetTargetEntity()
            self:Destroy()
            local newHARMS = CreateUnitHPR('XRB2309', armySelf, pos[1], pos[2], pos[3], 0, 0, 0)
            newHARMS:SetHealth(newHARMS, health)
            newHARMS.SpottedByArmy = spottedByArmy
            newHARMS:SetFireState(fireState)
            if target then
                IssueAttack({ newHARMS }, target)
            end
        end
    end,

    DeathThread = function(self, overkillRatio, instigator)
        local bp = self.Blueprint
        local army = self.Army
        self.Trash:Add(CreateAttachedEmitter(self, 'xrb2308', army, '/effects/emitters/flash_03_emit.bp'):ScaleEmitter(2))
        self.Trash:Add(CreateAttachedEmitter(self, 'xrb2308', army, '/effects/emitters/flash_04_emit.bp'):ScaleEmitter(2))

        self:DestroyAllDamageEffects()
        self:PlaySound(bp.Audio.Destroyed)

        local isNaval = true
        local shallSink = true

        WaitSeconds(utilities.GetRandomFloat(self.DestructionExplosionWaitDelayMin, self.DestructionExplosionWaitDelayMax))

        if self.PlayDestructionEffects then
            self:CreateDestructionEffects(overkillRatio)
        end

        if self.ShowUnitDestructionDebris and overkillRatio then
            self:CreateUnitDestructionDebris(true, true, overkillRatio > 2)
        end

        self.DisallowCollisions = true
        self.Trash:Add(ForkThread(self.SinkDestructionEffects,self))
        self.overkillRatio = overkillRatio
        local this = self
        self:StartSinking(
            function()
                this:DestroyUnit(overkillRatio)
            end
        )
    end,

    StartSinking = function(self, callback)
        if not self.sinkingFromBuild and self.Bottom then
            self.Trash:Add(ForkThread(callback,self))
        elseif self.sinkingFromBuild then
            self.sinkProjectile.callback = callback
            return
        else
            CStructureUnit.StartSinking(self, callback)
        end
    end,
}

TypeClass = XRB2308
