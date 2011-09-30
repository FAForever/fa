do

local FrigatesFirst = { Frigates, Destroyers, Battleships, Cruisers, Carriers, Subs, NukeSubs, Sonar, RemainingCategory }
local DestroyersFirst = { Destroyers, Frigates, Battleships, Cruisers, Carriers, Subs, NukeSubs, Sonar, RemainingCategory }
local CruisersFirst = { Cruisers, Carriers, Battleships, Destroyers, Frigates, Subs, NukeSubs, Sonar, RemainingCategory }
local BattleshipsFirst = { Battleships, Destroyers, Frigates, Cruisers, Carriers, Subs, NukeSubs, Sonar, RemainingCategory }
local CarriersFirst = { Carriers, Cruisers, Battleships, Destroyers, Frigates, Subs, NukeSubs, Sonar, RemainingCategory }
local Subs = { Subs, NukeSubs, RemainingCategory }
local SonarFirst = { Sonar, Carriers, Cruisers, Battleships, Destroyers, Frigates, Subs, NukeSubs, Sonar, RemainingCategory }

function BlockBuilderLand(unitsList, formationBlock, categoryTable, spacing)
    spacing = spacing or 1
    local numRows = table.getn(formationBlock)
    local i = 1
    local whichRow = 1
    local whichCol = 1
    local currRowLen = table.getn(formationBlock[whichRow])
    local rowType = false
    local formationLength = 0
    local inserted = false
	
	if unitsList.Experimentals and unitsList.Experimentals > 0 then
		spacing = 2
	end
	
    while unitsList.UnitTotal >= i do
        if whichCol > currRowLen then
            if whichRow == numRows then
                whichRow = 1
                if formationBlock.RowBreak then
                    formationLength = formationLength + 1 + formationBlock.RowBreak
                else
                    formationLength = formationLength + 1
                end
            else
                whichRow = whichRow + 1
                if formationBlock.LineBreak then
                    formationLength = formationLength + 1 + formationBlock.LineBreak
                else
                    formationLength = formationLength + 1
                end
                rowType = false
            end
            whichCol = 1
            currRowLen = table.getn(formationBlock[whichRow])
        end
        local currColSpot = GetColSpot(currRowLen, whichCol) # Translate whichCol to correct spot in row
        local currSlot = formationBlock[whichRow][currColSpot]
        for numType, type in currSlot do
            if inserted then
                break
            end
            for numGroup, group in type do
                if not formationBlock.HomogenousRows or (rowType == false or rowType == type) then
                    if unitsList[group] > 0 then
                        #local xPos = (math.ceil(whichCol/2)/2) - 0.25
                        local xPos
                        if math.mod( currRowLen, 2 ) == 0 then
                            xPos = math.ceil(whichCol/2) - .5
                            if not (math.mod(whichCol, 2) == 0) then
                                xPos = xPos * -1
                            end
                        else
                            if whichCol == 1 then
                                xPos = 0
                            else
                                xPos = math.ceil( ( (whichCol-1) /2 ) )
                                if not (math.mod(whichCol, 2) == 0) then
                                    xPos = xPos * -1
                                end
                            end
                        end
                        if formationBlock.HomogenousRows and not rowType then
                            rowType = type
                        end
                        table.insert(FormationPos, {xPos*spacing, -formationLength*spacing, categoryTable[group], formationLength, true})
                        inserted = true
                        unitsList[group] = unitsList[group] - 1
                        break
                    end
                end
            end
        end
        if inserted then
            i = i + 1
            inserted = false
        end
        whichCol = whichCol + 1
    end
    return FormationPos
end

end
