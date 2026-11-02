
--- /taunt <index>: broadcast a numbered taunt. Receivers silently ignore out-of-range indices.
---@type UIChatCommand
Command = {
    Name = 'taunt',
    Description = 'Play a numbered taunt for every player to hear.',
    Params = {
        { Name = 'index', Type = 'Int' },
    },
    Accept = function(args)
        if GetFocusArmy() == -1 then
            return false, "/taunt: observers can't taunt."
        end
        if args.index < 1 then
            return false, "/taunt: index must be at least 1."
        end
        return true
    end,
    Execute = function(args)
        import("/lua/ui/game/taunt.lua").SendTaunt(args.index)
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
