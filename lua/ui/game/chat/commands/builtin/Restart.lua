
-------------------------------------------------------------------------------
-- /restart — immediately restart the current session. Single-player only.
-- Skips the confirmation dialog that the escape-menu's Restart button shows;
-- the command itself is deliberate enough.

local function IsSingleplayer()
    return not SessionIsMultiplayer() and not SessionIsReplay()
end

---@type UIChatCommand
Command = {
    Name = 'restart',
    Description = 'Restart the current mission (single-player only).',
    ShouldRegister = IsSingleplayer,
    Execute = function()
        RestartSession()
    end,
}

-------------------------------------------------------------------------------
--#region Debugging

function __moduleinfo.OnDirty()
    import(__moduleinfo.name)
end

--#endregion
