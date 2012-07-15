#*****************************************************************************
#* File: lua/selfdestruct.lua
#* Summary: Self destruct sim code
#*
#* Copyright © 2008 Gas Powered Games, Inc.  All rights reserved.
#*****************************************************************************

function ToggleSelfDestruct(data)
    -- supress self destruct in tutorial missions as they screw up the mission end
    if ScenarioInfo.tutorial and ScenarioInfo.tutorial == true then
        return
    end
    if data.owner != -1 then
        local unitEntities = {}
        for _, unitId in data.units do
            local unit = GetEntityById(unitId)
            if OkayToMessWithArmy(unit:GetArmy()) then
                table.insert(unitEntities, unit)
            end
        end
        if table.getsize(unitEntities) > 0 then
            local togglingOff = false
            for _, unit in unitEntities do
                if unit.SelfDestructThread then
                    togglingOff = true
                    KillThread(unit.SelfDestructThread)
                    unit.SelfDestructThread = false
                    local entityId = unit:GetEntityId()
                    CancelCountdown(entityId)
                end
            end
            if not togglingOff then
                for _, unitEnt in unitEntities do
                    local unit = unitEnt
                    local entityId = unit:GetEntityId()
					local bp = unit:GetBlueprint()
					if bp.Defense.InstantDeath then
						unit:Kill()
					else
						StartCountdown(entityId)
						unit.SelfDestructThread = ForkThread(function()
							WaitSeconds(5)
							unit:Kill()
						end)
					end
                end
            end
        end
    end
end

