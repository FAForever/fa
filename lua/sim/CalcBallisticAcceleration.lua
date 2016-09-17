local XZDist = import('/lua/utilities.lua').XZDistanceTwoVectors

-- This table stores last acceleration and numbers of bombs left in a cluster bomb run
-- format : bomb_data[entityId] = {n_left=<n_left>, acc=<last_acc>}
local bomb_data = {}

CalculateBallisticAcceleration = function(weapon, projectile)
    local bp = weapon:GetBlueprint()
    local MuzzleSalvoSize = bp.MuzzleSalvoSize
    local MuzzleSalvoDelay = bp.MuzzleSalvoDelay
    local acc = 4.75
    local launcher = projectile:GetLauncher()
    if not launcher then return acc end
    local id = launcher:GetEntityId()

    if MuzzleSalvoSize > 1 and bomb_data[id] == nil then
        bomb_data[id] = {acc=4.75, n_left=MuzzleSalvoSize}
    end
    


    -- Get projectile position and velocity
    -- velocity needs to multiplied by 10 due to being returned /tick instead of /s
    local proj = {pos=projectile:GetPosition(), vel=VMult(Vector(launcher:GetVelocity()), 10)}
    local entity = launcher:GetTargetEntity()
    local target

    if entity and IsUnit(entity) then
        -- target is a entity
        target = {pos=entity:GetPosition(), vel=VMult(Vector(entity:GetVelocity()), 10)}
    else
        -- target is something else i.e. attack ground
        target = {pos=weapon:GetCurrentTargetPos(), vel=Vector(0, 0, 0)}
    end

    if not target.pos then -- target no longer alive
        if bomb_data[id] then
            -- use same acceleration as last bomb
            acc = bomb_data[id].acc
            bomb_data[id].n_left = bomb_data[id].n_left - 1
            if bomb_data[id].n_left < 1 then
                bomb_data[id] = nil
            end
        end

        return acc
    end

    -- calculate flat(exclude y-axis) distance and velocity between projectile and target
    local dist = {pos=XZDist(proj.pos, target.pos), vel=XZDist(proj.vel, target.vel)}
    if dist.vel == 0 then return acc end

    if bp.DropBombShort then
        -- deliberately drop bomb short by % ratio, could be useful for torpedo bombers
        dist.pos = dist.pos * math.clamp(1 - bp.DropBombShort, 0, 1)
    end

    if bomb_data[id] ~= nil then -- bomber will drop several bombs
        -- calculate space between bombs, this is multiplied by 0.5
        -- to get the bombs overlapping a bit
        local len = MuzzleSalvoDelay * dist.vel * 0.5
        local current_bomb = MuzzleSalvoSize - bomb_data[id].n_left

        -- calculate the position for this particular bomb
        dist.pos = dist.pos - (len * (MuzzleSalvoSize - 1)) / 2 + len * current_bomb
        bomb_data[id].n_left = bomb_data[id].n_left - 1
        if bomb_data[id].n_left < 1 then
            bomb_data[id] = nil
        end
    end

    -- how many seconds until the bomb hits the target in xz-space
    local time = dist.pos / dist.vel
    if time == 0 then return acc end
    
    
    if bp.BombLineSpread and bp.BombingLines then
        --target.pos = DisplaceTarget(dist.vel, bp.BombLineSpread, time, target.pos)
        local bomblines = math.floor(bp.BombingLines)
        
        if bomblines > 1 then
        
        local offset = 0
        
        if math.mod(bomblines, 2) == 0 then
            offset = bp.BombLineSpread/2
        end --ensure even numbers are spread both to left and right
        
        local minspread = -math.ceil((bomblines-2)*0.5)
        local maxspread = math.ceil((bomblines-1)*0.5)
        --WARN('from' .. minspread .. ' to ' .. maxspread)
        local projbp = projectile:GetBlueprint()
        
            for i=minspread, maxspread do
           
                local newproj = projectile:CreateChildProjectile(projbp.Source)
                local adjvelocity = DisplaceTarget(proj.vel, (bp.BombLineSpread*i)-offset, time)
                newproj:SetVelocity(adjvelocity[1], adjvelocity[2], adjvelocity[3])
                newproj:PassDamageData(projectile.DamageData)
                
            end
            projectile:Destroy() --we dont need it any more
            
        else WARN('BombingLines defined incorrectly in blueprint:' .. launcher:GetBlueprintID() .. ' The value needs to be a positive integer over 1')
        end
        
    end

    -- find out where the target will be at that point in time (it could be moving)
    target.tpos = {target.pos[1] + time * target.vel[1], 0, target.pos[3] + time * target.vel[3]}
    -- what is the height at that future position
    target.tpos[2] = GetSurfaceHeight(target.tpos[1], target.tpos[3])

    -- The basic formula for displacement over time is x = v0*t + 0.5*a*t^2
    -- x: displacement, v0: initial velocity, a: acceleration, t: time
    -- v0 is zero due to projectiles not inheriting y-speed of bomber
    -- now we can calculate what acceleration we need to make it hit the target in the y-axis
    -- a = 2 * (1/t)^2 * x
    
    


    acc = 2 * math.pow(1 / time , 2) * (proj.pos[2] - target.tpos[2])
    

    if bomb_data[id] then
        -- store last acceleration in case target dies in the middle of carpet bomb run
        bomb_data[id].acc = acc
    end

    
    return acc
end

DisplaceTarget = function(vel, disp, time)
    --here we will be adding a 2d displacement to our target position, for lots of interesting things.
    --we will be working in 2d, but our vector will be 3d so we can add it easily later.
    --for that we just set y to 0 and call it a day.
    
    
    --local direction = Vector(vel[1], 0, vel[3])
    --[x][z] goes to [-z][x] for right hand and [z][-x] for left hand
    local perpendicular = Vector(vel[3], 0, -vel[1]) --we want to displace perpendicular to the direction our bomb is going in
    local dist = math.sqrt(perpendicular[1]*perpendicular[1] + perpendicular[3]*perpendicular[3]) --the length of our vector
    
    displacement = VMult(perpendicular, (disp/dist)) --obtain unit vector AND scale it in the same line! efficiency!
    --1/dist would be the unit vector, then we just multiply that by disp but we are being cool here.
    local velocitychange = VMult(displacement, 1/time) --get the velocity we need to add so we get into the right place. probably.
    --since we are going perpendicular to the bomb path, this doesnt affect CalculateBallisticAcceleration and so we dont need to change the target position.
    
    
    local velocity = VAdd(vel, velocitychange) --add our adjusted speed to our projectile speed.
    
    return velocity
end