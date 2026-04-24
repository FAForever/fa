
local ChatConfigController = import("/lua/ui/game/chat/config/ChatConfigController.lua")

-------------------------------------------------------------------------------
-- /unmute <target> — reverse of `/mute`. Clears the mute flag for the given
-- player so their messages start showing again (both new arrivals and any
-- that landed in the history while they were muted).

---@type UIChatCommand
Command = {
    Name = 'unmute',
    Description = 'Re-show messages from a previously muted player.',
    Params = {
        { Name = 'target', Type = 'Player' },
    },
    Execute = function(args)
        ChatConfigController.SetMutedLive(args.target, false)
    end,
}

-------------------------------------------------------------------------------
--#region Debugging

function __moduleinfo.OnDirty()
    import(__moduleinfo.name)
end

--#endregion
