--*****************************************************************************
--* File: lua/modules/maui/mauiutil.lua
--* Author: Chris Blackwell
--* Summary: Various utility functions that will assist UI creation
--*
--* Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--*****************************************************************************

local Checkbox = import("/lua/maui/checkbox.lua").Checkbox

-- Create a radio group, which is a group of checkboxes and associtated labels that have
-- a mutually exclusive checked state.
---@class RadioGroup
RadioGroup = ClassSimple {
    -- items is an indexed table of checkbox's with labels in the form:
    -- {{checkbox = Checkbox(), label = Text()}, {checkbox = Checkbox(), label = Text()}, etc}
    -- default is the default index
    __init = function(self, items, default)
        default = default or 1
        self._items = items
        self.current = default
        self._items[default].checkbox:SetCheck(true)

        for index, item in items do
            item.checkbox._radioGroupIndex = index
            item.label._radioGroupIndex = index

            -- forward all click events from the label to the checkbox
            item.label.HandleEvent = function(control, event)
                local retval = false
                if self._labelEventHandler then
                    self._labelEventHandler(control, event)
                end
                if event.Type == 'ButtonPress' or event.Type == 'ButtonDClick' then
                    self._items[control._radioGroupIndex].checkbox:HandleEvent(event)
                    retval = true
                end
                return retval
            end

            item.checkbox.HandleEvent = function(control, event)
                local retval = false
                if self._checkboxEventHandler then
                    self._checkboxEventHandler(control, event)
                end
                if event.Type == 'ButtonPress' or event.Type == 'ButtonDClick' then
                    local curIndex = control._radioGroupIndex
                    if self.current != curIndex then
                        self._items[self.current].checkbox:SetCheck(false)
                        self.current = curIndex
                        control:SetCheck(true)
                        self:OnChoose(curIndex, self._items[curIndex])
                    end
                    self:OnClick(curIndex, self._items[curIndex])
                    retval = true
                else
                    -- let other events go through so we get rollover states
                    retval = Checkbox.HandleEvent(control, event)
                end
                
                return retval
            end
        end
    end,

    Select = function(self, index)
        if index < 1 or index > table.getn(self._items) then
            return
        end
        if index != self.current then
            self._items[self.current].checkbox:SetCheck(false)
            self.current = index
            self._items[index].checkbox:SetCheck(true)
            self:OnChoose(index, self._items[index])
        end
        self:OnClick(index, self._items[index])
    end,

    -- these allow you to set a handler that will get called before the custom handler
    SetCheckboxEventHandler = function(self, handler)
        self._checkboxEventHandler = handler
    end,
    
    SetLabelEventHandler = function(self, handler)
        self._labelEventHandler = handler
    end,

    -- called when item chosen, passes in the index of the item and the item itself (so you can access .checkbox and .label)
    OnChoose = function(self, index, item) end,

    -- called when item is clicked on, regardless if it's already in chosen state
    OnClick = function(self, index, item) end,
}

