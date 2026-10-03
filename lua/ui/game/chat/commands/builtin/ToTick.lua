
--- /to-tick <tick>: fast-forward to `tick` and pause. Only registered with `/debug`.
---@type UIChatCommand
Command = {
    Name = 'to-tick',
    Description = 'Fast-forward the sim to <tick> and pause there.',
    ShouldRegister = function()
        return HasCommandLineArg('/debug')
    end,
    Params = {
        { Name = 'tick', Type = 'Int' },
    },
    Accept = function(args)
        if args.tick < 0 then
            return false, "/to-tick: tick must be non-negative."
        end
        local current = GetGameTick()
        if args.tick <= current then
            return false, string.format(
                "/to-tick: target tick %d has already passed (now at %d).",
                args.tick, current)
        end
        return true
    end,
    Execute = function(args)
        ConExecute("wld_RunWithTheWind 1")

        ForkThread(
            function()
                while GetGameTick() < args.tick - 5 do
                    WaitFrames(1)
                end
                ConExecute("wld_RunWithTheWind 0")
                SessionRequestPause()
            end
        )
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
