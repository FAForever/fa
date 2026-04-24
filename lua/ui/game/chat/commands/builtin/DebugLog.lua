
-------------------------------------------------------------------------------
-- /debug-log — toggle the log window (same entry point the debug hotkey
-- uses). Only registered when the game was launched with `/debug`.

---@type UIChatCommand
Command = {
    Name = 'debug-log',
    Description = 'Toggle the log window.',
    ShouldRegister = function()
        return HasCommandLineArg('/debug')
    end,
    Execute = function()
        ConExecute('WIN_ToggleLogDialog')
    end,
}

-------------------------------------------------------------------------------
--#region Debugging

function __moduleinfo.OnDirty()
    import(__moduleinfo.name)
end

--#endregion
