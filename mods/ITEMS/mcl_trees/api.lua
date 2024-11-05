-- Tree nodes: Wood, Wooden Planks, Sapling, Leaves, Stripped Wood
local S = minetest.get_translator(minetest.get_current_modname())
local bark_stairs = minetest.settings:get_bool("mcl_extra_nodes",true)

local wood_groups = {
	handy = 1, axey = 1, material_wood = 1,
	flammable = 3, fire_encouragement = 5, fire_flammability = 20
}

local wood_sounds = mcl_sounds.node_sound_wood_defaults()

local function queue()
	return {
		front = 1,
		back = 1,
		queue = {},
		enqueue = function(self, value)
			self.queue[self.back] = value
			self.back = self.back + 1
		end,
		dequeue = function(self) local value = self.queue[self.front]
			if not value then
				return
			end
			self.queue[self.front] = nil
			self.front = self.front + 1
			return value
		end,
		size = function(self)
			return self.back - self.front
		end,
	}
end

-- Make leaves which do not have a log within 6 nodes orphan.
local function update_far_away_leaves(pos)
	local logs = minetest.find_nodes_in_area(pos:subtract(12), pos:add(12), "group:tree")

	local function distance(a, b)
		return math.abs(a.x - b.x) + math.abs(a.y - b.y) + math.abs(a.z - b.z)
	end

	local function log_in_range(lpos)
		for _, tpos in pairs(logs) do
			if distance(lpos, tpos) <= 6 then
				return true
			end
		end
		return false
	end

	local leaves = minetest.find_nodes_in_area(pos:subtract(6), pos:add(6), "group:leaves")
	for _, lpos in pairs(leaves) do
		if not log_in_range(lpos) then
			local node = minetest.get_node(lpos)
			local ndef = minetest.registered_nodes[node.name]
			if math.floor(node.param2 / 32) ~= 1 and ndef._mcl_leaves then
				minetest.swap_node(lpos, {
					name = ndef._mcl_orphan_leaves,
					param2 = node.param2,
				})
			end
		end
	end
end

local tree_tab = {}
local leaves_tab = {}
local orphan_tab = {}

local directions = {
	vector.new(1, 0, 0),
	vector.new(-1, 0, 0),
	vector.new(0, 1, 0),
	vector.new(0, -1, 0),
	vector.new(0, 0, 1),
	vector.new(0, 0, -1),
}

minetest.register_on_mods_loaded(function()
	for name, ndef in pairs(minetest.registered_nodes) do
		local cid = minetest.get_content_id(name)
		tree_tab[cid] = minetest.get_item_group(name, "tree") ~= 0 and true or nil
		if minetest.get_item_group(name, "leaves") ~= 0 and ndef._mcl_leaves then
			local def = {
				c_leaves = minetest.get_content_id(ndef._mcl_leaves),
				c_orphan_leaves = minetest.get_content_id(ndef._mcl_orphan_leaves),
			}
			leaves_tab[cid] = def
			orphan_tab[cid] = minetest.get_item_group(name, "orphan_leaves") ~= 0 and def or nil
		end
	end
end)

local function update_leaves(pos, old_distance)
	local vm = minetest.get_voxel_manip()
	local emin, emax = vm:read_from_map(pos:offset(-8, -8, -8), pos:offset(8, 8, 8))
	local a = VoxelArea:new{MinEdge = emin, MaxEdge = emax}
	local data = vm:get_data()
	local param2_data = vm:get_param2_data()

	local function get_distance(ind)
		local cid = data[ind]
		if tree_tab[cid] then
			return 0
		elseif orphan_tab[cid] then
			return 7
		elseif leaves_tab[cid] then
			return math.max(math.floor(param2_data[ind] / 32) - 1, 0)
		end
	end

	local function update_distance(ind, distance)
		data[ind] = distance < 7 and leaves_tab[data[ind]].c_leaves or
				leaves_tab[data[ind]].c_orphan_leaves
		param2_data[ind] = (distance + 1) * 32 + param2_data[ind] % 32
	end

	local clear_queue = queue()
	local fill_queue = queue()
	if old_distance then
		clear_queue:enqueue({ pos = pos, distance = old_distance })
	end
	if get_distance(a:indexp(pos)) then
		fill_queue:enqueue({ pos = pos, distance = get_distance(a:indexp(pos)) })
	end

	while clear_queue:size() > 0 do
		local entry = clear_queue:dequeue()
		local pos = entry.pos ---@diagnostic disable-line: need-check-nil
		local distance = entry.distance ---@diagnostic disable-line: need-check-nil

		for _, dir in pairs(directions) do
			local pos2 = pos:add(dir)
			local ind2 = a:indexp(pos2)
			local distance2 = get_distance(ind2)
			if distance2 and distance2 < 7 then
				if distance2 > distance then
					if leaves_tab[data[ind2]] then
						update_distance(ind2, 7)
						clear_queue:enqueue({ pos = pos2, distance = distance + 1 })
					end
				else
					fill_queue:enqueue({ pos = pos2, distance = distance2 })
				end
			end
		end
	end

	while fill_queue:size() > 0 do
		local entry = fill_queue:dequeue()
		local pos = entry.pos ---@diagnostic disable-line: need-check-nil
		local distance2 = entry.distance + 1 ---@diagnostic disable-line: need-check-nil

		for _, dir in pairs(directions) do
			local pos2 = pos:add(dir)
			local ind2 = a:indexp(pos2)
			if leaves_tab[data[ind2]] and get_distance(ind2) > distance2 then
				update_distance(ind2, distance2)
				fill_queue:enqueue({ pos = pos2, distance = distance2 })
			end
		end
	end

	vm:set_data(data)
	vm:set_param2_data(param2_data)
	vm:write_to_map(false)
end

-- called from leaves after_place_node
local function set_placed_leaves_p2(pos)
	local n = minetest.get_node(pos)
	local palette_index = 0
	if minetest.get_item_group(n.name, "biomecolor") ~= 0 then
		palette_index = mcl_util.get_pos_p2(pos)
	end

	-- 32 represents a log distance of 0 (which means the no decay)
	n.param2 = 32 + palette_index
	minetest.swap_node(pos,n)
end

local tpl_log = {
	_doc_items_hidden = false,
	paramtype2 = "facedir",
	groups = table.merge(wood_groups, {
		tree = 1, building_block = 1, supports_mushrooms=1
	}),
	sounds = mcl_sounds.node_sound_wood_defaults(),
	on_place = mcl_util.rotate_axis,
	on_rotate = screwdriver.rotate_3way,
	_on_axe_place = mcl_trees.strip_tree,
	_mcl_blast_resistance = 2,
	_mcl_hardness = 2,
	_mcl_burntime = 15,
	_mcl_cooking_output = "mcl_core:charcoal_lump"
}
local tpl_wood = {
	_doc_items_hidden = false,
	is_ground_content = false,
	groups = table.merge(wood_groups,{wood = 1, building_block = 1}),
	sounds = mcl_sounds.node_sound_wood_defaults(),
	_mcl_blast_resistance = 3,
	_mcl_hardness = 2,
	_mcl_burntime = 15
}
local tpl_leaves = {
	_doc_items_hidden = false,
	drawtype = "allfaces_optional",
	waving = 2,
	paramtype = "light",
	paramtype2 = "color",
	palette = "mcl_core_palette_leaves.png",
	groups = {
		handy = 1, hoey = 1, shearsy = 1, swordy = 1, dig_by_piston = 1,
		deco_block = 1, leaves = 1, biomecolor = 1,
		flammable = 2, fire_encouragement = 30, fire_flammability = 60,
		compostability = 30
	},
	_mcl_shears_drop = true,
	sounds = mcl_sounds.node_sound_leaves_defaults(),
	_mcl_blast_resistance = 0.2,
	_mcl_hardness = 0.2,
	_mcl_silk_touch_drop = true,
}

local tpl_sapling = {
	_doc_items_longdesc = S("When placed on soil (such as dirt) and exposed to light, a sapling will grow into a tree after some time."),
	_tt_help = S("Needs soil and light to grow"),
	_doc_items_hidden = false,
	drawtype = "plantlike",
	waving = 1,
	paramtype = "light",
	sunlight_propagates = true,
	walkable = false,
	selection_box = {
		type = "fixed",
		fixed = {-5/16, -0.5, -5/16, 5/16, 0.5, 5/16},
	},
	groups = {
		dig_immediate = 3, dig_by_water = 1, dig_by_piston = 1, destroy_by_lava_flow = 1,
		attached_node = 1,
		deco_block = 1,
		plant = 1, sapling = 1, non_mycelium_plant = 1,
		compostability = 30
	},
	sounds = mcl_sounds.node_sound_leaves_defaults(),
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_int("stage", 0)
	end,
	on_place = mcl_util.generate_on_place_plant_function(function(pos, _)
		local node_below = minetest.get_node_or_nil(vector.offset(pos,0,-1,0))
		if not node_below then return false end
		return minetest.get_item_group(node_below.name, "soil_sapling") > 1
	end),
	_on_bone_meal = function(itemstack, placer, pointed_thing, pos, node) ---@diagnostic disable-line: unused-local
		if math.random() > 0.45 then return end --sapling has a 45% chance to grow when bone mealing
		return mcl_trees.grow_tree(pos,node)
	end,
	node_placement_prediction = "",
	_mcl_blast_resistance = 0,
	_mcl_hardness = 0,
	_mcl_burntime = 5
}

local tpl_door = {
	_doc_items_longdesc = S("Wooden doors are 2-block high barriers which can be opened or closed by hand and by a redstone signal."),
	_doc_items_usagehelp = S("To open or close a wooden door, rightclick it or supply its lower half with a redstone signal."),
	groups = {handy=1,axey=1, material_wood=1, flammable=-1},
	_mcl_hardness = 3,
	_mcl_blast_resistance = 3,
	_mcl_burntime = 10,
	sounds = mcl_sounds.node_sound_wood_defaults(),
}
local tpl_trapdoor = {
	_doc_items_longdesc = S("Wooden trapdoors are horizontal barriers which can be opened and closed by hand or a redstone signal. They occupy the upper or lower part of a block, depending on how they have been placed. When open, they can be climbed like a ladder."),
	_doc_items_usagehelp = S("To open or close the trapdoor, rightclick it or send a redstone signal to it."),
	groups = {handy=1,axey=1, mesecon_effector_on=1, material_wood=1, flammable=-1},
	_mcl_hardness = 3,
	_mcl_blast_resistance = 3,
	_mcl_burntime = 15,
	sounds = mcl_sounds.node_sound_wood_defaults(),
}

-- Set log on_construct/after_destruct like this for compatibility with mods.
minetest.register_on_mods_loaded(function()
	for name, ndef in pairs(minetest.registered_nodes) do
		if minetest.get_item_group(name, "tree") ~= 0 then
			local old_on_cons = ndef.on_construct
			local old_after_dest = ndef.after_destruct
			minetest.override_item(name, {
				on_construct = function(pos)
					if old_on_cons then
						old_on_cons(pos)
					end
					update_leaves(pos)
				end,
				after_destruct = function(pos)
					if old_after_dest then
						old_after_dest(pos)
					end
					update_far_away_leaves(pos)
					update_leaves(pos, 0)
				end,
			})
		end
	end
end)

function mcl_trees.generate_leaves_def(modname, subname, def, sapling, drop_apples, sapling_chances)
	local apple_chances = {200, 180, 160, 120, 40}
	local stick_chances = {50, 45, 30, 35, 10}

	local palette = tpl_leaves.palette
	if def.palette == "" then
		palette = def.palette
	end

	local function get_drops(fortune_level)
		local drop = {
			max_items = 1,
			items = {
				{
					items = {"mcl_core:stick 1"},
					rarity = stick_chances[fortune_level + 1]
				},
				{
					items = {"mcl_core:stick 2"},
					rarity = stick_chances[fortune_level + 1]
				},
			}
		}
		if type(sapling) == "string" then
			table.insert(drop.items, {
				items = {sapling},
				rarity = sapling_chances[fortune_level + 1] or sapling_chances[fortune_level]
			})
		elseif type(sapling) == "table" then
			for _, s in pairs(sapling) do
				table.insert(drop.items, {
						items = {s},
						rarity = sapling_chances[fortune_level + 1] or sapling_chances[fortune_level]
				})
			end
		end
		if drop_apples then
			table.insert(drop.items, {
				items = {"mcl_core:apple"},
				rarity = apple_chances[fortune_level + 1]
			})
		end
		return drop
	end

	local leaves_id = modname .. subname
	local orphan_leaves_id = modname .. subname.. "_orphan"

	local basedef = table.merge(tpl_leaves, {
		drop = get_drops(0),
		after_place_node = set_placed_leaves_p2,
		_mcl_fortune_drop = { get_drops(1), get_drops(2), get_drops(3), get_drops(4) },
		_mcl_leaves = leaves_id,
		_mcl_orphan_leaves = orphan_leaves_id,
	}, def or {}, { palette = palette })

	local l_def = table.merge(basedef, {
		on_construct = function(pos)
			update_leaves(pos)
		end,
		after_destruct = function(pos, oldnode)
			update_leaves(pos, math.max(math.floor(oldnode.param2 / 32) - 1, 0))
		end,
	})
	local o_def = table.merge(basedef, {
		_doc_items_create_entry = false,
		_mcl_shears_drop = {leaves_id},
		_mcl_silk_touch_drop = {leaves_id},
	})
	o_def.groups = table.merge(l_def.groups, {
		not_in_creative_inventory = 1,
		orphan_leaves = 1,
	})

	return {
		leaves_id = leaves_id,
		leaves_def = l_def,
		orphan_leaves_id = orphan_leaves_id,
		orphan_leaves_def = o_def,
	}
end

local function register_leaves(subname, def, sapling, drop_apples, sapling_chances)
	local d = mcl_trees.generate_leaves_def("mcl_trees:", subname, def, sapling, drop_apples, sapling_chances)
	minetest.register_node(":" .. d["leaves_id"], d["leaves_def"])
	minetest.register_node(":" .. d["orphan_leaves_id"], d["orphan_leaves_def"])
end

function mcl_trees.register_wood(name, p)
	if not p then p = {} end
	local rname = p.readable_name or name
	if mcl_trees.woods[name] == nil then
		mcl_trees.woods[name] = p
	end
	if p.tree == nil or type(p.tree) == "table" then
		minetest.register_node(":mcl_trees:".."tree_"..name,table.merge(tpl_log,{
			description = S("@1 Log", rname),
			_doc_items_longdesc = S("The trunk of a @1 tree.", rname),
			tiles = { minetest.get_current_modname().."_log_"..name.."_top.png",  "mcl_core_log_"..name.."_top.png", "mcl_core_log_"..name..".png"},
			_mcl_stripped_variant = "mcl_trees:stripped_"..name,
		},p.tree or {}))
	end

	if p.wood == nil or type(p.wood) == "table" then
		minetest.register_node(":mcl_trees:wood_"..name, table.merge(tpl_wood,{
			description =  S("@1 Planks", rname),
			_doc_items_longdesc = doc.sub.items.temp.build,
			tiles = { minetest.get_current_modname().."_planks_"..name..".png"},
		},p.wood or {}))
		minetest.register_craft({
			output = "mcl_trees:wood_"..name.." 4",
			recipe = {
				{ "mcl_trees:tree_"..name },
			}
		})
	end

	if p.bark == nil or type(p.bark) == "table" then
		minetest.register_node(":mcl_trees:bark_"..name,table.merge(tpl_log, {
			description = S("@1 Bark", rname),
			_doc_items_longdesc = S("This is a decorative block surrounded by the bark of a tree trunk."),
			tiles = p.tree and p.tree.tiles and {p.tree.tiles[3]} or { minetest.get_current_modname().."_log_"..name..".png"},
			is_ground_content = false,
			_mcl_stripped_variant = "mcl_trees:bark_stripped_"..name,
		}, p.bark or {}))
		minetest.register_craft({
			output = "mcl_trees:bark_"..name.." 3",
			recipe = {
				{ "mcl_trees:tree_"..name, "mcl_trees:tree_"..name },
				{ "mcl_trees:tree_"..name, "mcl_trees:tree_"..name },
			}
		})
	end

	if p.stripped == nil or type(p.stripped) == "table" then
		minetest.register_node(":mcl_trees:stripped_"..name, table.merge(tpl_log, {
			description = S("Stripped @1 Log", rname),
			_doc_items_longdesc = S("The stripped trunk of an @1 tree.", rname),
			_doc_items_hidden = false,
			tiles = { minetest.get_current_modname().."_stripped_"..name.."_top.png",  "mcl_core_stripped_"..name.."_top.png", "mcl_core_stripped_"..name.."_side.png"},
		}, p.stripped or {}))
	end

	if p.stripped_bark == nil or type(p.stripped_bark) == "table" then
		minetest.register_node(":mcl_trees:bark_stripped_"..name, table.merge(tpl_log, {
			description = S("Stripped @1 Wood", rname),
			_doc_items_longdesc = S("The stripped wood of an @1 tree.", rname),
			tiles = { minetest.get_current_modname().."_stripped_"..name.."_side.png"},
			is_ground_content = false,
		}, p.stripped_bark or {}))
	end

	if p.sapling == nil or type(p.sapling) == "table" then
		minetest.register_node(":mcl_trees:sapling_"..name, table.merge(tpl_sapling, {
			description = S("@1 Sapling", rname),
			tiles = { minetest.get_current_modname().."_sapling_"..name..".png"},
			inventory_image = minetest.get_current_modname().."_sapling_"..name..".png",
			wield_image = minetest.get_current_modname().."_sapling_"..name..".png",
		}, p.sapling or {}))
	end


	if p.leaves == nil or type(p.leaves) == "table" then
		register_leaves("leaves_"..name,
			table.merge({
				description = S("@1 Leaves", rname),
				_doc_items_longdesc = S("@1 leaves are grown from @2 trees.", rname, rname),
				tiles = { minetest.get_current_modname().."_leaves_"..name..".png"},
			}, p.leaves or {} ),
			p.saplingdrop or ( "mcl_trees:sapling_"..name ),
			p.drop_apples or false,
			p.sapling_chances or {20, 16, 12, 10}
		)
	end
	if p.fence == nil or type(p.fence) == "table" then
		p.fence = p.fence or {}
		mcl_fences.register_fence_def(name.."_fence", table.merge({
			description = p.fence.description or S("@1 Fence", rname),
			tiles = p.fence.tiles or { "mcl_fences_fence_"..name..".png" },
			groups = p.fence.groups or table.merge(wood_groups, { fence_wood = 1 }),
			connects_to = p.fence.connects_to or { "group:fence_wood", "group:solid" },
			sounds = p.fence.sounds or wood_sounds,
			_mcl_blast_resistance = p.fence._mcl_blast_resistance or 3,
			_mcl_hardness = p.fence._mcl_hardness or 2,
			_mcl_burntime = p.fence._mcl_burntime or 15,
			_mcl_fences_baseitem = "mcl_trees:wood_"..name
		}, p.fence))
	end
	if p.fence_gate == nil or type(p.fence_gate) == "table" then
		p.fence_gate = p.fence_gate or {}
		mcl_fences.register_fence_gate_def(name.."_fence", table.merge({
			description = p.fence_gate.description or S("@1 Fence Gate", rname),
			tiles = p.fence_gate.tiles or { "mcl_fences_fence_"..name..".png" },
			groups = p.fence_gate.groups or table.merge(wood_groups,{fence_wood = 1}),
			_mcl_blast_resistance = p.fence_gate._mcl_blast_resistance or 3,
			_mcl_hardness = p.fence_gate._mcl_hardness or 2,
			sounds = p.fence_gate.sounds or wood_sounds,
			_mcl_fences_sounds = {
				open = {
					spec = p.fence_gate.sound_open,
					gain = p.fence_gate.sound_gain_open,
				},
				close = {
					spec = p.fence_gate.sound_close,
					gain = p.fence_gate.sound_gain_close
				}
			},
			_mcl_burntime = p.fence_gate._mcl_burntime or 15,
			_mcl_fences_baseitem = "mcl_trees:wood_"..name}, p.fence_gate))
	end
	if p.door == nil or type(p.door) == "table" then
		mcl_doors:register_door("mcl_doors:door_"..name,table.merge(tpl_door, {
			description = S("@1 Door", rname),
			inventory_image = "mcl_doors_door_"..name..".png",
			tiles_bottom = {"mcl_doors_door_"..name.."_lower.png", "mcl_doors_door_"..name.."_side_lower.png"},
			tiles_top = {"mcl_doors_door_"..name.."_upper.png", "mcl_doors_door_"..name.."_side_upper.png"}
		}, p.door or {}))
		minetest.register_craft({
			output = "mcl_doors:door_"..name.." 3",
			recipe = {
				{"mcl_trees:wood_"..name, "mcl_trees:wood_"..name},
				{"mcl_trees:wood_"..name, "mcl_trees:wood_"..name},
				{"mcl_trees:wood_"..name, "mcl_trees:wood_"..name}
			}
		})
	end
	if p.trapdoor == nil or type(p.trapdoor) == "table" then
		mcl_doors:register_trapdoor("mcl_doors:trapdoor_"..name,table.merge(tpl_trapdoor, {
			description = S("@1 Trapdoor", rname),
			tile_front = "mcl_doors_trapdoor_"..name..".png",
			tile_side = "mcl_doors_trapdoor_"..name.."_side.png",
			wield_image = "mcl_doors_trapdoor_"..name..".png",
		}, p.trapdoor or {}))
		minetest.register_craft({
			output = "mcl_doors:trapdoor_"..name.." 2",
			recipe = {
				{"mcl_trees:wood_"..name,"mcl_trees:wood_"..name,"mcl_trees:wood_"..name,},
				{"mcl_trees:wood_"..name,"mcl_trees:wood_"..name,"mcl_trees:wood_"..name,},
			}
		})
	end

	if p.stairs == nil or type(p.stairs) == "table" then
		p.stairs = p.stairs or {}
		mcl_stairs.register_stair(name, table.merge({
			baseitem="mcl_trees:wood_"..name,
			description = S("@1 Stairs", rname),
			groups = { wood_stairs = 1 },
			overrides = {
				_mcl_burntime = 15
			},
		}, p.stairs))
		if p.bark == nil or type(p.bark) == "table"  then
			mcl_stairs.register_stair(name.."_bark", table.merge({
				baseitem="mcl_trees:bark_"..name,
				description = S("@1 Bark Stairs", rname),
				groups = { bark_stairs = 1 },
				recipeitem=bark_stairs and "mcl_trees:bark_"..name or "",
				overrides = {
					_mcl_burntime = 15
				},
			}, p.stairs))
		end
	end

	if p.slab == nil or type(p.slab) == "table" then
		p.slab = p.slab or {}
		mcl_stairs.register_slab(name, table.merge({
			baseitem="mcl_trees:wood_"..name,
			description = S("@1 Slab", rname),
			groups = { wood_slab = 1 },
			register_stair_and_slab = false,
			overrides = {
				_mcl_burntime = 7.5,
			},
		}, p.slab))
		if p.bark == nil or type(p.bark) == "table" then
			mcl_stairs.register_slab(name.."_bark", table.merge({
				baseitem="mcl_trees:bark_"..name,
				description = S("@1 Bark Slab", rname),
				groups = { bark_slab = 1 },
				recipeitem=bark_stairs and "mcl_trees:bark_"..name or "",
				overrides = {
					_mcl_burntime = 7.5,
				},
			}, p.slab))
		end
	end
	if p.sign_color and ( p.sign == nil or type(p.sign) == "table" ) then
		mcl_signs.register_sign(name,p.sign_color,table.merge({
			description = S("@1 Sign", rname),
			_mcl_burntime = 10
		}, p.sign or {}))
		minetest.register_craft({
			output = "mcl_signs:wall_sign_"..name.." 3",
			recipe = {
				{"mcl_trees:wood_"..name,"mcl_trees:wood_"..name,"mcl_trees:wood_"..name,},
				{"mcl_trees:wood_"..name,"mcl_trees:wood_"..name,"mcl_trees:wood_"..name,},
				{"","mcl_core:stick",""},
			}
		})
	end

	if p.pressure_plate == nil or type(p.pressure_plate) == "table" then
		p.pressure_plate = p.pressure_plate or {}
		mesecon.register_pressure_plate(
			"mesecons_pressureplates:pressure_plate_"..name,
			S("@1 Pressure Plate", rname),
			p.wood and p.wood.tiles or { minetest.get_current_modname().."_planks_"..name..".png"},
			p.wood and p.wood.tiles or { minetest.get_current_modname().."_planks_"..name..".png"},
			p.wood and p.wood.tiles[1] or "mcl_core_planks_"..name..".png",
			nil,
			{{"mcl_trees:wood_"..name, "mcl_trees:wood_"..name}},
			mcl_sounds.node_sound_wood_defaults(),
			{axey=1, material_wood=1},
			nil,
			S("A wooden pressure plate is a redstone component which supplies its surrounding blocks with redstone power while any movable object (including dropped items, players and mobs) rests on top of it."),
			p.pressure_plate and p.pressure_plate._mcl_burntime or 15
		)
	end
	if p.button == nil or type(p.button) == "table" then
		p.button = p.button or {}
		mesecon.register_button(
			name,
			S("@1 Button", rname),
			p.wood and p.wood.tiles[1] or "mcl_core_planks_"..name..".png",
			"mcl_trees:wood_"..name,
			mcl_sounds.node_sound_wood_defaults(),
			{material_wood=1,handy=1,axey=1},
			1.5,
			true,
			S("A wooden button is a redstone component made out of wood which can be pushed to provide redstone power. When pushed, it powers adjacent redstone components for 1.5 seconds. Wooden buttons may also be pushed by arrows."),
			"mesecons_button_push_wood",
			p.button and p.button._mcl_burntime or 5
		)
	end

	if (p.sapling == nil or type(p.sapling) == "table") and (p.potted_sapling == nil or type(p.potted_sapling) == "table") then
		mcl_flowerpots.register_potted_flower("mcl_trees:sapling_"..name, table.merge({
			name = "sapling_"..name,
			desc = S("@1 Sapling", rname),
			image = minetest.get_current_modname().."_sapling_"..name..".png",
		},p.potted_sapling or {}))
	end

	if p.boat == nil or type(p.boat) == "table" then
		p.boat = p.boat or {}
		mcl_boats.register_boat(name,table.merge({
			description = S("@1 Boat", rname),
		}, p.boat.item or {}), p.boat.object or {}, p.boat.entity or {})
	end
	if p.chest_boat == nil or type(p.chest_boat) == "table" then
		p.chest_boat = p.chest_boat or {}
		mcl_boats.register_boat(name.."_chest",table.merge({
			description = S("@1 Chest Boat", rname),
		}, p.chest_boat.item or {}), p.chest_boat.object or {}, p.chest_boat.entity or {})

	end
end

local modpath = minetest.get_modpath(minetest.get_current_modname())
minetest.register_on_mods_loaded(function()
	mcl_structures.register_structure("wood_test", {
	filenames = {
		modpath.."/schematics/wood_test.mts"
		},
	}, true)
end)

local function get_stairs_nodes()
	local r = {}
	for n, _ in pairs(minetest.registered_nodes) do
		if n:find("_stair") or n:find("_slab") then
			table.insert(r,n)
		end
	end
	return r
end

minetest.register_on_mods_loaded(function()
	mcl_structures.register_structure("stairs_test", {
	place_func = function(pos, _, _)
		local stairs = get_stairs_nodes()
		local s = math.ceil(math.sqrt(#stairs))
		local x = 1
		local y = 1
		for _, n in pairs(stairs) do
			if x > s then x=1 y = y + 1 end
			minetest.set_node(vector.offset(pos,x,y,0),{name=n})
			x = x + 1
		end
	end,
	}, true)
end)
