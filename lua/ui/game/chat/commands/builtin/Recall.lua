
-------------------------------------------------------------------------------
-- /recall — cast a "yes" vote on the team recall. Mirrors clicking the
-- `Recall` button in the diplomacy panel. Observers can't vote.
--
-- Only the "yes" case is exposed for now; voting no is rare enough that the
-- diplomacy UI suffices.

---@type UIChatCommand
Command = {
    Name = 'recall',
    Description = 'Vote yes on the team recall.',
    Accept = function()
        if GetFocusArmy() == -1 then
            return false, "/recall: observers can't vote."
        end
        return true
    end,
    Execute = function()
        SimCallback({
            Func = "SetRecallVote",
            Args = { From = GetFocusArmy(), Vote = true },
        })
    end,
}

-------------------------------------------------------------------------------
--#region Debugging

function __moduleinfo.OnDirty()
    import(__moduleinfo.name)
end

--#endregion
