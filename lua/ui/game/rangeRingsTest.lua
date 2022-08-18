
ForkThread(
    function()

        local thread = false
        local trash = TrashBag()

        local curr = import('/lua/ui/game/rangeRings.lua')
        local prev = false

        while true do

            curr = import('/lua/ui/game/rangeRings.lua')
            if curr ~= prev then 
                trash:Destroy()
                thread = curr.CreateTestRings(trash)
                prev = curr
            end

            WaitFrames(1)
        end
    end
)