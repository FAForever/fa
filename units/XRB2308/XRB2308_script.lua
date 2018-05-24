-----------------------------------------------------------------
-- File     :  /cdimage/units/XRB2205/XRB2205_script.lua
-- Author(s):  Jessica St. Croix, Gordon Duclos
-- Summary  :  Cybran Heavy Torpedo Launcher Script
-- Copyright ? 2007 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

local CStructureUnit = import('/lua/cybranunits.lua').CStructureUnit
local CKrilTorpedoLauncherWeapon = import('/lua/cybranweapons.lua').CKrilTorpedoLauncherWeapon
local utilities = import('/lua/utilities.lua')

XRB2308 = Class(CStructureUnit) {
    Weapons = {
        Turret01 = Class(CKrilTorpedoLauncherWeapon) {},
    },

    OnStopBeingBuilt = function(self, builder, layer)
        CStructureUnit.OnStopBeingBuilt(self, builder, layer)
        
        IssueDive({self})
        self:FinalAnimation()

        local army = self:GetArmy() -- Add inital sinking effects
        self.Trash:Add(CreateAttachedEmitter(self, 'xrb2308', army, '/effects/emitters/tt_water02_footfall01_01_emit.bp'):ScaleEmitter(1.4)) -- One-off
        self.Trash:Add(CreateAttachedEmitter(self, 'xrb2308', army, '/effects/emitters/tt_snowy01_landing01_01_emit.bp'):ScaleEmitter(1.5)) -- One-off

        ChangeState(self, self.IdleState)
    end,

    -- Do the deploy animation
    FinalAnimation = function(self)
        local bp = self:GetBlueprint()
        local bpAnim = bp.Display.AnimationDeploy

        self.OpenAnim = CreateAnimator(self)
        self.OpenAnim:PlayAnim(bpAnim)
        self.Trash:Add(self.OpenAnim)
        self:PlaySound(bp.Audio.Deploy)
    end,

    DeathThread = function(self, overkillRatio, instigator)
        local bp = self:GetBlueprint()

        -- Add an initial death explosion
        local army = self:GetArmy()
        self.Trash:Add(CreateAttachedEmitter(self, 'xrb2308', army, '/effects/emitters/flash_03_emit.bp'):ScaleEmitter(2))
        self.Trash:Add(CreateAttachedEmitter(self, 'xrb2308', army, '/effects/emitters/flash_04_emit.bp'):ScaleEmitter(2))

        self:DestroyAllDamageEffects()
        self:PlaySound(bp.Audio.Destroyed)

        -- Here down is near-shadowing the function, all to change the entity subset. Dumb, right?
        local isNaval = true
        local shallSink = true -- This unit should definitely sink, no need to check cats.

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
        self:StartSinking(
            function()
                this:DestroyUnit(overkillRatio)
            end
        )
    end,

    -- Called from unit.lua DeathThread
    StartSinking = function(self, callback)
        if not self.sinkingFromBuild and self.Bottom then -- We don't want to sink at death if we're on the seabed
            ForkThread(callback)
        elseif self.sinkingFromBuild then -- If still sinking, set the destruction callback for impact
            self.sinkProjectile.callback = callback
            return
        else -- Unit is static and floating. Use normal destruction params
            CStructureUnit.StartSinking(self, callback)
        end
    end,
}

TypeClass = XRB2308
