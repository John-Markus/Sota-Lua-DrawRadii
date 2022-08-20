-- draw_ui module for Lua

local module = { }
module.config = {}
module.config.ui_fade_timeout = 10
module.config.show_verbose_msg = 1
module.config.avatar_height = 0
module.config.distance_multiplier = 0.9
module.config.align_to_camera = 0

module.avatar = {x = 0, y = 0, z = 0, orientation = 0, ui_bearing = 0, is_firstperson = 0}

module.textures = { }
module.ui_objects = { }
module.tracking = { }
module.current_ui_object = false;
module.was_ui_visible = 0

module.VerboseMsg = function (text)
	if module.config.show_verbose_msg then
		ShroudConsoleLog(text)
	end
end

module.ClearUsageTracking = function() 
	module.tracking = { }
end

module.HideUnused = function()
	for handle, objectsAr in pairs(module.ui_objects) do
		if module.tracking[handle] then
		else
			for key, objectId in pairs(objectsAr) do
				ShroudHideObject(objectId, UI.Image)
			end
		end
	end
end

module.UpdateAvatarLocation = function()
	module.avatar.x = ShroudPlayerX
	module.avatar.y = ShroudPlayerY + module.config.avatar_height
	module.avatar.z = ShroudPlayerZ
	-- Direction the avatar is facing
	module.avatar.orientation = ShroudGetPlayerOrientation() + 0

	-- Direction the camera is facing
	local vCenter = ShroudWorldToScreenPoint(module.avatar.x, module.avatar.y, module.avatar.z)
	local vNorth = ShroudWorldToScreenPoint(module.avatar.x, module.avatar.y, module.avatar.z + 1)
	module.avatar.ui_bearing = - math.floor(math.deg(math.atan2(vNorth.x - vCenter.x, vNorth.y - vCenter.y))) 

end

--- Load specified path as a texture
-- @param color Internal name that should be used to recall the texture
-- @param path  Path to the texture file
module.LoadTexturePixel = function(color, path)
	-- Load texture into texture list
	local idx = ShroudLoadTexture(path, true)
	if idx > 0 then
		module.textures[color] = idx
		module.VerboseMsg("Texture loaded: " .. color .. " from " .. path)		
	else
		module.VerboseMsg("Texture load failed: " .. path)
	end
end

--- Retrieve internal texture ID using color name provided
-- @param color Name of the texture
module.GetTextureId = function(color)
	-- Get texture ID from texture name
	if module.textures[color] then
		return module.textures[color]
	end
	return -1
end

--- Generate and cache textured element
-- @param handle
-- @param idx1
-- @param idx2
-- @param color
module.PrepareSolidElement = function(handle, idx1, idx2, color)
	idx1 = idx1 or 1
	idx2 = idx2 or 1

	-- Prepare a Solid Texture Element (create a new one if not exists)
	local key = handle .. "-" .. idx1 .. "-" .. idx2
	if module.ui_objects[handle] then
		if module.ui_objects[handle][key] then
			module.current_ui_object = module.ui_objects[handle][key]
			return module.current_ui_object
		end
	else
		module.ui_objects[handle] = {}
	end
	
	local _texture = module.GetTextureId(color)
	module.current_ui_object = ShroudUIImage(0, 0, 1, 1, _texture)
	
	ShroudSetTransparency(module.current_ui_object, UI.Image, 1)
	ShroudHideObject(module.current_ui_object, UI.Image)
	ShroudRaycastObject(module.current_ui_object, UI.Image, false)

	module.ui_objects[handle][key] = module.current_ui_object
	return module.current_ui_object
end

module.DrawLine = function (X1, Y1, X2, Y2, alpha)
	alpha = alpha or 1
	-- Draw a line using Solid Texture (Use Prepare Solid Element first)
	if module.current_ui_object == -1 then
		return
	end

	-- Hide out of bounds lines
	if X1 < 0 or Y1 < 0 or X2 < 0 or Y2 < 0 then 
		ShroudHideObject(module.current_ui_object, UI.Image)
		return
	end

	if X1 > ShroudGetScreenX() or X2 > ShroudGetScreenX() then
		ShroudHideObject(module.current_ui_object, UI.Image)
		return
	end
	if Y1 > ShroudGetScreenY() or Y2 > ShroudGetScreenY() then
		ShroudHideObject(module.current_ui_object, UI.Image)
		return
	end
	--ShroudConsoleLog("DrawLine (" .. X1 .. "," .. Y1 .. ") - (" .. X2 .. ","  .. Y2 .. ")")

	-- Calculate parameters for rotating and resizing solid texture into lines
	local _size = math.ceil(math.sqrt(math.pow(X2-X1,2) + math.pow(Y2-Y1,2)))
	local _slope = math.deg(math.atan2(X2 - X1 , Y2 - Y1)) + 270
	local _depth = math.max(1, 4 - math.ceil(Y1 / ShroudGetScreenY() * 3))

	-- Perform UI object modifications
	ShroudSetPosition    (module.current_ui_object, UI.Image, X1, Y1)
	ShroudSetSize        (module.current_ui_object, UI.Image, _size, _depth)
	ShroudRotateObject   (module.current_ui_object, UI.image, _slope)
	ShroudShowObject     (module.current_ui_object, UI.Image)
	ShroudSetTransparency(module.current_ui_object, UI.Image, (1 - Y1 / ShroudGetScreenY()) * alpha)

	module.was_ui_visible = module.config.ui_fade_timeout
end

module.ConvertAngleToScreen = function(angle, radius, yoffset)
	yoffset = yoffset or 0

	local _angle = math.rad(angle)

	local x = module.avatar.x + math.sin(_angle) * radius
	local y = module.avatar.y + yoffset
	local z = module.avatar.z + math.cos(_angle) * radius

	local vOut = ShroudWorldToScreenPoint(x, y, z)
	vOut.y = ShroudGetScreenY() - vOut.y
	return vOut
end

module.DrawAngularPath = function(handle, pathCollection, color, radius_multiplier, angle_offset, alpha)
	color             = color or "white"
	radius_multiplier = radius_multiplier or 1
	angle_offset      = angle_offset or 0
	alpha             = alpha or 1

	module.tracking[handle] = 1
	
	local PX = module.avatar.x
	local PY = module.avatar.y
	local PZ = module.avatar.z
	local PB = 0
	if module.config.align_to_camera == 0 then
		PB = module.avatar.orientation 
	else
		PB = module.avatar.ui_bearing
	end
	
	
	-- Last values
	local LA, LR, LX, LY, LZ, LSX, LSY = 0, 0, 0, 0, 0, 0, 0
	-- new values
	local NA, NR, NX, NY, NZ, NSX, NSY = 0, 0, 0, 0, 0, 0, 0

	local flag_drawLine = 0	
	local NOfs
	-- adjust from UI size differences
	radius_multiplier = radius_multiplier * module.config.distance_multiplier
	
	for pathidx, pathArray in ipairs(pathCollection) do        
		-- We want to skip first element
		flag_drawLine = 0
		for i = 1, #pathArray do
			-- get angle and radius from pathArray
			NA = pathArray[i][1]
			NR = pathArray[i][2]
			NOfs = pathArray[i][3] or 0

			--ShroudConsoleLog("Angle: " .. NA .. ", radius: " .. NR)

			if NR < 0 then
				-- If radius is negative, do not draw line
				flag_drawLine = 0
				NR = -NR
			end

			vOut = module.ConvertAngleToScreen(NA + PB + angle_offset, NR * radius_multiplier, NOfs)

			NSX = vOut.x
			NSY = vOut.y

			if flag_drawLine != 0 then
				module.PrepareSolidElement(handle, pathidx, i, color)
				module.DrawLine(LSX, LSY, NSX, NSY, alpha)
			end
			LA = NA; LR = NR; LX = NX; LY = NY; LZ = NZ; LSX = NSX; LSY = NSY;
			flag_drawLine = 1
		end
	end
end
	
module.HideVisualizations = function()
    if module.was_ui_visible <= 0 then
        return
    end

    module.was_ui_visible = module.was_ui_visible - 1
    for handle, objectAr in pairs(module.ui_objects) do
        for key, objectId in pairs(objectAr) do
            if module.was_ui_visible > 0 then
                ShroudSetTransparency(objectId,UI.Image, module.was_ui_visible / module.config.ui_fade_timeout)
            else
                ShroudHideObject(objectId,UI.Image)
            end
        end
    end    	
end


return module
