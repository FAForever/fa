
--******************************************************************************************************
--** Copyright (c) 2022  Willem 'Jip' Wijnia
--**
--** Permission is hereby granted, free of charge, to any person obtaining a copy
--** of this software and associated documentation files (the "Software"), to deal
--** in the Software without restriction, including without limitation the rights
--** to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
--** copies of the Software, and to permit persons to whom the Software is
--** furnished to do so, subject to the following conditions:
--**
--** The above copyright notice and this permission notice shall be included in all
--** copies or substantial portions of the Software.
--**
--** THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
--** IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
--** FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
--** AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
--** LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
--** OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
--** SOFTWARE.
--******************************************************************************************************

local Prefs = import("/lua/user/prefs.lua")

--- Allows us to detect a double click
local pStructure1 = nil

---@param command UserCommand
function RingExtractor(command)
    -- retrieve the option in question, can have values: 'off', 'only-storages-extractors' and 'full-suite'
    local option = Prefs.GetFromCurrentProfile('options.structure_capping_feature_01')

    -- bail out - we're not interested
    if option == 'off' then
        return
    end

    -- check if we have engineers
    local units = EntityCategoryFilterDown(categories.ENGINEER, command.Units)
    if not units[1] then return end

    -- check if we have a building that we target
    local structure = GetUnitById(command.Target.EntityId)
    if not structure or IsDestroyed(structure) then return end

    -- various conditions written out for maintainability
    local isShiftDown = IsKeyDown('Shift')
    local isDoubleTapped = structure ~= nil and (pStructure1 == structure)
    local isUpgrading = structure:GetFocus() ~= nil

    local isTech1 = structure:IsInCategory('TECH1')
    local isTech2 = structure:IsInCategory('TECH2')
    local isTech3 = structure:IsInCategory('TECH3')

    if structure:IsInCategory('STRUCTURE') then
        if structure:IsInCategory('MASSEXTRACTION') then
            local buildStorages =
            (
                (isTech1 and isUpgrading and isDoubleTapped and isShiftDown)
                    or (isTech2 and isUpgrading and isDoubleTapped and isShiftDown)
                    or (isTech2 and not isUpgrading)
                    or isTech3
                )

            if buildStorages then

                -- prevent consecutive calls
                local gameTick = GameTick()
                if structure.RingStoragesStamp then
                    if structure.RingStoragesStamp + 5 > gameTick then
                        return
                    end
                end

                structure.RingStoragesStamp = gameTick

                print("Ringing extractor with storages")
                SimCallback({ Func = 'RingExtractor', Args = { target = command.Target.EntityId } }, true)

                if (isTech1 and isUpgrading) or (isTech2 and not isUpgrading) then
                    structure = nil
                    pStructure1 = nil
                end
            end
        end
    end

    -- keep track of previous structure to identify a 2nd / 3rd click
    pStructure1 = structure

    -- prevent building up state when upgrading but shift isn't pressed
    if isUpgrading and not isShiftDown then
        structure = nil
        pStructure1 = nil
    end
end