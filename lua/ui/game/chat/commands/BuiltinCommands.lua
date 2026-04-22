
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
    name = 'all',
    description = 'Send to all players and observers.',
    execute = function(_, ctx)
        ctx.controller.SetRecipient(ChatModel.RecipientAll)
    end,
}

---@type UIChatCommand
Allies = {
    name = 'allies',
    aliases = { 'team' },
    description = 'Send to allies only.',
    execute = function(_, ctx)
        ctx.controller.SetRecipient(ChatModel.RecipientAllies)
    end,
}

---@type UIChatCommand
Whisper = {
    name = 'whisper',
    aliases = { 'w', 'pm' },
    description = 'Whisper to a specific player (by nickname or army ID).',
    params = {
        { name = 'target', type = 'player' },
    },
    accept = function(args)
        local armies = GetArmiesTable()
        if armies and args.target == armies.focusArmy then
            return false, "/whisper: can't whisper yourself."
        end
        return true
    end,
    execute = function(args, ctx)
        ctx.controller.SetRecipient(args.target)
    end,
}

-------------------------------------------------------------------------------
-- Introspection

---@type UIChatCommand
Help = {
    name = 'help',
    aliases = { '?' },
    description = 'Lists available chat commands.',
    execute = function(_, ctx)
        local controller = ctx.controller
        local Registry = import("/lua/ui/game/chat/commands/ChatCommandRegistry.lua")

        controller.AppendLocalSystemMessage("Available chat commands:")

        for _, cmd in ipairs(Registry.GetAll()) do
            local params = ''
            if cmd.params then
                for _, p in ipairs(cmd.params) do
                    local fmt = p.optional and ' [%s]' or ' <%s>'
                    params = params .. string.format(fmt, p.name)
                end
            end

            local aliases = ''
            if cmd.aliases and table.getn(cmd.aliases) > 0 then
                aliases = ' (aka /' .. table.concat(cmd.aliases, ', /') .. ')'
            end

            controller.AppendLocalSystemMessage(
                string.format("  /%s%s%s — %s", cmd.name, params, aliases, cmd.description or '')
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
