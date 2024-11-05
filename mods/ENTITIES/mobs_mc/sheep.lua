local S = minetest.get_translator("mobs_mc")
local WOOL_REPLACE_RATE = 80
local gotten_texture = { "blank.png", "mobs_mc_sheep.png" }

local function unicolor_to_wool(unicolor_group)
	local d = mcl_dyes.unicolor_to_dye(unicolor_group)
	if d then
		return "mcl_wool:"..d:gsub("^mcl_dyes:","")
	end
	return "mcl_wool:white"
end

local function sheep_texture(unicolor_group)
	local color = mcl_dyes.colors["white"].rgb.."00"
	local d = mcl_dyes.unicolor_to_dye(unicolor_group)
	if d then
		color = mcl_dyes.colors[d:gsub("^mcl_dyes:","")].rgb.."D0"
	end
	return {
		"mobs_mc_sheep_fur.png^[colorize:"..color,
		"mobs_mc_sheep.png",
	}
end

local function get_sheep_drops(unicolor_group)
	local wool = unicolor_to_wool(unicolor_group)
	return {
		{
			name = "mcl_mobitems:mutton",
			 chance = 1,
			 min = 1,
			 max = 2,
			 looting = "common",
		 },{
			name = wool,
			chance = 1,
			min = 1,
			max = 1,
			looting = "common",
		 },
	}
end

mcl_mobs.register_mob("mobs_mc:sheep", {
	description = S("Sheep"),
	type = "animal",
	spawn_class = "passive",
	hp_min = 8,
	hp_max = 8,
	xp_min = 1,
	xp_max = 3,
	collisionbox = {-0.45, -0.01, -0.45, 0.45, 1.29, 0.45},
	head_swivel = "head.control",
	bone_eye_height = 3.3,
	head_eye_height = 1.1,
	horizontal_head_height=-.7,
	curiosity = 6,
	head_yaw="z",
	visual = "mesh",
	mesh = "mobs_mc_sheepfur.b3d",
	textures = { sheep_texture("unicolor_white") },
	gotten_texture = gotten_texture,
	color = "unicolor_white",
	makes_footstep_sound = true,
	walk_velocity = 0.9,
	run_velocity = 1.5,
	follow_velocity = 1.5,
	runaway = true,
	runaway_from = {"mobs_mc:wolf"},
	drops = get_sheep_drops(),
	fear_height = 4,
	sounds = {
		random = "mobs_sheep",
		death = "mobs_sheep",
		damage = "mobs_sheep",
		sounds = "mobs_mc_animal_eat_generic",
		distance = 16,
	},
	animation = {
		stand_start = 0, stand_end = 0,
		walk_start = 0, walk_end = 40, walk_speed = 40,
		run_start = 0, run_end = 40, run_speed = 40,
		eat_start = 40, eat_end = 80, eat_loop = false,
	},
	_child_animations = {
		stand_start = 81, stand_end = 81,
		walk_start = 81, walk_end = 121, walk_speed = 80,
		run_start = 81, run_end = 121, run_speed = 80,
		eat_start = 121, eat_end = 161, eat_loop = false,
	},
	follow = { "mcl_farming:wheat_item" },
	view_range = 12,

	replace_rate = WOOL_REPLACE_RATE,
	replace_delay = 1.3,
	replace_what = {
		{ "mcl_core:dirt_with_grass", "mcl_core:dirt", -1 },
		{ "mcl_flowers:tallgrass", "air", 0 },
	},
	on_replace = function(self)
		self.color = self.color or "unicolor_white"
		self.base_texture = sheep_texture(self.color)
		self.drops = get_sheep_drops(self.color)
		self.state = "eat"
		self:set_animation("eat")
		self:set_velocity(0)

		minetest.after(self.replace_delay, function(self)
			if self and self.object and self.object:get_velocity() and self.health > 0 then
				self.object:set_velocity(vector.zero())
				self.gotten = false
				self.object:set_properties({ textures = self.base_texture })
			end
		end, self)

		minetest.after(2.5, function(self)
			if self and self.object and  self.object:get_pos() and self.state == 'eat' and self.health > 0 then
				self.state = "walk"
			end
		end,self)

	end,

	do_custom = function(self)
		if not self.initial_color_set then
			local r = math.random(0,100000)
			if r <= 81836 then -- 81.836%
				self.color = "unicolor_white"
			elseif r <= 81836 + 5000 then -- 5%
				self.color = "unicolor_grey"
			elseif r <= 81836 + 5000 + 5000 then-- 5%
				self.color = "unicolor_darkgrey"
			elseif r <= 81836 + 5000 + 5000 + 5000 then -- 5%
				self.color = "unicolor_black"
			elseif r <= 81836 + 5000 + 5000 + 5000 + 3000 then -- 3%
				self.color = "unicolor_dark_orange"
			else-- 0.164%
				self.color = "unicolor_light_red"
			end
			self.base_texture = sheep_texture(self.color)
			self.object:set_properties({ textures = self.base_texture })
			self.drops = get_sheep_drops(self.color)
			self.initial_color_set = true
		end
	end,

	on_rightclick = function(self, clicker)
		if self:follow_holding(clicker) and self:feed_tame(clicker, 4, true, false) then return end

		local item = clicker:get_wielded_item()
		-- Dye sheep
		if minetest.get_item_group(item:get_name(), "dye") == 1 and not self.gotten then
			local idef = item:get_definition()
			if not minetest.is_creative_enabled(clicker:get_player_name()) then
				item:take_item()
				clicker:set_wielded_item(item)
			end
			local cgroup = "unicolor_"..mcl_dyes.colors[idef._color].unicolor
			self.color = cgroup
			self.base_texture = sheep_texture(cgroup)
			self.object:set_properties({
				textures = self.base_texture,
			})
			self.drops = get_sheep_drops(cgroup)
			return
		end
		if self.child then return end
		if minetest.get_item_group(item:get_name(), "shears") > 0 and not self.gotten then
			self.gotten = true
			local pos = self.object:get_pos()
			minetest.sound_play("mcl_tools_shears_cut", {pos = pos}, true)
			pos.y = pos.y + 0.5
			self.color = self.color or "unicolor_white"
			minetest.add_item(pos, ItemStack(unicolor_to_wool(self.color).." "..math.random(1,3)))
			self.base_texture = gotten_texture
			self.object:set_properties({ textures = self.base_texture })
			if not minetest.is_creative_enabled(clicker:get_player_name()) then
				item:add_wear(mobs_mc.shears_wear)
				clicker:get_inventory():set_stack("main", clicker:get_wield_index(), item)
			end
			return
		end
	end,
	on_breed = function(parent1, parent2)
		local pos = parent1.object:get_pos()
		local child = mcl_mobs.spawn_child(pos, parent1.name)
		if child then
			local ent_c = child:get_luaentity()
			local color = { parent1.color, parent2.color }

			local dye1 = mcl_dyes.unicolor_to_dye(color[1])
			local dye2 = mcl_dyes.unicolor_to_dye(color[2])
			local output
			if dye1 and dye2 then
				output = minetest.get_craft_result({items = {dye1, dye2}, method="normal"})
			end
			if output and not output.item:is_empty() then
				local ndef = output.item:get_definition()
				local cgroup = "unicolor_"..mcl_dyes.colors[ndef._color].unicolor
				ent_c.color = cgroup
				ent_c.base_texture = sheep_texture(cgroup)
			else
				ent_c.color = color[math.random(2)]
			end

			ent_c.base_texture = sheep_texture(ent_c.color)
			ent_c.initial_color_set = true
			ent_c.tamed = true
			ent_c.owner = parent1.owner
			child:set_properties({textures = ent_c.base_texture})
			return false
		end
	end,
	_on_dispense = function(self, dropitem, pos, droppos, dropnode, dropdir)
		if minetest.get_item_group(dropitem:get_name(), "shears") > 0 then
			local pos = self.object:get_pos()
			self.base_texture = { "blank.png", "mobs_mc_sheep.png" }
			dropitem = self:use_shears({ "blank.png", "mobs_mc_sheep.png" }, dropitem)

			self.color = self.color or "unicolor_white"
			if self.drops[2] then
				minetest.add_item(pos, unicolor_to_wool(self.color) .. " " .. math.random(1, 3))
			end
			self.drops = {{ name = "mcl_mobitems:mutton", chance = 1, min = 1, max = 2 },}
			return dropitem
		end
		return mcl_mobs.mob_class._on_dispense(self, dropitem, pos, droppos, dropnode, dropdir)
	end
})

mcl_mobs.spawn_setup({
	name = "mobs_mc:sheep",
	type_of_spawning = "ground",
	dimension = "overworld",
	aoc = 9,
	min_height = mobs_mc.water_level + 3,
	biomes = {
		"flat",
		"IcePlainsSpikes",
		"ColdTaiga",
		"ColdTaiga_beach",
		"ColdTaiga_beach_water",
		"MegaTaiga",
		"MegaSpruceTaiga",
		"ExtremeHills",
		"ExtremeHills_beach",
		"ExtremeHillsM",
		"ExtremeHills+",
		"ExtremeHills+_snowtop",
		"StoneBeach",
		"Plains",
		"Plains_beach",
		"SunflowerPlains",
		"Taiga",
		"Taiga_beach",
		"Forest",
		"Forest_beach",
		"FlowerForest",
		"FlowerForest_beach",
		"BirchForest",
		"BirchForestM",
		"RoofedForest",
		"Savanna",
		"Savanna_beach",
		"SavannaM",
		"Jungle",
		"BambooJungle",
		"Jungle_shore",
		"JungleM",
		"JungleM_shore",
		"JungleEdge",
		"JungleEdgeM",
		"Swampland",
		"Swampland_shore",
		"CherryGrove",
	},
	chance = 120,
})

mcl_mobs.register_egg("mobs_mc:sheep", S("Sheep"), "#e7e7e7", "#ffb5b5", 0)
