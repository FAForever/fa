
local ChatModel = import("/lua/ui/game/chat/ChatModel.lua")

-------------------------------------------------------------------------------
-- Built-in chat commands.
--
-- Each command is exported as a top-level `UIChatCommand` table. Importing
-- this module has no side effects; `ChatController.RegisterBuiltinCommands`
-- is responsible for handing these off to the registry.

-------------------------------------------------------------------------------
-- Recipient switching

---@type UIChatCommand
All = {
    Name = 'all',
    Description = 'Send to all players and observers.',
    Execute = function(_, ctx)
        ctx.Controller.SetRecipient(ChatModel.RecipientAll)
    end,
}

---@type UIChatCommand
Allies = {
    Name = 'allies',
    Aliases = { 'team' },
    Description = 'Send to allies only.',
    Execute = function(_, ctx)
        ctx.Controller.SetRecipient(ChatModel.RecipientAllies)
    end,
}

---@type UIChatCommand
Whisper = {
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

-------------------------------------------------------------------------------
-- Introspection

---@type UIChatCommand
Help = {
    Name = 'help',
    Aliases = { '?' },
    Description = 'Lists available chat commands.',
    Execute = function(_, ctx)
        local controller = ctx.Controller
        local Registry = import("/lua/ui/game/chat/commands/ChatCommandRegistry.lua")

        controller.AppendLocalSystemMessage("Available chat commands:")

        for _, cmd in ipairs(Registry.GetAll()) do
            local params = ''
            if cmd.Params then
                for _, p in ipairs(cmd.Params) do
                    local fmt = p.Optional and ' [%s]' or ' <%s>'
                    params = params .. string.format(fmt, p.Name)
                end
            end

            local aliases = ''
            if cmd.Aliases and table.getn(cmd.Aliases) > 0 then
                aliases = ' (aka /' .. table.concat(cmd.Aliases, ', /') .. ')'
            end

            controller.AppendLocalSystemMessage(
                string.format("  /%s%s%s — %s", cmd.Name, params, aliases, cmd.Description or '')
            )
        end
    end,
}

-------------------------------------------------------------------------------
--#region Debugging

function __moduleinfo.OnDirty()
    import(__moduleinfo.name)
end

--#endregion
