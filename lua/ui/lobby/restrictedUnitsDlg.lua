local UIUtil = import('/lua/ui/uiutil.lua')
local Tooltip = import('/lua/ui/game/tooltip.lua')
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Group = import('/lua/maui/group.lua').Group
local Popup = import('/lua/ui/controls/popups/popup.lua').Popup
local Checkbox = import('/lua/ui/controls/Checkbox.lua').Checkbox

local restrictedUnits = import('/lua/ui/lobby/restrictedUnitsData.lua').restrictedUnits

--- Create a dialog allowing the user to select categories of unit to disable
--
-- @param parent Parent UI control to create the dialog inside.
-- @param initialRestrictions A list of keys from restrictedUnitsData.lua for which the corresponding
--                      toggles in this popup should be initially selected.
-- @param OnOk A function that will be passed the new set of selected keys if the dialog is closed via
--       the "OK" button.
-- @param OnCancel A function to be called if the dialog is cancelled.
-- @param isHost If falsy, the control will be read-only.
function CreateDialog(parent, initialRestrictions, OnOk, OnCancel, isHost)
    -- build a set of what's currently restricted to make it easy for initial setup
    local initialRestrictedSet = {}
    if initialRestrictions then
        for index, restriction in initialRestrictions do
            initialRestrictedSet[restriction] = true
        end
    end

    local dialogContent = Group(parent)
    dialogContent.Width:Set(483)
    dialogContent.Height:Set(426)

    local popup = Popup(parent, dialogContent)

    local function doCancel()
        OnCancel()
        popup:Close()
    end

    popup.OnShadowClicked = doCancel
    popup.OnEscapePressed = doCancel

    local title = UIUtil.CreateText(dialogContent, "<LOC restricted_units_dlg_0000>Unit Manager", 20, UIUtil.titleFont)
    LayoutHelpers.AtTopIn(title, dialogContent, 12)
    LayoutHelpers.AtHorizontalCenterIn(title, dialogContent)

    local okBtn = UIUtil.CreateButtonWithDropshadow(dialogContent, '/BUTTON/medium/', "<LOC _Ok>")
    LayoutHelpers.AtBottomIn(okBtn, dialogContent, 10)
    LayoutHelpers.AtLeftIn(okBtn, dialogContent, -2)

    local resetBtn = UIUtil.CreateButtonWithDropshadow(dialogContent, '/BUTTON/medium/', "<LOC _Reset>")
    LayoutHelpers.AtBottomIn(resetBtn, dialogContent, 10)
    LayoutHelpers.AtHorizontalCenterIn(resetBtn, dialogContent)
    Tooltip.AddButtonTooltip(resetBtn, 'options_reset_all')

    local cancelBtn = UIUtil.CreateButtonWithDropshadow(dialogContent, '/BUTTON/medium/', "<LOC _Cancel>")
    LayoutHelpers.AtBottomIn(cancelBtn, dialogContent, 10)
    LayoutHelpers.AtRightIn(cancelBtn, dialogContent, -2)

    local buttonGroup = Group(dialogContent)
    LayoutHelpers.AtLeftIn(buttonGroup, dialogContent, 13)
    buttonGroup.Top:Set(title.Bottom)
    buttonGroup.Bottom:Set(resetBtn.Top)
    buttonGroup.Width:Set(function() return dialogContent.Width() - 24 end)

    if not isHost then
        cancelBtn.label:SetText(LOC("<LOC _Close>"))
        resetBtn:Hide()
        okBtn:Hide()
    end

    buttonGroup.controlList = {}

    local function CreateListElement(parentControl, restrictionKey)
        local checkbox = Checkbox(parentControl,
            UIUtil.SkinnableFile('/checkbox/unitman/d_up.dds'),
            UIUtil.SkinnableFile('/checkbox/unitman/s_up.dds'),
            UIUtil.SkinnableFile('/checkbox/unitman/d_over.dds'),
            UIUtil.SkinnableFile('/checkbox/unitman/s_over.dds'),
            UIUtil.SkinnableFile('/checkbox/unitman/d_up.dds'), -- Don't care
            UIUtil.SkinnableFile('/checkbox/unitman/d_up.dds'),
            LOC(restrictedUnits[restrictionKey].name), true)
        LayoutHelpers.AtLeftIn(checkbox.label, checkbox, 30)
        -- Evil layout hack:
        checkbox.label.Width:Set(199)
        checkbox.Width:Set(229)

        checkbox.restrictionKey = restrictionKey

        checkbox:SetCheck(initialRestrictedSet[restrictionKey], true)
        if not isHost then
            -- We use this instead of calling Disable() as a slightly elegant way of killing the
            -- mouse-over events, too.
            checkbox.HandleEvent = function() end
        end

        if restrictedUnits[restrictionKey].tooltip then
            Tooltip.AddControlTooltip(checkbox, restrictedUnits[restrictionKey].tooltip)
        end

        return checkbox
    end

    local sortOrder = import('/lua/ui/lobby/restrictedUnitsData.lua').sortOrder

    -- Lay out the toggle controls in two columns.
    local controlIndex = 1
    for index, key in sortOrder do
        if restrictedUnits[key] then
            local rowNumber = math.ceil(controlIndex / 2) - 1
            local control = CreateListElement(buttonGroup, key)
            if math.mod(controlIndex, 2) ~= 0 then
                LayoutHelpers.AtLeftIn(control, buttonGroup)
            else
                control.Left:Set(buttonGroup.controlList[controlIndex - 1].Right)
            end
            LayoutHelpers.AtTopIn(control, buttonGroup, rowNumber * control.Height())

            buttonGroup.controlList[controlIndex] = control
            controlIndex = controlIndex + 1
        end
    end

    cancelBtn.OnClick = doCancel

    okBtn.OnClick = function()
        local newRestrictions = {}

        -- Read out the checkbox state into a new list of restriction keys to pass to OnOk.
        for index, control in buttonGroup.controlList do
            if control:IsChecked() then
                table.insert(newRestrictions, control.restrictionKey)
            end
        end

        OnOk(newRestrictions)
        popup:Close()
    end

    resetBtn.OnClick = function()
        for index, control in buttonGroup.controlList do
            control:SetCheck(false, true)
        end
    end
end
