-- This file contains the functions which deal with creating and updating ETA overlay for ACU upgrades

local FindClients = import('/lua/ui/game/chat.lua').FindClients
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local UIUtil = import('/lua/ui/uiutil.lua')
local Prefs = import('/lua/user/prefs.lua')

local overlayDisabled
overlays = {}

function setOverlayDisabled(bool)
    overlayDisabled = bool
end

function getOverlayDisabled()
    return overlayDisabled
end

function toggleNotifyOverlay(args)
    if args[1] == 'enablenotifyoverlay' then
        overlayDisabled = false
        print 'Notify Overlay Enabled'
    elseif args[1] == 'disablenotifyoverlay' then
        overlayDisabled = true
        print 'Notify Overlay Disabled'
    end

    if not args[2] or args[2] ~= 'once' then
        Prefs.SetToCurrentProfile('Notify_Overlay_Disabled', overlayDisabled)
        Prefs.SavePreferences()
    end
end

-- This is called when we recieve a chat message from another player in the 'Notify' chat channel
-- These messages are generated below in onStartEnhancement
function processNotification(players, msg)
    local args = {}

    for word in string.gfind(msg.text, "%S+") do
        table.insert(args, word)
    end

    for _, k in {1, 3, 4, 5, 6, 7} do
        args[k] = tonumber(args[k])
    end

    if not overlayDisabled then
        updateEnhancementOverlay(args)
    end
end

function round(num, idp)
	if not idp then
		return tonumber(string.format("%." .. (idp or 0) .. "f", num))
	else
  		local mult = 10 ^ (idp or 0)
		return math.floor(num * mult + 0.5) / mult
  	end
end

function createEnhancementOverlay(id, pos)
	local overlay = Bitmap(GetFrame(0))

	overlay.Width:Set(100)
	overlay.Height:Set(50)
	overlay.id = id
	overlay.pos = pos
	overlay.lastUpdate = GameTick()

	overlay:SetNeedsFrameUpdate(true)
	overlay.OnFrame = function(self, delta)
		if GameTick() - overlay.lastUpdate > 1 then
			overlays[id] = nil
			overlay:Destroy()
			return
		end

		local worldView = import('/lua/ui/game/worldview.lua').viewLeft
		local pos = worldView:Project(Vector(overlay.pos.x, overlay.pos.z, overlay.pos.y))

		LayoutHelpers.AtLeftTopIn(overlay, worldView, pos.x - overlay.Width() / 2, pos.y - overlay.Height() / 2 + 1)
	end

	overlay.progress = UIUtil.CreateText(overlay, '0%', 12, UIUtil.bodyFont)
	overlay.progress:SetColor('white')
    overlay.progress:SetDropShadow(true)
	LayoutHelpers.AtCenterIn(overlay.progress, overlay, 15, 0)

	overlay.eta = UIUtil.CreateText(overlay, 'ETA', 10, UIUtil.bodyFont)
	overlay.eta:SetColor('white')
    overlay.eta:SetDropShadow(true)
	LayoutHelpers.AtCenterIn(overlay.eta, overlay, -15, 0)

	return overlay
end

function updateEnhancementOverlay(args)
	local id = args[1]
	local progress = args[2]
	local eta = args[3]
	local paused = args[4]
	local pos = {x = args[5], z = args[6], y = args[7]}

	if not overlays[id] then
		ForkThread(
            function()
                overlays[id] = createEnhancementOverlay(id, pos)
            end
		)
		return
	end

	local overlay = overlays[id]

    -- Update an existing overlay
	if overlay then
		overlay.progress:SetText(progress .. "%")
		if paused == 0 then
			eta = math.max(0, eta - GetGameTimeSeconds())
		end
		overlay.eta:SetText("ETA " .. string.format("%.2d:%.2d", eta / 60, math.mod(eta, 60)))
		overlay.pos = pos
		overlay.lastUpdate = GameTick()
	end
end

function generateEnhancementMessage(data)
    local unit = data.unit
    local pos = data.pos
    local buildTime = data.buildTime
    local msg = data.msg
    local lastTick = data.last_tick
    local lastProgress = data.last_progress

    local progress = unit:GetWorkProgress()

    local tick = GameTick()
    local seconds = GetGameTimeSeconds()

    -- Initial eta
    if not data.eta then
        data.eta = seconds + (buildTime / unit:GetBuildRate())
    end

    if GetIsPaused({unit}) then
        if lastTick ~= 0 then
            data.last_tick = 0
            data.last_progress = 0
            data.eta = math.max(0, data.eta - seconds)
        end
    elseif not lastTick or (tick - lastTick > 30) then
        if lastTick == 0 then
            data.eta = data.eta + seconds
        end
        if lastProgress and lastProgress ~= 0 then
            data.eta = round(seconds + ((tick - lastTick) / 10) * ((1 - progress) / (progress - lastProgress)))
        end

        data.last_tick = tick
        data.last_progress = progress
    end

    progress = math.floor((progress * 100) + 0.5)
    msg.text = data.id .. ' ' .. progress .. ' ' .. data.eta .. ' ' .. (GetIsPaused({unit}) and 1 or 0) .. ' ' .. pos[1] .. ' ' .. pos[2] ..  ' ' .. pos[3]
    SessionSendChatMessage(FindClients(), msg)
end
