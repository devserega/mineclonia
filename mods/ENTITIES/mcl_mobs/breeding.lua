local mob_class = mcl_mobs.mob_class

local HORNY_TIME = 30*20
local HORNY_AGAIN_TIME = 30*20 -- was 300 or 15*20
local CHILD_GROW_TIME = 24000

function mob_class:use_shears(new_textures, shears_stack)
	if minetest.get_item_group(shears_stack:get_name(), "shears") > 0 then
		self.object:set_properties({ textures = new_textures })
		self.gotten = true
		minetest.sound_play("mcl_tools_shears_cut", { pos = self.object:get_pos() }, true)
		local shears_def = shears_stack:get_definition()
		shears_stack:add_wear(65535 / shears_def._mcl_diggroups.shearsy.uses)
	end
	return shears_stack
end

function mob_class:_on_dispense(dropitem)
	local item = dropitem.get_name and dropitem:get_name() or dropitem
	if self.follow and ((type(self.follow) == "table" and table.indexof(self.follow, item) ~= -1) or item == self.follow) then
		if self:feed_tame(nil, 1, true, false) then
			dropitem:take_item()
			return dropitem
		end
	end
end

function mob_class:feed_tame(clicker, heal, breed, tame, notake)
	local consume_food = false

	if clicker and tame and not self.child then
		if not self.owner or self.owner == "" then
			self.tamed = true
			self.owner = clicker:get_player_name()
			consume_food = true
		end
	end

	if self.health < self.object:get_properties().hp_max and not consume_food then
		consume_food = true
		self.health = math.min(self.health + heal, self.object:get_properties().hp_max)
		if self.htimer < 1 then
			self.htimer = 5
		end
		self.object:set_hp(self.health)
	end

	if not consume_food and self.child == true then
		consume_food = true
		self.hornytimer = self.hornytimer + ((CHILD_GROW_TIME - self.hornytimer) * 0.1)
	end

	if breed and not consume_food and self.hornytimer == 0 and not self.horny then
		consume_food = true
		self.horny = true
		self.persistent = true
	end

	self:update_tag()
	if clicker and consume_food then
		if not minetest.is_creative_enabled(clicker:get_player_name()) and not notake then
			local item = clicker:get_wielded_item()
			item:take_item()
			clicker:set_wielded_item(item)
		end
		self:mob_sound("eat", nil, true)
	else
		self:mob_sound("random", true)
	end

	return consume_food
end

function mcl_mobs.spawn_child(pos, mob_type)
	local child = minetest.add_entity(pos, mob_type)
	if not child then
		return
	end

	local ent = child:get_luaentity()
	mcl_mobs.effect(pos, 15, "mcl_particles_smoke.png", 1, 2, 2, 15, 5)
	ent.child = true
	local textures
	if ent.child_texture then
		textures = ent.child_texture[1]
	end

	ent:set_properties({
		textures = textures,
		visual_size = {
			x = ent.base_size.x * .5,
			y = ent.base_size.y * .5,
		},
		collisionbox = {
			ent.base_colbox[1] * .5,
			ent.base_colbox[2] * .5,
			ent.base_colbox[3] * .5,
			ent.base_colbox[4] * .5,
			ent.base_colbox[5] * .5,
			ent.base_colbox[6] * .5,
		},
		selectionbox = {
			ent.base_selbox[1] * .5,
			ent.base_selbox[2] * .5,
			ent.base_selbox[3] * .5,
			ent.base_selbox[4] * .5,
			ent.base_selbox[5] * .5,
			ent.base_selbox[6] * .5,
		},
	})

	ent.animation = ent._child_animations
	ent._current_animation = nil
	ent:set_animation("stand")
	return child
end

function mob_class:check_breeding()
	if self.child == true then
		-- When a child, hornytimer is used to count age until adulthood
		self.hornytimer = self.hornytimer + 1
		if self.hornytimer >= CHILD_GROW_TIME then
			self.child = false
			self.hornytimer = 0
			self:set_properties({
				textures = self.base_texture,
				mesh = self.base_mesh,
				visual_size = self.base_size,
				collisionbox = self.base_colbox,
				selectionbox = self.base_selbox,
			})
			if self.on_grown then
				self.on_grown(self)
			else
				-- jump when fully grown so as not to fall into ground
				self.object:set_velocity({
					x = 0,
					y = self.jump_height,
					z = 0
				})
			end
			self.animation = nil
			local anim = self._current_animation
			self._current_animation = nil
			self:set_animation(anim)
		end
		return
	else
		if self.horny == true then
			self.hornytimer = self.hornytimer + 1

			if self.hornytimer >= HORNY_TIME + HORNY_AGAIN_TIME then
				self.hornytimer = 0
				self.horny = false
			end
		end
	end
	if self.horny == true
	and self.hornytimer <= HORNY_TIME then
		local pos = self.object:get_pos()

        if (self.hornytimer % 20) == 0.0 then
            mcl_mobs.effect({x = pos.x, y = pos.y + 1, z = pos.z}, 8, "heart.png", 3, 4, 1, 0.1)
        end

		local num = 0
		for obj in minetest.objects_inside_radius(pos, 3) do
			local ent = obj:get_luaentity()
			-- check for same animal with different colour
			local canmate = false
			if ent then
				if ent.name == self.name then
					canmate = true
				else
					local entname = string.split(ent.name,":")
					local selfname = string.split(self.name,":")
					if entname[1] == selfname[1] then
						entname = string.split(entname[2],"_")
						selfname = string.split(selfname[2],"_")
						if entname[1] == selfname[1] then
							canmate = true
						end
					end
				end
			end

			if ent
			and canmate == true
			and ent.horny == true
			and ent.hornytimer <= HORNY_TIME then
				num = num + 1
			end

			-- found your mate? then have a baby
			if num > 1 then
				self.hornytimer = HORNY_TIME + 1
				ent.hornytimer = HORNY_TIME + 1
				minetest.after(5, function(parent1, parent2, pos)
					if not parent1.object:get_luaentity() then
						return
					end
					if not parent2.object:get_luaentity() then
						return
					end

					mcl_experience.throw_xp(pos, math.random(1, 7))

					if parent1.on_breed then
						if parent1.on_breed(parent1, parent2) == false then
							return
						end
					end
					local child = mcl_mobs.spawn_child(pos, parent1.name)
					if child then
						local ent_c = child:get_luaentity()
						-- Use texture of one of the parents
						local p = math.random(1, 2)
						if p == 1 then
							ent_c.base_texture = parent1.base_texture
						else
							ent_c.base_texture = parent2.base_texture
						end
						ent_c:set_properties({
							textures = ent_c.base_texture
						})
						ent_c.tamed = true
						ent_c.owner = parent1.owner
					end
				end, self, ent, pos)
				break
			end
		end
	end
end

function mob_class:stay()
	self.order = "sit"
	self:set_state("stand")
	self.walk_chance = 0
	self.jump = false
	if self.animation.sit_start then
		self:set_animation("sit")
	else
		self:set_animation("stand")
	end
end

function mob_class:roam()
	self.order = "roam"
	self:set_state("stand")
	self.walk_chance = 50
	self.jump = true
	self:set_animation("stand")
end

function mob_class:toggle_sit(clicker,p)
	if not self.tamed or self.child  or self.owner ~= clicker:get_player_name() then
		return
	end
	local pos = self.object:get_pos()
	local particle
	if not self.order or self.order == "" or self.order == "sit" then
		particle = "mobs_mc_wolf_icon_roam.png"
		self:roam()
	else
		particle = "mobs_mc_wolf_icon_sit.png"
		self:stay()
	end
	local pp = vector.new(0,1.4,0)
	if p then pp = vector.offset(pp,0,p,0) end
	-- Display icon to show current order (sit or roam)
	minetest.add_particle({
		pos = vector.add(pos, pp),
		velocity = {x=0,y=0.2,z=0},
		expirationtime = 1,
		size = 4,
		texture = particle,
		playername = self.owner,
		glow = minetest.LIGHT_MAX,
	})
end

function mob_class:break_in(player)
	self.temper = self.temper or (math.random(100))
	if not self.tamed then
		local item = player:get_wielded_item()
		local temper_increase = 0
		if self._temper_increase and self._temper_increase[item:get_name()] then
			temper_increase = self._temper_increase[item:get_name()]
			item:take_item()
			player:set_wielded_item(item)
		elseif not self.driver then
			self.object:set_properties({stepheight = 1.1})
			self:attach(player)
			self.buck_off_time = 40 -- TODO how long does it take in minecraft?
			if self.temper > 100 then
				self.tamed = true -- NOTE taming can only be finished by riding the horse
				if not self.owner or self.owner == "" then
					self.owner = player:get_player_name()
				end
				-- Spawn effect at mount yaw pos so it can be easily noticable in first person view
				local pos = self.object:get_pos()
				local yaw = self.object:get_yaw()
				local x = pos.x + -math.sin(yaw)
				local z = pos.z +  math.cos(yaw)
				mcl_mobs.effect({x = x, y = pos.y + 1.5, z = z}, 20, "heart.png", 3, 4, 1.5, 0.1)
			end
			temper_increase = 5
		elseif self.driver and self.driver == player then
			mcl_mobs.detach(player, vector.new(0, 0, 1))
		end
		self.temper = self.temper + temper_increase
		return true
	end
end
