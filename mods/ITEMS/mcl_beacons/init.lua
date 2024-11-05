local S = minetest.get_translator(minetest.get_current_modname())

mcl_beacons = {
	blocks ={"mcl_core:diamondblock","mcl_core:ironblock","mcl_core:goldblock","mcl_core:emeraldblock","mcl_nether:netheriteblock"},
	fuel = {"mcl_core:diamond","mcl_core:emerald","mcl_core:iron_ingot","mcl_core:gold_ingot","mcl_nether:netherite_ingot"}
}

local pallete_order = {
	glass_cyan		 		= 1,
	pane_cyan_flat			= 1,
	pane_cyan				= 1,

	glass_white		 		= 2,
	pane_white_flat			= 2,
	pane_white				= 2,

	glass_brown				= 3,
	pane_brown_flat			= 3,
	pane_brown				= 3,

	glass_blue				= 4,
	pane_blue_flat			= 4,
	pane_blue				= 4,

	glass_light_blue		= 5,
	pane_light_blue_flat	= 5,
	pane_light_blue			= 5,

	glass_pink				= 6,
	pane_pink_flat			= 6,
	pane_pink				= 6,

	glass_purple			= 7,
	pane_purple_flat		= 7,
	pane_purple		 		= 7,

	glass_red				= 8,
	pane_red_flat			= 8,
	pane_red				= 8,

	glass_silver			= 9,
	pane_silver_flat		= 9,
	pane_silver				= 9,

	glass_gray		 		= 10,
	pane_gray_flat	 		= 10,
	pane_gray		   		= 10,

	glass_lime		  		= 11,
	pane_lime_flat	  		= 11,
	pane_lime		   		= 11,

	glass_green		 		= 12,
	pane_green_flat	 		= 12,
	pane_green		  		= 12,

	glass_orange			= 13,
	pane_orange_flat		= 13,
	pane_orange		 		= 13,

	glass_yellow			= 14,
	pane_yellow_flat		= 14,
	pane_yellow		 		= 14,

	glass_black		 		= 15,
	pane_black_flat	 		= 15,
	pane_black		  		= 15,

	glass_magenta	   		= 16,
	pane_magenta_flat   	= 16,
	pane_magenta			= 16
}

local function get_beacon_beam(glass_nodename)
	if glass_nodename == "air" then return 0 end
	local glass_string = glass_nodename:split(':')[2]
	if not pallete_order[glass_string] then return 0 end
	return pallete_order[glass_string]
end

local function set_node_if_clear(pos,node)
	local tn = minetest.get_node(pos)
	local def = minetest.registered_nodes[tn.name]
	if tn.name == "air" or (def and def.buildable_to) then
		minetest.set_node(pos,node)
	end
end

minetest.register_node("mcl_beacons:beacon_beam", {
	tiles = {"blank.png^[noalpha^[colorize:#b8bab9"},
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.1250, -0.5000, -0.1250, 0.1250, 0.5000, 0.1250}
		}
	},
	pointable= false,
	light_source = minetest.LIGHT_MAX,
	walkable = false,
	groups = {not_in_creative_inventory=1},
	_mcl_blast_resistance = 1200,
	paramtype2 = "color",
	palette = "beacon_beam_palette.png",
	palette_index = 0,
	buildable_to = true,
})

mesecon.register_mvps_stopper("mcl_beacons:beacon_beam")

local function remove_beacon_beam(pos)
	for y=pos.y, pos.y+301 do
		local node = minetest.get_node({x=pos.x,y=y,z=pos.z})
		if node.name ~= "air" and node.name ~= "mcl_core:bedrock" and node.name ~= "mcl_core:void" then
			if node.name == "ignore" then
				minetest.get_voxel_manip():read_from_map({x=pos.x,y=y,z=pos.z}, {x=pos.x,y=y,z=pos.z})
				node = minetest.get_node({x=pos.x,y=y,z=pos.z})
			end

			if node.name == "mcl_beacons:beacon_beam" then
				minetest.remove_node({x=pos.x,y=y,z=pos.z})
			end
		end
	end
end

local function beacon_blockcheck(pos)
	for y_offset = 1,4 do
		local block_y = pos.y - y_offset
		for block_x = (pos.x-y_offset),(pos.x+y_offset) do
			for block_z = (pos.z-y_offset),(pos.z+y_offset) do
				local valid_block = false --boolean which stores if block is valid or not
				for _, beacon_block in pairs(mcl_beacons.blocks) do
					if beacon_block == minetest.get_node({x=block_x,y=block_y,z=block_z}).name and not valid_block then --is the block in the pyramid a valid beacon block
						valid_block =true
					end
				end
				if not valid_block then
					return y_offset -1 --the last layer is complete, this one is missing or incomplete
				end
			end
		end
		if y_offset == 4 then --all checks are done, beacon is maxed
			return y_offset
		end
	end
end

local function clear_obstructed_beam(pos)
	for y=pos.y+1, pos.y+100 do
		local nodename = minetest.get_node({x=pos.x,y=y, z = pos.z}).name
		if nodename ~= "mcl_core:bedrock" and nodename ~= "air" and nodename ~= "mcl_core:void" and nodename ~= "ignore" then --ignore means not loaded, let's just assume that's air
			if nodename ~="mcl_beacons:beacon_beam" then
				if minetest.get_item_group(nodename,"glass") == 0 and minetest.get_item_group(nodename,"material_glass") == 0  then
					remove_beacon_beam(pos)
					return true
				end
			end
		end
	end

	return false
end

local function effect_player(effect, pos, power_level, effect_level,player)
	local distance =  vector.distance(player:get_pos(), pos)
	if distance > (power_level+1)*10 then return end
	mcl_potions.give_effect_by_level (effect, player, effect_level, 16)
end

local function apply_effects_to_all_players(pos)
	local meta = minetest.get_meta(pos)
	local effect_string = meta:get_string("effect")
	local effect_level = meta:get_int("effect_level")
	local secondary = meta:get_string ("secondary_effect")

	local power_level = beacon_blockcheck(pos)

	if effect_level == 2 and power_level < 4 then --no need to run loops when beacon is in an invalid setup :P
		return
	end

	local beacon_distance = (power_level + 1) * 10

	for player in mcl_util.connected_players(pos, beacon_distance) do
		if not clear_obstructed_beam (pos) then
			effect_player (effect_string, pos, power_level, effect_level, player)
			if secondary and secondary ~= "" and power_level == 4 then
				effect_player (secondary, pos, power_level, 1, player)
			end
		end
	end
end

local function allow_metadata_inventory_take(pos, _, _, stack, player)
	local name = player:get_player_name()
	if minetest.is_protected(pos, name) then
		minetest.record_protection_violation(pos, name)
		return 0
	end
	return stack:get_count()
end

local function allow_metadata_inventory_put(pos, listname, index, stack, player)
	return allow_metadata_inventory_take(pos, listname, index, stack, player)
end

local function allow_metadata_inventory_move()
	return 0
end

local open_beacons = {}

local function upgrade_effect_level_button (oldmeta)
	local effect = oldmeta:get_string ("effect")
	if effect and effect ~= "" then
	local pdef = mcl_potions.registered_effects[effect] or { }
	local tooltip = (pdef.description or "???") .. " II"
	return ("image_button[8.5,3.5;1,1;"
		.. (pdef.icon or "unknown.png")
		.. ";upgrade_ii;]"
		.. "tooltip[8.5,3.5;1,1;" .. tooltip .. "]")
	else
	return ""
	end
end

local function generate_beacon_formspec (pos, meta)
	return ("size[11,14]"
		.. "label[0.5,1;"..minetest.formspec_escape(S("Primary Power:")).."]"
		.. "label[5.5,1;"..minetest.formspec_escape(S("Secondary Power:")).."]"
		.. "label[0.5,8.25;"..minetest.formspec_escape( S("Inventory:")).."]"
		.. "image[1,1.5;1,1;custom_beacon_symbol_4.png]"
		.. "image[1,3;1,1;custom_beacon_symbol_3.png]"
		.. "image[1,4.5;1,1;custom_beacon_symbol_2.png]"
		.. "image[6,3.5;1,1;custom_beacon_symbol_1.png]"
		.. "image_button[2.5,1.5;1,1;mcl_potions_effect_swift.png;swiftness;]"
		.. "image_button[3.5,1.5;1,1;mcl_potions_effect_haste.png;haste;]"
		.. "image_button[2.5,3;1,1;mcl_potions_effect_resistance.png;resistance;]"
		.. "image_button[3.5,3;1,1;mcl_potions_effect_leaping.png;leaping;]"
		.. "image_button[3.0,4.5;1,1;mcl_potions_effect_strong.png;strength;]"
		.. "image_button[7.5,3.5;1,1;mcl_potions_effect_regenerating.png;regeneration;]"
		.. upgrade_effect_level_button (meta)
		.. "item_image[1,7;1,1;mcl_core:diamond]"
		.. "item_image[2.2,7;1,1;mcl_core:emerald]"
		.. "item_image[3.4,7;1,1;mcl_core:iron_ingot]"
		.. "item_image[4.6,7;1,1;mcl_core:gold_ingot]"
		.. "item_image[5.8,7;1,1;mcl_nether:netherite_ingot]"
		.. mcl_formspec.get_itemslot_bg(7.2,7,1,1)
		.. string.format ("list[nodemeta:%s,%s,%s;input;7.2,7;1,1;]",
				  pos.x, pos.y, pos.z)
		.. mcl_formspec.get_itemslot_bg(1,9,9,3)
		.. "list[current_player;main;1,9;9,3;9]"
		.. mcl_formspec.get_itemslot_bg(1,12.5,9,1)
		.. "list[current_player;main;1,12.5;9,1;]")
end

minetest.register_node("mcl_beacons:beacon", {
	description = S("Beacon"),
	drawtype = "mesh",
	collisionbox = {-0.5, -0.5, -0.5, 0.5, 0.5, 0.5},
	mesh = "mcl_beacon.b3d",
	tiles = {"beacon_UV.png"},
	is_ground_content = false,
	use_texture_alpha = "clip",
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		inv:set_size("input", 1)
	end,
	on_destruct = function(pos)
		local meta = minetest.get_meta(pos)
		local input = meta:get_inventory():get_stack("input",1)
		if not input:is_empty() then
			local p = {x=pos.x+math.random(0, 10)/10-0.5, y=pos.y, z=pos.z+math.random(0, 10)/10-0.5} --from mcl_anvils
			minetest.add_item(p, input)
		end
		remove_beacon_beam(pos)
	end,
	on_rightclick = function (pos, node, clicker)
		local name = clicker:get_player_name ()
		if minetest.is_protected (pos, name) then
		minetest.record_protection_violation (pos, name)
		return 0
		end
		minetest.show_formspec (clicker:get_player_name (),
					"mcl_beacons:beacon_formspec",
					generate_beacon_formspec (pos,
								  minetest.get_meta (pos)))
		open_beacons[name] = pos
	end,
	allow_metadata_inventory_put = allow_metadata_inventory_put,
	allow_metadata_inventory_move = allow_metadata_inventory_move,
	allow_metadata_inventory_take = allow_metadata_inventory_take,
	light_source = minetest.LIGHT_MAX,
	groups = {handy=1, deco_block=1},
	drop = "mcl_beacons:beacon",
	sounds = mcl_sounds.node_sound_glass_defaults(),
	_mcl_hardness = 3,
})

mesecon.register_mvps_stopper("mcl_beacons:beacon")

function mcl_beacons.register_beaconblock (itemstring)--API function for other mods
	table.insert(mcl_beacons.blocks, itemstring)
end

function mcl_beacons.register_beaconfuel(itemstring)
	table.insert(mcl_beacons.fuel, itemstring)
end

minetest.register_abm{
	label="update beacon beam",
	nodenames = {"mcl_beacons:beacon_beam"},
	interval = 1,
	chance = 1,
	action = function(pos)
		local node_below = minetest.get_node({x=pos.x,y=pos.y-1,z=pos.z})
		local node_above = minetest.get_node({x=pos.x,y=pos.y+1,z=pos.z})
		local node_current = minetest.get_node(pos)

		if node_below.name ~= "mcl_beacons:beacon" and minetest.get_item_group(node_below.name,"material_glass") == 0 and node_below.name ~= "mcl_beacons:beacon_beam" then
			if minetest.get_node({x=pos.x,y=pos.y-2,z=pos.z}).name == "mcl_beacons:beacon" then
				set_node_if_clear({x=pos.x,y=pos.y-1,z=pos.z},{name="mcl_beacons:beacon_beam",param2=0})
			end
			remove_beacon_beam(pos)
		elseif node_above.name == "air" or (node_above.name == "mcl_beacons:beacon_beam" and node_above.param2 ~= node_current.param2) then
			set_node_if_clear({x=pos.x,y=pos.y+1,z=pos.z},{name="mcl_beacons:beacon_beam",param2=node_current.param2})
		elseif minetest.get_item_group(node_above.name, "glass") ~= 0 or minetest.get_item_group(node_above.name,"material_glass") ~= 0 then
			set_node_if_clear({x=pos.x,y=pos.y+2,z=pos.z},{name="mcl_beacons:beacon_beam",param2=get_beacon_beam(node_above.name)})
		end
	end,
}

minetest.register_abm{
	label="apply beacon effects to players",
	nodenames = {"mcl_beacons:beacon"},
	interval = 3,
	chance = 1,
	action = function(pos)
		apply_effects_to_all_players(pos)
	end,
}

minetest.register_craft({
	output = "mcl_beacons:beacon",
	recipe = {
		{"mcl_core:glass", "mcl_core:glass", "mcl_core:glass"},
		{"mcl_core:glass", "mcl_mobitems:nether_star", "mcl_core:glass"},
		{"mcl_core:obsidian", "mcl_core:obsidian", "mcl_core:obsidian"}
	}
})

local function upgrade_old_data (pos, node, dtime_s)
	-- Clear the primary effect if it is Regeneration, or substitute
	-- `strength' for the old value `strenght'.
	local meta = minetest.get_meta (pos)
	if meta:get_string ("effect") == "regeneration" then
	meta:set_string ("effect", "")
	meta:set_string ("secondary_effect", "regeneration")
	meta:set_string ("effect_level", 1)
	elseif meta:get_string ("effect") == "strenght" then
	meta:set_string ("effect", "strength")
	end
	-- Clear previously installed formspec properties, now that they
	-- are now computed and displayed from within on_rightclick.
	meta:set_string ("formspec", "")
end

minetest.register_lbm ({
	label = "Upgrade legacy beacon data",
	name = "mcl_beacons:upgrade_data",
	nodenames = {"mcl_beacons:beacon"},
	run_at_every_load = false,
	action = upgrade_old_data,
})

-- Remove players who depart from `open_beacons'

minetest.register_on_leaveplayer (function (player, timed_out)
	open_beacons[player] = nil
end)

local function apply_beacon_formspec (sender, formname, fields)
	if formname ~= "mcl_beacons:beacon_formspec" then
	return
	end
	local sender_name = sender:get_player_name ()
	local pos = open_beacons[sender_name]
	if fields.quit then
	open_beacons[sender_name] = nil
	return
	end
	-- Return if the node is no longer a beacon.
	if not pos or minetest.get_node (pos).name ~= "mcl_beacons:beacon" then
	return
	end
	if (fields.swiftness or fields.regeneration or fields.leaping
	or fields.strength or fields.upgrade_ii or fields.resistance
	or fields.haste) then
	local power_level = beacon_blockcheck (pos)

	if minetest.is_protected (pos, sender_name) then
		minetest.record_protection_violation(pos, sender_name)
		return
	elseif power_level == 0 then
		return
	end

	local meta = minetest.get_meta (pos)
	local inv = meta:get_inventory ()
	local input = inv:get_stack ("input", 1)

	if input:is_empty() then
		return
	end

	local valid_item = false

	for _, item in ipairs (mcl_beacons.fuel) do
		if input:get_name () == item then
		valid_item = true
		end
	end

	if not valid_item then
		return
	end

	local successful = false

	if fields.swiftness then
		meta:set_string ("effect", "swiftness")
		if minetest.get_meta (pos):get_int ("effect_level") < 1 then
		meta:set_int ("effect_level", 1)
		end
		successful = true
	elseif fields.haste then
		meta:set_string ("effect", "haste")
		if minetest.get_meta (pos):get_int ("effect_level") < 1 then
		meta:set_int ("effect_level", 1)
		end
		successful = true
	elseif fields.leaping and power_level >= 2 then
		meta:set_string ("effect", "leaping")
		if minetest.get_meta (pos):get_int ("effect_level") < 1 then
		meta:set_int ("effect_level", 1)
		end
		successful = true
	elseif fields.resistance and power_level >= 2 then
		meta:set_string ("effect", "resistance")
		if minetest.get_meta (pos):get_int ("effect_level") < 1 then
		meta:set_int ("effect_level", 1)
		end
		successful = true
	elseif fields.strength and power_level >= 3 then
		meta:set_string ("effect","strength")
		if minetest.get_meta (pos):get_int ("effect_level") < 1 then
		meta:set_int ("effect_level", 1)
		end
		successful = true
	elseif fields.regeneration and power_level == 4 then
		-- If a secondary effect is enabled, the effect level must
		-- be reset to 1.
		meta:set_int ("effect_level", 1)
		meta:set_string ("secondary_effect", "regeneration")
		successful = true
	elseif fields.upgrade_ii and power_level == 4 then
		-- Upgrade the primary effect to II but cancel the
		-- secondary one.  Also verify that there is an effect to
		-- upgrade.
		if minetest.get_meta (pos):get_string ("effect")
		and minetest.get_meta (pos):get_int ("effect_level") < 2 then
		minetest.get_meta (pos):set_int ("effect_level", 2)
		minetest.get_meta (pos):set_string ("secondary_effect", "")
		successful = true
		end
	end
	if successful then
		if power_level == 4 then
		awards.unlock(sender_name, "mcl:maxed_beacon")
		end
		awards.unlock(sender_name, "mcl:beacon")
		input:take_item ()
		inv:set_stack("input",1,input)

		local beam_palette_index = 0
		remove_beacon_beam(pos)
		for y = pos.y +1, pos.y + 201 do
		local node = minetest.get_node({x=pos.x,y=y,z=pos.z})
		if node.name == "ignore" then
			minetest.get_voxel_manip():read_from_map({x=pos.x,y=y,z=pos.z}, {x=pos.x,y=y,z=pos.z})
			node = minetest.get_node({x=pos.x,y=y,z=pos.z})
		end

		if minetest.get_item_group(node.name, "glass") ~= 0 or minetest.get_item_group(node.name,"material_glass") ~= 0 then
			beam_palette_index = get_beacon_beam(node.name)
		end

		if node.name == "air" then
			minetest.set_node({x=pos.x,y=y,z=pos.z},{name="mcl_beacons:beacon_beam",param2=beam_palette_index})
		end
		end
		apply_effects_to_all_players(pos) --call it once outside the globalstep so the player gets the effect right after selecting it
		-- Redisplay the formspec.
		minetest.show_formspec (sender_name,
					"mcl_beacons:beacon_formspec",
					generate_beacon_formspec (pos, meta))
	end
	end
end

minetest.register_on_player_receive_fields (apply_beacon_formspec)
