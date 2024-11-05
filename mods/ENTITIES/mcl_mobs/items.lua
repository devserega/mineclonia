local mob_class = mcl_mobs.mob_class

local function player_near(pos)
	for o in minetest.objects_inside_radius(pos, 2) do
		if o:is_player() then return true end
	end
end

local function get_armor_texture(obj, armor_name)
	local stack = ItemStack(armor_name)
	local def = stack:get_definition()
	if armor_name == "" then
		return ""
	end
	if armor_name=="blank.png" then
		return "blank.png"
	end
	local t = def._mcl_armor_texture or ""
	if type(def._mcl_armor_texture) == "function" then
		t = def._mcl_armor_texture(obj, stack)
	end
	return t.."^"
end

function mob_class:set_armor_texture()
	if self.armor_list then
		local chestplate=minetest.registered_items[ItemStack(self.armor_list.torso):get_name()]  or {name=""}
		local boots=minetest.registered_items[ItemStack(self.armor_list.feet):get_name()] or {name=""}
		local leggings=minetest.registered_items[ItemStack(self.armor_list.legs):get_name()] or {name=""}
		local helmet=minetest.registered_items[ItemStack(self.armor_list.head):get_name()] or {name=""}

		if helmet.name=="" and chestplate.name=="" and leggings.name=="" and boots.name=="" then
			helmet={name="blank.png"}
		end

		local texture = get_armor_texture(self.object, chestplate.name)
		..get_armor_texture(self.object, helmet.name)
		..get_armor_texture(self.object, boots.name)
		..get_armor_texture(self.object, leggings.name)
		if string.sub(texture, -1,-1) == "^" then
			texture=string.sub(texture,1,-2)
		end
		if self.base_texture[self.wears_armor and 1] then
			self.base_texture[self.wears_armor and 1]=texture
		end
		self:set_properties({textures=self.base_texture})

		local armor_
		if type(self.armor) == "table" then
			armor_ = table.copy(self.armor)
			armor_.immortal = 1
		else
			armor_ = {immortal=1, fleshy = self.armor}
		end

		for _,item in pairs(self.armor_list) do
			if not item then return end
			if type(minetest.get_item_group(item, "mcl_armor_points")) == "number" then
				armor_.fleshy=armor_.fleshy-(minetest.get_item_group(item, "mcl_armor_points")*3.5)
			end
		end
		self.object:set_armor_groups(armor_)
	end
end

function mob_class:is_drop(itemstack)
	if self.drops then
		for _, v in pairs(self.drops) do
			if v and v.name and v.name == itemstack:get_name() then return true end
		end
	end
end

function mob_class:check_item_pickup()
	if self.pick_up and #self.pick_up > 0 or self.wears_armor then
		local p = self.object:get_pos()
		if not p then return end
		for o in minetest.objects_inside_radius(p, 2) do
			local l=o:get_luaentity()
			if l and l.name == "__builtin:item" and not player_near(p) and not self:is_drop(ItemStack(l.itemstring)) then
				local stack = ItemStack(l.itemstring)
				local def = stack:get_definition()
				local itemname = stack:get_name()

				if self.wears_armor and minetest.get_item_group(itemname, "armor") > 0 and def._mcl_armor_element then
					if self.armor_list[def._mcl_armor_element] == "" then
						self.armor_list[def._mcl_armor_element] = stack:to_string()
						o:remove()
						self:set_armor_texture()
						self.persistent = true
					end
				elseif self.pick_up then
					for _, v in pairs(self.pick_up) do
						if self.on_pick_up and itemname == v then
							local r = self.on_pick_up(self,l)
							if r and r.is_empty and not r:is_empty() then
								l.itemstring = r:to_string()
							elseif r and r.is_empty and r:is_empty() then
								o:remove()
							end
						end
					end
				end
			end
		end
	end
end
