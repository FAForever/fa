-- The replay viewer's timeline: a bar at the bottom of the screen, hidden until the mouse is at that edge, Ctrl-T
-- pins it or a move is under way, and a status strip above it while the replay moves to a chosen time. The engine does
-- the moving (ReplaySeek) behind this session, so the view, this UI and this file all stay.

local UIUtil = import('/lua/ui/uiutil.lua')
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Group = import('/lua/maui/group.lua').Group
local FlatPanel = import('/lua/ui/controls/flat_panel.lua')
local FlatProgress = import('/lua/ui/controls/flat_progress.lua').FlatProgress
local FlatTextButton = import('/lua/ui/controls/flat_text_button.lua').FlatTextButton
local Scrubber = import('/lua/ui/game/replay_scrubber.lua').Scrubber

local kBarWidth = 900
local kBarHeight = 34
local kBarBottom = 10
local kBarDepth = 9500
local kLabelSpace = 64
local kBottomEdge = 48
local kFadeSeconds = 0.12
local kKeyframeRefreshSeconds = 1
local kToggleKey = 'Ctrl-T'

local bar = false
local status = false
local watcher = false
local pinned = false

local function FormatTicks(ticks)
    local seconds = math.floor(math.max(ticks or 0, 0) / 10)
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor(math.mod(seconds, 3600) / 60)
    if hours > 0 then
        return string.format("%d:%02d:%02d", hours, minutes, math.mod(seconds, 60))
    end
    return string.format("%02d:%02d", minutes, math.mod(seconds, 60))
end

--- Moves the replay to a tick, either way, keeping the view.
function Seek(tick)
    ReplaySeek(math.floor(tick))
end

--- Before a new sim's first beat. Its units are new objects under the same ids, and FAF's ACU icons look units up
--- by id, so they would go on using the old ones; a change of focus army is what drops them.
function OnSimReplaced()
    import('/lua/ui/game/avatars.lua').FocusArmyChanged()
    import('/lua/ui/notify/notify.lua').KillAllWatchers()
end

--- Esc, before anything else it does: true when it stopped a move, or has to wait as the sim is being replaced.
function OnEscape()
    local progress = bar and ReplaySeekProgress()
    if not progress then
        return false
    end
    if not progress.restarting then
        ReplayCancelSeek()
    end
    return true
end

--- The hotkey: keeps the bar shown, or leaves it to the mouse again.
function Toggle()
    pinned = not pinned
end

local function CreateStatus(parent, anchor)
    local panel = FlatPanel.FlatPanel(parent, "ReplaySeekStatus")
    LayoutHelpers.SetDimensions(panel, 340, 46)
    LayoutHelpers.AtHorizontalCenterIn(panel, parent)
    panel.Bottom:Set(function() return anchor.Top() - LayoutHelpers.ScaleNumber(8) end)
    panel.Depth:Set(kBarDepth + 20)

    local title = UIUtil.CreateText(panel, "", 13, UIUtil.bodyFont)
    title:SetColor(UIUtil.fontColor())
    LayoutHelpers.AtLeftTopIn(title, panel, 12, 8)
    title.Depth:Set(function() return panel.Depth() + 3 end)

    local cancel = FlatTextButton(panel, LOC("<LOC _Cancel>Cancel"), 12)
    LayoutHelpers.AtRightIn(cancel, panel, 6)
    cancel.Top:Set(function() return panel.Top() + LayoutHelpers.ScaleNumber(5) end)
    cancel.Depth:Set(function() return panel.Depth() + 3 end)
    cancel.OnClick = function()
        ReplayCancelSeek()
    end

    local detail = UIUtil.CreateText(panel, "", 12, UIUtil.bodyFont)
    detail:SetColor(UIUtil.highlightColor())
    detail.Right:Set(function() return cancel.Left() - LayoutHelpers.ScaleNumber(4) end)
    detail.Top:Set(function() return panel.Top() + LayoutHelpers.ScaleNumber(9) end)
    detail.Depth:Set(function() return panel.Depth() + 3 end)

    local progressLine = FlatProgress(panel)
    LayoutHelpers.AtLeftIn(progressLine, panel, 12)
    LayoutHelpers.AtRightIn(progressLine, panel, 12)
    LayoutHelpers.SetHeight(progressLine, 3)
    LayoutHelpers.AtBottomIn(progressLine, panel, 9)
    progressLine.Depth:Set(function() return panel.Depth() + 3 end)

    panel.Update = function(self, progress, delta)
        local back = progress.targetTick < progress.currentTick
        if progress.restarting then
            title:SetText(LOCF("%s %s", back and "Going back to" or "Going to", FormatTicks(progress.targetTick)))
            detail:SetText("")
            progressLine:Sweep(delta)
            FlatPanel.SetVisible(cancel, false)
        else
            title:SetText(LOCF("%s %s", "Going to", FormatTicks(progress.targetTick)))
            detail:SetText(FormatTicks(progress.currentTick))
            progressLine:SetProgress(progress.progress)
            FlatPanel.SetVisible(cancel, true)
        end
    end

    panel:SetShown(false)
    return panel
end

function Create()
    if bar then
        return bar
    end
    local parent = GetFrame(0)

    bar = FlatPanel.FlatPanel(parent, "ReplayTimelineBar")
    bar.Width:Set(function() return math.min(parent.Width() - 40, LayoutHelpers.ScaleNumber(kBarWidth)) end)
    LayoutHelpers.SetHeight(bar, kBarHeight)
    LayoutHelpers.AtHorizontalCenterIn(bar, parent)
    LayoutHelpers.AtBottomIn(bar, parent, kBarBottom)
    bar.Depth:Set(kBarDepth)

    local current = UIUtil.CreateText(bar, "00:00", 13, UIUtil.bodyFont)
    current:SetColor(UIUtil.fontColor())
    LayoutHelpers.AtLeftIn(current, bar, 12)
    LayoutHelpers.AtVerticalCenterIn(current, bar)
    current:DisableHitTest()
    current.Depth:Set(function() return bar.Depth() + 3 end)

    local totalTicks = GetReplayTotalTicks()
    local total = UIUtil.CreateText(bar, totalTicks > 0 and FormatTicks(totalTicks) or "--:--", 13, UIUtil.bodyFont)
    total:SetColor(UIUtil.highlightColor())
    LayoutHelpers.AtRightIn(total, bar, 12)
    LayoutHelpers.AtVerticalCenterIn(total, bar)
    total:DisableHitTest()
    total.Depth:Set(function() return bar.Depth() + 3 end)

    local scrubber = Scrubber(bar, totalTicks, FormatTicks)
    scrubber.Left:Set(function() return bar.Left() + LayoutHelpers.ScaleNumber(kLabelSpace) end)
    scrubber.Right:Set(function() return bar.Right() - LayoutHelpers.ScaleNumber(kLabelSpace) end)
    scrubber.Width:Set(function() return scrubber.Right() - scrubber.Left() end)
    scrubber.Top:Set(bar.Top)
    scrubber.Bottom:Set(bar.Bottom)
    scrubber.Height:Set(function() return scrubber.Bottom() - scrubber.Top() end)
    scrubber.Depth:Set(function() return bar.Depth() + 4 end)
    scrubber.OnScrub = function(self, tick)
        current:SetText(FormatTicks(tick))
    end
    scrubber.OnSeek = function(self, tick)
        Seek(tick)
    end
    scrubber.SeekKind = function(self, tick)
        return ReplaySeekKind(tick)
    end

    status = CreateStatus(parent, bar)

    -- Its own control, as a hidden bar has to be able to come back.
    watcher = Group(parent, "ReplayTimelineWatcher")
    LayoutHelpers.SetDimensions(watcher, 1, 1)
    LayoutHelpers.AtLeftTopIn(watcher, parent)
    watcher:DisableHitTest()
    watcher:SetNeedsFrameUpdate(true)
    local untilKeyframeRefresh = 0
    local atBottom = false
    watcher.OnFrame = function(self, delta)
        local progress = ReplaySeekProgress()

        -- Off the world view, which includes over this bar, the height is NaN: the last one known stands.
        local mouseY = GetMouseScreenPos()[2]
        if mouseY == mouseY then
            atBottom = mouseY >= parent.Bottom() - LayoutHelpers.ScaleNumber(kBottomEdge)
        end
        bar:Fade(pinned or atBottom or scrubber:IsDragging() or progress != nil, delta, kFadeSeconds)

        local tick = GameTick()
        if not bar:IsHidden() then
            -- During a move the playhead stands at the target, and the scrubber marks where the replay really is.
            local playhead = progress and progress.targetTick or tick
            scrubber:Update(playhead, progress and progress.currentTick or tick)
            -- Once a second while the bar is shown.
            untilKeyframeRefresh = untilKeyframeRefresh - delta
            if untilKeyframeRefresh <= 0 then
                untilKeyframeRefresh = kKeyframeRefreshSeconds
                scrubber:SetKeyframes(GetReplayKeyframeTicks())
            end
            if not scrubber:IsDragging() then
                current:SetText(FormatTicks(playhead))
            end
        end

        status:Fade(progress != nil, delta, kFadeSeconds)
        if progress then
            status:Update(progress, delta)
        end
    end
    bar.OnDestroy = function()
        if status then
            status:Destroy()
            status = false
        end
        if watcher then
            watcher:Destroy()
            watcher = false
        end
        bar = false
    end

    -- The options screen sets these when changed; a game starts with the engine's defaults. GetOptions and not
    -- GetOption, which gives an unset option's default, and that would overwrite /con.
    local GetOptions = import('/lua/user/prefs.lua').GetOptions
    local budget = GetOptions('replay_keyframe_budget')
    if budget then
        ConExecute("replay_KeyframeMaxMB " .. tostring(budget))
    end
    local spacing = GetOptions('replay_keyframe_spacing')
    if spacing then
        ConExecute("replay_KeyframeEvery " .. tostring(math.floor(spacing) * 10))
    end
    local prepare = GetOptions('replay_keyframe_prepare')
    if prepare then
        ConExecute("replay_PrepareKeyframes " .. tostring(prepare))
    end

    bar:SetShown(false)
    IN_AddKeyMapTable({[kToggleKey] = {action = "UI_Lua import('/lua/ui/game/replay_timeline.lua').Toggle()"}})
    return bar
end

--- A reload of this file (the module manager in /lua/system/import.lua, when the file changes on disk): the old
--- module's bar goes, and the new module builds its own, keeping the pin. Without this the old bar stayed on screen
--- while Esc and the hotkey reached the new module, which had none.
local rebuild = false

function __moduleinfo.OnDirty()
    rebuild = bar ~= false
    if bar then
        bar:Destroy()
    end
    if rebuild then
        ForkThread(function()
            WaitFrames(2)
            import(__moduleinfo.name)
        end)
    end
end

--- A new module that failed to load (an error in the file) has no Create: the error is reported where it was imported.
function __moduleinfo.OnReload(newModule)
    if rebuild and rawget(newModule, 'Create') then
        newModule.Create()
        if pinned then
            newModule.Toggle()
        end
    end
end
