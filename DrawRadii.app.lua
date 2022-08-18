local ScriptName = "Draw Radii";
local Version = "1.0";
local CreatorName = "John Markus";
local Description = "Draw skill circle around you";
local IconPath = "Sota-Lua-DrawRadii/appicon.png";



config = {
    is_ui_initialized = 0,
    gui_draw_once = 0,
    textures = {},
    uiobjects = {},
    current_ui_object = false,
    was_ui_visible = 0,
}

shapes = {
    circle = {}

}

localizations = {

}

-- This is for loading additional lua modules.
-- Use variable = init_<filename>() to obtain the object
function importModule(filename)
    local file = io.open("Sota-Lua-DrawRadii/modules/" .. filename .. ".lua")
    local data = file:read("*all")
    file:close()
    _G["init_" .. filename] = assert(loadsafe(data))
end

-- localization function
function __(ident, msg)
    if localizations[ident] then
      return localizations[ident]
    end
      
    return msg
end

function LoadTexturePixel(color) 
    local idx = ShroudLoadTexture("Sota-Lua-DrawRadii/images/" .. color .. ".png", true)
    if idx > 0 then
        config.textures[color] = idx
        ShroudConsoleLog("texture loaded: " .. color .. "=" .. idx)
    else
        ShroudConsoleLog("texture failed: " .. color )
    end
end

function InitApp()
    ShroudConsoleLog('Lua Plugin: Draw Radii initialized.')


end



function ui_drawline(X1, Y1, X2, Y2, ui)
    if config.current_ui_object == -1 then
        return
    end
    
    if X1 < 0 or Y1 < 0 or X2 < 0 or Y2 < 0 then 
        ShroudHideObject(config.current_ui_object, UI.Image)
        return
    end
    
    if X1 > ShroudGetScreenX() or X2 > ShroudGetScreenX() then
        ShroudHideObject(config.current_ui_object, UI.Image)
        return
    end
    if Y1 > ShroudGetScreenY() or Y2 > ShroudGetScreenY() then
        ShroudHideObject(config.current_ui_object, UI.Image)
        return
    end
    --ShroudConsoleLog("DrawLine (" .. X1 .. "," .. Y1 .. ") - (" .. X2 .. ","  .. Y2 .. ")")

    local _size = math.ceil(math.sqrt(math.pow(X2-X1,2) + math.pow(Y2-Y1,2)))
    local _slope = math.deg(math.atan2(X2 - X1 , Y2 - Y1)) + 270
    local _depth = math.max(1, 4 - math.ceil(Y1 / ShroudGetScreenY() * 3))

    

    ShroudSetPosition(config.current_ui_object, UI.Image, X1, Y1)
    ShroudSetSize(config.current_ui_object, UI.Image, _size, _depth)
    ShroudRotateObject(config.current_ui_object, UI.image, _slope)
    ShroudShowObject(config.current_ui_object, UI.Image)
    ShroudSetTransparency(config.current_ui_object, UI.Image, 1 - Y1 / ShroudGetScreenY())

end

function fit360(angle) 
    while angle < 0 do
        angle = angle + 360
    end
    while angle >= 360 do
        angle = angle - 360
    end
    return angle
end    

function ui_hideUIObjects(handle) 
    if config.uiobjecs[handle] then
    end    
end

function ui_get_texture(color)
    if config.textures[color] then
        return config.textures[color]
    end
    ShroudConsoleLog("texture missing: " .. color)
    return -1
end

function ui_prepare_ui_object(handle, idx1, idx2, color)
    local key = handle .. '-' .. idx1 .. '-' .. idx2
    if config.uiobjects[handle] then        
        if config.uiobjects[handle][key] then
            config.current_ui_object = config.uiobjects[handle][key]
            return config.current_ui_object
        end
    else   
        config.uiobjects[handle] = {}
    end

    local _texture = ui_get_texture(color)
    config.current_ui_object = ShroudUIImage(0, 0, 1, 1, _texture)
    ShroudSetTransparency(config.current_ui_object, UI.Image, 1)
    ShroudHideObject(config.current_ui_object, UI.Image)
    
    
    config.uiobjects[handle][key] = config.current_ui_object
    return config.current_ui_object
end


function DrawAngularPath(handle, pathCollection, radius_multiplier, color) 
    local PX = ShroudPlayerX
    local PY = ShroudPlayerY + 4
    local PZ = ShroudPlayerZ
    local PB = fit360(ShroudGetPlayerOrientation())

    local LA, LR, LX, LY, LZ, LSX, LSY = 0, 0, 0, 0, 0, 0, 0
    local NA, NR, NX, NY, NZ, NSX, NSY = 0, 0, 0, 0, 0, 0, 0

    local flag_drawLine = 0

    radius_multiplier = radius_multiplier * 0.9

    for pathidx, pathArray in ipairs(pathCollection) do        
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

            local _NA = math.rad(NA - PB)

            -- calculate coordinates
            
            NX = PX + math.sin(_NA) * NR * radius_multiplier
            NY = PY
            NZ = PZ - math.cos(_NA) * NR * radius_multiplier

            vOut = ShroudWorldToScreenPoint(NX, NY, NZ)
            NSX = vOut.x
            NSY = vOut.y

            if flag_drawLine != 0 then
                local _ui = ui_prepare_ui_object(handle, pathidx, i, color)
                ui_drawline(LSX, LSY, NSX, NSY, _ui)
            end
            LA = NA; LR = NR; LX = NX; LY = NY; LZ = NZ; LSX = NSX; LSY = NSY;
            flag_drawLine = 1
        end
        

    end


end

function ShroudOnStart()
    -- Load additional modules using importModule() here
    LoadTexturePixel('white')
    LoadTexturePixel('black')

    LoadTexturePixel('red')
    LoadTexturePixel('green')
    LoadTexturePixel('blue')

    LoadTexturePixel('yellow')
    LoadTexturePixel('cyan')
    LoadTexturePixel('magenta')

    shapes.circle = {}
    for i = 0, 360, 10 do
        table.insert(shapes.circle, i);
        table.insert(shapes.circle, 1);
    end

    --for i = 1, ShroudGetStatCount() do
    --    ShroudConsoleLog(i .. ': ' .. ShroudGetStatNameByNumber(i) .. ' = ' .. ShroudGetStatValueByNumber(i))
    --end


end

function ShowVisualizations()
    config.was_ui_visible = 10
    DrawAngularPath('x', {{45,0.1,225,0.1},{135,0.1,315,0.1}}, 4.9, "white")
    DrawAngularPath('Spear Radii', {shapes.circle}, 4.9, "yellow")
    
    DrawAngularPath('Spinning Radii', {shapes.circle}, 6.7, "cyan")
    DrawAngularPath('Pull Radii', {shapes.circle}, 7.9, "white")

end

function HideVisualizations()
    if config.was_ui_visible <= 0 then
        return
    end

    config.was_ui_visible = config.was_ui_visible - 1
    for handle, objectAr in pairs(config.uiobjects) do
        for key, objectId in pairs(objectAr) do
            if config.was_ui_visible > 0 then
                ShroudSetTransparency(objectId,UI.Image, config.was_ui_visible / 10)
            else
                ShroudHideObject(objectId,UI.Image)
            end
        end
    end    


end


function ShroudOnGUI()


end

function ShroudOnUpdate()
    if ShroudGetPlayerCombatMode() then
        ShowVisualizations()
    else
        HideVisualizations()

    end
end

function ShroudOnConsoleInput(type, sourcePlayer, message)
end







