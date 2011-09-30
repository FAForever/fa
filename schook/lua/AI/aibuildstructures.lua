do

function AddToBuildQueue(aiBrain, builder, whatToBuild, buildLocation, relative)
    if not builder.EngineerBuildQueue then
        builder.EngineerBuildQueue = {}
    end
    # put in build queue.. but will be removed afterwards... just so that it can iteratively find new spots to build  
     AIUtils.EngineerTryReclaimCaptureAreaSorian(aiBrain, builder, BuildToNormalLocation(buildLocation)) 
     aiBrain:BuildStructure( builder, whatToBuild, buildLocation, false )       
    
    local newEntry = {whatToBuild, buildLocation, relative}
    
    table.insert(builder.EngineerBuildQueue, newEntry)
end

function AINewExpansionBase( aiBrain, baseName, position, builder, constructionData )
    local radius = constructionData.ExpansionRadius or 100
    # PBM Style expansion bases here
    if aiBrain:PBMHasPlatoonList() then
    # Figure out what type of builders to import
        local expansionTypes = constructionData.ExpansionTypes
    if not expansionTypes then
        expansionTypes = { 'Air', 'Land', 'Sea', 'Gate' }
    end

    # Check if it already exists
        for k,v in aiBrain.PBM.Locations do
            if v.LocationType == baseName then
                return
            end
        end
        aiBrain:PBMAddBuildLocation( position, radius, baseName, true )

        for num, typeString in expansionTypes do
            for bNum, builder in aiBrain.PBM.Platoons[typeString] do
                if builder.LocationType == 'MAIN' and CheckExpansionType( typeString, ScenarioInfo.BuilderTable[typeString][builder.BuilderName].ExpansionExclude )  then
                    local pltnTable = {}
                    for dField, data in builder do
                        if dField == 'LocationType' then
                            pltnTable[dField] = baseName
                        elseif dField == 'PlatoonHandle' then
                            pltnTable[dField] = false
                        elseif dField == 'PlatoonTimeOutThread' then
                            pltnTable[dField] = nil
                        else
                            pltnTable[dField] = data
                        end
                    end
                    table.insert( aiBrain.PBM.Platoons[typeString], pltnTable )
                    aiBrain.PBM.NeedSort[typeString] = true
                end
            end
        end

    else
        if not aiBrain.BuilderManagers or aiBrain.BuilderManagers[baseName] or not builder.BuilderManagerData then
            #LOG('*AI DEBUG: ARMY ' .. aiBrain:GetArmyIndex() .. ': New Engineer for expansion base - ' .. baseName)
            builder.BuilderManagerData.EngineerManager:RemoveUnit(builder)
            aiBrain.BuilderManagers[baseName].EngineerManager:AddUnit(builder, true)
            return
        end
        
        aiBrain:AddBuilderManagers( position, radius, baseName, true )
        
        # Move the engineer to the new base managers
        builder.BuilderManagerData.EngineerManager:RemoveUnit(builder)
        aiBrain.BuilderManagers[baseName].EngineerManager:AddUnit(builder, true)
        
        # Iterate through bases finding the value of each expansion
        local baseValues = {}
        local highPri = false
        for templateName, baseData in BaseBuilderTemplates do
            local baseValue = baseData.ExpansionFunction( aiBrain, position, constructionData.NearMarkerType )
            table.insert( baseValues, { Base = templateName, Value = baseValue } )
            if not highPri or baseValue > highPri then
                highPri = baseValue
            end
        end
        
        # Random to get any picks of same value
        local validNames = {}
        for k,v in baseValues do
            if v.Value == highPri then
                table.insert( validNames, v.Base )
            end
        end
        local pick = validNames[ Random( 1, table.getn(validNames) ) ]
        
        # Error if no pick
        if not pick then
            LOG('*AI DEBUG: ARMY ' .. aiBrain:GetArmyIndex() .. ': Layer Preference - ' .. per .. ' - yielded no base types at - ' .. locationType )
        end

        # Setup base        
        #LOG('*AI DEBUG: ARMY ' .. aiBrain:GetArmyIndex() .. ': Expanding using - ' .. pick .. ' at location ' .. baseName)
        import('/lua/ai/AIAddBuilderTable.lua').AddGlobalBaseTemplate(aiBrain, baseName, pick )
        
        # If air base switch to building an air factory rather than land
        if ( string.find(pick, 'Air') or string.find(pick, 'Water') ) then
            #if constructionData.BuildStructures[1] == 'T1LandFactory' then
            #    constructionData.BuildStructures[1] = 'T1AirFactory'
            #end
			local numToChange = BaseBuilderTemplates[pick].BaseSettings.FactoryCount.Land
			for k,v in constructionData.BuildStructures do
				if constructionData.BuildStructures[k] == 'T1LandFactory' and numToChange <= 0 then
					constructionData.BuildStructures[k] = 'T1AirFactory'
				elseif constructionData.BuildStructures[k] == 'T1LandFactory' and numToChange > 0 then
					numToChange = numToChange - 1
				end
			end
        end
    end    
end

function DoHackyLogic(buildingType, builder)
    if buildingType == 'T2StrategicMissile' then
        local unitInstance = false
        
        builder:ForkThread(function()
            while true do
                if not unitInstance then
                    unitInstance = builder:GetUnitBeingBuilt()
                end
                aiBrain = builder:GetAIBrain()
                if unitInstance then
                    TriggerFile.CreateUnitStopBeingBuiltTrigger( function(unitBeingBuilt)
                        local newPlatoon = aiBrain:MakePlatoon('', '')
                        aiBrain:AssignUnitsToPlatoon(newPlatoon, {unitBeingBuilt}, 'Attack', 'None')
                        newPlatoon:StopAI()
                        newPlatoon:ForkAIThread(newPlatoon.TacticalAI)
                    end, unitInstance )
                    break
                end
                WaitSeconds(1)
            end
        end)
    end
end

end