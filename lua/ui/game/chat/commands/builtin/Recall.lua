
--- /recall: vote yes on the team recall. Only "yes" is exposed (voting no stays in the diplomacy UI).
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

--- Hot-reload hook: re-registers this command so saved edits take effect.
---@param newModule any
function __moduleinfo.OnReload(newModule)
    import("/lua/ui/game/chat/commands/ChatCommandRegistry.lua").Register(newModule.Command)
end

--- Hot-reload hook: schedules the re-import so `OnReload` fires with the freshly-loaded module.
function __moduleinfo.OnDirty()
    ForkThread(function()
        WaitFrames(1)
        import(__moduleinfo.name)
    end)
end

--#endregion
