-- v1.1

--###################
--################### SQUID
--###################

local S = minetest.get_translator("mobs_mc")

local base_psdef = {
	amount = 8,
	time=0,
	minpos = vector.new(-1,-1,-1),
	maxpos = vector.new(1,1,1),
	minvel = vector.new(-0.25,-0.25,-0.25),
	maxvel = vector.new(0.25,0.25,0.25),
	minacc = vector.new(-0.5,-0.5,-0.5),
	maxacc = vector.new(0.5,0.5,0.5),
	minexptime = 1,
	maxexptime = 2,
	minsize = 0.8,
	maxsize= 1.5,
	glow = 5,
	collisiondetection = true,
	collision_removal = true,
}

local psdefs = {}

for i=1,4 do
	local p = table.copy(base_psdef)
	p.texture = "extra_mobs_glow_squid_glint"..i..".png"
	table.insert(psdefs,p)
end

local squid_defs = {
	type = "animal",
	spawn_class = "water",
    can_despawn = true,
    passive = true,
    hp_min = 10,
    hp_max = 10,
    xp_min = 1,
    xp_max = 3,
    armor = 100,
	spawn_in_group_min = 2,
    spawn_in_group = 4,
	-- FIXME: If the squid is near the floor, it turns black
	collisionbox = { -0.4, 0.0, -0.4, 0.4, 0.9, 0.4 },
	visual = "mesh",
    mesh = "mobs_mc_squid.b3d",
	sounds = {
		damage = {name="mobs_mc_squid_hurt", gain=0.3},
		death = {name="mobs_mc_squid_death", gain=0.4},
		flop = "mobs_mc_squid_flop",
		-- TODO: sounds: random
		distance = 16,
    },
	animation = {
		stand_start = 1,
		stand_end = 60,
		walk_start = 1,
		walk_end = 60,
		run_start = 1,
		run_end = 60,
	},
	visual_size = { x = 3, y = 3 },
	makes_footstep_sound = false,
	swims = true,
	breathes_in_water = true,
	jump = false,
	view_range = 16,
	runaway = true,
	fear_height = 4,
	fly = true,
	fly_in = { "mcl_core:water_source", "mclx_core:river_water_source" },
}

mcl_mobs.register_mob("mobs_mc:squid", table.merge(squid_defs, {
	description = S("Squid"),
	textures = {
        { "mobs_mc_squid.png" }
    },
    drops = {
		{
			name = "mcl_mobitems:ink_sac",
			chance = 1,
			min = 1,
			max = 3,
			looting = "common"
		}
	}
}))

mcl_mobs.register_mob("mobs_mc:glow_squid", table.merge(squid_defs, {
	description = S("Glow Squid"),
	textures = {
		{ "extra_mobs_glow_squid.png" }
	},
	drops = {
		{
			name = "mcl_mobitems:glow_ink_sac",
			chance = 1,
			min = 1,
			max = 3,
			looting = "common"
		}
	},
	glow = minetest.LIGHT_MAX,
	particlespawners = psdefs,
}))

-- TODO: Behaviour: squirt

-- Spawn near the water surface
mcl_mobs.spawn_setup({
	name = "mobs_mc:squid",
	type_of_spawning = "water",
	dimension = "overworld",
	min_height = mobs_mc.water_level - 16,
	max_height = mobs_mc.water_level + 1,
	min_light = 0,
	max_light = minetest.LIGHT_MAX + 1,
	aoc = 7,
	chance = 80,
})

-- spawn eggs
mcl_mobs.register_egg("mobs_mc:squid", S("Squid"), "#223b4d", "#708999", 0)

-- spawning
mcl_mobs.spawn_setup({
	name = "mobs_mc:glow_squid",
	type_of_spawning = "water",
	dimension = "overworld",
	min_height = mobs_mc.water_level - 125,
	max_height = mobs_mc.water_level - 32 + 1,
	min_light = 0,
	max_light = 0,
	aoc = 3,
	chance = 100,
})

-- spawn egg
mcl_mobs.register_egg("mobs_mc:glow_squid", S("Glow Squid"), "#095757", "#87f6c0", 0)
