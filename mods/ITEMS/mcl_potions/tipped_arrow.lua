local S = minetest.get_translator(minetest.get_current_modname())

local arrow_def = minetest.registered_items["mcl_bows:arrow"]
local arrow_longdesc = arrow_def._doc_items_longdesc or ""
local arrow_tt = arrow_def._tt_help or ""

local function arrow_image(colorstring, opacity)
	if not opacity then
		opacity = 127
	end
	return {"mcl_bows_arrow.png^(mcl_bows_arrow_overlay.png^[colorize:"..colorstring..":"..tostring(opacity)..")"}
end

function mcl_potions.register_arrow(name, desc, color, def)
	local tt = def._tt or ""
	local groups = {ammo=1, ammo_bow=1, brewitem=1, _mcl_potion=1}
	if def.nocreative then groups.not_in_creative_inventory = 1 end
	minetest.register_craftitem("mcl_potions:"..name.."_arrow", table.merge (arrow_def, {
		description = desc,
		_tt_help = arrow_tt .. "\n" .. tt,
		_dynamic_tt = def._dynamic_tt,
		_mcl_filter_description = mcl_potions.filter_potion_description,
		_doc_items_longdesc = arrow_longdesc .. "\n" ..
			S("This particular arrow is tipped and will give an effect when it hits a player or mob.") .. "\n" ..
			(def.longdesc or ""),
		_effect_list = def._effect_list,
		uses_level = def.uses_level,
		has_potent = def.has_potent,
		has_plus = def.has_plus,
		_default_potent_level = def._default_potent_level,
		_default_extend_level = def._default_extend_level,
		inventory_image = "mcl_bows_arrow_inv.png^(mcl_potions_arrow_inv.png^[colorize:"..color..":100)",
		groups = groups,
		_get_all_virtual_items = def._get_all_virtual_items
	}))

	local ARROW_ENTITY = table.copy(minetest.registered_entities["mcl_bows:arrow_entity"])
	ARROW_ENTITY.initial_properties.textures = arrow_image (color, 100)
	ARROW_ENTITY._itemstring = "mcl_potions:"..name.."_arrow"

	function ARROW_ENTITY._extra_hit_func (obj)
		local potency, plus = 0, 0
		if def._effect_list then
		local ef_level
		local dur

		for name, details in pairs(def._effect_list) do
			ef_level = mcl_potions.level_from_details (details, potency)
			dur = mcl_potions.duration_from_details (details, potency,
								 plus,
								 mcl_potions.SPLASH_FACTOR)
			mcl_potions.give_effect_by_level(name, obj, ef_level, dur)
		end
		end
		if def.custom_effect then def.custom_effect(obj, potency+1) end
	end

	minetest.register_entity("mcl_potions:"..name.."_arrow_entity", ARROW_ENTITY)

	minetest.register_craft({
		output = "mcl_potions:"..name.."_arrow 8",
		recipe = {
			{"mcl_bows:arrow","mcl_bows:arrow","mcl_bows:arrow"},
			{"mcl_bows:arrow","mcl_potions:"..name.."_lingering","mcl_bows:arrow"},
			{"mcl_bows:arrow","mcl_bows:arrow","mcl_bows:arrow"}
		}
	})

	if minetest.get_modpath("doc_identifier") then
		doc.sub.identifier.register_object("mcl_bows:arrow_entity", "craftitems", "mcl_bows:arrow")
	end
end
