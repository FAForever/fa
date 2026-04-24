
local Registry = import("/lua/ui/game/chat/commands/ChatCommandRegistry.lua")

-------------------------------------------------------------------------------
-- /help (aka /?) — prints every registered command as a local system line.

---@type UIChatCommand
Command = {
    Name = 'help',
    Aliases = { '?' },
    Description = 'Lists available chat commands.',
    Execute = function(_, ctx)
        local controller = ctx.Controller
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
