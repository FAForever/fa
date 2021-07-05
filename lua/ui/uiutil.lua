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
local Checkbox = import('/lua/ui/controls/Checkbox.lua').Checkbox
local RadioButtons = import('/lua/maui/radiobuttons.lua').RadioButtons
local Scrollbar = import('/lua/maui/scrollbar.lua').Scrollbar
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local Cursor = import('/lua/maui/cursor.lua').Cursor
local Prefs = import('/lua/user/prefs.lua')
local Border = import('/lua/ui/controls/border.lua').Border
local ItemList = import('/lua/maui/itemlist.lua').ItemList
local Layouts = import('/lua/skins/layouts.lua')
local Popup = import('/lua/ui/controls/popups/popup.lua').Popup
local NinePatch = import('/lua/ui/controls/ninepatch.lua').NinePatch
local InputDialog = import('/lua/ui/controls/popups/inputdialog.lua').InputDialog
local skins = import('/lua/skins/skins.lua').skins

--* Handy global variables to assist skinning
buttonFont = import('/lua/lazyvar.lua').Create()            -- default font used for button faces
factionFont = import('/lua/lazyvar.lua').Create()      -- default font used for dialog button faces
dialogButtonFont = import('/lua/lazyvar.lua').Create()      -- default font used for dialog button faces
bodyFont = import('/lua/lazyvar.lua').Create()              -- font used for all other text
fixedFont = import('/lua/lazyvar.lua').Create()             -- font used for fixed width characters
titleFont = import('/lua/lazyvar.lua').Create()             -- font used for titles and labels
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
factionTextColor = import('/lua/lazyvar.lua').Create()      -- faction color for text foreground
factionBackColor = import('/lua/lazyvar.lua').Create()      -- faction color for text background

-- table of layouts supported by this skin, not a lazy var as we don't need updates
layouts = nil

--* other handy variables!
consoleDepth = false  -- in order to get the console to always be on top, assign this number and never go over

networkBool = import('/lua/lazyvar.lua').Create()    -- boolean whether the game is local or networked

-- Default scenario for skirmishes / MP Lobby
defaultScenario = '/maps/scmp_039/scmp_039_scenario.lua'
requiredType = 'skirmish'

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

local UIFileCache = {}
-- The files below are missing from the game and are used to leave UIFile early
local UIFileBlacklist = {
    ['/icons/units/opc1001_icon.dds'] = true,
    ['/icons/units/opc1002_icon.dds'] = true,
    ['/icons/units/opc2001_icon.dds'] = true,
    ['/icons/units/opc5007_icon.dds'] = true,
    ['/icons/units/opc5008_icon.dds'] = true,
    ['/icons/units/ope2001_icon.dds'] = true,
    ['/icons/units/ope2002_icon.dds'] = true,
    ['/icons/units/ope6002_icon.dds'] = true,
    ['/icons/units/ope6004_icon.dds'] = true,
    ['/icons/units/ope6005_icon.dds'] = true,
    ['/icons/units/ope6006_icon.dds'] = true,
    ['/icons/units/uab5204_icon.dds'] = true,
    ['/icons/units/uac1902_icon.dds'] = true,
    ['/icons/units/xsc9011_icon.dds'] = true,
    ['/icons/units/xsc9010_icon.dds'] = true,
    ['/icons/units/xsc8020_icon.dds'] = true,
    ['/icons/units/xsc8019_icon.dds'] = true,
    ['/icons/units/xsc8018_icon.dds'] = true,
    ['/icons/units/xsc8017_icon.dds'] = true,
    ['/icons/units/xsc8016_icon.dds'] = true,
    ['/icons/units/xsc8015_icon.dds'] = true,
    ['/icons/units/xsc8014_icon.dds'] = true,
    ['/icons/units/xsc8013_icon.dds'] = true,
    ['/icons/units/xsc1601_icon.dds'] = true,
    ['/icons/units/xsc1701_icon.dds'] = true,
    ['/icons/units/xro4001_icon.dds'] = true,
    ['/icons/units/xrc2401_icon.dds'] = true,
    ['/icons/units/xrc2301_icon.dds'] = true,
    ['/icons/units/xrc2101_icon.dds'] = true,
    ['/icons/units/xec9011_icon.dds'] = true,
    ['/icons/units/xec9010_icon.dds'] = true,
    ['/icons/units/xec9009_icon.dds'] = true,
    ['/icons/units/xec9008_icon.dds'] = true,
    ['/icons/units/xec9007_icon.dds'] = true,
    ['/icons/units/xec9006_icon.dds'] = true,
    ['/icons/units/xec9005_icon.dds'] = true,
    ['/icons/units/xec9002_icon.dds'] = true,
    ['/icons/units/xec9001_icon.dds'] = true,
    ['/icons/units/xec9003_icon.dds'] = true,
    ['/icons/units/xec1909_icon.dds'] = true,
    ['/icons/units/xec1908_icon.dds'] = true,
    ['/icons/units/xec9004_icon.dds'] = true,
    ['/icons/units/xac8103_icon.dds'] = true,
    ['/icons/units/xac8102_icon.dds'] = true,
    ['/icons/units/xac8101_icon.dds'] = true,
    ['/icons/units/xac8003_icon.dds'] = true,
    ['/icons/units/xac8002_icon.dds'] = true,
    ['/icons/units/xac2301_icon.dds'] = true,
    ['/icons/units/xac8001_icon.dds'] = true,
    ['/icons/units/uxl0021_icon.dds'] = true,
    ['/icons/units/urb5206_icon.dds'] = true,
    ['/icons/units/urb5204_icon.dds'] = true,
    ['/icons/units/urb3103_icon.dds'] = true,
    ['/icons/units/hel0001_icon.dds'] = true,
    ['/icons/units/ueb5204_icon.dds'] = true,
    ['/icons/units/ueb5208_icon.dds'] = true
}

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
    if sessionClientsTable ~= nil then
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
                local mapWidth = size[1]
                local mapHeight = size[2]

                -- The meshes used here are, due to limitations of native code, only capable of
                -- scaling preserving aspect ratio.
                -- GPG forgot to include one for tall-thin maps, but here we make optimal use of the
                -- two they did give us :/
                if mapWidth == mapHeight * 2 then
                    -- Wide maps
                    MapBorderAdd(skins[skin].imagerMeshHorz)
                    if skins[skin].imagerMeshDetailsHorz then
                        MapBorderAdd(skins[skin].imagerMeshDetailsHorz)
                    end
                elseif mapWidth == mapHeight then
                    -- Squares
                    MapBorderAdd(skins[skin].imagerMesh)
                    if skins[skin].imagerMeshDetails then
                        MapBorderAdd(skins[skin].imagerMeshDetails)
                    end
                elseif mapHeight == mapWidth * 2 then
                   -- TODO: Someone please make a mesh for this case.
                end
            end
        else
            MapBorderClear()
        end
    end

end

--* skin control, sets the current skin table
function SetCurrentSkin(skin, overrideTable)
    local skinTable = skins[skin]
    if not skinTable then
        skin = 'uef'
        skinTable = skins[skin]
    end

    currentSkin:Set(skin)

    tooltipTitleColor:Set(skinTable.tooltipTitleColor)
    tooltipBorderColor:Set(skinTable.tooltipBorderColor)
    buttonFont:Set(skinTable.buttonFont)
    factionFont:Set(skinTable.factionFont)
    dialogButtonFont:Set(skinTable.dialogButtonFont)
    bodyFont:Set(skinTable.bodyFont)
    fixedFont:Set(skinTable.fixedFont)
    titleFont:Set(skinTable.titleFont)
    bodyColor:Set(skinTable.bodyColor)
    factionTextColor:Set(skinTable.factionTextColor)
    factionBackColor:Set(skinTable.factionBackColor)
    if (overrideTable.faction_font_color == nil and Prefs.GetOption('faction_font_color')) or overrideTable.faction_font_color then
        fontColor:Set(skinTable.fontColor)
    else
        fontColor:Set(skins["default"].fontColor)
    end
    fontOverColor:Set(skinTable.fontOverColor)
    fontDownColor:Set(skinTable.fontDownColor)
    dialogCaptionColor:Set(skinTable.dialogCaptionColor)
    dialogColumnColor:Set(skinTable.dialogColumnColor)
    dialogButtonColor:Set(skinTable.dialogButtonColor)
    highlightColor:Set(skinTable.highlightColor)
    disabledColor:Set(skinTable.disabledColor)
    panelColor:Set(skinTable.panelColor)
    transparentPanelColor:Set(skinTable.transparentPanelColor)
    consoleBGColor:Set(skinTable.consoleBGColor)
    consoleFGColor:Set(skinTable.consoleFGColor)
    consoleTextBGColor:Set(skinTable.consoleTextBGColor)
    menuFontSize:Set(skinTable.menuFontSize)
    layouts = skinTable.layouts

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

function UpdateCurrentSkin(overrideTable)
    SetCurrentSkin(currentSkin(), overrideTable)
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

    -- Find the next skin from our current skin, skipping default/randomfaction: they're not really
    -- skins note that if the skin table is updated while running, the order of the table might change
    -- so your cycle may be different. No big deal, just be aware it's a side effect.
    local numSkins = table.getn(skinNames)
    for index, skinName in skinNames do
        if skinName == currentSkin() then
            local nextSkinIndex = index + dir
            if nextSkinIndex > numSkins then nextSkinIndex = 1 end
            if nextSkinIndex < 1 then nextSkinIndex = numSkins end
            if skinNames[nextSkinIndex] == 'default' or skinNames[nextSkinIndex] == 'random'  then   -- skip default entry as it's not really a skin
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

    -- disable when in Screen Capture mode
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
function UIFile(filespec, checkMods)
    if UIFileBlacklist[filespec] then return filespec end
    local skins = import('/lua/skins/skins.lua').skins
    local useSkin = currentSkin()
    local currentPath = skins[useSkin].texturesPath
    local origPath = currentPath

    if useSkin == nil or currentPath == nil then
        return nil
    end

    if not UIFileCache[currentPath .. filespec] then
        local found = false

        if useSkin == 'default' then
            found = currentPath .. filespec
        else
            while not found and useSkin do
                found = currentPath .. filespec
                if not DiskGetFileInfo(found) then
                    -- Check mods
                    local inmod = false
                    if checkMods then
                        if __active_mods then
                            for id, mod in __active_mods do
                                -- Unit Icons
                                if DiskGetFileInfo(mod.location .. filespec) then
                                    found = mod.location .. filespec
                                    inmod = true
                                    break
                                -- ACU Enhancements
                                elseif DiskGetFileInfo(mod.location .. currentPath .. filespec) then
                                    found = mod.location .. currentPath .. filespec
                                    inmod = true
                                    break
                                end
                            end
                        end
                    end

                    if not inmod then
                        found = false
                        useSkin = skins[useSkin].default
                        if useSkin then
                            currentPath = skins[useSkin].texturesPath
                        end
                    end
                end
            end
        end

        if not found then
            -- don't print error message if "filespec" is a valid path
            if not DiskGetFileInfo(filespec) then
                SPEW('[uiutil.lua, function UIFile()] - Unable to find file:'.. origPath .. filespec)
            end
            found = filespec
        end

        UIFileCache[origPath .. filespec] = found
    end
    return UIFileCache[origPath .. filespec]
end

--* return the filename as a lazy var function to allow triggering of OnDirty
function SkinnableFile(filespec, checkMods)
    return function()
        return UIFile(filespec, checkMods)
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
function CreateText(parent, label, pointSize, font, dropshadow)
    label = LOC(label) or LOC("<LOC uiutil_0000>[no text]")
    font = font or buttonFont
    local text = Text(parent, "Text: " .. label)
    text:SetFont(font, pointSize)
    text:SetColor(fontColor)
    text:SetText(label)

    if dropshadow then
        text:SetDropShadow(true)
    end
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
function CreateButton(parent, up, down, over, disabled, label, pointSize, textOffsetVert, textOffsetHorz, clickCue, rolloverCue, dropshadow)
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
    button:UseAlphaHitTest(false)

    if label and pointSize then
        button.label = CreateText(button, label, pointSize, buttonFont, dropshadow)
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

function CreateButtonWithDropshadow(parent, filename, label, textOffsetVert, textOffsetHorz, clickCue, rolloverCue)
    return CreateButton(parent
        , filename .. "_btn_up.dds"
        , filename .. "_btn_down.dds"
        , filename .. "_btn_over.dds"
        , filename .. "_btn_dis.dds"
        , label
        , 11
        , textOffsetVert
        , textOffsetHorz
        , clickCue
        , rolloverCue
        , true
        )
end

-- Create a ninepatch using a texture path and naming convention, instead of explicitly with 9 images.
function CreateNinePatchStd(parent, texturePath)
    return NinePatch(parent,
        SkinnableFile(texturePath .. 'center.dds'),
        SkinnableFile(texturePath .. 'topLeft.dds'),
        SkinnableFile(texturePath .. 'topRight.dds'),
        SkinnableFile(texturePath .. 'bottomLeft.dds'),
        SkinnableFile(texturePath .. 'bottomRight.dds'),
        SkinnableFile(texturePath .. 'left.dds'),
        SkinnableFile(texturePath .. 'right.dds'),
        SkinnableFile(texturePath .. 'top.dds'),
        SkinnableFile(texturePath .. 'bottom.dds')
)
end

function SurroundWithNinePatch(parent, texturePath, fudgeX, fudgeY)
    local patch = CreateNinePatchStd(parent, texturePath)

    patch:Surround(parent, fudgeX or 62, fudgeY or 62)
    LayoutHelpers.DepthUnderParent(patch, parent, 2)
end

--- Surround the given control with an eight-patch dynamically-scaling Border constructed using
 -- standard names from the given texture path.
 -- The expected names of texture components are:
 -- topLeft.dds, topRight.dds, bottomLeft.dds, bottomRight.dds, left.dds, right.dds, top.dds.
 -- @see Border for an explanation of how the textures are arranged.
 --
 -- @param control The control to surround with the border images.
 -- @param texturePath The path relative to the skinning root where the textue files are located.
 -- @param fudgeX The amount of overlap in the X direction the border textures shall have with the
 --               control. The default fudgefactors are suitable for use with the widely-used
 --               "laser box" borders.
 -- @param fudgeY As fudgeX, but in the Y direction.
 --
function SurroundWithBorder(control, texturePath, fudgeX, fudgeY)
    local border = Border(control,
        SkinnableFile(texturePath .. 'topLeft.dds'),
        SkinnableFile(texturePath .. 'topRight.dds'),
        SkinnableFile(texturePath .. 'bottomLeft.dds'),
        SkinnableFile(texturePath .. 'bottomRight.dds'),
        SkinnableFile(texturePath .. 'left.dds'),
        SkinnableFile(texturePath .. 'right.dds'),
        SkinnableFile(texturePath .. 'top.dds'),
        SkinnableFile(texturePath .. 'bottom.dds')
)

    border:Surround(control, fudgeX or 62, fudgeY or 62)
    LayoutHelpers.DepthOverParent(border, control, 2)
end

-- Create a checkbox using the default checkbox texture. Kept as its own entry point for the benefit
-- of retarded GPG code that things "radiobtn" is a sensible name for a checkbox texture.
function CreateCheckboxStd(parent, texturePath)
    local checkbox = Checkbox(parent,
        SkinnableFile(texturePath .. '-d_btn_up.dds'),
        SkinnableFile(texturePath .. '-s_btn_up.dds'),
        SkinnableFile(texturePath .. '-d_btn_over.dds'),
        SkinnableFile(texturePath .. '-s_btn_over.dds'),
        SkinnableFile(texturePath .. '-d_btn_dis.dds'),
        SkinnableFile(texturePath .. '-s_btn_dis.dds')
)
    return checkbox
end

function CreateCheckbox(parent, texturePath, label, labelRight, labelSize, clickCue, rollCue)
    local checkbox = Checkbox(parent,
        SkinnableFile(texturePath .. 'd_up.dds'),
        SkinnableFile(texturePath .. 's_up.dds'),
        SkinnableFile(texturePath .. 'd_over.dds'),
        SkinnableFile(texturePath .. 's_over.dds'),
        SkinnableFile(texturePath .. 'd_dis.dds'),
        SkinnableFile(texturePath .. 's_dis.dds'),
        label, labelRight, labelSize, clickCue, rollCue)
    return checkbox
end

function CreateRadioButtonsStd(parent, texturePath, title, buttons, default)
    local radioButton = RadioButtons(parent, title, buttons, default, "Arial", 14, fontColor,
        SkinnableFile(texturePath .. 'd_up.dds'),
        SkinnableFile(texturePath .. 's_up.dds'),
        SkinnableFile(texturePath .. 'd_over.dds'),
        SkinnableFile(texturePath .. 's_over.dds'),
        SkinnableFile(texturePath .. 'd_dis.dds'),
        SkinnableFile(texturePath .. 's_dis.dds'),
        "")
    return radioButton
end

 function CreateDialogButtonStd(parent, filename, label, pointSize, textOffsetVert, textOffsetHorz, clickCue, rolloverCue)
    local button = CreateButtonStd(parent,filename,label,pointSize,textOffsetVert,textOffsetHorz, clickCue, rolloverCue)
    button.label:SetFont(dialogButtonFont, pointSize)
    button.label:SetColor(dialogButtonColor)
    return button
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
    scrollbar:SetTextures(   SkinnableFile(scrollbg)
                            ,SkinnableFile(scrollbarmid)
                            ,SkinnableFile(scrollbartop)
                            ,SkinnableFile(scrollbarbot))

    local scrollUpButton = Button(    scrollbar
                                    , SkinnableFile(textureName..'arrow-up_scr_up.dds')
                                    , SkinnableFile(textureName..'arrow-up_scr_down.dds')
                                    , SkinnableFile(textureName..'arrow-up_scr_over.dds')
                                    , SkinnableFile(textureName..'arrow-up_scr_dis.dds')
                                    , "UI_Arrow_Click")

    local scrollDownButton = Button(  scrollbar
                                    , SkinnableFile(textureName..'arrow-down_scr_up.dds')
                                    , SkinnableFile(textureName..'arrow-down_scr_down.dds')
                                    , SkinnableFile(textureName..'arrow-down_scr_over.dds')
                                    , SkinnableFile(textureName..'arrow-down_scr_dis.dds')
                                    , "UI_Arrow_Click")

    LayoutHelpers.AnchorToRight(scrollbar, attachto, offset_right)
    scrollbar.Top:Set(scrollUpButton.Bottom)
    scrollbar.Bottom:Set(scrollDownButton.Top)

    scrollUpButton.Left:Set(scrollbar.Left)
    LayoutHelpers.AtTopIn(scrollUpButton, attachto, offset_top)

    scrollDownButton.Left:Set(scrollbar.Left)
    LayoutHelpers.AtBottomIn(scrollDownButton, attachto, offset_bottom)

    scrollbar.Right:Set(scrollUpButton.Right)

    scrollbar:AddButtons(scrollUpButton, scrollDownButton)
    scrollbar:SetScrollable(attachto)

    return scrollbar
end

function CreateLobbyVertScrollbar(attachto, offset_right, offset_bottom, offset_top)
    return CreateVertScrollbarFor(attachto, offset_right, "/SCROLLBAR_VERT/", offset_bottom, offset_top)
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

    local textLine = {}
    textLine[1] = CreateText(dialog, "", 18, titleFont)
    LayoutHelpers.AtTopIn(textLine[1], dialog, 15)
    LayoutHelpers.AtHorizontalCenterIn(textLine[1], dialog)

    LayoutHelpers.SetWidth(dialog, 428)
    local textBoxWidth = (dialog.Width() - LayoutHelpers.ScaleNumber(80))
    local tempTable = import('/lua/maui/text.lua').WrapText(LOC(dialogText), textBoxWidth,
    function(text)
        return textLine[1]:GetStringAdvance(text)
    end)

    local tempLines = table.getn(tempTable)

    local textHeight = 0
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

        textHeight = textHeight + textLine[i]:Height()
    end

    dialog.Height:Set(textHeight + LayoutHelpers.ScaleNumber(85))

    local popup = Popup(parent, dialog)
    -- Don't close when the shadow is clicked.
    popup.OnShadowClicked = function() end
    popup.OnEscapePressed = function() end

    local function MakeButton(text, callback)
        local button = CreateButtonWithDropshadow(dialog, '/BUTTON/medium/', text)
        if callback then
            button.OnClick = function(self)
                callback()
                if destroyOnCallback then
                    popup:Close()
                end
            end
        else
            button.OnClick = function(self)
                popup:Close()
            end
        end
        return button
    end

    dialog._button1 = false
    dialog._button2 = false
    dialog._button3 = false

    local numButtons = 0
    if button1Text then
        numButtons = numButtons + 1
        dialog._button1 = MakeButton(button1Text, button1Callback)
        LayoutHelpers.AtBottomIn(dialog._button1, dialog, 10)
    end
    if button2Text then
        numButtons = numButtons + 1
        dialog._button2 = MakeButton(button2Text, button2Callback)
        LayoutHelpers.AtBottomIn(dialog._button2, dialog, 10)
    end
    if button3Text then
        numButtons = numButtons + 1
        dialog._button3 = MakeButton(button3Text, button3Callback)
        LayoutHelpers.AtBottomIn(dialog._button3, dialog, 10)
    end

    if numButtons > 1 then
        -- A button to either size...
        dialog._button1.Left:Set(function()
            return dialog.Left() + (((dialog.Width() / 2) - dialog._button1.Width()) / 2) - 44
        end)

        -- Handle stupid weird GPG convention...
        local rightButton
        if numButtons == 3 then
            rightButton = dialog._button3

            -- The third (second) button goes in the middle.
            LayoutHelpers.AtHorizontalCenterIn(dialog._button2, dialog)
        else
            rightButton = dialog._button2
        end

        rightButton.Left:Set(function()
            local halfWidth = dialog.Width() / 2
            return dialog.Left() + halfWidth + ((halfWidth - dialog._button2.Width()) / 2) + 44
        end)
    elseif numButtons == 1 then
        LayoutHelpers.AtHorizontalCenterIn(dialog._button1, dialog)
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

    return popup
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
                    if x and h ~= self.ID then
                        x:Destroy()
                    end
                end
            end
            worldCovers[index].OnHide = function(self, hidden)
                for h, x in worldCovers do
                    if x and h ~= self.ID then
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

function GetFactionIcon(factionIndex)
    return import('/lua/factions.lua').Factions[factionIndex + 1].Icon
end

function CreateDialogBrackets(parent, leftOffset, topOffset, rightOffset, bottomOffset, altTextures)
    local ret = Group(parent)

    local texturePath
    if altTextures then
        texturePath = "/scx_menu/panel-brackets-small"
    else
        texturePath = "/scx_menu/panel-brackets"
    end

    ret.topleft = Bitmap(ret, UIFile(texturePath .. '/bracket-ul_bmp.dds'))
    ret.topright = Bitmap(ret, UIFile(texturePath .. '/bracket-ur_bmp.dds'))
    ret.bottomleft = Bitmap(ret, UIFile(texturePath .. '/bracket-ll_bmp.dds'))
    ret.bottomright = Bitmap(ret, UIFile(texturePath .. '/bracket-lr_bmp.dds'))

    ret.topleftglow = Bitmap(ret, UIFile(texturePath .. '/bracket-glow-ul_bmp.dds'))
    ret.toprightglow = Bitmap(ret, UIFile(texturePath .. '/bracket-glow-ur_bmp.dds'))
    ret.bottomleftglow = Bitmap(ret, UIFile(texturePath .. '/bracket-glow-ll_bmp.dds'))
    ret.bottomrightglow = Bitmap(ret, UIFile(texturePath .. '/bracket-glow-lr_bmp.dds'))

    ret.topleftglow.Depth:Set(function() return ret.topleft.Depth() - 1 end)
    ret.toprightglow.Depth:Set(function() return ret.topright.Depth() - 1 end)
    ret.bottomleftglow.Depth:Set(function() return ret.bottomleft.Depth() - 1 end)
    ret.bottomrightglow.Depth:Set(function() return ret.bottomright.Depth() - 1 end)

    LayoutHelpers.AtCenterIn(ret.topleftglow, ret.topleft)
    LayoutHelpers.AtCenterIn(ret.toprightglow, ret.topright)
    LayoutHelpers.AtCenterIn(ret.bottomleftglow, ret.bottomleft)
    LayoutHelpers.AtCenterIn(ret.bottomrightglow, ret.bottomright)

    LayoutHelpers.AtLeftTopIn(ret.topleft, parent, -leftOffset, -topOffset)
    LayoutHelpers.AtRightTopIn(ret.topright, parent, -rightOffset, -topOffset)
    LayoutHelpers.AtLeftBottomIn(ret.bottomleft, parent, -leftOffset, -bottomOffset)
    LayoutHelpers.AtRightBottomIn(ret.bottomright, parent, -rightOffset, -bottomOffset)

    ret:DisableHitTest(true)
    LayoutHelpers.FillParent(ret, parent)

    return ret
end

-- Enable or disable a control based on a boolean.
function setEnabled(control, enabled)
    if (enabled) then
        control:Enable()
    else
        control:Disable()
    end
end

-- Show or hide a control based on a boolean.
function setVisible(control, visible)
    if (visible) then
        control:Show()
    else
        control:Hide()
    end
end

function GetReplayId()
    local id = nil

    if HasCommandLineArg("/syncreplay") and HasCommandLineArg("/gpgnet") and GetFrontEndData('syncreplayid') ~= nil and GetFrontEndData('syncreplayid') ~= 0 then
        id = GetFrontEndData('syncreplayid')
    elseif HasCommandLineArg("/savereplay") then
        -- /savereplay format is gpgnet://local_ip:port/replay_id/USERNAME.SCFAreplay
        -- see https://github.com/FAForever/downlords-faf-client/blob/b819997b2c4964ae6e6801d5d2eecd232bca5688/src/main/java/com/faforever/client/fa/LaunchCommandBuilder.java#L192
        local url = GetCommandLineArg("/savereplay", 1)[1]
        local fistpos = string.find(url, "/", 10) + 1
        local lastpos = string.find(url, "/", fistpos) - 1
        id = string.sub(url, fistpos, lastpos)
    elseif HasCommandLineArg("/replayid") then
        id =  GetCommandLineArg("/replayid", 1)[1]
    end

    return id
end

-- Create an input dialog with the given title and listener function.
function CreateInputDialog(parent, title, listener, fallbackBox, str)
    local dialog = InputDialog(parent, title, fallbackBox, str)
    dialog.OnInput = listener

    return dialog
end

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