-----------------------------------------------------------------
-- File     :  /lua/sim/DefaultWeapons.lua
-- Author(s):  John Comes
-- Summary  :  Default definitions of weapons
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------
local Weapon = import('/lua/sim/Weapon.lua').Weapon
local CollisionBeam = import('/lua/sim/CollisionBeam.lua').CollisionBeam
local Game = import('/lua/game.lua')
local CalculateBallisticAcceleration = import('/lua/sim/CalcBallisticAcceleration.lua').CalculateBallisticAcceleration

-- Most weapons derive from this class, including beam weapons later in this file
DefaultProjectileWeapon = Class(Weapon) {

    FxRackChargeMuzzleFlash = {},
    FxRackChargeMuzzleFlashScale = 1,
    FxChargeMuzzleFlash = {},
    FxChargeMuzzleFlashScale = 1,
    FxMuzzleFlash = {
        '/effects/emitters/default_muzzle_flash_01_emit.bp',
        '/effects/emitters/default_muzzle_flash_02_emit.bp',
    },
    FxMuzzleFlashScale = 1,

    -- Called when the weapon is created, almost always when the owning unit is created
    OnCreate = function(self)

        Weapon.OnCreate(self)

        local bp = self:GetBlueprint()
        local rof = self:GetWeaponRoF()
        self.WeaponCanFire = true
        if bp.RackRecoilDistance ~= 0 then
            self.RecoilManipulators = {}
        end

        -- Make certain the weapon has essential aspects defined
        if not bp.RackBones then
           local strg = '*ERROR: No RackBones table specified, aborting weapon setup.  Weapon: ' .. bp.DisplayName .. ' on Unit: ' .. self.unit:GetUnitId()
           error(strg, 2)
           return
        end
        if not bp.MuzzleSalvoSize then
           local strg = '*ERROR: No MuzzleSalvoSize specified, aborting weapon setup.  Weapon: ' .. bp.DisplayName .. ' on Unit: ' .. self.unit:GetUnitId()
           error(strg, 2)
           return
        end
        if not bp.MuzzleSalvoDelay then
           local strg = '*ERROR: No MuzzleSalvoDelay specified, aborting weapon setup.  Weapon: ' .. bp.DisplayName .. ' on Unit: ' .. self.unit:GetUnitId()
           error(strg, 2)
           return
        end

        self.CurrentRackSalvoNumber = 1

        -- Calculate recoil speed so that it finishes returning just as the next shot is ready
        if bp.RackRecoilDistance ~= 0 then
            local dist = bp.RackRecoilDistance
            if bp.RackBones[1].TelescopeRecoilDistance then
                local tpDist = bp.RackBones[1].TelescopeRecoilDistance
                if math.abs(tpDist) > math.abs(dist) then
                    dist = tpDist
                end
            end
            self.RackRecoilReturnSpeed = bp.RackRecoilReturnSpeed or math.abs(dist / ((1 / rof) - (bp.MuzzleChargeDelay or 0))) * 1.25
        end

        -- Ensure firing cycle is compatible internally
        self.NumMuzzles = 0
        for rk, rv in bp.RackBones do
            self.NumMuzzles = self.NumMuzzles + table.getn(rv.MuzzleBones or 0)
        end
        self.NumMuzzles = self.NumMuzzles / table.getn(bp.RackBones)
        local totalMuzzleFiringTime = (self.NumMuzzles - 1) * bp.MuzzleSalvoDelay
        if totalMuzzleFiringTime > (1 / rof) then
            local strg = '*ERROR: The total time to fire muzzles is longer than the RateOfFire allows, aborting weapon setup.  Weapon: ' .. bp.DisplayName .. ' on Unit: ' .. self.unit:GetUnitId()
            error(strg, 2)
            return false
        end
        if bp.RackRecoilDistance ~= 0 and bp.MuzzleSalvoDelay ~= 0 then
            local strg = '*ERROR: You can not have a RackRecoilDistance with a MuzzleSalvoDelay not equal to 0, aborting weapon setup.  Weapon: ' .. bp.DisplayName .. ' on Unit: ' .. self.unit:GetUnitId()
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

        ChangeState(self, self.IdleState)
    end,

    -- This function creates the projectile, and happens when the unit is trying to fire
    -- Called from inside RackSalvoFiringState
    CreateProjectileAtMuzzle = function(self, muzzle)
        local proj = self:CreateProjectileForWeapon(muzzle)
        if not proj or proj:BeenDestroyed() then
            return proj
        end

        local bp = self:GetBlueprint()
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
        if self.unit:GetCurrentLayer() == 'Water' and bp.Audio.FireUnderWater then
            self:PlaySound(bp.Audio.FireUnderWater)
        elseif bp.Audio.Fire then
            self:PlaySound(bp.Audio.Fire)
        end

        self:CheckBallisticAcceleration(proj)  -- Check weapon blueprint for trajectory fix request

        return proj
    end,

    -- Used mainly for Bomb drop physics calculations
    CheckBallisticAcceleration = function(self, proj)
        local bp = self:GetBlueprint()
        if bp.FixBombTrajectory then
            local acc = CalculateBallisticAcceleration(self, proj)
            proj:SetBallisticAcceleration(-acc) -- Change projectile trajectory so it hits the target
        end
    end,

    -- Triggers when the weapon is moved horizontally, usually by owner's motion
    OnMotionHorzEventChange = function(self, new, old)
        Weapon.OnMotionHorzEventChange(self, new, old)

        -- Handle weapons which must pack before moving
        local bp = self:GetBlueprint()
        if bp.WeaponUnpackLocksMotion == true and old == 'Stopped' then
            self:PackAndMove()
        end

        -- Handle motion-triggered FiringRandomness changes
        if old == 'Stopped' then
            if bp.FiringRandomnessWhileMoving then
                self:SetFiringRandomness(bp.FiringRandomnessWhileMoving)
            end
        elseif new == 'Stopped' and bp.FiringRandomnessWhileMoving then
            self:SetFiringRandomness(bp.FiringRandomness)
        end
    end,

    -- Called on horizontal motion event
    PackAndMove = function(self)
        ChangeState(self, self.WeaponPackingState)
    end,

    -- Create an economy event for those weapons which require Energy to fire
    StartEconomyDrain = function(self)
        if self.FirstShot then return end

        local bp = self:GetBlueprint()
        if not self.EconDrain and bp.EnergyRequired and bp.EnergyDrainPerSecond then
            local nrgReq = self:GetWeaponEnergyRequired()
            local nrgDrain = self:GetWeaponEnergyDrain()
            if nrgReq > 0 and nrgDrain > 0 then
                local time = nrgReq / nrgDrain
                if time < 0.1 then
                    time = 0.1
                end
                self.EconDrain = CreateEconomyEvent(self.unit, nrgReq, 0, time)
                self.FirstShot = true
            end
        end
    end,

    -- Determine how much Energy is required to fire
    GetWeaponEnergyRequired = function(self)
        local bp = self:GetBlueprint()
        local weapNRG = (bp.EnergyRequired or 0) * (self.AdjEnergyMod or 1)
        if weapNRG < 0 then
            weapNRG = 0
        end
        return weapNRG
    end,

    -- Determine how much Energy should be drained per second
    GetWeaponEnergyDrain = function(self)
        local bp = self:GetBlueprint()
        local weapNRG = (bp.EnergyDrainPerSecond or 0) * (self.AdjEnergyMod or 1)
        return weapNRG
    end,

    GetWeaponRoF = function(self)
        local bp = self:GetBlueprint()

        return bp.RateOfFire / (self.AdjRoFMod or 1)
    end,

 -- Effect Functions Section
 -- Play visual effects, animations, recoil etc

 -- Played when a muzzle is fired. Mostly used for muzzle flashes
    PlayFxMuzzleSequence = function(self, muzzle)
        local bp = self:GetBlueprint()
        for k, v in self.FxMuzzleFlash do
            CreateAttachedEmitter(self.unit, muzzle, self.unit:GetArmy(), v):ScaleEmitter(self.FxMuzzleFlashScale)
        end
    end,

    -- Played during the beginning of the MuzzleChargeDelay time when a muzzle in a rack is fired.
    PlayFxMuzzleChargeSequence = function(self, muzzle)
        local bp = self:GetBlueprint()
        for k, v in self.FxChargeMuzzleFlash do
            CreateAttachedEmitter(self.unit, muzzle, self.unit:GetArmy(), v):ScaleEmitter(self.FxChargeMuzzleFlashScale)
        end
    end,

    -- Played when a rack salvo charges
    -- Do not wait in here or the sequence in the blueprint will be messed up. Fork a thread instead
    PlayFxRackSalvoChargeSequence = function(self)
        local bp = self:GetBlueprint()
        for k, v in self.FxRackChargeMuzzleFlash do
            for ek, ev in bp.RackBones[self.CurrentRackSalvoNumber].MuzzleBones do
                CreateAttachedEmitter(self.unit, ev, self.unit:GetArmy(), v):ScaleEmitter(self.FxRackChargeMuzzleFlashScale)
            end
        end
        if bp.Audio.ChargeStart then
            self:PlaySound(bp.Audio.ChargeStart)
        end
        if bp.AnimationCharge and not self.Animator then
            self.Animator = CreateAnimator(self.unit)
            self.Animator:PlayAnim(self:GetBlueprint().AnimationCharge):SetRate(bp.AnimationChargeRate or 1)
        end
    end,

    -- Played when a rack salvo reloads
    -- Do not wait in here or the sequence in the blueprint will be messed up. Fork a thread instead
    PlayFxRackSalvoReloadSequence = function(self)
        local bp = self:GetBlueprint()
        if bp.AnimationReload and not self.Animator then
            self.Animator = CreateAnimator(self.unit)
            self.Animator:PlayAnim(self:GetBlueprint().AnimationReload):SetRate(bp.AnimationReloadRate or 1)
        end
    end,

    -- Played when a rack reloads. Mostly used for Recoil
    PlayFxRackReloadSequence = function(self)
        local bp = self:GetBlueprint()
        if bp.CameraShakeRadius and bp.CameraShakeMax and bp.CameraShakeMin and bp.CameraShakeDuration and
            bp.CameraShakeRadius > 0 and bp.CameraShakeMax > 0 and bp.CameraShakeMin >= 0 and bp.CameraShakeDuration > 0 then
            self.unit:ShakeCamera(bp.CameraShakeRadius, bp.CameraShakeMax, bp.CameraShakeMin, bp.CameraShakeDuration)
        end
        if bp.ShipRock == true then
            local ix,iy,iz = self.unit:GetBoneDirection(bp.RackBones[self.CurrentRackSalvoNumber].RackBone)
            self.unit:RecoilImpulse(-ix,-iy,-iz)
        end
        if bp.RackRecoilDistance ~= 0 then
            self:PlayRackRecoil({bp.RackBones[self.CurrentRackSalvoNumber]})
        end
    end,

    -- Played when a weapon unpacks
    PlayFxWeaponUnpackSequence = function(self)

        -- Deal with owner's audio cues
        local unitBP = self.unit:GetBlueprint()
        if unitBP.Audio.Activate then
            self:PlaySound(unitBP.Audio.Activate)
        end
        if unitBP.Audio.Open then
            self:PlaySound(unitBP.Audio.Open)
        end

        -- Deal with the Weapon's audio and animations
        local bp = self:GetBlueprint()
        if bp.Audio.Unpack then
            self:PlaySound(bp.Audio.Unpack)
        end
        if bp.WeaponUnpackAnimation and not self.UnpackAnimator then
            self.UnpackAnimator = CreateAnimator(self.unit)
            self.UnpackAnimator:PlayAnim(bp.WeaponUnpackAnimation):SetRate(0)
            self.UnpackAnimator:SetPrecedence(bp.WeaponUnpackAnimatorPrecedence or 0)
            self.unit.Trash:Add(self.UnpackAnimator)
        end
        if self.UnpackAnimator then
            self.UnpackAnimator:SetRate(bp.WeaponUnpackAnimationRate)
            WaitFor(self.UnpackAnimator)
        end
    end,

    -- Played when a weapon packs up
    -- There is no target, and all rack salvos are complete
    PlayFxWeaponPackSequence = function(self)
        local bp = self:GetBlueprint()
        local unitBP = self.unit:GetBlueprint()
        if unitBP.Audio.Close then
            self:PlaySound(unitBP.Audio.Close)
        end
        if bp.WeaponUnpackAnimation and self.UnpackAnimator then
            self.UnpackAnimator:SetRate(-bp.WeaponUnpackAnimationRate)
        end
        if self.UnpackAnimator then
            WaitFor(self.UnpackAnimator)
        end
    end,

    -- Create the visual side of rack recoil
    PlayRackRecoil = function(self, rackList)
        local bp = self:GetBlueprint()
        for k, v in rackList do
            local tmpSldr = CreateSlider(self.unit, v.RackBone)
            table.insert(self.RecoilManipulators, tmpSldr)
            tmpSldr:SetPrecedence(11)
            tmpSldr:SetGoal(0, 0, bp.RackRecoilDistance)
            tmpSldr:SetSpeed(-1)
            self.unit.Trash:Add(tmpSldr)
            if v.TelescopeBone then
                tmpSldr = CreateSlider(self.unit, v.TelescopeBone)
                table.insert(self.RecoilManipulators, tmpSldr)
                tmpSldr:SetPrecedence(11)
                tmpSldr:SetGoal(0, 0, v.TelescopeRecoilDistance or bp.RackRecoilDistance)
                tmpSldr:SetSpeed(-1)
                self.unit.Trash:Add(tmpSldr)
            end
        end
        self:ForkThread(self.PlayRackRecoilReturn, rackList)
    end,

    -- The opposite function to PlayRackRecoil, returns the rack to default position
    PlayRackRecoilReturn = function(self, rackList)
        WaitTicks(1)
        for k, v in rackList do
            for mk, mv in self.RecoilManipulators do
                mv:SetGoal(0, 0, 0)
                mv:SetSpeed(self.RackRecoilReturnSpeed)
            end
        end
    end,

    -- Wait for all recoil and animations
    WaitForAndDestroyManips = function(self)
        local manips = self.RecoilManipulators
        if manips then
            for k, v in manips do
                WaitFor(v)
            end
            self:DestroyRecoilManips()
        end
        if self.Animator then
            WaitFor(self.Animator)
            self.Animator:Destroy()
            self.Animator = nil
        end
    end,

    -- Destroy the sliders which cause weapon visual recoil
    DestroyRecoilManips = function(self)
        local manips = self.RecoilManipulators
        if manips then
            for k, v in manips do
                v:Destroy()
            end
            self.RecoilManipulators = {}
        end
    end,

    -- Should be called whenever a target is lost
    -- Includes the manual selection of a new target, and the issuing of a move order
    OnLostTarget = function(self)
        -- Issue 43
        -- Tell the owner this weapon has lost the target
        if self.unit then
            self.unit:OnLostTarget(self)
        end

        Weapon.OnLostTarget(self)
        local bp = self:GetBlueprint()
        if bp.WeaponUnpacks == true then
            ChangeState(self, self.WeaponPackingState)
        else
            ChangeState(self, self.IdleState)
        end
    end,

    -- Sends the weapon to DeadState, probably called by the Owner
    OnDestroy = function(self)
        ChangeState(self, self.DeadState)
    end,

    -- Checks to see if the weapon is allowed to fire
    CanWeaponFire = function(self)
        return self.WeaponCanFire
    end,

    -- Present for Overcharge to hook into
    OnWeaponFired = function(self)
    end,

    -- I think this is triggered whenever the state changes to anything but DeadState
    OnEnterState = function(self)
        if self.WeaponWantEnabled and not self.WeaponIsEnabled then
            self.WeaponIsEnabled = true
            self:SetWeaponEnabled(true)
        elseif not self.WeaponWantEnabled and self.WeaponIsEnabled then
            local bp = self:GetBlueprint()
            if bp.CountedProjectile ~= true then
                self.WeaponIsEnabled = false
                self:SetWeaponEnabled(false)
            end
        end
        if self.WeaponAimWantEnabled and not self.WeaponAimIsEnabled then
            self.WeaponAimIsEnabled = true
            self:AimManipulatorSetEnabled(true)
        elseif not self.WeaponAimWantEnabled and self.WeaponAimIsEnabled then
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
            if self.unit.Dead then return end
            self.unit:SetBusy(false)
            self:WaitForAndDestroyManips()

            local bp = self:GetBlueprint()
            if not bp.RackBones then
                error('Error on rackbones ' .. self.unit:GetUnitId())
            end
            for k, v in bp.RackBones do
                if v.HideMuzzle == true then
                    for mk, mv in v.MuzzleBones do
                        self.unit:ShowBone(mv, true)
                    end
                end
            end
            self:StartEconomyDrain()
            if table.getn(bp.RackBones) > 1 and self.CurrentRackSalvoNumber > 1 then
                WaitSeconds(self:GetBlueprint().RackReloadTimeout)
                self:PlayFxRackSalvoReloadSequence()
                self.CurrentRackSalvoNumber = 1
            end
        end,

        OnGotTarget = function(self)
            Weapon.OnGotTarget(self)

            local bp = self:GetBlueprint()

            -- Issue 43
            if self.unit then
                self.unit:OnGotTarget(self)
            end

            if bp.WeaponUnpackLockMotion ~= true or (bp.WeaponUnpackLocksMotion == true and not self.unit:IsUnitState('Moving')) then
                if bp.CountedProjectile == true and not self:CanFire() then
                    return
                end
                if bp.WeaponUnpacks == true then
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
            local bp = self:GetBlueprint()
            if bp.WeaponUnpacks == true then
                ChangeState(self, self.WeaponUnpackingState)
            else
                if bp.RackSalvoChargeTime and bp.RackSalvoChargeTime > 0 then
                    ChangeState(self, self.RackSalvoChargeState)

                -- SkipReadyState used for Janus and Corsair
                elseif bp.SkipReadyState and bp.SkipReadyState == true then
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
            self.unit:SetBusy(true)
            self:PlayFxRackSalvoChargeSequence()

            local bp = self:GetBlueprint()
            if bp.NotExclusive then
                self.unit:SetBusy(false)
            end
            WaitSeconds(self:GetBlueprint().RackSalvoChargeTime)
            if bp.NotExclusive then
                self.unit:SetBusy(true)
            end

            if bp.RackSalvoFiresAfterCharge == true then
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

            local bp = self:GetBlueprint()
            if bp.CountedProjectile == true and bp.WeaponUnpacks == true then
                self.unit:SetBusy(true)
            else
                self.unit:SetBusy(false)
            end

            self.WeaponCanFire = true
            if self.EconDrain then
                self.WeaponCanFire = false
                WaitFor(self.EconDrain)
                RemoveEconomyEvent(self.unit, self.EconDrain)
                self.EconDrain = nil
                self.WeaponCanFire = true
            end

            -- This code has the effect of forcing a unit to wait on its firing state to change from Hold Fire
            -- before resuming the sequence from this point
            -- Introduced to fix a bug where units with this bp flag would go straight to projectile creation
            -- from OnGotTarget, without waiting for OnFire() to be called from engine.
            if bp.CountedProjectile == true or bp.AnimationReload then
                if self.unit:GetFireState() == 1 then
                    while self.unit:GetFireState() == 1 do
                        WaitTicks(1)
                    end
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
            local clockTime = rof
            local totalTime = clockTime
            while clockTime > 0.0 and
                  not self:BeenDestroyed() and
                  not self.unit.Dead do
                self.unit:SetWorkProgress(1 - clockTime / totalTime)
                clockTime = clockTime - 0.1
                WaitSeconds(0.1)
            end
        end,

        Main = function(self)
            self.unit:SetBusy(true)
            self:DestroyRecoilManips()

            local bp = self:GetBlueprint()
            local rof = self:GetWeaponRoF()
            local numRackFiring = self.CurrentRackSalvoNumber

            --This is done to make sure that when racks should fire together, they do
            if bp.RackFireTogether == true then
                numRackFiring = table.getsize(bp.RackBones)
            end

            -- Fork timer counter thread carefully
            if not self:BeenDestroyed() and
               not self.unit.Dead then
                if bp.RenderFireClock and rof > 0 then
                    self:ForkThread(self.RenderClockThread, 1/rof)
                end
            end

            -- Most of the time this will only run once, the only time it doesn't is when racks fire together
            while self.CurrentRackSalvoNumber <= numRackFiring and not self.HaltFireOrdered do
                local rackInfo = bp.RackBones[self.CurrentRackSalvoNumber]
                local numMuzzlesFiring = bp.MuzzleSalvoSize

                if bp.MuzzleSalvoDelay == 0 then
                    numMuzzlesFiring = table.getn(rackInfo.MuzzleBones)
                end

                local muzzleIndex = 1
                for i = 1, numMuzzlesFiring do
                    if self.HaltFireOrdered then
                        continue
                    end

                    local muzzle = rackInfo.MuzzleBones[muzzleIndex]
                    if rackInfo.HideMuzzle == true then
                        self.unit:ShowBone(muzzle, true)
                    end

                    -- Deal with Muzzle charging sequence
                    if bp.MuzzleChargeDelay and bp.MuzzleChargeDelay > 0 then
                        if bp.Audio.MuzzleChargeStart then
                            self:PlaySound(bp.Audio.MuzzleChargeStart)
                        end

                        self:PlayFxMuzzleChargeSequence(muzzle)
                        if bp.NotExclusive then
                            self.unit:SetBusy(false)
                        end
                        WaitSeconds(bp.MuzzleChargeDelay)
                        if bp.NotExclusive then
                            self.unit:SetBusy(true)
                        end
                    end
                    self:PlayFxMuzzleSequence(muzzle)

                    if rackInfo.HideMuzzle == true then
                        self.unit:HideBone(muzzle, true)
                    end

                    if self.HaltFireOrdered then
                        continue
                    end
                    local proj = self:CreateProjectileAtMuzzle(muzzle)

                    -- Decrement the ammo if they are a counted projectile
                    if proj and not proj:BeenDestroyed() and bp.CountedProjectile == true then
                        if bp.NukeWeapon == true then
                            self.unit:NukeCreatedAtUnit()

                            -- Generate UI notification for automatic nuke ping
                            local launchData = { army = self.unit:GetArmy()-1, location = self:GetCurrentTargetPos()}
                            if not Sync.NukeLaunchData then Sync.NukeLaunchData = {} end
                            table.insert(Sync.NukeLaunchData, launchData)
                            self.unit:RemoveNukeSiloAmmo(1)
                        else
                            self.unit:RemoveTacticalSiloAmmo(1)
                        end
                    end

                    -- Deal with muzzle firing sequence
                    muzzleIndex = muzzleIndex + 1
                    if muzzleIndex > table.getn(rackInfo.MuzzleBones) then
                        muzzleIndex = 1
                    end
                    if bp.MuzzleSalvoDelay > 0 then
                        if bp.NotExclusive then
                            self.unit:SetBusy(false)
                        end
                        WaitSeconds(bp.MuzzleSalvoDelay)
                        if bp.NotExclusive then
                            self.unit:SetBusy(true)
                        end
                    end
                end
                self:PlayFxRackReloadSequence()

                if self.CurrentRackSalvoNumber <= table.getn(bp.RackBones) then
                    self.CurrentRackSalvoNumber = self.CurrentRackSalvoNumber + 1
                end
            end

            self:DoOnFireBuffs()    -- Found in mohodata weapon.lua
            self.FirstShot = false
            self:StartEconomyDrain()
            self:OnWeaponFired()    -- Used primarily by Overcharge

            -- We can fire again after reaching here
            self.HaltFireOrdered = false

            -- Deal with the rack firing sequence
            if self.CurrentRackSalvoNumber > table.getn(bp.RackBones) then
                self.CurrentRackSalvoNumber = 1

                if bp.RackSalvoReloadTime > 0 then
                    ChangeState(self, self.RackSalvoReloadState)
                elseif bp.RackSalvoChargeTime > 0 then
                    ChangeState(self, self.IdleState)
                elseif bp.CountedProjectile == true and bp.WeaponUnpacks == true then
                    ChangeState(self, self.WeaponPackingState)
                elseif bp.CountedProjectile == true and not bp.WeaponUnpacks then
                    ChangeState(self, self.IdleState)
                else
                    ChangeState(self, self.RackSalvoFireReadyState)
                end
            elseif bp.CountedProjectile == true and not bp.WeaponUnpacks then
                ChangeState(self, self.IdleState)
            elseif bp.CountedProjectile == true and bp.WeaponUnpacks == true then
                ChangeState(self, self.WeaponPackingState)
            else
                ChangeState(self, self.RackSalvoFireReadyState)
            end
        end,

        OnLostTarget = function(self)
            Weapon.OnLostTarget(self)
            local bp = self:GetBlueprint()
            if bp.WeaponUnpacks == true then
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
            self.unit:SetBusy(true)
            self:PlayFxRackSalvoReloadSequence()

            local bp = self:GetBlueprint()
            if bp.NotExclusive then
                self.unit:SetBusy(false)
            end
            WaitSeconds(self:GetBlueprint().RackSalvoReloadTime)
            self:WaitForAndDestroyManips()

            if bp.NotExclusive then
                self.unit:SetBusy(true)
            end
            if self:WeaponHasTarget() and bp.RackSalvoChargeTime > 0 and self:CanFire() then
                ChangeState(self, self.RackSalvoChargeState)
            elseif self:WeaponHasTarget() and self:CanFire() then
                ChangeState(self, self.RackSalvoFireReadyState)
            elseif not self:WeaponHasTarget() and bp.WeaponUnpacks == true and bp.WeaponUnpackLocksMotion ~= true then
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
            self.unit:SetBusy(true)

            local bp = self:GetBlueprint()
            if bp.WeaponUnpackLocksMotion then
                self.unit:SetImmobile(true)
            end
            self:PlayFxWeaponUnpackSequence()

            local rackSalvoChargeTime = self:GetBlueprint().RackSalvoChargeTime
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
            self.unit:SetBusy(true)

            local bp = self:GetBlueprint()
            WaitSeconds(self:GetBlueprint().WeaponRepackTimeout)

            self:AimManipulatorSetEnabled(false)
            self:PlayFxWeaponPackSequence()
            if bp.WeaponUnpackLocksMotion then
                self.unit:SetImmobile(false)
            end
            ChangeState(self, self.IdleState)
        end,

        OnGotTarget = function(self)
            Weapon.OnGotTarget(self)

            -- Issue 43
            if self.unit then
                self.unit:OnGotTarget(self)
            end

            if not self:GetBlueprint().ForceSingleFire then
                ChangeState(self, self.WeaponUnpackingState)
            end
        end,

        OnFire = function(self)
            local bp = self:GetBlueprint()
            if bp.CountedProjectile == true and not self:GetBlueprint().ForceSingleFire then
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

KamikazeWeapon = Class(Weapon) {
    OnFire = function(self)
        local myBlueprint = self:GetBlueprint()
        DamageArea(self.unit, self.unit:GetPosition(), myBlueprint.DamageRadius, myBlueprint.Damage, myBlueprint.DamageType or 'Normal', myBlueprint.DamageFriendly or false)
        self.unit:PlayUnitSound('Destroyed')
        self.unit:Destroy()
    end,
}

BareBonesWeapon = Class(Weapon) {
    Data = {},

    OnFire = function(self)
        local myBlueprint = self:GetBlueprint()
        local myProjectile = self.unit:CreateProjectile(myBlueprint.ProjectileId, 0, 0, 0, nil, nil, nil):SetCollision(false)
        if self.Data then
            myProjectile:PassData(self.Data)
        end
    end,
}

OverchargeWeapon = Class(DefaultProjectileWeapon) {
    NeedsUpgrade = false,
    AutoMode = false,
    AutoThread = nil,
    EnergyRequired = nil,

    HasEnergy = function(self)
        return self.unit:GetAIBrain():GetEconomyStored('ENERGY') >= self.EnergyRequired
    end,

    -- Can we use the OC weapon?
    CanOvercharge = function(self)
        return not self.unit:IsOverchargePaused() and self:HasEnergy() and not
            self:UnitOccupied() and not
            self.unit:IsUnitState('Enhancing') and not
            self.unit:IsUnitState('Upgrading')
    end,

    -- Returns true if the unit is doing something that shouldn't allow any weapon fire
    UnitOccupied = function(self)
        return (self.unit:IsUnitState('Upgrading') and not self.unit:IsUnitState('Enhancing')) or -- Don't let us shoot if we're upgrading, unless it's an enhancement task
            self.unit:IsUnitState('Building') or
            self.unit:IsUnitState('Repairing') or
            self.unit:IsUnitState('Reclaiming')
    end,

    -- The Overcharge cool-down function
    PauseOvercharge = function(self)
        if not self.unit:IsOverchargePaused() then
            self.unit:SetOverchargePaused(true)
            self:OnDisableWeapon()
            WaitSeconds(1 / self:GetBlueprint().RateOfFire)
            self.unit:SetOverchargePaused(false)
            if self.AutoMode then
                self.AutoThread = self:ForkThread(self.AutoEnable)
            end
        end
    end,

    AutoEnable = function(self)
        while not self:CanOvercharge() do
            WaitSeconds(0.1)
        end

        if self.AutoMode then
            self:OnEnableWeapon()
        end
    end,

    SetAutoOvercharge = function(self, auto)
        self.AutoMode = auto

        if self.AutoMode then
            self.AutoThread = self:ForkThread(self.AutoEnable)
        else
            if self.AutoThread then
                KillThread(self.AutoThread)
                self.AutoThread = nil
            end
            if self.enabled then
                self:OnDisableWeapon()
            end
        end
    end,

    OnCreate = function(self)
        DefaultProjectileWeapon.OnCreate(self)
        self.EnergyRequired = self:GetBlueprint().EnergyRequired
        self:SetWeaponEnabled(false)
        self.AimControl:SetEnabled(false)
        self.AimControl:SetPrecedence(0)
        self.unit:SetOverchargePaused(false)
    end,

    OnGotTarget = function(self)
        if self:CanOvercharge() then
            DefaultProjectileWeapon.OnGotTarget(self)
        else
            self:OnDisableWeapon()
        end
    end,

    OnFire = function(self)
        if self:CanOvercharge() then
            DefaultProjectileWeapon.OnFire(self)
        else
            self:OnDisableWeapon()
        end
    end,

    IsEnabled = function(self)
        return self.enabled
    end,

    OnEnableWeapon = function(self)
        if self:BeenDestroyed() then return end
        DefaultProjectileWeapon.OnEnableWeapon(self)
        self:SetWeaponEnabled(true)
        if self:CanOvercharge() then
            self.unit:SetWeaponEnabledByLabel(self.DesiredWeaponLabel, false)
        end
        self.unit:BuildManipulatorSetEnabled(false)
        self.AimControl:SetEnabled(true)
        self.AimControl:SetPrecedence(20)
        self.unit.BuildArmManipulator:SetPrecedence(0)
        self.AimControl:SetHeadingPitch(self.unit:GetWeaponManipulatorByLabel(self.DesiredWeaponLabel):GetHeadingPitch())
        self.enabled = true
    end,

    OnDisableWeapon = function(self)
        if self.unit:BeenDestroyed() then return end
        self:SetWeaponEnabled(false)

        -- Only allow it to turn on the primary weapon if the unit is ready
        if not self:UnitOccupied() then
            self.unit:SetWeaponEnabledByLabel(self.DesiredWeaponLabel, true)
        end

        self.unit:BuildManipulatorSetEnabled(false)
        self.AimControl:SetEnabled(false)
        self.AimControl:SetPrecedence(0)
        self.unit.BuildArmManipulator:SetPrecedence(0)
        self.unit:GetWeaponManipulatorByLabel(self.DesiredWeaponLabel):SetHeadingPitch(self.AimControl:GetHeadingPitch())

        self.enabled = false
    end,

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

DefaultBeamWeapon = Class(DefaultProjectileWeapon) {
    BeamType = CollisionBeam,

    OnCreate = function(self)
        self.Beams = {}

        -- Ensure that the weapon blueprint is set up properly for beams
        local bp = self:GetBlueprint()
        if not bp.BeamCollisionDelay then
            local strg = '*ERROR: No BeamCollisionDelay specified for beam weapon, aborting setup.  Weapon: ' .. bp.DisplayName .. ' on Unit: ' .. self.unit:GetUnitId()
            error(strg, 2)
            return
        end
        if not bp.BeamLifetime then
            local strg = '*ERROR: No BeamLifetime specified for beam weapon, aborting setup.  Weapon: ' .. bp.DisplayName .. ' on Unit: ' .. self.unit:GetUnitId()
            error(strg, 2)
            return
        end

        -- Create the beam
        for rk, rv in bp.RackBones do
            for mk, mv in rv.MuzzleBones do
                local beam
                beam = self.BeamType{
                    Weapon = self,
                    BeamBone = 0,
                    OtherBone = mv,
                    CollisionCheckInterval = bp.BeamCollisionDelay * 10,    -- Why is this multiplied by 10? IceDreamer
                }
                local beamTable = {Beam = beam, Muzzle = mv, Destroyables = {}}
                table.insert(self.Beams, beamTable)
                self.unit.Trash:Add(beam)
                beam:SetParentWeapon(self)
                beam:Disable()
            end
        end

        DefaultProjectileWeapon.OnCreate(self)
    end,

    -- This entirely overrides the default
    CreateProjectileAtMuzzle = function(self, muzzle)
        local enabled = false
        for k, v in self.Beams do
            if v.Muzzle == muzzle and v.Beam:IsEnabled() then
                enabled = true
            end
        end
        if not enabled then
            self:PlayFxBeamStart(muzzle)
        end

        local bp = self:GetBlueprint()
        if self.unit:GetCurrentLayer() == 'Water' and bp.Audio.FireUnderWater then
            self:PlaySound(bp.Audio.FireUnderWater)
        elseif bp.Audio.Fire then
            self:PlaySound(bp.Audio.Fire)
        end
    end,

    PlayFxBeamStart = function(self, muzzle)
        local army = self.unit:GetArmy()
        local bp = self:GetBlueprint()
        local beam
        local beamTable
        self.BeamDestroyables = {}

        for k, v in self.Beams do
            if v.Muzzle == muzzle then
                beam = v.Beam
                beamTable = v
            end
        end
        if not beam then
            error('*ERROR: We have a beam created that does not coincide with a muzzle bone.  Internal Error, aborting beam weapon.', 2)
            return
        end

        if beam:IsEnabled() then return end
        beam:Enable()
        self.unit.Trash:Add(beam)

        -- Deal with continuous and non-continuous beams
        if bp.BeamLifetime > 0 then
            self:ForkThread(self.BeamLifetimeThread, beam, bp.BeamLifetime or 1)    -- Non-continuous only
        end
        if bp.BeamLifetime == 0 then
            self.HoldFireThread = self:ForkThread(self.WatchForHoldFire, beam)      -- Continuous only
        end

        -- Deal with beam audio cues
        if bp.Audio.BeamStart then
            self:PlaySound(bp.Audio.BeamStart)
        end
        if bp.Audio.BeamLoop and self.Beams[1].Beam then
            self.Beams[1].Beam:SetAmbientSound(bp.Audio.BeamLoop, nil)
        end
        self.BeamStarted = true
    end,

    -- Kill the beam if hold fire is requested
    WatchForHoldFire = function(self, beam)
        while true do
            WaitSeconds(1)
            --if we're at hold fire, stop beam
            if self.unit and (self.unit:GetFireState() == 1 or self.NumTargets == 0) then
                self.BeamStarted = false
                self:PlayFxBeamEnd(beam)
            end
        end
    end,

    -- Force the beam to last the proper amount of time
    BeamLifetimeThread = function(self, beam, lifeTime)
        WaitSeconds(lifeTime)
        WaitTicks(1)
        self:PlayFxBeamEnd(beam)
    end,

    PlayFxWeaponUnpackSequence = function(self)
        local bp = self:GetBlueprint()
        -- If it's not a continuous beam, or  if it's a continuous beam that's off
        if bp.BeamLifetime > 0 or (bp.BeamLifetime == 0 and not self.ContBeamOn) then
            DefaultProjectileWeapon.PlayFxWeaponUnpackSequence(self)
        end
    end,


    -- Kill the beam
    PlayFxBeamEnd = function(self, beam)
        if not self.unit.Dead then
            local bp = self:GetBlueprint()
            if bp.Audio.BeamStop and self.BeamStarted then
                self:PlaySound(bp.Audio.BeamStop)
            end
            if bp.Audio.BeamLoop and self.Beams[1].Beam then
                self.Beams[1].Beam:SetAmbientSound(nil, nil)
            end
            if beam then
                beam:Disable()
            else
                for k, v in self.Beams do
                    v.Beam:Disable()
                end
            end
            self.BeamStarted = false
        end
        if self.HoldFireThread then
            KillThread(self.HoldFireThread)
        end
    end,

    StartEconomyDrain = function(self)
        local bp = self:GetBlueprint()
        if not self.EconDrain and bp.EnergyRequired and bp.EnergyDrainPerSecond then
            if not self:EconomySupportsBeam() then
                return
            end
        end
        DefaultProjectileWeapon.StartEconomyDrain(self)
    end,

    OnHaltFire = function(self)
        for k,v in self.Beams do
            -- Only halt fire on the beams that are currently enabled
            if not v.Beam:IsEnabled() then
                continue
            end
            self:PlayFxBeamEnd(v.Beam)
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
            local bp = self:GetBlueprint()
            if bp.BeamLifetime > 0 then
                self:PlayFxBeamEnd()
            else
                self.ContBeamOn = true
            end
            DefaultProjectileWeapon.WeaponPackingState.Main(self)
        end,
    },

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

    EconomySupportsBeam = function(self)
        local aiBrain = self.unit:GetAIBrain()
        local energyIncome = aiBrain:GetEconomyIncome('ENERGY') * 10
        local energyStored = aiBrain:GetEconomyStored('ENERGY')
        local nrgReq = self:GetWeaponEnergyRequired()
        local nrgDrain = self:GetWeaponEnergyDrain()

        if energyStored < nrgReq and energyIncome < nrgDrain then
            return false
        end
        return true
    end,
}

local NukeDamage = import('/lua/sim/NukeDamage.lua').NukeAOE
DeathNukeWeapon = Class(BareBonesWeapon) {
    OnFire = function(self)
    end,

    Fire = function(self)
        local bp = self:GetBlueprint()
        local proj = self.unit:CreateProjectile(bp.ProjectileId, 0, 0, 0, nil, nil, nil):SetCollision(false)
        proj:ForkThread(proj.EffectThread)

        -- Play the explosion sound
        local projBp = proj:GetBlueprint()
        if projBp.Audio.NukeExplosion then
            self:PlaySound(projBp.Audio.NukeExplosion)
        end

        proj.InnerRing = NukeDamage()
        proj.InnerRing:OnCreate(bp.NukeInnerRingDamage, bp.NukeInnerRingRadius, bp.NukeInnerRingTicks, bp.NukeInnerRingTotalTime)
        proj.OuterRing = NukeDamage()
        proj.OuterRing:OnCreate(bp.NukeOuterRingDamage, bp.NukeOuterRingRadius, bp.NukeOuterRingTicks, bp.NukeOuterRingTotalTime)

        local launcher = self.unit
        local pos = proj:GetPosition()
        local army = launcher:GetArmy()
        local brain = launcher:GetAIBrain()
        local damageType = bp.DamageType
        proj.InnerRing:DoNukeDamage(launcher, pos, brain, army, damageType)
        proj.OuterRing:DoNukeDamage(launcher, pos, brain, army, damageType)

        -- Stop it calling DoDamage any time in the future.
        proj.DoDamage = function(self, instigator, DamageData, targetEntity) end
    end,
}

SCUDeathWeapon = Class(BareBonesWeapon) {
    OnFire = function(self)
    end,

    Fire = function(self)
        local myBlueprint = self:GetBlueprint()
        local myProjectile = self.unit:CreateProjectile(myBlueprint.ProjectileId, 0, 0, 0, nil, nil, nil):SetCollision(false)
        myProjectile:PassDamageData(self:GetDamageTable())
    end,
}
