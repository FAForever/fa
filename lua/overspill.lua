----------------------------------------------------
--  File     :  /lua/overspill.lua
--  Author(s):  Michael Sondergaard <sheeo@sheeo.dk>
--  Summary  :  Module for handling shield overspill
----------------------------------------------------

local Util = import('utilities.lua')
local largestShieldDiameter = 120
local overspills = {}

-- Find all shields overlapping the source entity
function GetOverlappingShields(source)
    local adjacentShields = {}
    local brain = source.Owner:GetAIBrain()
    local units = brain:GetUnitsAroundPoint((categories.SHIELD * categories.DEFENSE) + categories.BUBBLESHIELDSPILLOVERCHECK, source.Owner:GetPosition(), largestShieldDiameter, 'Ally')
    local pos = source:GetCachePosition()
    local OverlapRadius = 0.98 * (source.Size / 2) -- Size is diameter, dividing by 2 to get radius

    local obp, oOverlapRadius, vpos, OverlapDist
    for _, v in units do
        if v and IsUnit(v) and not v.Dead
                and v.MyShield and v.MyShield:IsUp()
                and v.MyShield.Size and v.MyShield.Size > 0
                and source.Owner ~= v then
            vspos = v.MyShield:GetCachePosition()
            oOverlapRadius = 0.98 * (v.MyShield.Size / 2)
            -- If "source" and "v" are more than this far apart then the shields don't overlap,
            -- otherwise they do
            OverlapDist = OverlapRadius + oOverlapRadius
            if VDist3(pos, vspos) <= OverlapDist then
                table.insert(adjacentShields, v.MyShield)
            end
        end
    end
    return adjacentShields
end

function RegisterDamage(shieldId, instigatorId, amount)
    if not overspills[shieldId] then
        overspills[shieldId] = {}
    end
    table.insert(overspills[shieldId], {instigatorId = instigatorId,
                                        amount = amount,
                                        tick = GetGameTick()})
end

-- Returns whether the given shield already took
-- the given amount of damage from the given instigator
function DidTakeDamageAlready(shieldId, instigatorId, amount)
    if not overspills[shieldId] then
        return false
    else
        local currentTick = GetGameTick()
        for _, v in overspills[shieldId] do
            if v.instigatorId == instigatorId and math.abs(v.amount - amount) < 0.1 and v.tick + 2 >= currentTick then
                return true
            end
        end
    end
    return false
end

function CleanupDamageTable()
    local currentGameTick = GetGameTick()
    for shieldId, spills in overspills do
        for k, spill in spills do
            if spill.tick < GetGameTick() - 2 then
                table.remove(spills, k)
            end
        end
    end
end

-- Set up overspilling from the given source with the
-- given dmgType and dmgMod
function DoOverspill(source, instigator, amount, dmgType, dmgMod)
    if not instigator then
        return
    end
    if source:IsUp() then
        local instigatorId = instigator.EntityId
        RegisterDamage(source:GetEntityId(), instigatorId, amount)
        local doDamage = function()
            WaitTicks(1)
            local overlappingShields = GetOverlappingShields(source)
            for _, v in overlappingShields do
                local targetId = v:GetEntityId()
                if v:IsUp() and not DidTakeDamageAlready(targetId, instigatorId, amount) then
                    local direction = Util.GetDirectionVector(source.Owner:GetCachePosition(), v.Owner:GetCachePosition())
                    v:ApplyDamage(source, (amount * dmgMod), direction, dmgType, false)
                    RegisterDamage(targetId, instigatorId, amount)
                end
            end
            CleanupDamageTable()
        end
        source.Owner:ForkThread(doDamage)
    end
end
