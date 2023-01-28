--
-- Terran Fragmentation/Sensor Shells
--
local TArtilleryProjectile = import("/lua/terranprojectiles.lua").TArtilleryProjectile
local VisionMarkerOpti = import("/lua/sim/vizmarker.lua").VisionMarkerOpti

-- upvalue for performance
local CreateEmitterAtEntity = CreateEmitterAtEntity
local Random = Random
local MathSin = math.sin
local MathCos = math.cos

local TFragmentationSensorShellFrag = import("/lua/effecttemplates.lua").TFragmentationSensorShellFrag 

TIFFragmentationSensorShell01 = ClassProjectile(TArtilleryProjectile) {
    OnImpact = function(self, TargetType, TargetEntity)
        -- the split fx
        CreateEmitterAtEntity( self, self.Army, TFragmentationSensorShellFrag[1])
        CreateEmitterAtEntity( self, self.Army, TFragmentationSensorShellFrag[2])

        -- Create several other projectiles in a dispersal pattern
        local bp = self.Blueprint.Physics
        local numProjectiles = bp.Fragments - 1

        -- Randomization of the spread
        local angle = 6.28 / numProjectiles
        local angleInitial = angle * Random()
        local angleVariation = angle * 0.35

        local px, _, pz = self:GetPositionXYZ()

        -- retrieve the current velocity
        local vx, vy, vz = self:GetVelocity()
        local xVec = 0
        local yVec = vy
        local zVec = 0

        -- create vision
        ---@type VisionMarkerOpti
        local marker = VisionMarkerOpti({ Owner = self })
        marker:UpdatePosition(px, pz)
        marker:UpdateDuration(5)
        marker:UpdateIntel(self.Army, 5, 'Vision', true)

		-- one initial projectile following same directional path as the original
        local proj = self:CreateChildProjectile(bp.FragmentId)
        proj:SetVelocity(vx, vy, vz)
        proj:SetVelocity(6)
        proj.DamageData = self.DamageData

        -- launch projectiles at semi-random angles away from split location
        for i = 0, numProjectiles - 1 do

            -- compute a random offset of the velocity for this fragment
            local a = angleInitial + (i*angle)
            xVec = vx + (MathSin(a + 2 * angleVariation * Random() - angleVariation)) * 0.5
            zVec = vz + (MathCos(a + 2 * angleVariation * Random() - angleVariation)) * 0.5

            -- create the projectile and set the velocity direction and then the velocity magnitude
            local proj = self:CreateChildProjectile(bp.FragmentId)
            proj:SetVelocity(xVec,yVec,zVec)
            proj:SetVelocity(6)

            -- just copy reference of damage data
            proj.DamageData = self.DamageData
        end

        self:Destroy()
    end,
}
TypeClass = TIFFragmentationSensorShell01