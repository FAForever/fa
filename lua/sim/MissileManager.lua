
-- import 'dem things
local TMissileCruiseProjectileOpti = import('/lua/terranprojectiles.lua').TMissileCruiseProjectileOpti

-- upvalue for performance (globals)
local VDist2 = VDist2
local ForkThread = ForkThread
local WaitTicks = coroutine.yield
local setmetatable = setmetatable

-- upvalue for performance (math functions)
local MathPi = math.pi

-- upvalue for performance (moho functions)
local EntityBeenDestroyed = _G.moho.entity_methods.BeenDestroyed
local EntityGetPosition = _G.moho.entity_methods.GetPosition
local EntityGetPositionXYZ = _G.moho.entity_methods.GetPositionXYZ
local EntitySetCollisionShape = _G.moho.entity_methods.SetCollisionShape

local ProjectileSetTurnRate = _G.moho.projectile_methods.SetTurnRate
local ProjectileGetCurrentTargetPosition = _G.moho.projectile_methods.GetCurrentTargetPosition

-- functions to hook missiles in
AddMissile2Ticks = false
-- AddMissile4Ticks = false 
-- AddMissile8Ticks = false 
-- AddMissile10Ticks = false

do 
    -- keeps track of the missiles in various stages
    local Stage1 = { }
    local Stage2 = { }

    local Stage1Next = 1
    local Stage2Next = 1

    -- tells the garbage collector it doesn't have to wait for us
    local Weak = { __mode = "v" }
    setmetatable(Stage1, Weak)
    setmetatable(Stage2, Weak)

    -- provide implementation of the function above
    AddMissile2Ticks = function(missile)
        Stage1[Stage1Next] = missile 
        Stage1Next = Stage1Next + 1
    end

    -- run the behavior
    ForkThread(
        function()
            while true do 

                -- adjust missiles that reached stage 2
                for k = 1, Stage2Next - 1 do 
        
                    -- get the missile and check if it is still valid
                    local missile = Stage2[k]
                    if not missile or EntityBeenDestroyed(missile) then 
                        continue 
                    end
        
                    -- compute distance
                    local tpos = ProjectileGetCurrentTargetPosition(missile)
                    local px, _, pz = EntityGetPositionXYZ(missile)
                    local dist = VDist2(px, pz, tpos[1], tpos[3])
        
                    -- compute multiplier
                    local multiplier = 200 / dist
                    if multiplier < 1.0 then 
                        multiplier = 1.0
                    end
        
                    -- set turn rate accordingly
                    ProjectileSetTurnRate(missile, multiplier * 10)
                end
        
                -- switch them up
                local temp = Stage2
                Stage2 = Stage1 
                Stage1 = temp 
        
                -- switch them up
                Stage2Next = Stage1Next
                Stage1Next = 1
        
                -- wait a bit
                WaitTicks(2)
            end
        end
    )
end