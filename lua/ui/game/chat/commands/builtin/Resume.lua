
-------------------------------------------------------------------------------
-- /resume — un-pause the local simulation. Symmetric with `/pause`;
-- available in single-player and replay.

---@type UIChatCommand
Command = {
    Name = 'resume',
    Description = 'Resume the simulation.',
    ShouldRegister = function()
        return not SessionIsMultiplayer()
    end,
    Execute = function()
        SessionResume()
    end,
}

-------------------------------------------------------------------------------
--#region Debugging

function __moduleinfo.OnDirty()
    import(__moduleinfo.name)
end

--#endregion
