--******************************************************************************************************
--** Copyright (c) 2024 FAForever
--**
--** Permission is hereby granted, free of charge, to any person obtaining a copy
--** of this software and associated documentation files (the "Software"), to deal
--** in the Software without restriction, including without limitation the rights
--** to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
--** copies of the Software, and to permit persons to whom the Software is
--** furnished to do so, subject to the following conditions:
--**
--** The above copyright notice and this permission notice shall be included in all
--** copies or substantial portions of the Software.
--**
--** THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
--** IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
--** FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
--** AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
--** LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
--** OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
--** SOFTWARE.
--******************************************************************************************************

local IconCheckbox = import('/lua/maui/checkbox.lua').IconCheckbox
local SkinnableFile = import('/lua/ui/uiutil.lua').SkinnableFile

local iconTextures = {
    repeatBuild = '/game/construct-sm_btn/infinite_',
    template = '/game/construct-sm_btn/template_',
}

-- This returns the iconId so we can track it on the button
local GetIconTextures = function(iconId)
    if iconTextures[iconId] then
        local pre = iconTextures[iconId]
        return SkinnableFile(pre..'on.dds'),
            SkinnableFile(pre..'off.dds')
    end
end

---@class RepeatBuildTemplateCheckbox : IconCheckbox
RepeatBuildTemplateCheckbox = Class(IconCheckbox) {

    __init = function(self, parent)
        IconCheckbox.__init(self, parent)
        self.key = 'repeatBuild'
        self:Layout()
    end,

    Layout = function(self)
        self:SetIconTextures(GetIconTextures(self.key))
        IconCheckbox.Layout(self)
    end,

    OnClick = function(self, modifiers)
        if self.key == 'repeatBuild' then
            self:ToggleCheck()
        elseif self.key == 'template' then
            self:SetCheck(false)
        end
    end,

    SetIconKey = function(self, key)
        -- We want to display the template (or nothing) when explicitly called for
        if not key or key == 'template' then
            self.key = key
            self:SetCheck(false, true)
        -- Otherwise, show the repeat build symbol
        else
            self.key = 'repeatBuild'
        end
        self:Layout()
    end,

    OnSelection = function(self, key)
        -- We'll need to update here based on the units we have selected
    end,
}