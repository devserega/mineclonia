-- Compatibility polyfills for legacy minetest
--
-- polyfill for minetest < 5.9
if not vector.random_direction then
	function vector.random_direction()
		-- Generate a random direction of unit length, via rejection sampling
		local x, y, z, l2
		repeat -- expected less than two attempts on average (volume sphere vs. cube)
			x, y, z = math.random() * 2 - 1, math.random() * 2 - 1, math.random() * 2 - 1
			l2 = x*x + y*y + z*z
		until l2 <= 1 and l2 >= 1e-6
		-- normalize
		local l = math.sqrt(l2)
		return vector.new(x/l, y/l, z/l)
	end
end

local function valid_object_iterator(objects)
	local i = 0
	local function next_valid_object()
		i = i + 1
		local obj = objects[i]
		if obj == nil then
			return
		end
		if obj:get_pos() then
			return obj
		end
		return next_valid_object()
	end
	return next_valid_object
end

local function valid_object_iterator_in_radius(objects, center, radius)
	local i = 0
	local function next_valid_object()
		i = i + 1
		local obj = objects[i]
		if obj == nil then
			return
		end
		local p = obj:get_pos()
		if p and vector.distance(p, center) <= radius then
			return obj
		end
		return next_valid_object()
	end
	return next_valid_object
end

function mcl_util.connected_players(center, radius)
	local pls = minetest.get_connected_players()
	if not center then return valid_object_iterator(pls) end
	return valid_object_iterator_in_radius(pls, center, radius or 1)
end

if not minetest.objects_inside_radius then --polyfill for pre minetest 5.9
	function core.objects_inside_radius(center, radius)
		return valid_object_iterator(core.get_objects_inside_radius(center, radius))
	end

	function core.objects_in_area(min_pos, max_pos)
		return valid_object_iterator(core.get_objects_in_area(min_pos, max_pos))
	end
end

if not vector.in_area then
	function vector.in_area(pos, min, max)
		return (pos.x >= min.x) and (pos.x <= max.x) and
			(pos.y >= min.y) and (pos.y <= max.y) and
			(pos.z >= min.z) and (pos.z <= max.z)
	end
end

-- Pre minetest 5.9
if not minetest.get_node_boxes then
--> function(nodename) -> whether node matches
	local function nodename_matcher(node_or_groupname)
		if string.sub(node_or_groupname, 1, 6) == "group:" then
			local groups = string.split(node_or_groupname:sub(("group:"):len() + 1), ",")
			return function(nodename)
				for _, groupname in pairs(groups) do
					if minetest.get_item_group(nodename, groupname) == 0 then
						return false
					end
				end
				return true
			end
		else
			return function(nodename)
				return nodename == node_or_groupname
			end
		end
	end
		-- Minetest allows shorthand box = {...} instead of {{...}}
	local function get_boxes(box_or_boxes)
		return type(box_or_boxes[1]) == "number" and {box_or_boxes} or box_or_boxes
	end

	local has_boxes_prop = {collision_box = "walkable", selection_box = "pointable"}

	-- Required for raycast box IDs to be accurate
	local connect_sides_order = {"top", "bottom", "front", "left", "back", "right"}

	local connect_sides_directions = {
		top = vector.new(0, 1, 0),
		bottom = vector.new(0, -1, 0),
		front = vector.new(0, 0, -1),
		left = vector.new(-1, 0, 0),
		back = vector.new(0, 0, 1),
		right = vector.new(1, 0, 0),
	}
	function minetest.get_node_boxes(type, pos)
		local node = minetest.get_node(pos)
		local node_def = minetest.registered_nodes[node.name]
		if not node_def or node_def[has_boxes_prop[type]] == false then
			return {}
		end
		local boxes = {{-0.5, -0.5, -0.5, 0.5, 0.5, 0.5}}
		local def_node_box = node_def.drawtype == "nodebox" and node_def.node_box
		local def_box = node_def[type] or def_node_box -- will evaluate to def_node_box for type = nil
		if not def_box then
			return boxes -- default to regular box
		end
		local box_type = def_box.type
		if box_type == "regular" then
			return boxes
		end
		local fixed = def_box.fixed
		boxes = get_boxes(fixed or {})
		local paramtype2 = node_def.paramtype2
		if box_type == "leveled" then
			boxes = table.copy(boxes)
			local level = (paramtype2 == "leveled" and node.param2 or node_def.leveled or 0) / 255 - 0.5
			for _, box in ipairs(boxes) do
				box[5] = level
			end
		elseif box_type == "wallmounted" then
			local dir = minetest.wallmounted_to_dir((paramtype2 == "colorwallmounted" and node.param2 % 8 or node.param2) or 0)
			local box
			-- The (undocumented!) node box defaults below are taken from `NodeBox::reset`
			if dir.y > 0 then
				box = def_box.wall_top or {-0.5, 0.5 - 1/16, -0.5, 0.5, 0.5, 0.5}
			elseif dir.y < 0 then
				box = def_box.wall_bottom or {-0.5, -0.5, -0.5, 0.5, -0.5 + 1/16, 0.5}
			else
				box = def_box.wall_side or {-0.5, -0.5, -0.5, -0.5 + 1/16, 0.5, 0.5}
				if dir.z > 0 then
					box = {box[3], box[2], -box[4], box[6], box[5], -box[1]}
				elseif dir.z < 0 then
					box = {-box[6], box[2], box[1], -box[3], box[5], box[4]}
				elseif dir.x > 0 then
					box = {-box[4], box[2], box[3], -box[1], box[5], box[6]}
				else
					box = {box[1], box[2], -box[6], box[4], box[5], -box[3]}
				end
			end
			return {assert(box, "incomplete wallmounted collisionbox definition of " .. node.name)}
		end
		if box_type == "connected" then
			boxes = table.copy(boxes)
			local connect_sides = connect_sides_directions -- (ab)use directions as a "set" of sides
			if node_def.connect_sides then -- build set of sides from given list
				connect_sides = {}
				for _, side in ipairs(node_def.connect_sides) do
					connect_sides[side] = true
				end
			end
			local function add_collisionbox(key)
				for _, box in ipairs(get_boxes(def_box[key] or {})) do
					table.insert(boxes, box)
				end
			end
			local matchers = {}
			for i, nodename_or_group in ipairs(node_def.connects_to or {}) do
				matchers[i] = nodename_matcher(nodename_or_group)
			end
			local function connects_to(nodename)
				for _, matcher in ipairs(matchers) do
					if matcher(nodename) then
						return true
					end
				end
			end
			local connected, connected_sides
			for _, side in ipairs(connect_sides_order) do
				if connect_sides[side] then
					local direction = connect_sides_directions[side]
					local neighbor = minetest.get_node(vector.add(pos, direction))
					local connects = connects_to(neighbor.name)
					connected = connected or connects
					connected_sides = connected_sides or (side ~= "top" and side ~= "bottom")
					add_collisionbox((connects and "connect_" or "disconnected_") .. side)
				end
			end
			if not connected then
				add_collisionbox("disconnected")
			end
			if not connected_sides then
				add_collisionbox("disconnected_sides")
			end
			return boxes
		end
		if box_type == "fixed" and paramtype2 == "facedir" or paramtype2 == "colorfacedir" then
			local param2 = paramtype2 == "colorfacedir" and node.param2 % 32 or node.param2 or 0
			if param2 ~= 0 then
				boxes = table.copy(boxes)
				local axis = ({5, 6, 3, 4, 1, 2})[math.floor(param2 / 4) + 1]
				local other_axis_1, other_axis_2 = (axis % 3) + 1, ((axis + 1) % 3) + 1
				local rotation = (param2 % 4) / 2 * math.pi
				local flip = axis > 3
				if flip then axis = axis - 3; rotation = -rotation end
				local sin, cos = math.sin(rotation), math.cos(rotation)
				if axis == 2 then
					sin = -sin
				end
				for _, box in ipairs(boxes) do
					for off = 0, 3, 3 do
						local axis_1, axis_2 = other_axis_1 + off, other_axis_2 + off
						local value_1, value_2 = box[axis_1], box[axis_2]
						box[axis_1] = value_1 * cos - value_2 * sin
						box[axis_2] = value_1 * sin + value_2 * cos
					end
					if not flip then
						box[axis], box[axis + 3] = -box[axis + 3], -box[axis]
					end
					local function fix(coord)
						if box[coord] > box[coord + 3] then
							box[coord], box[coord + 3] = box[coord + 3], box[coord]
						end
					end
					fix(other_axis_1)
					fix(other_axis_2)
				end
			end
		end
		return boxes
	end
end
