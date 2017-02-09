local WORLDPATH = realterrain.worldpath
local RASTERS = realterrain.rasters
local SCHEMS = realterrain.schems
local PROCESSOR = realterrain.processor
local imagesize = realterrain.imagesize

local function list_images()
	local list = {}
	if package.config:sub(1,1) == "/" then
	--Unix
		--Loop through all files
		for file in io.popen('find "'..RASTERS..'" -type f'):lines() do                         
			local filename = string.sub(file, #RASTERS + 1)
			local im = imagesize.imgsize(RASTERS .. filename)
			if im then
				table.insert(list, filename)
			end
			im = nil
		end
		return list
	else
	--Windows
		--Open directory look for files, loop through all files 
		for filename in io.popen('dir "'..RASTERS..'" /b'):lines() do
			local im = imagesize.imgsize(RASTERS .. filename)
			if im then
				table.insert(list, filename)
			end
			im = nil
		end
		return list
	end
end

local function list_schems()
	local list = {}
	if package.config:sub(1,1) == "/" then
	--Unix
		--Loop through all files
		for file in io.popen('find "'..SCHEMS..'" -type f'):lines() do                         
			local filename = string.sub(file, #SCHEMS + 1)
			if string.find(file, ".mts", -4) ~= nil then
				table.insert(list, string.sub(filename, 1, -5))
			end
		end
		return list
	else
	--Windows
		--Open directory look for files, loop through all files 
		for filename in io.popen('dir "'..SCHEMS..'" /b'):lines() do
			if string.find(filename, ".mts", -4) ~= nil then
				table.insert(list, string.sub(filename, 1, -5))
			end
		end
		return list
	end
end

local function list_nodes()
	local list = {}
	--generate a list of all registered nodes that are simple blocks
	for name, def in pairs(minetest.registered_nodes) do
		if def.drawtype == "normal" and string.sub(name, 1, 12) ~= "realterrain:" then
			table.insert(list, name)
		end
	end
	--add water and lava
	table.insert(list, "realterrain:water_static")
	table.insert(list, "default:water_source")
	table.insert(list, "default:lava_source")
	return list
end

local function list_plants()
	local list = {}
	--generate a list of all registered nodes that are simple blocks
	for name, def in pairs(minetest.registered_nodes) do
		if def.drawtype == "plantlike" and string.sub(name, 1, 8) ~= "vessels:"  then
			table.insert(list, name)
		end
	end
	return list
end

local function list_symbology()
	local list = {}
	--generate a list of all registered nodes that are simple blocks
	for name, def in pairs(minetest.registered_nodes) do
		if def.drawtype == "normal" and string.sub(name, 1, 12) == "realterrain:"  then
			table.insert(list, name)
		end
	end
	return list
end

--need to override the minetest.formspec_escape to return empty string when nil
local function escape(str)
	if not str or str == "" then return "" else return minetest.formspec_escape(str) end
end

-- show the main remote control form
local function show_rc_form(pname)
	local player = minetest.get_player_by_name(pname)
	local ppos = player:getpos()
	local degree = player:get_look_yaw()*180/math.pi - 90
	if degree < 0 then degree = degree + 360 end
	local dir
	if     degree <= 45 or degree > 315 then dir = "North"
	elseif degree <= 135 then dir = "West"
	elseif degree <= 225 then dir = "South"
	else   dir = "South" end
	local howfar = "unknown"
	local surface = realterrain.get_surface(math.floor(ppos.x+0.5), math.floor(ppos.z+0.5))
	local above_below = "unknown"
	if surface then
		howfar = math.floor(math.abs(ppos.y-surface))
		if ppos.y < surface then
			above_below = "above"
		else
			above_below = "below"
		end
	else
		surface = "unknown"
	end
	local mode = realterrain.get_mode()
	local modename = mode.name
	
	local images = list_images()
	local f_images = ""
	for _, image in ipairs(images) do
		f_images = f_images .. image .. ","
	end
	local bits = {}
	bits["8"] = "1"
	bits["16"] = "2"
	
	local dmode = {}
	dmode["2D"] = "1"
	dmode["3D"] = "2"
	
	local f_modes = ""
	for _, mode in ipairs(realterrain.modes) do
		if f_modes == ""  then
			f_modes = mode.name
		else
			f_modes = f_modes .. "," .. mode.name
		end
	end
	
	--print("IMAGES in DEM folder: "..f_images)
	local col = {0.5, 2.5, 6.4, 8, 9, 10, 11, 12, 13}
	
	--form header
	local f_header = 			"size[14,10]" ..
								"button[0,0;3,1;gotosurface;Teleport to Surface]"..
								"button[3,0;3,1;resetday;Reset Morning Sun]"..
								"label[6,0;You are at x= "..math.floor(ppos.x)..
								" y= "..math.floor(ppos.y).." z= "..math.floor(ppos.z).." and mostly facing "..dir.."]"..
								"label[6,0.5;The surface is "..howfar.." blocks "..
									above_below.." you at "..surface.."]"
	--Scale settings
	local f_settings =			"label["..col[1]..",1.1;Raster Mode]"..
								"dropdown["..col[2]..",1;4,1;output;"..f_modes..";"..
									realterrain.get_mode_idx(realterrain.settings.output).."]"
									
	if modename == "normal" or modename == "surface" then
		local pos1 = "not set"
		local pos2 = "not set"
		if realterrain.pos1 then
			pos1 = "("..realterrain.pos1.x..","..realterrain.pos1.y..","..realterrain.pos1.z..")"
		end
		if realterrain.pos2 then
			pos2 = "("..realterrain.pos2.x..","..realterrain.pos2.y..","..realterrain.pos2.z..")"
		end
		f_settings = f_settings ..
		"label["..col[4]..",4;Structure Optoins:]"..
		"label["..col[4]..",4.5;pos1: "..pos1..", pos2: "..pos2.."]"..
		"button["..col[4]..",5;1,1;setpos1;Pos1]" ..
		"button["..col[5]..",5;1,1;setpos2;Pos2]" ..
		"button["..col[6]..",5;1.5,1;posreset;Clear]"
		
		if realterrain.pos1 and realterrain.pos2 then
			f_settings = f_settings..
			"button["..col[8]..",5;1.5,1;savestructure;Save]"
		end
	end
	if modename ~= "polynomial" then
		f_settings = f_settings ..
		"label["..col[4]-.2 ..",2;Scales]"..
		"label["..col[7]-.2 ..",2;Offsets]"..					
		
		"label["..col[4]..",2.5;Y]"..
		"label["..col[5]..",2.5;X]"..
		"label["..col[6]..",2.5;Z]"..
		
		"field["..col[4]..",3.25;1,1;yscale;;"..
			escape(realterrain.get_setting("yscale")).."]" ..
		"field["..col[5]..",3.25;1,1;xscale;;"..
			escape(realterrain.get_setting("xscale")).."]" ..
		"field["..col[6]..",3.25;1,1;zscale;;"..
			escape(realterrain.get_setting("zscale")).."]" ..
		
		"label["..col[7]..",2.5;Y]"..
		"label["..col[8]..",2.5;X]"..
		"label["..col[9]..",2.5;Z]"..
		
		"field["..col[7]..",3.25;1,1;yoffset;;"..
			escape(realterrain.get_setting("yoffset")).."]" ..
		"field["..col[8]..",3.25;1,1;xoffset;;"..
			escape(realterrain.get_setting("xoffset")).."]" ..
		"field["..col[9]..",3.25;1,1;zoffset;;"..
			escape(realterrain.get_setting("zoffset")).."]"
	end
	if modename == "distance" then
		f_settings = f_settings ..
		"label["..col[4]..",4;Distance Options:]"..
		"field["..col[4]..",5.25;1,1;dist_lim;limit;"..
			escape(realterrain.get_setting("dist_lim")).."]" ..
		"label["..col[5]..",4.6;mode:]"..
		"dropdown["..col[5]..",5.05;1,1;dist_mode;2D,3D;"..
			dmode[escape(realterrain.get_setting("dist_mode"))].."]"..
		"field["..col[7]..",5.25;1,1;dist_to_min;to min;"..
			escape(realterrain.get_setting("dist_to_min")).."]" ..
		"field["..col[8]..",5.25;1.5,1;dist_to_max;to max;"..
			escape(realterrain.get_setting("dist_to_max")).."]" 
		
	end
	if modename == "polynomial" then							
		f_settings = f_settings ..
		"label["..col[4]..",4;Polynomial Co-efficients]"..
		"field["..col[4]..",5.25;2,1;polya;(a*(x^2)*(z^2));"..
			escape(realterrain.get_setting("polya")).."]" ..
		"field["..col[6]..",5.25;2,1;polyb;+(b*(x^2)*(z));"..
			escape(realterrain.get_setting("polyb")).."]" ..
		"field["..col[8]..",5.25;2,1;polyc;+(c*(x)*(z^2));"..
			escape(realterrain.get_setting("polyc")).."]" ..
		"field["..col[4]..",6.25;2,1;polyd;+(d*(x^2));"..
			escape(realterrain.get_setting("polyd")).."]" ..
		"field["..col[6]..",6.25;2,1;polye;+(e*(z^2));"..
			escape(realterrain.get_setting("polye")).."]"..
		"field["..col[8]..",6.25;2,1;polyf;+(f*(x));"..
			escape(realterrain.get_setting("polyf")).."]"..
		"field["..col[4]..",7.25;2,1;polyg;+(g*(z));"..
		   escape(realterrain.get_setting("polyg")).."]"..
		"field["..col[6]..",7.25;2,1;polyh;+h;"..
			escape(realterrain.get_setting("polyh")).."]"
	end
	if not mode.computed then
		f_settings = f_settings ..
		"label["..col[1]..",3.1;Elevation File]"..
		"dropdown["..col[2]..",3;4,1;fileelev;"..f_images..";"..
			realterrain.get_idx(images, realterrain.get_setting("fileelev")) .."]"
	end
	if mode.get_cover then															
		f_settings = f_settings ..
		"label["..col[1]..",4.1;Biome File]"..
		"dropdown["..col[2]..",4;4,1;filecover;"..f_images..";"..
			realterrain.get_idx(images, realterrain.get_setting("filecover")) .."]" 
	end
	if mode.get_input then
		f_settings = f_settings ..
		"label["..col[1]..",5.1;Input File 1 (R)]"..
		"dropdown["..col[2]..",5;4,1;fileinput;"..f_images..";"..
			realterrain.get_idx(images, realterrain.get_setting("fileinput")) .."]"
	end
	if mode.get_input2 then
		f_settings = f_settings ..
		"label["..col[1]..",6.1;Input File 2 (G)]"..
		"dropdown["..col[2]..",6;4,1;fileinput2;"..f_images..";"..
			realterrain.get_idx(images, realterrain.get_setting("fileinput2")) .."]"
	end
	if mode.get_input3 then
		f_settings = f_settings ..
		"label["..col[1]..",7.1;Input File 3 (B)]"..
		"dropdown["..col[2]..",7;4,1;fileinput3;"..f_images..";"..
			realterrain.get_idx(images, realterrain.get_setting("fileinput3")) .."]"
	end
	if not mode.computed
	and PROCESSOR ~= "py"
	and PROCESSOR ~="gm"
	and PROCESSOR ~= "convert"
	and not (PROCESSOR == "magick" and MAGICK_AS_CONVERT) then --these modes know the bits
		f_settings = f_settings ..
		"label["..col[3]+0.2 ..",2;Bits]"..
		"dropdown["..col[3]..",3;1,1;elevbits;8,16;"..
				bits[escape(realterrain.get_setting("elevbits"))].."]"
		if mode.get_cover then
			f_settings = f_settings ..
			"dropdown["..col[3]..",4;1,1;coverbits;8,16;"..
				bits[escape(realterrain.get_setting("coverbits"))].."]"
		end
		if mode.get_input then
			f_settings = f_settings ..
			"dropdown["..col[3]..",5;1,1;inputbits;8,16;"..
				bits[escape(realterrain.get_setting("inputbits"))].."]"
		end
		if mode.get_input2 then
			f_settings = f_settings ..
			"dropdown["..col[3]..",6;1,1;input2bits2;8,16;"..
				bits[escape(realterrain.get_setting("input2bits"))].."]"
		end
		if mode.get_input3 then
			f_settings = f_settings ..
			"dropdown["..col[3]..",7;1,1;input3bits;8,16;"..
				bits[escape(realterrain.get_setting("input3bits"))].."]"
		end
	end
	if modename == "normal" or modename == "surface" then
		f_settings = f_settings ..	
		"field[1,9;2,1;waterlevel;Water Level;"..
			escape(realterrain.get_setting("waterlevel")).."]"..
		"field[3,9;2,1;alpinelevel;Alpine Level;"..
			escape(realterrain.get_setting("alpinelevel")).."]"
	end
	--Action buttons
	local f_footer =			"button_exit[8,8;2,1;exit;Biomes]"..
								--[["button_exit[10,8;2,1;exit;Ores]"..--]]
								"button_exit[12,8;2,1;exit;Symbols]"..
								
								"label[5.5,9;Apply and]"..
								"label[5.5,9.4;delete map:]"..
								"button_exit[7.1,9;2,1;exit;Delete]"..
                                "label[10,9.25;Apply only: ]"..
								"button_exit[11.5,9;2,1;exit;Apply]"
								
    
    minetest.show_formspec(pname, "realterrain:rc_form", 
                        f_header ..
                        f_settings ..
                        f_footer
    )
    return true
end

local function show_cover_form(pname)
	local schems = list_schems()
	local f_schems = ""
	for _, schem in ipairs(schems) do
		f_schems = f_schems .. schem .. ","
	end
	
	local col= {0.01,  0.5,1.3,2.1,   3.5,5.5,6.5,8.5,   10,11,12,13,   12.5}
	local f_header = 	"size[14,10]" ..
						"button_exit["..col[13]..",9.5;1.5,1;exit;Apply]"..
						--"label["..col[1]..",0.01;USGS Biome]"..
						"label["..col[2]..",0.01;Ground 1,2]"..
						"label["..col[4]..",0.01;Mix]"..
						"label["..col[5]..",0.01;Tree]".."label["..col[6]..",0.01;Prob]"..
						"label["..col[7]..",0.01;Tree2]".."label["..col[8]..",0.01;Mix]"..
						"label["..col[9]..",0.01;Shrub]".."label["..col[10]..",0.01;Prob]"..
						"label["..col[11]..",0.01;Shrub2]".."label["..col[12]..",0.01;Mix]"
	local f_body = ""
	for i=0,9,1 do
		local h = (i +1) * 0.7
		f_body = f_body ..
			"label["..col[1]..","..h ..";"..i.."]"..
			"item_image_button["..(col[2])..","..(h-0.2)..";0.8,0.8;"..realterrain.get_setting("b"..i.."ground")..";ground;"..i.."]"..
			"item_image_button["..(col[3])..","..(h-0.2)..";0.8,0.8;"..
			realterrain.get_setting("b"..i.."ground2")..";ground2;"..i.."]"..
			"field["..(col[4]+0.2)..","..h ..";1,1;b"..i.."gprob;;"..
				escape(realterrain.get_setting("b"..i.."gprob")).."]"
		f_body = f_body ..
			"dropdown["..col[5]..","..(h-0.3) ..";2,1;b"..i.."tree;"..f_schems..";"..
				realterrain.get_idx(schems, realterrain.get_setting("b"..i.."tree")) .."]" ..
			"field["..(col[6]+0.2)..","..h ..";1,1;b"..i.."tprob;;"..
				escape(realterrain.get_setting("b"..i.."tprob")).."]" ..
			"dropdown["..col[7]..","..(h-0.3) ..";2,1;b"..i.."tree2;"..f_schems..";"..
				realterrain.get_idx(schems, realterrain.get_setting("b"..i.."tree2")) .."]" ..
			"field["..(col[8]+0.2)..","..h ..";1,1;b"..i.."tprob2;;"..
				escape(realterrain.get_setting("b"..i.."tprob2")).."]"
		f_body = f_body ..
			"item_image_button["..(col[9])..","..(h-0.2)..";0.8,0.8;"..realterrain.get_setting("b"..i.."shrub")..";shrub;"..i.."]"..
			"field["..col[10]..","..h ..";1,1;b"..i.."sprob;;"..
				escape(realterrain.get_setting("b"..i.."sprob")).."]"..
			"item_image_button["..(col[11])..","..(h-0.2)..";0.8,0.8;"..realterrain.get_setting("b"..i.."shrub2")..";shrub2;"..i.."]"..
			"field["..col[12]..","..h ..";1,1;b"..i.."sprob2;;"..
				escape(realterrain.get_setting("b"..i.."sprob2")).."]"
	end
	local f_notes = "label[1,8;Biome 1 - Roads,  Biome2 - Agriculture,  Biome3 - Rangeland]"..
					"label[1,8.5;Biome 4 - Forest,  Biome 5 - Water,  Biome 6 - Wetlands]"..
					"label[1,9;Biome 7 - Barren,  Biome 8 - Tundra,  Biome 9 - Glacial]"
	
	minetest.show_formspec(pname,   "realterrain:cover_config",
                                    f_header .. f_body .. f_notes
	)
	return true
end

local function show_ores_form(pname)
	
	local col= {0.01,  0.5,1.3,2.1,   3.5,5.5,6.5,8.5,   10,11,12,13,   12.5}
	local f_header = 	"size[14,10]" ..
						"button_exit["..col[13]..",9.5;1.5,1;exit;Apply]"
						--"label["..col[1]..",0.01;USGS Biome]"..
						
	local f_body = ""
	for i=0,9,1 do
		local h = (i +1) * 0.7
		
		f_body = ""
	end
	local f_notes = ""
	
	minetest.show_formspec(pname,   "realterrain:ores_config",
                                    f_header .. f_body .. f_notes
	)
	return true
end

local function show_symbology(pname)
	local col= {0.01,2}
	local f_header = 	"size[14,10]" ..
						"button_exit[11,0.01;2,1;exit;Apply]"..
						"label["..col[1]..",0.01;Symbol]"..
						"label["..col[2]..",0.01;Node]"
	local f_body = ""
	for i=1,10 do
			local h = (i +1) * 0.7
		f_body = f_body ..
			"label["..col[1]..","..h ..";"..i.."]"..
			"item_image_button["..(col[2])..","..(h-0.2)..";0.8,0.8;"..realterrain.get_setting("rastsymbol"..i)..";rastsymbol;"..i.."]"
	end
	minetest.show_formspec(pname,   "realterrain:symbology",
                                    f_header..f_body
	)
	return true
end

local function show_item_images(pname, items, setting)
	local f_images = ""
	local i = 1
	local j = 1
	for _, item in ipairs(items) do
		f_images = f_images .. "item_image_button["..i..","..j..";1,1;"..item..";"..setting..";"..item.."]"
		if i < 12 then
			i = i + 1
		else
			i = 1
			j = j + 1
		end
		
	end
	local f_body = "size[14,10]" ..
					"button_exit[12,0.01;2,1;exit;Cancel]"
	--print(f_images)	
	minetest.show_formspec(pname,   "realterrain:image_items",
                                    f_body..f_images
	)
	return true
end

local function show_all_symbols(pname, items, setting)
	local f_images = ""
	local i = 1
	local j = 1
	for _, item in ipairs(items) do
		f_images = f_images .. "item_image_button["..(i*0.6)..","..(j*0.6)..";0.6,0.6;"..item..";"..setting..";"..item.."]"
		if i < 16 then
			i = i + 1
		else
			i = 1
			j = j + 1
		end
		
	end
	local f_body = "size[14,10]" ..
					"button_exit[12,0.01;2,1;exit;Cancel]"
	--print(f_images)	
	minetest.show_formspec(pname,   "realterrain:all_symbols",
                                    f_body..f_images
	)
	return true
end

-- this is the form-error popup
local function show_invalidated(pname, formname, fields)
	local back, message
	if formname == "realterrain:rc_form" then back = "Main"
	elseif formname == "realterrain:cover_config" then back = "Cover"
	elseif formname == "realterrain:ores_config" then back = "Ores"
	elseif formname == "realterrain:symbology" then back = "Symbols"
	end
	for _, field in pairs(fields) do
		if not message then
			message = "The following fields were invalid: "..field
		else
			message = message .. ", "..field
		end
	end
	
	minetest.chat_send_player(pname, "Form error: ".. message)
	minetest.show_formspec(pname,   "realterrain:invalidated",
                                    "size[10,8]" ..
                                    "button_exit[1,1;2,1;exit;"..back.."]"..
                                    "label[1,3;"..escape(message).."]"
	)
	return true
end

-- the controller for changing map settings
minetest.register_tool("realterrain:remote" , {
	description = "Realterrain Settings",
	inventory_image = "remote.png",
	--left-clicking the tool
	on_use = function (itemstack, user, pointed_thing)
        local pname = user:get_player_name()
		show_rc_form(pname)
	end,
})

local function save_structure(pos1,pos2)
	--swap the max and mins until pos1 is the pmin and pos2 is the pmax
	local xmin,ymin,zmin,xmax,ymax,zmax
	if pos1.x < pos2.x then xmin = pos1.x else xmin = pos2.x end
	if pos1.y < pos2.y then ymin = pos1.y else ymin = pos2.y end
	if pos1.z < pos2.z then zmin = pos1.z else zmin = pos2.z end
	if pos1.x > pos2.x then xmax = pos1.x else xmax = pos2.x end
	if pos1.y > pos2.y then ymax = pos1.y else ymax = pos2.y end
	if pos1.z > pos2.z then zmax = pos1.z else zmax = pos2.z end
	pos1 = {x=xmin, y=ymin, z=zmin}
	pos2 = {x=xmax, y=ymax, z=zmax}
	
	if minetest.create_schematic(pos1, pos2, nil, STRUCTURES..pos1.x.."_"..pos1.y.."_"..pos1.z..".mts") then
		return true
	end
	
end

-- Processing the form from the RC
minetest.register_on_player_receive_fields(function(player, formname, fields)
	if string.sub(formname, 1, 12) == "realterrain:" then
		local wait = os.clock()
		while os.clock() - wait < 0.05 do end --popups don't work without this
		--print("form, "..formname.." submitted: "..dump(fields))
		local pname = player:get_player_name()
		
		--the popup form never has settings so process that first
		if formname == "realterrain:invalidated" then
			if fields.exit == "Main" then
				show_rc_form(pname)
			elseif fields.exit == "Cover" then
				show_cover_form(pname)
			elseif fields.exit == "Ores" then
				show_ores_form(pname)
			elseif fields.exit == "Symbols" then
				show_symbology(pname)
			end
			return true
		end
		--the main form
		if formname == "realterrain:rc_form" then 
			--buttons that don't close the form:
			local ppos = player:getpos()
			if fields.gotosurface then
				local surface = realterrain.get_surface(ppos.x, ppos.z)
				if surface then
					player:setpos({x=ppos.x, y=surface+0.5, z=ppos.z})
					--should refresh this form so that the position info updates
					show_rc_form(pname)
				else
					minetest.chat_send_player(pname, "surface is undetectable")
				end
				return true
			elseif fields.resetday then
				minetest.set_timeofday(0.25)
			elseif fields.setpos1 then
				realterrain.pos1 = {x=math.floor(ppos.x+0.5),y=math.floor(ppos.y+0.5),z=math.floor(ppos.z+0.5)}
				minetest.chat_send_player(pname, "pos1 set to ("..realterrain.pos1.x..","..realterrain.pos1.y..","..realterrain.pos1.z..")")
				show_rc_form(pname)
				return true
			elseif fields.setpos2 then
				realterrain.pos2 = {x=math.floor(ppos.x+0.5),y=math.floor(ppos.y+0.5),z=math.floor(ppos.z+0.5)}
				minetest.chat_send_player(pname, "pos2 set to ("..realterrain.pos2.x..","..realterrain.pos2.y..","..realterrain.pos2.z..")")
				show_rc_form(pname)
				return true
			elseif fields.posreset then
				realterrain.pos1 = nil
				realterrain.pos2 = nil
				show_rc_form(pname)
				return true
			elseif fields.savestructure then
				if realterrain.pos1 and realterrain.pos2 then --will always be since button not shown otherwise
					save_structure(realterrain.pos1,realterrain.pos2)
					minetest.chat_send_player(pname, "structure persisted to file")
				end
				return true
			end
			
			--actual form submissions
			if fields.output or fields.fileelev or fields.filecover or fields.fileinput
				or fields.fileinput2 or fields.fileinput3 then
				--check to see if the source rasters were changed, if so re-initialize
				local old_output, old_elev, old_cover, old_input
				old_output = realterrain.settings.output
				old_elev = realterrain.settings.fileelev
				old_cover = realterrain.settings.filecover
				old_input = realterrain.settings.fileinput
				
				-- @todo validation for mode and raster selection changes, or not
				
				-- save form fields, if errors then show popup
				local invalids = realterrain.validate_and_save(fields)
				if invalids ~= false then
					show_invalidated(pname, formname, invalids)
					return false
				end
				
				minetest.chat_send_player(pname, "You changed the mapgen settings!")
				if old_elev ~= realterrain.settings.fileelev
					or old_cover ~= realterrain.settings.filecover
					or old_input ~= realterrain.settings.fileinput then
					realterrain.init()
				end
				if old_output ~= realterrain.settings.output then
					--redisplay the form so that mode-specific stuff is shown/hidden
					show_rc_form(pname)
					return true
				end
				
            elseif fields.exit then --Apply or any other button
				
				-- save form fields, if errors then show popup
				local invalids = realterrain.validate_and_save(fields)
				if invalids ~= false then
					show_invalidated(pname, formname, invalids)
					return false
				end
				
				minetest.chat_send_player(pname, "You changed the mapgen settings!")
			end
			if fields.exit == "Delete" then --@todo use the popup form do display a confirmation dialog box
                --kick all players and delete the map file
                local players = minetest.get_connected_players()
				for _, player in ipairs(players) do
					minetest.kick_player(player:get_player_name(), "map.sqlite deleted by admin, reload level")	
				end
				minetest.register_on_shutdown(function()
					local wait = os.clock()
					while os.clock() - wait < 1 do end --the following delete happens too fast otherwise @todo this doesn't help
					os.remove(WORLDPATH.."/map.sqlite")
				end)
				
                return true
			elseif fields.exit == "Biomes" then
				show_cover_form(pname)
				return true
			elseif fields.exit == "Ores" then
				show_ores_form(pname)
				return true
			elseif fields.exit == "Symbols" then
				show_symbology(pname)
				return true
			end
			return true
		end
		
		--cover config form
		if formname == "realterrain:cover_config" then
			-- @todo validated all non dropdown fields (numbers as numbers)
				
			-- save form fields, if errors then show popup
			local invalids = realterrain.validate_and_save(fields)
			if invalids ~= false then
				show_invalidated(pname, formname, invalids)
				return false
			end
			
			minetest.chat_send_player(pname, "You changed the biome settings!")
			if fields.exit == "Apply" then
				show_rc_form(pname)
				return true
			elseif fields.ground then
				local setting = "b"..fields.ground.."ground"
				show_item_images(pname, list_nodes(), setting)
			elseif fields.ground2 then
				local setting = "b"..fields.ground2.."ground2"
				show_item_images(pname, list_nodes(), setting)
			elseif fields.shrub then
				local setting = "b"..fields.shrub.."shrub"
				show_item_images(pname, list_plants(), setting)
			elseif fields.shrub2 then
				local setting = "b"..fields.shrub2.."shrub2"
				show_item_images(pname, list_plants(), setting)
			end
			return true
		end
		--item image selection form
		if formname == "realterrain:image_items" then
			
			-- save form fields, if errors then show popup
			local invalids = realterrain.validate_and_save(fields)
			if invalids ~= false then
				show_invalidated(pname, formname, invalids)
				return false
			end
			
			minetest.chat_send_player(pname, "You changed the biome settings!")
			show_cover_form(pname)
			return true
		end
		--raster symbology selection form
		if formname == "realterrain:symbology" then
			-- @todo validated all non dropdown fields (numbers as numbers)
				
			-- save form fields, if errors then show popup
			local invalids = realterrain.validate_and_save(fields)
			if invalids ~= false then
				show_invalidated(pname, formname, invalids)
				return false
			end
			
			minetest.chat_send_player(pname, "You changed the symbology settings!")
			if fields.exit == "Apply" then
				show_rc_form(pname)
				return true
			elseif fields.rastsymbol then 
				local setting = "rastsymbol"..fields.rastsymbol
				minetest.chat_send_player(pname, "please be patient while all symbols load")
				show_all_symbols(pname, list_symbology(), setting)
			end
			return true
		end
		--symbology selection form
		if formname == "realterrain:all_symbols" then
			-- save form fields, if errors then show popup
			local invalids = realterrain.validate_and_save(fields)
			if invalids ~= false then
				show_invalidated(pname, formname, invalids)
				return false
			end
			minetest.chat_send_player(pname, "You changed the symbology settings!")
			show_symbology(pname)
			return true
		end
		return true
	end
end)


