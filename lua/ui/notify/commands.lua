-- This file allows new /commandhere type commands to be added which can be used
-- with the in-game chat

-- command_table = {
--     commandText = commandfunction()
-- }
local command_table = {}

-- This is called by notify.lua at game start to register the commands into the table
function AddChatCommand(commandText, func)
    command_table[commandText] = func
end

-- This is called from chat.lua when a /command is detected
function RunChatCommand(args)
    local command = args[1]

    if command_table[command] then
        command_table[command](args)
        return true
    end

    return false
end
