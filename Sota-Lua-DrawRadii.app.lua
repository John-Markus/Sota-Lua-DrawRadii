local ScriptName = "Draw Radii";
local Version = "v1.0.0 - 20220820.1";
local CreatorName = "John Markus";
local Description = "Draw skill circle around you";
local IconPath = "Sota-Lua-DrawRadii/appicon.png";

local UID = false;
local animation_counter = 0

config = {

}

shapes = {
    circle = {}

}

localizations = {

}

-- This is for loading additional lua modules.
-- Use variable = init_<filename>() to obtain the object
function importModule(filename)
    local _path = ShroudLuaPath .. "/Sota-Lua-DrawRadii/modules/lib_" .. filename .. ".lua"
    local file = io.open(_path)
    local data = file:read("*all")
    file:close()
    _G["init_" .. filename] = assert(loadsafe(data))
    ShroudConsoleLog("Loaded lua module: " .. _path)
end

-- localization function
function __(ident, msg)
    if localizations[ident] then
      return localizations[ident]
    end
      
    return msg
end

function LoadTexturePixel(color) 
    local _path = "Sota-Lua-DrawRadii/images/" .. color .. ".png"
    if UID.LoadTexturePixel(color, _path) then
    else
        ShroudConsoleLog("Texture load failed: " .. _path)
    end
end

function ShroudOnStart()
    importModule('draw_ui')
    UID = init_draw_ui()

    -- Load additional modules using importModule() here
    LoadTexturePixel('white')
    LoadTexturePixel('black')

    LoadTexturePixel('red')
    LoadTexturePixel('green')
    LoadTexturePixel('blue')

    LoadTexturePixel('yellow')
    LoadTexturePixel('cyan')
    LoadTexturePixel('magenta')

    LoadTexturePixel('neon_red')
    LoadTexturePixel('neon_green')
    LoadTexturePixel('neon_blue')

    LoadTexturePixel('orange')
    LoadTexturePixel('dark_green')    

    shapes.circle = {}
    shapes.wavy_circle = {}
    for i = 0, 360, 10 do
        table.insert(shapes.circle, {i, 1, 0});
        table.insert(shapes.wavy_circle, {i, 1, math.sin(math.rad(i * 10))/10});
    end
end

function ShowVisualizations()
    UID.UpdateAvatarLocation()
    UID.ClearUsageTracking()

    animation_counter = animation_counter + 3
    if animation_counter >= 360 then
        animation_counter = 0
    end

    -- bard skills has fixed range
    local bard_skill_range = 5 * (1 + ShroudGetStatValueByName("ResoundingReachBonus"))
    local BardSkills = {}
    BardSkills["MelodyOfMending"] = "green"
    BardSkills["AnthemOfAlacrity"] = "blue"
    BardSkills["PsalmOfStagnation"] = "yellow"
    BardSkills["AtonalAria"] = "red"
    BardSkills["SavageSonata"] = "cyan"
    BardSkills["ConcussiveCanticle"] = "neon_red"
    BardSkills["MesmerizingMelody"] = "orange"
    BardSkills["RhapsodyOfRecovery"] = "neon_green"
    BardSkills["RefrainOfResistance"] = "neon_blue"

    local _buffs = ShroudGetPlayerBuff()
    
    -- draw UI elements that are aligned to the character
    UID.config.align_to_camera  = 0 
    UID.DrawAngularPath('x', { {{180,1},{0,1},{90,1},{270,1},{0,1}} }, "white", 0.3, 0, 0.1)

    local bard_skill_in_use = 0

    for i, v in pairs(_buffs) do
        if BardSkills[v.runeName] then
            bard_skill_in_use = bard_skill_in_use + 1
            UID.DrawAngularPath(v.runeName, {shapes.wavy_circle}, BardSkills[v.runeName], bard_skill_range, animation_counter + bard_skill_in_use * 15)
        end
    end
    if bard_skill_in_use == 0 then
        UID.DrawAngularPath("BardSkillCircle", {shapes.circle}, "white", bard_skill_range, 0, 0.1)
    end

    -- draw UI element that are aligned to the camera
    UID.config.align_to_camera = 1

    UID.HideUnused()
end

function DisplayBuffs()
    local _buffs = ShroudGetPlayerBuff()
    if _buffs then
        for i,v in pairs(_buffs) do
            ShroudConsoleLog(v.runeName);
            for x,y in pairs(v.effects) do
                ShroudConsoleLog(y.value .. " " .. y.description .. " Duration: " .. y.currentDuration .. "/" .. y.totalDuration .. " Ticks: " .. y.totalTick);
            end           
        end
    end    

end

function HideVisualizations()
    UID.HideVisualizations()
end

function ShroudOnGUI()
end

function ShroudOnUpdate()
    if UID then
        if ShroudGetPlayerCombatMode() then
            ShowVisualizations()
        else
            HideVisualizations()
        end
    end
end

function ShroudOnConsoleInput(type, sourcePlayer, message)
end
