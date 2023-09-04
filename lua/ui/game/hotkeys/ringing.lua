
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

local ringExtractorPrefs = Prefs.GetFromCurrentProfile('options.structure_capping_feature_01')
RingStorages = ringExtractorPrefs == 'on' or ringExtractorPrefs == 'on-inner' or ringExtractorPrefs == 'on-all'
RingFabricatorsInner = ringExtractorPrefs == 'on-inner'
RingFabricatorsAll = ringExtractorPrefs == 'on-all'
RingRadars = Prefs.GetFromCurrentProfile('options.structure_ringing_radar') == 'on'
RingArtillery = Prefs.GetFromCurrentProfile('options.structure_ringing_artillery') == 'on'
RingArtilleryTech3Exp = Prefs.GetFromCurrentProfile('options.structure_ringing_artillery_end_game') == 'on'

--- Allows us to detect a double click
local pStructure1 = nil
local pStructure2 = nil

---@param command UserCommand
function RingExtractor(command)

    -- check if we have engineers
    local units = EntityCategoryFilterDown(categories.ENGINEER, command.Units)
    if not units[1] then return end

    -- check if we have a building that we target
    local structure = GetUnitById(command.Target.EntityId)
    if not structure or IsDestroyed(structure) then return end

    -- various conditions written out for maintainability
    local isShiftDown = IsKeyDown('Shift')

    local isDoubleTapped = structure ~= nil and (pStructure1 == structure)
    local isTripleTapped = structure ~= nil and (pStructure1 == structure) and (pStructure2 == structure)

    local isUpgrading = structure:GetFocus() ~= nil

    local isTech1 = structure:IsInCategory('TECH1')
    local isTech2 = structure:IsInCategory('TECH2')
    local isTech3 = structure:IsInCategory('TECH3')
    local isExp = structure:IsInCategory('EXPERIMENTAL')

    -- only run logic for structures
    if structure:IsInCategory('STRUCTURE') then

        -- try and create storages and / or fabricators around it
        if (RingStorages or RingFabricatorsInner or RingFabricatorsAll) and structure:IsInCategory('MASSEXTRACTION') then

            -- check what type of buildings we'd like to make
            local buildFabs =
            (RingFabricatorsInner or RingFabricatorsAll)
                and (
                (isTech2 and isUpgrading and isTripleTapped and isShiftDown)
                    or (isTech3 and isDoubleTapped and isShiftDown)
                )

            local buildStorages =
            (
                (isTech1 and isUpgrading and isDoubleTapped and isShiftDown)
                    or (isTech2 and isUpgrading and isDoubleTapped and isShiftDown)
                    or (isTech2 and not isUpgrading)
                    or isTech3
                ) and not buildFabs

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
                SimCallback({ Func = 'RingWithStorages', Args = { target = command.Target.EntityId } }, true)

                -- only clear state if we can't make fabricators
                if (isTech1 and isUpgrading) or (isTech2 and not isUpgrading) then
                    structure = nil
                    pStructure1 = nil
                    pStructure2 = nil
                end
            end

            if buildFabs then

                -- prevent consecutive calls
                local gameTick = GameTick()
                if structure.RingFabsStamp then
                    if structure.RingFabsStamp + 5 > gameTick then
                        return
                    end
                end

                structure.RingFabsStamp = gameTick

                print("Ringing extractor with fabricators")
                SimCallback({ Func = 'RingWithFabricators', Args = { target = command.Target.EntityId, allFabricators = RingFabricatorsAll } }, true)

                -- reset state
                structure = nil
                pStructure1 = nil
                pStructure2 = nil
            end

        elseif RingArtillery and structure:IsInCategory('ARTILLERY') and isTech2 then
            -- prevent consecutive calls
            local gameTick = GameTick()
            if structure.RingStamp then
                if structure.RingStamp + 5 > gameTick then
                    return
                end
            end

            structure.RingStamp = gameTick

            print("Ringing with power generators")
            SimCallback({ Func = 'RingArtilleryTech2', Args = { target = command.Target.EntityId } }, true)

            -- reset state
            structure = nil
            pStructure1 = nil
            pStructure2 = nil

        elseif RingArtilleryTech3Exp and structure:IsInCategory('ARTILLERY') and (isTech3 or isExp) then
            -- prevent consecutive calls
            local gameTick = GameTick()
            if structure.RingStamp then
                if structure.RingStamp + 5 > gameTick then
                    return
                end
            end

            structure.RingStamp = gameTick

            print("Ringing with power generators")
            SimCallback({ Func = 'RingArtilleryTech3Exp', Args = { target = command.Target.EntityId } }, true)

            -- reset state
            structure = nil
            pStructure1 = nil
            pStructure2 = nil
        elseif RingRadars   and (structure:IsInCategory('RADAR') or structure:IsInCategory('OMNI'))
                            and ( -- checks for upgrading state
                                (isTech1 and isUpgrading and isDoubleTapped and isShiftDown)
                                    or (isTech2 and isUpgrading and isDoubleTapped and isShiftDown)
                                    or (isTech2 and not isUpgrading)
                                    or (isTech3)
                                )
        then
            -- prevent consecutive calls
            local gameTick = GameTick()
            if structure.RingStamp then
                if structure.RingStamp + 5 > gameTick then
                    return
                end
            end

            structure.RingStamp = gameTick

            print("Ringing with power generators")
            SimCallback({ Func = 'RingRadar', Args = { target = command.Target.EntityId } }, true)

            -- reset state
            structure = nil
            pStructure1 = nil
            pStructure2 = nil
        end
    end

    -- keep track of previous structure to identify a 2nd / 3rd click
    pStructure2 = pStructure1
    pStructure1 = structure

    -- prevent building up state when upgrading but shift isn't pressed
    if isUpgrading and not isShiftDown then
        structure = nil
        pStructure1 = nil
        pStructure2 = nil
    end
end