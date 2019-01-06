function distanceRectPoint(rect, p)
    local dx = math.max(rect[1] - p[1], 0, p[1] - rect[3]);
    local dy = math.max(rect[2] - p[2], 0, p[2] - rect[4]);
    return math.sqrt(dx*dx + dy*dy);
end


function ReclaimGround(command)
            local Units={}
            for id, unit in command.Units do
                table.insert(Units, unit:GetEntityId())
            end 
            local cb = {
                     Func = 'ReclaimGround',
                     Args = {
                         Units = Units, Location = command.Target.Position,
                         Move = command.Target.Type == 'Position',
                         From = GetFocusArmy()
                     }
                 }
            SimCallback(cb, true)
			
end


function ReclaimGroundSim(units, location, doMove)
    local MAX_SIZE = 5
    local range = 99 -- choose minimum distance below

    for _, u in units do
        local bp = u:GetBlueprint()
        range = math.min(bp.Economy.MaxBuildDistance or 10, range) + MAX_SIZE
    end
    local reclaimTargets = GetReclaimablesInRect(location[1] - range, location[3] - range, location[1] + range, location[3] + range)
    reclaims = {}
    for _, r in reclaimTargets do
        if(not IsUnit(r)) then
            local bp = r:GetBlueprint()
            local type = bp.ScriptClass -- tree, wreckage etc

            local sizeX = bp.Footprint.SizeX
            local sizeZ = bp.Footprint.SizeZ
            local pos = location
            local rpos = r.CachePosition
            local rect = {rpos[1]-sizeX*0.5, rpos[3]-sizeZ*0.5, rpos[1]+sizeX*0.5, rpos[3]+sizeZ*0.5}

            if(VDist3(r.CachePosition, location)  <= range and distanceRectPoint(rect, {pos[1], pos[3]}) < range - MAX_SIZE) then
                table.insert(reclaims, r)
            end
        end
    end
    if(reclaims) then
        if(doMove) then
            IssueMove(units, location)
        end
        --table.sort(reclaims, function(a, b) return a.(parametr) > b.(parametr) end)
		for _, r in reclaims do
            IssueReclaim(units, r)
        end
    end
    
end
