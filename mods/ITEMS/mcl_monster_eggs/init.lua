-- Monster eggs!
-- Blocks which spawn silverfish when destroyed.

local S = minetest.get_translator(minetest.get_current_modname())

mcl_monster_eggs = {}

-- Template function for registering monster egg blocks
local function register_infested_block(name, description, overrides)

	local olddef = minetest.registered_nodes[name]
	local newdef = table.merge(olddef, {
		description = description,
		_tt_help = S("Hides a silverfish"),
		_doc_items_longdesc = S([[
			An infested block is a block from which a silverfish will pop out when it is broken.
			It looks identical to its normal counterpart.
		]]),
		groups = table.merge(olddef.groups, {spawns_silverfish = 1}),
		drop = "",
		_mcl_silk_touch_drop = {name},
		_mcl_hardness = olddef._mcl_hardness / 2,
		_mcl_blast_resistance = 0.75,
		after_dig_node = function (pos, _, _, digger)
			local itemstack = digger:get_wielded_item()
			local silk_touch = mcl_enchanting.has_enchantment(itemstack, "silk_touch")
			local is_book = itemstack:get_name() == "mcl_enchanting:book_enchanted"
			if not minetest.is_creative_enabled("") and (is_book and silk_touch)
			or not minetest.is_creative_enabled("") and (not is_book and not silk_touch) then
				minetest.add_entity(pos, "mobs_mc:silverfish")
			end
		end,
		on_blast = function (pos, _)
			minetest.remove_node(pos)
			if not minetest.is_creative_enabled("") then
				minetest.add_entity(pos, "mobs_mc:silverfish")
			end
		end
	})
	newdef._mcl_stonecutter_recipes = nil
	local base = name:gsub("^[_%w]*:", "")
	minetest.register_node(":mcl_monster_eggs:monster_egg_"..base, table.merge(newdef, overrides))
end

mcl_monster_eggs.register_infested_block = register_infested_block

-- Register all the monster egg blocks
register_infested_block("mcl_core:stone", S("Infested Stone"))
register_infested_block("mcl_core:cobble", S("Infested Cobblestone"))
register_infested_block("mcl_core:stonebrick", S("Infested Stone Bricks"))
register_infested_block("mcl_core:stonebrickcracked", S("Infested Cracked Stone Bricks"))
register_infested_block("mcl_core:stonebrickmossy", S("Infested Mossy Stone Bricks"))
register_infested_block("mcl_core:stonebrickcarved", S("Infested Chiseled Stone Bricks"))
