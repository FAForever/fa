
local MobileUnit = import("/lua/sim/units/mobileunit.lua").MobileUnit
local MobileUnitOnCreate = MobileUnit.OnCreate
local MobileUnitOnMotionHorzEventChange = MobileUnit.OnMotionHorzEventChange

local AnimationManipulatorPlayAnim = moho.AnimationManipulator.PlayAnim
local AnimationManipulatorSetRate = moho.AnimationManipulator.SetRate

---@class WalkingLandUnit : MobileUnit
---@field Animator moho.AnimationManipulator
---@field AnimationWalk? string
---@field AnimationWalkRate number
WalkingLandUnit = ClassUnit(MobileUnit) {
    WalkingAnim = nil,
    WalkingAnimRate = 1,

    ---@param self WalkingLandUnit
    OnCreate = function(self)
        MobileUnitOnCreate(self)

        local blueprintDisplay = self.Blueprint.Display
        self.AnimationWalk = blueprintDisplay.AnimationWalk
        self.AnimationWalkRate = blueprintDisplay.AnimationWalkRate or 1

        if self.AnimationWalk then
            self.Animator = CreateAnimator(self, true)
        end
    end,

    ---@param self WalkingLandUnit
    ---@param new string
    ---@param old string
    OnMotionHorzEventChange = function(self, new, old)
        MobileUnitOnMotionHorzEventChange(self, new, old)

        if old == 'Stopped' then
            local animator = self.Animator
            local animationWalk = self.AnimationWalk
            local animationWalkRate = self.AnimationWalkRate

            if animator then
                AnimationManipulatorPlayAnim(animator, animationWalk, true)
                AnimationManipulatorSetRate(animator, animationWalkRate)
            end
        end
    end,
}

