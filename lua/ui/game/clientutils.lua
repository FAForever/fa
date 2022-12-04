
local focusArmy = GetFocusArmy()
local clients = GetSessionClients()
local armies = GetArmiesTable().armiesTable

--- Returns all clients in the game
---@return number[]
function GetAll()
    local recipients = { }
    for k, client in clients do
        for l, source in client.authorizedCommandSources do
            recipients[source] = true
        end
    end

    return table.keys(recipients)
end

--- Returns all allied clients in the game
---@return number[]
function GetAllies()
    local recipients = { }
    for k, client in clients do
        for l, source in client.authorizedCommandSources do
            if IsAlly(focusArmy, source) then
                recipients[source] = true
            end
        end
    end

    return table.keys(recipients)
end