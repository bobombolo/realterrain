for k, colorcode in ipairs(realterrain.slopecolors) do
	minetest.register_node(
		'realterrain:slope'..k, {
			description = "Slope: "..k,
			tiles = { colorcode..'.bmp' },
			light_source = 9,
			groups = {oddly_breakable_by_hand=1, not_in_creative_inventory=1},
			--[[after_place_node = function(pos, placer, itemstack, pointed_thing)
				local meta = minetest.get_meta(pos)
				meta:set_string("infotext", "Gis:"..colorcode);
				meta:set_int("placed", os.clock()*1000);
			end,--]]
	})	
end

--register the aspect symbology nodes
for k, colorcode in ipairs(realterrain.aspectcolors) do
	minetest.register_node(
		'realterrain:aspect'..k, {
			description = "Aspect: "..k,
			tiles = { colorcode..'.bmp' },
			light_source = 9,
			groups = {oddly_breakable_by_hand=1, not_in_creative_inventory=1},
			--[[after_place_node = function(pos, placer, itemstack, pointed_thing)
				local meta = minetest.get_meta(pos)
				meta:set_string("infotext", "Gis:"..colorcode);
				meta:set_int("placed", os.clock()*1000);
			end,--]]
	})
end

for k, symbol in ipairs(realterrain.symbols) do
	minetest.register_node(
		'realterrain:'..symbol, {
			description = "Symbol: "..symbol,
			tiles = { "white.bmp^[colorize:#"..symbol },
			light_source = 9,
			groups = {oddly_breakable_by_hand=1, not_in_creative_inventory=1},
			--[[after_place_node = function(pos, placer, itemstack, pointed_thing)
				local meta = minetest.get_meta(pos)
				meta:set_string("infotext", "Gis:"..colorcode);
				meta:set_int("placed", os.clock()*1000);
			end,--]]
	})
end

minetest.register_node(
	'realterrain:water_static', {
		description = "Water that Stays Put",
		tiles = { 'water_static.png' },
		--light_source = 9,
		groups = {oddly_breakable_by_hand=1},
		sunlight_propagates = true,
		--drawtype = "glasslike_framed_optional",
		post_effect_color = { r=0, g=0, b=128, a=128 },
		--[[after_place_node = function(pos, placer, itemstack, pointed_thing)
			local meta = minetest.get_meta(pos)
			meta:set_string("infotext", "Gis:"..colorcode);
			meta:set_int("placed", os.clock()*1000);
		end,--]]
})
