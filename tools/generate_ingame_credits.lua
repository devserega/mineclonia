#! /usr/bin/env lua
-- Script to automatically generate mods/HUD/mcl_credits/people.lua from CREDITS.md
-- Run from MCLA root folder

local colors = {
	["Creators of Mineclonia"] = "0x0A9400",
	["Creator of MineClone2"] = "0xFBF837",
	["Creator of MineClone"] = "0xFF51D5",
	["Active Contributors"] = "0xF84355",
	["Previous Contributors"] = "0x52FF00",
	["Original Mod Authors"] = "0xA60014",
	["3D Models"] = "0x343434",
	["Textures and menu images"] = "0x0019FF",
	["Translations"] = "0xFF9705",
	["Special thanks"] = "0x00FF60",
}

local from = io.open("CREDITS.md", "r")
local to = io.open("mods/HUD/mcl_credits/people.lua", "w")

to:write([[
local modname = minetest.get_current_modname()
local S = minetest.get_translator(modname)

]])

to:write("return {\n")

local started_block = false

for line in from:lines() do
	if line:find("## ") == 1 then
		if started_block then
			to:write("\t}},\n")
		end
		local title = line:sub(4, #line)
		to:write("\t{S(\"" .. title .. "\"), " .. (colors[title] or "0xFFFFFF") .. ", {\n")
		started_block = true
	elseif line:find("*") == 1 then
		to:write("\t\t\"" .. line:sub(3, #line) .. "\",\n")
	end
end

if started_block then
	to:write("\t}},\n")
end

to:write("}\n")
