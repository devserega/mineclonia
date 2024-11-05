local S = minetest.get_translator("mcl_copper")

local function on_lightning_strike(pos, _, pos2)
	local node = minetest.get_node(pos)
	if vector.distance(pos, pos2) <= 1 then
		node.name = mcl_copper.get_undecayed(node.name, 4)
	else
		node.name = mcl_copper.get_undecayed(node.name, math.random(4))
	end
	minetest.swap_node(pos, node)
end

minetest.register_node("mcl_copper:stone_with_copper", {
	description = S("Copper Ore"),
	_doc_items_longdesc = S("Some copper contained in stone, it is pretty common and can be found below sea level."),
	tiles = {"default_stone.png^mcl_copper_ore.png"},
	groups = {pickaxey = 3, building_block = 1, material_stone = 1, blast_furnace_smeltable=1},
	drop = {
		max_items = 1,
		items = {
			{items = {"mcl_copper:raw_copper 5"},rarity = 5},
			{items = {"mcl_copper:raw_copper 4"},rarity = 5},
			{items = {"mcl_copper:raw_copper 3"},rarity = 5},
			{items = {"mcl_copper:raw_copper 2"}},
		}
	},
	sounds = mcl_sounds.node_sound_stone_defaults(),
	_mcl_blast_resistance = 3,
	_mcl_hardness = 3,
	_mcl_silk_touch_drop = true,
	_mcl_fortune_drop = mcl_core.fortune_drop_ore,
	_mcl_cooking_output = "mcl_copper:copper_ingot"
})

minetest.register_node("mcl_copper:block_raw", {
	description = S("Block of Raw Copper"),
	_doc_items_longdesc = S("A block used for compact raw copper storage."),
	tiles = {"mcl_copper_block_raw.png"},
	is_ground_content = false,
	groups = {pickaxey = 2, building_block = 1, blast_furnace_smeltable = 1 },
	sounds = mcl_sounds.node_sound_metal_defaults(),
	_mcl_blast_resistance = 6,
	_mcl_hardness = 5,
})

local n_desc = {
	[""] = "",
	["_exposed"] = S("Exposed"),
	["_weathered"] = S("Weathered"),
	["_oxidized"] = S("Oxidized"),
}

local bulb_light = {
	[""] = minetest.LIGHT_MAX,
	["_exposed"] = 12,
	["_weathered"] = 8,
	["_oxidized"] = 4,
}

for n, desc in pairs(n_desc) do
	local bdesc = desc
	if n == "" then
		bdesc = S("Block of")
	end
	minetest.register_node("mcl_copper:block"..n, {
		description = S("@1 Copper", bdesc),
		_doc_items_longdesc = S("@1 copper is mostly a decorative block.", bdesc),
		tiles = {"mcl_copper"..(n == "" and "_block" or n) ..".png"},
		is_ground_content = false,
		groups = {pickaxey = 2, building_block = 1, stonecuttable = 1},
		sounds = mcl_sounds.node_sound_metal_defaults(),
		_mcl_blast_resistance = 6,
		_mcl_hardness = 3,
	})

	minetest.register_node("mcl_copper:block"..n.."_cut", {
		description = S("@1 Cut Copper", desc),
		_doc_items_longdesc = S("@1 copper is mostly a decorative block.", desc),
		tiles = {"mcl_copper"..(n == "" and "_block" or n) .."_cut.png"},
		is_ground_content = false,
		groups = {pickaxey = 2, building_block = 1, stonecuttable = 1},
		sounds = mcl_sounds.node_sound_metal_defaults(),
		_mcl_blast_resistance = 6,
		_mcl_hardness = 3,
		_mcl_stonecutter_recipes = { "mcl_copper:block"..n }
	})

	minetest.register_node("mcl_copper:block"..n.."_chiseled", {
		description = S("@1 Chiseled Copper", desc),
		_doc_items_longdesc = S("@1 Chiseled copper is mostly a decorative block.", desc),
		tiles = {"mcl_copper"..(n == "" and "_block" or n) .."_chiseled.png"},
		is_ground_content = false,
		groups = {pickaxey = 2, building_block = 1, stonecuttable = 1},
		sounds = mcl_sounds.node_sound_metal_defaults(),
		_mcl_blast_resistance = 6,
		_mcl_hardness = 3,
		_mcl_stonecutter_recipes = { "mcl_copper:block"..n, "mcl_copper:block"..n.."_cut" }
	})
	minetest.register_node("mcl_copper:block"..n.."_grate", {
		description = S("@1 Copper Grate", desc),
		_doc_items_longdesc = S("@1 Chiseled copper is mostly a decorative block.", desc),
		drawtype = "allfaces_optional",
		tiles = {"mcl_copper"..(n == "" and "_block" or n) .."_grate.png"},
		use_texture_alpha = "blend",
		is_ground_content = false,
		groups = {pickaxey = 2, building_block = 1 },
		sounds = mcl_sounds.node_sound_metal_defaults(),
		_mcl_blast_resistance = 6,
		_mcl_hardness = 3,
		_mcl_stonecutter_recipes = { "mcl_copper:block"..n }
	})

	minetest.register_node("mcl_copper:bulb"..n.."_on", {
		description = S("@1 Copper Bulb On", desc),
		_doc_items_longdesc = S("@1 copper is mostly a decorative block.", desc),
		tiles = { "mcl_copper"..(n == "" and "_block" or n) .."_bulb_on.png"},
		is_ground_content = false,
		light_source = bulb_light[n],
		groups = {pickaxey = 2, building_block = 1, not_in_creative_inventory = 1, comparator_signal = 1},
		sounds = mcl_sounds.node_sound_metal_defaults(),
		_mcl_blast_resistance = 6,
		_mcl_hardness = 3,
		drop = "mcl_copper:bulb"..n.."_off",
		mesecons = {effector = {
			action_on = function(pos, node)
				node.name = "mcl_copper:bulb"..n.."_off"
				minetest.swap_node(pos,node)
			end,
			rules = mesecon.rules.alldirs,
		}},
	})
	minetest.register_node("mcl_copper:bulb"..n.."_off", {
		description = S("@1 Copper Bulb", desc),
		_doc_items_longdesc = S("@1 copper is mostly a decorative block.", desc),
		tiles = { "mcl_copper"..(n == "" and "_block" or n) .."_bulb_off.png"},
		is_ground_content = false,
		groups = {pickaxey = 2, building_block = 1 },
		sounds = mcl_sounds.node_sound_metal_defaults(),
		_mcl_blast_resistance = 6,
		_mcl_hardness = 3,
		mesecons = {effector = {
			action_on = function(pos, node)
				node.name = "mcl_copper:bulb"..n.."_on"
				minetest.swap_node(pos,node)
			end,
			rules = mesecon.rules.alldirs,
		}},
	})

	mcl_doors:register_trapdoor("mcl_copper:trapdoor"..n, {
		description = S("@1 Copper Trapdoor", desc),
		groups = { copper = 1, pickaxey = 2, deco_block = 1 },
		sounds = mcl_sounds.node_sound_metal_defaults(),
		sound_close = "doors_steel_door_close",
		sound_open = "doors_steel_door_open",
		tile_front = "mcl_copper_trapdoor"..n..".png",
		tile_side = "mcl_copper_trapdoor"..n.."_side.png",
		wield_image = "mcl_copper_trapdoor"..n..".png",
		_mcl_blast_resistance = 3,
		_mcl_hardness = 3
	})
	mcl_doors:register_door("mcl_copper:door"..n, {
		description = S("@1 Copper Door", desc),
		groups = { door = 1, copper = 1, pickaxey = 2, building_block = 1},
		inventory_image = "mcl_copper_door"..n..".png",
		sounds = mcl_sounds.node_sound_metal_defaults(),
		sound_close = "doors_steel_door_close",
		sound_open = "doors_steel_door_open",
		tiles_bottom = { "mcl_copper_door"..n.."_bottom.png^[transformFX", "mcl_copper_door"..n.."_bottom.png" },
		tiles_top = { "mcl_copper_door"..n.."_top.png^[transformFX", "mcl_copper_door"..n.."_top.png" },
		_mcl_blast_resistance = 3,
		_mcl_hardness = 3
	})
	mcl_wip.register_wip_item("mcl_copper:door"..n)
end


for xposr, desc in pairs(n_desc) do
	if xposr == "" then
		mcl_stairs.register_stair_and_slab("copper"..xposr.."_cut", {
			baseitem = "mcl_copper:block"..xposr.."_cut",
			description_stair = S("@1 Cut Copper Stairs", desc),
			description_slab = S("@1 Cut Copper Slab", desc),
			overrides = {_mcl_stonecutter_recipes = {"mcl_copper:block", "mcl_copper:block"..xposr.."_cut"}}
		})
	else
		mcl_stairs.register_stair_and_slab("copper"..xposr.."_cut", {
			baseitem = "mcl_copper:block"..xposr.."_cut",
			description_stair = S("@1 Cut Copper Stairs", desc),
			description_slab = S("@1 Cut Copper Slab", desc),
			overrides = {_mcl_stonecutter_recipes = {"mcl_copper:block", "mcl_copper:block"..xposr.."_cut"}, _on_lightning_strike = on_lightning_strike}
		})
	end
end
-- mcl_stairs.register_stair_and_slab("copper_exposed_cut", {
-- 	baseitem = "mcl_copper:block_exposed_cut",
-- 	description_stair = "Exposed Cut Copper Stairs",
-- 	description_slab = "Exposed Cut Copper Slab",
-- 	overrides = {_mcl_stonecutter_recipes = {"mcl_copper:block_exposed", "mcl_copper:block_exposed_cut"}, _on_lightning_strike = on_lightning_strike}
-- })
--
-- mcl_stairs.register_stair_and_slab("copper_weathered_cut", {
-- 	baseitem = "mcl_copper:block_weathered_cut",
-- 	description_stair = "Weathered Cut Copper Stairs",
-- 	description_slab = "Weathered Cut Copper Slab",
-- 	overrides = {_mcl_stonecutter_recipes = {"mcl_copper:block_weathered", "mcl_copper:block_weathered_cut"}, _on_lightning_strike = on_lightning_strike}
-- })
--
-- mcl_stairs.register_stair_and_slab("copper_oxidized_cut", {
-- 	baseitem = "mcl_copper:block_oxidized_cut",
-- 	description_stair = "Oxidized Cut Copper Stairs",
-- 	description_slab = "Oxidized Cut Copper Slab",
-- 	overrides = {_mcl_stonecutter_recipes = {"mcl_copper:block_oxidized", "mcl_copper:block_oxidized_cut"}, _on_lightning_strike = on_lightning_strike}
-- })
