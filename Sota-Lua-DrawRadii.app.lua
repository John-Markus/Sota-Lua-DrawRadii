-- This program is free software. It comes without any warranty, to
-- the extent permitted by applicable law. You can redistribute it
-- and/or modify it under the terms of the Do What The Fuck You Want
-- To Public License, Version 2, as published by Sam Hocevar. See
-- http://www.wtfpl.net/ for more details.

local ScriptName = "Draw Radii";
local Version = "v1.1.0 - 20220821.0";
local CreatorName = "John Markus";
local Description = "Draw skill circle around you";
local IconPath = "Sota-Lua-DrawRadii/appicon.png";

local UID = false;
local animation_counter = 0

config = {
    UI_LANGUAGE = '',
    CURRENT_CARDS = {},
    CURRENT_SCHOOLS = {},
}

shapes = {
    circle = {}

}

localizations = {

}


UNIQUE_SKILLS = { }
SCHOOLS_MAP = { }
SKILLS_MAP = { }


-- This is for loading additional lua modules.
-- Use variable = init_<filename>() to obtain the object
function importModule(filename)
    local _path = ShroudLuaPath .. "/Sota-Lua-DrawRadii/modules/lib_" .. filename .. ".lua"
    local file = io.open(_path)
    local data = file:read("*all")
    file:close()
    local obj = assert(loadsafe(data))
    if obj then
        _G["init_" .. filename] = obj
        ShroudConsoleLog("Loaded lua module: " .. filename)
    else
        ShroudConsoleLog("Module Load Failed: " .. _path)
    end
end

-- This is for loading table from a JSON data.
function importJSON(filename)
    local _path = ShroudLuaPath .. "/Sota-Lua-DrawRadii/data/" .. filename
    local file = io.open(_path)
    local data = file:read("*all")
    file:close()
    local _data = json.parse(data)
    if _data then
        ShroudConsoleLog("Loaded JSON data: " .. filename)
        return _data
    end
    ShroudConsoleLog("JSON Load failed: " .. _path)
    return { }
end

-- Change UI Language
function SetUILanguage(lang)
    if config.UI_LANGUAGE == lang then
        return
    end
    config.UI_LANGUAGE = lang
    ShroudConsoleLog("LANGUAGE DETECTED: " .. lang)

end

-- localization function
function __(ident, msg)
    if localizations[config.UI_LANGUAGE] then
        if localizations[config.UI_LANGUAGE][ident] then
            return localizations[config.UI_LANGUAGE][ident]
        end
    end
      
    return msg
end

-- Periodic functon to update current deck information
function UpdateCurrentDeck()
    config.CURRENT_CARDS = { }
    config.CURRENT_SCHOOLS = { }
    local _deck =  ShroudCurrentDeck();
    if _deck then
        local _cards = ShroudGetDeckCardList(_deck.name);
        if _cards then
            for i, v in pairs(_cards) do                
                -- If this skill has unique name across different languages, use this to detect UI language.
                if UNIQUE_SKILLS[v.name] then
                    SetUILanguage(UNIQUE_SKILLS[v.name])
                end
                -- See if we can find generic skill name from language specific name
                local _id = ""
                if SKILLS_MAP["en"] then 
                    if SKILLS_MAP["en"][v.name] then
                        _id = SKILLS_MAP["en"][v.name]
                    end
                end

                if SKILLS_MAP[config.UI_LANGUAGE] then 
                    if SKILLS_MAP[config.UI_LANGUAGE][v.name] then
                        _id = SKILLS_MAP[config.UI_LANGUAGE][v.name]
                    end
                end

                if _id != "" then
                    config.CURRENT_CARDS[ _id ] = v                  
                    -- See if we can find out in which School they belong to
                    if SCHOOLS_MAP[_id] then
                        local _school = SCHOOLS_MAP[_id]
                        config.CURRENT_SCHOOLS[_school] = 1
                    end
                end

                --ConsoleLog(string.format("Deck Card ID: %s Name: %s Qty: %s", v.id, v.name, v.quantity));
            end
        end
    end

end


function LoadTexturePixel(color) 
    local _path = "Sota-Lua-DrawRadii/images/" .. color .. ".png"
    if UID.LoadTexturePixel(color, _path) then
    else
        ShroudConsoleLog("Texture load failed: " .. _path)
    end
end

function ShroudOnStart()
    UNIQUE_SKILLS = importJSON('unique_skills.json')
    SCHOOLS_MAP   = importJSON('schools_map.json')
    SKILLS_MAP    = importJSON('skills_map_rev.json')

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

    ShroudRegisterPeriodic("UpdateCurrentDeck", "UpdateCurrentDeck", 3, true)
    UpdateCurrentDeck()
end

function Visualize_BardSkills()
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
    local bard_skill_in_use = 0

    UID.config.align_to_camera  = 0 

    for i, v in pairs(_buffs) do
        if BardSkills[v.runeName] then
            --UID.DrawAngularPath(v.runeName, {shapes.wavy_circle}, BardSkills[v.runeName], bard_skill_range, animation_counter + bard_skill_in_use * 15, 1, bard_skill_in_use / 10)
            UID.DrawAngularPath{handle = v.runeName, paths = {shapes.wavy_circle}, color = BardSkills[v.runeName], detect_bounds = 1, 
                                radius_multiplier = bard_skill_range, angle_offset = animation_counter + bard_skill_in_use * 15, alpha = 1, yoffset = bard_skill_in_use / 10}
            bard_skill_in_use = bard_skill_in_use + 1
        end
    end
    if bard_skill_in_use == 0 then        
        --UID.DrawAngularPath("BardSkillCircle", {shapes.circle}, "white", bard_skill_range, 0, 0.1)
        if config.CURRENT_SCHOOLS["Bard"] then             
            UID.DrawAngularPath{handle = "BardSkillCircle", paths = {shapes.circle}, color = "white", detect_bounds = 1, 
                                radius_multiplier = bard_skill_range, angle_offset = animation_counter, alpha = 0.1}
        end

    end

end



function ShowVisualizations()
     animation_counter = animation_counter + 3
    if animation_counter >= 360 then
        animation_counter = 0
    end

    local deck = ShroudCurrentDeck()
    
    
    -- draw UI elements that are aligned to the character
    UID.config.align_to_camera  = 0 
    UID.DrawAngularPath('x', { {{180,1},{0,1},{90,1},{270,1},{0,1}} }, "white", 0.3, 0, 0.1)

    Visualize_BardSkills()

    -- draw UI element that are aligned to the camera
    UID.config.align_to_camera = 1

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
        UID.ClearUsageTracking()
        UID.UpdateAvatarLocation()
    
        if ShroudGetPlayerCombatMode() then
            ShowVisualizations()
        end
        UID.HideUnused()
    end
end

function ShroudOnConsoleInput(type, sourcePlayer, message)
end
