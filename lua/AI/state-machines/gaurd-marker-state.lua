
-- ChangeState


BaseStateMachine = ClassSimple {
    TickFunction = function(self, func, wait)
        -- some logic to make sure we get destroyed on state change

        while true do 
            func()
            WaitSeconds(wait)
        end
    end

    GetNearbyPlatoons = function(self)

    end,
}

---@class AIGuardMarker
AttackPlatoon = Class(BaseStateMachine) {

    __init = function(self, platoon, configuration)
        BaseStateMachine.__init(self, platoon, configuration, 'GuardMarker')
        self.Platoon = platoon
        self.Configuration = configuration

        local units = platoon:GetPlatoonUnits()
        for k, unit in units do
            -- set some identifier
        end

        self:ChangeState(self.FindTarget)
    end,

    FindTarget = State {

        ---@param self AIGuardMarker
        Main = function(self)

            -- some logic to find a target

            -- target found
            ChangeState(self, self.FindPath)

            -- no target found
            ChangeState(self, self.Blank)

        end,

    },

    FindPath = State {
        ---@param self AIGuardMarker
        Main = function(self) 

            -- some logic to determine path

            -- no path found / path found too long
            ChangeState(self, self.WaitForTransports)

            -- path found
            ChangeState(self, self.NavigateToTarget)
        end,
    },

    WaitForTransports = State {
        ---@param self AIGuardMarker
        Main = function(self) 

            -- some logic to wait for transports

            self:TickFunction(
                function()

                    -- scan for threat

                    -- detected significant threat, oh noo!!

                    local platoons = self:GetNearbyPlatoons('Engage')

                    -- compute our total threat value

                    -- if total threat value of ourself > detected significant threat

                    self:ChangeState(self.Engage)
                    for k, platoon in platoons do
                        platoon:ChangeState(platoon.Engage)
                    end

                    -- if significant threat
                    self:ChangeState(self.Flee)

                    -- if insignificant threat
                    self:ChangeState(self.Engage)
                end, 2
            )

            -- transports found
            ChangeState(self, self.TransportToTarget)

        end,
    },

    TransportToTarget = State {
        ---@param self AIGuardMarker
        Main = function(self) 

            -- some logic to check if we are at the destination

            -- transports are under attack, find a new path
            ChangeState(self, self.FindPath)

            -- at the destination
            ChangeState(self, self.AtTarget)

        end,
    },

    NavigateToTarget = State {
        ---@param self AIGuardMarker
        Main = function(self) 

            self:ForkThread(
                function()
                    while true do
                        WaitSeconds(1.0)


                    end
                end
            )

            self:TickFunction(
                function()
                    -- scan for threat

                    -- if significant threat
                    self:ChangeState(self.Flee)

                    -- if insignificant threat
                    self:ChangeState(self.Engage)
                end, 2
            )


        end,
    },

    Flee = State {
        ---@param self AIGuardMarker
        Main = function(self) 

        end,
    },

    Engage = State {
        ---@param self AIGuardMarker
        Main = function(self) 
            -- do issue aggressive move
        end,
    },

    AtTarget = State {
        ---@param self AIGuardMarker
        Main = function(self)
            -- check surroundings for threat or opportunities

            -- significant threat
            ChangeState(self, self.Flee)

            -- insignificant threat
            ChangeState(self, self.Engage)

            -- nothing around us
            ChangeState(self, self.FindTarget)
        end,
    },

    Blank = State {
        ---@param self AIGuardMarker
        Main = function(self) 

        end,
    }
}

function ApplyGuardMarkerBehavior(platoon, configuration)
    GuardMarker(platoon, configuration)
end