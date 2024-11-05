local mob_class = mcl_mobs.mob_class
-- API for Mobs Redo: MineClone 2 Edition (MRM)

local PATHFINDING = "gowp"

-- Localize
local S = minetest.get_translator("mcl_mobs")

-- Invisibility mod check
mcl_mobs.invis = {}

local peaceful_mode = minetest.settings:get_bool("only_peaceful_mobs", false)

function mob_class:set_properties(prop)
	mcl_util.set_properties(self.object, prop)
end

function mob_class:safe_remove()
	self.removed = true
	minetest.after(0,function(obj)
		if obj and obj:get_pos() then
			mcl_burning.extinguish(obj)
			obj:remove()
		end
	end,self.object)
end

function mob_class:get_nametag()
	return self.nametag or ""
end

function mob_class:update_tag() --update nametag and/or the debug box
	self:set_properties({
		nametag = self:get_nametag(),
	})
end

function mob_class:update_timers(dtime)
	for k, v in pairs(self._timers) do
		self._timers[k] = v - dtime
	end
end

function mob_class:check_timer(timer, interval)
	if not self._timers[timer] then
		self._timers[timer] = math.random() * interval --start with a random time to avoid many timers firing simultaneously
	end
	if self._timers[timer] <= 0  then
		self._timers[timer] = interval
		return true
	end
	return false
end

function mob_class:jock_to(mob, reletive_pos, rot)
	self.jockey = mob
	local jock = minetest.add_entity(self.object:get_pos(), mob)
	if not jock then return end
	jock:get_luaentity().docile_by_day = false
	jock:get_luaentity().riden_by_jock = true
	self.object:set_attach(jock, "", reletive_pos, rot)
	return jock
end

--[[
NOTE: This function is not called when something is about to despawn.

It is called every 18 seconds.

DO NOT change the state of the mob in this function!

Edit the copied state so it's serialized in the state you need to.
]]
function mob_class:get_staticdata()
	local pos = self.object:get_pos()
	if not mcl_mobs.check_vector(pos) then
		self.object:remove()
		return
	end

	local tmp = {}

	for tag, stat in pairs(self) do

		local t = type(stat)

		if  t ~= "function"
		and t ~= "nil"
		and t ~= "userdata"
		and tag ~= "_cmi_components" then
			tmp[tag] = self[tag]
		end
	end

	if self._mcl_potions then
		tmp._mcl_potions = self._mcl_potions
		for name_raw, data in pairs(tmp._mcl_potions) do
			data.spawner = nil
			local def = mcl_potions.registered_effects[name_raw:match("^_EF_(.+)$")]
			if def and def.on_save_effect then def.on_save_effect(self.object) end
		end
	else
		tmp._mcl_potions = {}
	end

	return minetest.serialize(tmp)
end

function mob_class:valid_texture(def_textures)
	if not self.base_texture then
		return false
	end

	if self.texture_selected then
		if #def_textures < self.texture_selected then
			self.texture_selected = nil
		else
			return true
		end
	end
	return false
end

function mob_class:update_textures()
	local def = mcl_mobs.registered_mobs[self.name]
	--If textures in definition change, reload textures
	if not self:valid_texture(def.texture_list) then

		-- compatiblity with old simple mobs textures
		if type(def.texture_list[1]) == "string" then
			def.texture_list = {def.texture_list}
		end

		if not self.texture_selected then
			local c = 1
			if #def.texture_list > c then c = #def.texture_list end
			self.texture_selected = math.random(c)
		end

		self.base_texture = def.texture_list[self.texture_selected]
		self.base_mesh = def.initial_properties.mesh
		self.base_size = def.initial_properties.visual_size
		self.base_colbox = def.initial_properties.collisionbox
		self.base_selbox = def.initial_properties.selectionbox
	end
end

function mob_class:scale_size(scale, force)
	if self.scaled and not force then return end
	self:set_properties({
		visual_size = {
			x = self.base_size.x * scale,
			y = self.base_size.y * scale,
		},
		collisionbox = {
			self.base_colbox[1] * scale,
			self.base_colbox[2] * scale,
			self.base_colbox[3] * scale,
			self.base_colbox[4] * scale,
			self.base_colbox[5] * scale,
			self.base_colbox[6] * scale,
		},
		selectionbox = {
			self.base_selbox[1] * scale,
			self.base_selbox[2] * scale,
			self.base_selbox[3] * scale,
			self.base_selbox[4] * scale,
			self.base_selbox[5] * scale,
			self.base_selbox[6] * scale,
		},
	})
	self.scaled = true
end

function mob_class:reset_path()
	self.path = {}
	self.path.way = {} -- path to follow, table of positions
	self.path.lastpos = {x = 0, y = 0, z = 0}
	self.path.stuck = false
	self.path.following = false
	self.path.stuck_timer = 0
end

function mob_class:mob_activate(staticdata, dtime)
	if not self.object:get_pos() or staticdata == "remove" then
		mcl_burning.extinguish(self.object)
		self.object:remove()
		return
	end

	if staticdata then
		local tmp = minetest.deserialize(staticdata)

		if tmp then
			for _,stat in pairs(tmp) do
				self[_] = stat
			end
		end
	end

	if not self.state then
		self:set_state("stand")
	elseif self.state == "die" then
		self:safe_remove()
		return
	elseif self.state == "attack" then
		if not self.attack or not self.attack.get_pos or not self.attack:get_pos() then
			self:set_state("stand")
		end
	end

	if peaceful_mode and not self.persist_in_peaceful then
		mcl_burning.extinguish(self.object)
		self.object:remove()
		return
	end

	self:update_textures()
	self:reset_path()

	if not self.base_selbox then
		self.base_selbox = self.initial_properties.selectionbox or self.base_colbox
	end

	if self.gotten == true
	and self.gotten_texture then
		self:set_properties({textures = self.gotten_texture })
	end

	if self.gotten == true
	and self.gotten_mesh then
		self:set_properties({mesh = self.gotten_mesh})
	end

	local def = mcl_mobs.registered_mobs[self.name]
	if self.child == true then
		self:scale_size(0.5)
		if def.child_texture then
			self.base_texture = def.child_texture[1]
		end
	end

	if self.health == 0 then
		self.health = math.random (self.hp_min, self.object:get_properties().hp_max)
	end
	if self.breath == nil then
		self.breath = self.object:get_properties().breath_max
	end

	-- Armor groups
	-- immortal=1 because we use custom health
	-- handling (using "health" property)
	local armor
	if type(self.armor) == "table" then
		armor = table.copy(self.armor)
		armor.immortal = 1
	else
		armor = {immortal=1, fleshy = self.armor}
	end
	self.object:set_armor_groups(armor)
	self.sounds.distance = self.sounds.distance or 10

	self.object:set_texture_mod("")

	if not self.nametag then
		self.nametag = def.nametag
	end

	self.base_size = self.base_size or {x = 1, y = 1, z = 1}

	if self.base_texture then
		self:set_properties({textures = self.base_texture})
	end

	self:set_yaw( (math.random(0, 360) - 180) / 180 * math.pi, 6)
	self:update_tag()
	self._current_animation = nil
	self:set_animation( "stand")

	if self.riden_by_jock then --- Keep this function before self.on_spawn() is run.
		self.object:remove()
		return
	end

	if self.on_spawn and not self.on_spawn_run then
		if self:on_spawn() == false then
			self:safe_remove()
			return
		else
			self.on_spawn_run = true
		end
	end

	if not self.wears_armor and self.armor_list then
		self.armor_list = nil
	elseif not self._run_armor_init and self.wears_armor then
		self.armor_list = { head = "", torso = "", feet = "", legs = "" }
		self:set_armor_texture()
		self._run_armor_init = true
	end

	if not self._mcl_potions then
		self._mcl_potions = {}
	end
	mcl_potions._load_entity_effects(self)

	if def.after_activate then
		def.after_activate(self, staticdata, def, dtime)
	end
end

function mob_class:forward_directions()
	local yaw = self.object:get_yaw()
	local cbox = self.object:get_properties().collisionbox
	local dir_x = -math.sin(yaw) * (cbox[4] + 0.5)
	local dir_z = math.cos(yaw) * (cbox[4] + 0.5)

	return dir_x, dir_z
end

function mob_class:node_infront_ok(pos, y_adjust, fallback)
	fallback = fallback or mcl_mobs.fallback_node

	local dir_x, dir_z = self:forward_directions()
	local node = minetest.get_node_or_nil(vector.offset(pos, dir_x, y_adjust, dir_z))

	if node and minetest.registered_nodes[node.name] then
		return node
	end

	return minetest.registered_nodes[fallback]
end

function mob_class:set_state(state)
	if self.state == "die" then
		return
	end
	--minetest.log("set_state: " .. state .. ", " .. debug.traceback())
	self.state = state
end

-- returns true if mob has died
-- which only happens if a mob explodes itself as part of an attack
function mob_class:do_states(dtime)
	--minetest.log("state: " .. self.state .. ", order: " .. self.order .. ", mob: " .. self.name)
	if self.state == PATHFINDING then
		self:check_gowp(dtime)
	elseif self.state == "walk" then
		self:do_states_walk()
	elseif self.state == "runaway" then
		self:do_states_runaway()
	elseif self.state == "attack" then
		if self:do_states_attack(dtime) then
			return true
		end
	elseif self.state == "fly" then
		self:do_states_fly()
	elseif self.state == "swim" or self.state == "flop" then
		self:do_states_swim()
	else
		self:do_states_stand()
	end
end

local function update_attack_timers (self, dtime)
	if self.pause_timer > 0 then
		self.pause_timer = self.pause_timer - dtime
		return true
	end
	-- attack timer
	self.timer = self.timer + dtime
	if self.state ~= "attack" and self.state ~= PATHFINDING then
		if self.timer < 1 then
			return true
		end
		self.timer = 0
	end

	if self.timer > 100 then
		self.timer = 1
	end
end

function mob_class:on_step(dtime, moveresult)
	local pos = self.object:get_pos()
	if not mcl_mobs.check_vector(pos) or self.removed then
		self:safe_remove()
		return
	end
	local should_drive = self:should_drive ()

	if self:check_despawn(pos, dtime) then return true end

	self:update_tag()

	if not should_drive or self.steer_class ~= "follow_item" then
	   self:slow_mob ()
	end

	if not (moveresult and moveresult.touching_ground) and self:falling(pos) then return end

	-- Get nodes early for use in other functions
	local cbox = self.object:get_properties().collisionbox
	local y_level = cbox[2]

	if self.child then
		y_level = cbox[2] * 0.5
	end

	local p = vector.copy(pos)
	p.y = p.y + y_level + 0.25 -- foot level
	local pos2 = vector.offset(pos, 0, -1, 0)
	self.standing_in =  mcl_mobs.node_ok(p, "air").name
	self.standing_on =  mcl_mobs.node_ok(pos2, "air").name
	local pos_head = vector.offset(p, 0, cbox[5] - 0.5, 0)
	self.head_in =  mcl_mobs.node_ok(pos_head, "air").name

	self:falling (pos)

	if self.force_step then
		self:force_step(dtime)
	end

	self:update_timers(dtime)
	if self:check_suspend() then
		self.object:set_velocity(vector.zero()) --stop movement otherwise mobs keep moving continuously
		return
	end

	self:check_water_flow()

	if not self.driver then
	   self:env_danger_movement_checks (dtime)
	end

	if not self.fire_resistant then
		mcl_burning.tick(self.object, dtime, self)
		-- mcl_burning.tick may remove object immediately
		if not self.object:get_pos() then return end
	end

	if self.state == "die" then return end

	if should_drive then
	   self:check_smooth_rotation (dtime)

	   -- Called only to reset the swivel.
	   self:check_head_swivel (dtime, true)
	   self:drive ("walk", "stand", false, dtime, moveresult)
	   self:env_damage (dtime, pos)
	   self:check_particlespawners(dtime)
	   self:check_item_pickup()
	else
	   self:follow_player() -- Mob following code.
	   self:set_animation_speed()
	   self:check_smooth_rotation(dtime)
	   self:check_head_swivel(dtime)

	   self:set_armor_texture()
	   self:check_runaway_from()

	   self:attack_players_and_npcs()
	   self:attack_monsters()
	   self:attack_specific()

	   self:check_breeding()
	   self:check_aggro(dtime)

	   -- Expel drivers riding submerged mobs.
	   self:expel_underwater_drivers ()
	end

	if self.do_custom then
		if self.do_custom(self, dtime) == false then
			return
		end
	end

	if should_drive then
	   return
	end

	if self._just_portaled then
		self._just_portaled = self._just_portaled - dtime
		if self._just_portaled < 0 then
			self._just_portaled = nil
		end
	end

	if update_attack_timers(self, dtime) then
	   return
	end

	self:check_particlespawners(dtime)
	self:check_item_pickup()

	if self.opinion_sound_cooloff > 0 then
		self.opinion_sound_cooloff = self.opinion_sound_cooloff - dtime
	end
	-- mob plays random sound at times. Should be 120. Zombie and mob farms are ridiculous
	if math.random(1, 70) == 1 then
		self:mob_sound("random", true)
	end

	if self:env_damage (dtime, pos) then return end
	if self:do_states(dtime) then return end

	--mobs that can climb over stuff
	if self.always_climb
	   and self:node_infront_ok(pos, 0).name ~= "air" then
		self:climb()
	end

	if self.jump_sound_cooloff > 0 then
		self.jump_sound_cooloff = self.jump_sound_cooloff - dtime
	end

	self:do_jump()

	if not self.object:get_luaentity() then
		return false
	end
end

minetest.register_chatcommand("clearmobs",{
	privs = { maphack = true },
	params = "[<all> | <nametagged> | <tamed>] [<range>]",
	description=S("Remove all, nametagged or tamed mobs within the specified distance or everywhere. When unspecified remove all mobs except tamed and nametagged ones."),
	func=function(n,param)
		local sparam = param:split(" ")
		local p = minetest.get_player_by_name(n)

		local typ
		local range
		if sparam[1] then
			typ = sparam[1]
			if typ ~= "all" and typ ~= "nametagged" and typ ~= "tamed" then
				typ = nil
				range = tonumber(sparam[1])
				if not range then
					return false, S("Invalid syntax.")
				end
			end
		end
		if sparam[2] then
			range = tonumber(sparam[2])
			if not range then
				return false, S("Invalid syntax.")
			end
		end

		for _, o in pairs(minetest.luaentities) do
			if o.is_mob then
				if not range or vector.distance(p:get_pos(), o.object:get_pos()) <= range then
					if typ == "all" or
						(typ == "nametagged" and o.nametag) or
						(typ == "tamed" and o.tamed and not o.nametag) or
						(not typ and not o.nametag and not o.tamed) then
						o:safe_remove()
					end
				end
			end
		end
end})
