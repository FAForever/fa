
local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")

local locations = {
    lefttop = {'AtLeftIn', 'AtTopIn'},
    leftcenter = {'AtLeftIn', 'AtVerticalCenterIn'},
    leftbottom = {'AtLeftIn', 'AtBottomIn'},
    righttop = {'AtRightIn', 'AtTopIn'},
    rightcenter = {'AtRightIn', 'AtVerticalCenterIn'},
    rightbottom = {'AtRightIn', 'AtBottomIn'},
    centertop = {'AtHorizontalCenterIn', 'AtTopIn'},
    center = {'AtHorizontalCenterIn', 'AtVerticalCenterIn'},
    centerbottom = {'AtHorizontalCenterIn', 'AtBottomIn'},
}

local controls = {}
local worldView = import("/lua/ui/game/borders.lua").GetMapGroup()

function PrintToScreen(textData)
    if not locations[textData.location] then
        WARN('Trying to print text \"'..textData.text..'\" to an invalid location!')
        return false
    else
        local control = false
        local newControl = false
        if not controls[textData.location] then 
            controls[textData.location] = {}
            newControl = true
        else    
            for index, textControl in controls[textData.location] do
                if not textControl.active then
                    control = textControl
                    break
                end
            end
        end
        if not control then
            control = UIUtil.CreateText(worldView, '', 12, UIUtil.bodyFont)
            control:DisableHitTest()
            control.Depth:Set(GetFrame(0):GetTopmostDepth() + 1)
            table.insert(controls[textData.location], control)
            if newControl then
                LayoutHelpers[locations[textData.location][1]](control, worldView)
                LayoutHelpers[locations[textData.location][2]](control, worldView)
            else
                LayoutHelpers.Below(control, controls[textData.location][table.getn(controls[textData.location])-1])
            end
        end
        control:SetText(textData.text)
        local color = 'ffffffff'
        if textData.color and type(textData.color) == 'string' and string.len(textData.color) == 8 then
            color = textData.color
        end
        control:SetColor(color)
        control:SetFont(UIUtil.bodyFont, textData.size)
        control.active = true
        control:Show()
        control:SetAlpha(1)
        if textData.duration then
            control.time = 0
            control:SetNeedsFrameUpdate(true)
            control.OnFrame = function(self, time)
                self.time = time + self.time
                if self.time > textData.duration then
                    local newAlpha = self:GetAlpha() - time
                    if newAlpha < 0 then
                        self:Hide()
                        self.active = false
                        self:SetNeedsFrameUpdate(false)
                    else
                        self:SetAlpha(newAlpha)
                    end
                end
            end
        end
    end
end