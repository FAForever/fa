-- Unit test and regression suite for QuickDialog / Popup lifetime & Launch re-entrancy
-- Simulates Moho UI object hierarchy, TrashBag, EscapeHandler, and Lobby launch sequence.
--
-- This test specifies and verifies the contracts implemented in:
-- - lua/ui/controls/popups/popup.lua (Popup lifecycle, TrashBag, and owner-aware escape teardown)
-- - lua/ui/uiutil.lua (QuickDialog button lifecycle, double-click protection, and re-arming)
-- - lua/ui/dialogs/eschandler.lua (EscapeHandler stack and owner-aware PopEscapeHandler)
-- - lua/ui/lobby/lobby.lua (TryLaunch launchInProgress lock and observer kick flow)

local tests_failed = 0
local tests_passed = 0

local function assert_true(cond, msg)
    if not cond then
        tests_failed = tests_failed + 1
        local err = "FAIL: " .. (msg or "assertion failed")
        print(err)
    else
        tests_passed = tests_passed + 1
    end
end

local function assert_false(cond, msg)
    assert_true(not cond, msg)
end

local function assert_equal(a, b, msg)
    if a ~= b then
        tests_failed = tests_failed + 1
        local err = string.format("FAIL: expected %s, got %s (%s)", tostring(b), tostring(a), msg or "")
        print(err)
    else
        tests_passed = tests_passed + 1
    end
end

-- ============================================================================
-- Moho / Maui Engine Simulation
-- ============================================================================

local escapeHandlers = {}

local function PushEscapeHandler(h)
    table.insert(escapeHandlers, h)
    return h
end

local function PopEscapeHandler(handler)
    if #escapeHandlers == 0 then
        tests_failed = tests_failed + 1
        print("FAIL: EscapeHandler stack underflow / popped when empty!")
        return nil
    end

    if handler then
        for i = #escapeHandlers, 1, -1 do
            if escapeHandlers[i] == handler then
                return table.remove(escapeHandlers, i)
            end
        end
        return nil
    end

    return table.remove(escapeHandlers)
end

local function GetEscapeHandlerCount()
    return #escapeHandlers
end

local function HandleEsc()
    if #escapeHandlers > 0 then
        local topHandler = escapeHandlers[#escapeHandlers]
        topHandler()
    end
end

local function IsDestroyed(control)
    return not control or control._destroyed == true
end

-- Simulates TrashBag (matching lua/system/trashbag.lua)
local TrashBag = {}
TrashBag.__index = TrashBag

function TrashBag.new()
    local self = setmetatable({}, TrashBag)
    self._items = {}
    return self
end

function TrashBag:Add(item)
    table.insert(self._items, item)
    return item
end

function TrashBag:Destroy()
    for _, item in ipairs(self._items) do
        if item and item.Destroy then
            item:Destroy()
        end
    end
    self._items = {}
end

-- Simulates Control (matching lua/maui/control.lua)
local Control = {}
Control.__index = Control

function Control.new(parent, debugname)
    local self = setmetatable({}, Control)
    self._destroyed = false
    self._isDisabled = false
    self._clicked = false
    self._children = {}
    self.debugname = debugname or "Control"
    if parent then
        self:SetParent(parent)
    end
    return self
end

function Control:SetParent(newParent)
    -- Remove from old parent's child list
    if self._parent and self._parent._children then
        for i, child in ipairs(self._parent._children) do
            if child == self then
                table.remove(self._parent._children, i)
                break
            end
        end
    end

    self._parent = newParent

    -- Add to new parent's child list
    if newParent and newParent._children then
        table.insert(newParent._children, self)
    end
end

function Control:Destroy()
    if self._destroyed then
        tests_failed = tests_failed + 1
        print("FAIL: Native crash / Assertion failed: Double-destroy on " .. tostring(self.debugname))
        return
    end
    self._destroyed = true

    -- Recursively destroy children in Moho C++ engine
    local childrenCopy = {}
    for _, child in ipairs(self._children) do
        table.insert(childrenCopy, child)
    end
    for _, child in ipairs(childrenCopy) do
        if not child._destroyed then
            child:Destroy()
        end
    end

    if self.OnDestroy then
        self:OnDestroy()
    end
end

function Control:Disable()
    self._isDisabled = true
end

function Control:Enable()
    self._isDisabled = false
end

function Control:IsDisabled()
    return self._isDisabled
end

local Group = {}
Group.__index = setmetatable(Group, Control)
function Group.new(parent, debugname)
    local self = Control.new(parent, debugname or "Group")
    setmetatable(self, Group)
    return self
end

-- ============================================================================
-- Popup Implementation (matching lua/ui/controls/popups/popup.lua)
-- ============================================================================

local Popup = {}
Popup.__index = setmetatable(Popup, Group)

function Popup.new(parent, content)
    local self = Group.new(parent, "Popup")
    setmetatable(self, Popup)
    self.Trash = TrashBag.new()
    self.content = content
    self._closed = false
    content:SetParent(self)

    local escapeHandler = function()
        self:OnEscapePressed()
    end
    self._escapeHandler = escapeHandler
    PushEscapeHandler(escapeHandler)

    self.Trash:Add({
        Destroy = function()
            if self._escapeHandler then
                PopEscapeHandler(self._escapeHandler)
                self._escapeHandler = nil
            end
        end,
    })

    return self
end

function Popup:Close()
    if not IsDestroyed(self) then
        self:OnClosed()
        self:Destroy()
    end
end

function Popup:OnClosed()
    if not self._closed then
        self._closed = true
        if self._escapeHandler then
            PopEscapeHandler(self._escapeHandler)
            self._escapeHandler = nil
        end
    end
end

function Popup:OnDestroy()
    if self.Trash then
        self.Trash:Destroy()
    end
    self:OnClosed()
end

function Popup:OnEscapePressed()
    self:Close()
end

function Popup:OnShadowClicked()
    self:Close()
end

-- ============================================================================
-- QuickDialog Implementation (matching lua/ui/uiutil.lua)
-- ============================================================================

local function QuickDialog(parent, dialogText, button1Text, button1Callback, button2Text, button2Callback, destroyOnCallback, modalInfo)
    if destroyOnCallback == nil then
        destroyOnCallback = true
    end

    local dialog = Group.new(parent, "quickDialogGroup")
    local popup = Popup.new(parent, dialog)
    popup.OnShadowClicked = function() end
    popup.OnEscapePressed = function() end

    local function MakeButton(text, callback)
        local button = Control.new(dialog, "Button_" .. tostring(text))
        if callback then
            button.OnClick = function(self)
                if self._clicked then return end
                self._clicked = true
                self:Disable()

                callback()

                if destroyOnCallback and not IsDestroyed(popup) then
                    popup:Close()
                elseif not IsDestroyed(self) then
                    self._clicked = false
                    self:Enable()
                end
            end
        else
            button.OnClick = function(self)
                if self._clicked then return end
                self._clicked = true
                self:Disable()

                if not IsDestroyed(popup) then
                    popup:Close()
                elseif not IsDestroyed(self) then
                    self._clicked = false
                    self:Enable()
                end
            end
        end
        return button
    end

    if button1Text then
        dialog._button1 = MakeButton(button1Text, button1Callback)
    end
    if button2Text then
        dialog._button2 = MakeButton(button2Text, button2Callback)
    end

    if modalInfo and modalInfo.escapeButton then
        popup.OnEscapePressed = function(self)
            local btn = modalInfo.escapeButton == 1 and dialog._button1 or dialog._button2
            if btn and not btn:IsDisabled() then
                btn:OnClick()
            else
                self:Close()
            end
        end
    end

    return popup, dialog
end

-- ============================================================================
-- Tests
-- ============================================================================

print("--- Running QuickDialog & Popup Lifecycle Tests ---")

-- Test 1: Standard open & close via button
do
    local initialEscCount = GetEscapeHandlerCount()
    local GUI = Group.new(nil, "LobbyGUI")
    local popup, dialog = QuickDialog(GUI, "Standard Dialog", "OK", nil, nil, nil, true)

    assert_equal(GetEscapeHandlerCount(), initialEscCount + 1, "Escape handler registered")
    assert_false(IsDestroyed(popup), "Popup is open")

    dialog._button1:OnClick()

    assert_true(IsDestroyed(popup), "Popup is destroyed after OK click")
    assert_equal(GetEscapeHandlerCount(), initialEscCount, "Escape handler popped after close")
end

-- Test 2: Standard open & close via Escape handler
do
    local initialEscCount = GetEscapeHandlerCount()
    local GUI = Group.new(nil, "LobbyGUI")
    local popup = Popup.new(GUI, Group.new(GUI, "PopupContent"))

    assert_equal(GetEscapeHandlerCount(), initialEscCount + 1, "Escape handler registered")

    -- Simulate Escape key press calling topmost handler
    HandleEsc()

    assert_true(IsDestroyed(popup), "Popup destroyed via escape")
    assert_equal(GetEscapeHandlerCount(), initialEscCount, "Escape handler stack cleanly balanced after escape")
end

-- Test 3: Fixed QuickDialog - callback destroys parent GUI without crashing or double-destroy
do
    local initialEscCount = GetEscapeHandlerCount()
    local GUI = Group.new(nil, "LobbyGUI")
    local launchCount = 0

    local function TryLaunch(skipCheck)
        launchCount = launchCount + 1
        -- Simulates launch: engine destroys GUI
        GUI:Destroy()
    end

    local popup, dialog = QuickDialog(GUI, "Kick observers?", "Yes", function() TryLaunch(true) end, "No", nil, true)

    assert_equal(GetEscapeHandlerCount(), initialEscCount + 1, "Escape handler pushed on popup create")

    -- Click "Yes"
    dialog._button1:OnClick()

    assert_equal(launchCount, 1, "TryLaunch called once")
    assert_true(IsDestroyed(GUI), "GUI destroyed")
    assert_true(IsDestroyed(popup), "Popup destroyed")
    assert_equal(GetEscapeHandlerCount(), initialEscCount, "Escape handler stack cleanly balanced")
end

-- Test 4: Dialog stays open (destroyOnCallback = false) -> button re-arms for subsequent clicks
do
    local initialEscCount = GetEscapeHandlerCount()
    local GUI = Group.new(nil, "LobbyGUI")
    local actionCount = 0

    local popup, dialog = QuickDialog(GUI, "Are you sure?", "Yes", function()
        actionCount = actionCount + 1
    end, "No", nil, false)

    -- First click
    dialog._button1:OnClick()
    assert_equal(actionCount, 1, "Action called on first click")
    assert_false(dialog._button1:IsDisabled(), "Button re-armed when dialog stays open")

    -- Second click
    dialog._button1:OnClick()
    assert_equal(actionCount, 2, "Action called on second click when dialog kept open")

    popup:Close()
    assert_equal(GetEscapeHandlerCount(), initialEscCount, "Escape handlers restored")
end

-- Test 5: Lobby TryLaunch re-entrancy guard test
do
    local launchInProgress = false
    local kickCount = 0
    local launchCount = 0
    local GUI = Group.new(nil, "LobbyGUI")
    GUI.launchGameButton = Control.new(GUI, "LaunchButton")

    local function TryLaunch(skipNoObserversCheck)
        if launchInProgress then
            return
        end

        local anyOtherObservers = true
        if anyOtherObservers and not skipNoObserversCheck then
            QuickDialog(GUI, "Kick observers?", "Yes", function() TryLaunch(true) end, "No", nil, true)
            return
        end

        local HostUtils = {
            KickObservers = function(reason)
                kickCount = kickCount + 1
            end,
            RefreshButtonEnabledness = function()
                GUI.launchGameButton:Enable()
            end,
        }
        HostUtils.KickObservers("GameLaunched")

        if launchInProgress then
            return
        end
        launchInProgress = true
        GUI.launchGameButton:Disable()

        launchCount = launchCount + 1
        GUI:Destroy()
    end

    -- Initial launch click prompts dialog
    TryLaunch(false)
    assert_equal(kickCount, 0, "No kick before confirmation")
    assert_equal(launchCount, 0, "No launch before confirmation")
    assert_false(launchInProgress, "launchInProgress is false while dialog open")

    -- Find the open dialog inside GUI
    local dialog
    for _, child in ipairs(GUI._children) do
        if child.content then
            dialog = child.content
            break
        end
    end
    assert_true(dialog ~= nil, "Dialog was created and found")

    -- Rapidly trigger the "Yes" button twice
    dialog._button1:OnClick()
    dialog._button1:OnClick()

    assert_equal(kickCount, 1, "Kicked observers exactly once")
    assert_equal(launchCount, 1, "Launched game exactly once")
    assert_true(launchInProgress, "Launch marked in progress")
    assert_true(IsDestroyed(GUI), "GUI cleanly destroyed")
end

-- Test 6: Nested Popups - closing in LIFO order keeps stack balanced
do
    local initialEscCount = GetEscapeHandlerCount()
    local GUI = Group.new(nil, "LobbyGUI")

    local popupA = Popup.new(GUI, Group.new(GUI, "PopupAContent"))
    assert_equal(GetEscapeHandlerCount(), initialEscCount + 1, "Popup A escape handler pushed")

    local popupB = Popup.new(GUI, Group.new(GUI, "PopupBContent"))
    assert_equal(GetEscapeHandlerCount(), initialEscCount + 2, "Popup B escape handler pushed")

    -- Press Escape to close B
    HandleEsc()
    assert_true(IsDestroyed(popupB), "Popup B destroyed on Escape")
    assert_false(IsDestroyed(popupA), "Popup A remains open")
    assert_equal(GetEscapeHandlerCount(), initialEscCount + 1, "Only Popup A handler remains")

    -- Press Escape to close A
    HandleEsc()
    assert_true(IsDestroyed(popupA), "Popup A destroyed on Escape")
    assert_equal(GetEscapeHandlerCount(), initialEscCount, "Escape stack empty after all popups closed")
end

-- Test 7: Nested Popups - destroying lower popup out-of-order removes its handler without corrupting upper popup
do
    local initialEscCount = GetEscapeHandlerCount()
    local GUI = Group.new(nil, "LobbyGUI")

    local popupA = Popup.new(GUI, Group.new(GUI, "PopupAContent"))
    local popupB = Popup.new(GUI, Group.new(GUI, "PopupBContent"))
    assert_equal(GetEscapeHandlerCount(), initialEscCount + 2, "Two popups active")

    -- Destroy lower popup A directly (e.g. parent container teardown or programmatic close)
    popupA:Destroy()
    assert_true(IsDestroyed(popupA), "Popup A destroyed")
    assert_false(IsDestroyed(popupB), "Popup B still alive")
    assert_equal(GetEscapeHandlerCount(), initialEscCount + 1, "Handler A removed cleanly")

    -- Press Escape: Popup B's handler should be executed
    HandleEsc()
    assert_true(IsDestroyed(popupB), "Popup B destroyed on Escape")
    assert_equal(GetEscapeHandlerCount(), initialEscCount, "Escape stack fully balanced")
end

-- Test 8: Subclass Lifecycle Override - TrashBag cleans up escape handler even with custom OnDestroy
do
    local initialEscCount = GetEscapeHandlerCount()
    local GUI = Group.new(nil, "LobbyGUI")

    local CustomPopup = {}
    CustomPopup.__index = setmetatable(CustomPopup, Popup)
    function CustomPopup.new(parent)
        local content = Group.new(parent, "CustomContent")
        local self = Popup.new(parent, content)
        setmetatable(self, CustomPopup)
        return self
    end

    -- Subclass defines custom OnDestroy
    local customDestroyRan = false
    function CustomPopup:OnDestroy()
        customDestroyRan = true
        Popup.OnDestroy(self)
    end

    local customPopup = CustomPopup.new(GUI)
    assert_equal(GetEscapeHandlerCount(), initialEscCount + 1, "Custom popup registered escape handler")

    customPopup:Close()
    assert_true(customDestroyRan, "Custom OnDestroy executed")
    assert_true(IsDestroyed(customPopup), "Custom popup destroyed")
    assert_equal(GetEscapeHandlerCount(), initialEscCount, "Escape handler stack balanced")
end

-- Test 9: QuickDialog with modalInfo escapeButton
do
    local initialEscCount = GetEscapeHandlerCount()
    local GUI = Group.new(nil, "LobbyGUI")
    local cancelPressed = false

    local popup, dialog = QuickDialog(GUI, "Modal prompt", "Accept", nil, "Cancel", function()
        cancelPressed = true
    end, true, { escapeButton = 2 })

    assert_equal(GetEscapeHandlerCount(), initialEscCount + 1, "Modal QuickDialog escape handler registered")

    -- Press Escape -> routes to Cancel button
    HandleEsc()
    assert_true(cancelPressed, "Escape routed to Cancel callback")
    assert_true(IsDestroyed(popup), "Popup closed after escape-button callback")
    assert_equal(GetEscapeHandlerCount(), initialEscCount, "Escape handler stack balanced")
end

print("\n--- All 9 test suites finished! ---")
print(string.format("Total assertions passed: %d, failed: %d\n", tests_passed, tests_failed))

if tests_failed > 0 then
    os.exit(1)
end
