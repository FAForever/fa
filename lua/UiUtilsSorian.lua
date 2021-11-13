#****************************************************************************
#**
#**  File     :  /lua/modules/AI/UiUtilsSorian.lua
#**  Author(s): Sorian
#**
#**  Summary  :
#**
#****************************************************************************
local ipairs = ipairs
local stringLower = string.lower
local IsAlly = IsAlly
local stringGsub = string.gsub
local next = next
local type = type

function ProcessAIChat(to, from, text)
    local armies = GetArmiesTable()
    if (to == 'allies' or type(to) == 'number') then
        for i, v in armies.armiesTable do
            if not v.human and not v.civilian and IsAlly(i, from) and (to == 'allies' or to == i) then
                local testtext = stringGsub(text, '%s(.*)', '')
                local aftertext = stringGsub(text, '^%a+%s', '')
                aftertext = trim(aftertext)
                if stringLower(testtext) == 'target' and aftertext != '' then
                    if stringLower(aftertext) == 'at will' then
                        SimCallback({Func = 'AIChat', Args = {Army = i, NewTarget = 'at will'}})
                    else
                        for x, z in armies.armiesTable do
                            if trim(stringLower(stringGsub(z.nickname,'%b()', ''))) == stringLower(aftertext) then
                                SimCallback({Func = 'AIChat', Args = {Army = i, NewTarget = x}})
                            end
                        end
                    end
                elseif stringLower(testtext) == 'focus' and aftertext != '' then
                    local focus = trim(stringLower(aftertext))
                    SimCallback({Func = 'AIChat', Args = {Army = i, NewFocus = focus}})
                elseif stringLower(testtext) == 'current' and aftertext == 'focus' then
                    SimCallback({Func = 'AIChat', Args = {Army = i, CurrentFocus = true}})
                elseif stringLower(testtext) == 'give' and aftertext == 'me an engineer' and to == i then
                    SimCallback({Func = 'AIChat', Args = {Army = i, ToArmy = from, GiveEngineer = true}})
                elseif stringLower(testtext) == 'command' and to == i then
                    SimCallback({Func = 'AIChat', Args = {Army = i, ToArmy = from, Command = true, Text = aftertext}})
                elseif to == i then
                    SimCallback({Func = 'AIChat', Args = {Army = i, ToArmy = from, Command = true, Text = ''}})
                end
            end
        end
    end
end

function trim(s)
    return (stringGsub(s, "^%s*(.-)%s*$", "%1"))
end