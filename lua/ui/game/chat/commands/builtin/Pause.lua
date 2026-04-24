
-------------------------------------------------------------------------------
-- /pause — pause the local simulation. Available in single-player and
-- replay; multiplayer pausing goes through a vote/request flow handled by
-- the existing hotkey, so this command stays out of the way there.

---@type UIChatCommand
Command = {
    Name = 'pause',
    Description = 'Pause the simulation.',
    ShouldRegister = function()
        return not SessionIsMultiplayer()
    end,
    Execute = function()
        SessionRequestPause()
    end,
}

-------------------------------------------------------------------------------
--#region Debugging

function __moduleinfo.OnDirty()
    import(__moduleinfo.name)
end

--#endregion
