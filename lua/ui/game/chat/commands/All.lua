
local ChatModel = import("/lua/ui/game/chat/ChatModel.lua")

-------------------------------------------------------------------------------
-- /all — switch the send target to every player and observer.

---@type UIChatCommand
Command = {
    Name = 'all',
    Description = 'Send to all players and observers.',
    Execute = function(_, ctx)
        ctx.Controller.SetRecipient(ChatModel.RecipientAll)
    end,
}

-------------------------------------------------------------------------------
--#region Debugging

function __moduleinfo.OnDirty()
    import(__moduleinfo.name)
end

--#endregion
