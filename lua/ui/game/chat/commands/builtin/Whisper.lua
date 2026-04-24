
-------------------------------------------------------------------------------
-- /whisper <target> (aka /w, /pm) — private-message a specific player.
-- The `target` parameter type is resolved by `ChatCommandTypes.lua`.

---@type UIChatCommand
Command = {
    Name = 'whisper',
    Aliases = { 'w', 'pm' },
    Description = 'Whisper to a specific player (by nickname or army ID).',
    Params = {
        { Name = 'target', Type = 'Player' },
    },
    Accept = function(args)
        local armies = GetArmiesTable()
        if armies and args.target == armies.focusArmy then
            return false, "/whisper: can't whisper yourself."
        end
        return true
    end,
    Execute = function(args, ctx)
        ctx.Controller.SetRecipient(args.target)
    end,
}
