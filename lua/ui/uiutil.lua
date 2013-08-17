 --*****************************************************************************
--* File: lua/modules/ui/uiutil.lua
--* Author: Chris Blackwell
--* Summary: Various utility functions to make UI scripts easier and more consistent
--*
--* Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--*****************************************************************************

local LazyVar = import('/lua/lazyvar.lua')
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Group = import('/lua/maui/group.lua').Group
local Text = import('/lua/maui/text.lua').Text
local MultiLineText = import('/lua/maui/multilinetext.lua').MultiLineText
local Button = import('/lua/maui/button.lua').Button
local Edit = import('/lua/maui/edit.lua').Edit
local Checkbox = import('/lua/maui/Checkbox.lua').Checkbox
local Scrollbar = import('/lua/maui/scrollbar.lua').Scrollbar
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local Cursor = import('/lua/maui/cursor.lua').Cursor
local Prefs = import('/lua/user/prefs.lua')
local Border = import('/lua/maui/border.lua').Border
local ItemList = import('/lua/maui/itemlist.lua').ItemList
local Layouts = import('/lua/skins/layouts.lua')

--* Handy global variables to assist skinning
buttonFont = import('/lua/lazyvar.lua').Create()            -- default font used for button faces
factionFont = import('/lua/lazyvar.lua').Create()      -- default font used for dialog button faces
dialogButtonFont = import('/lua/lazyvar.lua').Create()      -- default font used for dialog button faces
bodyFont = import('/lua/lazyvar.lua').Create()              -- font used for all other text
fixedFont = import('/lua/lazyvar.lua').Create()             -- font used for fixed width characters
titleFont = import('/lua/lazyvar.lua').Create()             -- font used for titles and labels
newFont = import('/lua/lazyvar.lua').Create()             -- XinnonyWork NEW FONT 2013
fontColor = import('/lua/lazyvar.lua').Create()             -- common font color
fontOverColor = import('/lua/lazyvar.lua').Create()             -- common font color
fontDownColor = import('/lua/lazyvar.lua').Create()             -- common font color
tooltipTitleColor = import('/lua/lazyvar.lua').Create()             -- common font color
tooltipBorderColor = import('/lua/lazyvar.lua').Create()             -- common font color
bodyColor = import('/lua/lazyvar.lua').Create()             -- common color for dialog body text
dialogCaptionColor = import('/lua/lazyvar.lua').Create()    -- common color for dialog titles
dialogColumnColor = import('/lua/lazyvar.lua').Create()     -- common color for column headers in a dialog
dialogButtonColor = import('/lua/lazyvar.lua').Create()     -- common color for buttons in a dialog
highlightColor = import('/lua/lazyvar.lua').Create()        -- text highlight color
disabledColor = import('/lua/lazyvar.lua').Create()         -- text disabled color
panelColor = import('/lua/lazyvar.lua').Create()            -- default color when drawing a panel
transparentPanelColor = import('/lua/lazyvar.lua').Create() -- default color when drawing a transparent panel
consoleBGColor = import('/lua/lazyvar.lua').Create()        -- console background color
consoleFGColor = import('/lua/lazyvar.lua').Create()        -- console foreground color (text)
consoleTextBGColor = import('/lua/lazyvar.lua').Create()    -- console text background color
menuFontSize = import('/lua/lazyvar.lua').Create()          -- font size used on main in game escape menu  
-- table of layouts supported by this skin, not a lazy var as we don't need updates
layouts = nil     
           
--* other handy variables!
consoleDepth = false  -- in order to get the console to always be on top, assign this number and never go over

networkBool = import('/lua/lazyvar.lua').Create()    -- boolean whether the game is local or networked

# Default scenario for skirmishes / MP Lobby
defaultScenario = '/maps/scmp_039/scmp_039_scenario.lua'      

--* These values MUST NOT CHANGE! They syncronize with values in UIManager.h and are used to
--* specify a render pass
-- render before the world is rendered
UIRP_UnderWorld     = 1
-- reserved for world views
UIRP_World          = 2
-- render with glow (note, won't render when world isn't visible)
UIRP_Glow           = 4
-- render without glow
UIRP_PostGlow       = 8

--* useful key codes, weirdly inconsistent, some are MSW vk codes, some are wxW codes :(
VK_BACKSPACE = 8
VK_TAB = 9
VK_ENTER = 13
VK_ESCAPE = 27
VK_SPACE = 32
VK_PRIOR = 33
VK_NEXT = 34
VK_UP = 38
VK_DOWN = 40
VK_PAUSE = 310

local currentSkin = import('/lua/lazyvar.lua').Create()

currentLayout = false
changeLayoutFunction = false    -- set this function to get called with the new layout name when layout changes

--* layout control, sets current layout preference
function SetCurrentLayout(layout)
    if not layout then return end
    -- make sure this skin contains the layout, otherwise do nothing
    local foundLayout = false
    for index, complayout in layouts do
        if layout == complayout then
            foundLayout = true
            break
        end
    end
    if not foundLayout then return end

    currentLayout = layout
    Prefs.SetToCurrentProfile("layout", currentLayout)
    SelectUnits(nil)
    if changeLayoutFunction then changeLayoutFunction(layout) end
end

function GetNetworkBool()
    local sessionClientsTable = GetSessionClients()
    local networkBool = false
    local sessionBool = true
    if sessionClientsTable != nil then
        networkBool = SessionIsMultiplayer()
    else
        sessionBool = false
    end
    return networkBool, sessionBool
end

function GetAnimationPrefs()
    return true
end

function GetLayoutFilename(key)
    if Layouts[currentLayout][key] then
        return Layouts[currentLayout][key]
    else
        WARN('No layout file for \'', key, '\' in the current layout. Expect layout errors.')
        return false
    end
end

function UpdateWorldBorderState(skin, isOn)
    if skin == nil then
        skin = currentSkin()
    end
    
    if SessionIsActive() then
        if isOn == nil then
            isOn = Prefs.GetOption('world_border')
        end
        if isOn then
            local skins = import('/lua/skins/skins.lua').skins
            if skins[skin].imagerMesh then
                MapBorderClear()
                --Set the world mesh to the skins world mesh
                local size = SessionGetScenarioInfo().size
                if size[1] == 2048 and size[2] == 1024 then
                    MapBorderAdd(skins[skin].imagerMeshHorz)
                    if skins[skin].imagerMeshDetailsHorz then
                        MapBorderAdd(skins[skin].imagerMeshDetailsHorz)
                    end
                else
                    MapBorderAdd(skins[skin].imagerMesh)
                    if skins[skin].imagerMeshDetails then
                        MapBorderAdd(skins[skin].imagerMeshDetails)
                    end
                end
            end
        else
            MapBorderClear()
        end
    end

end

--* skin control, sets the current skin table
function SetCurrentSkin(skin)
    local skins = import('/lua/skins/skins.lua').skins
    
    if skins[skin] == nil then
        skin = 'uef'
    end
    
    currentSkin:Set(skin)

    tooltipTitleColor:Set(skins[skin].tooltipTitleColor or skins['default'].tooltipTitleColor)
    tooltipBorderColor:Set(skins[skin].tooltipBorderColor or skins['default'].tooltipBorderColor)
    buttonFont:Set(skins[skin].buttonFont or skins['default'].buttonFont)
    factionFont:Set(skins[skin].factionFont or skins['default'].factionFont)
    dialogButtonFont:Set(skins[skin].dialogButtonFont or skins['default'].dialogButtonFont)
    bodyFont:Set(skins[skin].bodyFont or skins['default'].bodyFont)
    fixedFont:Set(skins[skin].fixedFont or skins['default'].fixedFont)
    titleFont:Set(skins[skin].titleFont or skins['default'].titleFont)
    fontColor:Set(skins[skin].fontColor or skins['default'].fontColor)
    bodyColor:Set(skins[skin].bodyColor or skins['default'].bodyColor)
    fontOverColor:Set(skins[skin].fontOverColor or skins['default'].fontOverColor)
    fontDownColor:Set(skins[skin].fontDownColor or skins['default'].fontDownColor)
    dialogCaptionColor:Set(skins[skin].dialogCaptionColor or skins['default'].dialogCaptionColor)
    dialogColumnColor:Set(skins[skin].dialogColumnColor or skins['default'].dialogColumnColor)
    dialogButtonColor:Set(skins[skin].dialogButtonColor or skins['default'].dialogButtonColor)
    highlightColor:Set(skins[skin].highlightColor or skins['default'].highlightColor)
    disabledColor:Set(skins[skin].disabledColor or skins['default'].disabledColor)
    panelColor:Set(skins[skin].panelColor or skins['default'].panelColor)
    transparentPanelColor:Set(skins[skin].transparentPanelColor or skins['default'].transparentPanelColor)
    consoleBGColor:Set(skins[skin].consoleBGColor or skins['default'].consoleBGColor)
    consoleFGColor:Set(skins[skin].consoleFGColor or skins['default'].consoleFGColor)
    consoleTextBGColor:Set(skins[skin].consoleTextBGColor or skins['default'].consoleTextBGColor)
    menuFontSize:Set(skins[skin].menuFontSize or skins['default'].menuFontSize)
    layouts = skins[skin].layouts or skins['default'].layouts

    UpdateWorldBorderState(skin)
    
    local curLayout = Prefs.GetFromCurrentProfile("layout")

    if not curLayout then
        SetCurrentLayout(layouts[1])
    else
        local validLayout = false
        for i, layoutName in layouts do
            if layoutName == curLayout then
                validLayout = true
                break
            end
        end
        if validLayout then
            SetCurrentLayout(curLayout)
        else
            SetCurrentLayout(layouts[1])
        end
    end

    Prefs.SetToCurrentProfile("skin", skin)
end

function SetCurrentSkin2(skin)
    local skins = import('/lua/skins/skins.lua').skins
    
    if skins[skin] == nil then
        skin = 'uef'
    end
    
    currentSkin:Set(skin)

    menuFontSize:Set(skins[skin].menuFontSize or skins['default'].menuFontSize)
    layouts = skins[skin].layouts or skins['default'].layouts

    --UpdateWorldBorderState(skin)
    
    --local curLayout = Prefs.GetFromCurrentProfile("layout")

    --if not curLayout then
        --SetCurrentLayout(layouts[1])
    --else
        --local validLayout = false
        --for i, layoutName in layouts do
            --if layoutName == curLayout then
                --validLayout = true
                --break
            --end
        --end
        --if validLayout then
            --SetCurrentLayout(curLayout)
        --else
            --SetCurrentLayout(layouts[1])
        --end
    --end

    Prefs.SetToCurrentProfile("skin", skin)
end

--* cycle through all available skins
function RotateSkin(direction)
    if not SessionIsActive() or import('/lua/ui/game/gamemain.lua').IsNISMode() then
        return
    end

    local skins = import('/lua/skins/skins.lua').skins

    -- build an array of skin names
    local skinNames = {}
    for skin in skins do
        table.insert(skinNames, skin)
    end

    local dir
    if direction == '+' then
        dir = 1
    else
        dir = -1
    end

    -- Find the next skin from our current skin, skipping default, as it's not really a skin!
    -- note that if the skin table is updated while running, the order of the table might change
    -- so your cycle may be different. No big deal, just be aware it's a side effect.
    local numSkins = table.getn(skinNames)
    for index, skinName in skinNames do
        if skinName == currentSkin() then
            local nextSkinIndex = index + dir
            if nextSkinIndex > numSkins then nextSkinIndex = 1 end
            if nextSkinIndex < 1 then nextSkinIndex = numSkins end
            if skinNames[nextSkinIndex] == 'default' then   -- skip default entry as it's not really a skin
                nextSkinIndex = nextSkinIndex + dir
                if nextSkinIndex > numSkins then nextSkinIndex = 1 end
                if nextSkinIndex < 1 then nextSkinIndex = numSkins end
            end
            LOG('attempting to set skin to: ', skinNames[nextSkinIndex])
            SetCurrentSkin(skinNames[nextSkinIndex])
            break
        end
    end
end

--* cycle through all available layouts
function RotateLayout(direction)

    # disable when in Screen Capture mode
    if import('/lua/ui/game/gamemain.lua').gameUIHidden then
        return
    end

    local dir
    if direction == '+' then
        dir = 1
    else
        dir = -1
    end

    local numLayouts = table.getn(layouts)
    for index, layoutName in layouts do
        if layoutName == currentLayout then
            local nextLayoutIndex = index + dir
            if nextLayoutIndex > numLayouts then nextLayoutIndex = 1 end
            if nextLayoutIndex < 1 then nextLayoutIndex = numLayouts end
            SetCurrentLayout(layouts[nextLayoutIndex])
            break
        end
    end
end

--* given a path and name relative to the skin path, returns the full path based on the current skin
function UIFile(filespec)
    local skins = import('/lua/skins/skins.lua').skins
    local visitingSkin = currentSkin()
    local currentPath = skins[visitingSkin].texturesPath

    if visitingSkin == nil or currentPath == nil then
        return nil
    end

    -- if current skin is default, then don't bother trying to look for it, just append the default dir
    if visitingSkin == 'default' then
        return currentPath .. filespec
    else
        while visitingSkin do
            local curFile = currentPath .. filespec
            if DiskGetFileInfo(curFile) then
                return curFile
            else
                visitingSkin = skins[visitingSkin].default
                if visitingSkin then currentPath = skins[visitingSkin].texturesPath end
            end
        end
    end

    LOG("Warning: Unable to find file ", filespec)
    -- pass out the final string anyway so resource loader can gracefully fail
    return filespec
end

--* return the filename as a lazy var function to allow triggering of OnDirty
function SkinnableFile(filespec)
    return function()
        return UIFile(filespec)
    end
end

--* each UI screen needs something to be responsible for parenting all its controls so
--* placement and destruction can occur. This creates a group which fills the screen.
function CreateScreenGroup(root, debugName)
    if not root then return end
    local screenGroup = Group(root, debugName or "screenGroup")
    LayoutHelpers.FillParent(screenGroup, root)
    return screenGroup
end

--* Get cursor information for a given cursor ID
function GetCursor(id)
    local skins = import('/lua/skins/skins.lua').skins
    local cursors = skins[currentSkin()].cursors or skins['default'].cursors
    if not cursors[id] then
        LOG("Requested cursor not found: " .. id)
    end
    return cursors[id][1], cursors[id][2], cursors[id][3], cursors[id][4], cursors[id][5]
end

--* create the one cursor used by the game
function CreateCursor()
    local cursor = Cursor(GetCursor('DEFAULT'))
    return cursor
end

--* return a text object with the appropriate font set
function CreateText(parent, label, pointSize, font)
    label = LOC(label) or LOC("<LOC uiutil_0000>[no text]")
    font = font or buttonFont
    local text = Text(parent, "Text: " .. label)
    text:SetFont(font, pointSize)
    text:SetColor(fontColor)
    text:SetText(label)
    return text
end

function SetupEditStd(control, foreColor, backColor, highlightFore, highlightBack, fontFace, fontSize, charLimit)
    if charLimit then
        control:SetMaxChars(charLimit)
    end
    if foreColor then
        control:SetForegroundColor(foreColor)
    end
    if backColor then
        control:SetBackgroundColor(backColor)
    end
    if highlightFore then
        control:SetHighlightForegroundColor(highlightFore)
    end
    if highlightBack then
        control:SetHighlightBackgroundColor(highlightBack)
    end
    if fontFace and fontSize then
        control:SetFont(fontFace, fontSize)
    end
    
    control.OnCharPressed = function(self, charcode)
        if charcode == VK_TAB then
            return true
        end
        local charLim = self:GetMaxChars()
        if STR_Utf8Len(self:GetText()) >= charLim then
            local sound = Sound({Cue = 'UI_Menu_Error_01', Bank = 'Interface',})
            PlaySound(sound)
        end
    end
end

--* return a button set up with a text overlay and a click sound
function CreateButton(parent, up, down, over, disabled, label, pointSize, textOffsetVert, textOffsetHorz, clickCue, rolloverCue)
    textOffsetVert = textOffsetVert or 0
    textOffsetHorz = textOffsetHorz or 0
    if clickCue == "NO_SOUND" then
        clickCue = nil
    else
        clickCue = clickCue or "UI_Menu_MouseDown_Sml"
    end
    if rolloverCue == "NO_SOUND" then
        rolloverCue = nil
    else
        rolloverCue = rolloverCue or "UI_Menu_Rollover_Sml"
    end
    if type(up) == 'string' then
        up = SkinnableFile(up)
    end
    if type(down) == 'string' then
        down = SkinnableFile(down)
    end
    if type(over) == 'string' then
        over = SkinnableFile(over)
    end
    if type(disabled) == 'string' then
        disabled = SkinnableFile(disabled)
    end

    local button = Button(parent, up, down, over, disabled, clickCue, rolloverCue)
    button:UseAlphaHitTest(true)

    if label and pointSize then
        button.label = CreateText(button, label, pointSize)
        LayoutHelpers.AtCenterIn(button.label, button, textOffsetVert, textOffsetHorz)
        button.label:DisableHitTest()

        -- if text exists, set up to grey it out
        button.OnDisable = function(self)
            Button.OnDisable(self)
            button.label:SetColor(disabledColor)
        end

        button.OnEnable = function(self)
            Button.OnEnable(self)
            button.label:SetColor(fontColor)
        end
        button.OnRolloverEvent = function(self, event)
            if event == 'enter' then
                button.label:SetColor(fontOverColor)
            elseif event == 'exit' then
                button.label:SetColor(fontColor)
            elseif event == 'down' then
                button.label:SetColor(fontDownColor)
            end
        end
    end

    return button
end

function SetNewButtonTextures(button, up, down, over, disabled)
    -- if strings passed in, make them skinnables, otherwise assume they are already skinnables
    if type(up) == 'string' then
        up = SkinnableFile(up)
    end
    if type(down) == 'string' then
        down = SkinnableFile(down)
    end
    if type(over) == 'string' then
        over = SkinnableFile(over)
    end
    if type(disabled) == 'string' then
        disabled = SkinnableFile(disabled)
    end

    button:SetNewTextures(up, down, over, disabled)
end

--* create a button with standardized texture names
--* given a path and button name prefix, generates the four button asset file names according to the naming convention
function CreateButtonStd(parent, filename, label, pointSize, textOffsetVert, textOffsetHorz, clickCue, rolloverCue)
    return CreateButton(parent
        , filename .. "_btn_up.dds"
        , filename .. "_btn_down.dds"
        , filename .. "_btn_over.dds"
        , filename .. "_btn_dis.dds"
        , label
        , pointSize
        , textOffsetVert
        , textOffsetHorz
        , clickCue
        , rolloverCue
        )
end

function CreateButtonStd2(parent, filename, label, pointSize, textOffsetVert, textOffsetHorz, clickCue, rolloverCue) -- XinnonyWork
    return CreateButton(parent
        , filename .. "_up.dds"
        , filename .. "_down.dds"
        , filename .. "_over.dds"
        , filename .. "_dis.dds"
        , label
        , pointSize
        , textOffsetVert
        , textOffsetHorz
        , clickCue
        , rolloverCue
        )
end

function CreateCheckbox(parent, up, upsel, over, oversel, dis, dissel, clickCue, rollCue)
    local clickSound = clickCue or 'UI_Mini_MouseDown'
    local rollSound = rollCue or 'UI_Mini_Rollover'
    local checkbox = Checkbox( parent, up, upsel, over, oversel, dis, dissel, clickSound, rollSound)
    checkbox:UseAlphaHitTest(true)
    return checkbox
end

function CreateCheckboxStd(parent, filename, clickCue, rollCue)
    local checkbox = CreateCheckbox( parent,
        SkinnableFile(filename .. '-d_btn_up.dds'),
        SkinnableFile(filename .. '-s_btn_up.dds'),
        SkinnableFile(filename .. '-d_btn_over.dds'),
        SkinnableFile(filename .. '-s_btn_over.dds'),
        SkinnableFile(filename .. '-d_btn_dis.dds'),
        SkinnableFile(filename .. '-s_btn_dis.dds'),
        clickCue, rollCue)
    return checkbox
end

function CreateDialogButtonStd(parent, filename, label, pointSize, textOffsetVert, textOffsetHorz, clickCue, rolloverCue)
    local button = CreateButtonStd(parent,filename,label,pointSize,textOffsetVert,textOffsetHorz, clickCue, rolloverCue)
    button.label:SetFont( dialogButtonFont, pointSize )
    button.label:SetColor( dialogButtonColor )
    return button
end

function SetNewButtonStdTextures(button, filename)
    SetNewButtonTextures(button
        , filename .. "_btn_up.dds"
        , filename .. "_btn_down.dds"
        , filename .. "_btn_over.dds"
        , filename .. "_btn_dis.dds")
end

--* return the standard scrollbar
function CreateVertScrollbarFor(attachto, offset_right, filename, offset_bottom, offset_top)
    offset_right = offset_right or 0
	offset_bottom = offset_bottom or 0
	offset_top = offset_top or 0
    local textureName = filename or '/small-vert_scroll/'
    local scrollbg = textureName..'back_scr_mid.dds'
    local scrollbarmid = textureName..'bar-mid_scr_over.dds'
    local scrollbartop = textureName..'bar-top_scr_up.dds'
    local scrollbarbot = textureName..'bar-bot_scr_up.dds'
    if filename then
        scrollbg = textureName..'back_scr_mid.dds'
        scrollbarmid = textureName..'bar-mid_scr_up.dds'
        scrollbartop = textureName..'bar-top_scr_up.dds'
        scrollbarbot = textureName..'bar-bot_scr_up.dds'
    end
    local scrollbar = Scrollbar(attachto, import('/lua/maui/scrollbar.lua').ScrollAxis.Vert)
    scrollbar:SetTextures(  SkinnableFile(scrollbg)
                            ,SkinnableFile(scrollbarmid)
                            ,SkinnableFile(scrollbartop)
                            ,SkinnableFile(scrollbarbot))
                            
    local scrollUpButton = Button(  scrollbar
                                    , SkinnableFile(textureName..'arrow-up_scr_up.dds')
                                    , SkinnableFile(textureName..'arrow-up_scr_over.dds')
                                    , SkinnableFile(textureName..'arrow-up_scr_down.dds')
                                    , SkinnableFile(textureName..'arrow-up_scr_dis.dds')
                                    , "UI_Arrow_Click")

    local scrollDownButton = Button(  scrollbar
                                    , SkinnableFile(textureName..'arrow-down_scr_up.dds')
                                    , SkinnableFile(textureName..'arrow-down_scr_over.dds')
                                    , SkinnableFile(textureName..'arrow-down_scr_down.dds')
                                    , SkinnableFile(textureName..'arrow-down_scr_dis.dds')
                                    , "UI_Arrow_Click")

    scrollbar.Left:Set(function() return attachto.Right() + offset_right end)
    scrollbar.Top:Set(scrollUpButton.Bottom)
    scrollbar.Bottom:Set(scrollDownButton.Top)

    scrollUpButton.Left:Set(scrollbar.Left)
    scrollUpButton.Top:Set(function() return attachto.Top() + offset_top end)
    
	scrollDownButton.Left:Set(scrollbar.Left)
    scrollDownButton.Bottom:Set(function() return attachto.Bottom() + offset_bottom end)
    
    scrollbar.Right:Set(scrollUpButton.Right)
    
    scrollbar:AddButtons(scrollUpButton, scrollDownButton)
    scrollbar:SetScrollable(attachto)

    return scrollbar
end

function CreateHorzScrollbarFor(attachto, offset)
    offset = offset or 0
    local scrollbar = Scrollbar(attachto, import('/lua/maui/scrollbar.lua').ScrollAxis.Horz)
    local scrollRightButton = Button(  scrollbar
                                    , SkinnableFile('/widgets/large-h_scr/arrow-right_scr_up.dds')
                                    , SkinnableFile('/widgets/large-h_scr/arrow-right_scr_down.dds')
                                    , SkinnableFile('/widgets/large-h_scr/arrow-right_scr_over.dds')
                                    , SkinnableFile('/widgets/large-h_scr/arrow-right_scr_dis.dds'))
    scrollRightButton.Right:Set(attachto.Right)
    scrollRightButton.Bottom:Set(function() return attachto.Top() + offset end)

    local scrollLeftButton = Button(  scrollbar
                                    , SkinnableFile('/widgets/large-h_scr/arrow-left_scr_up.dds')
                                    , SkinnableFile('/widgets/large-h_scr/arrow-left_scr_down.dds')
                                    , SkinnableFile('/widgets/large-h_scr/arrow-left_scr_over.dds')
                                    , SkinnableFile('/widgets/large-h_scr/arrow-left_scr_dis.dds'))
    scrollLeftButton.Left:Set(attachto.Left)
    scrollLeftButton.Bottom:Set(function() return attachto.Top() + offset end)

    scrollbar:SetTextures(  UIFile('/widgets/back_scr/back_scr_mid.dds')
                            ,UIFile('/widgets/large-h_scr/bar-mid_scr_over.dds')
                            ,UIFile('/widgets/large-h_scr/bar-right_scr_over.dds')
                            ,UIFile('/widgets/large-h_scr/bar-left_scr_over.dds'))
    scrollbar.Left:Set(scrollLeftButton.Right)
    scrollbar.Right:Set(scrollRightButton.Left)
    scrollbar.Top:Set(scrollRightButton.Top)
    scrollbar.Bottom:Set(scrollRightButton.Bottom)

    scrollbar:AddButtons(scrollLeftButton, scrollRightButton)
    scrollbar:SetScrollable(attachto)

    return scrollbar
end

-- cause a dialog to get input focus, optional functions to perform when the user hits enter or escape
-- functions signature is: function()
function MakeInputModal(control, onEnterFunc, onEscFunc)
    AddInputCapture(control)
    
    local oldOnDestroy = control.OnDestroy
    control.OnDestroy = function(self)
        RemoveInputCapture(control)
        oldOnDestroy(self)
    end    
    
    if onEnterFunc or onEscFunc then
        control.oldHandleEvent = control.HandleEvent
        control.HandleEvent = function(self, event)
            if event.Type == 'KeyDown' then
                if event.KeyCode == VK_ESCAPE then
                    if onEscFunc then
                        onEscFunc()
                        return true
                    end                
                elseif event.KeyCode == VK_ENTER then
                    if onEnterFunc then
                        onEnterFunc()
                        return true
                    end
                end
            end
            if control.oldHandleEvent then
                return control.oldHandleEvent(self, event)
			end               
			return true
        end
    end
end

-- create and manage an info dialog
-- parent: the control to parent the dialog to
-- dialogText: the text to display in the dialog
-- button1Text: text for the first button (opt)
-- button1Callback: callback function for the first button, signature function() (opt)
-- button2Text: text for the second button (opt)
-- button2Callback: callback function for the second button, signature function() (opt)
-- button3Text: text for the second button (opt)
-- button3Callback: callback function for the second button, signature function() (opt)
-- destroyOnCallback: if true, destroy when any button is pressed (if false, you must destroy) (opt)
-- modalInfo: Sets up modal info for dialog using a table in the form:
--  escapeButton = int 1-3 : the button function to mimic when the escape button is pressed
--  enterButton = int 1-3 : the button function to mimic when the enterButton is pressed
--  worldCover = bool : control if a world cover should be shown
function QuickDialog(parent, dialogText, button1Text, button1Callback, button2Text, button2Callback, button3Text, button3Callback, destroyOnCallback, modalInfo)
    -- if there is a callback and destroy not specified, assume destroy
    if (destroyOnCallback == nil) and (button1Callback or button2Callback or button3Callback) then
        destroyOnCallback = true
    end

    local dialog = Group(parent, "quickDialogGroup")

    LayoutHelpers.AtCenterIn(dialog, parent)
    dialog.Depth:Set(GetFrame(parent:GetRootFrame():GetTargetHead()):GetTopmostDepth() + 1)
    local background = Bitmap(dialog, SkinnableFile('/dialogs/dialog/panel_bmp_m.dds'))
    dialog._background = background
    dialog.Width:Set(background.Width)
    dialog.Height:Set(background.Height)
    LayoutHelpers.FillParent(background, dialog)
    
    local textLine = {}
    textLine[1] = CreateText(dialog, "", 18, titleFont)
    textLine[1].Top:Set(background.Top)
    LayoutHelpers.AtHorizontalCenterIn(textLine[1], dialog)
    
    local textBoxWidth = (dialog.Width() - 80) 
    local tempTable = import('/lua/maui/text.lua').WrapText(LOC(dialogText), textBoxWidth,
    function(text)
        return textLine[1]:GetStringAdvance(text)
    end)

    local tempLines = table.getn(tempTable)
    
    local prevControl = false
    for i, v in tempTable do
        if i == 1 then
            textLine[1]:SetText(v)
            prevControl = textLine[1]
        else
            textLine[i] = CreateText(dialog, v, 18, titleFont)
            LayoutHelpers.Below(textLine[i], prevControl)
            LayoutHelpers.AtHorizontalCenterIn(textLine[i], dialog)
            prevControl = textLine[i]
        end
    end
    
    background:SetTiled(true)
    background.Bottom:Set(textLine[tempLines].Bottom)
    
    local backgroundTop = Bitmap(dialog, SkinnableFile('/dialogs/dialog/panel_bmp_T.dds'))
    backgroundTop.Bottom:Set(background.Top)
    backgroundTop.Left:Set(background.Left)
    local backgroundBottom = Bitmap(dialog, SkinnableFile('/dialogs/dialog/panel_bmp_b.dds'))
    backgroundBottom.Top:Set(background.Bottom)
    backgroundBottom.Left:Set(background.Left)
    
    background.brackets = CreateDialogBrackets(background, 35, 65, 35, 115, true)
    
    if not modalInfo or modalInfo.worldCover then
        CreateWorldCover(dialog)
    end
    
    local function MakeButton(text, callback)
        local button = CreateButtonStd( background
                                        , '/scx_menu/small-btn/small'
                                        , text
                                        , 14
                                        , 2)
        if callback then
            button.OnClick = function(self)
                callback()
				if destroyOnCallback then
					dialog:Destroy()
				end
            end
        else
            button.OnClick = function(self)
                dialog:Destroy()
            end
        end
        return button
    end

    dialog._button1 = false
    dialog._button2 = false
    dialog._button3 = false

    if button1Text then
        dialog._button1 = MakeButton(button1Text, button1Callback)
        LayoutHelpers.Below(dialog._button1, background, 0)
    end
    if button2Text then
        dialog._button2 = MakeButton(button2Text, button2Callback)
        LayoutHelpers.Below(dialog._button2, background, 0)
    end
    if button3Text then
        dialog._button3 = MakeButton(button3Text, button3Callback)
        LayoutHelpers.Below(dialog._button3, background, 0)
    end

    if dialog._button3 then
        -- center each button to one third of the dialog
        LayoutHelpers.AtHorizontalCenterIn(dialog._button2, dialog)
        LayoutHelpers.LeftOf(dialog._button1, dialog._button2, -8)
        LayoutHelpers.ResetLeft(dialog._button1)
        LayoutHelpers.RightOf(dialog._button3, dialog._button2, -8)
        backgroundTop:SetTexture(SkinnableFile('/dialogs/dialog_02/panel_bmp_T.dds'))
        backgroundBottom:SetTexture(SkinnableFile('/dialogs/dialog_02/panel_bmp_b.dds'))
        background:SetTexture(SkinnableFile('/dialogs/dialog_02/panel_bmp_m.dds'))
    elseif dialog._button2 then
        -- center each button to half the dialog
        dialog._button1.Left:Set(function()
            return dialog.Left() + (((dialog.Width() / 2) - dialog._button1.Width()) / 2) + 8
        end)
        dialog._button2.Left:Set(function()
            local halfWidth = dialog.Width() / 2
            return dialog.Left() + halfWidth + ((halfWidth - dialog._button2.Width()) / 2) - 8
        end)
    elseif dialog._button1 then
        LayoutHelpers.AtHorizontalCenterIn(dialog._button1, dialog)
    else
        backgroundBottom:SetTexture(UIFile('/dialogs/dialog/panel_bmp_alt_b.dds'))
        background.brackets:Hide()
    end

    if modalInfo and not modalInfo.OnlyWorldCover then
        local function OnEnterFunc()
            if modalInfo.enterButton then
                if modalInfo.enterButton == 1 then
                    if dialog._button1 then
                        dialog._button1.OnClick(dialog._button1)
                    end
                elseif modalInfo.enterButton == 2 then
                    if dialog._button2 then
                        dialog._button2.OnClick(dialog._button2)
                    end
                elseif modalInfo.enterButton == 3 then
                    if dialog._button3 then
                        dialog._button3.OnClick(dialog._button3)
                    end
                end
            end
        end
        
        local function OnEscFunc()
            if modalInfo.escapeButton then
                if modalInfo.escapeButton == 1 then
                    if dialog._button1 then
                        dialog._button1.OnClick(dialog._button1)
                    end
                elseif modalInfo.escapeButton == 2 then
                    if dialog._button2 then
                        dialog._button2.OnClick(dialog._button2)
                    end
                elseif modalInfo.escapeButton == 3 then
                    if dialog._button3 then
                        dialog._button3.OnClick(dialog._button3)
                    end
                end
            end
        end
        
        MakeInputModal(dialog, OnEnterFunc, OnEscFunc)
    end

    return dialog
end

function QuickDialog2(parent, dialogText, button1Text, button1Callback, button2Text, button2Callback, button3Text, button3Callback, destroyOnCallback, modalInfo, Offset_Width)
    -- if there is a callback and destroy not specified, assume destroy
    if (destroyOnCallback == nil) and (button1Callback or button2Callback or button3Callback) then
        destroyOnCallback = true
    end

    local dialog = Group(parent, "quickDialogGroup")

    LayoutHelpers.AtCenterIn(dialog, parent)
    dialog.Depth:Set(GetFrame(parent:GetRootFrame():GetTargetHead()):GetTopmostDepth() + 1)
    local background = Bitmap(dialog, SkinnableFile('/dialogs/dialog_02/panel_bmp_m.dds'))
    dialog._background = background
    dialog.Width:Set(654)--background.Width())
    dialog.Height:Set(background.Height)
    LayoutHelpers.FillParent(background, dialog)
    
    local textLine = {}
    textLine[1] = CreateText(dialog, "", 18, 'Arial')
    textLine[1].Top:Set(background.Top)
    LayoutHelpers.AtHorizontalCenterIn(textLine[1], dialog)
    
    local tempTable = import('/lua/maui/text.lua').WrapText(LOC(dialogText), 1000, function(text) return textLine[1]:GetStringAdvance(text) end)

    local tempLines = table.getn(tempTable)
    
    local prevControl = false
    for i, v in tempTable do
        if i == 1 then
            textLine[1]:SetText(v)
            prevControl = textLine[1]
        else
            textLine[i] = CreateText(dialog, v, 10, 'Arial')
            LayoutHelpers.Below(textLine[i], prevControl)
			LayoutHelpers.AtLeftIn(textLine[i], dialog, 30)
            --LayoutHelpers.AtHorizontalCenterIn(textLine[i], dialog)
            prevControl = textLine[i]
        end
    end
    
    background:SetTiled(true)
    background.Bottom:Set(textLine[tempLines].Bottom)
    
    local backgroundTop = Bitmap(dialog, SkinnableFile('/dialogs/dialog_02/panel_bmp_T.dds'))
    backgroundTop.Bottom:Set(background.Top)
    backgroundTop.Left:Set(background.Left)
    local backgroundBottom = Bitmap(dialog, SkinnableFile('/dialogs/dialog_02/panel_bmp_b.dds'))
    backgroundBottom.Top:Set(background.Bottom)
    backgroundBottom.Left:Set(background.Left)
    
    --background.brackets = CreateDialogBrackets(background, 35, 65, 35, 115, true)
    
    if not modalInfo or modalInfo.worldCover then
        CreateWorldCover(dialog)
    end
    
    local function MakeButton(text, callback)
        local button = CreateButtonStd( background
                                        , '/scx_menu/small-btn/small'
                                        , text
                                        , 14
                                        , 2)
        if callback then
            button.OnClick = function(self)
                callback()
				if destroyOnCallback then
					dialog:Destroy()
				end
            end
        else
            button.OnClick = function(self)
                dialog:Destroy()
            end
        end
        return button
    end

    dialog._button1 = false
    dialog._button2 = false
    dialog._button3 = false

    if button1Text then
        dialog._button1 = MakeButton(button1Text, button1Callback)
        LayoutHelpers.Below(dialog._button1, background, 0)
    end
    if button2Text then
        dialog._button2 = MakeButton(button2Text, button2Callback)
        LayoutHelpers.Below(dialog._button2, background, 0)
    end
    if button3Text then
        dialog._button3 = MakeButton(button3Text, button3Callback)
        LayoutHelpers.Below(dialog._button3, background, 0)
    end

    if dialog._button3 then
        -- center each button to one third of the dialog
        LayoutHelpers.AtHorizontalCenterIn(dialog._button2, dialog)
        LayoutHelpers.LeftOf(dialog._button1, dialog._button2, -8)
        LayoutHelpers.ResetLeft(dialog._button1)
        LayoutHelpers.RightOf(dialog._button3, dialog._button2, -8)
        backgroundTop:SetTexture(SkinnableFile('/dialogs/dialog_02/panel_bmp_T.dds'))
        backgroundBottom:SetTexture(SkinnableFile('/dialogs/dialog_02/panel_bmp_b.dds'))
        background:SetTexture(SkinnableFile('/dialogs/dialog_02/panel_bmp_m.dds'))
    elseif dialog._button2 then
        -- center each button to half the dialog
        dialog._button1.Left:Set(function()
            return dialog.Left() + (((dialog.Width() / 2) - dialog._button1.Width()) / 2) + 8
        end)
        dialog._button2.Left:Set(function()
            local halfWidth = dialog.Width() / 2
            return dialog.Left() + halfWidth + ((halfWidth - dialog._button2.Width()) / 2) - 8
        end)
    elseif dialog._button1 then
        LayoutHelpers.AtHorizontalCenterIn(dialog._button1, dialog)
    else
        backgroundBottom:SetTexture(UIFile('/dialogs/dialog/panel_bmp_alt_b.dds'))
        background.brackets:Hide()
    end

    if modalInfo and not modalInfo.OnlyWorldCover then
        local function OnEnterFunc()
            if modalInfo.enterButton then
                if modalInfo.enterButton == 1 then
                    if dialog._button1 then
                        dialog._button1.OnClick(dialog._button1)
                    end
                elseif modalInfo.enterButton == 2 then
                    if dialog._button2 then
                        dialog._button2.OnClick(dialog._button2)
                    end
                elseif modalInfo.enterButton == 3 then
                    if dialog._button3 then
                        dialog._button3.OnClick(dialog._button3)
                    end
                end
            end
        end
        
        local function OnEscFunc()
            if modalInfo.escapeButton then
                if modalInfo.escapeButton == 1 then
                    if dialog._button1 then
                        dialog._button1.OnClick(dialog._button1)
                    end
                elseif modalInfo.escapeButton == 2 then
                    if dialog._button2 then
                        dialog._button2.OnClick(dialog._button2)
                    end
                elseif modalInfo.escapeButton == 3 then
                    if dialog._button3 then
                        dialog._button3.OnClick(dialog._button3)
                    end
                end
            end
        end
        
        MakeInputModal(dialog, OnEnterFunc, OnEscFunc)
    end

    return dialog
end

function CreateWorldCover(parent, colorOverride)
    local NumFrame = GetNumRootFrames() - 1
    local worldCovers = {}
    for i = 0, NumFrame do
        local index = i
        if GetFrame(index) == parent:GetRootFrame() then
            worldCovers[index] = Bitmap(parent)
            worldCovers[index].ID = index
            worldCovers[index].OnDestroy = function(self)
                for h, x in worldCovers do
                    if x and h != self.ID then 
                        x:Destroy()
                    end
                end
            end
            worldCovers[index].OnHide = function(self, hidden)
                for h, x in worldCovers do
                    if x and h != self.ID then 
                        x:SetHidden(hidden)
                    end
                end
            end
        else
            worldCovers[index] = Bitmap(GetFrame(index))
        end
        worldCovers[index]:SetSolidColor(colorOverride or 'ff000000')
        LayoutHelpers.FillParent(worldCovers[index], GetFrame(index))
        worldCovers[index].Depth:Set(function() return parent.Depth() - 2 end)
        worldCovers[index]:SetAlpha(0)
        worldCovers[index]:SetNeedsFrameUpdate(true)
        worldCovers[index].OnFrame = function(self, delta)
            local targetAlpha = self:GetAlpha() + (delta * 1.5)
            if targetAlpha < .8 then
                self:SetAlpha(targetAlpha)
            else
                self:SetAlpha(.8)
                self:SetNeedsFrameUpdate(false)
            end
        end
    end
    
    return worldCovers
end

function ShowInfoDialog(parent, dialogText, buttonText, buttonCallback, destroyOnCallback)
    local dlg = QuickDialog(parent, dialogText, buttonText, buttonCallback, nil, nil, nil, nil, destroyOnCallback, {worldCover = false, enterButton = 1, escapeButton = 1})
    return dlg
end

-- create a table of sequential file names (useful for loading animations)
function CreateSequentialFilenameTable(root, ext, first, last, numPlaces)
    local retTable = {}
    local formatString = string.format("%%s%%0%dd.%%s", numPlaces)
    for index = first, last do
        retTable[(index - first) + 1] = SkinnableFile(string.format(formatString, root, index, ext))
    end
    return retTable
end

-- create a box which is controlled by its external borders, and gives access to the "client" area as well
function CreateBox(parent)
    local border = Border(parent)
    border:SetTextures(
        SkinnableFile('/game/generic_brd/generic_brd_vert_l.dds'),
        SkinnableFile('/game/generic_brd/generic_brd_horz_um.dds'),
        SkinnableFile('/game/generic_brd/generic_brd_ul.dds'),
        SkinnableFile('/game/generic_brd/generic_brd_ur.dds'),
        SkinnableFile('/game/generic_brd/generic_brd_ll.dds'),
        SkinnableFile('/game/generic_brd/generic_brd_lr.dds'))
    local clientArea = Bitmap(parent, SkinnableFile('/game/generic_brd/generic_brd_m.dds'))
    border:LayoutControlInside(clientArea)
    clientArea.Width:Set(function() return clientArea.Right() - clientArea.Left() end)
    clientArea.Height:Set(function() return clientAreat.Bottom() - clientArea.Top() end)
    return border, clientArea
end

-- create borders around a control, with optional background
function CreateBorder(parent, addBg)
    local border = Border(parent)
    border:SetTextures(
        SkinnableFile('/game/generic_brd/generic_brd_vert_l.dds'),
        SkinnableFile('/game/generic_brd/generic_brd_horz_um.dds'),
        SkinnableFile('/game/generic_brd/generic_brd_ul.dds'),
        SkinnableFile('/game/generic_brd/generic_brd_ur.dds'),
        SkinnableFile('/game/generic_brd/generic_brd_ll.dds'),
        SkinnableFile('/game/generic_brd/generic_brd_lr.dds'))
    border:LayoutAroundControl(parent)

    local bg = nil
    if addBg then
        bg = Bitmap(parent, SkinnableFile('/game/generic_brd/generic_brd_m.dds'))
        border:LayoutControlInside(bg)
        bg.Width:Set(function() return bg.Right() - bg.Left() end)
        bg.Height:Set(function() return bg.Bottom() - bg.Top() end)
    end

    return border, bg
end

function GetFactionIcon(factionIndex)
    return import('/lua/factions.lua').Factions[factionIndex + 1].Icon
end

-- make sure you lay out text box before you attempt to set text
function CreateTextBox(parent)
    local box = ItemList(parent)
    box:SetFont(bodyFont, 14)
    box:SetColors(bodyColor, "black",  highlightColor, "white")
    CreateVertScrollbarFor(box)
    return box
end

function SetTextBoxText(textBox, text)
    textBox:DeleteAllItems()
    local wrapped = import('/lua/maui/text.lua').WrapText(LOC(text), textBox.Width(), function(curText) return textBox:GetStringAdvance(curText) end)
    for i, line in wrapped do
        textBox:AddItem(line)
    end 
end

function CreateDialogBrackets(parent, leftOffset, topOffset, rightOffset, bottomOffset, altTextures)
    local ret = Group(parent)
    
    if altTextures then
        ret.topleft = Bitmap(ret, UIFile('/scx_menu/panel-brackets-small/bracket-ul_bmp.dds'))
        ret.topright = Bitmap(ret, UIFile('/scx_menu/panel-brackets-small/bracket-ur_bmp.dds'))
        ret.bottomleft = Bitmap(ret, UIFile('/scx_menu/panel-brackets-small/bracket-ll_bmp.dds'))
        ret.bottomright = Bitmap(ret, UIFile('/scx_menu/panel-brackets-small/bracket-lr_bmp.dds'))
        
        ret.topleftglow = Bitmap(ret, UIFile('/scx_menu/panel-brackets-small/bracket-glow-ul_bmp.dds'))
        ret.toprightglow = Bitmap(ret, UIFile('/scx_menu/panel-brackets-small/bracket-glow-ur_bmp.dds'))
        ret.bottomleftglow = Bitmap(ret, UIFile('/scx_menu/panel-brackets-small/bracket-glow-ll_bmp.dds'))
        ret.bottomrightglow = Bitmap(ret, UIFile('/scx_menu/panel-brackets-small/bracket-glow-lr_bmp.dds'))
    else
        ret.topleft = Bitmap(ret, UIFile('/scx_menu/panel-brackets/bracket-ul_bmp.dds'))
        ret.topright = Bitmap(ret, UIFile('/scx_menu/panel-brackets/bracket-ur_bmp.dds'))
        ret.bottomleft = Bitmap(ret, UIFile('/scx_menu/panel-brackets/bracket-ll_bmp.dds'))
        ret.bottomright = Bitmap(ret, UIFile('/scx_menu/panel-brackets/bracket-lr_bmp.dds'))
        
        ret.topleftglow = Bitmap(ret, UIFile('/scx_menu/panel-brackets/bracket-glow-ul_bmp.dds'))
        ret.toprightglow = Bitmap(ret, UIFile('/scx_menu/panel-brackets/bracket-glow-ur_bmp.dds'))
        ret.bottomleftglow = Bitmap(ret, UIFile('/scx_menu/panel-brackets/bracket-glow-ll_bmp.dds'))
        ret.bottomrightglow = Bitmap(ret, UIFile('/scx_menu/panel-brackets/bracket-glow-lr_bmp.dds'))
    end
    
    ret.topleftglow.Depth:Set(function() return ret.topleft.Depth() - 1 end)
    ret.toprightglow.Depth:Set(function() return ret.topright.Depth() - 1 end)
    ret.bottomleftglow.Depth:Set(function() return ret.bottomleft.Depth() - 1 end)
    ret.bottomrightglow.Depth:Set(function() return ret.bottomright.Depth() - 1 end)
    
    LayoutHelpers.AtCenterIn(ret.topleftglow, ret.topleft)
    LayoutHelpers.AtCenterIn(ret.toprightglow, ret.topright)
    LayoutHelpers.AtCenterIn(ret.bottomleftglow, ret.bottomleft)
    LayoutHelpers.AtCenterIn(ret.bottomrightglow, ret.bottomright)
    
    ret.topleft.Left:Set(function() return parent.Left() - leftOffset end)
    ret.topleft.Top:Set(function() return parent.Top() - topOffset end)
    
    ret.topright.Right:Set(function() return parent.Right() + rightOffset end)
    ret.topright.Top:Set(function() return parent.Top() - topOffset end)
    
    ret.bottomleft.Left:Set(function() return parent.Left() - leftOffset end)
    ret.bottomleft.Bottom:Set(function() return parent.Bottom() + bottomOffset end)
    
    ret.bottomright.Right:Set(function() return parent.Right() + rightOffset end)
    ret.bottomright.Bottom:Set(function() return parent.Bottom() + bottomOffset end)
    
    ret:DisableHitTest(true)
    LayoutHelpers.FillParent(ret, parent)
    
    return ret
end