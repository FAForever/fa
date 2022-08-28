
---@class ScoreboardUtilities
local scoreboardUtilities = {
    
    --- Sanitzes a number for use on the scoreboard 
    ---@param number number
    ---@return string
    SanitizeNumber = function(number)
        if not number then
            return ""
        end

        if number < 1000 then 
            return string.format("%4d", number)
        else
            return string.format("%4dk", 0.1 * math.floor(0.01* number))
        end
    end,

    --- Used when trying to gift resources to yourself
    ---@param from number
    ---@param to number
    ---@return string
    NotToSelfMessage = function(from, to)
        return "You can't send resources to yourself!"
    end,

    --- Used when gifting mass to another player
    ---@param from number
    ---@param to number
    ---@return string
    MassGiftMessage = function(from, to)
        return "Sent %d mass to %s"
    end,

    --- Used when dumping mass to another player
    ---@param from number
    ---@param to number
    ---@return string
    MassDumpMessage = function(from, to)
        return "Dropped %d mass to %s"
    end,

    --- Used when asking for mass
    ---@param from number
    ---@param to number
    ---@return string
    MassAskMessage = function(from, to)
        return "Could %s gift me mass?"
    end,

    --- Used when the mass storage of the sender is empty 
    ---@return string
    MassEmptyMessage = function()
        return "Your mass storage is empty"
    end,

    --- Used when the mass storage of the receiver is full
    ---@return string
    MassFullMessage = function()
        return "Their mass storage is full"
    end,

}