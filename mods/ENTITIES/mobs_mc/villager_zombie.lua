--MCmobs v0.4
--maikerumine
--made for MC like Survival game
--License for code WTFPL and otherwise stated in readmes

local S = minetest.get_translator("mobs_mc")

--###################
--################### ZOMBIE VILLAGER
--###################

--[[
local professions = {
	farmer = "mobs_mc_villager_farmer.png",
	fisherman = "mobs_mc_villager_farmer.png",
	fletcher = "mobs_mc_villager_farmer.png",
	shepherd = "mobs_mc_villager_farmer.png",
	librarian = "mobs_mc_villager_librarian.png",
	cartographer = "mobs_mc_villager_librarian.png",
	armorer = "mobs_mc_villager_smith.png",
	leatherworker = "mobs_mc_villager_butcher.png",
	butcher = "mobs_mc_villager_butcher.png",
	weapon_smith = "mobs_mc_villager_smith.png",
	tool_smith = "mobs_mc_villager_smith.png",
	cleric = "mobs_mc_villager_priest.png",
	nitwit = "mobs_mc_villager.png",
}
--]]

mcl_mobs.register_mob("mobs_mc:villager_zombie", {
	description = S("Zombie Villager"),
	type = "monster",
	spawn_class = "hostile",
	spawn_in_group = 1,
	hp_min = 20,
	hp_max = 20,
	xp_min = 5,
	xp_max = 5,
	breath_max = -1,
	armor = {undead = 90, fleshy = 90},
	collisionbox = {-0.3, -0.01, -0.3, 0.3, 1.94, 0.3},
	visual = "mesh",
	mesh = "mobs_mc_villager_zombie.b3d",
	head_swivel = "Head_Control",
	bone_eye_height = 2.35,
	curiosity = 2,
	textures = {
		{"mobs_mc_zombie_butcher.png"},
		{"mobs_mc_zombie_farmer.png"},
		{"mobs_mc_zombie_librarian.png"},
		{"mobs_mc_zombie_priest.png"},
		{"mobs_mc_zombie_smith.png"},
		{"mobs_mc_zombie_villager.png"},
	},
	visual_size = {x=2.75, y=2.75},
	makes_footstep_sound = true,
	damage = 3,
	reach = 2,
	walk_velocity = 0.8,
	run_velocity = 1.2, -- same as zombie
	attack_type = "dogfight",
	group_attack = true,
	drops = {
		{name = "mcl_mobitems:rotten_flesh",
		chance = 1,
		min = 0,
		max = 2,
		looting = "common",},
		{name = "mcl_core:iron_ingot",
		chance = 120, -- 2.5% / 3
		min = 1,
		max = 1,
		looting = "rare",
		looting_factor = 0.01 / 3,},
		{name = "mcl_farming:carrot_item",
		chance = 120, -- 2.5% / 3
		min = 1,
		max = 1,
		looting = "rare",
		looting_factor = 0.01 / 3,},
		{name = "mcl_farming:potato_item",
		chance = 120, -- 2.5% / 3
		min = 1,
		max = 1,
		looting = "rare",
		looting_factor = 0.01 / 3,},
	},
	sounds = {
		random = "mobs_mc_zombie_growl",
		war_cry = "mobs_mc_zombie_growl",
		death = "mobs_mc_zombie_death",
		damage = "mobs_mc_zombie_hurt",
	},
	sound_params = {
		max_hear_distance = 16,
		gain = 0.5
	},
	animation = {
		stand_start = 20, stand_end = 40,
		walk_start = 0, walk_end = 20, walk_speed = 20,
		run_start = 0, run_end = 20, run_speed = 20,
	},
	on_rightclick = function(self, clicker)
		if not self._curing and clicker and clicker:is_player() then
			local wielditem = clicker:get_wielded_item()
			if wielditem:get_name() == "mcl_core:apple_gold"
			    and mcl_potions.has_effect (self.object,
							"weakness") then
				wielditem:take_item()
				clicker:set_wielded_item(wielditem)
				self._curing = math.random(3 * 60, 5 * 60)
				self.shaking = true
				self.persistent = true
			end
		end
	end,
	do_custom = function(self, dtime)
		if self._curing then
			self._curing = self._curing - dtime
			local obj = self.object
			if self._curing <= 0 then
				local villager_obj = mcl_util.replace_mob(obj, "mobs_mc:villager")
				if villager_obj then
					self._curing = nil
					local villager = villager_obj:get_luaentity()
					villager._profession = "unemployed"
					-- Give this villager 10 seconds of nausea.
					mcl_potions.give_effect ("nausea", villager_obj, 1, 10, false)
					return false
				end
			end
		end
	end,
	on_mob_replace = function(self, new_ent)
		if new_ent.name == "mobs_mc:villager" then
			new_ent._profession = self._profession
			new_ent._id = self._id
			new_ent._jobsite = self._jobsite
			new_ent._bed = self._bed
			new_ent._cured_zombie = true
			new_ent:set_textures()
		end
	end,
	sunlight_damage = 2,
	ignited_by_sunlight = true,
	floats = 0,
	view_range = 16,
	fear_height = 4,
	harmed_by_heal = true,
	attack_npcs = true,
})

mcl_mobs.spawn_setup({
	name = "mobs_mc:villager_zombie",
	type_of_spawning = "ground",
	dimension = "overworld",
	aoc = 9,
	biomes_except = {
		"MushroomIslandShore",
		"MushroomIsland",
	},
	chance = 50,
})

-- spawn eggs
mcl_mobs.register_egg("mobs_mc:villager_zombie", S("Zombie Villager"), "#563d33", "#799c66", 0)
