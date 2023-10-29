
local MobileUnit = import("/lua/sim/units/mobileunit.lua").MobileUnit

---@class WalkingLandUnit : MobileUnit
WalkingLandUnit = ClassUnit(MobileUnit) {
    WalkingAnim = nil,
    WalkingAnimRate = 1,
    IdleAnim = false,
    IdleAnimRate = 1,
    DeathAnim = false,
    DisabledBones = {},

    ---comment
    ---@param self WalkingLandUnit
    ---@param spec any
    OnCreate = function(self, spec)
        MobileUnit.OnCreate(self, spec)

        local blueprint = self.Blueprint
        self.AnimationWalk = blueprint.Display.AnimationWalk
        self.AnimationWalkRate = blueprint.Display.AnimationWalkRate
    end,

    ---comment
    ---@param self WalkingLandUnit
    ---@param new string
    ---@param old string
    OnMotionHorzEventChange = function(self, new, old)
        MobileUnit.OnMotionHorzEventChange(self, new, old)

        if old == 'Stopped' then
            if not self.Animator then
                self.Animator = CreateAnimator(self, true)
            end

            if self.AnimationWalk then
                self.Animator:PlayAnim(self.AnimationWalk, true)
                self.Animator:SetRate(self.AnimationWalkRate or 1)
            end
        elseif new == 'Stopped' then
            -- Only keep the animator around if we are dying and playing a death anim
            -- Or if we have an idle anim
            if self.IdleAnim and not self.Dead then
                self.Animator:PlayAnim(self.IdleAnim, true)
            elseif not self.DeathAnim or not self.Dead then
                self.Animator:Destroy()
                self.Animator = false
            end
        end
    end,
}

