#*****************************************************************************
#* File: lua/recall.lua
#* Summary: Recall the ACU.
#*
#* Copyright © 2013 Forged Alliance Forever
#*****************************************************************************

function ToggleRecall(data)

    local aiBrain = GetArmyBrain(GetFocusArmy())

    local units = aiBrain:GetListOfUnits( categories.COMMAND, false )
    
    for _, unit in units do
        if OkayToMessWithArmy(unit:GetArmy()) then
            unit:Recall()
        end
    end
end
