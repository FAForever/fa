local SemiBallisticComponent = import("/lua/sim/projectiles/components/semiballisticcomponent.lua").SemiBallisticComponent

---@class TacticalMissileComponent : SemiBallisticComponent
TacticalMissileComponent = ClassSimple(SemiBallisticComponent) {

    ---@param self TacticalMissileComponent | Projectile
    MovementThread = function(self)
        local blueprintPhysics = self.Blueprint.Physics

        -- are we a wiggler?
        local zigZagger = false
        if blueprintPhysics.MaxZigZag and
            blueprintPhysics.MaxZigZag > self.MaxZigZagThreshold then
            zigZagger = true
        end

        -- launch
        local launchTurnRateRange = self.LaunchTurnRateRange
        local launchTurnRate = self.LaunchTurnRate + launchTurnRateRange * (2 * Random() - 1)
        self:SetTurnRate(launchTurnRate)

        local launchTicksRange = self.LaunchTicksRange
        local launchTicks = self.LaunchTicks + Random(-launchTicksRange, launchTicksRange)
        WaitTicks(launchTicks)

        -- boost
        local boostTurnRate, boostTime = self:TurnRateFromAngleAndHeight()
        self:SetTurnRate(boostTurnRate)       
        WaitTicks(boostTime * 10 + 1)

        -- glide
        local glideTurnRate, glideTime = self:TurnRateFromDistance()

        if zigZagger then
            -- try to create a smooth transition
            if glideTime > 4.0 then
                for k = 1, 10 do
                    WaitTicks(4)
                    self:SetTurnRate(5 * k)
                end
                glideTime = glideTime - 4.0
            elseif glideTime > 2.0 then
                for k = 1, 5 do
                    WaitTicks(4)
                    self:SetTurnRate(10 * k)
                end
                glideTime = glideTime - 2.0
            elseif glideTime > 1.0 then
                for k = 1, 5 do
                    WaitTicks(2)
                    self:SetTurnRate(10 * k)
                end
                glideTime = glideTime - 1.0
            else
                self:SetTurnRate(50)
            end
        else
            self:SetTurnRate(glideTurnRate)
        end

        -- wait until we've allegedly hit our target
        self:SetLifetime((glideTime + 3))
        WaitTicks((glideTime + 1) * 10)

        -- then, if we still exist, we just want to stop existing. Therefore we find
        -- our way to the ground

        if not self:BeenDestroyed() then

            -- target the ground below us slowly turn towards the ground so that we do not fly off indefinitely
            local position = self:GetPosition()
            position[2] = GetSurfaceHeight(position[1], position[3])
            self:SetNewTargetGround(position)

            for k = 4, 1, -1 do
                if IsDestroyed(self) then
                    break
                end

                self:SetTurnRate(10 * k)
                WaitTicks(6)
            end
        end
    end,
}
