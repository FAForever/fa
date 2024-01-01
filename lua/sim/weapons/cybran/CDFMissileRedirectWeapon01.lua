local DefaultProjectileWeapon = import("/lua/sim/defaultweapons.lua").DefaultProjectileWeapon
local DefaultProjectileWeaponOnCreate = DefaultProjectileWeapon.OnCreate
local DefaultProjectileWeaponCreateProjectileAtMuzzle = DefaultProjectileWeapon.CreateProjectileAtMuzzle

---@class CDFMissileRedirectWeapon : DefaultProjectileWeapon
---@field RedirectTrash TrashBag
CDFMissileRedirectWeapon01 = ClassWeapon(DefaultProjectileWeapon) {

    RedirectBeams = { '/effects/emitters/particle_cannon_beam_02_emit.bp' },
    EndPointEffects = { '/effects/emitters/particle_cannon_end_01_emit.bp' },

    OnCreate = function(self)
        DefaultProjectileWeaponOnCreate(self)

        self.RedirectTrash = TrashBag()
    end,

    ---@param self CDFMissileRedirectWeapon
    ---@param muzzle Bone
    ---@return Projectile
    CreateProjectileAtMuzzle = function(self, muzzle)
        local projectile = self:GetCurrentTarget() --[[@as Projectile]]
        if projectile.IsRedirected then
            return nil
        end

        projectile.IsRedirected = true

        -- find all interesting properties
        local pvx, pvy, pvz = projectile:GetVelocity()
        local projectileSpeed = projectile:GetCurrentSpeed()
        local projectilePosition = projectile:GetPosition()
        local projectileOrientation = projectile:GetOrientation()
        local projectileLauncher = projectile:GetLauncher() --[[@as Unit]]
        local projectileBlueprintId = projectile.Blueprint.BlueprintId

        -- destroy the original projectile
        projectile:Destroy()

        -- change the projectile we produce
        self:ChangeProjectileBlueprint(projectileBlueprintId)

        -- create the projectile like usual
        local redirected = DefaultProjectileWeaponCreateProjectileAtMuzzle(self, muzzle)

        -- take out any existing movement threads
        if redirected.MoveThread then
            KillThread(redirected.MoveThread)
            redirected.MoveThread = nil
        end

        -- match the redirected projectile with the original projectile
        redirected.DamageData = projectile.DamageData
        redirected:SetVelocity(pvx, pvy, pvz)
        redirected:SetVelocity(10 * projectileSpeed)
        redirected:SetPosition(projectilePosition, true)
        redirected:SetOrientation(projectileOrientation, true)

        -- redirect behavior
        self.Trash:Add(ForkThread(self.RedirectBehaviorThread, self, redirected, projectileLauncher))
        self.Trash:Add(ForkThread(self.RedirectEffectThread, self, redirected, muzzle))
    end,

    ---@param self CDFMissileRedirectWeapon
    ---@param redirected Projectile
    ---@param launcher Unit
    RedirectBehaviorThread = function(self, redirected, launcher)
        if IsDestroyed(redirected) then
            return
        end

        -- rotate towards the sky
        local position = redirected:GetPosition()
        redirected:SetLifetime(30)
        redirected:SetTurnRate(160)
        redirected:SetNewTargetGround({
            position[1] + (2 - 4 * Random()),
            position[2] + 12,
            position[3] + (2 - 4 * Random())
        })

        WaitTicks(10)

        if IsDestroyed(redirected) then
            return
        end

        -- try to mimic the movement thread of the original missile
        if not IsDestroyed(launcher) then
            redirected.OriginalTarget = launcher
            redirected:OnTrackTargetGround()
            redirected:SetTurnRate(0)
            redirected.MoveThread = redirected.Trash:Add(ForkThread(redirected.MovementThread, redirected, true))
            -- otherwise we destroy the projectile
        else
            Damage(nil, position, redirected, 200, "Normal")
        end
    end,

    ---@param self CDFMissileRedirectWeapon
    ---@param redirected Projectile
    ---@param muzzle Bone
    RedirectEffectThread = function(self, redirected, muzzle)

        local army = self.Army
        local owner = self.unit
        local trash = self.RedirectTrash

        for k, beam in self.RedirectBeams do
            trash:Add(AttachBeamEntityToEntity(redirected, -1, owner, muzzle, army, beam))
        end

        for k, effect in self.EndPointEffects do
            trash:Add(CreateAttachedEmitter(redirected, -1, army, effect))
        end

        WaitTicks(14)

        trash:Destroy()
    end,
}
