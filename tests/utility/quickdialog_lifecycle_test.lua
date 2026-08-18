-- Unit test and regression suite for QuickDialog / Popup lifetime & Launch re-entrancy
-- Simulates Moho UI object hierarchy, EscapeHandler, and Lobby launch sequence.

local tests_failed = 0
local tests_passed = 0

local function assert_true(cond, msg)
    if not cond then
        tests_failed = tests_failed + 1
        local err = "FAIL: " .. (msg or "assertion failed")
        print(err)
        error(err, 2)
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
        error(err, 2)
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
end
local function PopEscapeHandler()
    if #escapeHandlers == 0 then
        error("EscapeHandler stack underflow / popped when empty!", 2)
    end
    return table.remove(escapeHandlers)
end
local function GetEscapeHandlerCount()
    return #escapeHandlers
end

local function IsDestroyed(control)
    return not control or control._destroyed == true
end

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
        self._parent = parent
        table.insert(parent._children, self)
    end
    return self
end

function Control:Destroy()
    if self._destroyed then
        error("Native crash / Assertion failed: Double-destroy on " .. tostring(self.debugname), 2)
    end
    self._destroyed = true
    -- Recursively destroy children in Moho C++ engine
    for _, child in ipairs(self._children) do
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
-- Fixed Popup Implementation (matching lua/ui/controls/popups/popup.lua)
-- ============================================================================

local Popup = {}
Popup.__index = setmetatable(Popup, Group)

function Popup.new(parent, content)
    local self = Group.new(parent, "Popup")
    setmetatable(self, Popup)
    self.content = content
    content._parent = self
    table.insert(self._children, content)

    PushEscapeHandler(function()
        PopEscapeHandler()
        self:OnEscapePressed()
    end)
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
        PopEscapeHandler()
    end
end

function Popup:OnDestroy()
    self:OnClosed()
end

function Popup:OnEscapePressed()
    self:Close()
end

-- ============================================================================
-- Fixed QuickDialog Implementation (matching lua/ui/uiutil.lua)
-- ============================================================================

local function QuickDialog(parent, dialogText, button1Text, button1Callback, button2Text, button2Callback, destroyOnCallback)
    if destroyOnCallback == nil then
        destroyOnCallback = true
    end

    local dialog = Group.new(parent, "quickDialogGroup")
    local popup = Popup.new(parent, dialog)

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
                end
            end
        else
            button.OnClick = function(self)
                if self._clicked then return end
                self._clicked = true
                self:Disable()

                if not IsDestroyed(popup) then
                    popup:Close()
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

    return popup, dialog
end

-- ============================================================================
-- Tests
-- ============================================================================

print("--- Running QuickDialog & Popup Lifecycle Tests ---")

-- Test 1: Standard open & close
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

-- Test 2: Fixed QuickDialog - callback destroys parent GUI without crashing or double-destroy
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
    local status, err = pcall(function()
        dialog._button1:OnClick()
    end)

    assert_true(status, "Fixed QuickDialog handles parent destruction cleanly without crashing")
    assert_equal(launchCount, 1, "TryLaunch called once")
    assert_true(IsDestroyed(GUI), "GUI destroyed")
    assert_true(IsDestroyed(popup), "Popup destroyed")
    assert_equal(GetEscapeHandlerCount(), initialEscCount, "Escape handler stack cleanly balanced")
end

-- Test 3: Fixed QuickDialog - Button is one-shot and ignores rapid double clicks
do
    local initialEscCount = GetEscapeHandlerCount()
    local GUI = Group.new(nil, "LobbyGUI")
    local actionCount = 0

    local popup, dialog = QuickDialog(GUI, "Are you sure?", "Yes", function()
        actionCount = actionCount + 1
    end, "No", nil, false)

    -- First click
    dialog._button1:OnClick()
    assert_true(dialog._button1:IsDisabled(), "Button is disabled on first click")
    assert_equal(actionCount, 1, "Action called on first click")

    -- Rapid second click
    dialog._button1:OnClick()
    assert_equal(actionCount, 1, "Action NOT called on second click")

    popup:Close()
    assert_equal(GetEscapeHandlerCount(), initialEscCount, "Escape handlers restored")
end

-- Test 4: Lobby TryLaunch re-entrancy guard test
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

        if launchInProgress then
            return
        end
        launchInProgress = true
        GUI.launchGameButton:Disable()

        kickCount = kickCount + 1
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

print("\n--- All 4 test suites passed successfully! ---")
print(string.format("Total assertions passed: %d, failed: %d\n", tests_passed, tests_failed))
