
local ChatConfigController = import("/lua/ui/game/chat/config/ChatConfigController.lua")

-------------------------------------------------------------------------------
-- /mute <target> — hide future messages from a specific player for this
-- game. Goes straight to `Committed` via `SetMutedLive` so the filter picks
-- up the change immediately; `Pending` is untouched so an open config dialog
-- keeps its draft.

---@type UIChatCommand
Command = {
    Name = 'mute',
    Description = 'Hide messages from a specific player for the rest of the game.',
    Params = {
        { Name = 'target', Type = 'Player' },
    },
    Accept = function(args)
        local armies = GetArmiesTable()
        if armies and args.target == armies.focusArmy then
            return false, "/mute: can't mute yourself."
        end
        return true
    end,
    Execute = function(args)
        ChatConfigController.SetMutedLive(args.target, true)
    end,
}

-------------------------------------------------------------------------------
--#region Debugging

function __moduleinfo.OnDirty()
    import(__moduleinfo.name)
end

--#endregion
