local S = minetest.get_translator("mcl_blackstone")

minetest.register_node("mcl_blackstone:blackstone", {
	description = S("Blackstone"),
	tiles = {"mcl_blackstone_top.png", "mcl_blackstone_top.png", "mcl_blackstone_side.png"},
	sounds = mcl_sounds.node_sound_stone_defaults(),
	groups = {cracky = 3, pickaxey=1, material_stone=1, cobble=1, stonecuttable=1, building_block=1},
	_mcl_blast_resistance = 6,
	_mcl_hardness = 1.5,
})
minetest.register_node("mcl_blackstone:blackstone_gilded", {
	description = S("Gilded Blackstone"),
	tiles = {"mcl_blackstone_gilded.png"},
	sounds = mcl_sounds.node_sound_stone_defaults(),
	groups = {cracky = 3, pickaxey=1, material_stone=1, xp=1, building_block=1},
	drop = {
		max_items = 1,
		items = {
			{items = {"mcl_core:gold_nugget 2"},rarity = 40},
			{items = {"mcl_core:gold_nugget 3"},rarity = 40},
			{items = {"mcl_core:gold_nugget 4"},rarity = 40},
			{items = {"mcl_core:gold_nugget 5"},rarity = 40},
			-- 4x 1 in 40 chance adds up to a 10% chance
			{items = {"mcl_blackstone:blackstone_gilded"}, rarity = 1},
		}
	},
	_mcl_blast_resistance = 2,
	_mcl_hardness = 2,
	_mcl_silk_touch_drop = true,
	_mcl_fortune_drop = {
		discrete_uniform_distribution = true,
		items = {"mcl_core:gold_nugget"},
		min_count = 2,
		max_count = 5,
		cap = 5,
	},
})
minetest.register_node("mcl_blackstone:nether_gold", {
	description = S("Nether Gold Ore"),
	tiles = {"mcl_nether_gold_ore.png"},
	sounds = mcl_sounds.node_sound_stone_defaults(),
	groups = {cracky = 3, pickaxey=1, material_stone=1, xp=1, building_block=1},
	drop = {
		max_items = 1,
		items = {
			{items = {"mcl_core:gold_nugget 6"},rarity = 5},
			{items = {"mcl_core:gold_nugget 5"},rarity = 5},
			{items = {"mcl_core:gold_nugget 4"},rarity = 5},
			{items = {"mcl_core:gold_nugget 3"},rarity = 5},
			{items = {"mcl_core:gold_nugget 2"},rarity = 1},
		}
	},
	_mcl_blast_resistance = 3,
	_mcl_hardness = 3,
	_mcl_silk_touch_drop = true,
	_mcl_fortune_drop = mcl_core.fortune_drop_ore,
	_mcl_cooking_output = "mcl_core:gold_ingot"
})
minetest.register_node("mcl_blackstone:basalt_polished", {
	description = S("Polished Basalt"),
	tiles = {"mcl_blackstone_basalt_top_polished.png", "mcl_blackstone_basalt_top_polished.png", "mcl_blackstone_basalt_side_polished.png"},
	sounds = mcl_sounds.node_sound_stone_defaults(),
	paramtype2 = "facedir",
	on_place = mcl_util.rotate_axis,
	on_rotate = screwdriver.rotate_3way,
	is_ground_content = false,
	groups = {cracky = 3, pickaxey=1, material_stone=1, building_block=1},
	_mcl_blast_resistance = 4.2,
	_mcl_hardness = 1.25,
})
minetest.register_node("mcl_blackstone:basalt", {
	description = S("Basalt"),
	tiles = {"mcl_blackstone_basalt_top.png", "mcl_blackstone_basalt_top.png", "mcl_blackstone_basalt_side.png"},
	sounds = mcl_sounds.node_sound_stone_defaults(),
	paramtype2 = "facedir",
	on_place = mcl_util.rotate_axis,
	on_rotate = screwdriver.rotate_3way,
	groups = {cracky = 3, pickaxey=1, material_stone=1, stonecuttable=1, building_block=1},
	_mcl_blast_resistance = 4.2,
	_mcl_hardness = 1.25,
	_mcl_cooking_output = "mcl_blackstone:basalt_smooth"
})
minetest.register_node("mcl_blackstone:basalt_smooth", {
	description = S("Smooth Basalt"),
	tiles = {"mcl_blackstone_basalt_smooth.png"},
	sounds = mcl_sounds.node_sound_stone_defaults(),
	is_ground_content = false,
	groups = {cracky = 3, pickaxey=1, material_stone=1, building_block=1},
	_mcl_blast_resistance = 4.2,
	_mcl_hardness = 1.25,
	_mcl_stonecutter_recipes = {"mcl_blackstone:basalt"},
})
minetest.register_node("mcl_blackstone:blackstone_polished", {
	description = S("Polished Blackstone"),
	tiles = {"mcl_blackstone_polished.png"},
	sounds = mcl_sounds.node_sound_stone_defaults(),
	is_ground_content = false,
	groups = {cracky = 3, pickaxey=1, material_stone=1, stonecuttable = 1, building_block=1},
	_mcl_blast_resistance = 6,
	_mcl_hardness = 2,
	_mcl_stonecutter_recipes = {"mcl_blackstone:blackstone"},
})
minetest.register_node("mcl_blackstone:blackstone_chiseled_polished", {
	description = S("Chiseled Polished Blackstone"),
	tiles = {"mcl_blackstone_chiseled_polished.png"},
	sounds = mcl_sounds.node_sound_stone_defaults(),
	is_ground_content = false,
	groups = {cracky = 3, pickaxey=1, material_stone=1, building_block=1},
	_mcl_blast_resistance = 6,
	_mcl_hardness = 1.5,
	_mcl_stonecutter_recipes = {"mcl_blackstone:blackstone", "mcl_blackstone:blackstone_polished"},
})
minetest.register_node("mcl_blackstone:blackstone_brick_polished", {
	description = S("Polished Blackstone Bricks"),
	tiles = {"mcl_blackstone_polished_bricks.png"},
	sounds = mcl_sounds.node_sound_stone_defaults(),
	is_ground_content = false,
	groups = {cracky = 3, pickaxey=1, material_stone=1, building_block=1},
	_mcl_blast_resistance = 6,
	_mcl_hardness = 1.5,
	_mcl_stonecutter_recipes = {"mcl_blackstone:blackstone", "mcl_blackstone:blackstone_polished"},
	_mcl_cooking_output = "mcl_blackstone:blackstone_brick_polished_cracked"
})
minetest.register_node("mcl_blackstone:blackstone_brick_polished_cracked", {
	description = S("Cracked Polished Blackstone Bricks"),
	tiles = {"mcl_blackstone_polished_bricks_cracked.png"},
	sounds = mcl_sounds.node_sound_stone_defaults(),
	is_ground_content = false,
	groups = {cracky = 3, pickaxey=1, material_stone=1, building_block=1},
	_mcl_blast_resistance = 6,
	_mcl_hardness = 1.5,
})
minetest.register_node("mcl_blackstone:quartz_brick", {
	description = S("Quartz Bricks"),
	tiles = {"mcl_backstone_quartz_bricks.png"},
	is_ground_content = false,
	sounds = mcl_sounds.node_sound_stone_defaults(),
	groups = {cracky = 3, pickaxey=1, material_stone=1, building_block=1},
	_mcl_blast_resistance = 0.8,
	_mcl_hardness = 0.8,
})
minetest.register_node("mcl_blackstone:soul_soil", {
	description = S("Soul Soil"),
	tiles = {"mcl_blackstone_soul_soil.png"},
	sounds = mcl_sounds.node_sound_sand_defaults(),
	groups = { cracky=3, handy=1, shovely=1, soul_block=1, soil_fungus=1, building_block=1},
	_mcl_blast_resistance = 0.5,
	_mcl_hardness = 0.5,
})
minetest.register_node("mcl_blackstone:soul_fire", {
	description = S("Eternal Soul Fire"),
	_doc_items_longdesc = minetest.registered_nodes["mcl_fire:eternal_fire"]._doc_items_longdesc ,
	drawtype = "firelike",
	tiles = {
		{
			name = "soul_fire_basic_flame_animated.png",
			animation = {
				type = "vertical_frames",
				aspect_w = 16,
				aspect_h = 16,
				length = 1
			},
		},
	},
	inventory_image = "soul_fire_basic_flame.png",
	paramtype = "light",
	light_source = 10,
	walkable = false,
	buildable_to = true,
	sunlight_propagates = true,
	damage_per_second = 2,
	_mcl_node_death_message = minetest.registered_nodes["mcl_fire:fire"]._mcl_node_death_message,
	groups = {fire = 1, dig_immediate = 3, not_in_creative_inventory = 1, dig_by_piston = 1, destroys_items = 1, set_on_fire=8},
	floodable = true,
	drop = "",
	on_flood = function(pos, _, newnode)
		if minetest.get_item_group(newnode.name, "water") > 0 then
			minetest.sound_play("fire_extinguish_flame", {pos = pos, gain = 0.25, max_hear_distance = 16}, true)
		end
	end,
	on_construct=function(pos)
		local under = minetest.get_node(vector.offset(pos,0,-1,0)).name
		if minetest.get_item_group(under, "soul_block") > 0 then
			minetest.swap_node(pos, {name = "air"})
		end
	end
})

local old_onconstruct=minetest.registered_nodes["mcl_fire:fire"].on_construct
minetest.registered_nodes["mcl_fire:fire"].on_construct=function(pos)
	local under = minetest.get_node(vector.offset(pos,0,-1,0)).name
	if minetest.get_item_group(under, "soul_block") > 0 then
		minetest.swap_node(pos, {name = "mcl_blackstone:soul_fire"})
	end
	old_onconstruct(pos)
end

mcl_stairs.register_stair_and_slab("blackstone", {
	baseitem = "mcl_blackstone:blackstone",
	description_stair = S("Blackstone Stairs"),
	description_slab = S("Blackstone Slab"),
	overrides = {_mcl_stonecutter_recipes = {"mcl_blackstone:blackstone"}}, {_mcl_stonecutter_recipes = {"mcl_blackstone:blackstone"}}
})
mcl_stairs.register_stair_and_slab("blackstone_polished", {
	baseitem = "mcl_blackstone:blackstone_polished",
	description_stair = S("Polished Blackstone Stairs"),
	description_slab = S("Polished Blackstone Slab"),
	overrides = {_mcl_stonecutter_recipes = {"mcl_blackstone:blackstone", "mcl_blackstone:blackstone_polished"}}, {_mcl_stonecutter_recipes = {"mcl_blackstone:blackstone", "mcl_blackstone:blackstone_polished"}}
})
mcl_stairs.register_stair_and_slab("blackstone_brick_polished", {
	baseitem = "mcl_blackstone:blackstone_brick_polished",
	description_stair = S("Blackstone Brick Stairs"),
	description_slab = S("Blackstone Brick Slab"),
	overrides = {_mcl_stonecutter_recipes = {"mcl_blackstone:blackstone", "mcl_blackstone:blackstone_polished"}}, {_mcl_stonecutter_recipes = {"mcl_blackstone:blackstone", "mcl_blackstone:blackstone_polished"}}
})
minetest.register_alias("mcl_stairs:slab_blackstone_chiseled_polished_top", "mcl_stairs:slab_blackstone_polished_top")
minetest.register_alias("mcl_stairs:slab_blackstone_chiseled_polished", "mcl_stairs:slab_blackstone_polished")
minetest.register_alias("mcl_stairs:slab_blackstone_chiseled_polished_double", "mcl_stairs:slab_blackstone_polished_double")
minetest.register_alias("mcl_stairs:stair_blackstone_chiseled_polished", "mcl_stairs:stair_blackstone_polished")
minetest.register_alias("mcl_stairs:stair_blackstone_chiseled_polished_inner", "mcl_stairs:stair_blackstone_polished_inner")
minetest.register_alias("mcl_stairs:stair_blackstone_chiseled_polished_outer", "mcl_stairs:stair_blackstone_polished_outer")

mcl_torches.register_torch({
	name="soul_torch",
	description=S("Soul Torch"),
	doc_items_longdesc = S("Torches are light sources which can be placed at the side or on the top of most blocks."),
	doc_items_hidden = false,
	icon="soul_torch_on_floor.png",
	tiles = {{
		name = "soul_torch_on_floor_animated.png",
		animation = {type = "vertical_frames", aspect_w = 16, aspect_h = 16, length = 3.3}
	}},
	light = 10, --soul torches are a bit dimmer than normal torches
	groups = {dig_immediate = 3, deco_block = 1},
	sounds = mcl_sounds.node_sound_wood_defaults(),
	particles = true,
	flame_type = 2,
})

mcl_walls.register_wall_def("mcl_blackstone:wall", {
	description = S("Blackstone Wall"),
	source = "mcl_blackstone:blackstone",
	_mcl_stonecutter_recipes = {"mcl_blackstone:blackstone"},
})

minetest.register_craft({
	output = "mcl_blackstone:blackstone_polished 4",
	recipe = {
		{"mcl_blackstone:blackstone", "mcl_blackstone:blackstone"},
		{"mcl_blackstone:blackstone", "mcl_blackstone:blackstone"},
	}
})
minetest.register_craft({
	output = "mcl_blackstone:basalt_polished 4",
	recipe = {
		{"mcl_blackstone:basalt", "mcl_blackstone:basalt"},
		{"mcl_blackstone:basalt", "mcl_blackstone:basalt"},
	}
})
minetest.register_craft({
	output = "mcl_blackstone:blackstone_chiseled_polished 2",
	recipe = {
		{"mcl_blackstone:blackstone_polished"},
		{"mcl_blackstone:blackstone_polished"},
	}
})
minetest.register_craft({
	output = "mcl_blackstone:blackstone_brick_polished 4",
	recipe = {
		{"mcl_blackstone:blackstone_polished", "mcl_blackstone:blackstone_polished"},
		{"mcl_blackstone:blackstone_polished", "mcl_blackstone:blackstone_polished"},
	}
})
minetest.register_craft({
	output = "mcl_blackstone:quartz_brick 4",
	recipe = {
		{"mcl_nether:quartz_block", "mcl_nether:quartz_block"},
		{"mcl_nether:quartz_block", "mcl_nether:quartz_block"},
	}
})

minetest.register_craft({
	output = "mcl_blackstone:soul_torch 4",
	recipe = {
		{"group:coal"},
		{ "mcl_core:stick" },
		{ "group:soul_block" },
	}
})

minetest.register_abm({
	label = "Lava cooling (basalt)",
	nodenames = { "mcl_core:lava_flowing", "mcl_nether:nether_lava_flowing" },
	neighbors = {"mcl_core:ice"},
	interval = 1,
	chance = 1,
	action = function(pos)
		if minetest.get_node(vector.offset(pos, 0, -1, 0)).name == "mcl_blackstone:soul_soil" then
			minetest.set_node(pos, { name = "mcl_blackstone:basalt" })
		end
	end,
})
