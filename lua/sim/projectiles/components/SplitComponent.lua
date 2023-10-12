local MathSin = math.sin
local MathCos = math.cos
local MathPi = math.pi

---@class SplitComponent
SplitComponent = ClassSimple {

    ChildCount = 3,
    ChildProjectileBlueprint = '/projectiles/CIFMissileTacticalSplit01/CIFMissileTacticalSplit01_proj.bp',

    SpreadCone = 2 * MathPi,
    SpreadMultiplier = 1.0,
    SpreadMultiplierRange = 1.0,

    ---@param self SplitComponent | Projectile
    OnSplit = function(self, inheritTargetGround)
        local vx, vy, vz = self:GetVelocity()

        local spreadCone = self.SpreadCone
        local spreadMultiplier = self.SpreadMultiplier
        local spreadMultiplierRange = self.SpreadMultiplierRange

        local childCount = self.ChildCount
        local childBlueprint = self.ChildProjectileBlueprint
        local childVelocity = self:GetCurrentSpeed() * 5

        local childConeSection = spreadCone / childCount

        for i = 0, childCount - 1 do
            local xVec = vx + MathSin(i * childConeSection) * spreadMultiplier +
                (2 * spreadMultiplierRange * (Random() - 0.5))
            local yVec = vy + MathCos(i * childConeSection) * spreadMultiplier +
                (2 * spreadMultiplierRange * (Random() - 0.5))
            local zVec = vz + MathCos(i * childConeSection) * spreadMultiplier +
                (2 * spreadMultiplierRange * (Random() - 0.5))
            local proj = self:CreateChildProjectile(childBlueprint)
            proj:SetVelocity(xVec, yVec, zVec)
            proj:SetVelocity(childVelocity)
            proj.DamageData = self.DamageData

            if inheritTargetGround then
                proj:SetTurnRate(5)
                proj:SetNewTargetGround(self:GetCurrentTargetPosition())
                proj:TrackTarget(false)
            end
        end
    end,

}
