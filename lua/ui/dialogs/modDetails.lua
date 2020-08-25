
local dialogWidth = 770
local dialogHeight = 560

local modIconSize = 50
local modInfoPosition = modIconSize + 15
local modInfoHeight = modIconSize + 20

local Prefs = import('/lua/user/prefs.lua')

local Mods = import('/lua/mods.lua')
local UIUtil = import('/lua/ui/uiutil.lua')
local Tooltip = import('/lua/ui/game/tooltip.lua')
local Group = import('/lua/maui/group.lua').Group
local Button = import('/lua/maui/button.lua').Button
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local MultiLineText = import('/lua/maui/multilinetext.lua').MultiLineText
local Popup = import('/lua/ui/controls/popups/popup.lua').Popup
local RadioButton = import('/lua/ui/controls/radiobutton.lua').RadioButton
local Prefs = import('/lua/user/prefs.lua')

-- this version of Checkbox allows scaling of checkboxes
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')

-- INFO: {
--     INFO:   after={ },
--     INFO:   author="RK4000, Sheeo, speed2 and everyone that posted feedback on the forums.",
--     INFO:   before={ },
--     INFO:   conflicts={ },
--     INFO:   copyright="",
--     INFO:   description="RKs Explosions mod replaces the default explosions with a new enhanced explosions that are unique for each faction. This is a non-togglable version.",
--     INFO:   enabled=true,
--     INFO:   exclusive=false,
--     INFO:   hookdir="/hook",
--     INFO:   icon="/mods/rks_explosions/icon.png",
--     INFO:   location="/mods/rks_explosions",
--     INFO:   name="RKs Explosions",
--     INFO:   selectable=true,
--     INFO:   shadowdir="/shadow",
--     INFO:   sort="X",
--     INFO:   status="<LOC uimod_0022>Please update to newest version",
--     INFO:   tags={ BLACKLISTED=true },
--     INFO:   title="RKs Explosions ---- (v9.0)",
--     INFO:   type="BLACKLISTED",
--     INFO:   ui_only=false,
--     INFO:   uid="1dd86878-6d2f-4f6d-b879-d14d37bcd45b",
--     INFO:   units={ },
--     INFO:   url="http://forums.faforever.com/viewtopic.php?f=41&t=6813",
--     INFO:   version=9
--     INFO: 
-- }

local states = {
    normal   = UIUtil.SkinnableFile('/BUTTON/medium/_btn_up.dds'),
    active   = UIUtil.SkinnableFile('/BUTTON/medium/_btn_down.dds'),
    over     = UIUtil.SkinnableFile('/BUTTON/medium/_btn_over.dds'),
    disabled = UIUtil.SkinnableFile('/BUTTON/medium/_btn_dis.dds'),
}

local function ConstructBody(dialogContent)
    -- destroy any previous versions
    if dialogContent.body then 
        dialogContent.body:Destroy()
    end

    -- construct a new one
    dialogContent.body = Group(dialogContent)
    LayoutHelpers.SetHeight(dialogContent.body, dialogHeight - 150)
    LayoutHelpers.SetWidth(dialogContent.body, dialogWidth - 40)
    LayoutHelpers.AtHorizontalCenterIn(dialogContent.body, dialogContent)
    LayoutHelpers.AtVerticalCenterIn(dialogContent.body, dialogContent)
    LayoutHelpers.Below(dialogContent.body, dialogContent.icon, 40)
end

local function LoadPage(dialogContent, index, unsafe)

    unsafe = false or unsafe

    local function DefaultPage(parent, dialogContent, index)

        local page = Group(parent)
        LayoutHelpers.FillParent(page, parent)
    
        -- show there is an error
        page.information1 = UIUtil.CreateText(page, 'This page has developer errors.', 14, UIUtil.bodyFont)
        page.information1:DisableHitTest()
        page.information1:SetColor('696F69')
        page.information1:SetDropShadow(true)
        LayoutHelpers.AtVerticalCenterIn(page.information1, page, -100)
        LayoutHelpers.AtHorizontalCenterIn(page.information1, page)
    
        -- explain the button
        page.information2 = MultiLineText(page, UIUtil.bodyFont, 14, '696F69')
        page.information2.Width:Set(page.Width() - 20)
        page.information2:SetText('You can view the errors in the moholog by pressing the button below. This will rerun the code without protecting the current state from errors. The errors will be printed to moholog. Use \'f9\' or \'ctrl + f9\' to open moholog. ')
        page.information2:DisableHitTest()
        LayoutHelpers.Below(page.information2, page.information1, 10)
        LayoutHelpers.AtHorizontalCenterIn(page.information2, page)
    
        -- give a warning
        page.information3 = UIUtil.CreateText(page, 'By doing so you may crash your game.', 14, UIUtil.bodyFont)
        page.information3:DisableHitTest()
        page.information3:SetColor('FF6F69')
        page.information3:SetDropShadow(true)
        LayoutHelpers.Below(page.information3, page.information2, 34)
        LayoutHelpers.AtHorizontalCenterIn(page.information3, page)
    
        -- make the button
        page.moholog = UIUtil.CreateButton(page,
            states.normal,
            states.active,
            states.over,
            states.disabled,
            'rerun page', 
            12
        )
    
        page.moholog.OnClick = function(self)
            LoadPage(dialogContent, index, true)
        end
    
        LayoutHelpers.Below(page.moholog, page.information3, 24)
        LayoutHelpers.AtHorizontalCenterIn(page.moholog, page)
    
        return page
    end

    -- make the body for the page
    ConstructBody(dialogContent)

    -- clear out the previous page
    if dialogContent.page then 
        dialogContent.page:Destroy()
    end

    -- attempt to load in the next page
    local ok, page;

    if unsafe then 
        ok = true 
        page = dialogContent.constructors[index](dialogContent.body)
    else
        ok, page = pcall(dialogContent.constructors[index], dialogContent.body)
    end

    -- in case things go wrong, load in the default page
    if not ok or not page then 
        LOG("Loading in the default page. ")

        -- destroy anything in the body and make a new one
        ConstructBody(dialogContent)

        dialogContent.page = DefaultPage(dialogContent.body, dialogContent, index)
    else 
        LOG("Loading a page with index " .. index .. ".")
        dialogContent.page = page 
    end

    -- enable / disable the controls

    dialogContent.previous:Enable()
    if index <= dialogContent.pageMin then 
        dialogContent.previous:Disable()
    end

    dialogContent.next:Enable()
    if index >= dialogContent.pageMax then 
        dialogContent.next:Disable()
    end

    -- update the page information
    dialogContent.pageInformation:SetText('page ' .. index .. ' of ' .. dialogContent.pageMax)
    LayoutHelpers.AtVerticalCenterIn(dialogContent.pageInformation, dialogContent.next)
    LayoutHelpers.AtHorizontalCenterIn(dialogContent.pageInformation, dialogContent)

end
    

-- Create the dialog for Mod Manager
-- @param parent UI control to create the dialog within.
-- @param IsHost Is the user opening the control the host (and hence able to edit?)
-- @param availableMods Present only if user is host. The availableMods map from lobby.lua.
function CreateDialog(parent, mod)
    dialogContent = Group(parent)
    LayoutHelpers.SetWidth(dialogContent, dialogWidth)
    LayoutHelpers.SetHeight(dialogContent, dialogHeight)

    modsDialog = Popup(parent, dialogContent)
    LayoutHelpers.AtLeftTopIn(modsDialog, parent, 15, 10)

    -- icon
    dialogContent.icon = Bitmap(dialogContent, mod.icon)
    dialogContent.icon:DisableHitTest()
    LayoutHelpers.SetDimensions(dialogContent.icon, 50, 50)
    LayoutHelpers.AtLeftTopIn(dialogContent.icon, dialogContent, 15, 15)

    -- title
    dialogContent.title = UIUtil.CreateText(dialogContent, mod.title, 20, UIUtil.titleFont)
    dialogContent.title:DisableHitTest()
    dialogContent.title:SetColor('B9BFB9')
    dialogContent.title:SetDropShadow(true)
    LayoutHelpers.AtVerticalCenterIn(dialogContent.title, dialogContent.icon, 0)
    LayoutHelpers.AtLeftIn(dialogContent.title, dialogContent.icon, 60) 

    -- created by
    dialogContent.createdBy = UIUtil.CreateText(dialogContent, 'Created by', 14, UIUtil.bodyFont)
    dialogContent.createdBy:DisableHitTest()
    dialogContent.createdBy:SetColor('B9BFB9')
    dialogContent.createdBy:SetDropShadow(true)
    LayoutHelpers.AtLeftTopIn(dialogContent.createdBy, dialogContent.title, 0, 25)

    -- authors
    dialogContent.authors = UIUtil.CreateText(dialogContent, mod.author, 14, UIUtil.bodyFont)
    dialogContent.authors:SetColor('FFE9ECE9') -- #FFE9ECE9
    dialogContent.authors:SetDropShadow(true)
    LayoutHelpers.CenteredRightOf(dialogContent.authors, dialogContent.createdBy, 5, 0)

    -- previous and next buttons
    dialogContent.previous = UIUtil.CreateButton(dialogContent,
        states.normal,
        states.active,
        states.over,
        states.disabled,
        'previous', 
        12
    )

    LayoutHelpers.AtLeftBottomIn(dialogContent.previous, dialogContent, 20, 20)
    Tooltip.AddControlTooltip(dialogContent.previous, { text = "Previous page", body = "Go to the previous page." })

    dialogContent.next = UIUtil.CreateButton(dialogContent,
        states.normal,
        states.active,
        states.over,
        states.disabled,
        'next', 
        12
    )

    LayoutHelpers.AtRightBottomIn(dialogContent.next, dialogContent, 20, 20)
    Tooltip.AddControlTooltip(dialogContent.next, { text = "Next page", body = "Go to the next page." })

    dialogContent.next.OnClick = function(self)
        -- attempt to up the page index
        local index = math.min(dialogContent.pageIndex + 1, dialogContent.pageMax)
        dialogContent.pageIndex = index 

        -- load in the page
        LoadPage(dialogContent, index);
    end

    dialogContent.previous.OnClick = function(self)
        -- attempt to lower the page index
        local index = math.max(dialogContent.pageIndex - 1, dialogContent.pageMin)
        dialogContent.pageIndex = index 

        local profile = Prefs.GetCurrentProfile()
        LOG(repr(profile))

        -- load in the page
        LoadPage(dialogContent, index);
    end

    -- path to the pages
    local directory = mod.location
    local file = 'mod_details.lua'
    local path = directory .. '/' .. file 

    -- attempt to load in the pages
    local ok = true;

    -- attempt to load in the file
    local details = { }
    if ok then 
        LOG("Loading details of " .. mod.title .. ".")
        ok, details = pcall(import, path)

        if not details.constructors then 
            LOG("No constructors function defined.")
            ok = false 
        end
    end

    -- attempt to construct the pages
    dialogContent.constructors = { }
    if ok then 
        LOG("Loading constructors of " .. mod.title .. ".")
        ok, dialogContent.constructors = pcall(details.constructors)
    end

    -- page information
    dialogContent.pageInformation = UIUtil.CreateText(dialogContent, '', 14, UIUtil.bodyFont)
    dialogContent.pageInformation:DisableHitTest()
    dialogContent.pageInformation:SetColor('696F69')
    dialogContent.pageInformation:SetDropShadow(true)
    LayoutHelpers.AtVerticalCenterIn(dialogContent.pageInformation, dialogContent.next)
    LayoutHelpers.AtHorizontalCenterIn(dialogContent.pageInformation, dialogContent)

    -- are there any pages at all?
    if not ok then 
        LOG("There are no (valid) pages for " .. mod.title .. ".")

        dialogContent.next:Disable()
        dialogContent.previous:Disable()

        dialogContent.pageInformation:SetText('There are no pages')
        LayoutHelpers.AtVerticalCenterIn(dialogContent.pageInformation, dialogContent.next)
        LayoutHelpers.AtHorizontalCenterIn(dialogContent.pageInformation, dialogContent)

        -- show typical description
        dialogContent.desc = MultiLineText(dialogContent, UIUtil.bodyFont, 12, 'FFA2A5A2')
        dialogContent.desc.Width:Set(dialogContent.Width() - 20)
        dialogContent.desc:SetText(mod.description)
        dialogContent.desc:DisableHitTest()
        LayoutHelpers.Below(dialogContent.desc, dialogContent.icon, 20)

        return modsDialog
    end

    -- determine lower and upper limit, initial page index
    dialogContent.pageMin = 1 
    dialogContent.pageMax = table.getn(dialogContent.constructors)
    dialogContent.pageIndex = 1

    -- if there is only one page
    if dialogContent.pageMax == dialogContent.pageMin then 
        dialogContent.next:Disable()
        dialogContent.previous:Disable()

        dialogContent.pageInformation:SetText('There is only one page.')
        LayoutHelpers.AtVerticalCenterIn(dialogContent.pageInformation, dialogContent.next)
        LayoutHelpers.AtHorizontalCenterIn(dialogContent.pageInformation, dialogContent)
    end

    -- load in the first page
    LoadPage(dialogContent, dialogContent.pageIndex)
  

    return modsDialog
end