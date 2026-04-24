
-------------------------------------------------------------------------------
-- /debugger — opens the Lua debugger attached to the running session.
-- Only registered when the game was launched with `/debug`.

---@type UIChatCommand
Command = {
    Name = 'debugger',
    Description = 'Open the in-game Lua debugger.',
    ShouldRegister = function()
        return HasCommandLineArg('/debug')
    end,
    Execute = function()
        ConExecute('SC_LuaDebugger')
    end,
}

-------------------------------------------------------------------------------
--#region Debugging

function __moduleinfo.OnDirty()
    import(__moduleinfo.name)
end

--#endregion
