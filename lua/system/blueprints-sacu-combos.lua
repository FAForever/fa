--******************************************************************************************************
--** SACU loadout combos, for all four factions
--******************************************************************************************************

local TableInsert = table.insert
local TableGetn = table.getn
local StringLower = string.lower

-- Any unit blueprint carrying this category is treated as a loadout-eligible
-- base SACU: InjectSacuLoadoutPresets below generates its enhancement combo
-- presets, and MarkHiddenSacuLoadoutPresets tags those generated combos with
-- SACULOADOUTCOMBO. The four vanilla SACUs (uel0301/ual0301/url0301/xsl0301)
-- carry it via their own .bp files. A mod adding a new faction, or extending
-- an existing unit, opts in the same way - by adding SACULOADOUTBASE to that
-- unit's Categories (or AddCategories) - without hooking or editing this file
-- or lua/ui/game/sacuLoadout.lua at all.
local BaseCategory = 'SACULOADOUTBASE'

local SlotOrder = { 'LCH', 'RCH', 'Back' }

local function IsRemoveEnhancement(name)
    return string.sub(name, -6) == 'Remove'
end

local function SortedKeys(hashtable)
    local keys = {}
    for key in hashtable do
        TableInsert(keys, key)
    end
    table.sort(keys)
    return keys
end

local function EnhancementChain(enhName, slotDefs)
    local chain = { enhName }
    local current = enhName
    local guard = 0
    while slotDefs[current] and slotDefs[current].Prerequisite and guard < 8 do
        local pre = slotDefs[current].Prerequisite
        if not slotDefs[pre] then
            break
        end
        TableInsert(chain, 1, pre)
        current = pre
        guard = guard + 1
    end
    return chain
end

local function SlotChoices(slotDefs)
    local choices = { {} }
    local names = SortedKeys(slotDefs)
    for _, name in names do
        TableInsert(choices, EnhancementChain(name, slotDefs))
    end
    return choices
end

local function GroupBySlot(enhancements)
    local bySlot = {}
    for name, def in enhancements do
        if def.Slot and not IsRemoveEnhancement(name) then
            bySlot[def.Slot] = bySlot[def.Slot] or {}
            bySlot[def.Slot][name] = def
        end
    end
    return bySlot
end

function EnhancementSetKey(list)
    local copy = {}
    for _, name in list do
        TableInsert(copy, name)
    end
    table.sort(copy)
    return string.lower(table.concat(copy, '|'))
end

local function ExistingPresetKeys(namedPresets)
    local keys = {}
    for presetName, preset in namedPresets do
        if preset.Enhancements then
            keys[EnhancementSetKey(preset.Enhancements)] = presetName
        end
    end
    return keys
end

local function AllCombinations(slotChoices)
    local combos = { {} }
    for _, slot in SlotOrder do
        local choices = slotChoices[slot]
        if choices then
            local nextCombos = {}
            for _, prefix in combos do
                for _, choice in choices do
                    local merged = {}
                    for _, name in prefix do
                        TableInsert(merged, name)
                    end
                    for _, name in choice do
                        TableInsert(merged, name)
                    end
                    TableInsert(nextCombos, merged)
                end
            end
            combos = nextCombos
        end
    end
    return combos
end

local function ComboPresetName(enhancements)
    local copy = {}
    for _, name in enhancements do
        TableInsert(copy, StringLower(name))
    end
    table.sort(copy)
    return 'combo_' .. table.concat(copy, '_')
end

local function StripLocTag(text)
    -- string.gsub returns two values (result, replacement count); assigning to a
    -- single local truncates to just the result so callers passing this straight
    -- into another call (e.g. TableInsert(labels, StripLocTag(...))) don't have
    -- that count spliced in as a surprise extra argument.
    local stripped = string.gsub(text, '^<LOC [^>]+>', '')
    return stripped
end

--- Falls back to the enhancement's full in-game Name (loc-tag stripped) when
--- it has no ShortName of its own.
local function CleanLabel(name, def)
    if def and def.Name then
        return StripLocTag(def.Name)
    end
    return name
end

--- Short display label for a combo name, so combos still fit the unit info
--- panel - e.g. "Energy Accelerator" shows as "Energy". Read from the
--- enhancement's own ShortName field on the blueprint (set alongside its
--- Name, in the same <LOC key>text format) rather than a lookup table here,
--- so a modder adding a new enhancement gets a short combo label for free by
--- setting ShortName on their own blueprint - no table in this file to edit.
local function ComboUnitName(enhancements, bp)
    local labels = {}
    for _, name in enhancements do
        local def = bp.Enhancements[name]
        if def and def.ShortName then
            TableInsert(labels, StripLocTag(def.ShortName))
        else
            TableInsert(labels, CleanLabel(name, def))
        end
    end
    return 'SACU (' .. table.concat(labels, '/') .. ')'
end

function InjectSacuLoadoutPresets(all_bps)
    if not all_bps or not all_bps.Unit then
        return
    end

    local generated = 0
    local skippedNamed = 0

    for id, bp in all_bps.Unit do
        if bp.CategoriesHash and bp.CategoriesHash[BaseCategory] and bp.Enhancements and bp.EnhancementPresets then
            local bySlot = GroupBySlot(bp.Enhancements)
            local slotChoices = {}
            for _, slot in SlotOrder do
                if bySlot[slot] then
                    slotChoices[slot] = SlotChoices(bySlot[slot])
                end
            end

            local namedKeys = ExistingPresetKeys(bp.EnhancementPresets)
            local combos = AllCombinations(slotChoices)

            for _, enhList in combos do
                if TableGetn(enhList) > 0 then
                    local setKey = EnhancementSetKey(enhList)
                    if namedKeys[setKey] then
                        skippedNamed = skippedNamed + 1
                    else
                        local presetName = ComboPresetName(enhList)
                        if not bp.EnhancementPresets[presetName] then
                            local pretty = ComboUnitName(enhList, bp)
                            bp.EnhancementPresets[presetName] = {
                                -- Description carries the full pretty name (e.g. "SACU
                                -- (Cloak/EMP)"); UnitName is deliberately left unset, same
                                -- as every hand-authored preset on this unit (RAS, Engineer,
                                -- Combat, ...). HandleUnitWithBuildPresets in Blueprints.lua
                                -- maps preset.Description/UnitName onto the generated clone's
                                -- Description/General.UnitName - with UnitName unset it falls
                                -- through to the base SCU's own (also unset) General.UnitName,
                                -- so the unit-view panels' existing "name: TechN description"
                                -- logic naturally falls back to just "TechN description" with
                                -- no name/description duplication and no unit-specific UI code
                                -- needed in unitview.lua/unitviewDetail.lua for this.
                                Description = pretty,
                                BuildIconSortPriority = 90,
                                Enhancements = enhList,
                                HelpText = pretty,
                                SelectionPriority = 1,
                                SortCategory = 'SORTOTHER',
                                HiddenInBuildMenu = true,
                            }
                            generated = generated + 1
                        end
                    end
                end
            end
        end
    end

    SPEW(string.format('SACU loadout: generated %d hidden combos, reused %d named presets', generated, skippedNamed))
end

function MarkHiddenSacuLoadoutPresets(all_bps)
    if not all_bps or not all_bps.Unit then
        return
    end

    for id, bp in all_bps.Unit do
        local assigned = bp.EnhancementPresetAssigned
        if assigned and assigned.Name and string.sub(assigned.Name, 1, 6) == 'combo_' then
            local baseId = assigned.BaseBlueprintId
            local baseBp = baseId and all_bps.Unit[baseId]
            if baseBp and baseBp.CategoriesHash and baseBp.CategoriesHash[BaseCategory] then
                bp.CategoriesHash = bp.CategoriesHash or {}
                bp.CategoriesHash['SACULOADOUTCOMBO'] = true
                bp.Categories = table.unhash(bp.CategoriesHash)
            end
        end
    end
end
