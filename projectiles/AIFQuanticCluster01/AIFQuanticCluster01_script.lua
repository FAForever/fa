----------------------------------------------------------------------------------------
-- File     :  /data/projectiles/AIFQuanticCluster01/AIFQuanticCluster01_script.lua
-- Author(s):  Drew Staltman, Gordon Duclos
-- Summary  :  Quantic Cluster Projectile script
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
----------------------------------------------------------------------------------------
local EffectTemplate = import("/lua/effecttemplates.lua")
local AQuantumCluster = import("/lua/aeonprojectiles.lua").AQuantumCluster
local RandomFloat = import("/lua/utilities.lua").GetRandomFloat

-- upvalue for perfomance
local MathSin = math.sin
local MathCos = math.cos


---@class AIFQuanticCluster01 : AQuantumCluster
AIFQuanticCluster01 = ClassProjectile(AQuantumCluster) {

    ---@param self AIFQuanticCluster01
    ---@param TargetType string unused
    ---@param TargetEntity Prop|Unit unused
    OnImpact = function(self, TargetType, TargetEntity)
        local FxFragEffect = EffectTemplate.TFragmentationSensorShellFrag
        local army = self.Army
        local dmgData = self.DamageData
        local bp = self.Blueprint.Physics

        -- Split effects
        for k, v in FxFragEffect do
            CreateEmitterAtEntity( self, army, v )
        end

        local vx, vy, vz = self:GetVelocity()
        local velocity = 6

		-- One initial projectile following same directional path as the original
        self:CreateChildProjectile(bp.FragmentId):SetVelocity(vx, vy, vz):SetVelocity(velocity):PassDamageData(dmgData)

		-- Create several other projectiles in a dispersal pattern
        local numProjectiles = bp.Fragments
        local angle = (2 * math.pi) / numProjectiles
        local angleInitial = RandomFloat( 0, angle )

        -- Randomization of the spread
        local angleVariation = angle * 0.35 -- Adjusts angle variance spread
        local spreadMul = 10 -- Adjusts the width of the dispersal
        
        local xVec = 0
        local yVec = vy
        local zVec = 0

        -- Launch projectiles at semi-random angles away from split location
        for i = 0, (numProjectiles -1) do
            xVec = vx + (MathSin(angleInitial + (i*angle) + RandomFloat(-angleVariation, angleVariation))) * spreadMul
            zVec = vz + (MathCos(angleInitial + (i*angle) + RandomFloat(-angleVariation, angleVariation))) * spreadMul
            local proj = self:CreateChildProjectile(bp.FragmentId)
            proj:SetVelocity(xVec,yVec,zVec)
            proj:SetVelocity(velocity)
            proj.DamageData = dmgData
        end
        self:Destroy()
    end,
}
TypeClass = AIFQuanticCluster01