-----------------------------------------------------------------
-- File     :  /cdimage/units/XRB2205/XRB2205_script.lua
-- Author(s):  Jessica St. Croix, Gordon Duclos
-- Summary  :  Cybran Heavy Torpedo Launcher Script
-- Copyright ? 2007 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

-- Automatically upvalued moho functions for performance
local EntityMethods = _G.moho.entity_methods
local EntityMethodsSetHealth = EntityMethods.SetHealth

local GlobalMethods = _G
local GlobalMethodsIssueAttack = GlobalMethods.IssueAttack

local UnitMethods = _G.moho.unit_methods
local UnitMethodsSetFireState = UnitMethods.SetFireState
-- End of automatically upvalued moho functions

local CStructureUnit = import('/lua/cybranunits.lua').CStructureUnit
local CKrilTorpedoLauncherWeapon = import('/lua/cybranweapons.lua').CKrilTorpedoLauncherWeapon
local utilities = import('/lua/utilities.lua')

XRB2308 = Class(CStructureUnit)({
    Weapons = {
        Turret01 = Class(CKrilTorpedoLauncherWeapon)({}),
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
            --not IsIdle means that dummy HARMS has attack order and we want to transfer it to actual HARMS
            self:ForkThread(self.CreateNewHarmsWithDelay, armySelf, pos, spottedByArmy, fireState)
        else
            self:Destroy()

            local newHARMS = CreateUnitHPR('XRB2309', armySelf, pos[1], pos[2], pos[3], 0, 0, 0)

            EntityMethodsSetHealth(newHARMS, newHARMS, health)
            newHARMS.SpottedByArmy = spottedByArmy
            UnitMethodsSetFireState(newHARMS, fireState)
        end
    end,

    CreateNewHarmsWithDelay = function(self, armySelf, pos, spottedByArmy, fireState)
        --wait 1 tick to determine HARMS target
        WaitTicks(1)

        if not self:IsDead() then
            local health = self:GetHealth()
            local target = self:GetTargetEntity()

            self:Destroy()

            local newHARMS = CreateUnitHPR('XRB2309', armySelf, pos[1], pos[2], pos[3], 0, 0, 0)

            EntityMethodsSetHealth(newHARMS, newHARMS, health)
            newHARMS.SpottedByArmy = spottedByArmy
            UnitMethodsSetFireState(newHARMS, fireState)

            if target then
                GlobalMethodsIssueAttack({
                    newHARMS,
                }, target)
            end
        end
    end,

    DeathThread = function(self, overkillRatio, instigator)
        --dummy HARMS needs this death thread in case it dies during CreateNewHarmsWithDelay()
        local bp = self:GetBlueprint()

        -- Add an initial death explosion
        local army = self.Army
        self.Trash:Add(CreateAttachedEmitter(self, 'xrb2308', army, '/effects/emitters/flash_03_emit.bp'):ScaleEmitter(2))
        self.Trash:Add(CreateAttachedEmitter(self, 'xrb2308', army, '/effects/emitters/flash_04_emit.bp'):ScaleEmitter(2))

        self:DestroyAllDamageEffects()
        self:PlaySound(bp.Audio.Destroyed)

        -- Here down is near-shadowing the function, all to change the entity subset. Dumb, right?
        local isNaval = true
        -- This unit should definitely sink, no need to check cats.
        local shallSink = true

        WaitSeconds(utilities.GetRandomFloat(self.DestructionExplosionWaitDelayMin, self.DestructionExplosionWaitDelayMax))
        self:DestroyAllDamageEffects()
        self:DestroyIdleEffects()
        self:DestroyBeamExhaust()
        self:DestroyAllBuildEffects()

        -- BOOM!
        if self.PlayDestructionEffects then
            self:CreateDestructionEffects(overkillRatio)
        end

        -- Flying bits of metal and whatnot. More bits for more overkill.
        if self.ShowUnitDestructionDebris and overkillRatio then
            self.CreateUnitDestructionDebris(self, true, true, overkillRatio > 2)
        end

        self.DisallowCollisions = true

        -- Bubbles and stuff coming off the sinking wreck.
        self:ForkThread(self.SinkDestructionEffects)

        -- Avoid slightly ugly need to propagate this through callback hell...
        self.overkillRatio = overkillRatio

        local this = self
        self:StartSinking(function()

            this:DestroyUnit(overkillRatio)
        end)
    end,

    -- Called from unit.lua DeathThread
    StartSinking = function(self, callback)
        if not self.sinkingFromBuild and self.Bottom then
            -- We don't want to sink at death if we're on the seabed
            self:ForkThread(callback)
        elseif self.sinkingFromBuild then
            -- If still sinking, set the destruction callback for impact
            self.sinkProjectile.callback = callback
            return
        else
            -- Unit is static and floating. Use normal destruction params
            CStructureUnit.StartSinking(self, callback)
        end
    end,
})

TypeClass = XRB2308
