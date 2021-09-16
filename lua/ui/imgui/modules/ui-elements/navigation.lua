
local UIUtil = import('/lua/ui/uiutil.lua')
local Group = import('/lua/maui/group.lua').Group
local Slider = import('/lua/maui/slider.lua').Slider
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')

-- utility files
local Conversion = import('/lua/ui/imgui//modules/conversion.lua')
local ToLabel = Conversion.ToLabel

-- look up table for textures
local _tabBarTextures = { }
_tabBarTextures["up"] = "/lua/ui/imgui//textures/tab-bar-dds/default-up.dds"
_tabBarTextures["up-off"] = "/lua/ui/imgui//textures/tab-bar-dds/default-up-off.dds"
_tabBarTextures["down"] = "/lua/ui/imgui//textures/tab-bar-dds/default-down.dds"
_tabBarTextures["over"] = "/lua/ui/imgui//textures/tab-bar-dds/default-over.dds"
_tabBarTextures["disabled"] = "/lua/ui/imgui//textures/tab-bar-dds/default-down.dds"

--- Adds a tab bar.
-- @param identifier The identifier of this element.
-- @param tabs The identifiers of the tabs of the tab bar.
function BeginTabBar(window, identifier, tabIdentifiers)

    local element = self.tracker[identifier]
    if not element then 

        -- generic group element
        element = Group(self.main)
        element:DisableHitTest()  

        -- prevents errors with regard to the size of the group
        LayoutHelpers.SetWidth(element, 10)
        LayoutHelpers.SetHeight(element, 10)

        -- choose a tab to enable
        element.chooseTab = function (identifier)
            -- disable all tabs
            for k, tab in element.tabs do 
                tab.enabled = false 
                tab.changed = true 
            end

            -- enable tab
            element.tabs[identifier].enabled = true
        end

        -- factor to determine the amount of space for each tab
        local factor = 1 / table.getn(tabIdentifiers)
        local width = self.main.Right() - self.main.Left() - 2 * self.outline

        -- the tabs available in this tab bar, populated down below
        element.tabs = { }

        -- for each tab identifier provided
        for k, tabIdentifier in tabIdentifiers do 

            local tab = self.tracker[tabIdentifier]
            if not tab then 
        
                -- generic group tab
                tab = Group(self.main)
                tab:DisableHitTest()
        
                -- prevents errors with regard to the size of the group
                LayoutHelpers.SetWidth(tab, 10)
                LayoutHelpers.SetHeight(tab, 10)
        
                -- create the button tab
                local parent = tab 
                local normal = _tabBarTextures["up"]
                local active = _tabBarTextures["down"]
                local highlight = _tabBarTextures["over"]
                local disabled = _tabBarTextures["disabled"]
                local clickCue = "UI_Opt_Yes_No"
                local rolloverCue = "UI_Opt_Affirm_Over"
                tab.button = Button(parent, normal, active, highlight, disabled, clickCue, rolloverCue)
                LayoutHelpers.AtLeftTopIn(tab.button, tab, 0, 0)
                tab.button.Left:Set( function() return self.main.Left() + self.outline end )
                tab.button.Right:Set( function() return self.main.Left() + self.outline + 135 end )
                tab.button.Height:Set(24)
                tab.button.Depth:Set(2000)
        
                -- toggles the tab
                tab.button.OnClick = function(self, modifiers)
                    element.chooseTab(tab.identifier)
                end
        
                -- create the text tab
                local size = 12
                local color = "ffffffff"
                tab.text = UIUtil.CreateText(element, tabIdentifier, size, UIUtil.bodyFont)
                LayoutHelpers.AtVerticalCenterIn(tab.text, tab.button)
                LayoutHelpers.AtLeftIn(tab.text, tab.button, 10)
                tab.text:SetColor(color)
                tab.text.Depth:Set(2001)
                tab.text:DisableHitTest()
        
                -- add properties
                tab.changed = false
                tab.enabled = false 
                tab.identifier = tabIdentifier
                tab.index = k
        
                -- keep track of it
                self.tracker[tabIdentifier] = tab
                element.tabs[tabIdentifier] = tab
            end
        
            -- position it
            -- todo
            LayoutHelpers.AtLeftTopIn(tab, self.main, self.outline - 10, self.offset)
            tab.button.Left:Set( function() return self.main.Left() + 10 +self.outline + (tab.index - 1) * (factor * width) end )
            tab.button.Right:Set( function() return self.main.Left() + self.outline + tab.index * (factor * width) - 10 end )

            -- update the button if applicable
            if tab.changed then 
                if tab.enabled then 
                    tab.button:SetTexture(_tabBarTextures["up"])
                    tab.button:SetNewTextures(
                        _tabBarTextures["up"], 
                        _tabBarTextures["down"], 
                        _tabBarTextures["over"],
                        _tabBarTextures["disabled"]
                    )
                else 
                    tab.button:SetTexture(_tabBarTextures["up-off"])
                    tab.button:SetNewTextures(
                        _tabBarTextures["up-off"], 
                        _tabBarTextures["down"], 
                        _tabBarTextures["over"],
                        _tabBarTextures["disabled"]
                    )
                end
        
                tab.button:ApplyTextures()
                tab.changed = false 
            end 
        
            -- show it
            tab.used = true
            if tab:IsHidden() then 
                tab:Show()
            end
        end

        element.height = 30
    end

    -- update internal state
    self:UpdateOffset(element.height)
end

--- Ends a tab bar.
-- @param identifier The identifier of this element. This should match with the identifier used in mWindow:BeginTabBar.
function EndTabBar(window, identifier)
    self:Unindent()

    -- ??
    self:UpdateOffset(10)
end

--- Adds a tab bar.
-- @param identifier The identifier of this element. This should match with a tab used in mWindow:BeginTabBar.
function BeginTab(window, identifier)
    local tab = self.tracker[identifier]
    if not tab then 
        WARN("Unknown tab: " .. identifier)
    end

    return tab.enabled
end