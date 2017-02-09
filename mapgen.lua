local SCHEMS = realterrain.schems
local STRUCTURES = realterrain.structures

local cids = nil
local function build_cids()
	cids = { --turn various content ids into variables for speed
		dirt = minetest.get_content_id("default:dirt"),
		stone = minetest.get_content_id("default:stone"),
		alpine = minetest.get_content_id("default:gravel"),
		water_bottom = minetest.get_content_id("default:sand"),
		water = minetest.get_content_id("water_source"),
		air = minetest.get_content_id("air"),
		lava = minetest.get_content_id("lava_source"),
	}

	for i=0, 9 do
		local prefix = "b" .. i
		cids[i] = {
			ground = minetest.get_content_id(realterrain.settings[prefix.."ground"]),
			ground2 = minetest.get_content_id(realterrain.settings[prefix.."ground2"]),
			shrub = minetest.get_content_id(realterrain.settings[prefix.."shrub"]),
			shrub2 = minetest.get_content_id(realterrain.settings[prefix.."shrub2"])
		}
	end

	--register cids for SLOPE mode.name
	for i=1,10 do
		cids["symbol"..i] = minetest.get_content_id(realterrain.settings["rastsymbol"..i])
	end

	--register cids for ASPECT mode.name
	for k, code in ipairs(realterrain.aspectcolors) do
		cids["aspect"..k] = minetest.get_content_id("realterrain:".."aspect"..k)
	end


	cids["symbol10"] = minetest.get_content_id("realterrain:slope10")

	for _, symbol in ipairs(realterrain.symbols) do
		cids[symbol] = minetest.get_content_id("realterrain:"..symbol)
	end
end

local neighborhood = {
	a = {x= 1,y= 0,z= 1}, -- NW
	b = {x= 0,y= 0,z= 1}, -- N
	c = {x= 1,y= 0,z= 1}, -- NE
	d = {x=-1,y= 0,z= 0}, -- W
--	e = {x= 0,y= 0,z= 0}, -- SELF
	f = {x= 1,y= 0,z= 0}, -- E
	g = {x=-1,y= 0,z=-1}, -- SW
	h = {x= 0,y= 0,z=-1}, -- S
	i = {x= 1,y= 0,z=-1}, -- SE
}

--this function gets the height needed to fill below a node for surface-only modes
local function height_fill_below(x,z,heightmap)
	local height = 0
	local height_in_chunk = 0
	local height_below_chunk = 0
	local below_positions = {}
	local elev = heightmap[z][x].elev
	for dir, offset in pairs(neighborhood) do
		--get elev for all surrounding nodes
		if dir == "b" or dir == "d" or dir == "f" or dir == "h" then
			
			if heightmap[z+offset.z] and heightmap[z+offset.z][x+offset.x] and heightmap[z+offset.z][x+offset.x].elev then
				local nelev = heightmap[z+offset.z][x+offset.x].elev
				-- if the neighboring height is more than one down, check if it is the furthest down
				if elev > ( nelev) and height < (elev-nelev) then
					height = elev - nelev
				end
			end
		end
	end
	--print(height)
	return height -1
end

local function get_structures_for_chunk(x0,y0,z0, sidelen)
	local structures = {}
	--look in the structures folder and check each one to see if it is in the chunk
	local list = {}
	if package.config:sub(1,1) == "/" then
	--Unix
		--Loop through all files
		for file in io.popen('find "'..STRUCTURES..'" -type f'):lines() do                         
			local filename = string.sub(file, #STRUCTURES + 1)
			if string.find(file, ".mts", -4) ~= nil then
				table.insert(list, string.sub(filename, 1, -5))
			end
		end
	else
	--Windows
		--Open directory look for files, loop through all files 
		for filename in io.popen('dir "'..STRUCTURES..'" /b'):lines() do
			if string.find(filename, ".mts", -4) ~= nil then
				table.insert(list, string.sub(filename, 1, -5))
			end
		end
	end
	for _, v in ipairs(list) do
		local split = string.split(v,"_")
		local xmin = tonumber(split[1])
		local ymin = tonumber(split[2])
		local zmin = tonumber(split[3])
		--print("x0 "..x0..", y0 "..y0..", z0 "..z0..", xmin "..xmin..", ymin "..ymin..", zmin "..zmin)
		if xmin >= x0 and xmin < x0 + sidelen and ymin >= y0 and ymin < y0 + sidelen and zmin >= z0 and zmin < z0 + sidelen then
			print("structure found for this chunk")
			table.insert(structures,{x=xmin,y=ymin,z=zmin,schemname=v})
		end
	end
	return structures
end

local function get_aspect(n, rad)
	local rise_xrun = ((n.c + 2 * n.f + n.i) - (n.a + 2 * n.d + n.g)) / 8
	local rise_zrun = ((n.g + 2 * n.h + n.i) - (n.a + 2 * n.b + n.c)) / 8
	local aspect
	if rise_xrun ~= 0 then 
		aspect = math.atan2(rise_zrun, - rise_xrun) * 180 / math.pi 
		if aspect < 0 then aspect = 2 * math.pi + aspect end
	else 
		if rise_zrun > 0 then aspect = math.pi / 2 
		elseif rise_zrun < 0 then aspect = 2 * math.pi - (math.pi/2)
		else aspect = 0 -- @todo not sure if this is actually 0
		end
	end
	if rad then return aspect 
	else	
		local cell
		if aspect < 0 then cell = 90.0 - aspect
		elseif aspect > 90.0 then
			cell = 360.0 - aspect + 90.0
		else
			cell = 90.0 - aspect
		end
		return math.floor(cell + 0.5)
	end
end

local function get_curvature(n)
	local curve
	--[[local A,B,C,D,E,F,G,H,I --terms for polynomial
	A = ((n.a + n.c + n.g + n.i) / 4  - (n.b + n.d + n.f + n.h) / 2 + n.e) -- / L^4 (cell size)
	B = ((n.a + n.c - n.g - n.i) /4 - (n.b - n.h) /2) -- / L^3
	C = ((-n.a + n.c - n.g + n.i) /4 + (n.d - n.f) /2) -- / L^3--]]
	local D = ((n.d + n.f) /2 - n.e) -- / L^2
	local E = ((n.b + n.h) /2 - n.e) -- / L^2
	--[[F = (-n.a + n.c + n.g - n.i) -- / 4L^2
	G = (-n.d + n.f) -- / 2^L
	H = (n.b - n.h) -- / 2^L
	I = n.e--]]
	curve = -2*(D + E) -- * 100
	return curve
end

-- this is not tested with offsets and scales but should work
local function get_distance(x,y,z, heightmap)
	local limit = realterrain.settings.dist_lim
	local dist_mode = realterrain.settings.dist_mode
	local shortest = limit
	local to_min = realterrain.settings.dist_to_min
	local to_max = realterrain.settings.dist_to_max
	--print("min: "..to_min..", max: "..to_max)
	--buid a square around the search pixel
	local c=0
	for j=z-limit, z+limit do
		for i=x-limit, x+limit do
			c = c +1
			local v, e
			if heightmap[j] and heightmap[j][i] and heightmap[j][i].input then
				v = heightmap[j][i].input
				if dist_mode == "3D" then
					e = heightmap[j][i].elev
				end
				if v and v >= to_min and v <= to_max then
					local distance
					if dist_mode == "2D" then
						distance = math.sqrt(((z-j)^2)+((x-i)^2))
					elseif dist_mode == "3D" then
						distance = math.sqrt(((z-j)^2)+((x-i)^2)+((y-e)^2))
					end
					
					--print("candidate: "..distance)
					if distance < shortest then
						shortest = distance
						--print("shorter found: "..shortest)
					end
				end
			end
		end
	end
	--print(c)
	--print("distance: "..shortest)
	return shortest
end

local function get_slope(n, rad)
	--print(dump(n))
	local x_cellsize, z_cellsize = 1, 1
	local rise_xrun = ((n.c + 2 * n.f + n.i) - (n.a + 2 * n.d + n.g)) / (8 * x_cellsize)
	local rise_zrun = ((n.g + 2 * n.h + n.i) - (n.a + 2 * n.b + n.c)) / (8 * z_cellsize)
	local rise_xzrun = math.sqrt( rise_xrun ^ 2 + rise_zrun ^ 2 )
	if rad then return rise_xzrun end
	local degrees = math.atan(rise_xzrun) * 180 / math.pi
	return math.floor(degrees + 0.5)
end

local surface_cache = {} --used to prevent reading of DEM for skyblocks

function realterrain.generate(minp, maxp)
	local t0 = os.clock()
	local x1 = maxp.x
	local y1 = maxp.y
	local z1 = maxp.z

	local x0 = minp.x
	local y0 = minp.y
	local z0 = minp.z
	local treemap = {}
	local fillmap = {}
	--print("x0:"..x0..",y0:"..y0..",z0:"..z0..";x1:"..x1..",y1:"..y1..",z1:"..z1)
	
	local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
	local area = VoxelArea:new{MinEdge=emin, MaxEdge=emax}
	local data = vm:get_data()
	
	local sidelen = x1 - x0 + 1
	local ystridevm = area.ystride

	--calculate the chunk coordinates
	local cx0 = math.ceil(x0 / sidelen)
	local cy0 = math.ceil(y0 / sidelen)
	local cz0 = math.ceil(z0 / sidelen) 
	
	local mode = realterrain.get_mode()
	local modename = mode.name
	
	--check to see if the current chunk is above (or below) the elevation range for this footprint
	if surface_cache[cz0] and surface_cache[cz0][cx0] then
		if surface_cache[cz0][cx0].offelev then
			local chugent = math.ceil((os.clock() - t0) * 1000)
			print ("[OFF] "..chugent.." ms  mapchunk ("..cx0..", "..cy0..", "..cz0..")")
			return
		end
		if y0 >= surface_cache[cz0][cx0].maxelev then
			local chugent = math.ceil((os.clock() - t0) * 1000)
			print ("[SKY] "..chugent.." ms  mapchunk ("..cx0..", "..cy0..", "..cz0..")")
			vm:set_data(data)
			vm:calc_lighting()
			vm:write_to_map(data)
			vm:update_liquids()
			return
		end
		if mode.name ~= "normal" and y1 <= surface_cache[cz0][cx0].minelev then
			local chugent = math.ceil((os.clock() - t0) * 1000)
			print ("[SUB] "..chugent.." ms  mapchunk ("..cx0..", "..cy0..", "..cz0..")")
			return
		end
	end
	
	local buffer = mode.buffer or 0
	local computed = mode.computed
	local get_cover = mode.get_cover
	local get_input = mode.get_input
	local get_input2 = mode.get_input2
	local get_input3 = mode.get_input3
	local get_input_color = mode.get_input_color
	local fill_below = mode.fill_below
	local moving_window = mode.moving_window
	--build the heightmap and include different extents and values depending on mode
	local heightmap = realterrain.build_heightmap(x0-buffer, x1+buffer, z0-buffer, z1+buffer)
	--calculate the min and max elevations for skipping certain blocks completely
	local minelev, maxelev
	for z=z0, z1 do
		for x=x0, x1 do
			local elev
			if heightmap[z] and heightmap[z][x] then
				elev = heightmap[z][x].elev
				if elev then
					if not minelev then
						minelev = elev
						maxelev = elev
					else
						if elev < minelev then
							minelev = elev
						end
						if elev > maxelev then
							maxelev = elev
						end
					end
					--when comparing two elevs we need both of their min/max elevs
					if modename == "elevchange" then
						local elev
						elev = heightmap[z][x].input
						if elev then
							if not minelev then
								minelev = elev
								maxelev = elev
							else
								if elev < minelev then
									minelev = elev
								end
								if elev > maxelev then
									maxelev = elev
								end
							end
						end
					end
				end
			end
		end
	end
	--making distance more efficient
	local input_present = false
	if modename == "distance" then
		for z,v1 in pairs(heightmap) do
			for x in pairs(v1) do
				if not input_present and heightmap[z][x].input and heightmap[z][x].input > 0 then
					input_present = true
				end
			end
		end
	end
	-- if there were elevations in this footprint then add the min and max to the cache table if not already there
	if minelev then
		--print("minelev: "..minelev..", maxelev: "..maxelev)
		if not surface_cache[cz0] then
			surface_cache[cz0] = {}
		end
		if not surface_cache[cz0][cx0] then
			surface_cache[cz0][cx0] = {minelev = minelev, maxelev=maxelev}
		end
	else
		--otherwise this chunk was off the DEM raster
		if not surface_cache[cz0] then
			surface_cache[cz0] = {}
		end
		if not surface_cache[cz0][cx0] then
			surface_cache[cz0][cx0] = {offelev=true}
		end
		local chugent = math.ceil((os.clock() - t0) * 1000)
		print ("[OFF] "..chugent.." ms  mapchunk ("..cx0..", "..cy0..", "..cz0..")")
		return
	end
	--print(dump(heightmap))
	if not cids then
		build_cids()
	end
	--print(dump(cids))
	local c_dirt_with_grass = minetest.get_content_id("default:dirt_with_grass")
	local c_dirt_with_dry_grass = minetest.get_content_id("default:dirt_with_dry_grass")
	local c_dirt_with_snow = minetest.get_content_id("default:dirt_with_snow")
	local c_stone = minetest.get_content_id("default:stone")
	local c_dirt = minetest.get_content_id("default:dirt")
	
	--generate!
	for z = z0, z1 do
	for x = x0, x1 do
		if heightmap[z] and heightmap[z][x] and heightmap[z][x]["elev"] then
			--get the height needed to fill_below in surface mode
			local height
			if fill_below then
				height = height_fill_below(x,z,heightmap)
			end
			if not computed then
				--modes that use biomes:
				if get_cover then
					local elev = heightmap[z][x].elev -- elevation in meters from DEM and water true/false
					local cover = heightmap[z][x].cover
					local cover2, elev2
					--print(cover)
					if not cover or cover < 1 then
						cover = 0
					else
						cover = tonumber(string.sub(tostring(cover),1,1))
					end
					if modename == "elevchange" then
						elev2 = heightmap[z][x].input
					end
					if modename == "coverchange" then
						cover2 = heightmap[z][x].input
						if not cover2 or cover2 < 1 then
							cover2 = 0
						else
							cover2 = tonumber(string.sub(tostring(cover2),1,1))
						end
					end
					--print("elev: "..elev..", cover: "..cover)
					
					local ground, ground2, gprob, tree, tprob, tree2, tprob2, shrub, sprob, shrub2, sprob2
					
					ground = cids[cover].ground
					ground2 = cids[cover].ground2
					gprob = tonumber(realterrain.get_setting("b"..cover.."gprob"))
					tree = realterrain.get_setting("b"..cover.."tree")
					tprob = tonumber(realterrain.get_setting("b"..cover.."tprob"))
					tree2 = realterrain.get_setting("b"..cover.."tree2")
					tprob2 = tonumber(realterrain.get_setting("b"..cover.."tprob2"))
					shrub = cids[cover].shrub
					sprob = tonumber(realterrain.get_setting("b"..cover.."sprob"))
					shrub2 =cids[cover].shrub2
					sprob2 = tonumber(realterrain.get_setting("b"..cover.."sprob2")) 
					--[[if tree then print("cover: "..cover..", ground: "..ground..", tree: "..tree..", tprob: "..tprob..", shrub: "..shrub..", sprob: "..sprob)
					else print("cover: "..cover..", ground: "..ground..", tprob: "..tprob..", shrub: "..shrub..", sprob: "..sprob)
					end]]
					local vi = area:index(x, y0, z) -- voxelmanip index	
					for y = y0, y1 do
						--underground layers
						if y < elev and (mode.name == "normal") then 
							--create strata of stone, cobble, gravel, sand, coal, iron ore, etc
							if y < elev-(math.random(10,15)) then
								data[vi] = c_stone
							else
								--dirt with grass and dry grass fix
								if ( ground == c_dirt_with_grass or ground == c_dirt_with_dry_grass or ground == c_dirt_with_snow ) then
									data[vi] = c_dirt
								else
									data[vi] = ground
								end
							end
						--the surface layer, determined by cover value
						elseif  y == elev
						and ( cover ~= 5 or modename == "elevchange" or modename == "coverchange" or modename =="surface")
						or (y < elev and y >= (elev - height) and fill_below) then
							if modename == "coverchange" and cover2 and cover ~= cover2 then
								--print("cover1: "..cover..", cover2: "..cover2)
								data[vi] = cids["symbol10"]
							elseif modename == "elevchange"	and elev2 and (elev ~= elev2) then
								local diff = elev2 - elev
								if diff < 0 then
									color = "symbol10"
								else
									color = "symbol1"
								end
								data[vi] = cids[color]						
							elseif y < tonumber(realterrain.settings.waterlevel) then
								data[vi] = cids["water_bottom"]
							--alpine level
							elseif y > tonumber(realterrain.settings.alpinelevel) + math.random(1,5) then 
								data[vi] = cids["alpine"]
							--default
							else
								--print("ground2: "..ground2..", gprob: "..gprob)
								if gprob and gprob > 0 and ground2 and math.random(0,100) <= gprob then
									data[vi] = ground2
								else
									data[vi] = ground
								end
								if y < elev
								and ( data[vi] == c_dirt_with_grass or data[vi] == c_dirt_with_dry_grass or data[vi] == c_dirt_with_snow ) then
									data[vi] = cids["dirt"]
								end
							end
						--shrubs and trees one block above the ground
						elseif y == elev + 1 then
							if sprob > 0 and shrub and math.random(0,100) <= sprob then
								if sprob2 and sprob2 > 0 and shrub2 and math.random(0,100) <= sprob2 then
									data[vi] = shrub2
								else
									data[vi] = shrub
								end
							elseif tprob > 0 and tree and y < tonumber(realterrain.settings.alpinelevel) + math.random(1,5) and math.random(0,100) <= tprob then
								if tprob2 and tprob2 > 0 and tree2 and math.random(0,100) <= tprob2 then
									table.insert(treemap, {pos={x=x,y=y,z=z}, type=tree2})
								else
									table.insert(treemap, {pos={x=x,y=y,z=z}, type=tree})
								end
							end
						elseif y <= tonumber(realterrain.settings.waterlevel) then
							data[vi] = cids["water"] --normal minetest water source
						end
						vi = vi + ystridevm
					end --end y iteration
				else --raster output mode implied if cover is not set
					local vi = area:index(x, y0, z) -- voxelmanip index
					for y = y0, y1 do
						local elev
						elev = heightmap[z][x].elev
						if y == elev or (y < elev and y >= (elev - height) and fill_below) then
							local neighbors = {}
							local edge_case = false
							--moving window mode.names need neighborhood built
							if moving_window then
								neighbors["e"] = y
								for dir, offset in pairs(neighborhood) do
									--get elev for all surrounding nodes
									local nelev
									if heightmap[z+offset.z] and heightmap[z+offset.z][x+offset.x]then
										nelev = heightmap[z+offset.z][x+offset.x].elev
									end
									if nelev then
										neighbors[dir] = nelev
									else --edge case, need to abandon this pixel for slope
										edge_case = true
										--print("edgecase")
									end
								end
							end
							if not edge_case then
								local color
								if modename == "elevation" then
									if elev < 10 then color = "symbol1"
									elseif elev < 20 then color = "symbol2"
									elseif elev < 50 then color = "symbol3"
									elseif elev < 100 then color = "symbol4"
									elseif elev < 150 then color = "symbol5"
									elseif elev < 200 then color = "symbol6"
									elseif elev < 300 then color = "symbol7"
									elseif elev < 450 then color = "symbol8"
									elseif elev < 600 then color = "symbol9"
									elseif elev >= 600 then color = "symbol10" end
									--print("elev: "..elev)
									data[vi] = cids[color]				
								elseif modename == "slope" then
									local slope = get_slope(neighbors)
									if slope < 1 then color = "symbol1"
									elseif slope < 2 then color = "symbol2"
									elseif slope < 5 then color = "symbol3"
									elseif slope < 10 then color = "symbol4"
									elseif slope < 15 then color = "symbol5"
									elseif slope < 20 then color = "symbol6"
									elseif slope < 30 then color = "symbol7"
									elseif slope < 45 then color = "symbol8"
									elseif slope < 60 then color = "symbol9"
									elseif slope >= 60 then color = "symbol10" end
									--print("slope: "..slope)
									data[vi] = cids[color]							
								elseif modename == "aspect" then
									local aspect = get_aspect(neighbors)
									local slice = 22.5
									if aspect > 360 - slice or aspect <= slice then color = "aspect1"
									elseif aspect <= slice * 3 then color = "aspect2"
									elseif aspect <= slice * 5 then color = "aspect3"
									elseif aspect <= slice * 7 then color = "aspect4"
									elseif aspect <= slice * 9 then color = "aspect5"
									elseif aspect <= slice * 11 then color = "aspect6"
									elseif aspect <= slice * 13 then color = "aspect7"
									elseif aspect <= slice * 15 then color = "aspect8" end
									--print(aspect..":"..color)
									data[vi] = cids[color]
								elseif modename == "curvature" then
									local curve = get_curvature(neighbors)
									--print("raw curvature: "..curve)
									if curve < -4 then color = "symbol1"
									elseif curve < -3 then color = "symbol2"
									elseif curve < -2 then color = "symbol3"
									elseif curve < -1 then color = "symbol4"
									elseif curve < 0 then color = "symbol5"
									elseif curve > 4 then color = "symbol10"
									elseif curve > 3 then color = "symbol9"
									elseif curve > 2 then color = "symbol8"
									elseif curve > 1 then color = "symbol7"
									elseif curve >= 0 then color = "symbol6" end
									data[vi] = cids[color]
								elseif modename == "distance" then
									local limit = realterrain.settings.dist_lim
									--if there is no input present in the full search extent skip
									if input_present then 
										local distance = get_distance(x,y,z, heightmap)
										if distance < (limit/10) then color = "symbol1"
										elseif distance < (limit/10)*2 then color = "symbol2"
										elseif distance < (limit/10)*3 then color = "symbol3"
										elseif distance < (limit/10)*4 then color = "symbol4"
										elseif distance < (limit/10)*5 then color = "symbol5"
										elseif distance < (limit/10)*6 then color = "symbol6"
										elseif distance < (limit/10)*7 then color = "symbol7"
										elseif distance < (limit/10)*8 then color = "symbol8"
										elseif distance < (limit/10)*9 then color = "symbol9"
										else color = "symbol10"
										end
									else
										color = "symbol10"
									end
									data[vi] = cids[color]
								elseif (modename == "imageoverlay" and heightmap[z][x].input)
									or (mode.name == "bandoverlay" and heightmap[z][x].input and heightmap[z][x].input2 and heightmap[z][x].input3) then
									local input = heightmap[z][x].input
									local input2 = heightmap[z][x].input2
									local input3 = heightmap[z][x].input3
									local color1 = math.floor( ( input / 255 ) * 5 + 0.5) * 51
									local color2 = math.floor( ( input2 / 255 ) * 5 + 0.5) * 51
									local color3 = math.floor( ( input3 / 255 ) * 5 + 0.5) * 51
									--print("r: "..color1..", g: "..color2..", b: "..color3)
									color1 = string.format("%x", color1)
									if color1 == "0" then color1 = "00" end
									color2 = string.format("%x", color2)
									if color2 == "0" then color2 = "00" end
									color3 = string.format("%x", color3)
									if color3 == "0" then color3 = "00" end
									color = color1..color2..color3
									data[vi] = cids[color]
								end
							end
						end
						vi = vi + ystridevm
					end -- end y iteration
				end --end mode options for non-computed modes
			else --computed mode implied
				local vi = area:index(x, y0, z) -- voxelmanip index
				for y = y0, y1 do
					local elev = heightmap[z][x].elev
					-- print at y = 0 for now, if we change this then get_surface needs to be updated
					if y == 0 and modename == "mandelbrot" then
						if elev < 1 then color = "symbol1"
						elseif elev < 2 then color = "symbol2"
						elseif elev < 3 then color = "symbol3"
						elseif elev < 5 then color = "symbol4"
						elseif elev < 8 then color = "symbol5"
						elseif elev < 13 then color = "symbol6"
						elseif elev < 21 then color = "symbol7"
						elseif elev < 34 then color = "symbol8"
						elseif elev < 55 then color = "symbol9"
						elseif elev < 256 then color = "symbol10"
						else color = "000000"
						end
						data[vi] = cids[color]
					elseif modename == "polynomial"
					and (y == elev or (y < elev and y >= (elev - height) and fill_below) ) then
						
						--dirt with cover fix
						local ground = cids[0].ground
						if y < elev
						and ( ground == c_dirt_with_grass or ground == c_dirt_with_dry_grass or ground == c_dirt_with_snow ) then
							data[vi] = cids["dirt"]
						else
							data[vi] = ground
						end
					end
					vi = vi + ystridevm
				end --end y iteration
			end --end modes
		end --end if pixel is in heightmap
	end
	end
	-- public function made by the default mod, to register ores and blobs
	if default then
		if default.register_ores then
			default.register_ores()
		end
		if default.register_blobs then
			default.register_blobs()
		end
	end
	vm:set_data(data)
	minetest.generate_ores(vm, minp, maxp)
	vm:calc_lighting()
	vm:write_to_map(data)
	vm:update_liquids()
	
	--place all the trees (schems assumed to be 7x7 bases with tree in center)
	for _, tree in ipairs(treemap) do
		minetest.place_schematic({x=tree.pos.x-3,y=tree.pos.y,z=tree.pos.z-3}, SCHEMS..tree.type..".mts", (math.floor(math.random(0,3)) * 90), nil, false)
	end
	
	--place all structures whose pmin are in this chunk
	local structures = get_structures_for_chunk(x0,y0,z0, sidelen)
	for _, str in ipairs(structures) do
		minetest.place_schematic({x=str.x,y=str.y,z=str.z}, STRUCTURES..str.schemname..".mts")
	end
	
	local chugent = math.ceil((os.clock() - t0) * 1000)
	print ("[GEN] "..chugent.." ms  mapchunk ("..cx0..", "..cy0..", "..cz0..")")
end
