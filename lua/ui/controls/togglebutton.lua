local Group = import('/lua/maui/group.lua').Group
local UIUtil = import('/lua/ui/uiutil.lua')
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')

--- Represents a button with multiple states.
-- A ToggleButton is a button that, when clicked, moves to the next state (or back to the first state
-- if the end of the state list has been reached) and dispatches an event.
ToggleButton = Class(Group) {
    --- Create a new ToggleButton
    --
    -- @param parent The UI control to parent this control from.
    -- @param texturePath The path, relative to the source root, to look for textures. A directory
    --                    for each key in the keyset is expected to be located there, each of which
    --                    should contain a set of textures suitable for creating a Button.
    -- @param states A list of tables representing the states of this control. States are traversed
    --               in the order they are given in this list. Valid keys for each state object are:
    --               key: A value to uniquely identify this state. This will be passed to
    --                    OnStateChanged when the control transitions to this state.
    --               label (optional): The string label to put on the button when in this state.
    -- @param defaultKey The key of the state the control should start in.
    __init = function(self, parent, texturePath, states, defaultKey)
        Group.__init(self, parent)

        local buttonmap = {}
        self.buttonmap = buttonmap
        self.activeState = defaultKey

        for k, v in states do
            -- Closure copy
            local btnKey = v.key

            local btn = UIUtil.CreateButtonStd(self, texturePath .. btnKey .. "/", v.label)
            LayoutHelpers.AtLeftTopIn(btn, self)

            -- Hide this button if it is not the default.
            if btnKey ~= defaultKey then
                btn:Hide()
                btn:DisableHitTest()
            end

            buttonmap[btnKey] = btn
            local nextState = states[k + 1].key or states[1].key

            btn.OnClick = function(btn, modifiers)
                self:SetState(nextState)
            end
        end

        self.Width:Set(buttonmap[defaultKey].Width)
        self.Height:Set(buttonmap[defaultKey].Height)
    end,

    --- Set the control to the state with the given key.
    --
    -- @param stateKey The key of the state to transition to
    -- @param ignoreEvent If truthy, OnStateChanged will not be called as a result of this call.
    SetState = function(self, stateKey, ignoreEvent)
        -- Show the appropriate button for this state.
        for k, v in self.buttonmap do
            v:Hide()
        end
        self.buttonmap[stateKey]:Show()
        self.buttonmap[stateKey]:EnableHitTest()

        -- Possibly call the event listener.
        if not ignoreEvent then
            self:OnStateChanged(stateKey)
        end
    end,

    Disable = function(self)
        for k, v in self.buttonmap do
            v:Disable()
        end
    end,

    Enable = function(self)
        for k, v in self.buttonmap do
            v:Enable()
        end
    end,

    --- Called when the button is moved to a new state, via clicking or a call to SetState.
    OnStateChanged = function(self, newState) end
}
