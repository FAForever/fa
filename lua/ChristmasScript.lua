local ScenarioUtils = import('/lua/sim/ScenarioUtilities.lua')
local ScenarioFramework = import('/lua/ScenarioFramework.lua')


function Init()
    ForkThread(Create_Christmas_Presents)
end


function Create_Christmas_Presents()
    math.randomseed(1)
    
    local ListOfProps = {}
    local posx, posy = GetMapSize()
    local Map_Area = {
        ["x0"] = 0,
        ["y0"] = 0,
        ["x1"] = posx,
        ["y1"] = posy 
    }

    local i = 1
    local allprops = GetReclaimablesInRect(Map_Area)
    local StoneName = {'rock', 'boulder', 'fieldstone', 'iceberg'}
    local number_of_props = table.getn(allprops)

    for _, r in allprops or {} do
        local replaceit = 0
        local propbp = r:GetBlueprint()
        if propbp.ScriptClass == 'Tree' then
            replaceit = 0.035
        elseif string.find(propbp.Interface.HelpText, 'Rock') then  
            replaceit = 0.09
        end
        if number_of_props > 0 then
            replaceit = replaceit * 10000/number_of_props
        end
        if (replaceit > 0) then
            if(math.random(100) < 100 * replaceit) then
                local prop = r
                ListOfProps[i] = prop
                r:Destroy()
                i = i + 1
            end
        end
    end

    local color_gifts = {'blue', 'green', 'green2', 'pink', 'red', 'yellow'}
    local new_props = {}
    for _, color in color_gifts do
        new_props[table.getn(new_props)+1] = '/props/gift_' .. color .. '/gift_' .. color .. '_prop.bp'
    end
    for k = 1, 3 do
        new_props[table.getn(new_props)+ 1] = '/props/cookie/cookie_prop.bp'
    end
    new_props[table.getn(new_props)+ 1] = '/props/snowman/snowman_prop.bp'
    
    for _, present in ListOfProps or {} do
    local proptype = math.ceil(math.random(table.getn(new_props)))
        local NewGift = CreateProp( VECTOR3(present:GetPosition()['x'],
                            present:GetPosition()['y'],
                            present:GetPosition()['z'] ),
                            new_props[proptype])
                            
        -- set the reclaim values to match the removed prop
        NewGift:SetMaxReclaimValues( 5, present:GetBlueprint().Economy.ReclaimMassMax, present:GetBlueprint().Economy.ReclaimEnergyMax)
        -- determine the new size of the prop
        local new_size = ( (present:GetBlueprint().Economy.ReclaimMassMax + present:GetBlueprint().Economy.ReclaimEnergyMax/10 + math.random(25)) )   -- + 
        -- map the size of the prop into the allowed range        
        new_size = 0.02 + 0.064*(new_size-3)/135
        if(new_size < 0.02) then
            new_size = 0.02
        elseif (new_size > 0.084) then
            new_size = 0.084
        end
        if proptype == 10 then
            new_size = 9 * new_size
        end
        NewGift:SetScale(new_size*0.9)
        
        local orient = math.random(628)/100-3.14
        local vec = VECTOR3(math.cos(orient),0,math.sin(orient))
        NewGift:SetOrientation(OrientFromDir( vec ), true)
    end
end