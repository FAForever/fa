
-------------------------------------------------------------------------------
-- /debug-wind <tick> — fast-forward the simulation to `tick` at maximum
-- speed, then pause. Maxes out `WLD_GameSpeed` first so the sim runs as
-- fast as the engine allows, then hands off to `wld_RunWithTheWind` which
-- halts on its own when the target tick is reached.

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

        -- wait till we get there and pause
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

function __moduleinfo.OnDirty()
    import(__moduleinfo.name)
end

--#endregion
