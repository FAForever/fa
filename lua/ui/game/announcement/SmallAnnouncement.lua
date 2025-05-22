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
    ---@param text string
    __init = function(self, parent, text)
        AbstractAnnouncement.__init(self, parent)

        self.Title = UIUtil.CreateText(self.ContentArea, text, 22, UIUtil.titleFont)
    end,

    ---@param self UISmallAnnouncement
    ---@param parent Control
    ---@param text string
    __post_init = function(self, parent, text)
        AbstractAnnouncement.__post_init(self, parent)

        Layouter(self.Title)
            :AtCenterIn(parent, -250)
            :End()

        -- match the content area with the title
        Layouter(self.ContentArea)
            :Left(self.Title.Left)
            :Right(self.Title.Right)
            :AtTopIn(self.Title, 10)
            :Bottom(self.Title.Bottom)
            :ResetWidth()
            :ResetHeight()
            :Alpha(0, true)
            :End()

    end,
}
