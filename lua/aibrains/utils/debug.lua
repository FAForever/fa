
function AIStateMachineVisualize()
    local seen = { }

    while true do

        for k, v in seen do
            seen[k] = nil
        end

        local selectedUnits = DebugGetSelection()
        if selectedUnits and type(selectedUnits) == 'table' then
            for k = 1, table.getn(selectedUnits) do
                local selectedUnit = selectedUnits[k]
                local aiPlatoonReference = selectedUnit.AIPlatoonReference
                if aiPlatoonReference and not seen[aiPlatoonReference] then
                    seen[aiPlatoonReference] = true
                    if aiPlatoonReference.Visualize then
                        local ok, msg = pcall(aiPlatoonReference.Visualize, aiPlatoonReference)
                        if not ok then
                            WARN(msg)
                        end
                    end
                end
            end
        end

        WaitTicks(1)
    end
end


function AIStateMachineSyncMessages()
    while true do
        local units = DebugGetSelection()
        if units and units[1] then
            local unit = units[1]
            if unit.AIPlatoonReference then
                Sync.AIPlatoonInfo = {
                    PlatoonInfo = unit.AIPlatoonReference:GetDebugInfo(),
                    EntityId = unit.EntityId,
                    BlueprintId = unit.Blueprint.BlueprintId,
                    Position = unit:GetPosition(),
                }
            end
        end

        WaitTicks(10)
    end
end