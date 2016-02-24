NukeAOE = Class() {
    Damage = false,
    Radius = false,
    Ticks = false,
    TotalTime = false,

    OnCreate = function(self, damage, radius, ticks, totalTime)
        self.Damage = damage
        self.Radius = radius
        self.Ticks = ticks
        self.TotalTime = totalTime
    end,
    
    DoNukeDamage = function(self, launcher, pos, brain)
        local units = brain:GetUnitsAroundPoint(categories.ALLUNITS, pos, self.Radius)

        if self.TotalTime == 0 then
            for k, v in units do
                Damage(launcher, pos, v, self.Damage, 'Nuke')
            end
        else
            ForkThread(self.SlowNuke, self, launcher, pos)
        end
    end,
    
    SlowNuke = function(self, launcher, pos)
        local ringWidth = (self.Radius / self.Ticks)
        local tickLength = (self.TotalTime / self.Ticks)

        -- Since we're not allowed to have an inner radius of 0 in the DamageRing function,
        -- I'm manually executing the first tick of damage with a DamageArea function.
        DamageArea(launcher, pos, ringWidth, self.Damage, 'Nuke', true, true)
        WaitSeconds(tickLength)
        for i = 2, self.Ticks do
            DamageRing(launcher, pos, ringWidth * (i - 1), ringWidth * i, self.Damage, 'Nuke', true, true)
            WaitSeconds(tickLength)
        end
    end,
}
