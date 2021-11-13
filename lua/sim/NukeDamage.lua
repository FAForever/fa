local ipairs = ipairs
local ForkThread = ForkThread
local DamageArea = DamageArea
local next = next
local DamageRing = DamageRing

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

    DoNukeDamage = function(self, instigator, pos, brain, army, damageType)
        if self.TotalTime == 0 then
            import('/lua/sim/DamageArea.lua').DamageArea(instigator, pos, self.Radius, self.Damage, (damageType or 'Nuke'), true, true, brain, army)
        else
            ForkThread(self.SlowNuke, self, instigator, pos)
        end
    end,

    SlowNuke = function(self, instigator, pos)
        local ringWidth = (self.Radius / self.Ticks)
        local tickLength = (self.TotalTime / self.Ticks)

        -- Since we're not allowed to have an inner radius of 0 in the DamageRing function,
        -- I'm manually executing the first tick of damage with a DamageArea function.
        DamageArea(instigator, pos, ringWidth, self.Damage, 'Nuke', true, true)
        WaitSeconds(tickLength)
        for i = 2, self.Ticks do
            DamageRing(instigator, pos, ringWidth * (i - 1), ringWidth * i, self.Damage, 'Nuke', true, true)
            WaitSeconds(tickLength)
        end
    end,
}
