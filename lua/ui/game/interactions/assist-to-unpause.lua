
--- Unpauses a
---@param guardees UserUnit[]
---@param target UserUnit
local function OnGuardUnpause(guardees, target)
    local prefs = Prefs.GetFromCurrentProfile('options.assist_to_unpause')
    if prefs == 'On' or
        (
        prefs == 'ExtractorsAndRadars' and
            EntityCategoryContains((categories.MASSEXTRACTION + categories.RADAR) * categories.STRUCTURE, target))
    then

        -- start a single thread to keep track of when to unpause, logic feels a bit convoluted
        -- but that is purely to guarantee that we still have access to the user units as the
        -- game progresses
        if not target.ThreadUnpause then
            local id = target:GetEntityId()
            target.ThreadUnpause = ForkThread(
                function()
                    WaitSeconds(1.0)
                    local target = GetUnitById(id)
                    while target do
                        local candidates = target.ThreadUnpauseCandidates
                        if (candidates and not table.empty(candidates)) then
                            for id, _ in candidates do
                                local engineer = GetUnitById(id)
                                if engineer and not engineer:IsIdle() then
                                    local focus = engineer:GetFocus()
                                    if focus == target:GetFocus() then
                                        target.ThreadUnpauseCandidates = nil
                                        target.ThreadUnpause = nil
                                        SetPaused({ target }, false)
                                        break
                                    end
                                    -- engineer is idle, died, we switch armies, ...
                                else
                                    candidates[id] = nil
                                end
                            end
                        else
                            target.ThreadUnpauseCandidates = nil
                            target.ThreadUnpause = nil
                            break
                            ;end

                        WaitSeconds(1.0)
                        target = GetUnitById(id)
                    end
                end
            )
        end

        -- add these to keep track
        target.ThreadUnpauseCandidates = target.ThreadUnpauseCandidates or {}
        for k, guardee in guardees do
            target.ThreadUnpauseCandidates[guardee:GetEntityId()] = true
        end
    end
end

local Prefs = import("/lua/user/prefs.lua")

UnpauseRadars = Prefs.GetFromCurrentProfile('options.structure_ringing_radar') == 'on'
UnpauseExtractors = Prefs.GetFromCurrentProfile('options.structure_ringing_artillery') == 'on'
UnpauseFactories = Prefs.GetFromCurrentProfile('options.structure_ringing_artillery_end_game') == 'on'

---@param unit UserUnit
local function UnpauseThread(unit)

    LOG("UnpauseThread")
    reprsl(unit)
    while not IsDestroyed(unit) do
        WaitTicks(10)
        local assistees = GetAssistingUnitsList({unit})
        reprsl(assistees)
    end
end


---@param guardees UserUnit[]
---@param target UserUnit
function AssistToUnpause(guardees, target)
    if EntityCategoryContains(categories.STRUCTURE, target) then
        -- add these to keep track
        target.ThreadUnpauseCandidates = target.ThreadUnpauseCandidates or {}
        for k, guardee in guardees do
            target.ThreadUnpauseCandidates[guardee:GetEntityId()] = true
        end

        ForkThread(UnpauseThread, target)
    end
end