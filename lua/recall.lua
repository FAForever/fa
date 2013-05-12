#*****************************************************************************
#* File: lua/recall.lua
#* Summary: Recall the ACU.
#*
#* Copyright © 2013 Forged Alliance Forever
#*****************************************************************************

function ToggleRecall(data)
    if not OkayToMessWithArmy(data.From) then return end
    local aiBrain = GetArmyBrain(data.From)

    if aiBrain:IsDefeated() then return end
    
    local units = aiBrain:GetListOfUnits( categories.COMMAND, false )
    
    for _, unit in units do
        unit:Recall()
    end
end
