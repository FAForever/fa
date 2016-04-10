local KeyMapper = import('/lua/keymap/keymapper.lua')
local UIUtil = import('/lua/ui/uiutil.lua')
local Prefs = import('/lua/user/prefs.lua')

local CommandMode = import('/lua/ui/game/commandmode.lua')
local Construction = import('/lua/ui/game/construction.lua')
local Templates = import('/lua/ui/game/build_templates.lua')

local Group = import('/lua/maui/group.lua').Group
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Effect = import('/lua/maui/effecthelpers.lua')

local upgradeTab = import('/modules/upgradeTab.lua').upgradeTab

local buildingTab
local cyclePos
local cycleThread = false
local cycleLastName
local cycleLastMaxPos
local cycleButtons = {}

local modifiersKeys = {}

function initCycleButtons(values)
  local buttonH = 48
  local buttonW = 48

  -- Delete old ones
  for _, button in cycleButtons do
    button:Destroy()
  end

  cycleButtons = {}
  local i = 1
  for i_whatever, value in values do
    cycleButtons[i] = Bitmap(cycleMap, UIUtil.SkinnableFile('/icons/units/' .. value .. '_icon.dds'))
    cycleButtons[i].Height:Set(buttonH)
    cycleButtons[i].Width:Set(buttonW)
    cycleButtons[i].Depth:Set(1002)
    LayoutHelpers.AtLeftTopIn(cycleButtons[i], cycleMap, 29 + buttonH * (i-1), 18)
    i=i+1
  end
  
  cycleMap.Height:Set(buttonH + 36)
  cycleMap.Width:Set((i-1) * buttonH + 58)
  cycleMap:DisableHitTest(true)
end

function initCycleMap()
  cycleMap = Group(GetFrame(0))
  
  cycleMap.Depth:Set(1000) --always on top
  cycleMap.Width:Set(400)
  cycleMap.Height:Set(150)
  cycleMap.Top:Set(function() return GetFrame(0).Bottom()*.75 end)
  cycleMap.Left:Set(function() return (GetFrame(0).Right()-cycleMap.Width())/2  end)
  cycleMap:DisableHitTest()
  cycleMap:Hide()
    
  cycle_Panel_tl = Bitmap(cycleMap)
  cycle_Panel_tl:SetTexture('/textures/ui/hotbuild/cycle-panel-bg-tl.dds')
  cycle_Panel_tl.Top:Set(cycleMap.Top)
  cycle_Panel_tl.Left:Set(cycleMap.Left)
  cycle_Panel_tl.Width:Set(40)
  
  cycle_Panel_bl = Bitmap(cycleMap)
  cycle_Panel_bl:SetTexture('/textures/ui/hotbuild/cycle-panel-bg-bl.dds')
  cycle_Panel_bl.Bottom:Set(cycleMap.Bottom)
  cycle_Panel_bl.Left:Set(cycleMap.Left)
  cycle_Panel_bl.Width:Set(40)
    
  cycle_Panel_l = Bitmap(cycleMap)
  cycle_Panel_l:SetTexture('/textures/ui/hotbuild/cycle-panel-bg-l.dds')
  cycle_Panel_l.Top:Set(cycle_Panel_tl.Bottom)
  cycle_Panel_l.Bottom:Set(cycle_Panel_bl.Top)
  cycle_Panel_l.Left:Set(cycleMap.Left)
  cycle_Panel_l.Width:Set(40)

  cycle_Panel_tr = Bitmap(cycleMap)
  cycle_Panel_tr:SetTexture('/textures/ui/hotbuild/cycle-panel-bg-tr.dds')
  cycle_Panel_tr.Top:Set(cycleMap.Top)
  cycle_Panel_tr.Right:Set(cycleMap.Right)
  cycle_Panel_tr.Width:Set(40)
  
  cycle_Panel_br = Bitmap(cycleMap)
  cycle_Panel_br:SetTexture('/textures/ui/hotbuild/cycle-panel-bg-br.dds')
  cycle_Panel_br.Bottom:Set(cycleMap.Bottom)
  cycle_Panel_br.Right:Set(cycleMap.Right)
  cycle_Panel_br.Width:Set(40)
  
  cycle_Panel_r = Bitmap(cycleMap)
  cycle_Panel_r:SetTexture('/textures/ui/hotbuild/cycle-panel-bg-r.dds')
  cycle_Panel_r.Top:Set(cycle_Panel_tr.Bottom)
  cycle_Panel_r.Bottom:Set(cycle_Panel_br.Top)
  cycle_Panel_r.Right:Set(cycleMap.Right)
  cycle_Panel_r.Width:Set(40)
  
  cycle_Panel_t = Bitmap(cycleMap)
  cycle_Panel_t:SetTexture('/textures/ui/hotbuild/cycle-panel-bg-t.dds')
  cycle_Panel_t.Top:Set(cycleMap.Top)
  cycle_Panel_t.Left:Set(cycle_Panel_l.Right)
  cycle_Panel_t.Right:Set(cycle_Panel_r.Left)
  
  cycle_Panel_b = Bitmap(cycleMap)
  cycle_Panel_b:SetTexture('/textures/ui/hotbuild/cycle-panel-bg-b.dds')
  cycle_Panel_b.Bottom:Set(cycleMap.Bottom)
  cycle_Panel_b.Left:Set(cycle_Panel_l.Right)
  cycle_Panel_b.Right:Set(cycle_Panel_r.Left)
  
  cycle_Panel_m = Bitmap(cycleMap)
  cycle_Panel_m:SetTexture('/textures/ui/hotbuild/cycle-panel-bg-m.dds')
  cycle_Panel_m.Top:Set(cycle_Panel_t.Bottom)
  cycle_Panel_m.Bottom:Set(cycle_Panel_b.Top)
  cycle_Panel_m.Left:Set(cycle_Panel_l.Right)
  cycle_Panel_m.Right:Set(cycle_Panel_r.Left)
end

---- End of Initialize functions

function resetCycle(commandMode, modeData)
  --LOG("ResetCycle cm: " .. repr(commandMode) .. " data: " .. repr(modeData))
  -- Commandmode = false is when a building is built (left click with mouse)
  -- modeData.isCancel = false is when building is aborted by a right click... whyever
  -- modeData.isCancel = true when "canceling" by releasing shift
  if ((commandMode == false) or (modeData.isCancel == false)) then
    cyclePos = 0
  -- Set to 0, first one is 1 but it will be incremented!
  end
end

---- Non state changing getters
function getBuildingTab()
  local btSource = import('/modules/buildingtab.lua').buildingTab
  local buildingTab = {}
  for name, values in btSource do
    buildingTab[name] = {}
    for i, value in values do
      if (nil ~= __blueprints[value]) then
        table.insert(buildingTab[name], value)
      elseif (nil ~= btSource[value]) then
        for i, realValue in btSource[value] do
          if (nil ~= __blueprints[realValue]) then
            table.insert(buildingTab[name], realValue)
          else
            LOG("!!!!! Invalid indirect building value " .. value .. " -> " .. realValue)
          end
        end
      elseif (value == '_upgrade' or value == '_templates') then
        table.insert(buildingTab[name], value)
      else
        LOG("!!!!! Invalid building value " .. value)
      end
    end
  end
  return buildingTab
end

function addModifiers()
  modifiersKeys = {}
  -- Adding modifiers shorcuts on the fly.
  local currentKeyMap = import('/lua/keymap/keymapper.lua').GetKeyMappings()
    for key, action in currentKeyMap do
      if action["category"] == "hotbuilding" then
        if key != nil then
            if not import('/lua/keymap/keymapper.lua').IsKeyInMap("Shift-" .. key, currentKeyMap) then
                modifiersKeys["Shift-" .. key] = action
            else
                WARN("Shift-" .. key .. " is already bind")
            end
            
            if not import('/lua/keymap/keymapper.lua').IsKeyInMap("Alt-" .. key, currentKeyMap) then
                modifiersKeys["Alt-" .. key] = action
            else
                WARN("Alt-" .. key .. " is already bind")
            end    
        end
      end
    end  
    IN_AddKeyMapTable(modifiersKeys)
end

function init()
  buildingTab = getBuildingTab()
  initCycleMap()
  CommandMode.AddEndBehavior(resetCycle)  
end

---- The actual key action callback
function buildAction(name)
  modifier = ""
  if IsKeyDown("Shift") then
    modifier = "Shift"
  elseif IsKeyDown("Alt") then
    modifier = "Alt"
  end

  --LOG("---> buildAction " .. name .. " modifier: " .. modifier)
  local selection = GetSelectedUnits()
  if selection then
    --if current selection is engineer (includes commander)
    if table.getsize(EntityCategoryFilterDown(categories.ENGINEER, selection)) > 0 then 
      buildActionBuilding(name, modifier)
    else -- buildqueue or normal applying all the command
      buildActionUnit(name, modifier)
    end
  end
end

-- Some of the work here is redundant when cycle_preview is disabled
function buildActionBuilding(name, modifier)
  --LOG("BAB " .. name)
  local options = Prefs.GetFromCurrentProfile('options')
  local allValues = buildingTab[name]
  --LOG(repr(allValues))
  local effectiveValues = {}
  
 if (table.find(allValues, "_templates")) then
    return buildActionTemplate(modifier)
  end
  
  -- Reset everything that could be fading or running  
  hideCycleMap()

  -- filter the values
  local selection=GetSelectedUnits()
  local availableOrders,  availableToggles, buildableCategories = GetUnitCommandData(selection)
  local buildable = EntityCategoryGetUnitList(buildableCategories)
  for i1, value in allValues do
    for i2, buildableValue in buildable do
      if value == buildableValue then
        table.insert(effectiveValues, value)
      end
    end
  end
  
  local maxPos = table.getsize(effectiveValues)
  if (maxPos == 0) then
    return
  end
  
  -- Check if the selection/key has changed
  if ((cycleLastName == name) and (cycleLastMaxPos == maxPos)) then
    cyclePos = cyclePos + 1
    if(cyclePos > maxPos) then
      cyclePos = 1
    end
  else
    initCycleButtons(effectiveValues)
    cyclePos = 1
    cycleLastName = name
    cycleLastMaxPos = maxPos
  end
  
  if (options.hotbuild_cycle_preview == 1) then
    -- Highlight the active button
    for i, button in cycleButtons do
      if (i == cyclePos) then
        button:SetAlpha(1, true)
      else
        button:SetAlpha(0.4, true)
      end
    end
  
    cycleMap:Show()
    -- Start the fading thread  
    cycleThread = ForkThread(function()
		stayTime = options.hotbuild_cycle_reset_time / 2000.0;
		fadeTime = options.hotbuild_cycle_reset_time / 2000.0;
		
        WaitSeconds(stayTime)
        if (not cycleMap:IsHidden()) then
          Effect.FadeOut(cycleMap, fadeTime, 0.6, 0.1)
        end
        WaitSeconds(fadeTime)
        cyclePos = 0
      end)
  else
      cycleThread = ForkThread(function()
		WaitSeconds(options.hotbuild_cycle_reset_time / 1000.0);
        cyclePos = 0
      end)
  end
    
  local cmd = effectiveValues[cyclePos]
  -- LOG("StartCommandMode:" .. cmd)
  ClearBuildTemplates()
  CommandMode.StartCommandMode("build", {name = cmd})
end


-- Some of the work here is redundant when cycle_preview is disabled
function buildActionTemplate(modifier)
  local options = Prefs.GetFromCurrentProfile('options')
  -- Reset everything that could be fading or running  
  -- LOG("BAT")
  hideCycleMap()

  -- find all avaiable templates
  local effectiveTemplates = {}
  local effectiveIcons = {}
  local allTemplates = Templates.GetTemplates()

  if (not allTemplates) or table.getsize(allTemplates) == 0 then
    return
  end
  
  local selection = GetSelectedUnits()
  local availableOrders,  availableToggles, buildableCategories = GetUnitCommandData(selection)
  local buildableUnits = EntityCategoryGetUnitList(buildableCategories)
  --Allow all races to build other races templates
  local currentFaction = selection[1]:GetBlueprint().General.FactionName
  if options.gui_all_race_templates != 0 and currentFaction then
    local function ConvertID(BPID)
      local prefixes = {
        ["AEON"]     = {"uab", "xab", "dab",},
        ["UEF"]      = {"ueb", "xeb", "deb",},
        ["CYBRAN"]   = {"urb", "xrb", "drb",},
        ["SERAPHIM"] = {"xsb", "usb", "dsb",},
      }
      for i, prefix in prefixes[string.upper(currentFaction)] do
        if table.find(buildableUnits, string.gsub(BPID, "(%a+)(%d+)", prefix .. "%2")) then
          return string.gsub(BPID, "(%a+)(%d+)", prefix .. "%2")
        end
      end
      return false
    end
    for templateIndex, template in allTemplates do
      local valid = true
      local converted = false
      for _, entry in template.templateData do
        if type(entry) == 'table' then
          if not table.find(buildableUnits, entry[1]) then
            entry[1] = ConvertID(entry[1])
            converted = true
            if not table.find(buildableUnits, entry[1]) then
              valid = false
              break
            end
          end
        end
      end
      if valid then
        if converted then
          template.icon = ConvertID(template.icon)
        end
        template.templateID = templateIndex
        table.insert(effectiveTemplates, template)
		  table.insert(effectiveIcons, template.icon)
      end
    end
  else
    for templateIndex, template in allTemplates do
      local valid = true
      for _, entry in template.templateData do
        if type(entry) == 'table' then
          if not table.find(buildableUnits, entry[1]) then
            valid = false
            break
          end
        end
      end
      if valid then
        template.templateID = templateIndex
        table.insert(effectiveTemplates, template)
		    table.insert(effectiveIcons, template.icon)
      end
    end
  end
  
  local maxPos = table.getsize(effectiveTemplates)
  if (maxPos == 0) then
    return
  end
  
  -- Check if the selection/key has changed
  if ((cycleLastName == '_templates') and (cycleLastMaxPos == maxPos)) then
    cyclePos = cyclePos + 1
    if(cyclePos > maxPos) then
      cyclePos = 1
    end
  else
    initCycleButtons(effectiveIcons)
    cyclePos = 1
    cycleLastName = '_templates'
    cycleLastMaxPos = maxPos
  end
  
  
  if (options.hotbuild_cycle_preview == 1) then
    -- Highlight the active button
    for i, button in cycleButtons do
      if (i == cyclePos) then
        button:SetAlpha(1, true)
      else
        button:SetAlpha(0.4, true)
      end
    end
  
    cycleMap:Show()
    -- Start the fading thread  
    cycleThread = ForkThread(function()
		stayTime = options.hotbuild_cycle_reset_time / 2000.0;
		fadeTime = options.hotbuild_cycle_reset_time / 2000.0;
		
        WaitSeconds(stayTime)
        if (not cycleMap:IsHidden()) then
          Effect.FadeOut(cycleMap, fadeTime, 0.6, 0.1)
        end
        WaitSeconds(fadeTime)
        cyclePos = 0
      end)
  else
      cycleThread = ForkThread(function()
		WaitSeconds(options.hotbuild_cycle_reset_time / 1000.0);
        cyclePos = 0
      end)
  end
    
  local template = effectiveTemplates[cyclePos]
  local cmd = template.templateData[3][1]

  -- LOG("BAT cmd: " .. cmd .. " tplD: " .. repr(template.templateData))

  ClearBuildTemplates()
  CommandMode.StartCommandMode("build", {name = cmd})
  SetActiveBuildTemplate(template.templateData)

  if options.gui_template_rotator != 0 then
    -- rotating templates
    local worldview = import('/lua/ui/game/worldview.lua').viewLeft
    local oldHandleEvent = worldview.HandleEvent
    worldview.HandleEvent = function(self, event)
        if event.Type == 'ButtonPress' then
            if event.Modifiers.Middle then
                ClearBuildTemplates()
                local tempTemplate = table.deepcopy(template.templateData)
                for i = 3, table.getn(template.templateData) do
                    local index = i
                    template.templateData[index][3] = 0 - tempTemplate[index][4]
                    template.templateData[index][4] = tempTemplate[index][3]
                end
                SetActiveBuildTemplate(template.templateData)
            elseif event.Modifiers.Shift then
            else
                worldview.HandleEvent = oldHandleEvent
            end
        end
    end
  end

end


function hideCycleMap()
  if (cycleThread) then
    KillThread(cycleThread)
  end

  cycleMap:SetNeedsFrameUpdate(false)
  cycleMap.OnFrame = function(self, elapsedTime)
                     end 
  cycleMap:Hide();
  cycleMap:SetAlpha(1, true)
end

function buildActionUnit(name, modifier)
  local values = buildingTab[name]
  
  -- Try to delete old units except for the one currently in construction
  if (modifier == 'Alt') then
    local currentCommandQueue = Construction.getCurrentCommandQueue()
    if (currentCommandQueue) then
      for index = table.getn(currentCommandQueue), 1, -1  do
        local count = currentCommandQueue[index].count
        if (index == 1) then
          count = count - 1
        end
        DecreaseBuildCountInQueue(index, count)
      end
    end
  end
  
  for i, v in values do
    if (v == '_upgrade') then
      return buildActionUpgrade()
    end
  end
  local count = 1
  if (modifier == 'Shift') then
    count = 5
  end
  
  local selectedUnits = GetSelectedUnits()
  local availableOrders,  availableToggles, buildableCategories = GetUnitCommandData(selectedUnits)
  local buildable = EntityCategoryGetUnitList(buildableCategories)

  for i, v in values do
    for ii, ba in buildable do
      if (v == ba) then
        IssueBlueprintCommand("UNITCOMMAND_BuildFactory", v, count)
      end
    end
  end
end


-- Does not upgrade T1 facs that are currently upgrading to T2 to T3 when issued
function buildActionUpgrade()
  local selectedUnits = GetSelectedUnits()
  local availableOrders,  availableToggles, buildableCategories = GetUnitCommandData(selectedUnits)
  --local buildable = EntityCategoryGetUnitList(buildableCategories)
  local bpTypes = {}

  for index, unit in selectedUnits do
    local bpId = unit:GetBlueprint().BlueprintId
    -- LOG("bpid: " .. bpId)
    local cmd = upgradeTab[bpId]
    SelectUnits({unit})
    if(type(cmd) == "table") then -- Issue the first upgrade command that we may build
        for k,v in cmd do
            if EntityCategoryContains(buildableCategories, v) then
                IssueBlueprintCommand("UNITCOMMAND_Upgrade", v, 1, false)
                break
            end
        end
    elseif (type(cmd) == "string") then -- Direct upgrade path
      -- LOG("upgrading: " .. repr(unit) .. " with cmd: " .. cmd)
      if EntityCategoryContains(buildableCategories, cmd) then
          IssueBlueprintCommand("UNITCOMMAND_Upgrade", cmd, 1, false)
      end
    end
  end
  SelectUnits(selectedUnits)
end
