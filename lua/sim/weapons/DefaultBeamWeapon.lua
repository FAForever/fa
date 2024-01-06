
local DefaultProjectileWeapon = import("/lua/sim/defaultweapons.lua").DefaultProjectileWeapon
local CollisionBeam = import("/lua/sim/collisionbeam.lua").CollisionBeam

---@class DefaultBeamWeapon : DefaultProjectileWeapon
---@field DisableBeamThreadInstance? thread
---@field Beams { Beam: CollisionBeam, Muzzle: string, Destroyables: table}[]
---@field BeamStarted boolean
DefaultBeamWeapon = ClassWeapon(DefaultProjectileWeapon) {
    BeamType = CollisionBeam,

    ---@param self DefaultBeamWeapon
    OnCreate = function(self)
        DefaultProjectileWeapon.OnCreate(self)

        self.Beams = {}

        -- Ensure that the weapon blueprint is set up properly for beams
        local bp = self.Blueprint
        if not bp.BeamCollisionDelay then
            local strg = '*ERROR: No BeamCollisionDelay specified for beam weapon, aborting setup.  Weapon: ' ..
                bp.DisplayName .. ' on Unit: ' .. self.unit.UnitId
            error(strg, 2)
            return
        end
        if not bp.BeamLifetime then
            local strg = '*ERROR: No BeamLifetime specified for beam weapon, aborting setup.  Weapon: ' ..
                bp.DisplayName .. ' on Unit: ' .. self.unit.UnitId
            error(strg, 2)
            return
        end

        -- Create the beam
        for _, rack in bp.RackBones do
            for _, muzzle in rack.MuzzleBones do
                local beam
                beam = self.BeamType {
                    Weapon = self,
                    BeamBone = 0,
                    OtherBone = muzzle,
                    CollisionCheckInterval = bp.BeamCollisionDelay * 10, -- Why is this multiplied by 10? IceDreamer
                }
                local beamTable = { Beam = beam, Muzzle = muzzle, Destroyables = {} }
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

        -- find beam that matches the muzzle
        local beam
        for _, v in self.Beams do
            if v.Muzzle == muzzle then
                beam = v.Beam
                break
            end
        end

        -- edge case: no beam that matches the muzzle
        if not beam then
            error('*ERROR: We have a beam created that does not coincide with a muzzle bone.  Internal Error, aborting beam weapon.'
                , 2)
            return
        end

        -- edge case: we're already enabled
        if beam:IsEnabled() then
            return
        end

        -- enable the beam
        beam:Enable()

        -- non-continious beams that just end
        if bp.BeamLifetime > 0 then
            self:ForkThread(self.BeamLifetimeThread, beam, bp.BeamLifetime or 1)
        end

        -- continious beams
        if bp.BeamLifetime == 0 then
            self.HoldFireThread = self:ForkThread(self.WatchForHoldFire, beam)
        end

        -- manage audio of the beam
        local audio = bp.Audio
        local beamStart = audio.BeamStart
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

    ---@param self DefaultBeamWeapon
    OnGotTarget = function(self)
        DefaultProjectileWeapon.OnGotTarget(self)
        local blueprint = self.Blueprint
        if blueprint.BeamLifetime == 0 then
            local disableBeamThread = self.DisableBeamThreadInstance
            if disableBeamThread then
                disableBeamThread:Destroy()
            end
        end
    end,

    ---@param self DefaultBeamWeapon
    OnLostTarget = function(self)
        DefaultProjectileWeapon.OnLostTarget(self)
        if self.Blueprint.BeamLifetime == 0 then
            local thread = ForkThread(self.DisableBeamThread, self)
            self.Trash:Add(thread)
            self.DisableBeamThreadInstance = thread
        end
    end,

    ---@param self DefaultBeamWeapon
    DisableBeamThread = function(self)
        WaitTicks(11)
        for _, info in self.Beams do
            self:PlayFxBeamEnd(info.Beam)
        end
        self.DisableBeamThreadInstance = nil
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
        if not self.EconDrain and
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
        for _, info in self.Beams do
            local b = info.Beam
            if b:IsEnabled() then
                self:PlayFxBeamEnd(b)
            end
        end
    end,

    -- Weapon States Section

    IdleState = State(DefaultProjectileWeapon.IdleState) {
        Main = function(self)
            DefaultProjectileWeapon.IdleState.Main(self)
            self:PlayFxBeamEnd()
            self:ForkThread(self.ContinuousBeamFlagThread)
        end,
    },

    WeaponPackingState = State(DefaultProjectileWeapon.WeaponPackingState) {
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

    RackSalvoFireReadyState = State(DefaultProjectileWeapon.RackSalvoFireReadyState) {
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

    -- Kill the beam if hold fire is requested
    ---@deprecated
    ---@param self DefaultBeamWeapon
    ---@param beam CollisionBeam
    WatchForHoldFire = function(self, beam)
    end,
}
