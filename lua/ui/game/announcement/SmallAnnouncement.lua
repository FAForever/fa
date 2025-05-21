local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Layouter = LayoutHelpers.ReusedLayoutFor

local UIUtil = import("/lua/ui/uiutil.lua")
local Group = import("/lua/maui/group.lua").Group
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local TextArea = import("/lua/ui/controls/textarea.lua").TextArea

local AbstractAnnouncement = import("/lua/ui/game/announcement/AbstractAnnouncement.lua").AbstractAnnouncement

--- An announcement with just a title.
---@class UISmallAnnouncement : UIAbstractAnnouncement
---@field Title Text
SmallAnnouncement = ClassUI(AbstractAnnouncement) {

    ---@param self UISmallAnnouncement
    ---@param parent Control
    ---@param goalControl Control
    ---@param onFinishedCallback fun()
    ---@param text string
    __init = function(self, parent, goalControl, onFinishedCallback, text)
        AbstractAnnouncement.__init(self, parent, goalControl, onFinishedCallback)

        self.Title = UIUtil.CreateText(self, text, 22, UIUtil.titleFont)
    end,

    ---@param self UISmallAnnouncement
    ---@param parent Control
    ---@param goalControl Control
    ---@param onFinishedCallback fun()
    ---@param text string
    __post_init = function(self, parent, goalControl, onFinishedCallback, text)
        AbstractAnnouncement.__post_init(self, parent, goalControl, onFinishedCallback)

        LayoutHelpers.LayoutFor(self.Title)
            :AtCenterIn(GetFrame(0), -250)
            :DropShadow(true)
            :Color(UIUtil.fontColor)
            :End()

        LayoutHelpers.LayoutFor(self)
            :Fill(self.Title)
    end,
}
