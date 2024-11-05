local modname = minetest.get_current_modname()
local S = minetest.get_translator(modname)
local spawn_interval = 20 * 60
local max_lifetime = 60 * 60
local current_chance = 25
local wandering_trader = table.copy(mobs_mc.villager_mob)

local function E(f, t)
	return { "mcl_core:emerald", f or 1, t or f or 1 }
end

local function get_random_color()
	local _, color = table.random_element(mcl_dyes.colors)
	return color
end

local function get_random_dye()
	return "mcl_dyes:"..get_random_color()
end

local function get_random_tree()
	local _, wood = table.random_element(mcl_trees.woods)
	return "mcl_trees:tree_"..wood
end

local function get_random_sapling()
	local r = {}
	for k, _ in pairs(mcl_trees.woods) do
		local sap = "mcl_trees:sapling_"..k
		local def = minetest.registered_nodes[sap]
		if def and not def._unobtainable then
			table.insert(r, sap)
		end
	end
	return table.random_element(r)
end

local function get_random_flower()
	local _, flower = table.random_element(mcl_flowers.registered_simple_flowers)
	return flower
end
mobs_mc.wandering_trader = {}
mobs_mc.wandering_trader.trades_purchasing_table = {
	{ { "mcl_potions:water", 1, 1, }, E(), 1, 0 },
	{ { "mcl_buckets:bucket_water", 1, 1, }, E(2), 1, 0 },
	{ { "mcl_mobitems:milk_bucket", 1, 1, }, E(2), 1, 0 },
	{ { "mcl_potions:fermented_spider_eye", 1, 1, }, E(3), 1, 0 },
	{ { "mcl_farming:potato_item_baked", 1, 1, }, E(1), 1, 0 },
	{ { "mcl_farming:hay_block", 1, 1, }, E(1), 1, 0 },
}

mobs_mc.wandering_trader.trades_special_table = {
	{ E(), { "mcl_core:packed_ice", 1, 1, }, 6, 0 },
	{ E(), { "mcl_mobitems:gunpowder", 4, 4, }, 2, 0 },
	{ E(), { get_random_tree, 8, 8, }, 6, 0 },
	{ E(3), { "mcl_core:podzol", 3, 3, }, 6, 0 },
	{ E(5), { "mcl_core:ice", 1, 1, }, 6, 0 },
	{ E(6), { "mcl_potions:invisibility", 1, 1, }, 1, 0 },
	{ E(6, 20), { "mcl_tools:pick_iron_enchanted", 1, 1 } },
}

mobs_mc.wandering_trader.trades_ordinary_table = {
	{ E(), { "mcl_flowers:fern", 1, 1, }, 12, 0 },
	{ E(), { "mcl_core:reeds", 1, 1, }, 8, 0 },
	{ E(), { "mcl_farming:pumpkin", 1, 1, }, 4, 0 },
	{ E(), { get_random_flower, 1, 1, }, 12, 0 },

	{ E(), { "mcl_farming:wheat_seeds", 1, 1, }, 12, 0 },
	{ E(), { "mcl_farming:beetroot_seeds", 1, 1, }, 12, 0 },
	{ E(), { "mcl_farming:pumpkin_seeds", 1, 1, }, 12, 0 },
	{ E(), { "mcl_farming:melon_seeds", 1, 1, }, 12, 0 },
	{ E(), { get_random_dye, 1, 1, }, 12, 0 },
	{ E(), { "mcl_core:vine", 3, 3, }, 4, 0 },
	{ E(), { "mcl_flowers:waterlily", 3, 3, }, 2, 0 },
	{ E(), { "mcl_core:sand", 3, 3, }, 8, 0 },
	{ E(), { "mcl_core:redsand", 3, 3, }, 6, 0 },
	--{ E(), { "TODO: small_dripleaf", 3, 3, }, 5, 0 },
	{ E(), { "mcl_mushrooms:mushroom_brown", 3, 3, }, 4, 0 },
	{ E(), { "mcl_mushrooms:mushroom_red", 3, 3, }, 4, 0 },
	--{ E(), { "TODO:pointed_dripstone", 2, 5, }, 5, 0 },
	{ E(), { "mcl_lush_caves:rooted_dirt", 2, 2, }, 5, 0 },
	{ E(), { "mcl_lush_caves:moss", 2, 2, }, 5, 0 },
	{ E(2), { "mcl_ocean:sea_pickle_1_dead_brain_coral_block", 1, 1, }, 5, 0 },
	{ E(2), { "mcl_nether:glowstone", 1, 5, }, 5, 0 },
	{ E(3), { "mcl_buckets:bucket_tropical_fish", 1, 1, }, 4, 0 },
	--{ E(3), { "TODO: mcl_buckets:bucket_pufferfish", 1, 5, }, 4, 0 },
	{ E(3), { "mcl_ocean:kelp", 1, 1, }, 12, 0 },
	{ E(3), { "mcl_core:cactus", 1, 1, }, 8, 0 },
	{ E(3), { "mcl_ocean:brain_coral_block", 1, 1, }, 8, 0 },
	{ E(3), { "mcl_ocean:tube_coral_block", 1, 1, }, 8, 0 },
	{ E(3), { "mcl_ocean:bubble_coral_block", 1, 1, }, 8, 0 },
	{ E(3), { "mcl_ocean:fire_coral_block", 1, 1, }, 8, 0 },
	{ E(3), { "mcl_ocean:horn_coral_block", 1, 1, }, 8, 0 },
	{ E(4), { "mcl_mobitems:slimeball", 1, 1, }, 5, 0 },
	{ E(5), { get_random_sapling, 8, 8, }, 8, 0 },
	{ E(5), { "mcl_mobitems:nautilus_shell", 1, 1, }, 5, 0 },
}


local function get_wandering_trades()
	local purch = table.copy(mobs_mc.wandering_trader.trades_purchasing_table)
	local speci = table.copy(mobs_mc.wandering_trader.trades_special_table)
	local ordin = table.copy(mobs_mc.wandering_trader.trades_ordinary_table)
	local t = {}
	for _ = 1, 2 do
		table.insert(t, table.remove(purch, math.random(#purch)))
		table.insert(t, table.remove(speci, math.random(#speci)))
	end
	for _ = 1, 5 do
		table.insert(t, table.remove(ordin, math.random(#ordin)))
	end
	return { t }
end

function wandering_trader:do_custom()
	if os.time() - self._spawn_time > max_lifetime then
		self:safe_remove()
	end
end

function wandering_trader:on_spawn()
	if self._id then
		self:set_textures()
		for _, lid in pairs(self._llamas) do
			local e = mcl_util.get_luaentity_by_id(lid)
			if e then
				e.following = self.object
			end
		end
		return
	end
	self._id = minetest.sha1(minetest.get_gametime()..minetest.pos_to_string(self.object:get_pos())..tostring(math.random()))
	self._llamas = {}
	self._spawn_time = os.time()
	self:set_textures()
end

function wandering_trader:on_rightclick(clicker)
	self._profession = "wandering_trader"
	self:init_trader_vars()
	local name = clicker:get_player_name()
	self._trading_players[name] = true

	if self._trade_xp == nil or self._trades == nil then
		self._max_trade_tier = 5
		self._trade_xp = 255
		self:init_trades(get_wandering_trades())
	end
	self:update_max_tradenum()
	if self._trades == false then
		return
	end

	local inv = minetest.get_inventory({type="detached", name="mobs_mc:trade_"..name})
	if not inv then
		return
	end

	self:show_trade_formspec(name)

	local selfpos = self.object:get_pos()
	local clickerpos = clicker:get_pos()
	local dir = vector.direction(selfpos, clickerpos)
	self.object:set_yaw(minetest.dir_to_yaw(dir))
	self:stand_still()
end

table.update(wandering_trader, {
	description = S("Wandering Trader"),
	textures = {
		"mobs_mc_villager.png",
		"mobs_mc_villager.png", --hat
	},
	_profession = "wandering_trader",
	_notiers = true,
})

mcl_mobs.register_mob("mobs_mc:wandering_trader", wandering_trader)

-- spawn eggs
mcl_mobs.register_egg("mobs_mc:wandering_trader", S("Wandering Trader"), "#1E90FF", "#bc8b72", 0)

function mobs_mc.spawn_trader_llama(pos, wt)
	local o = minetest.add_entity(pos, "mobs_mc:llama")
	if o then
		local ot = o:get_properties().textures
		local l = o:get_luaentity()
		local wl = wt:get_luaentity()
		l._id = minetest.sha1(minetest.get_gametime()..minetest.pos_to_string(o:get_pos())..tostring(math.random()))
		table.insert(wl._llamas, l._id)
		local tx = {"blank.png", "mobs_mc_llama_decor_wandering_trader.png", ot[3]}
		l.base_texture = tx
		l.following = wt
		l._follow_trader = wt._id
		l.can_despawn = true
		o:set_properties({
			textures = tx,
		})
	end
end

function mobs_mc.spawn_wandering_trader(pos)
	local trader = minetest.add_entity(vector.offset(pos, 0, 1, 0), "mobs_mc:wandering_trader")
	if trader then
		local nn = minetest.find_nodes_in_area_under_air(vector.offset(pos, -2, -2 , -2), vector.offset(pos, 2, 2, 2), {"group:opaque"})
		if nn and #nn > 0 then
			for i=1,math.random(2) do
				mobs_mc.spawn_trader_llama(vector.offset((nn[i] or nn[i - 1]), 0, 1, 0), trader)
			end
		end
		return true
	end
end

local function get_points_on_circle(pos,r,n)
	local rt = {}
	for i=1, n do
		table.insert(rt,vector.offset(pos,r * math.cos(((i-1)/n) * (2*math.pi)),0,  r* math.sin(((i-1)/n) * (2*math.pi)) ))
	end
	return rt
end

local function attempt_trader_spawn(manual)
	local exists = false
	local spawned = false
	for _, v in pairs(minetest.luaentities) do
		if v.name == "mobs_mc:wandering_trader" then
			exists = true
		end
	end
	if not exists and math.random(100) < current_chance then
		current_chance = 25
		local ow_players = {}
		for pl in mcl_util.connected_players() do
			if mcl_worlds.pos_to_dimension(pl:get_pos()) == "overworld" then
				table.insert(ow_players, pl)
			end
		end
		if #ow_players > 0 then
			table.shuffle(ow_players)
			local pl = ow_players[1]
			local poss = get_points_on_circle(pl:get_pos(), 50, 24)
			table.shuffle(poss)
			for _, sp in pairs(poss) do
				local nn = minetest.find_nodes_in_area_under_air(vector.offset(sp, -5, -5 , -5), vector.offset(sp, 5, 5, 5), {"group:solid"})
				if nn and #nn > 0 then
					if mobs_mc.spawn_wandering_trader(nn[1]) then
						break
					end
				end
			end
			spawned = true
		end
	elseif not exists then
		current_chance = math.min(75, current_chance + 25)
	end

	if not manual then
		if mobs_mc.wandering_trader_spawn_job then
			mobs_mc.wandering_trader_spawn_job:cancel()
			--prevent multiple spawn jobs from being run
		end
		mobs_mc.wandering_trader_spawn_job = minetest.after(spawn_interval, attempt_trader_spawn)
	end
	return spawned
end

if minetest.settings:get_bool("mobs_spawn", true) then
	mobs_mc.wandering_trader_spawn_job = minetest.after(spawn_interval, attempt_trader_spawn)
end

minetest.register_chatcommand("spawn_wandering_trader", {
	privs = { debug = true, },
	func = function(_, _)
		minetest.log("current wandering trader spawn chance: "..tostring(current_chance))
		if attempt_trader_spawn(true) then
			minetest.log("wandering trader spawned")
		end
	end,
})
