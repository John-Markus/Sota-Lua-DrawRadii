-- draw_ui module for Lua

local module = { }
module.textures = { }
module.ui_objects = { }
module.current_ui_object = false;

module.LoadTexturePixel = function(color, path)
	-- Load texture into texture list
	local idx = ShroudLoadTexture(path, true)
	if idx > 0 then
		module.textures[color] = idx
	end
end

module.GetTextureId = function(color)
	-- Get texture ID from texture name
	if module.textures[color] then
		return module.textures[color]
	end
	return -1
end

module.PrepareSolidElement = function(handle, idx1, idx2, color)
	-- Prepare a Solid Texture Element (create a new one if not exists)
	local key = handle .. "-" .. idx1 .. "-" .. idx2
	if module.ui_objects[handle] then
		if module.ui_objects[handle][key] then
			module.current_ui_object = module.ui_objects[handle][key]
			return module.ui_objects[handle][key]
		end
	else
		module.ui_objects[handle] = {}
	end
	
	local _texture = module.GetTextureid(color)
	module.current_ui_object = ShroudUIImage(0, 0, 1, 1, _texture)
	
	ShroudSetTransparency(module.current_ui_object, UI.Image, 1)
	ShroudHideObject(module.current_ui_object, UI.Image)

	module.ui_objects[handle][key] = module.current_ui_object
	return module.current_ui_object
end

module.drawLine = function (X1, Y1, X2, Y2)
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
		ShroudHideObject(module.module.current_ui_object, UI.Image)
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
	ShroudSetTransparency(module.current_ui_object, UI.Image, 1 - Y1 / ShroudGetScreenY())
end

module.DrawAngularPath = function(handle, pathCollection, color, radius_multiplier, angle_offset)
	color             = color or "white"
	radius_multiplier = radius_multiplier or 1
	angle_offset      = angle_offset or 0
	
	local PX = ShroudPlayerX
	local PY = ShroudPlayerY + 4
	local PZ = ShroudPlayerZ
	local PB = ShroudGetPlayerOrientation() + 0

	-- Last values
	local LA, LR, LX, LY, LZ, LSX, LSY = 0, 0, 0, 0, 0, 0, 0
	-- new values
	local NA, NR, NX, NY, NZ, NSX, NSY = 0, 0, 0, 0, 0, 0, 0

	local flag_drawLine = 0	
	-- adjust from UI size differences
	radius_multiplier = radius_multiplier * 0.9
	
	for pathidx, pathArray in ipairs(pathCollection) do        
		-- We want to skip first element
		flag_drawLine = 0
		for i = 1, #pathArray / 2 do
			NA = pathArray[i * 2 -1]
			NR = pathArray[i * 2]

			--ShroudConsoleLog("Angle: " .. NA .. ", radius: " .. NR)

			if NR < 0 then
				-- If radius is negative, do not draw line
				flag_drawLine = 0
				NR = -NR
			end

			local _NA = math.rad(NA - PB + angle_offset)

			-- calculate coordinates
			NX = PX + math.sin(_NA) * NR * radius_multiplier
			NY = PY
			NZ = PZ - math.cos(_NA) * NR * radius_multiplier

			vOut = ShroudWorldToScreenPoint(NX, NY, NZ)
			NSX = vOut.x
			NSY = vOut.y

			if flag_drawLine != 0 then
				module.PrepareSolidElement(handle, pathidx, i, color)
				module.DrawLine(LSX, LSY, NSX, NSY)
			end
			LA = NA; LR = NR; LX = NX; LY = NY; LZ = NZ; LSX = NSX; LSY = NSY;
			flag_drawLine = 1
		end
	end
end
	



return module
