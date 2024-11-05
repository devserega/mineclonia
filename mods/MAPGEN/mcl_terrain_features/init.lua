local adjacents = {
	vector.new(1,0,0),
	vector.new(1,0,1),
	vector.new(1,0,-1),
	vector.new(-1,0,0),
	vector.new(-1,0,1),
	vector.new(-1,0,-1),
	vector.new(0,0,1),
	vector.new(0,0,-1),
	vector.new(0,-1,0)
}

local function airtower(pos,tbl,h)
	for i=1,h do
		table.insert(tbl,vector.offset(pos,0,i,0))
	end
end

local function makelake(pos,size,liquid,placein,border,pr,noair)
	local p1, p2 = vector.offset(pos,-size,-1,-size), vector.offset(pos,size,-1,size)
	minetest.emerge_area(p1, p2, function(_, _, calls_remaining)
		if calls_remaining ~= 0 then return end
		local nn = minetest.find_nodes_in_area(p1,p2,placein)
		if not nn[1] then return end
		table.sort(nn,function(a, b)
		   return vector.distance(pos, a) < vector.distance(pos, b)
		end)
		local lq, air = {}, {}
		local r = pr:next(math.ceil(#nn/4),#nn)
		for i=1,r do
			airtower(nn[i],air,10)
			table.insert(lq,nn[i])
		end
		mcl_util.bulk_swap_node(lq,{name=liquid})
		mcl_util.bulk_swap_node(air,{name="air"})
		air = {}
		local br = {}
		for _, v in pairs(lq) do
			for _, vv in pairs(adjacents) do
				local pp = vector.add(v,vv)
				local an = minetest.get_node(pp)
				if not border then
					if minetest.get_item_group(an.name,"solid") > 0 then
						border = an.name
					elseif minetest.get_item_group(minetest.get_node(nn[1]).name,"solid") > 0 then
						border = minetest.get_node_or_nil(nn[1]).name
					else
						border = "mcl_core:stone"
					end
					if border == nil or border == "mcl_core:dirt" then border = "mcl_core:dirt_with_grass" end
				end
				if not noair and an.name ~= liquid then
					table.insert(br,pp)
					local un = minetest.get_node(vector.offset(pp,0,1,0))
					if un.name ~= liquid then
						airtower(pp,air,10)
					end
				end
			end
		end
		mcl_util.bulk_swap_node(br,{name=border})
		mcl_util.bulk_swap_node(air,{name="air"})
		return true
	end)
	return true
end

local mushrooms = {"mcl_mushrooms:mushroom_brown","mcl_mushrooms:mushroom_red"}

local function get_fallen_tree_schematic(pos,pr)
	local tree = minetest.find_node_near(pos,15,{"group:tree"})
	if not tree then return end
	tree = minetest.get_node(tree).name
	local maxlen = 8
	local minlen = 2
	local vprob = 120
	local mprob = 160
	local len = pr:next(minlen,maxlen)
	local schem = {
		size = {x = len + 2, y = 2, z = 3},
		data = {
			{name = "air", prob=0},
			{name = "air", prob=0},
		}
	}
	for _ = 1,len do
		table.insert(schem.data,{name = "mcl_core:vine",param2=4, prob=vprob})
	end
	table.insert(schem.data,{name = "air", prob=0})
	table.insert(schem.data,{name = "air", prob=0})
	for _ = 1,len do
		table.insert(schem.data,{name = "air", prob=0})
	end

	table.insert(schem.data,{name = tree, param2 = 0})
	table.insert(schem.data,{name = "air", prob=0})
	for _ = 1,len do
		table.insert(schem.data,{name = tree, param2 = 12})
	end
	table.insert(schem.data,{name = "air", prob=0})
	table.insert(schem.data,{name = "air", prob=0})
	for _ = 1,len do
		table.insert(schem.data,{name =  mushrooms[pr:next(1,#mushrooms)], param2 = 12, prob=mprob})
	end

	table.insert(schem.data,{name = "air", prob=0})
	table.insert(schem.data,{name = "air", prob=0})
	for _ = 1,len do
		table.insert(schem.data,{name = "mcl_core:vine",param2=5, prob=vprob})
	end
	table.insert(schem.data,{name = "air", prob=0})
	table.insert(schem.data,{name = "air", prob=0})
	for _ = 1,len do
		table.insert(schem.data,{name = "air", prob=0})
	end

	return schem
end

mcl_structures.register_structure("fallen_tree",{
	place_on = {"group:grass_block"},
	terrain_feature = true,
	noise_params = {
		offset = 0.00018,
		scale = 0.01011,
		spread = {x = 250, y = 250, z = 250},
		seed = 24533,
		octaves = 3,
		persist = 0.66
	},
	flags = "place_center_x, place_center_z",
	sidelen = 18,
	solid_ground = true,
	y_max = mcl_vars.mg_overworld_max,
	y_min = minetest.get_mapgen_setting("water_level"),
	on_place = function(pos, def)
		local air_p1 = vector.offset(pos,-def.sidelen/2,1,-def.sidelen/2)
		local air_p2 = vector.offset(pos,def.sidelen/2,1,def.sidelen/2)
		local air = minetest.find_nodes_in_area(air_p1,air_p2,{"air"})
		if #air < ( def.sidelen * def.sidelen ) / 2 then
			return false
		end
		return true
	end,
	place_func = function(pos, _, pr)
		local schem=get_fallen_tree_schematic(pos,pr)
		if not schem then return end
		return minetest.place_schematic(pos,schem,"random")
	end
})

mcl_structures.register_structure("lavapool",{
	place_on = {"group:sand", "group:dirt", "group:stone"},
	terrain_feature = true,
	noise_params = {
		offset = 0,
		scale = 0.0000022,
		spread = {x = 250, y = 250, z = 250},
		seed = 78375213,
		octaves = 3,
		persist = 0.001,
		flags = "absvalue",
	},
	spawn_by = "air", -- this should not be necessary, but we had pools spawn underground
	check_offset = 1,
	num_spawn_by = 5,
	flags = "place_center_x, place_center_z, force_placement",
	y_max = mcl_vars.mg_overworld_max,
	y_min = minetest.get_mapgen_setting("water_level"),
	place_func = function(pos, _, pr)
		return makelake(pos,5,"mcl_core:lava_source",{"group:material_stone", "group:sand", "group:dirt"},"mcl_core:stone",pr)
	end
})

mcl_structures.register_structure("water_lake",{
	place_on = {"group:dirt","group:stone"},
	terrain_feature = true,
	noise_params = {
		offset = 0,
		scale = 0.000032,
		spread = {x = 250, y = 250, z = 250},
		seed = 756641353,
		octaves = 3,
		persist = 0.001,
		flags = "absvalue",
	},
	spawn_by = "air", -- this should not be necessary, but we had pools spawn underground
	check_offset = 1,
	num_spawn_by = 5,
	flags = "place_center_x, place_center_z, force_placement",
	y_max = mcl_vars.mg_overworld_max,
	y_min = minetest.get_mapgen_setting("water_level"),
	place_func = function(pos, _, pr)
		return makelake(pos,5,"mcl_core:water_source",{"group:material_stone", "group:sand", "group:dirt","group:grass_block"},"mcl_core:dirt_with_grass",pr)
	end
})

mcl_structures.register_structure("water_lake_mangrove_swamp",{
	place_on = {"mcl_mud:mud"},
	biomes = { "MangroveSwamp" },
	terrain_feature = true,
	noise_params = {
		offset = 0,
		scale = 0.0032,
		spread = {x = 250, y = 250, z = 250},
		seed = 6343241353,
		octaves = 3,
		persist = 0.001,
		flags = "absvalue",
	},
	spawn_by = "air", -- this should not be necessary, but we had pools spawn underground
	check_offset = 1,
	num_spawn_by = 5,
	flags = "place_center_x, place_center_z, force_placement",
	y_max = mcl_vars.mg_overworld_max,
	y_min = minetest.get_mapgen_setting("water_level"),
	place_func = function(pos, _, pr)
		return makelake(pos,3,"mcl_core:water_source",{"group:material_stone", "group:sand", "group:dirt","group:grass_block","mcl_mud:mud"},"mcl_mud:mud",pr,true)
	end
})

mcl_structures.register_structure("basalt_column",{
	place_on = {"mcl_blackstone:blackstone","mcl_blackstone:basalt"},
	terrain_feature = true,
	spawn_by = {"air"},
	num_spawn_by = 2,
	noise_params = {
		offset = 0,
		scale = 0.003,
		spread = {x = 250, y = 250, z = 250},
		seed = 72235213,
		octaves = 5,
		persist = 0.3,
		flags = "absvalue",
	},
	flags = "all_floors",
	y_max = mcl_vars.mg_nether_max - 20,
	y_min = mcl_vars.mg_lava_nether_max + 1,
	biomes = { "BasaltDelta" },
	place_func = function(pos, _, pr)
		local nn = minetest.find_nodes_in_area(vector.offset(pos,-5,-1,-5),vector.offset(pos,5,-1,5),{"air","mcl_blackstone:basalt","mcl_blackstone:blackstone"})
		table.sort(nn,function(a, b)
		   return vector.distance(vector.new(pos.x,0,pos.z), a) < vector.distance(vector.new(pos.x,0,pos.z), b)
		end)
		if #nn < 1 then return false end
		local basalt = {}
		local magma = {}
		for i=1,pr:next(1,#nn) do
			if minetest.get_node(vector.offset(nn[i],0,-1,0)).name ~= "air" then
				local dst=vector.distance(pos,nn[i])
				local r = pr:next(1,14)-dst
				for ii=0,r do
					if pr:next(1,25) == 1 then
						table.insert(magma,vector.new(nn[i].x,nn[i].y + ii,nn[i].z))
					else
						table.insert(basalt,vector.new(nn[i].x,nn[i].y + ii,nn[i].z))
					end
				end
			end
		end
		mcl_util.bulk_swap_node(magma,{name="mcl_nether:magma"})
		mcl_util.bulk_swap_node(basalt,{name="mcl_blackstone:basalt"})
		return true
	end
})
mcl_structures.register_structure("basalt_pillar",{
	place_on = {"mcl_blackstone:blackstone","mcl_blackstone:basalt"},
	terrain_feature = true,
	noise_params = {
		offset = 0,
		scale = 0.001,
		spread = {x = 250, y = 250, z = 250},
		seed = 7113,
		octaves = 5,
		persist = 0.1,
		flags = "absvalue",
	},
	flags = "all_floors",
	y_max = mcl_vars.mg_nether_max-40,
	y_min = mcl_vars.mg_lava_nether_max + 1,
	biomes = { "BasaltDelta" },
	place_func = function(pos, _, pr)
		local nn = minetest.find_nodes_in_area(vector.offset(pos,-2,-1,-2),vector.offset(pos,2,-1,2),{"air","mcl_blackstone:basalt","mcl_blackstone:blackstone"})
		table.sort(nn,function(a, b)
		   return vector.distance(vector.new(pos.x,0,pos.z), a) < vector.distance(vector.new(pos.x,0,pos.z), b)
		end)
		if #nn < 1 then return false end
		local basalt = {}
		local magma = {}
		for i=1,pr:next(1,#nn) do
			if minetest.get_node(vector.offset(nn[i],0,-1,0)).name ~= "air" then
				local dst=vector.distance(pos,nn[i])
				for ii=0,pr:next(19,35)-dst do
					if pr:next(1,20) == 1 then
						table.insert(magma,vector.new(nn[i].x,nn[i].y + ii,nn[i].z))
					else
						table.insert(basalt,vector.new(nn[i].x,nn[i].y + ii,nn[i].z))
					end
				end
			end
		end
		mcl_util.bulk_swap_node(basalt,{name="mcl_blackstone:basalt"})
		mcl_util.bulk_swap_node(magma,{name="mcl_nether:magma"})
		return true
	end
})

mcl_structures.register_structure("lavadelta",{
	place_on = {"mcl_blackstone:blackstone","mcl_blackstone:basalt"},
	spawn_by = {"mcl_blackstone:basalt","mcl_blackstone:blackstone"},
	num_spawn_by = 2,
	terrain_feature = true,
	noise_params = {
		offset = 0,
		scale = 0.005,
		spread = {x = 250, y = 250, z = 250},
		seed = 78375213,
		octaves = 5,
		persist = 0.1,
		flags = "absvalue",
	},
	flags = "all_floors",
	y_max = mcl_vars.mg_nether_max,
	y_min = mcl_vars.mg_lava_nether_max + 1,
	biomes = { "BasaltDelta" },
	place_func = function(pos, _, pr)
		local nn = minetest.find_nodes_in_area_under_air(vector.offset(pos,-10,-1,-10),vector.offset(pos,10,-2,10),{"mcl_blackstone:basalt","mcl_blackstone:blackstone","mcl_nether:netherrack"})
		table.sort(nn,function(a, b)
		   return vector.distance(vector.new(pos.x,0,pos.z), a) < vector.distance(vector.new(pos.x,0,pos.z), b)
		end)
		if #nn < 1 then return false end
		local lava = {}
		for i=1,pr:next(1,#nn) do
			table.insert(lava,nn[i])
		end
		mcl_util.bulk_swap_node(lava,{name="mcl_nether:nether_lava_source"})
		local basalt = {}
		local magma = {}
		for _,v in pairs(lava) do
			for _,vv in pairs(adjacents) do
				local p = vector.add(v,vv)
				if minetest.get_node(p).name ~= "mcl_nether:nether_lava_source" then
					table.insert(basalt,p)

				end
			end
			if math.random(3) == 1 then
				table.insert(magma,v)
			end
		end
		mcl_util.bulk_swap_node(basalt,{name="mcl_blackstone:basalt"})
		mcl_util.bulk_swap_node(magma,{name="mcl_nether:magma"})
		return true
	end
})

-- Powder snow traps
mcl_structures.register_structure("powder_snow_trap", {
	place_on = {"mcl_core:snowblock", "mcl_core:snow", "group:grass_block_snow"},
	sidelen = 80,
	noise_params = {
		offset = 0.00040,
		scale = 0.001,
		spread = {x = 500, y = 500, z = 500},
		seed = 2137,
		octaves = 4,
		persist = 0.67,
	},
	biomes = {"IcePlainsSpikes, ColdTaiga, ColdTaiga_beach, IcePlains"},
	y_min = 1,
	y_max = mcl_vars.mg_overworld_max,
	terrain_feature = true,
	place_func = function(pos)
		local width  = math.random(6) - 3
		local length = math.random(6) - 3
		local depth  = math.random(4)

		local solid_nodes = {}
		local node_name
		for i = 0, width do
			for j = 0, length do
				for k = 0, depth do
					node_name = minetest.get_node(vector.offset(pos, i, k, j)).name
					if minetest.get_item_group(node_name, "dirt") > 0
						or minetest.get_item_group(node_name, "snow_cover") > 0
						or minetest.get_item_group(node_name, "stone") > 0 then
						table.insert(solid_nodes, vector.offset(pos, i, k, j))
					end
				end
			end
		end

		if #solid_nodes == 0 then
			return false
		end

		minetest.bulk_set_node(solid_nodes, {name = "mcl_powder_snow:powder_snow"})
		return true
	end
})

-- direction is a multiplier to each block's y offset from the starting position, should be either -1 or 1
local function generate_dripstone(pos, max_length, direction)
		-- generating relative to some random sub position of the node, so the dripstone column is more asymetrical (aka natural)
		local x_offset = math.random(-0.2, 0.2)
		local z_offset = math.random(-0.2, 0.2)
		local r = math.ceil((max_length / 8))
		-- local r = math.random(2, 4)
		-- local max_length = r * 5 + math.random(0, 4)
		local c_to = minetest.get_content_id("mcl_dripstone:dripstone_block")
		local vm = minetest.get_voxel_manip()
		local start_pos, end_pos
		local foundation_start_y, foundation_end_y
		if direction == 1 then
			start_pos = vector.offset(pos, -r, -2, -r)
			end_pos = vector.offset(pos, r, max_length, r)
			foundation_start_y = pos.y + (-2 * direction)
			foundation_end_y = pos.y + (-1 * direction)
		else
			start_pos = vector.offset(pos, -r, -max_length, -r)
			end_pos = vector.offset(pos, r, 2, r)
			foundation_start_y = pos.y + (-1 * direction)
			foundation_end_y = pos.y + (-2 * direction)
		end
		local emin, emax = vm:read_from_map(start_pos, end_pos)
		local a = VoxelArea:new(
		{
			MinEdge = emin,
			MaxEdge = emax,
		})
		local data = vm:get_data()

		-- generating foundation
		for x = start_pos.x, end_pos.x do
			for z = start_pos.z, end_pos.z do
				for y = foundation_start_y, foundation_end_y do
					local vi = a:index(x, y, z)
					data[vi] = c_to
				end
			end
		end

		local length
		local offset_r
		for x = start_pos.x, end_pos.x do
			for z = start_pos.z, end_pos.z do
				offset_r = math.sqrt((pos.x - (x + x_offset))^2 + (pos.z - (z + z_offset))^2)
				-- length = max_length - r * offset_r - offset_r * offset_r -- this is the formula that decides the shape!!
				length = (max_length * (r^2 - offset_r^2)) / r^2
				for offset_y = 0, length do
					local vi = a:index(x, pos.y + (offset_y * direction), z)
					data[vi] = c_to
				end
			end
		end

		vm:set_data(data)
		vm:write_to_map(true)
end

mcl_structures.register_structure("large_dripstone_stalagtite", {
	place_on = {"group:stone"},
	spawn_by = "air",
	check_offset = 1,
	num_spawn_by = 5,
	biomes = {"DripstoneCave"},
	fill_ratio = 0.005,
	y_min = mcl_vars.mg_overworld_min + 1, -- plus one so it cant generate on bedrock
	y_max = 0,
	flags = "all_ceilings",
	place_offset_y = 1,
	terrain_feature = true,
	place_func = function(pos)
		local empty_air_length = 0
		while true do
			if minetest.get_node(vector.offset(pos, 0, -empty_air_length, 0)).name ~= "air" then
				break
			end
			empty_air_length = empty_air_length + 1
		end

		generate_dripstone(pos, math.min(20, empty_air_length * math.random(0.2, 0.6)), -1)
		return true
	end
})

mcl_structures.register_structure("large_dripstone_stalagmite", {
	place_on = {"group:stone"},
	spawn_by = "air",
	check_offset = -1,
	num_spawn_by = 5,
	biomes = {"DripstoneCave"},
	fill_ratio = 0.005,
	y_min = mcl_vars.mg_overworld_min + 1,
	y_max = 0,
	flags = "all_floors",
	terrain_feature = true,
	place_func = function(pos)
		local empty_air_length = 0
		while true do
			if minetest.get_node(vector.offset(pos, 0, empty_air_length, 0)).name ~= "air" then
				break
			end
			empty_air_length = empty_air_length + 1
		end

		generate_dripstone(pos, math.min(20, empty_air_length * math.random(0.4, 0.8)), 1)
		return true
	end
})

mcl_structures.register_structure("large_dripstone_column", {
	place_on = {"group:stone"},
	spawn_by = "air",
	check_offset = 1,
	num_spawn_by = 5,
	biomes = {"DripstoneCave"},
	fill_ratio = 0.005,
	y_min = mcl_vars.mg_overworld_min,
	y_max = 0,
	flags = "all_floors",
	terrain_feature = true,
	place_func = function(pos)
		local empty_air_length = 0
		while true do
			if minetest.get_item_group(minetest.get_node(vector.offset(pos, 0, empty_air_length, 0)).name, "solid") ~= 0 then
				break
			elseif empty_air_length > 20 then
				return false
			end
			empty_air_length = empty_air_length + 1
		end

		local height_multi = math.random(0.4, 6)
		generate_dripstone(pos, math.min(20, empty_air_length * height_multi), 1)
		generate_dripstone(vector.offset(pos, 0, empty_air_length, 0), math.min(20, empty_air_length * height_multi), -1)
		return true
	end
})
