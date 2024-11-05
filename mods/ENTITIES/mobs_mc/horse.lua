local S = minetest.get_translator("mobs_mc")
local mob_class = mcl_mobs.mob_class

local extended_pet_control = minetest.settings:get_bool("mcl_extended_pet_control",false)

local base_drop = {
	name = "mcl_mobitems:leather",
	chance = 1,
	min = 0,
	max = 2,
	looting = "common",
}

local function horse_extra_texture(horse, cstring)
	local base = horse._naked_texture or horse.base_texture[2]
	local saddle = horse._saddle
	local chest  = horse._chest
	local armor = horse._horse_armor
	local textures = {}
	if armor and minetest.get_item_group(armor, "horse_armor") > 0 then
		if cstring then
			textures[2] = base .. "^(" .. minetest.registered_items[armor]._horse_overlay_image:gsub(".png$", "_desat.png").."^[multiply:"..cstring..")"
		else
			textures[2] = base .. "^" .. minetest.registered_items[armor]._horse_overlay_image
		end
	else
		textures[2] = base
	end
	if saddle then
		textures[3] = base
	else
		textures[3] = "blank.png"
	end
	if chest then
		textures[1] = base
	else
		textures[1] = "blank.png"
	end
	return textures
end

local function attach_driver(self, clicker)
	mcl_title.set(clicker, "actionbar", {text=S("Sneak to dismount"), color="white", stay=60})
	self.object:set_properties({stepheight = 1.1})
	self.object:set_properties({selectionbox = {0,0,0,0,0,0}})
	self:attach(clicker)
end

local function detach_driver(self)
	self.object:set_properties({stepheight = 0.6})
	self.object:set_properties({selectionbox = self.object:get_properties().collisionbox})
	if self.driver then
		if extended_pet_control and self.order ~= "sit" then self:toggle_sit(self.driver) end
		mcl_mobs.detach(self.driver, {x=0, y=0, z=0})
	end
end

local can_equip_horse_armor = function(entity_id)
	return entity_id == "mobs_mc:horse" or entity_id == "mobs_mc:skeleton_horse" or entity_id == "mobs_mc:zombie_horse"
end

local can_breed = function(entity_id)
	return entity_id == "mobs_mc:horse" or "mobs_mc:mule" or entity_id == "mobs_mc:donkey"
end

local horse_base = {
	"mobs_mc_horse_brown.png",
	"mobs_mc_horse_darkbrown.png",
	"mobs_mc_horse_white.png",
	"mobs_mc_horse_gray.png",
	"mobs_mc_horse_black.png",
	"mobs_mc_horse_chestnut.png",
	"mobs_mc_horse_creamy.png",
}

local horse_markings = {
	"", -- no markings
	"mobs_mc_horse_markings_whitedots.png", -- snowflake appaloosa
	"mobs_mc_horse_markings_blackdots.png", -- sooty
	"mobs_mc_horse_markings_whitefield.png", -- paint
	"mobs_mc_horse_markings_white.png", -- stockings and blaze
}

local horse_textures = {}
for b=1, #horse_base do
	for m=1, #horse_markings do
		local fur = horse_base[b]
		if horse_markings[m] ~= "" then
			fur = fur .. "^" .. horse_markings[m]
		end
		table.insert(horse_textures, {
			"blank.png", -- chest
			fur, -- base texture + markings and optional armor
			"blank.png", -- saddle
		})
	end
end

-- Horse
local horse = {
	description = S("Horse"),
	type = "animal",
	spawn_class = "passive",
	spawn_in_group_min = 2,
	spawn_in_group = 6,
	visual = "mesh",
	mesh = "mobs_mc_horse.b3d",
	visual_size = {x=3.0, y=3.0},
	collisionbox = {-0.69825, -0.01, -0.69825, 0.69825, 1.59, 0.69825},
	runaway = true,
	run_velocity = 2,
	follow_velocity = 1.5,
	animation = {
		stand_start = 0, stand_end = 0, stand_speed = 25,
		walk_start = 0, walk_end = 40, walk_speed = 25,
		run_start = 0, run_end = 40, run_speed = 50,
	},
	textures = horse_textures,
	sounds = {
		random = "mobs_mc_horse_random",
		-- TODO: Separate damage sound
		damage = "mobs_mc_horse_death",
		death = "mobs_mc_horse_death",
		eat = "mobs_mc_animal_eat_generic",
		distance = 16,
	},
	fear_height = 4,
	fly = false,
	walk_chance = 60,
	view_range = 16,
	steer_class = "controls",
	follow = {
		"mcl_farming:carrot_item_gold",
		"mcl_core:apple_gold",
		"mcl_core:apple_gold_enchanted",
	},
	_temper_increase = {
		["mcl_core:sugar"] = 3,
		["mcl_farming:wheat_item"] = 3,
		["mcl_core:apple"] = 3,
		["mcl_farming:carrot_item_gold"] = 5,
		["mcl_core:apple_gold"] = 10
	},
	passive = true,
	hp_min = 15,
	hp_max = 30,
	xp_min = 1,
	xp_max = 3,
	floats = 1,
	makes_footstep_sound = true,
	jump = true,
	jump_height = 5.75,
	drops = { base_drop },
	should_drive = function (self)
		return self._saddle and mob_class.should_drive (self)
	end,
	on_spawn = function(self)
		local tex = horse_extra_texture(self)
		self.object:set_properties({textures = tex})
		self._horse_speed = math.random(486, 1457)/100
		self._horse_jump = math.random(575, 875)/100
	end,
	do_custom = function(self, dtime)
		if self.driver then
			local ctrl = self.driver:get_player_control()
			if ctrl and ctrl.sneak then
				detach_driver(self)
			end
			if self.run_velocity ~= self._horse_speed then
				self.run_velocity = self._horse_speed
			end
			if self.jump_height ~= self._horse_jump then
				self.jump_height = self._horse_jump
			end
		else
			detach_driver(self)
			self.run_velocity = self.initial_properties.run_velocity
			self.jump_height = self.initial_properties.jump_height
		end

		if not self.v2 then
			local vsize = self.object:get_properties().visual_size
			self.v2 = 0
			self.max_speed_forward = 7
			self.max_speed_reverse = 2
			self.accel = 6
			self.terrain_type = 3
			self.driver_attach_at = {x = 0, y = 4.17, z = -1.75}
			self.driver_eye_offset = {x = 0, y = 3, z = 0}
			self.driver_scale = {x = 1/vsize.x, y = 1/vsize.y}
		end

		self._regentimer = ( self._regentimer or 0) + dtime
		if self._regentimer >= 4 then
			if self.health < self.object:get_properties().hp_max then
				self.health = self.health + 1
			end
			self._regentimer = 0
		end

		if self.driver and not self.tamed and self.buck_off_time <= 0 then
			if math.random() < 0.2 then
				detach_driver(self)
				-- TODO bucking animation
			else
				self.buck_off_time = 20
			end
		end

		if self.buck_off_time then
			if self.driver then
				self.buck_off_time = self.buck_off_time - 1
			else
				self.buck_off_time = nil
			end
		end

		return true
	end,
	on_die = function(self)
		if self.driver then
			detach_driver(self)
		end
	end,
	on_rightclick = function(self, clicker)
		if not clicker or not clicker:is_player() then
			return
		end

		local item = clicker:get_wielded_item()
		local iname = item:get_name()
		local heal = 0

		if self._inv_id then
			if not self._chest and item:get_name() == "mcl_chests:chest" then
				item:take_item()
				clicker:set_wielded_item(item)
				self._chest = true
				-- Update texture
				if not self._naked_texture then
					-- Base horse texture without chest or saddle
					self._naked_texture = self.base_texture[2]
				end
				local tex = horse_extra_texture(self)
				self.base_texture = tex
				self.object:set_properties({textures = self.base_texture})
				self:update_drops()
				return
			elseif self._chest and clicker:get_player_control().sneak then
				mcl_entity_invs.show_inv_form(self,clicker)
				return
			end
		end

		if self:break_in(clicker) then return end

		if can_breed(self.name) then
			if (iname == "mcl_core:apple_gold") or (iname == "mcl_core:apple_gold_enchanted") then
				heal = 10
			elseif (iname == "mcl_farming:carrot_item_gold") then
				heal = 4
			end
			if heal > 0 and self:feed_tame(clicker, heal, true, false) then
				return
			end
		end

		if (iname == "mcl_core:sugar") then
			heal = 1
		elseif (iname == "mcl_farming:wheat_item") then
			heal = 2
		elseif (iname == "mcl_core:apple") then
			heal = 3
		elseif (iname == "mcl_farming:hay_block") then
			heal = 20
		end
		if heal > 0 and self:feed_tame(clicker, heal, false, false) then
			return
		end

		if self.tamed and not self.child and self.owner == clicker:get_player_name() then
			if not self.driver and clicker:get_player_control().sneak then
				return
			elseif not self.driver and iname == "mcl_mobitems:saddle" and self:set_saddle(clicker) then
				return
			elseif minetest.get_item_group(iname, "horse_armor") > 0 and can_equip_horse_armor(self.name) and not self.driver and self:set_armor(clicker) then
				return
			elseif not self.driver then
				attach_driver(self, clicker)
			end
		end
	end,
	set_saddle = function(self, clicker)
		if not self._saddle then
			local w = clicker:get_wielded_item()
			self._saddle = true
			if not minetest.is_creative_enabled(clicker:get_player_name()) then
				w:take_item()
				clicker:set_wielded_item(w)
			end
			if not self._naked_texture then
				self._naked_texture = self.base_texture[2]
			end
			local tex = horse_extra_texture(self)
			self.base_texture = tex
			self.object:set_properties({textures = self.base_texture})
			minetest.sound_play({name = "mcl_armor_equip_leather"}, {gain=0.5, max_hear_distance=12, pos=self.object:get_pos()}, true)
			self:update_drops()
			return true
		end
	end,
	set_armor = function(self, clicker)
		local w = clicker:get_wielded_item()
		local iname = w:get_name()
		if iname ~= self._horse_armor then
			local cstring
			if minetest.get_item_group(iname, "armor_leather") > 0 then
				local m = w:get_meta()
				local cs = m:get_string("mcl_armor:color")
				cstring = cs ~= "" and cs or nil
			end
			if not minetest.is_creative_enabled(clicker:get_player_name()) then
				w:take_item()
				clicker:set_wielded_item(w)
				if self._horse_armor then
					minetest.add_item(self.object:get_pos(), self._horse_armor)
				end
			end
			local armor = minetest.get_item_group(iname, "horse_armor")
			self._wearing_armor = true
			self._horse_armor = iname
			self.armor = armor
			local agroups = self.object:get_armor_groups()
			agroups.fleshy = self.armor
			self.object:set_armor_groups(agroups)
			if not self._naked_texture then
				self._naked_texture = self.base_texture[2]
			end
			local tex = horse_extra_texture(self, cstring)
			self.base_texture = tex
			self.object:set_properties({textures = self.base_texture})
			local def = w:get_definition()
			if def.sounds and def.sounds._mcl_armor_equip then
				minetest.sound_play({name = def.sounds._mcl_armor_equip}, {gain=0.5, max_hear_distance=12, pos=self.object:get_pos()}, true)
			end
			return true
		end
	end,
	update_drops = function(self)
		self.drops = { base_drop }
		if self._saddle then
			table.insert(self.drops,{
				name = "mcl_mobitems:saddle",
				chance = 1,
				min = 1,
				max = 1,
			})
		end
		if self._horse_armor then
			table.insert(self.drops,{
				name = self._horse_armor,
				chance = 1,
				min = 1,
				max = 1,
			})
		end
		if self._chest then
			table.insert(self.drops,{
				name = "mcl_chests:chest",
				chance = 1,
				min = 1,
				max = 1,
			})
		end
	end,
	on_breed = function(parent1, parent2)
		local pos = parent1.object:get_pos()
		local child = mcl_mobs.spawn_child(pos, parent1.name)
		if child then
			local ent_c = child:get_luaentity()
			local p = math.random(1, 2)
			local child_texture
			if p == 1 then
				if parent1._naked_texture then
					child_texture = parent1._naked_texture
				else
					child_texture = parent1.base_texture[2]
				end
			else
				if parent2._naked_texture then
					child_texture = parent2._naked_texture
				else
					child_texture = parent2.base_texture[2]
				end
			end
			local splt = string.split(child_texture, "^")
			if #splt >= 2 then
				local base = splt[1]
				local markings = splt[2]
				local mutate_base = math.random(1, 9)
				local mutate_markings = math.random(1, 9)
				if mutate_base == 1 then
					local b = math.random(1, #horse_base)
					base = horse_base[b]
				end
				if mutate_markings == 1 then
					local m = math.random(1, #horse_markings)
					markings = horse_markings[m]
				end
				child_texture = base
				if markings ~= "" then
					child_texture = child_texture .. "^" .. markings
				end
			end
			ent_c.base_texture = { "blank.png", child_texture, "blank.png" }
			ent_c._naked_texture = child_texture
			child:set_properties({textures = ent_c.base_texture})
			return false
		end
	end,
}

mcl_mobs.register_mob("mobs_mc:horse", horse)

local skeleton_horse = table.merge(horse, {
	description = S("Skeleton Horse"),
	breath_max = -1,
	armor = {undead = 100, fleshy = 100},
	textures = {{"blank.png", "mobs_mc_horse_skeleton.png", "blank.png"}},
	drops = {
		{
			name = "mcl_mobitems:bone",
			chance = 1,
			min = 0,
			max = 2,
		},
	},
	sounds = {
		random = "mobs_mc_skeleton_random",
		death = "mobs_mc_skeleton_death",
		damage = "mobs_mc_skeleton_hurt",
		eat = "mobs_mc_animal_eat_generic",
		base_pitch = 0.95,
		distance = 16,
	},
	harmed_by_heal = true,
})

mcl_mobs.register_mob("mobs_mc:skeleton_horse", skeleton_horse)

mcl_mobs.register_mob("mobs_mc:zombie_horse", table.merge(skeleton_horse, {
	description = S("Zombie Horse"),
	textures = {{"blank.png", "mobs_mc_horse_zombie.png", "blank.png"}},
	drops = {
		{
			name = "mcl_mobitems:rotten_flesh",
			chance = 1,
			min = 0,
			max = 2,
		},
	},
	sounds = {
		random = "mobs_mc_horse_random",
		-- TODO: Separate damage sound
		damage = "mobs_mc_horse_death",
		death = "mobs_mc_horse_death",
		eat = "mobs_mc_animal_eat_generic",
		base_pitch = 0.5,
		distance = 16,
	},
}))

local d = 0.86
local donkey = table.merge(horse, {
	description = S("Donkey"),
	textures = {{"blank.png", "mobs_mc_donkey.png", "blank.png"}},
	spawn_in_group = 3,
	spawn_in_group_min = 1,
	animation = {
		stand_start = 0, stand_end = 0,
		walk_start = 0, walk_end = 40,
		run_speed = 50
	},
	sounds = {
		random = "mobs_mc_donkey_random",
		damage = "mobs_mc_donkey_hurt",
		death = "mobs_mc_donkey_death",
		eat = "mobs_mc_animal_eat_generic",
		distance = 16,
	},
	visual_size = { x=horse.visual_size.x*d, y=horse.visual_size.y*d },
	collisionbox = {
		horse.collisionbox[1] * d,
		horse.collisionbox[2] * d,
		horse.collisionbox[3] * d,
		horse.collisionbox[4] * d,
		horse.collisionbox[5] * d,
		horse.collisionbox[6] * d,
	},
	jump = true,
	jump_height = 3.75,
})

mcl_mobs.register_mob("mobs_mc:donkey", donkey)
mcl_entity_invs.register_inv("mobs_mc:donkey","Donkey",15,true)

local m = 0.94
mcl_mobs.register_mob("mobs_mc:mule", table.merge(donkey, {
	description = S("Mule"),
	textures = {{"blank.png", "mobs_mc_mule.png", "blank.png"}},
	visual_size = { x=horse.visual_size.x*m, y=horse.visual_size.y*m },
	sounds = table.merge(donkey.sounds, {
		base_pitch = 1.15,
	}),
	collisionbox = {
		horse.collisionbox[1] * m,
		horse.collisionbox[2] * m,
		horse.collisionbox[3] * m,
		horse.collisionbox[4] * m,
		horse.collisionbox[5] * m,
		horse.collisionbox[6] * m,
	},
}))
mcl_entity_invs.register_inv("mobs_mc:mule","Mule",15,true)

mcl_mobs.spawn_setup({
	name = "mobs_mc:horse",
	type_of_spawning = "ground",
	dimension = "overworld",
	aoc = 9,
	min_height = mobs_mc.water_level + 3,
	biomes = {
	"flat",
	"Plains",
	"Plains_beach",
	"SunflowerPlains",
	"Savanna",
	"Savanna_beach",
	"SavannaM",
	"Savanna_beach",
	"Plains_beach",
	},
	chance = 40,
})

mcl_mobs.spawn_setup({
	name = "mobs_mc:donkey",
	type_of_spawning = "ground",
	dimension = "overworld",
	aoc = 9,
	min_height = mobs_mc.water_level + 3,
	biomes = {
	"flat",
	"Plains",
	"Plains_beach",
	"SunflowerPlains",
	"Savanna",
	"Savanna_beach",
	"SavannaM",
	"Savanna_beach",
	"Plains_beach",
	"CherryGrove",
	},
	chance = 10,
})

mcl_mobs.register_egg("mobs_mc:horse", S("Horse"), "#c09e7d", "#eee500", 0)
mcl_mobs.register_egg("mobs_mc:skeleton_horse", S("Skeleton Horse"), "#68684f", "#e5e5d8", 0)
mcl_mobs.register_egg("mobs_mc:zombie_horse", S("Zombie Horse"), "#2a5a37", "#84d080", 0)
mcl_mobs.register_egg("mobs_mc:donkey", S("Donkey"), "#534539", "#867566", 0)
mcl_mobs.register_egg("mobs_mc:mule", S("Mule"), "#1b0200", "#51331d", 0)
