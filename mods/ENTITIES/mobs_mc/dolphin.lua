local S = minetest.get_translator(minetest.get_current_modname())

local food_items = {
	"mcl_fishing:fish_raw",
	"mcl_fishing:salmon_raw",
	"mcl_fishing:clownfish_raw",
}

mcl_mobs.register_mob("mobs_mc:dolphin", {
	description = S("Dolphin"),
	type = "animal",
	spawn_class = "water",
	can_despawn = true,
	passive = true,
	hp_min = 10,
	hp_max = 10,
	xp_min = 1,
	xp_max = 3,
	armor = 100,
	walk_chance = 100,
	breath_max = 120,
	rotate = 180,
	spawn_in_group_min = 3,
	spawn_in_group = 5,
	tilt_swim = true,
	collisionbox = {-0.3, 0.0, -0.3, 0.3, 0.79, 0.3},
	visual = "mesh",
	mesh = "extra_mobs_dolphin.b3d",
	textures = {
		{"extra_mobs_dolphin.png"}
	},
	sounds = {
	},
	animation = {
		stand_start = 0, stand_end = 15, stand_speed = 20,
		walk_start = 0, walk_end = 15, walk_speed = 60,
		run_start = 0, run_end = 15, run_speed = 60,
		},
		drops = {
			{name = "mcl_fishing:fish_raw",
			chance = 1,
			min = 0,
			max = 1,},
	},
	visual_size = {x=3, y=3},
	makes_footstep_sound = false,
	swims = true,
	fly = true,
	fly_in = { "mcl_core:water_source", "mclx_core:river_water_source" },
	_player_check_time = 0,
	follow_holding = function (_) return true end,
	follow_velocity = 4.8,
	do_custom = function (self, dtime)
	local pos = self.object:get_pos ()
	local closest_player, cur_dist

	if not self:check_timer ("player_check", 0.3) then
		return
	end

	-- Cling to the current player if still swimming.
	if self.following and self:object_in_follow_range (self.following)
		and mcl_player.players[self.following].is_swimming then
		closest_player = self.following
	else
		for object in minetest.objects_inside_radius(pos, 15) do
			if object:is_player ()
				and mcl_player.players[object].is_swimming then
				local distance = vector.distance (pos, object:get_pos ())
				if not closest_player or cur_dist > distance then
				closest_player = object
				cur_dist = distance
				end
			end
		end
	end

	if closest_player then
		self.following = closest_player
		mcl_potions.give_effect ("dolphin_grace", closest_player, 1, 5)
	else
		self.following = nil
	end
	end,
	breathes_in_water = true,
	jump = false,
	view_range = 16,
	fear_height = 4,
	walk_velocity = 1,
	run_velocity = 1,
	swim_velocity = 2,
	group_attack = { "mobs_mc:dolphin" },
	reach = 2,
	damage = 2.5,
	attack_type = "dogfight",
	on_rightclick = function(self, clicker)
		local wi = clicker:get_wielded_item()
		if table.indexof(food_items, wi:get_name()) ~= -1 then
			if not minetest.is_creative_enabled(clicker:get_player_name()) then
				wi:take_item()
				clicker:set_wielded_item(wi)
			end
			local p = self.object:get_pos()
			local p1 = vector.offset(p, -64, -16, -64)
			local p2 = vector.offset(p, 64, math.min(1, p.y+16), 64)
			local chests = minetest.find_nodes_in_area(p1, p2, {"mcl_chests:chest_small"})
			if chests and #chests > 0 then
				table.sort(chests, function(a, b) return vector.distance(p, a) < vector.distance(p, b) end)
				self:go_to_pos(chests[1])
			end
		end
	end,
})

mcl_mobs.spawn_setup({
	name = "mobs_mc:dolphin",
	type_of_spawning = "water",
	dimension = "overworld",
	min_height = mobs_mc.water_level - 16,
	max_height = mobs_mc.water_level + 1,
	min_light = 0,
	max_light = minetest.LIGHT_MAX + 1,
	aoc = 7,
	chance = 70,
	biomes = {
		"Mesa",
		"FlowerForest",
		"Swampland",
		"Taiga",
		"ExtremeHills",
		"Jungle",
		"BambooJungle",
		"Savanna",
		"BirchForest",
		"MegaSpruceTaiga",
		"MegaTaiga",
		"ExtremeHills+",
		"Forest",
		"Plains",
		"Desert",
		"ColdTaiga",
		"MushroomIsland",
		"IcePlainsSpikes",
		"SunflowerPlains",
		"IcePlains",
		"RoofedForest",
		"ExtremeHills+_snowtop",
		"MesaPlateauFM_grasstop",
		"JungleEdgeM",
		"ExtremeHillsM",
		"JungleM",
		"BirchForestM",
		"MesaPlateauF",
		"MesaPlateauFM",
		"MesaPlateauF_grasstop",
		"MesaBryce",
		"JungleEdge",
		"SavannaM",
		"FlowerForest_beach",
		"Forest_beach",
		"StoneBeach",
		"Taiga_beach",
		"Savanna_beach",
		"Plains_beach",
		"ExtremeHills_beach",
		"ColdTaiga_beach",
		"Swampland_shore",
		"MushroomIslandShore",
		"JungleM_shore",
		"Jungle_shore",
		"MesaPlateauFM_sandlevel",
		"MesaPlateauF_sandlevel",
		"MesaBryce_sandlevel",
		"Mesa_sandlevel",
		"RoofedForest_ocean",
		"JungleEdgeM_ocean",
		"BirchForestM_ocean",
		"BirchForest_ocean",
		"IcePlains_deep_ocean",
		"Jungle_deep_ocean",
		"Savanna_ocean",
		"MesaPlateauF_ocean",
		"ExtremeHillsM_deep_ocean",
		"Savanna_deep_ocean",
		"SunflowerPlains_ocean",
		"Swampland_deep_ocean",
		"Swampland_ocean",
		"MegaSpruceTaiga_deep_ocean",
		"ExtremeHillsM_ocean",
		"JungleEdgeM_deep_ocean",
		"SunflowerPlains_deep_ocean",
		"BirchForest_deep_ocean",
		"IcePlainsSpikes_ocean",
		"Mesa_ocean",
		"StoneBeach_ocean",
		"Plains_deep_ocean",
		"JungleEdge_deep_ocean",
		"SavannaM_deep_ocean",
		"Desert_deep_ocean",
		"Mesa_deep_ocean",
		"ColdTaiga_deep_ocean",
		"Plains_ocean",
		"MesaPlateauFM_ocean",
		"Forest_deep_ocean",
		"JungleM_deep_ocean",
		"FlowerForest_deep_ocean",
		"MushroomIsland_ocean",
		"MegaTaiga_ocean",
		"StoneBeach_deep_ocean",
		"IcePlainsSpikes_deep_ocean",
		"ColdTaiga_ocean",
		"SavannaM_ocean",
		"MesaPlateauF_deep_ocean",
		"MesaBryce_deep_ocean",
		"ExtremeHills+_deep_ocean",
		"ExtremeHills_ocean",
		"MushroomIsland_deep_ocean",
		"Forest_ocean",
		"MegaTaiga_deep_ocean",
		"JungleEdge_ocean",
		"MesaBryce_ocean",
		"MegaSpruceTaiga_ocean",
		"ExtremeHills+_ocean",
		"Jungle_ocean",
		"RoofedForest_deep_ocean",
		"IcePlains_ocean",
		"FlowerForest_ocean",
		"ExtremeHills_deep_ocean",
		"MesaPlateauFM_deep_ocean",
		"Desert_ocean",
		"Taiga_ocean",
		"BirchForestM_deep_ocean",
		"Taiga_deep_ocean",
		"JungleM_ocean",
		"FlowerForest_underground",
		"JungleEdge_underground",
		"StoneBeach_underground",
		"MesaBryce_underground",
		"Mesa_underground",
		"RoofedForest_underground",
		"Jungle_underground",
		"Swampland_underground",
		"MushroomIsland_underground",
		"BirchForest_underground",
		"Plains_underground",
		"MesaPlateauF_underground",
		"ExtremeHills_underground",
		"MegaSpruceTaiga_underground",
		"BirchForestM_underground",
		"SavannaM_underground",
		"MesaPlateauFM_underground",
		"Desert_underground",
		"Savanna_underground",
		"Forest_underground",
		"SunflowerPlains_underground",
		"ColdTaiga_underground",
		"IcePlains_underground",
		"IcePlainsSpikes_underground",
		"MegaTaiga_underground",
		"Taiga_underground",
		"ExtremeHills+_underground",
		"JungleM_underground",
		"ExtremeHillsM_underground",
		"JungleEdgeM_underground",
	},
})

mcl_mobs.register_egg("mobs_mc:dolphin", S("Dolphin"), "#223b4d", "#f9f9f9", 0)
