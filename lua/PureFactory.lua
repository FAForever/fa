#****************************************************************************
#**
#**  File     :  /lua/PureFactory.lua
#**  Author(s):  Brute51
#**
#**  Summary  :  Additional code for factory units
#**
#****************************************************************************

# This function is makes sure (factory) units cannot reclaim and such [131]

function PureFactory(superClass)
    return Class(superClass) {

        OnStartReclaim = function(self, target)
            IssueStop({self})
            IssueClearCommands({self})
        end,

        OnStartCapture = function(self, target)
            IssueStop({self})
            IssueClearCommands({self})
        end,
    
        OnStartBuild = function(self, unitBeingBuilt, order)
            if not self:CanBuild( unitBeingBuilt:GetUnitId() ) then
                IssueStop({self})
                IssueClearCommands({self})
            else
                superClass.OnStartBuild(self, unitBeingBuilt, order)
            end
        end,

        BuildingState = State(superClass.BuildingState  or  State { Main = function(self) end, } )
        {
            Main = function(self)
                if not self:CanBuild( self.UnitBeingBuilt:GetUnitId() ) then
                    IssueStop({self})
                    IssueClearCommands({self})
                else
                    superClass.BuildingState.Main(self)
                end
            end,
        },

        FinishedBuildingState = State(superClass.FinishedBuildingState  or  State { Main = function(self) end, } )
        {
            Main = function(self)
                if not self:CanBuild( self.UnitBeingBuilt:GetUnitId() ) then
                    IssueStop({self})
                    IssueClearCommands({self})
                else
                    superClass.FinishedBuildingState.Main(self)
                end
            end,
        },
    }
end