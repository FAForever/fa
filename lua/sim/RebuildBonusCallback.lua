#****************************************************************************
#**
#**  File     :  /lua/sim/RebuildBonusCallback.lua
#**  Author(s):  Brute51
#**
#**  Summary  :  Rebuild bonus callback functions
#**
#****************************************************************************
#**
#** Doing this in 2D. How many times have you seen 2 wreckages at the same 
#** position where only the height differs?
#**
#****************************************************************************

RebuildBonusCheckCallbacks = {}

function RegisterRebuildBonusCheck( pos, fn, lifetime )
    local key = repr(pos[1])..repr(pos[3])
    RebuildBonusCheckCallbacks[key] = fn
    if not lifetime or lifetime >= 0 then
        ForkThread( DelayedUnregister, pos, lifetime or 1 )
    end
end

function UnregisterRebuildBonusCheck( pos )
    # I'm not sure setting a table value to nil to reduce works if the table value is a function. GetN says the 
    # size is 0 before and 0 after. I'm assuming it works and yes I know assumptions are bad.
    local key = repr(pos[1])..repr(pos[3])
    RebuildBonusCheckCallbacks[key] = nil
end

function DelayedUnregister( pos, delay )
    WaitTicks(delay)
    UnregisterRebuildBonusCheck( pos)
end

function RunRebuildBonusCallback( pos, WreckUnitBlueprint )
    local key = repr(pos[1])..repr(pos[3])
    local fn = RebuildBonusCheckCallbacks[key] or nil
    if fn then
        fn( WreckUnitBlueprint, pos )
    end
end
