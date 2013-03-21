local UIUtil = import('/lua/ui/uiutil.lua')
local gamemain = import('/lua/ui/game/gamemain.lua')
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Prefs = import('/lua/user/prefs.lua')
local Group = import('/lua/maui/group.lua').Group
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap

local skin = false
local currentskin = 'Default'
obj ={}
code={}

dis_play_good_bitmap=false

function end_skinning_process()
	--if true then return end
	for name,val in code do
		--LOG("==",val.obj.name)
		val.fct(val.obj)
	end
end

function reset_obj(object)
	local empty=UIUtil.UIFile('/hotstats/empty_sca.dds')
	object.part=0
	
	object:SetTexture(empty)
	
	if object.middle then object.middle:SetTexture(empty) end
		
	if object.left then object.left:SetTexture(empty) end	
	if object.right then object.right:SetTexture(empty)end	
	if object.top then object.top:SetTexture(empty) end
	if object.bottom then object.bottom:SetTexture(empty) end
		
	if object.topleft then object.topleft:SetTexture(empty) end
	if object.topright then object.topright:SetTexture(empty) end
	if object.bottomleft then object.bottomleft:SetTexture(empty) end
	if object.bottomright then object.bottomright:SetTexture(empty) end
end

function Set_Auto_9_Texture(name,object,parent,path, offsetTable)
	local list={topleft=name.."_tl.dds",top=name.."_t.dds",topright=name.."_tr.dds",
	left=name.."_l.dds",middle=name.."_m.dds",right=name.."_r.dds",
	bottomleft=name.."_bl.dds",bottom=name.."_b.dds",bottomright=name.."_br.dds"}
	return Set_Group_Texture(list,object,parent,path, nil, offsetTable)
end

function Set_Auto_3horiz_Texture(name,object,parent,path, offsetTable, centered)
	local list={left=name.."_l.dds",middle=name.."_m.dds",right=name.."_r.dds"}
	return Set_Group_Texture(list,object,parent,path, 'horizontal', offsetTable, centered)
end

function Set_Auto_3vert_Texture(name,object,parent,path, offsetTable, centered)
	local list={top=name.."_t.dds",middle=name.."_m.dds",bottom=name.."_b.dds"}
	return Set_Group_Texture(list,object,parent,path, 'vertical', offsetTable, centered)
end

function Set_Group_Texture(list,object,parent,path, grouptype, offsetTable, centered)
	if not Test_Files_ok(list,path) then
		return nil
	end
	if not object then
		object = Group(parent) 
		LayoutHelpers.FillParent(object, parent)
	end
	local value = 100
	reset_obj(object)
	
	if table.getsize(list) ==3 then
		if grouptype == 'horizontal' then
			if not(object.left) then object.left=Bitmap(object) end
			if not(object.middle) then object.middle=Bitmap(object) end
			if not(object.right) then object.right=Bitmap(object) end
			object.part=3
			object.middle:SetTexture(path..list.middle)
			object.left:SetTexture(path..list.left)
			object.right:SetTexture(path..list.right)
			
			if centered == 'centered' then
				LayoutHelpers.AtHorizontalCenterIn(object.middle, object)
				object.middle.Top:Set(object.Top)
				LayoutHelpers.ResetBottom(object.middle)

				LayoutHelpers.AtLeftIn(object.left, object)
				LayoutHelpers.AtTopIn(object.left, object)
				object.left.Right:Set(object.middle.Left)
				LayoutHelpers.ResetBottom(object.left)
				
				LayoutHelpers.AtRightIn(object.right, object)
				LayoutHelpers.AtTopIn(object.right, object)
				object.right.Left:Set(object.middle.Right)
				LayoutHelpers.ResetBottom(object.right)
			elseif centered == 'bottom' then
				LayoutHelpers.AtLeftIn(object.left, object, offsetTable.Left)
				LayoutHelpers.AtBottomIn(object.left, object, offsetTable.Bottom)
				LayoutHelpers.ResetRight(object.left)
				LayoutHelpers.ResetTop(object.left)
				
				LayoutHelpers.AtRightIn(object.right, object, offsetTable.Right)
				LayoutHelpers.AtBottomIn(object.right, object, offsetTable.Bottom)
				LayoutHelpers.ResetLeft(object.right)
				LayoutHelpers.ResetTop(object.right)

				object.middle.Left:Set(object.left.Right)
				object.middle.Right:Set(object.right.Left)
				LayoutHelpers.AtBottomIn(object.middle, object, offsetTable.Bottom)
				LayoutHelpers.ResetTop(object.middle)
			else
				LayoutHelpers.AtLeftIn(object.left, object, offsetTable.Left)
				LayoutHelpers.AtTopIn(object.left, object, offsetTable.Top)
				LayoutHelpers.ResetRight(object.left)
				LayoutHelpers.ResetBottom(object.left)
				
				LayoutHelpers.AtRightIn(object.right, object, offsetTable.Right)
				LayoutHelpers.AtTopIn(object.right, object, offsetTable.Top)
				LayoutHelpers.ResetLeft(object.right)
				LayoutHelpers.ResetBottom(object.right)

				object.middle.Left:Set(object.left.Right)
				object.middle.Right:Set(object.right.Left)
				LayoutHelpers.AtTopIn(object.middle, object, offsetTable.Top)
				LayoutHelpers.ResetBottom(object.middle)
			end
			LayoutHelpers.ResetBottom(object)
			if list.Tiled != nil and list.Tiled then object.middle:SetTiled(true) end
			object.Width:Set(function() return object.right.Right()-object.left.Left() end)
			object.Height:Set(function() return object.middle.Bottom()-object.middle.Top() end)
		else
			if not(object.top) then object.top=Bitmap(object) end
			if not(object.middle) then object.middle=Bitmap(object) end
			if not(object.bottom) then object.bottom=Bitmap(object) end
			object.part=3
			object.middle:SetTexture(path..list.middle)
			object.top:SetTexture(path..list.top)
			object.bottom:SetTexture(path..list.bottom)
			
			if centered == 'centered' then
				LayoutHelpers.AtVerticalCenterIn(object.middle, object)
				object.middle.Left:Set(object.Left)
				LayoutHelpers.ResetRight(object.middle)

				LayoutHelpers.AtLeftIn(object.top, object, offsetTable.Left)
				LayoutHelpers.AtTopIn(object.top, object, offsetTable.Top)
				LayoutHelpers.ResetRight(object.top)
				object.top.Bottom:Set(object.middle.Top)
				
				LayoutHelpers.AtLeftIn(object.bottom, object, offsetTable.Left)
				LayoutHelpers.AtBottomIn(object.bottom, object, offsetTable.Bottom)
				LayoutHelpers.ResetRight(object.bottom)
				object.bottom.Top:Set(object.middle.Bottom)
			elseif centered == 'right' then
				LayoutHelpers.AtRightIn(object.top, object, offsetTable.Right)
				LayoutHelpers.AtTopIn(object.top, object, offsetTable.Top)
				LayoutHelpers.ResetLeft(object.top)
				LayoutHelpers.ResetBottom(object.top)
				
				LayoutHelpers.AtRightIn(object.bottom, object, offsetTable.Right)
				LayoutHelpers.AtBottomIn(object.bottom, object, offsetTable.Bottom)
				LayoutHelpers.ResetLeft(object.bottom)
				LayoutHelpers.ResetTop(object.bottom)

				LayoutHelpers.AtRightIn(object.middle, object, offsetTable.Right)
				LayoutHelpers.ResetLeft(object.middle)
				object.middle.Top:Set(object.top.Bottom)
				object.middle.Bottom:Set(object.bottom.Top)
			else
				LayoutHelpers.AtLeftIn(object.top, object, offsetTable.Left)
				LayoutHelpers.AtTopIn(object.top, object, offsetTable.Top)
				LayoutHelpers.ResetRight(object.top)
				LayoutHelpers.ResetBottom(object.top)
				
				LayoutHelpers.AtLeftIn(object.bottom, object, offsetTable.Left)
				LayoutHelpers.AtBottomIn(object.bottom, object, offsetTable.Bottom)
				LayoutHelpers.ResetRight(object.bottom)
				LayoutHelpers.ResetTop(object.bottom)

				LayoutHelpers.AtLeftIn(object.middle, object, offsetTable.Left)
				LayoutHelpers.ResetRight(object.middle)
				object.middle.Top:Set(object.top.Bottom)
				object.middle.Bottom:Set(object.bottom.Top)
			end
			LayoutHelpers.ResetRight(object)
			if list.Tiled != nil and list.Tiled then object.middle:SetTiled(true) end
			object.Width:Set(function() return object.top.Right()-object.top.Left() end)
			object.Height:Set(function() return object.bottom.Bottom()-object.top.Top() end)
		end
	elseif table.getsize(list) ==9 then
		object.part=9
		--create bitmaps
		if not(object.middle) then object.middle=Bitmap(object) end		
		
		if not(object.left) then object.left=Bitmap(object) end
		if not(object.right) then object.right=Bitmap(object) end
		if not(object.top) then object.top=Bitmap(object) end
		if not(object.bottom) then object.bottom=Bitmap(object) end
		
		if not(object.topleft) then object.topleft=Bitmap(object) end
		if not(object.topright) then object.topright=Bitmap(object) end
		if not(object.bottomleft) then object.bottomleft=Bitmap(object) end
		if not(object.bottomright) then object.bottomright=Bitmap(object) end
		
		--set textures
		object.middle:SetTexture(path..list.middle)
		
		object.left:SetTexture(path..list.left)		
		object.right:SetTexture(path..list.right)		
		object.top:SetTexture(path..list.top)
		object.bottom:SetTexture(path..list.bottom)
		
		object.topleft:SetTexture(path..list.topleft)
		object.topright:SetTexture(path..list.topright)
		object.bottomleft:SetTexture(path..list.bottomleft)
		object.bottomright:SetTexture(path..list.bottomright)
		
		--layout bitmaps		
		--corners
		LayoutHelpers.AtLeftTopIn(object.topleft,object, offsetTable.Left, offsetTable.Top)
		LayoutHelpers.AtRightTopIn(object.topright,object, offsetTable.Right, offsetTable.Top)
		LayoutHelpers.AtLeftIn(object.bottomleft,object, offsetTable.Left)
		LayoutHelpers.AtBottomIn(object.bottomleft,object, offsetTable.Bottom)
		LayoutHelpers.AtRightIn(object.bottomright,object, offsetTable.Right)
		LayoutHelpers.AtBottomIn(object.bottomright,object, offsetTable.Bottom)
		
		--borders
		object.left.Top:Set(function() return object.topleft.Bottom() end)
		object.left.Bottom:Set(function() return object.bottomleft.Top() end)
		object.left.Left:Set(function() return object.Left() end)
		object.left.Right:Set(function() return object.Left() + object.left.BitmapWidth() end)
		if list.Tiled != nil and list.Tiled then object.left:SetTiled(true) end
		
		object.bottom.Top:Set(function() return object.Bottom() - object.bottom.BitmapHeight() end)
		object.bottom.Bottom:Set(function() return object.Bottom() end)
		object.bottom.Left:Set(function() return object.bottomleft.Right() end)
		object.bottom.Right:Set(function() return object.bottomright.Left() end)
		if list.Tiled != nil and list.Tiled then object.bottom:SetTiled(true) end
		
		object.top.Top:Set(function() return object.Top() end)
		object.top.Bottom:Set(function() return object.Top() + object.top.BitmapHeight() end)
		object.top.Left:Set(function() return object.topleft.Right() end)
		object.top.Right:Set(function() return object.topright.Left() end)
		if list.Tiled != nil and list.Tiled then object.top:SetTiled(true) end
		
		object.right.Top:Set(function() return object.topright.Bottom() end)
		object.right.Bottom:Set(function() return object.bottomright.Top() end)
		object.right.Left:Set(function() return object.Right() - object.right.BitmapWidth() end)
		object.right.Right:Set(function() return object.Right() end)
		if list.Tiled != nil and list.Tiled then object.right:SetTiled(true) end
		
		--center
		object.middle.Left:Set(function() return object.left.Right() end)
		object.middle.Right:Set(function() return object.right.Left() end)
		object.middle.Top:Set(function() return object.top.Bottom() end)
		object.middle.Bottom:Set(function() return object.bottom.Top() end)
		if list.Tiled != nil and list.Tiled then object.middle:SetTiled(true) end
		
		object.Width:Set(function() return object.right.Right()-object.left.Left() end)
		object.Height:Set(function() return object.bottom.Bottom()-object.top.Top() end)
		
	else
		WARN("Error trying to create a group of texture but not enough element (waiting 3 or 9, have "..table.getsize(list) )
		return nil
	end

	return object
end

function Set_Auto_Checkbox(name,object,parent,path)
	local list={up=name.."_up.dds", upsel=name.."_upsel.dds", over=name.."_over.dds", oversel=name.."_oversel.dds", dis=name.."_dis.dds", dissel=name.."_dissel.dds"}
	if Test_Files_ok(list,path) then
		--for resetting width/height
		object:SetTexture(path..list.up)
		object.Width:Set(object.BitmapWidth())
		object.Height:Set(object.BitmapHeight())

		object:SetNewTextures(path..list.up
			, path..list.upsel
			, path..list.over
			, path..list.oversel
			, path..list.dis
			, path..list.dissel)
	end

	return object
end

function Set_Auto_CheckboxButton(name,object,parent,path)
	local list={up=name.."_up.dds", upsel=name.."_down.dds", over=name.."_over.dds", oversel=name.."_over.dds", dis=name.."_dis.dds", dissel=name.."_dis.dds"}
	if Test_Files_ok(list,path) then
		--for resetting width/height
		object:SetTexture(path..list.up)
		object.Width:Set(object.BitmapWidth())
		object.Height:Set(object.BitmapHeight())

		object:SetNewTextures(path..list.up
			, path..list.upsel
			, path..list.over
			, path..list.oversel
			, path..list.dis
			, path..list.dissel)
	end

	return object
end

function Set_Auto_Button(name,object,parent,path)
	local list={over=name.."_over.dds",up=name.."_up.dds",down=name.."_down.dds",dis=name.."_dis.dds"}
	if Test_Files_ok(list,path) then 
		--for resetting width/height
		object:SetTexture(path..list.up)
		object.Width:Set(object.BitmapWidth())
		object.Height:Set(object.BitmapHeight())
		
		object:SetNewTextures(path..list.up
			, path..list.down
			, path..list.over
			, path..list.dis)
	end
	
	return object
end

function Set_Auto_Bitmap(name,object,parent,path)
	object:SetTexture(path..list.up)
	object.Width:Set(object.BitmapWidth())
	object.Height:Set(object.BitmapHeight())
end

function add_extension(files)
	local tmp=files
	if string.find(files,'.dds')== nil and string.find(files,'.png')==nil then
		tmp=tmp..".dds"
		LOG("Add extension to the files '".. files ..".")
	end
	return tmp
end

function Test_Files_ok(files,path)
	
	if type(files)=="string" then
		if DiskGetFileInfo(path..files) then 
--			if dis_play_good_bitmap then UIManager.Output_text("File "..path..files.." is correct !") end
		else
--			if UIManager.win then
--				UIManager.win:Show()
--			else
--				UIManager.Make_skin_info()
--			end
--			UIManager.Output_text("# ERROR - File "..path..files.." is not found.")
			return false
		end
	elseif type(files)=="table" then
		local tmp=""
		for i,v in files do
			tmp=v..","..tmp.." "
			if not DiskGetFileInfo(path..v) then 
--				if UIManager.win then
--					UIManager.win:Show()
--				else
--					UIManager.Make_skin_info()
--				end
--				UIManager.Output_text("# ERROR -  File "..path..v.." is not found (checked also the related file).")
				return false
			end
		end
--		if dis_play_good_bitmap then UIManager.Output_text("Files "..tmp .." in "..path.."are correct !") end
	end
	return true
end

 -- currentskin should AEON, UEF or CYBRAN or nil
function GetSkin(name,object,parent, modifiers)
	local full_name=name
	skin=import(GetActualSkinFile())
--	UIManager.Output_text("Skinning: " ..name.. ", "..modifiers )
	if object.grp then object.grp:Destroy() object.grp = false end
	if object.middle then reset_obj(object) end
--	if Prefs.GetFromCurrentProfile("uimanager_sav")["skin"] == 'Auto Faction' then
--		if uimod.factionTable[uimod.factionIndex] !=nil then
--			faction = uimod.factionTable[uimod.factionIndex]
--			currentskin = Prefs.GetFromCurrentProfile("uimanager_sav")[faction.."skin"]
--		else currentskin="Default" LOG("Bug intercepted in skinning") end
--	else
		currentskin = Prefs.GetFromCurrentProfile("uimanager_sav")["skin"]
--	end
	
	if currentskin == nil then currentskin = 'Default' end
	local skincheck = false
	for i, v in skin.skinlist do
		if v == currentskin then
			skincheck = true
		end
	end
	if not skincheck then
		currentskin = 'Default'
	end

	local factionnal=true --if true all faction have a different skin
	if name=="" or name==nil  then  
--		UIManager.Output_text("# ERROR - Empty name in the skin file!")
		return nil
	end
	if modifiers then full_name=name..":"..modifiers end
--	if object==nil or object==false then 	UIManager.Output_text("# WARNING - non existant object in ["..full_name.."] in the skin file ["..GetActualSkinFile().."].")	end

	local current=false
	local imgpath = false
	if modifiers then
		if factionnal and currentskin!=nil and currentskin!="" and skin[currentskin][name][modifiers] != nil then
			current=skin[currentskin][name][modifiers]
			imgpath = skin[currentskin].path
		elseif skin.Default[name][modifiers] != nil then
			current=skin.Default[name][modifiers]
			imgpath = skin.Default.path
		else
			return nil
		end
	else
		if factionnal and currentskin!=nil and currentskin!="" and skin[currentskin][name] != nil then
			current=skin[currentskin][name]
			imgpath = skin[currentskin].path
		elseif skin.Default[name] != nil then
			current=skin.Default[name]
			imgpath = skin.Default.path
		else
			return nil
		end
	end
	if parent==nil or parent==false then
--		UIManager.Output_text("# ERROR - non existant parent in ["..full_name.."] in the skin file ["..GetActualSkinFile().."].")
		return nil
	end
	
	local offsetTable = {Left = 0, Top = 0, Right = 0, Bottom = 0}
	if current.offsets then
		for i, v in current.offsets do
			offsetTable[i] = v
		end
	end
	if current.type=="9part" and  type(current.texture)=="string" then
		object=Set_Auto_9_Texture(current.texture,object,parent,imgpath, offsetTable)
		if object.Resizer then
			if current.sizelock then
				object.Resizer:SetSizeLock(true)
			else
				object.Resizer:SetSizeLock(false)
			end
		end
	elseif current.type=="3part_horiz" and  type(current.texture)=="string" then
		object=Set_Auto_3horiz_Texture(current.texture,object,parent,imgpath, offsetTable)
		if object.Resizer then
			local prefsaver = Prefs.GetFromCurrentProfile("uimod_SCA_sca")
			local oldTop = prefsaver[name]["Top"]
			prefsaver[name]["Bottom"] = oldTop + object.left.BitmapHeight()
			Prefs.SetToCurrentProfile("uimod_SCA_sca", prefsaver)
			Prefs.SavePreferences()
			if current.sizelock then
				object.Resizer:SetSizeLock(true)
			else
				object.Resizer:SetSizeLock('Vertical')
			end
		end
	elseif current.type=="3part_vertical" and  type(current.texture)=="string" then
		object=Set_Auto_3vert_Texture(current.texture,object,parent,imgpath, offsetTable)
		if object.Resizer then
			local prefsaver = Prefs.GetFromCurrentProfile("uimod_SCA_sca")
			local oldLeft = prefsaver[name]["Left"]
			prefsaver[name]["Right"] = oldLeft + object.top.BitmapWidth()
			Prefs.SetToCurrentProfile("uimod_SCA_sca", prefsaver)
			Prefs.SavePreferences()
			if current.sizelock then
				object.Resizer:SetSizeLock(true)
			else
				object.Resizer:SetSizeLock('Horizontal')
			end
		end
	elseif current.type=="3part_horiz_centered" and  type(current.texture)=="string" then
		object=Set_Auto_3horiz_Texture(current.texture,object,parent,imgpath, offsetTable, 'centered')
		if object.Resizer then
			local prefsaver = Prefs.GetFromCurrentProfile("uimod_SCA_sca")
			local oldTop = prefsaver[name]["Top"]
			prefsaver[name]["Bottom"] = oldTop + object.left.BitmapHeight()
			Prefs.SetToCurrentProfile("uimod_SCA_sca", prefsaver)
			Prefs.SavePreferences()
			if current.sizelock then
				object.Resizer:SetSizeLock(true)
			else
				object.Resizer:SetSizeLock('Vertical')
			end
		end
	elseif current.type=="3part_vertical_centered" and  type(current.texture)=="string" then
		object=Set_Auto_3vert_Texture(current.texture,object,parent,imgpath, offsetTable, 'centered')
		if object.Resizer then
			local prefsaver = Prefs.GetFromCurrentProfile("uimod_SCA_sca")
			local oldLeft = prefsaver[name]["Left"]
			prefsaver[name]["Right"] = oldLeft + object.top.BitmapWidth()
			Prefs.SetToCurrentProfile("uimod_SCA_sca", prefsaver)
			Prefs.SavePreferences()
			if current.sizelock then
				object.Resizer:SetSizeLock(true)
			else
				object.Resizer:SetSizeLock('Horizontal')
			end
		end
	elseif current.type=="3part_horiz_bottom" and  type(current.texture)=="string" then
		object=Set_Auto_3horiz_Texture(current.texture,object,parent,imgpath, offsetTable, 'bottom')
		if object.Resizer then
			local prefsaver = Prefs.GetFromCurrentProfile("uimod_SCA_sca")
			local oldTop = prefsaver[name]["Top"]
			prefsaver[name]["Bottom"] = oldTop + object.left.BitmapHeight()
			Prefs.SetToCurrentProfile("uimod_SCA_sca", prefsaver)
			Prefs.SavePreferences()
			if current.sizelock then
				object.Resizer:SetSizeLock(true)
			else
				object.Resizer:SetSizeLock('Vertical')
			end
		end
	elseif current.type=="3part_vertical_right" and  type(current.texture)=="string" then
		object=Set_Auto_3vert_Texture(current.texture,object,parent,imgpath, offsetTable, 'right')
		if object.Resizer then
			local prefsaver = Prefs.GetFromCurrentProfile("uimod_SCA_sca")
			local oldLeft = prefsaver[name]["Left"]
			prefsaver[name]["Right"] = oldLeft + object.top.BitmapWidth()
			Prefs.SetToCurrentProfile("uimod_SCA_sca", prefsaver)
			Prefs.SavePreferences()
			if current.sizelock then
				object.Resizer:SetSizeLock(true)
			else
				object.Resizer:SetSizeLock('Horizontal')
			end
		end
	elseif current.type=="button" and  type(current.texture)=="string" then object=Set_Auto_Button(current.texture,object,parent,imgpath)
	elseif current.type=="checkbox" and  type(current.texture)=="string" then object=Set_Auto_Checkbox(current.texture,object,parent,imgpath)
	elseif current.type=="checkboxAsButton" and  type(current.texture)=="string" then object=Set_Auto_CheckboxButton(current.texture,object,parent,imgpath)
	elseif current.type=="simpletexture" then Set_Auto_Bitmap(current.texture,object,parent,imgpath)
	else -- type no define then it's a bitmap
		-- Bitmap texturing
		if type(current.texture)=="string" then
			current.texture=add_extension(current.texture)
			local tex=imgpath .. current.texture
			if tex==nil or tex== "" then
--				UIManager.Output_text("# ERROR - non existant texture entry in ["..full_name.."] in the skin file ["..GetActualSkinFile().."].")
				return nil
			end
			if not Test_Files_ok(tex,"") then
				return nil
			end
			
			
#			if object.Type=='Group' then
#				object=Bitmap(parent)
#			end
			if not(object)  then 
				object=Bitmap(parent)
				LayoutHelpers.FillParent(object, parent) 
			end			
			
			object:SetTexture(tex)
#			if not(object.middle) then 
#				object.middle=Bitmap(object) 
#				LayoutHelpers.FillParent(object.middle, object) 
#				object.middle.Width:Set(object.Width)
#				object.middle.Height:Set(object.Height)
#			end
		
			object.part=1			
			if object.Resizer then
				object.Resizer:SetSizeLock(true)
				local prefsaver = Prefs.GetFromCurrentProfile("uimod_SCA_sca")
				
				--Check if left exist, if yes set left and use bitmap width to set right
				--if it doesnt exist set  right and use bitmap width to set left
				local oldLeft = false
				local oldRight = false
				if prefsaver[name]["Left"] == nil and prefsaver[name]["Right"] != nil then
					oldRight = prefsaver[name]["Right"]
					prefsaver[name]["Left"] = oldRight - object.BitmapWidth()					
				elseif prefsaver[name]["Left"] != nil then
					oldLeft = prefsaver[name]["Left"]					
					prefsaver[name]["Right"] = oldLeft + object.BitmapWidth()
				end
				
				--Check if top exist, if yes set top and use bitmap height to set bottom
				--if it doesnt exist set  bottom and use bitmap height to set top
				local oldTop = false
				local oldBottom = false
				if prefsaver[name]["Top"] == nil and prefsaver[name]["Bottom"] != nil then
					oldBottom = prefsaver[name]["Bottom"]
					prefsaver[name]["Top"] = oldBottom - object.BitmapHeight()
				elseif prefsaver[name]["Top"] != nil then
					oldTop = prefsaver[name]["Top"]
					prefsaver[name]["Bottom"] = oldTop + object.BitmapHeight()
				end
				
				Prefs.SetToCurrentProfile("uimod_SCA_sca", prefsaver)
				Prefs.SavePreferences()
			end

		elseif type(current.texture)=="table" then
			object=Set_Group_Texture(current.texture,object,parent,path)
		else
--			UIManager.Output_text("# ERROR - bad type of texture in ["..full_name.."] in the skin file ["..GetActualSkinFile().."].")

			return nil
		end
	end
	
--	if object ==nil then 	UIManager.Output_text("# ERROR - object is nil in ["..full_name.."] in the skin file ["..GetActualSkinFile().."].") return nil end
	
	if modifiers then 
		if obj[name]==nil then obj[name]={} end
		obj[name][modifiers]=object
	else
		obj[name]=object
	end
	
	if (current.x==nil or current.x=="" or current.y==nil or current.y=="") and (current.type_helpers==nil or current.type_helpers=="") then	
--		UIManager.Output_text(" Skip the positioning of "..full_name)
		return object
	end

	if current.type_helpers=="Center" then
		--LayoutHelpers.AtLeftTopIn(object,parent,current.x,current.y)
		LayoutHelpers.AtCenterIn(object,parent) --,current.x,current.y)
	elseif current.type_helpers=="RightTop" then
		LayoutHelpers.AtRightTopIn(object,parent,current.x,current.y)
		LayoutHelpers.ResetLeft(object)
		LayoutHelpers.ResetBottom(object)
	elseif current.type_helpers=="HorizontalCenter" then
		LayoutHelpers.AtHorizontalCenterIn(object,parent,current.x)
		object.Top:Set(function() return parent.Top() + current.y end)
		LayoutHelpers.ResetBottom(object)
	elseif current.type_helpers=="VerticalCenter" then
		LayoutHelpers.AtVerticalCenterIn(object,parent,current.y)
		object.Left:Set(function() return parent.Left() + current.x end)
		LayoutHelpers.ResetRight(object)
	else
		LayoutHelpers.AtLeftTopIn(object,parent,current.x,current.y)
		LayoutHelpers.ResetRight(object)
		LayoutHelpers.ResetBottom(object)
	end
	if current.x_right != nil then
		object.Right:Set(function() return parent.Right() - current.x_right end)
	end

	if current.y_bottom != nil then
		object.Bottom:Set(function() return parent.Bottom() - current.y_bottom end)
	end
	if current.code!=nil then 
		--current.code(object) 
		object.name=full_name code[full_name]={} code[full_name].fct=current.code code[full_name].obj=object
	end
	return object
end

function nnil(var)
	if var==nil then return "nil" end
	return var
end

function SetGridBounds(name, modifiers, minimap)
	if currentskin!="" and skin[currentskin][name][modifiers] != nil then
		current=skin[currentskin][name][modifiers]
	elseif skin.Default[name][modifiers] != nil then
		current=skin.Default[name][modifiers]
	else
--		UIManager.Output_text("# ERROR - about the Grid object ["..name.. ": " ..modifers.."] in the skin file ["..GetActualSkinFile().."].")
		return nil
	end
	
	if not minimap then
--		UIManager.GridBorders[name..'Height'] = current.top + current.bottom
--		UIManager.GridBorders[name..'Width'] = current.left + current.right
	end
	
	return current.left, current.top, current.right, current.bottom
end

--[[function SetText(name, control, parent, modifiers)
	if currentskin!="" and skin[currentskin][name][modifiers] != nil then
		current=skin[currentskin][name][modifiers]
	elseif skin.Default[name][modifiers] != nil then
		current=skin.Default[name][modifiers]
	else
--		UIManager.Output_text("# ERROR - setting text ["..name.. ": " ..modifers.."] in the skin file ["..GetActualSkinFile().."].")
		return nil
	end
	if not current.font then
		current.font = "Zeroes Three"
	end
	if not current.color then current.color = "FFbadbdb" end
	if not current.text then current.text = "" end
	
	if current.type_helpers=="Center" then
		LayoutHelpers.AtCenterIn(control, parent, current.y, current.x)
	elseif current.type_helpers=="RightTop" then
		LayoutHelpers.AtRightTopIn(control, parent, current.x, current.y)
		LayoutHelpers.ResetLeft(control)
		LayoutHelpers.ResetBottom(control)
	elseif current.type_helpers=="HorizontalCenter" then
		LayoutHelpers.AtHorizontalCenterIn(control, parent, current.x)
		LayoutHelpers.AtTopIn(control, parent, current.y)
		LayoutHelpers.ResetBottom(control)
	elseif current.type_helpers=="VerticalCenter" then
		LayoutHelpers.AtVerticalCenterIn(control, parent, current.y)
		control.Left:Set(function() return parent.Left() + current.x end)
		LayoutHelpers.ResetRight(control)
	else
		LayoutHelpers.AtLeftTopIn(control, parent, current.x, current.y)
		LayoutHelpers.ResetRight(control)
		LayoutHelpers.ResetBottom(control)
	end
	control:SetNewFont(current.font, current.size)
	control:SetText(current.text)
	control:SetColor(current.color)
end--]]

function SetStatusBar(name, parent, modifiers)
	if currentskin!="" and skin[currentskin][name][modifiers] != nil then
		current=skin[currentskin][name][modifiers]
		imgpath = skin[currentskin].path
	elseif skin.Default[name][modifiers] != nil then
		current=skin.Default[name][modifiers]
		imgpath = skin.Default.path
	else
--		UIManager.Output_text("# ERROR - setting statusbar ["..name.. ": " ..modifers.."] in the skin file ["..GetActualSkinFile().."].")
		return nil
	end
	local StatusBar = import('/lua/maui/statusbar.lua').StatusBar
	local bar = false
		
	if current.width then
	    bar = StatusBar(parent, current.range[1] or 0, current.range[2] or 100, false, current.inverse, imgpath.. current.background, imgpath.. current.foreground, true)	
		LayoutHelpers.AtLeftTopIn(bar, parent, current.x, current.y)
	    bar.Right:Set(function() return bar.Left() + 184 end)
		bar.Width:Set(function() return bar.Right() - bar.Left() end)
	else
	    bar = StatusBar(parent, current.range[1] or 0, current.range[2] or 100, current.vertical, current.inverse, imgpath.. current.background, imgpath.. current.foreground, false)	
		LayoutHelpers.AtLeftTopIn(bar, parent, current.x, current.y)
	end
	if current.slidepercentage then
		bar:SetMinimumSlidePercentage(current.slidepercentage)   --TODO some way to not hard code this! (it's the size of a tick in the status bar / size of the status bar)
	end
	return bar
end

function SetOrdersGrid(name, control, parent, modifiers)
	if currentskin!="" and skin[currentskin][name][modifiers] != nil then
		current=skin[currentskin][name][modifiers]
	elseif skin.Default[name][modifiers] != nil then
		current=skin.Default[name][modifiers]
	else
--		UIManager.Output_text("# ERROR - setting ordergrid ["..name.. ": " ..modifers.."] in the skin file ["..GetActualSkinFile().."].")
		return nil
	end
	control._itemWidth = current.width
	control._itemHeight = current.height
	control.Width:Set(current.width * current.cols)
	control.Height:Set(current.height * current.rows)
	control._visible["Horz"]:Set(function() return math.floor(control.Width() / current.width) end)
	control._visible["Vert"]:Set(function() return math.floor(control.Height() / current.height) end)
	LayoutHelpers.AtCenterIn(control, parent, current.y, current.x)
	control:AppendRows(current.rows)
	control:AppendCols(current.cols)
end

function GetOrdersButtonsPath(name, modifiers)
	local btnpath = false
	local currentpath=false
	if currentskin!="" and skin[currentskin][name][modifiers] != nil then
		currentpath=skin[currentskin][name][modifiers]
	elseif skin.Default[name][modifiers] != nil then
		currentpath=skin.Default[name][modifiers]
	else
--		UIManager.Output_text("# ERROR - setting order button path ["..name.. ": " ..modifers.."] in the skin file ["..GetActualSkinFile().."].")
		return nil
	end
	return currentpath
end

function SetPosition(name, control, parent, modifiers, relative)
	if currentskin!="" and skin[currentskin][name][modifiers] != nil then
		current=skin[currentskin][name][modifiers]
	elseif skin.Default[name][modifiers] != nil then
		current=skin.Default[name][modifiers]
	else
--		UIManager.Output_text("# ERROR - setting ordergrid ["..name.. ": " ..modifers.."] in the skin file ["..GetActualSkinFile().."].")
		return nil
	end
	if modifiers == 'abilitybox' or modifiers == 'helpbox' then
		LayoutHelpers.AtLeftIn(control, parent, current.x)
		LayoutHelpers.AtBottomIn(control, parent, current.y)
		LayoutHelpers.ResetRight(control)
		LayoutHelpers.ResetTop(control)
	elseif relative == 'rightof' then
		control.Left:Set(function() return parent.Right() + current.x end)
		LayoutHelpers.AtTopIn(control, parent, current.y)
		LayoutHelpers.ResetRight(control)
		LayoutHelpers.ResetBottom(control)
	elseif relative == 'righttop' then
		LayoutHelpers.AtRightTopIn(control, parent, current.x, current.y)
		LayoutHelpers.ResetLeft(control)
		LayoutHelpers.ResetBottom(control)
	else
		LayoutHelpers.AtLeftTopIn(control, parent, current.x, current.y)
		LayoutHelpers.ResetRight(control)
		LayoutHelpers.ResetBottom(control)
	end
	if current.height then
		control.Height:Set(current.height)
	end
	if current.width then
		control.Width:Set(current.width)
	end
end
