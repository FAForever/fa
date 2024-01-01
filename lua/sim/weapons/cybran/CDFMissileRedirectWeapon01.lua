
local Weapon = import("/lua/sim/weapon.lua").Weapon
local WeaponOnCreate = Weapon.OnCreate
local WeaponOnGotTarget = Weapon.OnGotTarget

local ProjectileDetector = import("/lua/sim/entities/ProjectileDetector.lua").ProjectileDetector

---@class CDFMissileRedirectWeapon : Weapon
CDFMissileRedirectWeapon01 = ClassWeapon(Weapon) {

    ---@param self CDFMissileRedirectWeapon
    OnCreate = function(self)
        WeaponOnCreate(self)
        LOG("Hellooo")

        local projectileDetector = ProjectileDetector({Owner = self.unit, Weapon = self, Radius = 8, Bone = 'Turret_Muzzle'})
        self.Trash:Add(projectileDetector)
    end,

    ---@param self CDFMissileRedirectWeapon
    ---@param projectile Projectile
    OnProjectileDetected = function(self, projectile)
        -- already being redirected, bail out
        if projectile.IsRedirected then
            return
        end

        -- allied projectile, bail out
        if IsAlly(self.Army, projectile.Army) then
            return
        end

        -- invalid projectile, bail out
        if not EntityCategoryContains(categories.MISSILE - categories.STRATEGIC, projectile) then
            return
        end

        -- find all interesting properties
        local pvx, pvy, pvz = projectile:GetVelocity()
        local projectilePosition = projectile:GetPosition()
        local projectileOrientation = projectile:GetOrientation()
        local projectileLauncher = projectile:GetLauncher() --[[@as Unit]]
        local projectileBlueprintId = projectile.Blueprint.BlueprintId

        projectile:Destroy()

        -- create a new projectile
        self:ChangeProjectileBlueprint('/projectiles/SIFLaanseTacticalMissile01/SIFLaanseTacticalMissile01_proj.bp')
        local redirected = self:CreateProjectile('Turret_Muzzle')
        
        -- populate the projectile
        redirected.DamageData = projectile.DamageData
        redirected:SetLifetime(30)
        redirected:SetCollideEntity(false)
        redirected:SetCollideSurface(false)
        redirected:SetTurnRate(160)
        redirected:SetVelocity(pvx, pvy, pvz)
        redirected:SetPosition(projectilePosition, true)
        redirected:SetOrientation(projectileOrientation, true)

        -- point it somewhere
        redirected:SetNewTargetGround({
            projectilePosition[1] + (2 - 4 * Random()),
            projectilePosition[2] + 6,
            projectilePosition[3] + (2 - 4 * Random())
        })
        redirected:TrackTarget(true)

        -- redirect it
        self.Trash:Add(ForkThread(self.RedirectProjectileThread, self, redirected, projectileLauncher))
    end,

    ---@param self CDFMissileRedirectWeapon
    ---@param redirected Projectile
    ---@param launcher Unit
    RedirectProjectileThread = function(self, redirected, launcher)
        -- check after we created the fork thread
        if IsDestroyed(redirected) then
            LOG("Destroyed!")
            return
        end

        redirected:SetNewTargetGround({
            0,
            1000,
            0
        })

        WaitTicks(4)

        -- check after we created the fork thread
        if IsDestroyed(redirected) then
            LOG("Destroyed!")
            return
        end

        redirected:SetCollideEntity(true)
        redirected:SetCollideSurface(true)

        -- if the launcher still exists then we target that
        if not IsDestroyed(launcher) then
            redirected.OriginalTarget = launcher
            redirected:OnTrackTargetGround()
            
            local movementThread = redirected.MovementThread
            if movementThread then
                redirected.MoveThread = redirected.Trash:Add(ForkThread(redirected.MovementThread, redirected))
            end
        -- otherwise we destroy the projectile
        else
            Damage(nil, position, redirected, 200, "Normal")
        end
    end,

    OnFire = function(self)
        LOG("OnFire")
    end,
}
