
function mcl_trees.strip_tree(itemstack, placer, pointed_thing)
	if pointed_thing.type ~= "node" then return end

	local node = minetest.get_node(pointed_thing.under)
	local noddef = minetest.registered_nodes[node.name]

	if noddef._mcl_stripped_variant and minetest.registered_nodes[noddef._mcl_stripped_variant] then
		minetest.swap_node(pointed_thing.under, {name=noddef._mcl_stripped_variant, param2=node.param2})
		if not minetest.is_creative_enabled(placer:get_player_name()) then
			-- Add wear (as if digging a axey node)
			local toolname = itemstack:get_name()
			local wear = mcl_autogroup.get_wear(toolname, "axey")
			itemstack:add_wear(wear)
		end
	end
	return itemstack
end

function mcl_trees.rotate_climbable(pos, node, _, mode)
	if mode == screwdriver.ROTATE_FACE then
		local r = screwdriver.rotate.wallmounted(pos, node, mode)
		node.param2 = r
		minetest.swap_node(pos, node)
		return true
	end
	return false
end

-- Check if a node stops a tree from growing.  Torches, plants, wood, tree,
-- leaves and dirt does not affect tree growth.
local function node_stops_growth(node)
	if node.name == "air" then
		return false
	end

	local def = minetest.registered_nodes[node.name]
	if not def then
		return true
	end

	local groups = def.groups or {}
	if (groups.plant or 0) ~= 0 or
			(groups.torch or 0) ~= 0 or
			(groups.dirt or 0) ~= 0 or
			(groups.dig_by_water or 0) ~= 0 or
			(groups.tree or 0) ~= 0 or
			(groups.bark or 0) ~= 0 or
			(groups.leaves or 0) ~= 0 or
			(groups.wood or 0) ~= 0 or
			def.buildable_to then
		return false
	end

	return true
end

-- Check the center column starting one node above the sapling
function mcl_trees.check_growth_simple(pos, height)
	for y = 1, height - 1 do
		local np = vector.offset(pos, 0, y, 0)
		if node_stops_growth(minetest.get_node(np)) then
			return false
		end
	end
	return true
end

-- check 6x6 area starting at sapling level
-- Assumes pos is "north east" sapling
function mcl_trees.check_growth_giant(pos, height)
	for x = -3, 2 do
		for z = -3, 2 do
			for y = 0, height - 1 do
				local np = vector.offset(pos, x, y, z)
				if node_stops_growth(minetest.get_node(np)) then
					return false
				end
			end
		end
	end
	return true
end

local function check_schem_growth(pos, file, giant)
	if file then
		local schem = loadstring(
			minetest.serialize_schematic(file, "lua", { lua_use_comments = false, lua_num_indent_spaces = 0 })
				.. " return schematic"
		)()
		if schem then
			local h = schem.size.y
			if giant then
				return mcl_trees.check_growth_giant(pos, h)
			else
				return mcl_trees.check_growth_simple(pos, h)
			end
		end
	end

	return false
end

local diagonals = {
	vector.new(1,0,1),
	vector.new(-1,0,1),
	vector.new(1,0,-1),
	vector.new(-1,0,-1),
}

local function check_2by2_saps(pos, node)
	local n = node.name
	-- quick check if at all there are sufficient saplings nearby
	if #minetest.find_nodes_in_area_under_air({x=pos.x-1, y=pos.y, z=pos.z-1}, {x=pos.x+1, y=pos.y, z=pos.z+1}, n) == 0 then return end
	-- we need to check 4 possible 2x2 squares on the x/z plane each uniquely defined by one of the
	-- diagonals of the position we're checking:
	for _,v in pairs(diagonals) do
		local d = vector.add(pos,v) --one of the 4 diagonal positions from this node
		local xp = vector.new(d.x,d.y,d.z-v.z) --go "back" towards our position on the z axis
		local zp = vector.new(d.x-v.x,d.y,d.z) --go "back" towards our position on the x axis

		local dn = minetest.get_node(d).name
		local xn = minetest.get_node(xp).name
		local zn = minetest.get_node(zp).name
		if n == dn and n == xn and n == zn then
			--if all the 3 acquired positions have the same nodename as the original node it must be a square
			local ne = pos
			for _,p in pairs({pos,d,xp,zp}) do
				if p.x > ne.x or p.z > ne.z then ne = p end
			end --find northeasternmost node
			return {d,xp,zp}, ne
		end
	end
end

function mcl_trees.grow_tree(pos, node)
	local name = node.name:gsub("mcl_trees:sapling_", "")
	if node.name:find("propagule") then
		name = "mangrove"
	end
	if not mcl_trees.woods[name] or ( not mcl_trees.woods[name].tree_schems and not mcl_trees.woods[name].tree_schems_2x2 ) then
		return
	end

	local schem, can_grow, tbt, ne
	local place_at = pos
	local is_2by2 = false
	if mcl_trees.woods[name].tree_schems_2x2  then
		tbt, ne = check_2by2_saps(pos, node)
		if tbt then
			table.shuffle(mcl_trees.woods[name].tree_schems_2x2)
			schem = mcl_trees.woods[name].tree_schems_2x2[1]
			can_grow = check_schem_growth(ne, schem.file, true)
			place_at = ne
			is_2by2 = true
		end
	end

	if not tbt and mcl_trees.woods[name].tree_schems then
		table.shuffle(mcl_trees.woods[name].tree_schems)
		schem = mcl_trees.woods[name].tree_schems[1]
		can_grow = check_schem_growth(place_at, schem.file, false)
	end

	if not schem then return end

	if can_grow then

		local offset = schem.offset
		minetest.remove_node(pos)
		if tbt then
			for _, v in pairs(tbt) do
				minetest.remove_node(v)
			end

			place_at = ne

			-- Assume trunk is in the center of the schema.
			-- Overide this in tree_schems if it isn't.
			if not offset then
				offset = vector.new(1, 0, 1)
			end
		end

		if offset then
			place_at = vector.subtract(place_at, offset)
		end

		minetest.place_schematic(
			place_at,
			schem.file,
			"random",
			nil,
			false,
			{ place_center_x = true, place_center_y = false, place_center_z = true }
		)

		local after_grow = minetest.registered_nodes[node.name]._after_grow
		if after_grow then
			after_grow(place_at, schem, is_2by2)
		end
	end
end

local nest_dirs = {vector.new(1, 0, 0), vector.new(-1, 0, 0), vector.new(0, 0, -1)}

function mcl_trees.add_bee_nest(pos)
	local col = vector.add(pos, nest_dirs[math.random(3)])
	for i = 2, 8 do
		local nestpos = vector.offset(col, 0, i -1 , 0)
		local abovename = minetest.get_node(vector.offset(col, 0, i, 0)).name
		if minetest.get_node(nestpos).name == "air" and
				(minetest.get_item_group(abovename, "leaves") > 0 or minetest.get_item_group(abovename, "tree") > 0) then
			minetest.set_node(nestpos, {name = "mcl_beehives:bee_nest"})
			-- TODO: spawn bee mobs in nest
			return
		end
	end
end

function mcl_trees.sapling_add_bee_nest(pos)
	if #minetest.find_nodes_in_area(vector.offset(pos,-2, 0 ,-2), vector.offset(pos, 2, 0, 2), {"group:flower"}) == 0 then return end
	if math.random(20) == 1 then
		mcl_trees.add_bee_nest(pos)
	end
end
