
-------------------------------------------------------------------------------
-- /debug-dump-controls — toggles `ui_DebugAltClick`, the console flag that
-- swaps Alt+left-click into a "switch focus army to whichever army owns this
-- unit" shortcut. Only registered when the game was launched with `/debug`.

---@type UIChatCommand
Command = {
    Name = 'debug-dump-controls',
    Description = 'Toggle the Alt+click army-switch debug shortcut.',
    ShouldRegister = function()
        return HasCommandLineArg('/debug')
    end,
    Execute = function()
        ConExecute('UI_DumpControlsUnderCursor')
    end,
}

-------------------------------------------------------------------------------
--#region Debugging

function __moduleinfo.OnDirty()
    import(__moduleinfo.name)
end

--#endregion
