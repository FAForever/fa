
-- # imports


local Group = import('/lua/maui/group.lua').Group
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local Checkbox = import('/lua/maui/checkbox.lua').Checkbox
local Text = import('/lua/maui/text.lua').Text
local Grid = import('/lua/maui/Grid.lua').Grid
local IntegerSlider = import('/lua/maui/slider.lua').IntegerSlider

local UIUtil = import('/lua/ui/uiutil.lua')
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local GameMain = import('/lua/ui/game/gamemain.lua')

local Prefs = import('/lua/user/prefs.lua')
local Tooltip = import('/lua/ui/game/tooltip.lua')
local FindClients = import('/lua/ui/game/chat.lua').FindClients

-- # locals

-- # old public interface

function CreateScoreUI()

end

function ToggleScoreControl()

end

function Expand()

end

function Contract()

end

function NoteGameSpeedChanged(value)

end

function ArmyAnnounce(army, text)

end

-- # classes

---@class Scoreboard : Group
Scoreboard = Class(Group) {

    __init = function(self, parent)
        Group.__init(self, parent, "Scoreboard")

        -- do not use self reference as that can be confusing
        local scoreboard = self 

        scoreboard.Depth:Set(10)

        scoreboard.bgTop = Bitmap(scoreboard)
        scoreboard.bgBottom = Bitmap(scoreboard)
        scoreboard.bgStretch = Bitmap(scoreboard)
        scoreboard.armyGroup = Group(scoreboard)
    
        scoreboard.leftBracketMin = Bitmap(scoreboard)
        scoreboard.leftBracketMax = Bitmap(scoreboard)
        scoreboard.leftBracketMid = Bitmap(scoreboard)
    
        scoreboard.rightBracketMin = Bitmap(scoreboard)
        scoreboard.rightBracketMax = Bitmap(scoreboard)
        scoreboard.rightBracketMid = Bitmap(scoreboard)
    
        scoreboard:DisableHitTest()
        scoreboard.leftBracketMin:DisableHitTest()
        scoreboard.leftBracketMax:DisableHitTest()
        scoreboard.leftBracketMid:DisableHitTest()
        scoreboard.rightBracketMin:DisableHitTest()
        scoreboard.rightBracketMax:DisableHitTest()
        scoreboard.rightBracketMid:DisableHitTest()

        scoreboard.Arrow = Checkbox(savedParent)
        scoreboard.Arrow.OnCheck = function(self, checked)
            scoreboard:SetCollapsed(not checked)
        end
        Tooltip.AddCheckboxTooltip(scoreboard.Arrow, 'score_collapse')

    end,


    --- Allows you to expand / contract the scoreboard accordingly
    --- @param self Scoreboard 
    SetCollapsed = function(self, state)

    end,

}