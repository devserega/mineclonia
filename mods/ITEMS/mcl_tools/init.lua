local modname = minetest.get_current_modname()
local modpath = minetest.get_modpath(modname)
local S = minetest.get_translator(modname)

mcl_tools = {}
mcl_tools.sets = {}

mcl_tools.commondefs = {
	["axe"] = {
		longdesc = S("An axe is your tool of choice to cut down trees, wood-based blocks and other blocks. Axes deal a lot of damage as well, but they are rather slow. Axes can be used to strip bark and hyphae from trunks. They can also be used to scrape blocks made of copper, reducing their oxidation stage or removing wax from waxed variants."),
		usagehelp = S("To strip bark from trunks and hyphae, use the ax by right-clicking on them. To reduce an oxidation stage from a block made of copper or remove wax from waxed variants, right-click on them. Doors and trapdoors also require you to hold down the sneak key while using the axe."),
		groups = { axe = 1, tool = 1 },
		diggroups = { axey = {} },
		craft_shapes = {
			{
				{ "material", "material" },
				{ "mcl_core:stick", "material" },
				{ "mcl_core:stick", "" }
			},
			{
				{ "material", "material" },
				{ "material", "mcl_core:stick" },
				{ "", "mcl_core:stick" }
			}
		}
	},
	["hoe"] = {
		longdesc = S("Hoes are essential tools for growing crops. They are used to create farmland in order to plant seeds on it. Hoes can also be used as very weak weapons in a pinch."),
		usagehelp = S("Use the hoe on a cultivatable block (by rightclicking it) to turn it into farmland. Dirt, grass blocks and grass paths are cultivatable blocks. Using a hoe on coarse dirt turns it into dirt."),
		groups = { hoe = 1, tool = 1 },
		diggroups = { hoey = {} },
		craft_shapes = {
			{
				{ "material", "material" },
				{ "mcl_core:stick", "" },
				{ "mcl_core:stick", "" }
			},
			{
				{ "material", "material" },
				{ "", "mcl_core:stick" },
				{ "", "mcl_core:stick" }
			}
		}
	},
	["pick"] = {
		longdesc = S("Pickaxes are mining tools to mine hard blocks, such as stone. A pickaxe can also be used as weapon, but it is rather inefficient."),
		groups = { pickaxe = 1, tool = 1 },
		diggroups = { pickaxey = {} },
		craft_shapes = {
			{
				{ "material", "material", "material" },
				{ "", "mcl_core:stick", "" },
				{ "", "mcl_core:stick", "" }
			}
		}
	},
	["shovel"] = {
		longdesc = S("Shovels are tools for digging coarse blocks, such as dirt, sand and gravel. They can also be used to turn grass blocks to grass paths. Shovels can be used as weapons, but they are very weak."),
		usagehelp = S("To turn a grass block into a grass path, hold the shovel in your hand, then use (rightclick) the top or side of a grass block. This only works when there's air above the grass block."),
		groups = { shovel = 1, tool = 1 },
		diggroups = { shovely = {} },
		craft_shapes = {
			{
				{ "material" },
				{ "mcl_core:stick" },
				{ "mcl_core:stick" }
			}
		}
	},
	["sword"] = {
		longdesc = S("Swords are great in melee combat, as they are fast, deal high damage and can endure countless battles. Swords can also be used to cut down a few particular blocks, such as cobwebs."),
		groups = { sword = 1, weapon = 1 },
		diggroups = { swordy = {}, swordy_cobweb = {} },
		craft_shapes = {
			{
				{ "material" },
				{ "material" },
				{ "mcl_core:stick" }
			}
		}
	}
}

local shears_longdesc = S("Shears are tools to shear sheep and to mine a few block types. Shears are a special mining tool and can be used to obtain the original item from grass, leaves and similar blocks that require cutting.")
local shears_use = S("To shear sheep or carve faceless pumpkins, use the “place” key on them. Faces can only be carved at the side of faceless pumpkins. Mining works as usual, but the drops are different for a few blocks.")

local wield_scale = mcl_vars.tool_wield_scale

local function on_tool_place(itemstack, placer, pointed_thing, tool)
	if pointed_thing.type ~= "node" then return end

	local node = minetest.get_node(pointed_thing.under)
	local ndef = minetest.registered_nodes[node.name]
	if not ndef then
		return
	end

	if not placer:get_player_control().sneak and ndef.on_rightclick then
		return minetest.item_place(itemstack, placer, pointed_thing)
	end
	if minetest.is_protected(pointed_thing.under, placer:get_player_name()) then
		minetest.record_protection_violation(pointed_thing.under, placer:get_player_name())
		return itemstack
	end

	if itemstack and type(ndef["_on_"..tool.."_place"]) == "function" then
		local itemstack, no_wear = ndef["_on_"..tool.."_place"](itemstack, placer, pointed_thing)
		if minetest.is_creative_enabled(placer:get_player_name()) or no_wear or not itemstack then
			return itemstack
		end

		-- Add wear using the usages of the tool defined in
		-- _mcl_diggroups. This assumes the tool only has one diggroups
		-- (which is the case in Mineclone).
		local tdef = minetest.registered_tools[itemstack:get_name()]
		if tdef and tdef._mcl_diggroups then
			for group, _ in pairs(tdef._mcl_diggroups) do
				itemstack:add_wear(mcl_autogroup.get_wear(itemstack:get_name(), group))
				return itemstack
			end
		end
		return itemstack
	end

	mcl_offhand.place(placer, pointed_thing)

	return itemstack
end

mcl_tools.tool_place_funcs = {}

for _,tool in pairs({"shovel","shears","axe","sword","pick"}) do
	mcl_tools.tool_place_funcs[tool] = function(itemstack,placer,pointed_thing)
		return on_tool_place(itemstack,placer,pointed_thing,tool)
	end
end

local function get_tool_diggroups(materialdefs, toolname)
	local diggroups = mcl_tools.commondefs[toolname].diggroups

	for _, diggroup in pairs(diggroups) do
		diggroup.speed = materialdefs.speed
		diggroup.level = materialdefs.level
		diggroup.uses = materialdefs.uses
	end

	return diggroups
end

local function replace_material_tag(shape, material)
	local recipe = table.copy(shape)

	for _, line in ipairs(recipe) do
		for count, tag in ipairs(line) do
			if tag == "material" then
				line[count] = material
			end
		end
	end

	return recipe
end

local function get_punch_uses(toolname, materialdefs)
	if toolname == "sword" then return materialdefs.uses end
	return materialdefs.uses / 2
end

local function register_tool(setname, materialdefs, toolname, tooldefs, overrides)
	local mod = minetest.get_current_modname()
	local itemstring = mod..":"..toolname.."_"..setname
	local commondefs = mcl_tools.commondefs[toolname]
	local tcs = table.copy(tooldefs.tool_capabilities or {})
	tooldefs.tool_capabilities = nil
	local tooldefs = table.merge({
		_doc_items_longdesc = commondefs.longdesc,
		_doc_items_usagehelp = commondefs.usagehelp,
		_mcl_diggroups = get_tool_diggroups(materialdefs, toolname),
		_mcl_toollike_wield = true,
		_repair_material = materialdefs.material,
		groups = table.merge(commondefs.groups, materialdefs.groups),
		tool_capabilities = table.merge(tcs, {
			max_drop_level = materialdefs.max_drop_level,
			punch_attack_uses = get_punch_uses(toolname, materialdefs)
		}),
		on_place = mcl_tools.tool_place_funcs[toolname],
		sound = { breaks = "default_tool_breaks" },
		wield_scale = wield_scale
	}, tooldefs, overrides or {})

	minetest.register_tool(itemstring, tooldefs)

	if materialdefs.craftable then
		for _, shapes in ipairs(mcl_tools.commondefs[toolname].craft_shapes) do
			local recipe = replace_material_tag(shapes, materialdefs.material)

			minetest.register_craft({
				output = itemstring,
				recipe = recipe
			})
		end
	end
end

---Used to add a new tool to all existing material sets. See [API.md](API.md) for more information.
---@param toolname string
---@param commondefs table
---@param tools table
---@param overrides table|nil
function mcl_tools.add_to_sets(toolname, commondefs, tools, overrides)
	if not mcl_tools.commondefs[toolname] then
		mcl_tools.commondefs[toolname] = commondefs
	end

	for setname, _ in pairs(mcl_tools.sets) do
		local materialdefs = mcl_tools.sets[setname]
		local tooldefs = tools[setname]

		register_tool(setname, materialdefs, toolname, tooldefs, overrides)
	end
end

---Used to add a set of tools to a material. See [API.md](API.md) for more information.
---@param setname string
---@param materialdefs table
---@param tools table
---@param overrides table|nil
function mcl_tools.register_set(setname, materialdefs, tools, overrides)
	if not mcl_tools.sets[setname] then
		mcl_tools.sets[setname] = materialdefs
	end

	for tool, defs in pairs(tools) do
		register_tool(setname, materialdefs, tool, defs, overrides)
	end
end

--Shears
minetest.register_tool("mcl_tools:shears", {
	description = S("Shears"),
	_doc_items_longdesc = shears_longdesc,
	_doc_items_usagehelp = shears_use,
	inventory_image = "default_tool_shears.png",
	wield_image = "default_tool_shears.png",
	stack_max = 1,
	groups = { tool=1, shears=1, dig_speed_class=4, enchantability=-1, },
	tool_capabilities = {
			full_punch_interval = 0.5,
			max_drop_level=1,
	},
	on_place = mcl_tools.tool_place_funcs.shears,
	sound = { breaks = "default_tool_breaks" },
	_mcl_toollike_wield = true,
	_mcl_diggroups = {
		shearsy = { speed = 1.5, level = 1, uses = 238 },
		shearsy_wool = { speed = 5, level = 1, uses = 238 },
		shearsy_cobweb = { speed = 15, level = 1, uses = 238 }
	},
})

minetest.register_craft({
	output = "mcl_tools:shears",
	recipe = {
		{ "mcl_core:iron_ingot", "" },
		{ "", "mcl_core:iron_ingot", },
	}
})

minetest.register_craft({
	output = "mcl_tools:shears",
	recipe = {
		{ "", "mcl_core:iron_ingot" },
		{ "mcl_core:iron_ingot", "" },
	}
})

dofile(modpath.."/mace.lua")
dofile(modpath.."/register.lua")
