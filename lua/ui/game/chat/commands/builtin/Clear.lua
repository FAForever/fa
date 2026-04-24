
local ChatModel = import("/lua/ui/game/chat/ChatModel.lua")

-------------------------------------------------------------------------------
-- /clear — wipes the local chat history. Sets a fresh empty table ref on the
-- model's `History` so observers (the line view) go dirty and redraw.

---@type UIChatCommand
Command = {
    Name = 'clear',
    Description = 'Clear the local chat history.',
    Execute = function()
        ChatModel.GetSingleton().History:Set({})
    end,
}

-------------------------------------------------------------------------------
--#region Debugging

function __moduleinfo.OnDirty()
    import(__moduleinfo.name)
end

--#endregion
