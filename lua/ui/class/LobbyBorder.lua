local Group = import("/lua/maui/group.lua").Group



LobbyBorder = Class(Group)
{
    __init = function(self, parent)
        Group.__init(self, parent)

        
    end,


    __post_init = function (self)
        self:_Layout()
    end,

    _Layout = function (self)
        
    end


}

