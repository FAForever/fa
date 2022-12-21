local Math_Random = math.random
local Math_Cos = math.cos
local Math_Sin = math.sin
local Math_Floor = math.floor

local Group = import("/lua/maui/group.lua").Group
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Prefs = import("/lua/user/prefs.lua")


local snowFlakesGroup
local snowFlakePath = "/textures/ui/events/snow/snowflake.dds"
local snowFlakeWidth = 10
local snowFlakeHeight = 10
local snowFlakeCount

function CreateSnowFlake(parent, speed, scale, xPos, yPos)
    local snowFlake = Bitmap(parent, snowFlakePath)
    snowFlake.parent = parent
    -- local snowFlake = Bitmap(self.ClientGroup)
    -- snowFlake:SetSolidColor('ffffffff')
    LayoutHelpers.AtLeftTopIn(snowFlake, snowFlake.parent, xPos, yPos)
    LayoutHelpers.SetDimensions(snowFlake, snowFlakeWidth * scale, snowFlakeHeight * scale)
    snowFlake:SetAlpha(math.random())
    snowFlake.speed = speed
    snowFlake.xPos = xPos
    snowFlake.yPos = yPos
    snowFlake.scale = scale

    snowFlake.counter = math.random() * 10
    snowFlake.sign = math.random() < 0.5 and 1 or -1
    snowFlake:DisableHitTest()
    snowFlake:SetNeedsFrameUpdate(true)
    snowFlake.OnFrame = function(control, delta)
        control.counter = control.counter + control.speed / 5000;
        local counterCos = Math_Cos(control.counter)
        local counterSin = Math_Sin(control.counter)
        control.xPos = control.xPos + control.sign * control.speed * counterCos / 200;
        control.yPos = control.yPos + counterSin / 100 + control.speed / 100;
        control.scale = control.scale + counterCos / 100;

        LayoutHelpers.AtLeftTopIn(control, control.parent, Math_Floor(control.xPos), Math_Floor(control.yPos))
        if control.sign > 0 then
            LayoutHelpers.SetDimensions(snowFlake, snowFlakeWidth * control.scale,
                snowFlakeHeight * control.scale * counterCos)
        else
            LayoutHelpers.SetDimensions(snowFlake, snowFlakeWidth * control.scale * counterSin,
                snowFlakeHeight * control.scale)
        end

        control:Show()

        if (control.Left() < control.parent.Left() or control.Right() > control.parent.Right()) then
            control:Hide()
        end
        if (control.yPos > control.parent.Height()) then
            control.yPos = -10
            control.xPos = Math_Random(control.parent.Width())
        end
    end
end

function CreateSnowFlakes(parent, count)
    if IsDestroyed(snowFlakesGroup) then
        snowFlakesGroup = Group(parent)
        LayoutHelpers.FillParent(snowFlakesGroup, parent)
        snowFlakesGroup:DisableHitTest()
    end
    snowFlakeCount = count or Prefs.GetFromCurrentProfile('SnowFlakesCount') or 100
    for i = 1, snowFlakeCount do
        CreateSnowFlake(snowFlakesGroup, 100, math.random() * 2, math.random(snowFlakesGroup.Width()),
            math.random(snowFlakesGroup.Height()))
    end
end

function Clear()
    if not IsDestroyed(snowFlakesGroup) then
        snowFlakesGroup:ClearChildren()
    end
end
