local CMolecularCannonProjectile = import("/lua/cybranprojectiles.lua").CMolecularCannonProjectile

local velocityTracker = function(self) 
    local entityId = self:GetEntityId()
    local v0 = {self:GetVelocity()}
    local t0 = GetGameTick()
    local dt = 5
            local launcherVel = {self:GetLauncher():GetVelocity()}
        local launcherHorzSpeed = math.sqrt(launcherVel[1] * launcherVel[1] + launcherVel[3] * launcherVel[3])
    LOG(string.format("Proj %s: launcher velocity/horzspeed: {%f, %f} |%f|"
        , entityId
        , launcherVel[1]
        , launcherVel[3]
        , launcherHorzSpeed
    ))
    WaitTicks(dt)
    while not self:BeenDestroyed() do
        local v = {self:GetVelocity()}
        local t = GetGameTick()
        local spd = self:GetCurrentSpeed()
        LOG(string.format("Proj %s: horz speed diff with launcher: %f (%+.2g%%)\tvert accel (%d):"
            , entityId
            -- , v[1]-launcherVel[1]
            -- , v[3]-launcherVel[3]
            , spd - launcherHorzSpeed
            , spd/launcherHorzSpeed * 100 - 100
            , (v[2] - v0[2])/(t-t0)
        ))
        if math.sqrt(v0[1]*v0[1]+v0[3]*v0[3]) - spd == 0 then
            LOG(string.format("Proj %s: Speed has stopped changing"
                , entityId
            ))
            break
        end
        t0 = t
        v0 = table.deepcopy(v)
        WaitTicks(dt)
    end
end

--- Cybran Molecular Cannon
---@class CDFCannonMolecular01: CMolecularCannonProjectile
CDFCannonMolecular01 = ClassProjectile(CMolecularCannonProjectile) {
    OnCreate = function(self, inWater)
        CMolecularCannonProjectile.OnCreate(self, inWater)
        self:ForkThread(velocityTracker, self)
    end,
}
TypeClass = CDFCannonMolecular01