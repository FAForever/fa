
local _buttonTextures = { }
_buttonTextures["up"] = '/textures/ui/common/game/orders/guard_btn_dis.dds'
_buttonTextures["down"] = '/textures/ui/common/game/orders/guard_btn_down.dds'
_buttonTextures["over"] = '/textures/ui/common/game/orders/guard_btn_over.dds'
_buttonTextures["disabled"] = '/textures/ui/common/game/orders/basic-empty_btn_slot.dds'

function mWindow:Button(identifier)

    local element = self.tracker[identifier]
    if not element then 

        -- create a standard group
        element = Group(self.main)
        element:DisableHitTest()

        -- prevents errors with regard to the size of the group
        LayoutHelpers.SetWidth(element, 10)
        LayoutHelpers.SetHeight(element, 10)

        -- button parameters
        local normal = _buttonTextures["up"]
        local active = _buttonTextures["down"]
        local highlight = _buttonTextures["over"]
        local disabled = _buttonTextures["disabled"]
        local clickCue = "UI_Opt_Yes_No"
        local rolloverCue = "UI_Opt_Affirm_Over"

        -- create the button
        element.button = Button(element, normal, active, highlight, disabled, clickCue, rolloverCue)
        LayoutHelpers.AtLeftTopIn(element.button, element, 0, 0)
        element.button.Width:Set(32)
        element.button.Height:Set(32)
        element.button.Depth:Set(2000)

        -- create the label
        local label = ToLabel(identifier) 
        element.label = UIUtil.CreateText(element, label, 12, UIUtil.bodyFont)
        element.label:SetColor(self.textColor)
        element.label:SetText(label)
        LayoutHelpers.CenteredRightOf(element.label, element.button, 6)

        -- state management
        element.height = 36
        element.enabled = false 
        element.button.OnClick = function(self, modifiers)
            element.enabled = true
        end

        -- keep track of it
        self.tracker[identifier] = element
    end

    -- position it
    LayoutHelpers.AtLeftTopIn(element, self.main, self.outline, self.offset)

    -- update internal state
    self:UpdateOffset(element.height)
    
    element.used = true
    if element:IsHidden() then 
        element:Show()
    end

    -- pass on the button state
    local enabled = element.enabled
    element.enabled = false

    return enabled
end
