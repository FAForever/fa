local CLandUnit = import('/lua/cybranunits.lua').CLandUnit
local CDFRocketIridiumWeapon = import('/lua/cybranweapons.lua').CDFRocketIridiumWeapon

SRL0310 = Class(CLandUnit) {
    Weapons = {
        MainGun = Class(CDFRocketIridiumWeapon) {
            FxMuzzleFlash = {
                '/effects/emitters/cybran_artillery_muzzle_flash_01_emit.bp',
                '/effects/emitters/cybran_artillery_muzzle_flash_02_emit.bp',
                -- '/effects/emitters/cybran_artillery_muzzle_smoke_01_emit.bp',
                '/effects/emitters/cybran_hoplight_muzzle_smoke_01_emit.bp',
            },

            CreateProjectileAtMuzzle = function(self, muzzle)
                local proj = CDFRocketIridiumWeapon.CreateProjectileAtMuzzle(self, muzzle)
                if proj and not proj:BeenDestroyed() then
                    proj:PassData(self:GetBlueprint().DamageToShields)
                end
            end,
        }
    },

    OnLayerChange = function(self, new, old)
        CLandUnit.OnLayerChange(self, new, old)
        if self.TransformThread and (new == 'Land' or new == 'Water') then
            KillThread(self.TransformThread)
            self.TransformThread = nil
        end
        if new == 'Water' then
            self.TransformThread = self:ForkThread(self.LayerTransform, false, old=='Air')
            self.Animator:PlayAnim(__blueprints.srl0310.Display.AnimationSwim, true)
        elseif new == 'Land' and old ~= 'None' then
            self.TransformThread = self:ForkThread(self.LayerTransform, true, old=='Air')
            self.Animator:PlayAnim(__blueprints.srl0310.Display.AnimationWalk, true)
        end
    end,

    OnMotionHorzEventChange = function( self, new, old )
        CLandUnit.OnMotionHorzEventChange(self, new, old)
        if not self.Animator then
            self.Animator = CreateAnimator(self, true)
            self.Animator:SetDirectionalAnim(true)
        end
        if old == 'Stopped' and new ~= 'Stopped' then
            self.Animator:PlayAnim(self:GetCurrentLayer()=='Water' and __blueprints.srl0310.Display.AnimationSwim or __blueprints.srl0310.Display.AnimationWalk, true)
            self.Animator:SetRate(__blueprints.srl0310.Display.AnimationWalkRate or 1)
        elseif new == 'Stopped' then
            self.Animator:SetRate(0)
        end
    end,

    LayerTransform = function(self, land, instant)
        if not self.TransformAnimator then
            self.TransformAnimator = CreateAnimator(self)
        end

        if land then
            self:SetImmobile(true)
            local dur = __blueprints.srl0310.Physics.LayerTransitionDuration
            self.TransformAnimator
                :PlayAnim(__blueprints.srl0310.Display.AnimationTransform)
                :SetRate(-self.TransformAnimator:GetAnimationDuration() / dur)
                :SetAnimationFraction(instant and 0 or 1)
            if not instant then
                coroutine.yield(dur * 10)
            end
            self:SetImmobile(false)
            --self:RevertCollisionShape()
        else
            self:SetImmobile(true)
            local dur = __blueprints.srl0310.Physics.LayerTransitionDuration
            self.TransformAnimator
                :PlayAnim(__blueprints.srl0310.Display.AnimationTransform)
                :SetRate(self.TransformAnimator:GetAnimationDuration() / dur)
                :SetAnimationFraction(instant and 1 or 0)
            if not instant then
                coroutine.yield(dur * 10)
            end
            self:SetImmobile(false)
            ---Collision box partially in the water
            --local bp = __blueprints[self.BpId]
            --self:SetCollisionShape( 'Box', bp.CollisionOffsetX or 0, bp.CollisionOffsetYSwim or 1, bp.CollisionOffsetZ or 0, bp.SizeX * 0.5, bp.SizeY * 0.5, bp.SizeZ * 0.5)
        end
        KillThread(self.TransformThread)
        self.TransformThread = nil
    end,
}

TypeClass = SRL0310
