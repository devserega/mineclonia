local modname = minetest.get_current_modname()
local modpath = minetest.get_modpath(modname)
local S = minetest.get_translator(modname)
local PARTICLE_DISTANCE = 25

mcl_trees.register_wood("cherry_blossom",{
	readable_name = S("Cherry"),
	sign_color="#F29889",
	tree_schems= {
		{file=modpath.."/schematics/mcl_cherry_blossom_tree_1.mts"},
		{file=modpath.."/schematics/mcl_cherry_blossom_tree_2.mts"},
		{file=modpath.."/schematics/mcl_cherry_blossom_tree_3.mts"},
	},
	tree = { tiles = {"mcl_cherry_blossom_log_top.png", "mcl_cherry_blossom_log_top.png","mcl_cherry_blossom_log.png"} },
	wood = { tiles = {"mcl_cherry_blossom_planks.png"}},
	sapling = {
		tiles = {"mcl_cherry_blossom_sapling.png"},
		inventory_image = "mcl_cherry_blossom_sapling.png",
		wield_image = "mcl_cherry_blossom_sapling.png",
		_after_grow = mcl_trees.sapling_add_bee_nest,
	},
	potted_sapling = {
		image = "mcl_cherry_blossom_sapling.png",
	},
	leaves = {
		tiles = { "mcl_cherry_blossom_leaves.png" },
		paramtype2 = "none",
		palette = "",
	},
	stripped = {
		tiles = {"mcl_cherry_blossom_log_top_stripped.png", "mcl_cherry_blossom_log_top_stripped.png","mcl_cherry_blossom_log_stripped.png"}
	},
	stripped_bark = {
		tiles = {"mcl_cherry_blossom_log_stripped.png"}
	},
	fence = { tiles = {"mcl_cherry_blossom_planks.png"},},
	fence_gate = { tiles = {"mcl_cherry_blossom_planks.png"},},
	door = {
		inventory_image = "mcl_cherry_blossom_door_inv.png",
		tiles_bottom = {"mcl_cherry_blossom_door_bottom.png", "mcl_cherry_blossom_door_bottom_side.png"},
		tiles_top = {"mcl_cherry_blossom_door_top.png", "mcl_cherry_blossom_door_top_side.png"},
	},
	trapdoor = {
		tile_front = "mcl_cherry_blossom_trapdoor.png",
		tile_side = "mcl_cherry_blossom_trapdoor_side.png",
		wield_image = "mcl_cherry_blossom_trapdoor.png",
	},
})

minetest.register_node("mcl_cherry_blossom:pink_petals",{
	description = S("Pink Petals"),
	doc_items_longdesc = S("Pink Petals are ground decoration of cherry grove biomes"),
	doc_items_hidden = false,
	paramtype = "light",
	paramtype2 = "facedir",
	walkable = false,
	sunlight_propagates = true,
	floodable = true,
	pointable = true,
	drawtype = "nodebox",
	node_box = {type = "fixed", fixed = {-1/2, -1/2, -1/2, 1/2, -7.9/16, 1/2}},
	collision_box = {type = "fixed", fixed = {-1/2, -1/2, -1/2, 1/2, -7.9/16, 1/2}},
	groups = {
		shearsy=1,
		handy=1,
		flammable=3,
		attached_node=1,
		dig_by_piston=1,
		compostability = 30,
		deco_block=1
		--not_in_creative_inventory=1,
	},
	use_texture_alpha = "clip",
	sounds = mcl_sounds.node_sound_leaves_defaults(),
	tiles = {
		"mcl_cherry_blossom_pink_petals.png",
		"mcl_cherry_blossom_pink_petals.png^[transformFY", -- mirror
		"blank.png" -- empty
	},
	inventory_image = "mcl_cherry_blossom_pink_petals_inv.png",
	_mcl_hardness = 0,
	_mcl_blast_resistance = 0,
	_on_bone_meal = function(_, _, _ , pos, n)
		minetest.add_item(pos,n.name)
	end
})

local cherry_particlespawner = {
	texture = "mcl_cherry_blossom_particle_1.png",
	texpool = {},
	amount = 4,
	time = 25,
	minvel = vector.zero(),
	maxvel = vector.zero(),
	minacc = vector.new(-0.2, -0.4, -0.2),
	maxacc = vector.new(0.2, -0.9, 0.2),
	minexptime = 1.5,
	maxexptime = 4.5,
	minsize = 1.0,
	maxsize= 1.25,
	glow = 1,
	collisiondetection = true,
	collision_removal = true,
}
for i=1,3 do
	table.insert(cherry_particlespawner.texpool, {
		name = "mcl_cherry_blossom_particle_"..i..".png",
		animation={type="vertical_frames", aspect_w=3, aspect_h=3, length=0.78},
	})
end

minetest.register_abm({
	label = "Cherry Blossom Particles",
	nodenames = {"mcl_trees:leaves_cherry_blossom"},
	interval = 25,
	chance = 2,
	action = function(pos)
		if minetest.get_node(vector.offset(pos, 0, -1, 0)).name ~= "air" then return end
		local pr = PseudoRandom(math.ceil(os.time() / 60 / 10)) -- make particles change direction every 10 minutes
		local v = vector.new(pr:next(-2, 2)/10, 0, pr:next(-2, 2)/10)
		v.y = pr:next(-9, -4) / 10
		for pl in mcl_util.connected_players(pos, PARTICLE_DISTANCE) do
			minetest.add_particlespawner(table.merge(cherry_particlespawner, {
				minacc = v,
				maxacc = v,
				minpos = vector.offset(pos, -0.25, -0.5, -0.25),
				maxpos = vector.offset(pos, 0.25, -0.5, 0.25),
				playername = pl:get_player_name(),
			}))
		end
	end
})
