#****************************************************************************
#**  File     :  /lua/simtransmissions.lua
#**  Author(s): Ted Snook
#**
#**  Summary  : Functions to save sim data off for the transmission log
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

local transmissions = {}
local techRestrictions = {}
local enhanceRestriction = {}
local campaignMode = false

function SaveEntry(entry)
    table.insert(transmissions, entry)
end

function SaveEnhancementRestriction(table)
    enhanceRestriction = table
end

function SaveTechRestriction(category)
    table.insert(techRestrictions, {cats = category, type = 'restriction'})
end

function SaveTechAllowance(category)
    table.insert(techRestrictions, {cats = category, type = 'allow'})
end

function IsCampaign(state)
    campaignMode = state
end

function OnPostLoad()
    -- Restore Transmissions
    Sync.AddTransmissions = transmissions
    
    Sync.CampaignMode = campaignMode
    
    -- Restore restricted enhancements
    Sync.EnhanceRestrict = enhanceRestriction
    
    Sync.UserUnitEnhancements = SimUnitEnhancements
    
    -- Restore build restrictions
#    for i, val in techRestrictions do
#        if val.type == 'restriction' then
#            AddBuildRestriction(val.cats)
#        elseif val.type == 'allow' then
#            RemoveBuildRestriction(val.cats)
#        end
#    end
end