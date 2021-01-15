function smartEngi()
    -- local engi = GetIdleEngineers()[1]
    print( 'lol' )
end
    local avgPoint = {0,0}

    avgPoint[1] = avgPoint[1] + engi:GetPosition()[1]
    avgPoint[2] = avgPoint[2] + engi:GetPosition()[3]
    
    local target_position = engi:GetPosition()
    target_position[1] = target_position[1] + 10

    avgPoint[1] = target_position[1] - avgPoint[1]
    avgPoint[2] = target_position[3] - avgPoint[2]

    local rotation = math.atan(avgPoint[1]/avgPoint[2])
    rotation = rotation * 180 / math.pi
    if avgPoint[2] < 0 then
        rotation = rotation + 180
    end
    print( 20 )
    local cb = {Func="AttackMove", Args={Target=target_position, Rotation = rotation, Clear=false}}
    print( 21 )
    SimCallback(cb, true)
    print( 22 )
    -- AddDefaultCommandFeedbackBlips(target_position)
    -- local engi = nil
    -- local avgPoint = nil
    -- local rotation = nil
    -- EndCommandMode(true)
    print( '...' )

end