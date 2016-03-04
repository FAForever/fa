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
        if self.TotalTime == 0 then
            local radius = self.Radius
        
            -- Hit units
            local units = brain:GetUnitsAroundPoint(categories.ALLUNITS, pos, radius)
            for _, u in units do
                Damage(launcher, pos, u, self.Damage, 'Nuke')
                
                -- Damage won't usually hit its own instigator
                if u == launcher then
                    Damage(nil, pos, u, self.Damage, 'Nuke')
                end
            end
            
            -- Hit reclaim
            local rect = {pos[1] - radius, pos[3] - radius, pos[1] + radius, pos[1] + radius}
            local reclaim = GetReclaimablesInRect(unpack(rect)) or {}
            for _, r in reclaim do
                if IsProp(r) and VDist3(r:GetPosition(), pos) <= radius then
                    Damage(launcher, pos, r, self.Damage, 'Nuke')
                end
            end
            
            -- Get rid of trees
            DamageArea(launcher, pos, radius, 1, 'Force', false, false)
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
