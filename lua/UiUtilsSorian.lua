--****************************************************************************
--**
--**  File     :  /lua/modules/AI/UiUtilsSorian.lua
--**  Author(s): Sorian
--**
--**  Summary  :
--**
--****************************************************************************
function ProcessAIChat(to, from, text)
    local armies = GetArmiesTable()
    if (to == 'allies' or type(to) == 'number') then
        for i, v in armies.armiesTable do
            if not v.human and not v.civilian and IsAlly(i, from) and (to == 'allies' or to == i) then
                local testtext = string.gsub(text, '%s(.*)', '')
                local aftertext = string.gsub(text, '^%a+%s', '')
                aftertext = trim(aftertext)
                if string.lower(testtext) == 'target' and aftertext != '' then
                    if string.lower(aftertext) == 'at will' then
                        SimCallback({Func = 'AIChat', Args = {Army = i, NewTarget = 'at will'}})
                    else
                        for x, z in armies.armiesTable do
                            if trim(string.lower(string.gsub(z.nickname,'%b()', ''))) == string.lower(aftertext) then
                                SimCallback({Func = 'AIChat', Args = {Army = i, NewTarget = x}})
                            end
                        end
                    end
                elseif string.lower(testtext) == 'focus' and aftertext != '' then
                    local focus = trim(string.lower(aftertext))
                    SimCallback({Func = 'AIChat', Args = {Army = i, NewFocus = focus}})
                elseif string.lower(testtext) == 'current' and aftertext == 'focus' then
                    SimCallback({Func = 'AIChat', Args = {Army = i, CurrentFocus = true}})
                elseif string.lower(testtext) == 'give' and aftertext == 'me an engineer' and to == i then
                    SimCallback({Func = 'AIChat', Args = {Army = i, ToArmy = from, GiveEngineer = true}})
                elseif string.lower(testtext) == 'command' and to == i then
                    SimCallback({Func = 'AIChat', Args = {Army = i, ToArmy = from, Command = true, Text = aftertext}})
                elseif to == i then
                    SimCallback({Func = 'AIChat', Args = {Army = i, ToArmy = from, Command = true, Text = ''}})
                end
            end
        end
    end
end

function trim(s)
    return (string.gsub(s, "^%s*(.-)%s*$", "%1"))
end