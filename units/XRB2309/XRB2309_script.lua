-----------------------------------------------------------------
-- File     :  /cdimage/units/XRB2205/XRB2205_script.lua
-- Author(s):  Jessica St. Croix, Gordon Duclos
-- Summary  :  Cybran Heavy Torpedo Launcher Script
-- Copyright ? 2007 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

local CStructureUnit = import("/lua/cybranunits.lua").CStructureUnit
local CKrilTorpedoLauncherWeapon = import("/lua/cybranweapons.lua").CKrilTorpedoLauncherWeapon
local utilities = import("/lua/utilities.lua")
local VizMarker = import("/lua/sim/vizmarker.lua").VizMarker

---@class XRB2309 : CStructureUnit
XRB2309 = ClassUnit(CStructureUnit) {
    Weapons = {
        Turret01 = ClassWeapon(CKrilTorpedoLauncherWeapon) {},
    },

    OnStopBeingBuilt = function(self, builder, layer)
        CStructureUnit.OnStopBeingBuilt(self, builder, layer)
        self:StartSinkingFromBuild()

        self.Trash:Add(CreateAttachedEmitter(self, 'xrb2308', self.Army,
            '/effects/emitters/tt_water02_footfall01_01_emit.bp'):ScaleEmitter(1.4))
        self.Trash:Add(CreateAttachedEmitter(self, 'xrb2308', self.Army,
            '/effects/emitters/tt_snowy01_landing01_01_emit.bp'):ScaleEmitter(1.5))
        ChangeState(self, self.IdleState)
    end,

    StartSinkingFromBuild = function(self)
        local position = self:GetPosition()
        if GetSurfaceHeight(position[1], position[3]) > position[2] then return end

        self.Trash:Add(CreateAttachedEmitter(self, 'xrb2308', self.Army,
            '/effects/emitters/tt_water_submerge02_01_emit.bp'):ScaleEmitter(1.5))
        local bone = 0
        local proj = self:CreateProjectileAtBone('/projectiles/Sinker/Sinker_proj.bp', bone)
        self.sinkProjectile = proj

        proj:SetLocalAngularVelocity(0, 0, 0)
        proj:Start(0, self, bone)
        proj:SetBallisticAcceleration(-0.75)
        self.Trash:Add(proj)
        self.Depthwatcher = self.Trash:Add(ForkThread(self.DepthWatcher,self))
    end,

    DepthWatcher = function(self)
        self.sinkingFromBuild = true

        local sinkFor = 3.4
        while self.sinkProjectile and sinkFor > 0 do
            WaitTicks(1)
            sinkFor = sinkFor - 0.1
        end

        local bottom = true
        if not self.Dead then
            if self.sinkProjectile then
                bottom = false
                self.sinkProjectile:Destroy()
                self.sinkProjectile = nil
            end

            self:SetPosition(self:GetPosition(), true)
            self:FinalAnimation()
        end

        self.sinkingFromBuild = false
        self.Bottom = bottom
    end,

    FinalAnimation = function(self)
        local bp = self.Blueprint
        local bpAnim = bp.Display.AnimationDeploy

        self.OpenAnim = CreateAnimator(self)
        self.OpenAnim:PlayAnim(bpAnim)
        self.Trash:Add(self.OpenAnim)
        self:PlaySound(bp.Audio.Deploy)

        local pos = self:GetPosition()

        for _, army in self.SpottedByArmy or {} do
            VizMarker({ X = pos[1], Z = pos[3], Radius = 4, LifeTime = 0.3, Army = army, Vision = true, })
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

TypeClass = XRB2309
