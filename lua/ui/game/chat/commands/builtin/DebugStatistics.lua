
-------------------------------------------------------------------------------
-- /debug-statistics — runs the engine's `ShowStats` console command, which
-- cycles the overlay that reports frame time, memory, etc. Only registered
-- when the game was launched with `/debug`.

---@type UIChatCommand
Command = {
    Name = 'debug-statistics',
    Description = 'Cycle the engine ShowStats overlay.',
    ShouldRegister = function()
        return HasCommandLineArg('/debug')
    end,
    Execute = function()
        ConExecute('ShowStats')
    end,
}

-------------------------------------------------------------------------------
--#region Debugging

function __moduleinfo.OnDirty()
    import(__moduleinfo.name)
end

--#endregion
