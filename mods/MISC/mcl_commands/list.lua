local S = minetest.get_translator(minetest.get_current_modname())

minetest.register_chatcommand("list", {
	description = S("Show who is logged on"),
	params = "",
	privs = {},
	func = function(name)
		local players = ""
		for player in mcl_util.connected_players() do
			players = players..player:get_player_name().."\n"
		end
		minetest.chat_send_player(name, players)
	end
})
