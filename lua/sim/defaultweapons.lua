#****************************************************************************
#**
#**  File     :  /lua/sim/DefaultWeapons.lua
#**  Author(s):  John Comes
#**
#**  Summary  :  Default definitions of weapons
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

local Weapon = import('/lua/sim/Weapon.lua').Weapon

local CollisionBeam = import('/lua/sim/CollisionBeam.lua').CollisionBeam

#new for CBFP
local Game = import('/lua/game.lua')
local CalculateBallisticAcceleration = import('/lua/sim/CalcBallisticAcceleration.lua').CalculateBallisticAcceleration 

#The big weapon change, most things are derived from this DefaultProjectileWeapon
#See the Solutions Library on how to use it.

DefaultProjectileWeapon = Class(Weapon) {		


    # Brute51 - added support for initialdamage in unit BP (copy/paste from Nomads code)
    GetDamageTable = function(self)
        local table = Weapon.GetDamageTable(self)
        table.InitialDamageAmount = self:GetBlueprint().InitialDamage or 0
        return table
    end,



    FxRackChargeMuzzleFlash = {},
    FxRackChargeMuzzleFlashScale = 1,
    FxChargeMuzzleFlash = {},
    FxChargeMuzzleFlashScale = 1,
    FxMuzzleFlash = {
		'/effects/emitters/default_muzzle_flash_01_emit.bp',
        '/effects/emitters/default_muzzle_flash_02_emit.bp',
    },
    FxMuzzleFlashScale = 1,    

    OnCreate = function(self)
    
        Weapon.OnCreate(self)
        local bp = self:GetBlueprint()
        self.WeaponCanFire = true
        if bp.RackRecoilDistance != 0 then
            self.RecoilManipulators = {}
        end
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
        #Calculate recoil speed so that it finishes returning just as the next shot is ready.
        if bp.RackRecoilDistance != 0 then
            local dist = bp.RackRecoilDistance
            if bp.RackBones[1].TelescopeRecoilDistance then
                local tpDist = bp.RackBones[1].TelescopeRecoilDistance
                if math.abs(tpDist) > math.abs(dist) then
                    dist = tpDist
                end
            end
            self.RackRecoilReturnSpeed = bp.RackRecoilReturnSpeed or math.abs( dist / (( 1 / bp.RateOfFire ) - (bp.MuzzleChargeDelay or 0))) * 1.25
        end
        #Error Checking
        self.NumMuzzles = 0
        for rk, rv in bp.RackBones do
            self.NumMuzzles = self.NumMuzzles + table.getn(rv.MuzzleBones or 0)
        end
        self.NumMuzzles = self.NumMuzzles / table.getn(bp.RackBones)
        local totalMuzzleFiringTime = (self.NumMuzzles - 1) * bp.MuzzleSalvoDelay
        if totalMuzzleFiringTime > (1 / bp.RateOfFire) then
            local strg = '*ERROR: The total time to fire muzzles is longer than the RateOfFire allows, aborting weapon setup.  Weapon: ' .. bp.DisplayName .. ' on Unit: ' .. self.unit:GetUnitId()
            error(strg, 2)
            return false
        end
        if bp.RackRecoilDistance != 0 and bp.MuzzleSalvoDelay != 0 then
            local strg = '*ERROR: You can not have a RackRecoilDistance with a MuzzleSalvoDelay not equal to 0, aborting weapon setup.  Weapon: ' .. bp.DisplayName .. ' on Unit: ' .. self.unit:GetUnitId()
            error(strg, 2)
            return false
        end
        if bp.EnergyChargeForFirstShot == false then
            self.FirstShot = true
        end
        if bp.RenderFireClock then
            self.unit:SetWorkProgress(1)
        end
        ChangeState(self, self.IdleState)
	
	###new for CBFP
        local bp = self:GetBlueprint()
        if bp.FixBombTrajectory then
            self.CBFP_CalcBallAcc = { Do = true, ProjectilesPerOnFire = (bp.ProjectilesPerOnFire or 1), MuzzleSalvoDelay = (bp.MuzzleSalvoDelay or 0.1), }
        end

    end,

    OnMotionHorzEventChange = function(self, new, old)
        Weapon.OnMotionHorzEventChange(self, new, old)
        local bp = self:GetBlueprint()
        if bp.WeaponUnpackLocksMotion == true and old == 'Stopped' then
            self:PackAndMove()
        end
        #Changing firing randomness while moving, NOTE: This is hard set.  If it's changed somewhere else this will override
        #I'd do it the proper way but we're at the end of the project and thusly stuck.
        if old == 'Stopped' then
            if bp.FiringRandomnessWhileMoving then
                self:SetFiringRandomness(bp.FiringRandomnessWhileMoving)
            end
        elseif new == 'Stopped' and bp.FiringRandomnessWhileMoving then
            self:SetFiringRandomness(bp.FiringRandomness)
        end
    end,

    CreateProjectileAtMuzzle = function(self, muzzle)
        local proj = self:CreateProjectileForWeapon(muzzle)
        if not proj or proj:BeenDestroyed()then
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
	
	#new for CBFP
	self:CheckBallisticAcceleration( proj)  # if weapon BP specifies fix bomb trajectory then that's what happens
        self:CheckCountedMissileLaunch()  # added by brute51 - provides a unit event function

        return proj
    end,

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

    #The adjacency mod only effects the over all cost, not the drain per second. So, the drain will be about the same
    #but the time it takes to drain will not be.
    GetWeaponEnergyRequired = function(self)
        local bp = self:GetBlueprint()
        local weapNRG = (bp.EnergyRequired or 0) * (self.AdjEnergyMod or 1)
        if weapNRG < 0 then
            weapNRG = 0
        end
        return weapNRG
    end,

    GetWeaponEnergyDrain = function(self)
        local bp = self:GetBlueprint()
        local weapNRG = (bp.EnergyDrainPerSecond or 0)
        return weapNRG
    end,

    #Effect functions: Not only visual effects but also plays animations, recoil, etc.

    #PlayFxMuzzleSequence: Played when a muzzle is fired.  Mostly used for muzzle flashes
    PlayFxMuzzleSequence = function(self, muzzle)
        local bp = self:GetBlueprint()
        for k, v in self.FxMuzzleFlash do
            CreateAttachedEmitter(self.unit, muzzle, self.unit:GetArmy(), v):ScaleEmitter(self.FxMuzzleFlashScale)
        end
    end,

    #PlayFxMuzzleSequence: Played during the beginning of the MuzzleChargeDelay time when a muzzle in a rack is fired.
    PlayFxMuzzleChargeSequence = function(self, muzzle)
        local bp = self:GetBlueprint()
        for k, v in self.FxChargeMuzzleFlash do
            CreateAttachedEmitter(self.unit, muzzle, self.unit:GetArmy(), v):ScaleEmitter(self.FxChargeMuzzleFlashScale)
        end
    end,    

    #PlayFxRackSalvoChargeSequence: Played when a rack salvo charges.  Do not put a wait in here or you'll
    #make the time value in the bp off.  Spawn another thread to do waits.
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

    #PlayFxRackSalvoReloadSequence: Played when a rack salvo reloads.  Do not put a wait in here or you'll
    #make the time value in the bp off.  Spawn another thread to do waits.
    PlayFxRackSalvoReloadSequence = function(self)
        local bp = self:GetBlueprint()
        if bp.AnimationReload and not self.Animator then
            self.Animator = CreateAnimator(self.unit)
            self.Animator:PlayAnim(self:GetBlueprint().AnimationReload):SetRate(bp.AnimationReloadRate or 1)
        end
    end,

    #PlayFxRackSalvoReloadSequence: Played when a rack reloads. Mostly used for Recoil.
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
        if bp.RackRecoilDistance != 0 then
            self:PlayRackRecoil({bp.RackBones[self.CurrentRackSalvoNumber]})
        end
    end,

    #PlayFxWeaponUnpackSequence: Played when a weapon unpacks.  Here a wait is used because by definition a weapon
    #can not fire while packed up.
    PlayFxWeaponUnpackSequence = function(self)
        local bp = self:GetBlueprint()
        local unitBP = self.unit:GetBlueprint()
        if unitBP.Audio.Activate then
            self:PlaySound(unitBP.Audio.Activate)
        end
        if unitBP.Audio.Open then
            self:PlaySound(unitBP.Audio.Open)
        end
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

    #PlayFxWeaponUnpackSequence: Played when a weapon packs up.  It has no target and is done with all of its rack salvos
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

    PlayRackRecoilReturn = function(self, rackList)
        WaitTicks(1)
        for k, v in rackList do
            for mk, mv in self.RecoilManipulators do
                mv:SetGoal(0, 0, 0)
                mv:SetSpeed(self.RackRecoilReturnSpeed)
            end
        end
    end,

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

    DestroyRecoilManips = function(self)
        local manips = self.RecoilManipulators
        if manips then
            for k, v in manips do
                v:Destroy()
            end
            self.RecoilManipulators = {}
        end
    end,

    #General State-less event handling
    OnLostTarget = function(self)
	
		-- issue#43 for better stealth
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

    OnDestroy = function(self)
        ChangeState(self, self.DeadState)
    end,

    OnEnterState = function(self)
        if self.WeaponWantEnabled and not self.WeaponIsEnabled then
            self.WeaponIsEnabled = true
            self:SetWeaponEnabled(true)
        elseif not self.WeaponWantEnabled and self.WeaponIsEnabled then
            local bp = self:GetBlueprint()
            if bp.CountedProjectile != true then
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

    PackAndMove = function(self)
        ChangeState(self, self.WeaponPackingState)
    end,

    CanWeaponFire = function(self)
        if self.WeaponCanFire then
            return self.WeaponCanFire
        else
            return true
        end
    end,

    OnWeaponFired = function(self)
    end,

    OnEnableWeapon = function(self)
    end,

    # WEAPON STATES:

    #Weapon is in idle state when it does not have a target and is done with any animations or unpacking.
    IdleState = State {
	
		-- issue#43 for better stealth
		OnGotTarget = function(self)
			if self.unit then 
				self.unit:OnGotTarget(self)
			end
		end,
	
        WeaponWantEnabled = true,
        WeaponAimWantEnabled = true,

        Main = function(self)
            if self.unit:IsDead() then return end
            
            self.unit:SetBusy(false)
            self:WaitForAndDestroyManips()
            local bp = self:GetBlueprint()
            #LOG("Weapon " .. bp.DisplayName .. " entered IdleState.")
            if not bp.RackBones then
                error('Error on rackbones ' .. self.unit:GetUnitId() )
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
            local bp = self:GetBlueprint()
			
			-- issue#43 for better stealth
			if self.unit then
				self.unit:OnGotTarget(self)
			end
			
            if (bp.WeaponUnpackLockMotion != true or (bp.WeaponUnpackLocksMotion == true and not self.unit:IsUnitState('Moving'))) then
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
                elseif bp.SkipReadyState and bp.SkipReadyState == true then
                    ChangeState(self, self.RackSalvoFiringState)
                else
                    ChangeState(self, self.RackSalvoFireReadyState)
                end
            end
        end,
    },

    RackSalvoChargeState = State {
        WeaponWantEnabled = true,
        WeaponAimWantEnabled = true,

        Main = function(self)
            self.unit:SetBusy(true)
            local bp = self:GetBlueprint()
            self:PlayFxRackSalvoChargeSequence()
            #LOG("Weapon " .. bp.DisplayName .. " entered RackSalvoChargeState.")
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

    RackSalvoFireReadyState = State {
        WeaponWantEnabled = true,
        WeaponAimWantEnabled = true,

        Main = function(self)
            local bp = self:GetBlueprint()
            #LOG("Weapon " .. bp.DisplayName .. " entered RackSalvoFireReadyState.")
            if (bp.CountedProjectile == true and bp.WeaponUnpacks == true) then
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
            #We change the state on counted projectiles because we won't get another OnFire call.
            #The second part is a hack for units with reload animations.  They have the same problem
            #they need a RackSalvoReloadTime that's 1/RateOfFire set to avoid firing twice on the first shot
            if bp.CountedProjectile == true  or bp.AnimationReload then
                ChangeState(self, self.RackSalvoFiringState)
            end
        end,

        OnFire = function(self)
            if self.WeaponCanFire then
                ChangeState(self, self.RackSalvoFiringState)
            end
        end,
    },

    RackSalvoFiringState = State {
        WeaponWantEnabled = true,
        WeaponAimWantEnabled = true,

        RenderClockThread = function(self, rof)
            local clockTime = rof
            local totalTime = clockTime
            while clockTime > 0.0 and 
                  not self:BeenDestroyed() and 
                  not self.unit:IsDead() do
                self.unit:SetWorkProgress( 1 - clockTime / totalTime )
                clockTime = clockTime - 0.1
                WaitSeconds(0.1)                            
            end
        end,
    
        Main = function(self)
            self.unit:SetBusy(true)
            local bp = self:GetBlueprint()
            #LOG("Weapon " .. bp.DisplayName .. " entered RackSalvoFiringState.")
            self:DestroyRecoilManips()
            local numRackFiring = self.CurrentRackSalvoNumber
            #This is done to make sure that when racks fire together, they fire together.
            if bp.RackFireTogether == true then
                numRackFiring = table.getsize(bp.RackBones)
            end

            # Fork timer counter thread carefully....
            if not self:BeenDestroyed() and 
               not self.unit:IsDead() then
                if bp.RenderFireClock and bp.RateOfFire > 0 then
                    local rof = 1 / bp.RateOfFire                
                    self:ForkThread(self.RenderClockThread, rof)                
                end
            end

            #Most of the time this will only run once, the only time it doesn't is when racks fire together.
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
                    self:CreateProjectileAtMuzzle(muzzle)
                    #Decrement the ammo if they are a counted projectile
                    if bp.CountedProjectile == true then
                        if bp.NukeWeapon == true then
                            self.unit:NukeCreatedAtUnit()
                            
                            #Generate ui notification for automatic nuke ping
        					local launchData = { army = self.unit:GetArmy()-1, location = self:GetCurrentTargetPos()}
							Sync.NukeLaunchData = launchData    
							    
                            self.unit:RemoveNukeSiloAmmo(1)
                        else
                            self.unit:RemoveTacticalSiloAmmo(1)
                        end
                    end
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

            self:DoOnFireBuffs()

            self.FirstShot = false

            self:StartEconomyDrain()

            self:OnWeaponFired()

            # We can fire again after reaching here
            self.HaltFireOrdered = false

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

        # Set a bool so we won't fire if the target reticle is moved
        OnHaltFire = function(self)
            self.HaltFireOrdered = true
        end,
    },

    RackSalvoReloadState = State {
        WeaponWantEnabled = true,
        WeaponAimWantEnabled = true,

        Main = function(self)
            self.unit:SetBusy(true)
            local bp = self:GetBlueprint()
            #LOG("Weapon " .. bp.DisplayName .. " entered RackSalvoReloadState.")
            self:PlayFxRackSalvoReloadSequence()
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
            elseif not self:WeaponHasTarget() and bp.WeaponUnpacks == true and bp.WeaponUnpackLocksMotion != true then
                ChangeState(self, self.WeaponPackingState)
            else
                ChangeState(self, self.IdleState)
            end
        end,

        OnFire = function(self)
        end,
    },

    WeaponUnpackingState = State {
        WeaponWantEnabled = false,
        WeaponAimWantEnabled = false,

        Main = function(self)
            self.unit:SetBusy(true)

            local bp = self:GetBlueprint()
            #LOG("Weapon " .. bp.DisplayName .. " entered WeaponUnpackingState.")
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

        # Override so that it doesn't play the firing sound when
        # we're not actually creating the projectile yet
        OnFire = function(self)
        end,
    },

    WeaponPackingState = State {
        WeaponWantEnabled = true,
        WeaponAimWantEnabled = true,

        Main = function(self)
            self.unit:SetBusy(true)
            local bp = self:GetBlueprint()
            #LOG("Weapon " .. bp.DisplayName .. " entered WeaponPackingState.")
            WaitSeconds(self:GetBlueprint().WeaponRepackTimeout)
            self:AimManipulatorSetEnabled(false)
            self:PlayFxWeaponPackSequence()
            if bp.WeaponUnpackLocksMotion then
                self.unit:SetImmobile(false)
            end
            ChangeState(self, self.IdleState)
        end,

        OnGotTarget = function(self)
			
			-- issue#43 for better stealth
			if self.unit then 
				self.unit:OnGotTarget(self)
			end
		
            if not self:GetBlueprint().ForceSingleFire then
                ChangeState(self, self.WeaponUnpackingState)
            end
        end,

        # Override so that it doesn't play the firing sound when
        # we're not actually creating the projectile yet
        OnFire = function(self)
            local bp = self:GetBlueprint()
            if bp.CountedProjectile == true and not self:GetBlueprint().ForceSingleFire then
                ChangeState(self, self.WeaponUnpackingState)
            end
        end,

    },

    DeadState = State {

        OnEnterState = function(self)
        end,

        Main = function(self)
        end,
    },
    
    ##3 new functions for CBFP
    CheckBallisticAcceleration = function(self, proj)                          # [152]
        if self.CBFP_CalcBallAcc and self.CBFP_CalcBallAcc.Do then
            local acc = CalculateBallisticAcceleration( self, proj, self.CBFP_CalcBallAcc.ProjectilesPerOnFire, self.CBFP_CalcBallAcc.MuzzleSalvoDelay )
            proj:SetBallisticAcceleration( -acc) # change projectile trajectory so it hits the target, cure for engine bug
        end
    end,

    CheckCountedMissileLaunch = function(self)
        # takes care of a unit event function added in CBFP v2. MOved it to here in v4, that way I can get rid of
        # a whole lot of other-mod-incompatible code
        local bp = self:GetBlueprint()
        if bp.CountedProjectile then
            if bp.NukeWeapon then
                self.unit:OnCountedMissileLaunch('nuke')
            else
                self.unit:OnCountedMissileLaunch('tactical')
            end
        end
    end,
    ##end 3 new functions for CBFP
}

KamikazeWeapon = Class(Weapon) {

    OnFire = function(self)
        local myBlueprint = self:GetBlueprint()
        DamageArea(self.unit, self.unit:GetPosition(), myBlueprint.DamageRadius, myBlueprint.Damage, myBlueprint.DamageType or 'Normal', myBlueprint.DamageFriendly or false)
        self.unit:Kill()
    end,
}

BareBonesWeapon = Class(Weapon) {
    Data = {},

    OnFire = function(self)
        local myBlueprint = self:GetBlueprint()
        local myProjectile = self.unit:CreateProjectile( myBlueprint.ProjectileId, 0, 0, 0, nil, nil, nil):SetCollision(false)
        if self.Data then
            myProjectile:PassData(self.Data)
        end
    end,
}


DefaultBeamWeapon = Class(DefaultProjectileWeapon) {

    BeamType = CollisionBeam,

    OnCreate = function(self)
        self.Beams = {}
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
        for rk, rv in bp.RackBones do
            for mk, mv in rv.MuzzleBones do
                local beam
                beam = self.BeamType{
                    Weapon = self,
                    BeamBone = 0,
                    OtherBone = mv,
                    CollisionCheckInterval = bp.BeamCollisionDelay * 10,
                }
                local beamTable = { Beam = beam, Muzzle = mv, Destroyables = {} }
                table.insert(self.Beams, beamTable)
                self.unit.Trash:Add(beam)
                beam:SetParentWeapon(self)
                beam:Disable()
            end
        end
        DefaultProjectileWeapon.OnCreate(self)
    end,

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
        self.BeamDestroyables = {}
        local beam
        local beamTable
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
        if bp.BeamLifetime > 0 then
            self:ForkThread(self.BeamLifetimeThread, beam, bp.BeamLifetime or 1)
        end
        if bp.BeamLifetime == 0 then
            self.HoldFireThread = self:ForkThread(self.WatchForHoldFire, beam)
        end
        if bp.Audio.BeamStart then
            self:PlaySound(bp.Audio.BeamStart)
        end
        if bp.Audio.BeamLoop and self.Beams[1].Beam then
            self.Beams[1].Beam:SetAmbientSound(bp.Audio.BeamLoop, nil)
        end
        self.BeamStarted = true
    end,

    PlayFxWeaponUnpackSequence = function(self)
        local bp = self:GetBlueprint()
        # if it's not a continuous beam, or  if it's a continuous beam that's off...
        if (bp.BeamLifetime > 0) or ((bp.BeamLifetime <= 0) and not self.ContBeamOn) then
            DefaultProjectileWeapon.PlayFxWeaponUnpackSequence(self)
        end
    end,

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
            # if not a continuous beam...
            if (bp.BeamLifetime > 0) then
                self:PlayFxBeamEnd()
            else
                self.ContBeamOn = true
            end
            DefaultProjectileWeapon.WeaponPackingState.Main(self)
        end,
    },

    PlayFxBeamEnd = function(self, beam)
        if not self.unit:IsDead() then
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

    ContinuousBeamFlagThread = function(self)
        WaitTicks(1)
        self.ContBeamOn = false
    end,

    BeamLifetimeThread = function(self, beam, lifeTime) 
        WaitSeconds(lifeTime)
        WaitTicks(1) # added by brute51 fix for beam weapon DPS bug [101]
        self:PlayFxBeamEnd(beam) 
    end, 
    
    WatchForHoldFire = function(self, beam)
        while true do
            WaitSeconds(1)
            #if we're at hold fire, stop beam
            if self.unit and self.unit:GetFireState() == 1 then
                self.BeamStarted = false
                self:PlayFxBeamEnd(beam)
            end
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
            # Only halt fire on the beams that are currently enabled
            if not v.Beam:IsEnabled() then
                continue
            end
            
            self:PlayFxBeamEnd( v.Beam )
        end
    end,
    
    EconomySupportsBeam = function(self)
        local aiBrain = self.unit:GetAIBrain()
        local energyIncome = aiBrain:GetEconomyIncome( 'ENERGY' ) * 10 # per tick to per seconds
        local energyStored = aiBrain:GetEconomyStored( 'ENERGY' )
        local nrgReq = self:GetWeaponEnergyRequired()
        local nrgDrain = self:GetWeaponEnergyDrain()

        if energyStored < nrgReq and energyIncome < nrgDrain then
            return false
        end
        return true    
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

    
}





