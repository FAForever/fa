
local Window = import("/lua/maui/window.lua")
local Group = import("/lua/maui/group.lua")

---@class PerformanceGraph : Group
local PerformanceGraph = ClassUI(Group) {

}

---@class PerformanceWindow : Window
local PerformanceWindow = ClassUI(Window) {

    __init = function(self, parent) 
        Window.__init(self, parent, "PerformanceWindow")

        self.IsOpen = true
    end,

    Open = function(self)
        if self.IsOpen then
            return
        end



    end,

    Close = function(self)
        if not self.IsOpen then
            return
        end



    end
}

local instance = false

--- Opens up the performance tracking window
function OpenWindow()

    SPEW("Opening performance tracking window")

    if not instance then 
        instance = PerformanceWindow()
    end

    instance:Open()
end

--- Closes the performance tracking window
function CloseWindow()

    SPEW("Closing performance tracking window")

    if instance then 
        instance:Close()
    end
end