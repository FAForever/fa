------------------------------------------------------------------------------
--  File     :  /data/projectiles/CIFBrackmanHackPegs01/CIFBrackmanHackPegs01_script.lua
--  Author(s):  Greg Kohne
--  Summary  :  Brackman Hack Peg-Pod
--  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------------------------
local EffectTemplate = import("/lua/effecttemplates.lua")
local CDFBrackmanHackPegProjectile01 = import("/lua/cybranprojectiles.lua").CDFBrackmanHackPegProjectile01
local RandomFloat = import("/lua/utilities.lua").GetRandomFloat

-- upvalue for perfomance
local CreateEmitterAtEntity = CreateEmitterAtEntity
local MathSin = math.sin
local MathCos = math.cos

--- Brackman Hack Peg-Pod
---@class CIFBrackmanHackPegs01 : CDFBrackmanHackPegProjectile01
CIFBrackmanHackPegs01 = ClassProjectile(CDFBrackmanHackPegProjectile01) {

    ---@param self CIFBrackmanHackPegs01
    ---@param TargetType string unused
    ---@param TargetEntity Prop|Unit unused
    OnImpact = function(self, TargetType, TargetEntity)
        local FxFragEffect = EffectTemplate.CBrackmanCrabPegPodSplit01
        local ChildProjectileBP = '/projectiles/CIFBrackmanHackPegs02/CIFBrackmanHackPegs02_proj.bp'
        local army = self.Army
        ------ Play split effects
        for k, v in FxFragEffect do
            CreateEmitterAtEntity( self, army, v )
        end
        local vx, vz = self:GetVelocity()
        local velocity = 18
		-- Create several other projectiles in a dispersal pattern
        local numProjectiles = 9
        local angle = (2*math.pi) / numProjectiles
        local angleInitial = RandomFloat( 0, angle )
        -- Randomization of the spread
        local angleVariation = 0.0 -- Adjusts angle variance spread
        local spreadMul = 0.753 -- Adjusts the width of the dispersal        

        local xVec = 0
        local zVec = 0

        -- Launch projectiles at semi-random angles away from split location
        for i = 0, (numProjectiles -1) do
            xVec = vx + (MathSin(angleInitial + (i*angle) + RandomFloat(-angleVariation, angleVariation))) * spreadMul
            zVec = vz + (MathCos(angleInitial + (i*angle) + RandomFloat(-angleVariation, angleVariation))) * spreadMul
            local proj = self:CreateProjectile(ChildProjectileBP, 0, 0.0, 0, xVec, -1.0, zVec):SetCollision(true):SetVelocity(velocity)
            proj.DamageData = self.DamageData
            proj:SetTargetPosition(self:GetCurrentTargetPosition())
        end
        self:Destroy()
    end,
}
TypeClass = CIFBrackmanHackPegs01