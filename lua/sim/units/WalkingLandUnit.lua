local LandUnit = import('/lua/sim/units/LandUnit.lua').LandUnit

WalkingLandUnit = Class(LandUnit) {
    WalkingAnim = nil,
    WalkingAnimRate = 1,
    IdleAnim = false,
    IdleAnimRate = 1,
    DeathAnim = false,
    DisabledBones = {},

    OnMotionHorzEventChange = function(self, new, old)
        LandUnit.OnMotionHorzEventChange(self, new, old)

        if old == 'Stopped' then
            if (not self.Animator) then
                self.Animator = CreateAnimator(self, true)
            end
            local bpDisplay = self:GetBlueprint().Display
            if bpDisplay.AnimationWalk then
                self.Animator:PlayAnim(bpDisplay.AnimationWalk, true)
                self.Animator:SetRate(bpDisplay.AnimationWalkRate or 1)
            end
        elseif new == 'Stopped' then
            -- only keep the animator around if we are dying and playing a death anim
            -- or if we have an idle anim
            if self.IdleAnim and not self.Dead then
                self.Animator:PlayAnim(self.IdleAnim, true)
            elseif(not self.DeathAnim or not self.Dead) then
                self.Animator:Destroy()
                self.Animator = false
            end
        end
    end
}
