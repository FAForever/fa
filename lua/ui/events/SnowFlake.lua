local Math_Random = math.random
local Math_Cos = math.cos
local Math_Sin = math.sin
local Math_Floor = math.floor

local Group = import("/lua/maui/group.lua").Group
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Prefs = import("/lua/user/prefs.lua")
local Lazyvar = import("/lua/lazyvar.lua").Create


local snowFlakesGroup
local snowFlakePath = "/textures/ui/events/snow/snowflake.dds"
local snowFlakeWidth = 10
local snowFlakeHeight = 10
local snowFlakeCount

local SnowFlake = ClassUI(Bitmap)
{
    __init = function(self, parent, speed, scale, xPos, yPos)
        Bitmap.__init(self, parent, snowFlakePath)
        self.parent = parent

        self.XScale = Lazyvar(scale)
        self.YScale = Lazyvar(scale)
        self.PosX = Lazyvar(xPos)
        self.PosY = Lazyvar(yPos)

        self:SetAlpha(Math_Random())

        self.Left:Set(function() return parent.Left() + Math_Floor(self.PosX()) end)
        self.Top:Set(function() return parent.Top() + Math_Floor(self.PosY()) end)
        self.Rotation = Lazyvar()
        self.sign = Math_Random() < 0.5 and 1 or -1

        if self.sign > 0 then
            self.Width:Set(function() return snowFlakeWidth * self.XScale() * self.Rotation() end)
            self.Height:Set(function() return snowFlakeHeight * self.YScale() end)
        else
            self.Width:Set(function() return snowFlakeWidth * self.XScale() end)
            self.Height:Set(function() return snowFlakeHeight * self.YScale() * self.Rotation() end)
        end


        self.speed = speed
        self.counter = Math_Random() * 10
        self:DisableHitTest()
        self:SetNeedsFrameUpdate(true)
    end,

    OnFrame = function(control, delta)
        control.counter = control.counter + delta
        local counterCos = Math_Cos(control.counter)
        local counterSin = Math_Sin(control.counter)

        control.PosX:Set(control.PosX() + control.sign * control.speed * counterCos / 200)
        control.PosY:Set(control.PosY() + counterSin / 100 + control.speed / 100)
        control.XScale:Set(control.XScale() + counterCos / 100)
        control.YScale:Set(control.YScale() + counterCos / 100)

        if control.sign > 0 then
            control.Rotation:Set(counterCos)
        else
            control.Rotation:Set(counterSin)
        end

        control:Show()

        if (control.Left() < control.parent.Left() or control.Right() > control.parent.Right()) then
            control:Hide()
        end
        if (control.PosY() > control.parent.Height()) then
            control.PosY:Set(-10)
            control.PosX:Set(Math_Random(control.parent.Width()))
        end
    end

}


function CreateSnowFlakes(parent, count)
    if IsDestroyed(snowFlakesGroup) then
        snowFlakesGroup = Group(parent)
        LayoutHelpers.FillParent(snowFlakesGroup, parent)
        snowFlakesGroup:DisableHitTest()
    end
    snowFlakeCount = count or Prefs.GetFromCurrentProfile('SnowFlakesCount') or 100
    for i = 1, snowFlakeCount do
        SnowFlake(snowFlakesGroup, 100, math.random() * 2, math.random(snowFlakesGroup.Width()),
            math.random(snowFlakesGroup.Height()))
    end
end

function Clear()
    if not IsDestroyed(snowFlakesGroup) then
        snowFlakesGroup:ClearChildren()
    end
end
