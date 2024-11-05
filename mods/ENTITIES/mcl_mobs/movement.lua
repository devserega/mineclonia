local mob_class = mcl_mobs.mob_class
local DEFAULT_FALL_SPEED = -9.81*1.5
local FLOP_HEIGHT = 6
local FLOP_HOR_SPEED = 1.5
--- how many radians to really turn away from a wall or cliff?
local YAW_RAD = 1.8
local node_snow = "mcl_core:snow"

local mobs_griefing = minetest.settings:get_bool("mobs_griefing") ~= false

-- TODO delete logging functions and all uses of them before MR
local log_flying = false
local log_swimming = false
local log_walking = false

local function walk_log(msg)
	if log_walking then
		minetest.log("walk_log: " .. msg)
	end
end

local function fly_log(msg)
	if log_flying then
		minetest.log("fly_log: " .. msg)
	end
end

local function swim_log(msg)
	if log_swimming then
		minetest.log("swim_log: " .. msg)
	end
end

local atann = math.atan
local function atan(x)
	if not x or x ~= x then
		return 0
	else
		return atann(x)
	end
end

-- Returns true is node can deal damage to self
function mob_class:is_node_dangerous(nodename)
	local nn = nodename
	if self.lava_damage > 0 then
		if minetest.get_item_group(nn, "lava") ~= 0 then
			return true
		end
	end
	if self.fire_damage > 0 then
		if minetest.get_item_group(nn, "fire") ~= 0 then
			return true
		end
	end
	if minetest.registered_nodes[nn] and minetest.registered_nodes[nn].damage_per_second and minetest.registered_nodes[nn].damage_per_second > 0 then
		return true
	end
	return false
end

-- Returns true if node is a water hazard to this mob
function mob_class:is_node_waterhazard(nodename)
	if self.swims or self.breathes_in_water or self.object:get_properties().breath_max == -1 then
		return false
	end

	if self.water_damage > 0 then
		if minetest.get_item_group(nodename, "water") ~= 0 then
			return true
		end
	end

	if
		minetest.registered_nodes[nodename]
		and minetest.registered_nodes[nodename].drowning
		and minetest.registered_nodes[nodename].drowning > 0
		and minetest.get_item_group(nodename, "water") ~= 0
	then
		return true
	end

	return false
end

function mob_class:target_visible(origin, target)
	if not origin then return end

	if not target and self.attack then
		target = self.attack
	end
	if not target then return end

	local target_pos = target:get_pos()
	if not target_pos then return end

	local origin_eye_pos = vector.offset(origin, 0, self.head_eye_height, 0)

	local targ_head_height, targ_feet_height
	local cbox = self.object:get_properties().collisionbox
	if target:is_player() then
		targ_head_height = vector.offset(target_pos, 0, cbox[5], 0)
		targ_feet_height = target_pos -- Cbox would put feet under ground which interferes with ray
	else
		targ_head_height = vector.offset(target_pos, 0, cbox[5], 0)
		targ_feet_height = vector.offset(target_pos, 0, cbox[2], 0)
	end

	if minetest.line_of_sight(origin_eye_pos, targ_head_height) then
		return true
	end

	if minetest.line_of_sight(origin_eye_pos, targ_feet_height) then
		return true
	end

	-- TODO mid way between feet and head

	return false
end

-- check line of sight (BrunoMine)
function mob_class:line_of_sight(pos1, pos2, stepsize)
	stepsize = stepsize or 1
	local s, _ = minetest.line_of_sight(pos1, pos2, stepsize)

	-- normal walking and flying mobs can see you through air
	if s then return true end

	-- New pos1 to be analyzed
	local npos1 = vector.copy(pos1)
	local r, pos = minetest.line_of_sight(npos1, pos2, stepsize)

	if r == true then return true end
	local nn = minetest.get_node(pos).name
	local td = vector.distance(pos1, pos2)
	local ad = 0

	-- It continues to advance in the line of sight in search of a real
	-- obstruction which counts as 'normal' nodebox.
	while minetest.registered_nodes[nn]
	and minetest.registered_nodes[nn].walkable == false do

		-- Check if you can still move forward
		if td < ad + stepsize then
			return true -- Reached the target
		end

		-- Moves the analyzed pos
		local d = vector.distance(pos1, pos2)

		npos1.x = ((pos2.x - pos1.x) / d * stepsize) + pos1.x
		npos1.y = ((pos2.y - pos1.y) / d * stepsize) + pos1.y
		npos1.z = ((pos2.z - pos1.z) / d * stepsize) + pos1.z

		-- NaN checks
		if d == 0
		or npos1.x ~= npos1.x
		or npos1.y ~= npos1.y
		or npos1.z ~= npos1.z then
			return false
		end

		ad = ad + stepsize

		-- scan again
		r, pos = minetest.line_of_sight(npos1, pos2, stepsize)

		if r == true then return true end
		-- New Nodename found
		nn = minetest.get_node(pos).name
	end

	return false
end

function mob_class:can_jump_cliff()
	local pos = self.object:get_pos()

	--is there nothing under the block in front? if so jump the gap.
	local dir_x, dir_z = self:forward_directions()
	local pos_low = vector.offset(pos, dir_x, -0.5, dir_z)
	local pos_far = vector.offset(pos, dir_x * 2, -0.5, dir_z * 2)
	local pos_far2 = vector.offset(pos, dir_x * 3, -0.5, dir_z * 3)

	local nodLow = mcl_mobs.node_ok(pos_low, "air")
	local nodFar = mcl_mobs.node_ok(pos_far, "air")
	local nodFar2 = mcl_mobs.node_ok(pos_far2, "air")

	if minetest.registered_nodes[nodLow.name]
	and minetest.registered_nodes[nodLow.name].walkable ~= true


	and (minetest.registered_nodes[nodFar.name]
	and minetest.registered_nodes[nodFar.name].walkable == true

	or minetest.registered_nodes[nodFar2.name]
	and minetest.registered_nodes[nodFar2.name].walkable == true)

	then
		--disable fear heigh while we make our jump
		self._jumping_cliff = true
		minetest.after(1, function()
			if self and self.object then
				self._jumping_cliff = false
			end
		end)
		return true
	else
		return false
	end
end

-- is mob facing a cliff or danger
function mob_class:is_at_cliff_or_danger()
	if self.fear_height == 0 or self._jumping_cliff or not self.object:get_luaentity() then -- 0 for no falling protection!
		return false
	end

	local cbox = self.object:get_properties().collisionbox
	local dir_x, dir_z = self:forward_directions()
	local pos = self.object:get_pos()

	local free_fall, blocker = minetest.line_of_sight(
		vector.offset(pos, dir_x, cbox[2], dir_z),
		vector.offset(pos, dir_x, -self.fear_height, dir_z))

	if free_fall then
		return true
	else
		local bnode = minetest.get_node(blocker)
		local danger = self:is_node_dangerous(bnode.name)
		if danger then
			return true
		else
			local def = minetest.registered_nodes[bnode.name]
			if def and def.walkable then
				return false
			end
		end
	end

	return false
end

function mob_class:is_at_water_danger()
	if self._jumping_cliff or self.swims or self.fly or self.object:get_properties().breath_max == -1 then
		return false
	end

	local cbox = self.object:get_properties().collisionbox
	local pos = self.object:get_pos()
	local infront = self:node_infront_ok(pos, -1)
	local height = cbox[5] - cbox[2]

	if self:is_node_waterhazard(infront.name) then
		-- if short then mob can drown in a single node
		if height <= 1.0 then
			return true
		else
			-- else it's only dangerous if two nodes deep
			local below_infront = self:node_infront_ok(pos, -2)
			if self:is_node_waterhazard(below_infront.name) then
				return true
			end
		end
	end

	return false
end

function mob_class:should_get_out_of_water()
	if self.breathes_in_water or self.object:get_properties().breath_max == -1 or self.swims then
		return false
	end

	-- water two nodes deep or head is sumbmerged
	if
		(
			minetest.registered_nodes[self.standing_in]
			and minetest.registered_nodes[self.standing_in].drowning
			and minetest.registered_nodes[self.standing_in].drowning > 0
			and minetest.registered_nodes[self.standing_on]
			and minetest.registered_nodes[self.standing_on].drowning
			and minetest.registered_nodes[self.standing_on].drowning > 0
		)
		or (
			minetest.registered_nodes[self.head_in]
			and minetest.registered_nodes[self.head_in].drowning
			and minetest.registered_nodes[self.head_in].drowning > 0
		)
	then
		return true
	end

	return false
end

function mob_class:get_out_of_water()
	local mypos = self.object:get_pos()
	local land = minetest.find_nodes_in_area_under_air(
		vector.offset(mypos, -32, -1, -32),
		vector.offset(mypos, 32, 1, 32),
		{ "group:solid" }
	)

	local closest = 10000
	local closest_land

	for _, v in pairs(land) do
		local dst = vector.distance(mypos, v)
		if dst < closest then
			closest = dst
			closest_land = v
		end
	end

	if closest_land then
		self:go_to_pos(closest_land)
	end
end

function mob_class:env_danger_movement_checks()
	-- TODO this is always true ... should it be?
	if self.order ~= "sleep" and self.move_in_group ~= false then
		self:check_herd()
	end
	--if not self:check_timer("env_danger_movement_checks", 0.1) then return end
	-- TODO: if this doesn't happen often enough mobs frequently jump into danger
	if self:should_get_out_of_water() and self.state ~= "attack" then
		self:get_out_of_water()
	elseif self:is_at_water_danger() and self.state ~= "attack" then
		if math.random(1, 10) <= 6 then
			self:set_velocity(0)
			self:set_state("stand")
			self:set_animation("stand")
			self:turn_away(8)
		end
	elseif self:is_at_cliff_or_danger() then
		self:set_velocity(0)
		self:set_state("stand")
		self:set_animation("stand")
		self:turn_away(8)
	end
end

function mob_class:check_jump (self_pos, moveresult)
	local max_y = nil

	-- Read the height of every colliding node in moveresult,
	-- and the node above.
	for _, item in ipairs (moveresult.collisions) do
		if item.type == "node"
			and (item.new_velocity.x ~= item.old_velocity.x
			     or item.new_velocity.z ~= item.old_velocity.z) then
			local pos = item.node_pos
			local boxes = minetest.get_node_boxes ("collision_box", pos)
			if pos.y > self_pos.y then
				for _, box in ipairs (boxes) do
					max_y = math.max (max_y or 0, pos.y + box[2], pos.y + box[5])
				end
			end
		end
	end
	return max_y and (max_y > self_pos.y)
		and (max_y - self_pos.y > self.object:get_properties ().stepheight)
end

-- jump if facing a solid node (not fences or gates)
function mob_class:do_jump()
	if not self.jump
	or self.jump_height == 0
	or self.fly
	or self.swims
	or self.order == "sleep" then
		return false
	end

	self.facing_fence = false

	local pos = self.object:get_pos()

	-- what is mob standing on?
	local cbox = self.object:get_properties().collisionbox
	local nod =  mcl_mobs.node_ok(vector.offset(pos, 0, cbox[2] - 0.2, 0))

	local in_water = minetest.get_item_group( mcl_mobs.node_ok(pos).name, "water") > 0

	if minetest.registered_nodes[nod.name].walkable == false and not in_water then
		return false
	end

	-- what is in front of mob?
	nod = self:node_infront_ok(pos, 0.5)

	-- this is used to detect if there's a block on top of the block in front of the mob.
	-- If there is, there is no point in jumping as we won't manage.
	local y_up = 1.5
	if in_water then
		y_up = cbox[5]
	end
	local nodTop = self:node_infront_ok(pos, y_up, "air")

	-- we don't attempt to jump if there's a stack of blocks blocking
	if minetest.registered_nodes[nodTop.name].walkable == true and not (self.attack and self.state == "attack") then
		return false
	end

	-- thin blocks that do not need to be jumped
	if nod.name == node_snow then
		return false
	end

	local ndef = minetest.registered_nodes[nod.name]
	if self.walk_chance == 0 or ndef and ndef.walkable or self:can_jump_cliff() then

		if
			minetest.get_item_group(nod.name, "fence") == 0
			and minetest.get_item_group(nod.name, "fence_gate") == 0
			and minetest.get_item_group(nod.name, "wall") == 0
		then
			local dir_x, dir_z = self:forward_directions()
			-- Extensive testing to get this to work  ...
			local v = vector.new(dir_x, self.jump_height + 0.5 * 10, dir_z)

			if not in_water and self:can_jump_cliff() then
				v = vector.multiply(v, vector.new(2.8, 1, 2.8))
			end

			-- ensure we don't turn if we are trying to jump up something
			self.order = "jump"
			self:set_animation("jump")
			walk_log("jump at: " .. minetest.pos_to_string(self.object:get_pos()))

			self.object:set_velocity(v)
			self.object:set_acceleration(vector.new(v.x, 1, v.z))

			-- when in air move forward
			minetest.after(0.3, function(self, v)
				if (not self.object) or (not self.object:get_luaentity()) or (self.state == "die") then
					return
				end
				walk_log("move forward at: " .. minetest.pos_to_string(self.object:get_pos()))
				self.object:set_acceleration(vector.new(v.x * 5, DEFAULT_FALL_SPEED, v.z * 5))

				if self.order == "jump" then
					self.order = ""
					if self.state == "stand" then
						self:set_velocity(self.walk_velocity)
						self:set_state("walk")
						self:set_animation("walk")
					end
				end
			end, self, v)

			if self:check_timer("jump_sound_cooloff", self.jump_sound_cooloff) then
				self:mob_sound("jump")
			end
		else
			self.facing_fence = true
		end

		-- if we jumped against a block/wall 4 times then turn
		if self.object:get_velocity().x ~= 0 and self.object:get_velocity().z ~= 0 then

			self.jump_count = (self.jump_count or 0) + 1

			if self.jump_count == 4 then
				self:turn_away(8)
				self.jump_count = 0
			end
		end
		return true
	end

	self.jump_count = 0

	return false
end

local function in_list(list, what)
	return type(list) == "table" and table.indexof(list, what) ~= -1
end

function mob_class:is_object_in_view(object_list, object_range, node_range, turn_around)
	local s = self.object:get_pos()
	local min_dist = object_range + 1
	local object_pos
	for object in minetest.objects_inside_radius(s, object_range) do
		local name = ""
		if object:is_player() then
			if not (mcl_mobs.invis[ object:get_player_name() ]
			or self.owner == object:get_player_name()
			or (not self:object_in_range(object))) then
				name = "player"
				if not (name ~= self.name
				and in_list(object_list, name)) then
					local item = object:get_wielded_item()
					name = item:get_name() or ""
				end
			end
		else
			local ent = object:get_luaentity()

			if ent then
				object = ent.object
				name = ent.name or ""
			end
		end

		-- find specific mob to avoid or runaway from
		if name ~= "" and name ~= self.name
		and in_list(object_list, name) then

			local p = object:get_pos()
			local dist = vector.distance(p, s)

			-- choose closest player/mob to avoid or runaway from
			if dist < min_dist
			-- aim higher to make looking up hills more realistic
			and self:line_of_sight(vector.offset(s, 0,1,0), vector.offset(p, 0,1,0)) == true then
				min_dist = dist
				object_pos = p
			end
		end
	end

	if not object_pos then
		-- find specific node to avoid or runaway from
		local p = minetest.find_node_near(s, node_range, object_list, true)
		local dist = p and vector.distance(p, s)
		if dist and dist < min_dist
		and self:line_of_sight(s, p) == true then
			object_pos = p
		end
	end

	if object_pos and turn_around then

		local vec = vector.subtract(object_pos, s)
		local yaw = (atan(vec.z / vec.x) + 3 *math.pi/ 2) - self.rotate
		if object_pos.x > s.x then yaw = yaw + math.pi end

		self:set_yaw(yaw, 4)
	end
	return object_pos ~= nil
end

-- should mob follow what I'm holding ?
function mob_class:follow_holding(clicker)
	if mcl_mobs.invis[clicker:get_player_name()] then
		return false
	end
	local item = clicker:get_wielded_item()
	if in_list(self.follow, item:get_name()) then
		return true
	end
	return false
end


-- find and replace what mob is looking for (grass, wheat etc.)
function mob_class:replace(pos)
	if not self.replace_rate
	or not self.replace_what
	or self.child == true
	or self.object:get_velocity().y ~= 0
	or math.random(1, self.replace_rate) > 1 then
		return
	end

	local what, with, y_offset

	if type(self.replace_what[1]) == "table" then
		local num = math.random(#self.replace_what)

		what = self.replace_what[num][1] or ""
		with = self.replace_what[num][2] or ""
		y_offset = self.replace_what[num][3] or 0
	else
		what = self.replace_what
		with = self.replace_with or ""
		y_offset = self.replace_offset or 0
	end

	pos.y = pos.y + y_offset

	local node = minetest.get_node(pos)
	if node.name == what then
		local oldnode = {name = what, param2 = node.param2}
		local newnode = {name = with, param2 = node.param2}
		local on_replace_return = false
		if self.on_replace then
			on_replace_return = self.on_replace(self, pos, oldnode, newnode)
		end

		if on_replace_return ~= false then
			if mobs_griefing then
				minetest.after(self.replace_delay, function()
					if self and self.object and self.object:get_velocity() and self.health > 0 then
						minetest.set_node(pos, newnode)
					end
				end)
			end
		end
	end
end

-- find someone to runaway from
function mob_class:check_runaway_from()
	if not self:check_timer("check_runaway_from", 1) then return end
	if (not self.runaway_from and self.state ~= "flop") or self.state == "runaway" then
		return
	end
	if self:is_object_in_view(self.runaway_from, self.view_range, self.view_range / 2, true) then
		self.state = "runaway"
		self.runaway_timer = 3
		self.following = nil
		self:set_animation("run")
	end
end

-- follow player if owner or holding item
function mob_class:follow_player()
	-- find player to follow
	if
		(self.follow ~= "" or self.order == "follow")
		and not self.following
		and self.state ~= "attack"
		and self.order ~= "sit"
		and self.state ~= "runaway"
	then

		for player in mcl_util.connected_players() do
			if (self:object_in_range(player))
			and not mcl_mobs.invis[ player:get_player_name() ] then
				self.following = player
				break
			end
		end
	end

	if self.type == "npc"
	and self.order == "follow"
	and self.state ~= "attack"
	and self.order ~= "sit"
	and self.owner ~= "" then

		-- npc stop following player if not owner
		if self.following
		and self.owner
		and self.owner ~= self.following:get_player_name() then
			self.following = nil
		end
	else
		-- stop following player if not holding specific item,
		-- mob is horny, fleeing or attacking
		if self.following
		and self.following:is_player()
		and (self:follow_holding(self.following) == false or
		self.horny or self.state == "runaway") then
			self.following = nil
		end

	end

	-- follow that thing
	if self.following then
		local s = self.object:get_pos()
		local p = self.following:get_pos()
		if p then
			local dist = vector.distance(p, s)
			-- dont follow if out of range
			if (not self:object_in_follow_range(self.following)) then
				self.following = nil
			else
				local vec = {
					x = p.x - s.x,
					z = p.z - s.z
				}
				local yaw = (atan(vec.z / vec.x) +math.pi/ 2) - self.rotate
				if p.x > s.x then yaw = yaw +math.pi end
				self:set_yaw( yaw, 2.35)
				-- anyone but standing npc's can move along
				if dist > 3
				and self.order ~= "stand" then
					self:set_velocity(self.follow_velocity)
					if self.walk_chance ~= 0 then
						self:set_animation( "run")
					end
				else
					self:set_velocity(0)
					self:set_animation( "stand")
				end
				return
			end
		end
	end
end

function mob_class:look_at(b)
	local s=self.object:get_pos()
	local v = { x = b.x - s.x, z = b.z - s.z }
	local yaw = (atann(v.z / v.x) +math.pi/ 2) - self.rotate
	if b.x > s.x then yaw = yaw +math.pi end
	self.object:set_yaw(yaw)
end

function mob_class:go_to_pos(b)
	if not self then return end
	local s=self.object:get_pos()
	if not b then
		--self:set_state("stand")
		return end
	if vector.distance(b,s) < 0.5 then
		--self:set_velocity(0)
		return true
	end
	self:look_at(b)
	self:set_velocity(self.walk_velocity)
	self:set_animation("walk")
end

function mob_class:check_herd()
	if not self:check_timer("check_herd", 6) then return end
	if self:should_get_out_of_water() then return end
	local pos = self.object:get_pos()
	if not pos then return end
	for o in minetest.objects_inside_radius(pos, self.view_range) do
		local l = o:get_luaentity()
		local p,y
		if l and l.is_mob and l.name == self.name then
			if self.horny and l.horny then
				p = l.object:get_pos()
			else
				y = o:get_yaw()
			end
			if p then
				self:go_to_pos(p)
			elseif y then
				self:set_yaw(y)
			end
		end
	end
end

function mob_class:teleport(target)
	if self.do_teleport then
		if self.do_teleport(self, target) == false then
			return
		end
	end
end

function mob_class:do_states_walk()
	local s = self.object:get_pos()
	local lp = nil

	-- is there something I need to avoid?
	if (self.water_damage > 0
			and self.lava_damage > 0)
			or self.object:get_properties().breath_max ~= -1 then
		lp = minetest.find_node_near(s, 1, {"group:water", "group:lava"})
	elseif self.water_damage > 0 then
		lp = minetest.find_node_near(s, 1, {"group:water"})
	elseif self.lava_damage > 0 then
		lp = minetest.find_node_near(s, 1, {"group:lava"})
	elseif self.fire_damage > 0 then
		lp = minetest.find_node_near(s, 1, {"group:fire"})
	end

	local is_in_danger = false
	if lp then
		-- If mob in or on dangerous block, look for land
		if (self:is_node_dangerous(self.standing_in) or
				self:is_node_dangerous(self.standing_on)) or (self:is_node_waterhazard(self.standing_in) or self:is_node_waterhazard(self.standing_on)) and (not self.fly) then
			is_in_danger = true

			-- If mob in or on dangerous block, look for land
			if is_in_danger then
				-- Better way to find shore - copied from upstream
				lp = minetest.find_nodes_in_area_under_air(
						{x = s.x - 5, y = s.y - 0.5, z = s.z - 5},
						{x = s.x + 5, y = s.y + 1, z = s.z + 5},
						{"group:solid"})

				lp = #lp > 0 and lp[math.random(#lp)]

				-- did we find land?
				if lp then

					local vec = {
						x = lp.x - s.x,
						z = lp.z - s.z
					}
					local yaw = (atan(vec.z / vec.x) + math.pi / 2) - self.rotate
					if lp.x > s.x  then yaw = yaw +math.pi end

					-- look towards land and move in that direction
					self:set_yaw(yaw, 6)
					self:set_velocity(self.walk_velocity)

				end
			end
		end
	end
	if not is_in_danger then
		local distance = self.avoid_distance or self.view_range / 2
		-- find specific node to avoid
		if self:is_object_in_view(self.avoid_nodes, distance, distance, true) then
			self:set_velocity(self.walk_velocity)
		-- otherwise randomly turn
		elseif math.random(1, 100) <= 30 then
			self:turn_away(6)
		end
	end
	-- stand for great fall or danger or fence in front
	local cliff_or_danger = false
	if is_in_danger then
		cliff_or_danger = self:is_at_cliff_or_danger()
	end

	local facing_solid = false

	-- No need to check if we are already going to turn
	if not self.facing_fence and not cliff_or_danger then
		local nod = self:node_infront_ok(vector.floor(s), 0.5)

		if minetest.registered_nodes[nod.name] and minetest.registered_nodes[nod.name].walkable == true then
			facing_solid = true
		end
	end
	if self.facing_fence == true
			or cliff_or_danger
			or facing_solid
			or math.random(1, 100) <= 30 then

		self:set_velocity(0)
		self:set_state("stand")
		self:set_animation( "stand")
		self:turn_away(4)
	else
		self:set_velocity(self.walk_velocity)

		if self:flight_check()
				and self.animation
				and self.animation.fly_start
				and self.animation.fly_end then
			self:set_animation( "fly")
		else
			self:set_animation( "walk")
		end
	end
end

function mob_class:flying_actions(can_takeoff)
	local s = self.object:get_pos()
	local y = math.random(1, 5)

	fly_log("flying_actions y = " .. y)

	-- Fly downwards if too high or randomly
	if s.y >= self.fly_limit or math.random() < 0.4 then
		y = -y
	end

	if self:should_flap() then
		-- in and on air
		fly_log("should_flap " .. y)
		self:fly_forward(y)
	elseif self:flight_check() == false then
		-- not in air
		fly_log("flight_check failed ... swimming?")
		self:fly_forward(math.abs(y))
	elseif can_takeoff and math.random(1, 100) <= self.fly_chance then
		if y < 0 then
			y = -y
		end
		fly_log("taking off at " .. y)
		self:fly_forward(y)
	else
		fly_log("walking, can_takeoff: " .. dump(can_takeoff))
		self:set_velocity(self.walk_velocity)
		self:set_state("walk")
		self:set_animation("walk")
	end
end

function mob_class:do_states_stand()

	local s = self.object:get_pos()

	if self.order == "sleep" then
		self:set_animation("stand")
		self:set_velocity(0)
		self:slow_mob()
		return
	end

	local yaw = self.object:get_yaw() or 0

	if math.random(1, 4) == 1 then
		local lp
		for obj in minetest.objects_inside_radius(s, 3) do
			if obj:is_player() then
				lp = obj:get_pos()
				break
			end
		end
		-- look at any players nearby, otherwise turn randomly
		if lp and self.look_at_players then

			local vec = {
				x = lp.x - s.x,
				z = lp.z - s.z,
			}
			yaw = (atan(vec.z / vec.x) + math.pi / 2) - self.rotate
			if lp.x > s.x then
				yaw = yaw + math.pi
			end
		else
			yaw = yaw + mcl_util.float_random(-YAW_RAD, YAW_RAD)
		end
		self:set_yaw(yaw, 8)
		--[[	else
		if not self.facing_fence then
			local nod = self:node_infront_ok(vector.floor(s), 0.5)
			if minetest.registered_nodes[nod.name] and minetest.registered_nodes[nod.name].walkable == true then
				yaw = yaw + YAW_RAD
				self:set_yaw( yaw, .1)
			end
		end]]
	end
	if self.order == "sit" then
		self:set_animation("sit")
		self:set_velocity(0)
		self:slow_mob()
	else
		self:set_animation("stand")
		self:set_velocity(0)
		self:slow_mob()
	end

	--walk_log("stand in " .. self.standing_in .. ", on " .. self.standing_on)
	if self.order == "stand" or self.order == "work" or self.order == "sleep" then
		self:set_state("stand")
		self:set_animation("stand")
	else
		if
			self.walk_chance ~= 0
			and self.facing_fence ~= true
			and math.random(1, 100) <= self.walk_chance
			and self:is_at_cliff_or_danger() == false
		then

			if self.fly then
				fly_log("walk or fly, is_at_cliff_or_danger: " .. dump(self:is_at_cliff_or_danger()))
				self:flying_actions(true)
			elseif self.swims then
				self:swim_or_jump()
			else
				self:set_velocity(self.walk_velocity)
				self:set_state("walk")
				self:set_animation("walk")
			end
		else
			if self.swims then
				self:swim_or_jump()
			end
		end
	end
end

function mob_class:fly_forward(y)
	-- let's be a bit random for flying
	local target_velocity = math.random(self.fly_velocity / 2, self.fly_velocity)
	self:set_velocity(target_velocity)
	fly_log("flying, y: " .. y .. ", target_velocity:  " .. target_velocity)

	local dir_x, dir_z = self:forward_directions()
	self.object:set_velocity(vector.new(dir_x, y, dir_z))
	self.object:set_acceleration(vector.new(dir_x, y, dir_z))

	self:set_animation(self:fly_or_walk_anim())
	self:set_state("fly")
end

function mob_class:do_states_fly()
	local s = self.object:get_pos()

	local is_in_danger = (self:is_node_dangerous(self.standing_in) or self:is_node_dangerous(self.standing_on))

	if not is_in_danger then
		local distance = self.avoid_distance or self.view_range / 2
		-- find specific node to avoid
		if self:is_object_in_view(self.avoid_nodes, distance, distance, true) then
			self:set_velocity(self.walk_velocity)
		-- otherwise randomly turn
		elseif math.random(1, 100) <= 30 then
			self:turn_away(1)
		end
	end

	local facing_solid = false

	-- No need to check if we are already going to turn
	if not self.facing_fence then
		local nod = self:node_infront_ok(vector.floor(s), 0.5)

		if minetest.registered_nodes[nod.name] and minetest.registered_nodes[nod.name].walkable == true then
			facing_solid = true
		end
	end

	fly_log("flying in " .. self.standing_in .. ", on " .. self.standing_on)

	if self.facing_fence == true or facing_solid or math.random(1, 100) <= 30 then

		self:turn_away(2)

		if self:should_flap() then
			fly_log("flapping?")
			self:slow_mob()
			self:set_animation("walk")
		else
			self:set_velocity(0)
			self:set_state("stand")
			self:set_animation("stand")
			self:slow_mob()
			fly_log("standing or floating?")
		end
	else
		self:flying_actions()
	end
end

function mob_class:go_to_water()
	local mypos = self.object:get_pos()
	local water = minetest.find_nodes_in_area_under_air(
		vector.offset(mypos, -24, -8, -24),
		vector.offset(mypos, 24, 8, 24),
		{ "group:water" }
	)

	local closest = 10000
	local closest_water

	for _, v in pairs(water) do
		local dst = vector.distance(mypos, v)
		if dst < closest then
			closest = dst
			closest_water = v
		end
	end

	-- TODO should flop in direction of water rather than swimming
	-- ... unless an axolotl?
	if closest_water then
		self:set_velocity(self.walk_velocity)
		self:go_to_pos(closest_water)
		return true
	end

	return false
end

function mob_class:swim_forward(y)
	local target_velocity = math.random(self.walk_velocity, self.swim_velocity)
	swim_log("swim_forward y: " .. y .. ", target_velocity " .. target_velocity)

	self:set_velocity(target_velocity)
	local dir_x, dir_z = self:forward_directions()
	self.object:set_acceleration(vector.new(dir_x, y, dir_z))
	self.object:set_velocity(vector.new(dir_x, y, dir_z))
	self:set_state("swim")
	self:set_animation(self:swim_or_walk_anim())
end

function mob_class:swim_or_jump()

	swim_log(
		"swim_or_jump "
			.. self.name
			.. ", head: "
			.. self.head_in
			.. ", in: "
			.. self.standing_in
			.. ", self.breath: "
			.. self.breath
	)

	if self.breathes_in_water == false and self.head_in == "air" then
		-- one breath back to max, just like a ral dolphin ^_^
		-- TODO some effect for this? Thar she blows!
		self.breath = self.object:get_properties().breath_max
	end

	-- TODO handle jumping out of water. e.g. Dolphin
	if self:swim_check() then
		swim_log("swim_check OK")
		local s = self.object:get_pos()
		local y = math.random(6, 15) / 10

		-- TODO maybe this should be a setting to allow different swimmers to act differently?
		-- e.g. some might swim closer to the surface more often than others...
		if math.random() < 0.3 then
			swim_log("swim_or_jump random")
			y = -y
		elseif
			not self:swim_check(vector.offset(s, 0, 1, 0))
			or (self.object:get_properties().breath_max == -1 and not self:swim_check(vector.offset(s, 0, 2, 0)))
		then
			swim_log("don't swim up")
			y = -y
		end

		self:swim_forward(y)
	else
		local def = minetest.registered_nodes[self.standing_on]

		-- not in water
		swim_log("swim_or_jump swim_check failed, falling?\n" .. dump(def))

		-- to fall or to flop, that is the question ...
		if def.drawtype == "airlike" then
			-- fall
			swim_log("swim_or_jump falling in air!")
			local a = self.object:get_acceleration()
			self.object:set_acceleration(vector.new(a.x * 0.8, self.fall_speed, a.z * 0.8))
			local dir_x, dir_z = self:forward_directions()
			self.object:set_velocity(vector.new(dir_x, -1, dir_z))
			self:set_animation("walk")
			self:set_state("swim")
		elseif def.drawtype == "liquid" then
			-- fall
			swim_log("swim_or_jump falling in to water!")
			--self.object:set_acceleration({ x = 0, y = -1.5, z = 0 })
			self.object:set_acceleration({ x = 0, y = DEFAULT_FALL_SPEED, z = 0 })
			--local dir_x, dir_z = self:forward_directions()
			self:slow_mob()
			--self.object:set_velocity(vector.new(dir_x, -1, dir_z))
			self:set_animation("walk")
			self:set_state("swim")
		else
			swim_log("swim_or_jump go_to_water?")

			if not self:go_to_water() then
				--flop
				swim_log("swim_or_jump flopping?")
				self:set_state("flop")
				self.object:set_acceleration({ x = 0, y = DEFAULT_FALL_SPEED, z = 0 })

				local p = self.object:get_pos()
				local cbox = self.object:get_properties().collisionbox
				local sdef = minetest.registered_nodes[mcl_mobs.node_ok(vector.add(p, vector.new(0, cbox[2] - 0.2, 0))).name]
				-- Flop on ground
				if sdef and sdef.walkable then
					if self.object:get_velocity().y < 0.1 then
						self:mob_sound("flop")
						self.object:set_velocity({
							x = math.random(-FLOP_HOR_SPEED, FLOP_HOR_SPEED),
							y = FLOP_HEIGHT,
							z = math.random(-FLOP_HOR_SPEED, FLOP_HOR_SPEED),
						})
					end
				end

				self:set_animation("stand", true)
			end
		end
	end
end

function mob_class:turn_away(delay)
	walk_log(self.order .. ", " .. debug.traceback())
	if not self:check_timer("turn_away", 0.3) then
		return
	end
	if self.order == "jump" or self._jumping_cliff then
		return
	end

	local yaw = self.object:get_yaw() or 0
	local turn = mcl_util.float_random(YAW_RAD / 2, YAW_RAD)
	if math.random() < 0.5 then
		turn = -turn
	end

	delay = delay or 1

	yaw = yaw + turn
	self:set_yaw(yaw, delay)
end

function mob_class:do_states_swim()
	local s = self.object:get_pos()

	local distance = self.avoid_distance or self.view_range / 2
	-- find specific node to avoid
	if self:is_object_in_view(self.avoid_nodes, distance, distance, true) then
		self:set_velocity(self.walk_velocity)
	-- otherwise randomly turn
	elseif math.random(1, 100) <= 30 then
		self:turn_away(3)
	end

	local facing_solid = false

	-- No need to check if we are already going to turn
	if not self.facing_fence then
		local nod = self:node_infront_ok(vector.floor(s), 0)
		if minetest.registered_nodes[nod.name] and minetest.registered_nodes[nod.name].walkable == true then
			facing_solid = true
		end
	end

	swim_log(
		"swimming in " .. self.standing_in .. ", on " .. self.standing_on .. ", facing_solid: " .. dump(facing_solid)
	)

	-- TODO do something here to slow swimmwers down as they approach the water's edge
	if self.facing_fence == true or facing_solid or math.random(1, 100) <= 30 then
		self:set_state("stand")
		self:turn_away(3)
		self:slow_mob()
		if self.object:get_velocity().y < 0.1 then
			self:set_animation("stand")
		else
			self:set_animation("walk")
		end
	end

	self:swim_or_jump()
end

function mob_class:do_states_runaway()
	self.runaway_timer = self.runaway_timer + 1

	-- stop after 5 seconds or when at cliff
	if self.runaway_timer > 5 or self:is_at_cliff_or_danger() then
		self.runaway_timer = 0
		self:set_velocity(0)
		self:set_state("stand")
		self:set_animation("stand")
		self:turn_away(2)
	else
		self:set_velocity(self.run_velocity)
		self:set_animation("run")
	end
end

function mob_class:check_smooth_rotation(dtime)
	-- smooth rotation by ThomasMonroe314
	if self._turn_to and self.order ~= "sleep" then
		self:set_yaw( self._turn_to, .1)
	end
	if self.delay and self.delay > 0 then
		local yaw = self.object:get_yaw() or 0
		if self.delay == 1 then
			yaw = self.target_yaw
		else
			local dif = math.abs(yaw - self.target_yaw)
			if yaw > self.target_yaw then
				if dif > math.pi then
					dif = 2 * math.pi - dif -- need to add
					yaw = yaw + dif / self.delay
				else
					yaw = yaw - dif / self.delay -- need to subtract
				end
			elseif yaw < self.target_yaw then
				if dif >math.pi then
					dif = 2 * math.pi - dif
					yaw = yaw - dif / self.delay -- need to subtract
				else
					yaw = yaw + dif / self.delay -- need to add
				end
			end
			if yaw > (math.pi * 2) then yaw = yaw - (math.pi * 2) end
			if yaw < 0 then yaw = yaw + (math.pi * 2) end
		end
		self.delay = self.delay - 1
		if self.shaking then
			yaw = yaw + (math.random() * 2 - 1) * 5 * dtime
		end
		self.object:set_yaw(yaw)
	end
	-- end rotation
end

--this is a generic climb function
function mob_class:climb()
	local current_velocity = self.object:get_velocity()
	local goal_velocity = {x=0, y=3, z=0}
	local new_velocity_addition = vector.subtract(goal_velocity,current_velocity)
	new_velocity_addition.x = 0
	new_velocity_addition.z = 0

	--smooths out mobs a bit
	if vector.length(new_velocity_addition) >= 0.0001 then
		self.object:add_velocity(new_velocity_addition)
	end
end
