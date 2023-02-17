-----------------------------------------------------------------
-- File     :  /lua/sim/DefaultWeapons.lua
-- Author(s):  John Comes
-- Summary  :  Default definitions of weapons
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------
-- upvalue globals for performance
local GetSurfaceHeight = GetSurfaceHeight
local VDist2 = VDist2

local EntityMethods = moho.entity_methods
local EntityGetPosition = EntityMethods.GetPosition
local EntityGetPositionXYZ = EntityMethods.GetPositionXYZ

local UnitMethods = moho.unit_methods
local UnitGetVelocity = UnitMethods.GetVelocity
local UnitGetTargetEntity = UnitMethods.GetTargetEntity

local Weapon = import("/lua/sim/weapon.lua").Weapon
local CollisionBeam = import("/lua/sim/collisionbeam.lua").CollisionBeam

local MathClamp = math.clamp

---@class WeaponSalvoData
---@field target? Unit | Prop   if absent, will use `targetpos` instead
---@field targetpos Vector      stores the last location of the target, or the ground fire location
---@field lastAccel number      stores the last acceleration that was used
---@field usestore? boolean     a flag that indicates if the target was lost

-- Most weapons derive from this class, including beam weapons later in this file
---@class DefaultProjectileWeapon : Weapon
---@field RecoilManipulators? TrashBag
---@field CurrentSalvoNumber number
---@field CurrentRackSalvoNumber number
---@field CurrentSalvoData? WeaponSalvoData
---@field AdjustedSalvoDelay? number if the weapon blueprint requests a trajectory fix, this is set to the effective duration of the salvo in ticks used to calculate projectile spread
---@field DropBombShortRatio? number if the weapon blueprint requests a trajectory fix, this is set to the ratio of the distance to the target that the projectile is launched short to
---@field SalvoSpreadStart? number   if the weapon blueprint requests a trajectory fix, this is set to the value that centers the projectile spread for `CurrentSalvoNumber` shot on the optimal target position
DefaultProjectileWeapon = ClassWeapon(Weapon) {

    FxRackChargeMuzzleFlash = import("/lua/effecttemplates.lua").NoEffects,
    FxRackChargeMuzzleFlashScale = 1,
    FxChargeMuzzleFlash = import("/lua/effecttemplates.lua").NoEffects,
    FxChargeMuzzleFlashScale = 1,
    FxMuzzleFlash = {
        '/effects/emitters/default_muzzle_flash_01_emit.bp',
        '/effects/emitters/default_muzzle_flash_02_emit.bp',
    },
    FxMuzzleFlashScale = 1,

    -- Called when the weapon is created, almost always when the owning unit is created
    ---@param self DefaultProjectileWeapon
    ---@return boolean
    OnCreate = function(self)
        Weapon.OnCreate(self)

        local bp = self.Blueprint
        local rackBones = bp.RackBones
        local rackRecoilDist = bp.RackRecoilDistance
        local muzzleSalvoDelay = bp.MuzzleSalvoDelay
        local muzzleSalvoSize = bp.MuzzleSalvoSize

        self.WeaponCanFire = true

        -- Make certain the weapon has essential aspects defined
        if not rackBones then
           local strg = '*ERROR: No RackBones table specified, aborting weapon setup.  Weapon: ' .. bp.DisplayName .. ' on Unit: ' .. self.unit:GetUnitId()
           error(strg, 2)
           return
        end
        if not muzzleSalvoSize then
           local strg = '*ERROR: No MuzzleSalvoSize specified, aborting weapon setup.  Weapon: ' .. bp.DisplayName .. ' on Unit: ' .. self.unit:GetUnitId()
           error(strg, 2)
           return
        end
        if not muzzleSalvoDelay then
           local strg = '*ERROR: No MuzzleSalvoDelay specified, aborting weapon setup.  Weapon: ' .. bp.DisplayName .. ' on Unit: ' .. self.unit:GetUnitId()
           error(strg, 2)
           return
        end

        self.CurrentRackSalvoNumber = 1

        local rof = self:GetWeaponRoF()
        -- Calculate recoil speed so that it finishes returning just as the next shot is ready
        if rackRecoilDist ~= 0 then
            self.RecoilManipulators = TrashBag()
            self.Trash:Add(self.RecoilManipulators)

            local dist = rackRecoilDist
            local telescopeRecoilDist = rackBones[1].TelescopeRecoilDistance
            if telescopeRecoilDist and math.abs(telescopeRecoilDist) > math.abs(dist) then
                dist = telescopeRecoilDist
            end
            self.RackRecoilReturnSpeed = bp.RackRecoilReturnSpeed or math.abs(dist / ((1 / rof) - (bp.MuzzleChargeDelay or 0))) * 1.25
        end
        if rackRecoilDist ~= 0 and muzzleSalvoDelay ~= 0 then
            local strg = '*ERROR: You can not have a RackRecoilDistance with a MuzzleSalvoDelay not equal to 0, aborting weapon setup.  Weapon: ' .. bp.DisplayName .. ' on Unit: ' .. self.unit:GetUnitId()
            error(strg, 2)
            return false
        end

        -- Ensure firing cycle is compatible internally
        local numRackBones = table.getn(rackBones)
        local numMuzzles = 0
        for _, rack in rackBones do
            local muzzleBones = rack.MuzzleBones
            numMuzzles = numMuzzles + table.getn(muzzleBones)
        end
        self.NumMuzzles = numMuzzles / numRackBones
        self.NumRackBones = numRackBones
        local totalMuzzleFiringTime = (self.NumMuzzles - 1) * muzzleSalvoDelay
        if totalMuzzleFiringTime > (1 / rof) then
            local strg = '*ERROR: The total time to fire muzzles is longer than the RateOfFire allows, aborting weapon setup.  Weapon: ' .. bp.DisplayName .. ' on Unit: ' .. self.unit:GetUnitId()
            error(strg, 2)
            return false
        end

        if bp.EnergyChargeForFirstShot == false then
            self.FirstShot = true
        end

        -- Set the firing cycle progress bar to full if required
        if bp.RenderFireClock then
            self.unit:SetWorkProgress(1)
        end

        if bp.FixBombTrajectory then
            local dropShort = bp.DropBombShort
            if dropShort then
                self.DropBombShortRatio = MathClamp(1 - dropShort, 0, 1)
            end
            if muzzleSalvoSize > 1 then
                -- center the spread on the target
                self.SalvoSpreadStart = -0.5 - 0.5 * muzzleSalvoSize
                -- adjusted time between bombs, this is multiplied by 0.5 to get the bombs overlapping a bit
                -- (also pre-convert velocity from per-ticks to per-seconds by multiplying by 10)
                self.AdjustedSalvoDelay = 5 * bp.MuzzleSalvoDelay
            end
        end

        ChangeState(self, self.IdleState)
    end,

    -- This function creates the projectile, and happens when the unit is trying to fire
    -- Called from inside RackSalvoFiringState
    ---@param self DefaultProjectileWeapon
    ---@param muzzle string
    ---@return Projectile
    CreateProjectileAtMuzzle = function(self, muzzle)
        local proj = self:CreateProjectileForWeapon(muzzle)
        if not proj or proj:BeenDestroyed() then
            return proj
        end

        local bp = self.Blueprint
        if bp.DetonatesAtTargetHeight == true then
            local pos = self:GetCurrentTargetPos()
            if pos then
                local theight = GetSurfaceHeight(pos[1], pos[3])
                local hght = pos[2] - theight
                proj:ChangeDetonateAboveHeight(hght)
            end
        end
        if bp.Flare then
            proj:AddFlare(bp.Flare)
        end
        if self.unit.Layer == 'Water' and bp.Audio.FireUnderWater then
            self:PlaySound(bp.Audio.FireUnderWater)
        elseif bp.Audio.Fire then
            self:PlaySound(bp.Audio.Fire)
        end

        if bp.FixBombTrajectory then
            self:CheckBallisticAcceleration(proj)
        end

        return proj
    end;

    -- Used mainly for Bomb drop physics calculations
    ---@param self DefaultProjectileWeapon
    ---@param proj Projectile
    CheckBallisticAcceleration = function(self, proj)
         -- Change projectile trajectory so it hits the target
        proj:SetBallisticAcceleration(-self:CalculateBallisticAcceleration(proj))
    end,

    ---@param self DefaultProjectileWeapon
    ---@param projectile Projectile
    ---@return number
    CalculateBallisticAcceleration = function(self, projectile)
        local launcher = projectile:GetLauncher()
        if not launcher then -- fail-fast
            return 4.75
        end

        local UnitGetVelocity = UnitGetVelocity
        local VDist2 = VDist2
        -- Get projectile position and velocity
        -- velocity will need to be multiplied by 10 due to being returned /tick instead of /s
        local projPosX, projPosY, projPosZ = EntityGetPositionXYZ(projectile)
        local projVelX,    _    , projVelZ = UnitGetVelocity(launcher)

        local targetPos
        local targetVelX, targetVelZ = 0, 0

        local data = self.CurrentSalvoData

        -- if it's the first time...
        if not data then
            -- setup target (which won't change mid-bombing run)
            local target = UnitGetTargetEntity(launcher)
            if target then -- target is a unit / prop
                targetPos = EntityGetPosition(target)
            else -- target is a position i.e. attack ground
                targetPos = self:GetCurrentTargetPos()
            end

            -- and there's not going to be a second time
            if self.Blueprint.MuzzleSalvoSize <= 1 then
                -- do the calculation but skip any cache or salvo logic
                if not targetPos then
                    return 4.75
                end
                if target and not target.IsProp then
                    targetVelX, _, targetVelZ = UnitGetVelocity(target)
                end
                local targetPosX, targetPosZ = targetPos[1], targetPos[3]
                local distVel = VDist2(projVelX, projVelZ, targetVelX, targetVelZ)
                if distVel == 0 then
                    return 4.75
                end
                local distPos = VDist2(projPosX, projPosZ, targetPosX, targetPosZ)
                do
                    local dropShort = self.DropBombShortRatio
                    if dropShort then
                        distPos = distPos * dropShort
                    end
                end
                if distPos == 0 then
                    return 4.75
                end
                local time = distPos / distVel
                projPosY = projPosY - GetSurfaceHeight(targetPosX + time * targetVelX, targetPosZ + time * targetVelZ)
                return 200 * projPosY / (time*time)
            else -- otherwise, calculate & cache a couple things the first time only
                data = {
                    lastAccel = 4.75,
                    targetpos = targetPos,
                }
                if target then
                    if target.Dead then
                        data.usestore = true
                    else
                        data.target = target
                    end
                end
                self.CurrentSalvoData = data
            end
        else -- if it's a successive bomb drop, get the targeting data
            local target = data.target
            if target then
                if target.Dead then -- if the unit is destroyed, use the last known position
                    data.target = nil
                    data.usestore = true -- flag that we lost the target
                    targetPos = data.targetpos
                else
                    if not target.IsProp then
                        targetVelX, _, targetVelZ = UnitGetVelocity(target)
                    end
                    targetPos = EntityGetPosition(target)
                    data.targetpos = targetPos
                end
            else
                targetPos = data.targetpos
            end
        end
        if not targetPos then
            -- put the bomb cluster in free-fall
            local GetSurfaceHeight = GetSurfaceHeight
            local MathSqrt = math.sqrt
            local spread = self.AdjustedSalvoDelay * (self.SalvoSpreadStart + self.CurrentSalvoNumber)
            -- nominal acceleration is 4.75; however, bomb clusters adjust the time it takes to land
            -- so we convert the acceleration to time to add the spread and convert back:
            -- h = unitY - surfaceY         =>  h2 = 0.5 * (unitY - surfaceHeight(unitX, unitZ))
            -- t = sqrt(2 h / a) + spread   =>  t = sqrt(4 / 4.75 * h2) + spread
            -- a = 0.5 h / t^2              =>  a = h2 / t^2
            local halfHeight = 0.5 * (projPosY - GetSurfaceHeight(projPosX, projPosZ))
            if halfHeight < 0.01 then return 4.75 end
            local time = MathSqrt(0.842105263158 * halfHeight) + spread

            -- now that we know roughly when we'll land, we can find a better guess for where
            -- we'll land, and thus guess the true falling height better as well
            halfHeight = 0.5 * (projPosY - GetSurfaceHeight(projPosX + time * projVelX, projPosX + time * projVelX))
            time = MathSqrt(0.842105263158 * halfHeight) + spread

            local acc = halfHeight / (time*time)
            data.lastAccel = acc
            return acc
        end

        -- calculate flat (exclude y-axis) distance and velocity between projectile and target
        -- velocity will eventually need to multiplied by 10 due to being per tick instead of per second
        local distVel = VDist2(projVelX, projVelZ, targetVelX, targetVelZ)
        if distVel == 0 then
            data.lastAccel = 4.75
            return 4.75
        end
        local targetPosX, targetPosZ = targetPos[1], targetPos[3]

        -- calculate the distance for this particular bomb
        local distPos = VDist2(projPosX, projPosZ, targetPosX, targetPosZ)
        do
            local dropShort = self.DropBombShortRatio
            if dropShort then
                distPos = distPos * dropShort
            end
        end

        -- how many ticks until the bomb hits the target in xz-space
        local time = distPos / distVel + self.AdjustedSalvoDelay * (self.SalvoSpreadStart + self.CurrentSalvoNumber)
        if time == 0 then
            data.lastAccel = 4.75
            return 4.75
        end

        -- find out where the target will be at that point in time (it could be moving)
        -- (time and velocity being in ticks cancel out)
        -- what is the height difference at that future position
        projPosY = projPosY - GetSurfaceHeight(targetPosX + time * targetVelX, targetPosZ + time * targetVelZ)

        -- The basic formula for displacement over time is h = 0.5 * a * t^2
        -- h: displacement, a: acceleration, t: time
        -- now we can calculate what acceleration we need to make it hit the target in the y-axis
        -- a = 2 * h / t^2

        -- also convert time from ticks to seconds (multiply by 10, twice)
        local acc = 200 * projPosY / (time*time)

        data.lastAccel = acc
        return acc
    end,

    -- Triggers when the weapon is moved horizontally, usually by owner's motion
    ---@param self DefaultProjectileWeapon
    ---@param new string
    ---@param old string
    OnMotionHorzEventChange = function(self, new, old)
        Weapon.OnMotionHorzEventChange(self, new, old)

        local blueprint = self.Blueprint

        -- Handle weapons which must pack before moving
        if blueprint.WeaponUnpackLocksMotion == true and old == 'Stopped' then
            self:PackAndMove()
        end

        -- Handle motion-triggered FiringRandomness changes
        if blueprint.FiringRandomnessWhileMoving then
            if old == 'Stopped' then
                self:SetFiringRandomness(blueprint.FiringRandomnessWhileMoving)
            elseif new == 'Stopped' then
                self:SetFiringRandomness(blueprint.FiringRandomness)
            end
        end
    end,

    -- Called on horizontal motion event
    ---@param self DefaultProjectileWeapon
    PackAndMove = function(self)
        ChangeState(self, self.WeaponPackingState)
    end,

    -- Create an economy event for those weapons which require Energy to fire
    ---@param self DefaultProjectileWeapon
    StartEconomyDrain = function(self)
        if self.FirstShot then return end
        if self.unit:GetFractionComplete() ~= 1 then return end

        if not self.EconDrain and self.EnergyRequired and self.EnergyDrainPerSecond then
            local nrgReq = self:GetWeaponEnergyRequired()
            local nrgDrain = self:GetWeaponEnergyDrain()
            if nrgReq > 0 and nrgDrain > 0 then
                local time = nrgReq / nrgDrain
                if time < 0.1 then
                    time = 0.1
                end
                self.EconDrain = CreateEconomyEvent(self.unit, nrgReq, 0, time)
                self.FirstShot = true
                self.unit:ForkThread(function()
                    WaitFor(self.EconDrain)
                    RemoveEconomyEvent(self.unit, self.EconDrain)
                    self.EconDrain = nil
                end)
            end
        end
    end,

    -- Determine how much Energy is required to fire
    ---@param self DefaultProjectileWeapon
    ---@return integer
    GetWeaponEnergyRequired = function(self)
        local weapNRG = (self.EnergyRequired or 0) * (self.AdjEnergyMod or 1)
        if weapNRG < 0 then
            weapNRG = 0
        end
        return weapNRG
    end,

    -- Determine how much Energy should be drained per second
    ---@param self DefaultProjectileWeapon
    ---@return integer
    GetWeaponEnergyDrain = function(self)
        local weapNRG = (self.EnergyDrainPerSecond or 0) * (self.AdjEnergyMod or 1)
        return weapNRG
    end,

    ---@param self DefaultProjectileWeapon
    ---@return number
    GetWeaponRoF = function(self)
        return self.Blueprint.RateOfFire / (self.AdjRoFMod or 1)
    end,

    -- Effect Functions Section
    -- Play visual effects, animations, recoil etc

    -- Played when a muzzle is fired. Mostly used for muzzle flashes
    ---@param self DefaultProjectileWeapon
    ---@param muzzle string
    PlayFxMuzzleSequence = function(self, muzzle)
        local unit = self.unit
        local army = self.Army
        local scale = self.FxMuzzleFlashScale
        for _, effect in self.FxMuzzleFlash do
            CreateAttachedEmitter(unit, muzzle, army, effect):ScaleEmitter(scale)
        end
    end,

    -- Played during the beginning of the MuzzleChargeDelay time when a muzzle in a rack is fired.
    ---@param self DefaultProjectileWeapon
    ---@param muzzle string
    PlayFxMuzzleChargeSequence = function(self, muzzle)
        local unit = self.unit
        local army = self.Army
        local scale = self.FxChargeMuzzleFlashScale
        for _, effect in self.FxChargeMuzzleFlash do
            CreateAttachedEmitter(unit, muzzle, army, effect):ScaleEmitter(scale)
        end
    end,

    -- Played when a rack salvo charges
    -- Do not wait in here or the sequence in the blueprint will be messed up. Fork a thread instead
    ---@param self DefaultProjectileWeapon
    PlayFxRackSalvoChargeSequence = function(self)
        local bp = self.Blueprint
        local muzzleBones = bp.RackBones[self.CurrentRackSalvoNumber].MuzzleBones
        local unit = self.unit
        local army = self.Army
        local scale = self.FxRackChargeMuzzleFlashScale
        for _, effect in self.FxRackChargeMuzzleFlash do
            for _, muzzle in muzzleBones do
                CreateAttachedEmitter(unit, muzzle, army, effect):ScaleEmitter(scale)
            end
        end
        local chargeStart = bp.Audio.ChargeStart
        if chargeStart then
            self:PlaySound(chargeStart)
        end
        local animationCharge = bp.AnimationCharge
        if animationCharge and self.Animator then
            local animator = CreateAnimator(unit)
            self.Animator = animator
            animator:PlayAnim(animationCharge):SetRate(bp.AnimationChargeRate or 1)
        end
    end,

    -- Played when a rack salvo reloads
    -- Do not wait in here or the sequence in the blueprint will be messed up. Fork a thread instead
    ---@param self DefaultProjectileWeapon
    PlayFxRackSalvoReloadSequence = function(self)
        local bp = self.Blueprint
        local animationReload = bp.AnimationReload
        if animationReload and not self.Animator then
            local animator = CreateAnimator(self.unit)
            self.Animator = animator
            animator:PlayAnim(animationReload):SetRate(bp.AnimationReloadRate or 1)
        end
    end,

    -- Played when a rack reloads. Mostly used for Recoil
    ---@param self DefaultProjectileWeapon
    PlayFxRackReloadSequence = function(self)
        local bp = self.Blueprint
        local cameraShakeRadius = bp.CameraShakeRadius
        local cameraShakeMax = bp.CameraShakeMax
        local cameraShakeMin = bp.CameraShakeMin
        local cameraShakeDuration = bp.CameraShakeDuration
        if  cameraShakeRadius   and cameraShakeRadius > 0 and
            cameraShakeMax      and cameraShakeMax > 0 and
            cameraShakeMin      and cameraShakeMin >= 0 and
            cameraShakeDuration and cameraShakeDuration > 0
        then
            self.unit:ShakeCamera(cameraShakeRadius, cameraShakeMax, cameraShakeMin, cameraShakeDuration)
        end
        if bp.RackRecoilDistance ~= 0 then
            self:PlayRackRecoil({bp.RackBones[self.CurrentRackSalvoNumber]})
        end
    end,

    -- Played when a weapon unpacks
    ---@param self DefaultProjectileWeapon
    PlayFxWeaponUnpackSequence = function(self)
        -- Deal with owner's audio cues
        local unitBP = self.unit:GetBlueprint()
        local unitBPAudio = unitBP.Audio
        local activate = unitBPAudio.Activate
        if activate then
            self:PlaySound(activate)
        end
        local open = unitBPAudio.Open
        if open then
            self:PlaySound(open)
        end

        -- Deal with the Weapon's audio and animations
        local bp = self.Blueprint
        local unpack = bp.Audio.Unpack
        if unpack then
            self:PlaySound(unpack)
        end
        local unpackAnimation = bp.WeaponUnpackAnimation
        local unpackAnimator = self.UnpackAnimator
        if unpackAnimation and not unpackAnimator then
            unpackAnimator = CreateAnimator(self.unit)
            self.UnpackAnimator = unpackAnimator
            unpackAnimator:PlayAnim(unpackAnimation):SetRate(0)
            unpackAnimator:SetPrecedence(bp.WeaponUnpackAnimatorPrecedence or 0)
            self.Trash:Add(unpackAnimator)
        end
        if unpackAnimator then
            unpackAnimator:SetRate(bp.WeaponUnpackAnimationRate)
            WaitFor(unpackAnimator)
        end
    end,

    -- Played when a weapon packs up
    -- There is no target, and all rack salvos are complete
    ---@param self DefaultProjectileWeapon
    PlayFxWeaponPackSequence = function(self)
        local bp = self.Blueprint
        local close = self.unit.Blueprint.Audio.Close
        if close then
            self:PlaySound(close)
        end
        local unpackAnimator = self.UnpackAnimator
        if unpackAnimator then
            if bp.WeaponUnpackAnimation then
                unpackAnimator:SetRate(-bp.WeaponUnpackAnimationRate)
            end
            WaitFor(unpackAnimator)
        end
    end,

    -- Create the visual side of rack recoil
    ---@param self DefaultProjectileWeapon
    ---@param rackList RackBoneBlueprint[]
    PlayRackRecoil = function(self, rackList)
        local bp = self.Blueprint
        local rackRecoilDist = bp.RackRecoilDistance

        ---@type TrashBag
        local recoilManipulatorBag = self.RecoilManipulators
        for _, rack in rackList do
            local telescopeBone = rack.TelescopeBone
            local tmpSldr = CreateSlider(self.unit, rack.RackBone)
            tmpSldr:SetPrecedence(11)
            tmpSldr:SetGoal(0, 0, rackRecoilDist)
            tmpSldr:SetSpeed(-1)
            recoilManipulatorBag:Add(tmpSldr)
            if telescopeBone then
                tmpSldr = CreateSlider(self.unit, telescopeBone)
                tmpSldr:SetPrecedence(11)
                tmpSldr:SetGoal(0, 0, rack.TelescopeRecoilDistance or rackRecoilDist)
                tmpSldr:SetSpeed(-1)
                recoilManipulatorBag:Add(tmpSldr)
            end
        end
        self:ForkThread(self.PlayRackRecoilReturn, rackList)
    end,

    -- The opposite function to PlayRackRecoil, returns the rack to default position
    ---@param self DefaultProjectileWeapon
    ---@param rackList RackBoneBlueprint[]
    PlayRackRecoilReturn = function(self, rackList)
        WaitTicks(1)
        local speed = self.RackRecoilReturnSpeed
        for _, recManip in self.RecoilManipulators do
            recManip:SetGoal(0, 0, 0)
            recManip:SetSpeed(speed)
        end
    end,

    -- Wait for all recoil and animations
    ---@param self DefaultProjectileWeapon
    WaitForAndDestroyManips = function(self)
        local manips = self.RecoilManipulators
        if manips then
            for _, manip in manips do
                WaitFor(manip)

            end
            self:DestroyRecoilManips()
        end
        local animator = self.Animator
        if animator then
            WaitFor(animator)

            animator:Destroy()
            self.Animator = nil
        end
    end,

    -- Destroy the sliders which cause weapon visual recoil
    ---@param self DefaultProjectileWeapon
    DestroyRecoilManips = function(self)
        if self.RecoilManipulators then
            self.RecoilManipulators:Destroy()
        end
    end,

    -- Should be called whenever a target is lost
    -- Includes the manual selection of a new target, and the issuing of a move order
    ---@param self DefaultProjectileWeapon
    OnLostTarget = function(self)
        -- Issue 43
        -- Tell the owner this weapon has lost the target
        local unit = self.unit
        if unit then
            unit:OnLostTarget(self)
        end

        Weapon.OnLostTarget(self)

        if self.Blueprint.WeaponUnpacks then
            ChangeState(self, self.WeaponPackingState)
        else
            ChangeState(self, self.IdleState)
        end
    end,

    -- Sends the weapon to DeadState, probably called by the Owner
    ---@param self DefaultProjectileWeapon
    OnDestroy = function(self)
        Weapon.OnDestroy(self)
        ChangeState(self, self.DeadState)
    end,

    -- Checks to see if the weapon is allowed to fire
    ---@param self DefaultProjectileWeapon
    ---@return boolean
    CanWeaponFire = function(self)
        return self.WeaponCanFire
    end,

    -- Present for Overcharge to hook into
    ---@param self DefaultProjectileWeapon
    OnWeaponFired = function(self)
    end,

    -- I think this is triggered whenever the state changes to anything but DeadState
    ---@param self DefaultProjectileWeapon
    OnEnterState = function(self)
        local weaponWantEnabled = self.WeaponWantEnabled
        local weaponIsEnabled = self.WeaponIsEnabled
        if weaponWantEnabled and not weaponIsEnabled then
            self.WeaponIsEnabled = true
            self:SetWeaponEnabled(true)
        elseif not weaponWantEnabled and weaponIsEnabled then
            local bp = self.Blueprint
            if bp.CountedProjectile ~= true then
                self.WeaponIsEnabled = false
                self:SetWeaponEnabled(false)
            end
        end

        local weaponAimWantEnabled = self.WeaponAimWantEnabled
        local weaponAimIsEnabled = self.WeaponAimIsEnabled
        if weaponAimWantEnabled and not weaponAimIsEnabled then
            self.WeaponAimIsEnabled = true
            self:AimManipulatorSetEnabled(true)
        elseif not weaponAimWantEnabled and weaponAimIsEnabled then
            self.WeaponAimIsEnabled = false
            self:AimManipulatorSetEnabled(false)
        end
    end,

    -- Weapon States

    -- Idle state is when the weapon has no target and is done with any animations or unpacking
    IdleState = State {
        WeaponWantEnabled = true,
        WeaponAimWantEnabled = true,

        Main = function(self)
            local unit = self.unit
            if unit.Dead then return end
            unit:SetBusy(false)
            self:WaitForAndDestroyManips()

            local bp = self.Blueprint
            for _, rack in bp.RackBones do
                if rack.HideMuzzle then
                    for _, muzzle in rack.MuzzleBones do
                        unit:ShowBone(muzzle, true)
                    end
                end
            end
            self:StartEconomyDrain()
            if self.NumRackBones > 1 and self.CurrentRackSalvoNumber > 1 then
                WaitSeconds(bp.RackReloadTimeout)
                self:PlayFxRackSalvoReloadSequence()
                self.CurrentRackSalvoNumber = 1
            end
        end,

        OnGotTarget = function(self)
            Weapon.OnGotTarget(self)
            local unit = self.unit

            if unit then
                unit:OnGotTarget(self)
            end

            local bp = self.Blueprint
            if not bp.WeaponUnpackLockMotion or (bp.WeaponUnpackLocksMotion and not self.unit:IsUnitState('Moving')) then
                if bp.CountedProjectile and not self:CanFire() then
                    return
                end
                if bp.WeaponUnpacks then
                    ChangeState(self, self.WeaponUnpackingState)
                else
                    if bp.RackSalvoChargeTime and bp.RackSalvoChargeTime > 0 then
                        ChangeState(self, self.RackSalvoChargeState)
                    else
                        ChangeState(self, self.RackSalvoFireReadyState)
                    end
                end
            end
        end,

        OnFire = function(self)
            local bp = self.Blueprint
            if bp.WeaponUnpacks then
                ChangeState(self, self.WeaponUnpackingState)
            else
                if bp.RackSalvoChargeTime and bp.RackSalvoChargeTime > 0 then
                    ChangeState(self, self.RackSalvoChargeState)

                -- SkipReadyState used for Janus and Corsair
                elseif bp.SkipReadyState and bp.SkipReadyState then
                    ChangeState(self, self.RackSalvoFiringState)
                else
                    ChangeState(self, self.RackSalvoFireReadyState)
                end
            end
        end,
    },

    -- This state is for when the weapon is charging before firing
    RackSalvoChargeState = State {
        WeaponWantEnabled = true,
        WeaponAimWantEnabled = true,

        Main = function(self)
            local unit = self.unit
            local bp = self.Blueprint
            local notExclusive = bp.NotExclusive
            unit:SetBusy(true)
            self:PlayFxRackSalvoChargeSequence()

            if notExclusive then
                unit:SetBusy(false)
            end
            WaitSeconds(bp.RackSalvoChargeTime)

            if notExclusive then
                unit:SetBusy(true)
            end

            if bp.RackSalvoFiresAfterCharge then
                ChangeState(self, self.RackSalvoFiringState)
            else
                ChangeState(self, self.RackSalvoFireReadyState)
            end
        end,

        OnFire = function(self)
        end,
    },

    -- This state is for when the weapon is ready to fire
    RackSalvoFireReadyState = State {
        WeaponWantEnabled = true,
        WeaponAimWantEnabled = true,

        Main = function(self)
            -- We change the state on counted projectiles because we won't get another OnFire call.
            -- The second part is a hack for units with reload animations.  They have the same problem
            -- they need a RackSalvoReloadTime that's 1/RateOfFire set to avoid firing twice on the first shot
            local unit = self.unit
            local bp = self.Blueprint
            if bp.CountedProjectile and bp.WeaponUnpacks then
                unit:SetBusy(true)
            else
                unit:SetBusy(false)
            end

            self.WeaponCanFire = true
            local econDrain = self.EconDrain
            if econDrain then
                self.WeaponCanFire = false
                WaitFor(econDrain)
                self.WeaponCanFire = true
            end

            -- This code has the effect of forcing a unit to wait on its firing state to change from Hold Fire
            -- before resuming the sequence from this point
            -- Introduced to fix a bug where units with this bp flag would go straight to projectile creation
            -- from OnGotTarget, without waiting for OnFire() to be called from engine.
            if bp.CountedProjectile or bp.AnimationReload then
                while unit:GetFireState() == 1 do
                    WaitTicks(1)

                end

                ChangeState(self, self.RackSalvoFiringState)
            end

            -- To prevent weapon getting stuck targeting something out of fire range but withing tracking radius
            WaitSeconds(5)

            -- Check if there is a better target nearby
            self:ResetTarget()
        end,

        OnFire = function(self)
            if self.WeaponCanFire then
                ChangeState(self, self.RackSalvoFiringState)
            end
        end,
    },

    -- This state is for when the weapon is actually in the process of firing
    RackSalvoFiringState = State {
        WeaponWantEnabled = true,
        WeaponAimWantEnabled = true,

        -- Render the fire recharge bar
        RenderClockThread = function(self, rof)
            local unit = self.unit
            local clockTime = math.round(10 * rof)
            local totalTime = clockTime
            while clockTime >= 0 and
                  not self:BeenDestroyed() and
                  not unit.Dead do
                unit:SetWorkProgress(1 - clockTime / totalTime)
                clockTime = clockTime - 1
                WaitSeconds(0.1)
            end
        end,

        Main = function(self)
            local unit = self.unit
            unit:SetBusy(true)
            self:DestroyRecoilManips()

            local bp = self.Blueprint
            local rof = self:GetWeaponRoF()
            local rackBoneCount = self.NumRackBones
            local muzzleCharge = bp.Audio.MuzzleChargeStart
            local countedProjectile = bp.CountedProjectile
            local salvoDelay = bp.MuzzleSalvoDelay or 0
            local chargeDelay = bp.MuzzleChargeDelay or 0
            local salvoSize = bp.MuzzleSalvoSize
            local notExclusive = bp.NotExclusive
            local rackBones = bp.RackBones

            local numRackFiring = self.CurrentRackSalvoNumber
            --This is done to make sure that when racks should fire together, they do
            if bp.RackFireTogether then
                numRackFiring = rackBoneCount
            end

            -- Fork timer counter thread carefully
            if not self:BeenDestroyed() and
               not unit.Dead then
                if bp.RenderFireClock and rof > 0 then
                    self:ForkThread(self.RenderClockThread, 1 / rof)
                end
            end

            -- Most of the time this will only run once, the only time it doesn't is when racks fire together
            while self.CurrentRackSalvoNumber <= numRackFiring and not self.HaltFireOrdered do
                local rack = rackBones[self.CurrentRackSalvoNumber]
                local muzzleBones = rack.MuzzleBones
                local muzzleBoneCount = table.getn(muzzleBones)
                local numMuzzlesFiring = salvoSize
                local rackHideMuzzle = rack.HideMuzzle

                if salvoDelay == 0 then
                    numMuzzlesFiring = muzzleBoneCount
                end

                if bp.FixedSpreadRadius then
                    local weaponPos = unit:GetPosition()
                    local targetPos = self:GetCurrentTargetPos()
                    local distance = VDist2(weaponPos[1], weaponPos[3], targetPos[1], targetPos[3])

                    -- This formula was obtained empirically and somehow it works :)
                    local randomness = 12 * bp.FixedSpreadRadius / distance

                    self:SetFiringRandomness(randomness)
                end

                local muzzleIndex = 1
                for i = 1, numMuzzlesFiring do
                    if self.HaltFireOrdered then
                        break
                    end
                    self.CurrentSalvoNumber = i
                    local muzzle = muzzleBones[muzzleIndex]
                    if rackHideMuzzle then
                        unit:ShowBone(muzzle, true)
                    end
                    -- Deal with Muzzle charging sequence
                    if chargeDelay > 0 then
                        if muzzleCharge then
                            self:PlaySound(muzzleCharge)
                        end
                        self:PlayFxMuzzleChargeSequence(muzzle)
                        if notExclusive then
                            unit:SetBusy(false)
                        end
                        WaitSeconds(chargeDelay)

                        if notExclusive then
                            unit:SetBusy(true)
                        end
                    end
                    self:PlayFxMuzzleSequence(muzzle)
                    if rackHideMuzzle then
                        unit:HideBone(muzzle, true)
                    end
                    if self.HaltFireOrdered then
                        break
                    end

                    local proj = self:CreateProjectileAtMuzzle(muzzle)

                    -- Decrement the ammo if they are a counted projectile
                    if proj and not proj:BeenDestroyed() and countedProjectile then
                        if bp.NukeWeapon then
                            unit:NukeCreatedAtUnit()

                            -- Generate UI notification for automatic nuke ping
                            local launchData = {
                                army = self.Army - 1,
                                location = self:GetCurrentTargetPos()
                            }
                            if not Sync.NukeLaunchData then
                                Sync.NukeLaunchData = {}
                            end
                            table.insert(Sync.NukeLaunchData, launchData)
                            unit:RemoveNukeSiloAmmo(1)
                        else
                            unit:RemoveTacticalSiloAmmo(1)
                        end
                    end

                    -- Deal with muzzle firing sequence
                    muzzleIndex = muzzleIndex + 1
                    if muzzleIndex > muzzleBoneCount then
                        muzzleIndex = 1
                    end
                    if salvoDelay > 0 then
                        if notExclusive then
                            unit:SetBusy(false)
                        end
                        WaitSeconds(salvoDelay)

                        if notExclusive then
                            unit:SetBusy(true)
                        end
                    end
                end
                self.CurrentSalvoData = nil -- once the salvo is done, reset the data
                self:PlayFxRackReloadSequence()
                local currentRackSalvoNumber = self.CurrentRackSalvoNumber
                if currentRackSalvoNumber <= rackBoneCount then
                    self.CurrentRackSalvoNumber = currentRackSalvoNumber + 1
                end
            end

            self:DoOnFireBuffs()    -- Found in mohodata weapon.lua
            self.FirstShot = false
            self:StartEconomyDrain()
            self:OnWeaponFired()    -- Used primarily by Overcharge

            -- We can fire again after reaching here
            self.HaltFireOrdered = false

            -- Deal with the rack firing sequence
            if self.CurrentRackSalvoNumber > rackBoneCount then
                self.CurrentRackSalvoNumber = 1
                if bp.RackSalvoReloadTime > 0 then
                    ChangeState(self, self.RackSalvoReloadState)
                elseif bp.RackSalvoChargeTime > 0 then
                    ChangeState(self, self.IdleState)
                elseif countedProjectile and bp.WeaponUnpacks then
                    ChangeState(self, self.WeaponPackingState)
                elseif countedProjectile and not bp.WeaponUnpacks then
                    ChangeState(self, self.IdleState)
                else
                    ChangeState(self, self.RackSalvoFireReadyState)
                end
            elseif countedProjectile and not bp.WeaponUnpacks then
                ChangeState(self, self.IdleState)
            elseif countedProjectile and bp.WeaponUnpacks then
                ChangeState(self, self.WeaponPackingState)
            else
                ChangeState(self, self.RackSalvoFireReadyState)
            end
        end,

        OnLostTarget = function(self)
            Weapon.OnLostTarget(self)
            if self.Blueprint.WeaponUnpacks then
                ChangeState(self, self.WeaponPackingState)
            end
        end,

        -- Set a bool so we won't fire if the target reticle is moved
        OnHaltFire = function(self)
            self.HaltFireOrdered = true
        end,
    },

    -- This state is for when the weapon is reloading
    RackSalvoReloadState = State {
        WeaponWantEnabled = true,
        WeaponAimWantEnabled = true,

        Main = function(self)
            local unit = self.unit
            unit:SetBusy(true)
            self:PlayFxRackSalvoReloadSequence()

            local bp = self.Blueprint
            local notExclusive = bp.NotExclusive

            if notExclusive then
                unit:SetBusy(false)
            end
            WaitSeconds(bp.RackSalvoReloadTime)

            self:WaitForAndDestroyManips()

            if notExclusive then
                unit:SetBusy(true)
            end
            local hasTarget = self:WeaponHasTarget()
            local canFire = self:CanFire()
            if hasTarget and bp.RackSalvoChargeTime > 0 and canFire then
                ChangeState(self, self.RackSalvoChargeState)
            elseif hasTarget and canFire then
                ChangeState(self, self.RackSalvoFireReadyState)
            elseif not hasTarget and bp.WeaponUnpacks and not bp.WeaponUnpackLocksMotion then
                ChangeState(self, self.WeaponPackingState)
            else
                ChangeState(self, self.IdleState)
            end
        end,

        OnFire = function(self)
        end,
    },

    -- This state is for weapons which have to unpack before firing
    WeaponUnpackingState = State {
        WeaponWantEnabled = false,
        WeaponAimWantEnabled = false,

        Main = function(self)
            local unit = self.unit
            unit:SetBusy(true)

            local bp = self.Blueprint
            if bp.WeaponUnpackLocksMotion then
                unit:SetImmobile(true)
            end
            self:PlayFxWeaponUnpackSequence()

            local rackSalvoChargeTime = bp.RackSalvoChargeTime
            if rackSalvoChargeTime and rackSalvoChargeTime > 0 then
                ChangeState(self, self.RackSalvoChargeState)
            else
                ChangeState(self, self.RackSalvoFireReadyState)
            end
        end,

        OnFire = function(self)
        end,
    },

    -- This state is for weapons which have to pack up before moving or whatever
    WeaponPackingState = State {
        WeaponWantEnabled = true,
        WeaponAimWantEnabled = true,

        Main = function(self)
            local unit = self.unit
            unit:SetBusy(true)

            local bp = self.Blueprint
            WaitSeconds(bp.WeaponRepackTimeout)

            self:AimManipulatorSetEnabled(false)
            self:PlayFxWeaponPackSequence()
            if bp.WeaponUnpackLocksMotion then
                unit:SetImmobile(false)
            end
            ChangeState(self, self.IdleState)
        end,

        OnGotTarget = function(self)
            Weapon.OnGotTarget(self)

            -- Issue 43
            local unit = self.unit
            if unit then
                unit:OnGotTarget(self)
            end

            if not self.Blueprint.ForceSingleFire then
                ChangeState(self, self.WeaponUnpackingState)
            end
        end,

        OnFire = function(self)
            local bp = self.Blueprint
            if bp.CountedProjectile and not bp.ForceSingleFire then
                ChangeState(self, self.WeaponUnpackingState)
            end
        end,

    },

    -- This state is entered only when the owner of the weapon is dead
    DeadState = State {
        OnEnterState = function(self)
        end,

        Main = function(self)
        end,
    },
}

---@class KamikazeWeapon : Weapon
KamikazeWeapon = ClassWeapon(Weapon) {
    ---@param self KamikazeWeapon
    OnFire = function(self)
        local unit = self.unit
        local bp = self.Blueprint
        DamageArea(unit, unit:GetPosition(), bp.DamageRadius, bp.Damage, bp.DamageType or 'Normal', bp.DamageFriendly or false)
        unit:PlayUnitSound('Destroyed')
        unit:Destroy()
    end,
}

---@class BareBonesWeapon : Weapon
BareBonesWeapon = ClassWeapon(Weapon) {
    Data = {},

    ---@param self BareBonesWeapon
    OnFire = function(self)
        local bp = self.Blueprint
        local proj = self.unit:CreateProjectile(bp.ProjectileId, 0, 0, 0, nil, nil, nil):SetCollision(false)
        local data = self.data
        if data then
            proj:PassData(data)
        end
    end,
}

---@class OverchargeWeapon : DefaultProjectileWeapon
OverchargeWeapon = ClassWeapon(DefaultProjectileWeapon) {
    NeedsUpgrade = false,
    AutoMode = false,
    AutoThread = nil,
    EnergyRequired = nil,

    ---@param self OverchargeWeapon
    ---@return boolean
    HasEnergy = function(self)
        return self.Brain:GetEconomyStored('ENERGY') >= self.EnergyRequired
    end,

    -- Can we use the OC weapon?
    ---@param self OverchargeWeapon
    ---@return boolean
    CanOvercharge = function(self)
        local unit = self.unit
        return not unit:IsOverchargePaused() and self:HasEnergy() and not
            self:UnitOccupied() and not
            unit:IsUnitState('Enhancing') and not
            unit:IsUnitState('Upgrading')
    end,

    ---@param self OverchargeWeapon
    StartEconomyDrain = function(self) -- OverchargeWeapon drains energy on impact
    end,

    -- Returns true if the unit is doing something that shouldn't allow any weapon fire
    ---@param self OverchargeWeapon
    ---@return boolean
    UnitOccupied = function(self)
        local unit = self.unit
        return (unit:IsUnitState('Upgrading') and not unit:IsUnitState('Enhancing')) or -- Don't let us shoot if we're upgrading, unless it's an enhancement task
            unit:IsUnitState('Building') or
            unit:IsUnitState('Repairing') or
            unit:IsUnitState('Reclaiming')
    end,

    -- The Overcharge cool-down function
    ---@param self OverchargeWeapon
    PauseOvercharge = function(self)
        local unit = self.unit
        if not unit:IsOverchargePaused() then
            unit:SetOverchargePaused(true)
            self:OnDisableWeapon()
            WaitSeconds(1 / self.Blueprint.RateOfFire)
            self.unit:SetOverchargePaused(false)
            if self.AutoMode then
                self.AutoThread = self:ForkThread(self.AutoEnable)
            end
        end
    end,

    ---@param self OverchargeWeapon
    AutoEnable = function(self)
        while not self:CanOvercharge() do
            WaitSeconds(0.1)

        end

        if self.AutoMode then
            self:OnEnableWeapon()
        end
    end,

    ---@param self OverchargeWeapon
    ---@param auto boolean
    SetAutoOvercharge = function(self, auto)
        self.AutoMode = auto

        if self.AutoMode then
            self.AutoThread = self:ForkThread(self.AutoEnable)
        else
            local autoThread = self.AutoThread
            if autoThread then
                KillThread(autoThread)
                self.AutoThread = nil
            end
            if self.enabled then
                self:OnDisableWeapon()
            end
        end
    end,

    ---@param self OverchargeWeapon
    OnCreate = function(self)
        DefaultProjectileWeapon.OnCreate(self)
        self.EnergyRequired = self.Blueprint.EnergyRequired
        self:SetWeaponEnabled(false)
        local aimControl = self.AimControl
        aimControl:SetEnabled(false)
        aimControl:SetPrecedence(0)
        self.unit:SetOverchargePaused(false)
    end,

    ---@param self OverchargeWeapon
    OnGotTarget = function(self)
        if self:CanOvercharge() then
            DefaultProjectileWeapon.OnGotTarget(self)
        else
            self:OnDisableWeapon()
        end
    end,

    ---@param self OverchargeWeapon
    OnFire = function(self)
        if self:CanOvercharge() then
            DefaultProjectileWeapon.OnFire(self)
        else
            self:OnDisableWeapon()
        end
    end,

    ---@param self OverchargeWeapon
    ---@return boolean
    IsEnabled = function(self)
        return self.enabled
    end,

    ---@param self OverchargeWeapon
    OnEnableWeapon = function(self)
        if self:BeenDestroyed() then return end
        DefaultProjectileWeapon.OnEnableWeapon(self)
        local unit = self.unit
        local weaponLabel = self.DesiredWeaponLabel
        local aimControl = self.AimControl
        self:SetWeaponEnabled(true)
        if self:CanOvercharge() then
            unit:SetWeaponEnabledByLabel(weaponLabel, false)
        end
        unit:BuildManipulatorSetEnabled(false)
        aimControl:SetEnabled(true)
        aimControl:SetPrecedence(20)
        unit.BuildArmManipulator:SetPrecedence(0)
        aimControl:SetHeadingPitch(unit:GetWeaponManipulatorByLabel(weaponLabel):GetHeadingPitch())
        self.enabled = true
    end,

    ---@param self OverchargeWeapon
    OnDisableWeapon = function(self)
        local unit = self.unit
        if unit:BeenDestroyed() then return end
        self:SetWeaponEnabled(false)
        local weaponLabel = self.DesiredWeaponLabel
        local aimControl = self.AimControl
        -- Only allow it to turn on the primary weapon if the unit is ready
        if not self:UnitOccupied() then
            unit:SetWeaponEnabledByLabel(weaponLabel, true)
        end

        unit:BuildManipulatorSetEnabled(false)
        aimControl:SetEnabled(false)
        aimControl:SetPrecedence(0)
        unit.BuildArmManipulator:SetPrecedence(0)
        unit:GetWeaponManipulatorByLabel(weaponLabel):SetHeadingPitch(aimControl:GetHeadingPitch())

        self.enabled = false
    end,

    ---@param self OverchargeWeapon
    OnWeaponFired = function(self)
        DefaultProjectileWeapon.OnWeaponFired(self)
        self:ForkThread(self.PauseOvercharge)
    end,

    -- Weapon State Modifications
    IdleState = State(DefaultProjectileWeapon.IdleState) {
        OnGotTarget = function(self)
            if self:CanOvercharge() then
                DefaultProjectileWeapon.IdleState.OnGotTarget(self)
            else
                self:ForkThread(function()
                    while self.enabled and not self:CanOvercharge() do
                        WaitSeconds(0.1)
                    end

                    if self.enabled then
                        self:OnGotTarget()
                    end
                end)
            end
        end,

        OnFire = function(self)
            if self:CanOvercharge() then
                ChangeState(self, self.RackSalvoFiringState)
            else
                self:OnDisableWeapon()
            end
        end,
    },

    RackSalvoFireReadyState = State(DefaultProjectileWeapon.RackSalvoFireReadyState) {
        OnFire = function(self)
            if self:CanOvercharge() then
                DefaultProjectileWeapon.RackSalvoFireReadyState.OnFire(self)
            else
                self:OnDisableWeapon()
            end
        end,
    }
}

---@class DefaultBeamWeapon : DefaultProjectileWeapon
DefaultBeamWeapon = ClassWeapon(DefaultProjectileWeapon) {
    BeamType = CollisionBeam,

    ---@param self DefaultBeamWeapon
    OnCreate = function(self)
        DefaultProjectileWeapon.OnCreate(self)

        self.Beams = {}

        -- Ensure that the weapon blueprint is set up properly for beams
        local bp = self.Blueprint
        if not bp.BeamCollisionDelay then
            local strg = '*ERROR: No BeamCollisionDelay specified for beam weapon, aborting setup.  Weapon: ' .. bp.DisplayName .. ' on Unit: ' .. self.unit.UnitId
            error(strg, 2)
            return
        end
        if not bp.BeamLifetime then
            local strg = '*ERROR: No BeamLifetime specified for beam weapon, aborting setup.  Weapon: ' .. bp.DisplayName .. ' on Unit: ' .. self.unit.UnitId
            error(strg, 2)
            return
        end

        -- Create the beam
        for _, rack in bp.RackBones do
            for _, muzzle in rack.MuzzleBones do
                local beam
                beam = self.BeamType{
                    Weapon = self,
                    BeamBone = 0,
                    OtherBone = muzzle,
                    CollisionCheckInterval = bp.BeamCollisionDelay * 10,    -- Why is this multiplied by 10? IceDreamer
                }
                local beamTable = {Beam = beam, Muzzle = muzzle, Destroyables = {}}
                table.insert(self.Beams, beamTable)
                self.Trash:Add(beam)
                beam:SetParentWeapon(self)
                beam:Disable()
            end
        end
    end,

    OnDestroy = function(self)
        DefaultProjectileWeapon.OnDestroy(self)
        for k, info in self.Beams do
            info.Beam:Destroy()
        end
    end,

    -- This entirely overrides the default
    ---@param self DefaultBeamWeapon
    ---@param muzzle string
    CreateProjectileAtMuzzle = function(self, muzzle)
        local enabled = false
        for _, beam in self.Beams do
            if beam.Muzzle == muzzle and beam.Beam:IsEnabled() then
                enabled = true
                break
            end
        end
        if not enabled then
            self:PlayFxBeamStart(muzzle)
        end

        local audio = self.Blueprint.Audio
        if self.unit.Layer == 'Water' and audio.FireUnderWater then
            self:PlaySound(audio.FireUnderWater)
        elseif audio.Fire then
            self:PlaySound(audio.Fire)
        end
    end,

    ---@param self DefaultBeamWeapon
    ---@param muzzle string
    PlayFxBeamStart = function(self, muzzle)
        local bp = self.Blueprint
        local beam
        self.BeamDestroyables = {}

        for _, v in self.Beams do
            if v.Muzzle == muzzle then
                beam = v.Beam
            end
        end
        if not beam then
            error('*ERROR: We have a beam created that does not coincide with a muzzle bone.  Internal Error, aborting beam weapon.', 2)
            return
        end

        if beam:IsEnabled() then return end
        beam:Enable()
        self.Trash:Add(beam)

        -- Deal with continuous and non-continuous beams
        if bp.BeamLifetime > 0 then
            self:ForkThread(self.BeamLifetimeThread, beam, bp.BeamLifetime or 1)    -- Non-continuous only
        end
        if bp.BeamLifetime == 0 then
            self.HoldFireThread = self:ForkThread(self.WatchForHoldFire, beam)      -- Continuous only
        end

        local audio = bp.Audio
        local beamStart = audio.BeamStart
        -- Deal with beam audio cues
        if beamStart then
            self:PlaySound(beamStart)
        end
        local beamLoop = audio.BeamLoop
        if beamLoop then
            -- should be `beam.Beam` but `PlayFxBeamEnd` wouldn't get enough muzzle info to stop the sound
            local b = self.Beams[1].Beam
            if b then
                b:SetAmbientSound(beamLoop, nil)
            end
        end
        self.BeamStarted = true
    end,

    -- Kill the beam if hold fire is requested
    ---@param self DefaultBeamWeapon
    ---@param beam CollisionBeam
    WatchForHoldFire = function(self, beam)
        local unit = self.unit
        local hasTargetPrev = true
        while not (IsDestroyed(self) or IsDestroyed(unit)) do

            local hasTarget = self:GetCurrentTarget() != nil
            if   -- check for hold fire
                (unit:GetFireState() == 1) or
                 -- check if we have a target still, relevant for beam weapons that work indefinitely
                (not (hasTarget or hasTargetPrev))
            then
                self.BeamStarted = false
                self:PlayFxBeamEnd(beam)
            end

            hasTargetPrev = hasTarget
            WaitSeconds(0.5)
        end
    end,

    -- Force the beam to last the proper amount of time
    ---@param self DefaultBeamWeapon
    ---@param beam any
    ---@param lifeTime number
    BeamLifetimeThread = function(self, beam, lifeTime)
        WaitSeconds(lifeTime)
        WaitTicks(1)
        self:PlayFxBeamEnd(beam)
    end,

    ---@param self DefaultBeamWeapon
    PlayFxWeaponUnpackSequence = function(self)
        -- If it's not a continuous beam, or if it's a continuous beam that's off
        local beamLifetime = self.Blueprint.BeamLifetime
        if beamLifetime > 0 or (beamLifetime == 0 and not self.ContBeamOn) then
            DefaultProjectileWeapon.PlayFxWeaponUnpackSequence(self)
        end
    end,

    -- Kill the beam
    ---@param self DefaultBeamWeapon
    ---@param beam any
    PlayFxBeamEnd = function(self, beam)
        if not self.unit.Dead then
            local audio = self.Blueprint.Audio
            local beamStop = audio.BeamStop
            if beamStop and self.BeamStarted then
                self:PlaySound(beamStop)
            end
            -- see starting comments
            local firstBeam = self.Beams[1].Beam
            if audio.BeamLoop and firstBeam then
                firstBeam:SetAmbientSound(nil, nil)
            end
            if beam then
                beam:Disable()
            else
                for _, b in self.Beams do
                    b.Beam:Disable()
                end
            end
            self.BeamStarted = false
        end
        local thread = self.HoldFireThread
        if thread then
            KillThread(thread)
        end
    end,

    ---@param self DefaultBeamWeapon
    StartEconomyDrain = function(self)
        if  not self.EconDrain and
            self.EnergyRequired and
            self.EnergyDrainPerSecond and
            not self:EconomySupportsBeam()
        then
            return
        end
        DefaultProjectileWeapon.StartEconomyDrain(self)
    end,

    ---@param self DefaultBeamWeapon
    OnHaltFire = function(self)
        for _, beam in self.Beams do
            -- Only halt fire on the beams that are currently enabled
            local b = beam.Beam
            if not b:IsEnabled() then
                continue
            end
            self:PlayFxBeamEnd(b)
        end
    end,

    -- Weapon States Section

    IdleState = State (DefaultProjectileWeapon.IdleState) {
        Main = function(self)
            DefaultProjectileWeapon.IdleState.Main(self)
            self:PlayFxBeamEnd()
            self:ForkThread(self.ContinuousBeamFlagThread)
        end,
    },

    WeaponPackingState = State (DefaultProjectileWeapon.WeaponPackingState) {
        Main = function(self)
            local bp = self.Blueprint
            if bp.BeamLifetime > 0 then
                self:PlayFxBeamEnd()
            else
                self.ContBeamOn = true
            end
            DefaultProjectileWeapon.WeaponPackingState.Main(self)
        end,
    },

    ---@param self DefaultBeamWeapon
    ContinuousBeamFlagThread = function(self)
        WaitTicks(1)
        self.ContBeamOn = false
    end,

    RackSalvoFireReadyState = State (DefaultProjectileWeapon.RackSalvoFireReadyState) {
        Main = function(self)
            if not self:EconomySupportsBeam() then
                self:PlayFxBeamEnd()
                ChangeState(self, self.IdleState)
                return
            end
            DefaultProjectileWeapon.RackSalvoFireReadyState.Main(self)
        end,
    },

    ---@param self DefaultBeamWeapon
    ---@return boolean
    EconomySupportsBeam = function(self)
        local aiBrain = self.Brain
        local energyIncome = aiBrain:GetEconomyIncome('ENERGY') * 10
        local energyStored = aiBrain:GetEconomyStored('ENERGY')
        local energyReq = self:GetWeaponEnergyRequired()
        local energyDrain = self:GetWeaponEnergyDrain()

        if energyStored < energyReq and energyIncome < energyDrain then
            return false
        end
        return true
    end,
}

local NukeDamage = import("/lua/sim/nukedamage.lua").NukeAOE
---@class DeathNukeWeapon : BareBonesWeapon
DeathNukeWeapon = ClassWeapon(BareBonesWeapon) {

    ---@param self DeathNukeWeapon
    OnFire = function(self)
    end,

    ---@param self DeathNukeWeapon
    Fire = function(self)
        local bp = self.Blueprint
        local launcher = self.unit
        local proj = launcher:CreateProjectile(bp.ProjectileId, 0, 0, 0, nil, nil, nil):SetCollision(false)
        proj:ForkThread(proj.EffectThread)

        -- Play the explosion sound
        local audNukeExplosion = proj.Blueprint.Audio.NukeExplosion
        if audNukeExplosion then
            self:PlaySound(audNukeExplosion)
        end

        proj.InnerRing = NukeDamage()
        proj.InnerRing:OnCreate(bp.NukeInnerRingDamage, bp.NukeInnerRingRadius, bp.NukeInnerRingTicks, bp.NukeInnerRingTotalTime)
        proj.OuterRing = NukeDamage()
        proj.OuterRing:OnCreate(bp.NukeOuterRingDamage, bp.NukeOuterRingRadius, bp.NukeOuterRingTicks, bp.NukeOuterRingTotalTime)

        local pos = proj:GetPosition()
        local brain = launcher:GetAIBrain()
        local damageType = bp.DamageType
        local army = launcher.Army
        proj.InnerRing:DoNukeDamage(launcher, pos, brain, army, damageType)
        proj.OuterRing:DoNukeDamage(launcher, pos, brain, army, damageType)

        -- Stop it calling DoDamage any time in the future.
        proj.DoDamage = function(self, instigator, DamageData, targetEntity) end
    end,
}

---@class SCUDeathWeapon : BareBonesWeapon
SCUDeathWeapon = ClassWeapon(BareBonesWeapon) {
    ---@param self SCUDeathWeapon
    OnFire = function(self)
    end,

    ---@param self SCUDeathWeapon
    Fire = function(self)
        local bp = self.Blueprint
        local proj = self.unit:CreateProjectile(bp.ProjectileId, 0, 0, 0, nil, nil, nil):SetCollision(false)
        proj:PassDamageData(self:GetDamageTable())
    end,
}

-- kept for mod backwards compatibility
local XZDist = import("/lua/utilities.lua").XZDistanceTwoVectors