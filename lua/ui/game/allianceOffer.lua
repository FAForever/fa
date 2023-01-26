--*****************************************************************************
--* File: lua/modules/ui/game/allianceOffer.lua
--* Summary: Dialog when an incoming alliance offer is received
--*
--* Copyright � 2006 Gas Powered Games, Inc.  All rights reserved.
--*****************************************************************************
local UIUtil = import("/lua/ui/uiutil.lua")
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local Button = import("/lua/maui/button.lua").Button
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Text = import("/lua/maui/text.lua").Text

local dialog = nil
local pendingOffers = {}
local activeOffer = nil

local ShowNextOffer

local function ShowOffer( query, callback )

    activeOffer = { query, callback }
    
    local layout = UIUtil.SkinnableFile('/dialogs/diplomacy-team-alliance/diplomacy-team-alliance_layout.lua')

    local worldView = import("/lua/ui/game/worldview.lua").view
    dialog = Bitmap(worldView, UIUtil.SkinnableFile('/dialogs/diplomacy-team-alliance/team-panel_bmp.dds'))
    dialog:SetRenderPass(UIUtil.UIRP_PostGlow)  -- just in case our parent is the map
    dialog:SetName("Alliance Offer")

    LayoutHelpers.AtHorizontalCenterIn(dialog,worldView)
    LayoutHelpers.AtTopIn(dialog,worldView)

    local dialogTitle = UIUtil.CreateText(dialog, "<LOC allyui_0000>Alliance Offer", 18, UIUtil.titleFont )
    dialogTitle:SetColor( UIUtil.dialogCaptionColor )
    LayoutHelpers.RelativeTo(dialogTitle, dialog, layout, "l_team-alliance", "team-panel_bmp")

    local armies = GetArmiesTable().armiesTable
    local text = LOCF("<LOC dipui_0001>%s offers you an alliance.", armies[query.From].nickname)

    local message = UIUtil.CreateText(dialog, text, 12, UIUtil.bodyFont )
    LayoutHelpers.RelativeTo(message, dialog, layout, "l_player-text", "team-panel_bmp")

    local function MakeClickCallback(result)
        return function(self, modifiers)
                   activeOffer = nil
                   dialog:Destroy()
                   dialog = nil
                   callback(result)
                   ShowNextOffer()
                end
    end

    local accept = UIUtil.CreateDialogButtonStd(dialog, "/dialogs/standard_btn/standard", "<LOC _Accept>Accept", 12)
    LayoutHelpers.RelativeTo(accept, dialog, layout, "l_accept_btn_up", "team-panel_bmp")
    accept.OnClick = MakeClickCallback('accept')

    local reject = UIUtil.CreateDialogButtonStd(dialog, "/dialogs/standard_btn/standard", "<LOC _Reject>Reject", 12)
    LayoutHelpers.RelativeTo(reject, dialog, layout, "l_reject_btn", "team-panel_bmp")
    reject.OnClick = MakeClickCallback('reject')

    local never = UIUtil.CreateDialogButtonStd(dialog, "/dialogs/standard_btn/standard", "<LOC _Never>Never!", 12)
    LayoutHelpers.RelativeTo(never, dialog, layout, "l_never_btn", "team-panel_bmp")
    never.OnClick = MakeClickCallback('never')
end

function ShowNextOffer()
    local n = table.getn(pendingOffers)
    if n > 0 then
        local query, callback = unpack(pendingOffers[n])
        table.remove(pendingOffers)
        ShowOffer( query, callback )
    end
end

function OfferAlliance( query, callback )

    LOG('OfferAlliance called, query=' .. repr(query))

    if dialog then
        table.insert(pendingOffers, {query,callback})
    else
        ShowOffer(query, callback)
    end
end


function AcceptOffer(from, to)
    if activeOffer and activeOffer[1].From == from and activeOffer[1].To == to then
        local callback = activeOffer[2]
        activeOffer = nil
        dialog:Destroy()
        dialog = nil
        callback('accept')
        ShowNextOffer()
        return true
    else
        for k,offer in pendingOffers do
            if offer[1].From == from and offer[1].To == to then
                local callback = offer[2]
                table.remove(pendingOffers, k)
                callback('accept')
                return true
            end
        end
        return false
    end
end
