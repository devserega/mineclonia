lightning = {
	auto = true,
	effect_range = 500,
}
setmetatable(lightning, { __index = mcl_lightning })

minetest.register_alias("lightning:dying_flame", "mcl_fire:fire")
