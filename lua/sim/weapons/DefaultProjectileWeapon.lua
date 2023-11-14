--**********************************************************************************
--** Copyright (c) 2023 FAForever
--**
--** Permission is hereby granted, free of charge, to any person obtaining a copy
--** of this software and associated documentation files (the "Software"), to deal
--** in the Software without restriction, including without limitation the rights
--** to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
--** copies of the Software, and to permit persons to whom the Software is
--** furnished to do so, subject to the following conditions:
--**
--** The above copyright notice and this permission notice shall be included in all
--** copies or substantial portions of the Software.
--**
--** THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
--** IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
--** FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
--** AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
--** LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
--** OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
--** SOFTWARE.
--**********************************************************************************
local Weapon = import('/lua/sim/Weapon.lua').Weapon
local WeaponOnCreate = Weapon.OnCreate
local WeaponOnGotTarget = Weapon.OnGotTarget
local WeaponOnLostTarget = Weapon.OnLostTarget
local WeaponOnDestroy = Weapon.OnDestroy
local WeaponOnMotionHorzEventChange = Weapon.OnMotionHorzEventChange

-- upvalue scope for performance
local WaitFor = WaitFor
local WaitTicks = WaitTicks
local WaitSeconds = WaitSeconds

local VDist2 = VDist2
local ForkThread = ForkThread
local ChangeState = ChangeState
local GetSurfaceHeight = GetSurfaceHeight

local CreateSlider = CreateSlider
local CreateAnimator = CreateAnimator

local CreateAttachedEmitter = CreateAttachedEmitter

local EntityMethods = moho.entity_methods
local EntityGetPosition = EntityMethods.GetPosition
local EntityGetPositionXYZ = EntityMethods.GetPositionXYZ

local UnitMethods = moho.unit_methods
local UnitGetVelocity = UnitMethods.GetVelocity
local UnitGetTargetEntity = UnitMethods.GetTargetEntity

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
---@field WeaponPackState 'Packed' | 'Unpacked' | 'Unpacking' | 'Packing'
DefaultProjectileWeapon = ClassWeapon(Weapon) {

    FxRackChargeMuzzleFlash = { },
    FxRackChargeMuzzleFlashScale = 1,
    FxChargeMuzzleFlash = { },
    FxChargeMuzzleFlashScale = 1,
    FxMuzzleFlash = {
        '/effects/emitters/default_muzzle_flash_01_emit.bp',
        '/effects/emitters/default_muzzle_flash_02_emit.bp',
    },
    FxMuzzleFlashScale = 1,

    WeaponPackState = 'Packed',

    -- Called when the weapon is created, almost always when the owning unit is created
    ---@param self DefaultProjectileWeapon
    ---@return boolean
    OnCreate = function(self)
        WeaponOnCreate(self)

        local bp = self.Blueprint
        local rackBones = bp.RackBones
        local rackRecoilDist = bp.RackRecoilDistance
        local muzzleSalvoDelay = bp.MuzzleSalvoDelay
        local muzzleSalvoSize = bp.MuzzleSalvoSize

        self.WeaponCanFire = true

        -- Make certain the weapon has essential aspects defined
        if not rackBones then
            local strg = '*ERROR: No RackBones table specified, aborting weapon setup.  Weapon: ' ..
                bp.DisplayName .. ' on Unit: ' .. self.unit:GetUnitId()
            error(strg, 2)
            return
        end
        if not muzzleSalvoSize then
            local strg = '*ERROR: No MuzzleSalvoSize specified, aborting weapon setup.  Weapon: ' ..
                bp.DisplayName .. ' on Unit: ' .. self.unit:GetUnitId()
            error(strg, 2)
            return
        end
        if not muzzleSalvoDelay then
            local strg = '*ERROR: No MuzzleSalvoDelay specified, aborting weapon setup.  Weapon: ' ..
                bp.DisplayName .. ' on Unit: ' .. self.unit:GetUnitId()
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
            self.RackRecoilReturnSpeed = bp.RackRecoilReturnSpeed or
                math.abs(dist / ((1 / rof) - (bp.MuzzleChargeDelay or 0))) * 1.25
        end
        if rackRecoilDist ~= 0 and muzzleSalvoDelay ~= 0 then
            local strg = '*ERROR: You can not have a RackRecoilDistance with a MuzzleSalvoDelay not equal to 0, aborting weapon setup.  Weapon: '
                .. bp.DisplayName .. ' on Unit: ' .. self.unit:GetUnitId()
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
            local strg = '*ERROR: The total time to fire muzzles is longer than the RateOfFire allows, aborting weapon setup.  Weapon: '
                .. bp.DisplayName .. ' on Unit: ' .. self.unit:GetUnitId()
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
    ---@param muzzle Bone
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
        local projVelX, _, projVelZ = UnitGetVelocity(launcher)

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
                return 200 * projPosY / (time * time)
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

            local acc = halfHeight / (time * time)
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
        local acc = 200 * projPosY / (time * time)

        data.lastAccel = acc
        return acc
    end,

    -- Triggers when the weapon is moved horizontally, usually by owner's motion
    ---@param self DefaultProjectileWeapon
    ---@param new string
    ---@param old string
    OnMotionHorzEventChange = function(self, new, old)
        WeaponOnMotionHorzEventChange(self, new, old)

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
    ---@param muzzle Bone
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
        if cameraShakeRadius and cameraShakeRadius > 0 and
            cameraShakeMax and cameraShakeMax > 0 and
            cameraShakeMin and cameraShakeMin >= 0 and
            cameraShakeDuration and cameraShakeDuration > 0
        then
            self.unit:ShakeCamera(cameraShakeRadius, cameraShakeMax, cameraShakeMin, cameraShakeDuration)
        end
        if bp.RackRecoilDistance ~= 0 then
            self:PlayRackRecoil({ bp.RackBones[self.CurrentRackSalvoNumber] })
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
            self.WeaponPackState = 'Unpacking'
            WaitFor(unpackAnimator)
            self.WeaponPackState = 'Unpacked'
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

            self.WeaponPackState = 'Packing'
            WaitFor(unpackAnimator)
            self.WeaponPackState = 'Packed'
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

        local thread = ForkThread(self.PlayRackRecoilReturn, self, rackList)
        self.Trash:Add(thread)
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

        WeaponOnLostTarget(self)

        if self.Blueprint.WeaponUnpacks then
            ChangeState(self, self.WeaponPackingState)
        else
            ChangeState(self, self.IdleState)
        end
    end,

    -- Sends the weapon to DeadState, probably called by the Owner
    ---@param self DefaultProjectileWeapon
    OnDestroy = function(self)
        WeaponOnDestroy(self)
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

        StateName = 'IdleState',

        WeaponWantEnabled = true,
        WeaponAimWantEnabled = true,

        Main = function(self)
            local unit = self.unit
            if unit.Dead then return end
            unit:SetBusy(false)

            -- at this point salvo is always done so reset the data
            self.CurrentSalvoData = nil 

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
            WeaponOnGotTarget(self)

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
            if bp.WeaponUnpacks and self.WeaponPackState ~= 'Unpacked' then
                ChangeState(self, self.WeaponUnpackingState)
            else
                if bp.RackSalvoChargeTime and bp.RackSalvoChargeTime > 0 then
                    ChangeState(self, self.RackSalvoChargeState)

                    -- SkipReadyState used for Janus and Corsair
                elseif bp.SkipReadyState then
                    ChangeState(self, self.RackSalvoFiringState)
                else
                    ChangeState(self, self.RackSalvoFireReadyState)
                end
            end
        end,
    },

    -- This state is for when the weapon is charging before firing
    RackSalvoChargeState = State {

        StateName = 'RackSalvoChargeState',

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

        StateName = 'RackSalvoFireReadyState',

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

            -- Usually weapons with counted projectiles (TMLs, SMLs, SMDs) have a weapon unpacking / packing animation. As a result,
            -- once they reach this state they won't receive another 'OnFire' event from the engine. To help them fire anyway we
            -- manually force them proceed at this point

            if (bp.CountedProjectile) then

                -- But, as we're doing something unnatural we need to take into account the fire state. As an interesting side effect,
                -- this bit of logic allows for the 'Sync strike' feature to function

                -- prevent firing the weapon through `OnFire`
                self.WeaponCanFire = false

                while unit:GetFireState() == 1 do
                    WaitTicks(1)
                end

                -- now we're good and ready to fire as we see fit
                self.WeaponCanFire = true

                ChangeState(self, self.RackSalvoFiringState)
            end

            if not (IsDestroyed(unit) or IsDestroyed(self)) then
                if bp.TargetResetWhenReady then

                    -- attempts to fix weapons that intercept projectiles to being stuck on a projectile while reloading, preventing
                    -- other weapons from targeting that projectile. Is a side effect of the blueprint field `DesiredShooterCap`. For a more
                    -- aggressive version see the blueprint field `DisableWhileReloading` which completely disables the weapon

                    WaitTicks(5)

                    self:ResetTarget()
                else

                    -- attempts to fix units being stuck on targets that are outside their current attack radius, but inside
                    -- the tracking radius. This happens when the unit is trying to fire, but it is never actually firing and
                    -- therefore the thread of this state is not destroyed

                    -- wait reload time + 2 seconds, then force the weapon to recheck its target
                    WaitSeconds((1 / self.Blueprint.RateOfFire) + 3)
                    self:ResetTarget()
                end
            end
        end,

        OnFire = function(self)
            if self.WeaponCanFire then
                ChangeState(self, self.RackSalvoFiringState)
            end
        end,
    },

    -- This state is for when the weapon is actually in the process of firing
    RackSalvoFiringState = State {

        StateName = 'RackSalvoFiringState',

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
                            unit:RemoveNukeSiloAmmo(1)
                            -- Generate UI notification for automatic nuke ping
                            local launchData = {
                                army = self.Army - 1,
                                location = (GetFocusArmy() == -1 or IsAlly(self.Army, GetFocusArmy())) and self:GetCurrentTargetPos() or nil
                            }
                            if not Sync.NukeLaunchData then
                                Sync.NukeLaunchData = {}
                            end
                            table.insert(Sync.NukeLaunchData, launchData)
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

                self:PlayFxRackReloadSequence()
                local currentRackSalvoNumber = self.CurrentRackSalvoNumber
                if currentRackSalvoNumber <= rackBoneCount then
                    self.CurrentRackSalvoNumber = currentRackSalvoNumber + 1
                end
            end

            self:DoOnFireBuffs() -- Found in mohodata weapon.lua
            self.FirstShot = false
            self:StartEconomyDrain()
            self:OnWeaponFired() -- Used primarily by Overcharge

            -- We can fire again after reaching here
            self.HaltFireOrdered = false

            -- attempts to fix weapons that intercept projectiles to being stuck on a projectile while reloading, preventing
            -- other weapons from targeting that projectile. Is a side effect of the blueprint field `DesiredShooterCap`. This
            -- is the more aggressive variant of `TargetResetWhenReady` as it completely disables the weapon. Should only be used
            -- for weapons that do not visually track, such as torpedo defenses

            if bp.DisableWhileReloading then
                local reloadTime = math.floor(10 / self.Blueprint.RateOfFire) - 1
                if reloadTime > 4 then
                    self:SetEnabled(false)
                    WaitTicks(reloadTime)
                    self:SetEnabled(true)
                end
            end

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
            self.__base.OnLostTarget(self)
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

        StateName = 'RackSalvoReloadState',

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

        StateName = 'WeaponUnpackingState',

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

        StateName = 'WeaponPackingState',

        WeaponWantEnabled = true,
        WeaponAimWantEnabled = true,

        ---@param self DefaultProjectileWeapon
        Main = function(self)
            local unit = self.unit

            if not IsDestroyed(unit) then
                unit:SetBusy(true)
            end

            local bp = self.Blueprint
            WaitSeconds(bp.WeaponRepackTimeout)

            self:AimManipulatorSetEnabled(false)
            self:PlayFxWeaponPackSequence()
            if bp.WeaponUnpackLocksMotion then
                unit:SetImmobile(false)
            end
            ChangeState(self, self.IdleState)
        end,

        ---@param self DefaultProjectileWeapon
        OnGotTarget = function(self)
            Weapon.OnGotTarget(self)

            local unit = self.unit
            if unit then
                unit:OnGotTarget(self)
            end

            if not self.Blueprint.ForceSingleFire then
                ChangeState(self, self.WeaponUnpackingState)
            end
        end,

        ---@param self DefaultProjectileWeapon
        OnFire = function(self)
            local bp = self.Blueprint
            if  -- triggers when we use the distribute orders feature to distribute TMLs / SMLs launch orders
                self.WeaponPackState == 'Unpacking' or

                -- triggers when we fired a missile but we're still waiting for the pack animation to finish
                (bp.CountedProjectile and (not bp.ForceSingleFire))
            then
                ChangeState(self, self.WeaponUnpackingState)
            end
        end,

    },

    -- This state is entered only when the owner of the weapon is dead
    DeadState = State {

        StateName = 'DeadState',

        OnEnterState = function(self)
        end,

        Main = function(self)
        end,
    },
}