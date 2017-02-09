local RASTERS = realterrain.rasters
local PROCESSOR = realterrain.processor
local py = realterrain.py

--the raw get pixel method that uses the selected method and accounts for bit depth
local function get_raw_pixel(x,z, rastername) -- "rastername" is a string
	--print("x: "..x.." z: "..z..", rastername: "..rastername)
	local raster = realterrain[rastername]
	local colstart, rowstart = 0,0
	if PROCESSOR == "native" and raster.format == "bmp" then
		x=x+1
		z=z-1
		colstart = 1
		rowstart = -1
	end
	
	z = -z
	local r,g,b
	local width, length
	width = raster.width
	length = raster.length
	--check to see if the image is even on the raster, otherwise skip
	if width and length and ( x >= rowstart and x <= width ) and ( z >= colstart and z <= length ) then
		--print(rastername..": x "..x..", z "..z)
		if PROCESSOR == "native" then
			if raster.format == "bmp" then
				local bitmap = raster.image
				local c
				if bitmap.pixels[z] and bitmap.pixels[z][x] then
					c = bitmap.pixels[z][x]
					r = c.r
					g = c.g
					b = c.b
					--print("r: ".. r..", g: "..g..", b: "..b)
				end
			elseif raster.format == "png" then
				local bitmap = raster.image
				local c
				if bitmap.pixels[z] and bitmap.pixels[z][x] then
					c = bitmap.pixels[z][x]
					r = c.r
					g = c.g
					b = c.b
				end
			elseif raster.format == "tiff" then
				local file = raster.image
				if not file then
					print("tiff mode problem retrieving file handle")
				end
				--print(file)
				if x < 0 or z < 0 or x >= width or z >= length then return end
				if raster.bits == 8 then
					file:seek("set", ((z) * width) + x + 8)
					r = file:read(1)
					if r then
						r = r:byte()
						
						r = tonumber(r)
						--print(r)
					else
						print(rastername..": nil value encountered at x: "..x..", z: "..z)
						r = nil
					end
				else
					file:seek("set", ((z) * width * 2) + (x*2) + 11082) -- + 11082 cleans up the dem16.tif raster,
					local r1 = file:read(1)
					local r2 = file:read(1)
					if r1 and r2 then
						r = tonumber(r1:byte()) + tonumber(r2:byte())*256 --might be *256 the wrong byte
						--print(r)
					else
						print(rastername..": one of two bytes is nil")
					end
				end
			end
		elseif PROCESSOR == "py" then
			if raster.mode == "RGB" then
				py.execute(rastername.."_r, "..rastername.."_g,"..rastername.."_b = "..rastername.."_pixels["..x..", "..z.."]")
				r = tonumber(tostring(py.eval(rastername.."_r")))
				g = tonumber(tostring(py.eval(rastername.."_g")))
				b = tonumber(tostring(py.eval(rastername.."_b")))
			else
				r = tonumber(tostring(py.eval(rastername.."_pixels["..x..","..z.."]"))) --no bit depth conversion required
			end
			--print(r)
		else
			if raster.image then
				if PROCESSOR == "magick" then
					r,g,b = raster.image:get_pixel(x, z) --@todo change when magick autodetects bit depth
					--print(rastername.." raw r: "..r..", g: "..g..", b: "..b..", a: "..a)
					r = math.floor(r * (2^raster.bits))
					g = math.floor(g * (2^raster.bits))
					b = math.floor(b * (2^raster.bits))
				elseif PROCESSOR == "imlib2" then
					r = raster.image:get_pixel(x, z).red
					g = raster.image:get_pixel(x, z).green
					b = raster.image:get_pixel(x, z).blue
				end
			end
		end
		--print (v)
		return r,g,b
	end
end

local function get_brot_pixel(x,z)
	--taken from https://plus.maths.org/content/computing-mandelbrot-set
	--Where do we want to center the brot?
	local cx = realterrain.settings.xoffset
	local cz = realterrain.settings.zoffset
	--This is the "zoom" factor.
	local xscale = realterrain.settings.xscale
	local zscale = realterrain.settings.zscale
	local limit = 4		--Divergence check value.
	local lp = 0		--Convergence check value.
	local a1,b1,a2,b2 	--For calculating the iterations.
	local ax,az 		--The actual position of (x,z) in relation to the Mandelbrot set.
	--What is the *mathematical* value of this point?
	ax=cx+x*xscale
	az=cz+z*zscale
	--And now for the magic formula!
	a1=ax
	b1=az
	--The first condition is satisfied if we have convergence. The second is satisfied if we have divergence.
	while (lp<=255) and ((a1*a1)+(b1*b1)<=limit) do
		--Do one iteration
		lp=lp+1
		a2=a1*a1-b1*b1+ax
		b2=2*a1*b1+az
		--This is indeed the square of a+bi, done component-wise.
		a1=a2
		b1=b2
	end
	if lp > 256 then print(">256:"..lp) end
	return lp
end

local function polynomial(x,z)
	local a,b,c,d,e,f,g,h
	a = realterrain.settings.polya
	b = realterrain.settings.polyb
	c = realterrain.settings.polyc
	d = realterrain.settings.polyd
	e = realterrain.settings.polye
	f = realterrain.settings.polyf
	g = realterrain.settings.polyg
	h = realterrain.settings.polyh
	
	local value = (a*(x^2)*(z^2))+(b*(x^2)*(z))+(c*(x)*(z^2))+(d*(x^2))+(e*(z^2))+(f*(x))+(g*(z))+h
	--print(value)
	return math.floor(value)
end

--this function parses a line of IM or GM pixel enumeration without any scaling or adjustment
local function parse_enumeration(line, get_rgb)
	local value
	if line then
		--print("enumeration line: "..line)
		--parse the output pixels
		local firstcomma = string.find(line, ",")
		--print("first comma: "..firstcomma)
		local right = tonumber(string.sub(line, 1 , firstcomma - 1)) + 1
		--print("right: "..right)
		local firstcolon = string.find(line, ":")
		--print("first colon: "..firstcolon)
		local down = tonumber(string.sub(line, firstcomma + 1 , firstcolon - 1))
		--print("down: "..down)
		local secondcomma
		local firstpercent = string.find(line, "%%")
		-- if a percent is found then we know we are using IM convert and it is a 16bit value
		if firstpercent then
			value = tonumber(string.sub(line, firstcolon + 3, firstpercent -1))
			--print("value: "..value)
			value = value / 100 * (2^16)
		else
			secondcomma = string.find(line, ",", firstcolon)
			value = tonumber(string.sub(line, firstcolon + 3, secondcomma -1))
		end
		--get the blue and green channel as well if requested
		if get_rgb then
			local r,g,b
			r = value
			--print("r: "..r)
			local thirdcomma = string.find(line, ",", secondcomma+1)
			local closeparenthesis = string.find(line, ")")
			local percent_or_not = 1
			if firstpercent then percent_or_not = 2 end
			g = tonumber(string.sub(line, secondcomma+1, thirdcomma - percent_or_not))
			--print("g: "..g)
			b = tonumber(string.sub(line, thirdcomma+1, closeparenthesis - percent_or_not))
			--print("b: "..b)
			value = {r=r,g=g,b=b}
		end
		return value, right, down
	else
		--print("no line")
		return false
		
	end
end

local function get_enumeration(rastername, firstcol, width, firstrow, length)
	--print(rastername)
	local raster = realterrain[rastername]
	local table_enum = {}
	local enumeration
	if PROCESSOR == "gm" then
		enumeration = raster.image:clone():crop(width,length,firstcol,firstrow):format("txt"):toString()
		table_enum = string.split(enumeration, "\n")
	elseif PROCESSOR == "magick" then
		local tmpimg
		tmpimg = raster.image:clone()
		tmpimg:crop(width,length,firstcol,firstrow)
		tmpimg:set_format("txt")
		enumeration = tmpimg:get_blob()
		tmpimg:destroy()
		table_enum = string.split(enumeration, "\n")
	elseif PROCESSOR == "convert" then
		local cmd = CONVERT..' "'..RASTERS..realterrain.settings["file"..rastername]..'"'..
			' -crop '..width..'x'..length..'+'..firstcol..'+'..firstrow..' txt:-'
		enumeration = io.popen(cmd)
		--print(cmd)
		for line in enumeration:lines() do
			table.insert(table_enum, line)
		end
	end
	return table_enum
end

--main function that builds a heightmap using the various processors' methods available
function realterrain.build_heightmap(x0, x1, z0, z1)
	local mode = realterrain.get_mode()
	local modename = mode.name
	local heightmap = {}
	local xscale = realterrain.settings.xscale
	local zscale = realterrain.settings.zscale
	local xoffset = realterrain.settings.xoffset 
	local zoffset = realterrain.settings.zoffset 
	local yscale = realterrain.settings.yscale
	local yoffset = realterrain.settings.yoffset
	local scaled_x0 = math.floor(x0/xscale+xoffset+0.5)
	local scaled_x1 = math.floor(x1/xscale+xoffset+0.5)
	local scaled_z0 = math.floor(z0/zscale+zoffset+0.5)
	local scaled_z1 = math.floor(z1/zscale+zoffset+0.5)
	
	if not mode.computed then
		local rasternames = {}
		if realterrain.settings.fileelev ~= "" then table.insert(rasternames, "elev") end
		if mode.get_cover  and realterrain.settings.filecover ~= "" then table.insert(rasternames, "cover")	end
		if mode.get_input and realterrain.settings.fileinput ~= "" then	table.insert(rasternames, "input") end
		if mode.get_input2  and realterrain.settings.fileinput2 ~= "" then table.insert(rasternames, "input2") end
		if mode.get_input3  and realterrain.settings.fileinput3 ~= "" then table.insert(rasternames, "input3") end
		
		for _, rastername in ipairs(rasternames) do
			local raster = realterrain[rastername]
			--see if we are even on the raster or that there is a raster
			if( not realterrain.settings["file"..rastername]
			or (scaled_x1 < 0)
			or (scaled_x0 > raster.width)
			or (scaled_z0 > 0)
			or (-scaled_z1 > raster.length)) then
				--print("off raster request: scaled_x0: "..scaled_x0.." scaled_x1: "..scaled_x1.." scaled_z0: "..scaled_z0.." scaled_z1: "..scaled_z1)
				return heightmap
			end
			
			--processors that require enumeration parsing rather than pixel-access
			if PROCESSOR == "gm"
			or PROCESSOR == "convert"
			or (PROCESSOR == "magick" and MAGICK_AS_CONVERT) then
				local pixels = {}
				--convert map pixels to raster pixels
				local cropstartx = scaled_x0
				local cropendx = scaled_x1
				local cropstartz = -scaled_z1
				local cropendz = -scaled_z0
				local empty_cols = 0
				local empty_rows = 0
				--don't request pixels to the left or above the raster, count how many we were off if we were going to
				if scaled_x0 < 0 then
					empty_cols = - scaled_x0
					cropstartx = 0
				end
				if scaled_z1 > 0 then
					empty_rows = scaled_z1
					cropstartz = 0
				end
				--don't request pixels beyond maxrows or maxcols in the raster  --@todo this doesn't account for scaling, offsets
				if scaled_x1 > raster.width then cropendx = raster.width end
				if -scaled_z0 > raster.length then cropendz = raster.length end
				local cropwidth = cropendx-cropstartx+1
				local croplength = cropendz-cropstartz+1	
				
				--print(rastername..": offcrop cols: "..empty_cols..", rows: "..empty_rows)
				--print(rastername.." request range: x:"..x0..","..x1.."; z:"..z0..","..z1)
				--print(rastername.." request entries: "..(x1-x0+1)*(z1-z0+1))
				local enumeration = get_enumeration(rastername, cropstartx, cropwidth, cropstartz, croplength)
				
				--print(dump(enumeration))
				
				local entries = 0
				
				local mincol, maxcol, minrow, maxrow
				local firstline = true
				--build the pixel table from the enumeration
				for _, line in ipairs(enumeration) do                         
					if firstline and (PROCESSOR == "magick" or (PROCESSOR == "convert" and string.sub(CONVERT, 1, 2) ~= "gm" )) then
						firstline = false --first line is a header in IM but not GM
						--and do nothing
					else
						entries = entries + 1
						--print(entries .." :: " .. v)
						
						local value, right, down
						if rastername == "input" and mode.get_input_color then
							value,right,down = parse_enumeration(line, true)
						else
							value,right,down = parse_enumeration(line)
							
						end	
						
						-- for elevation layers apply vertical scale and offset
						if rastername == "elev" then
							value = math.floor((value * realterrain.settings.yscale) + realterrain.settings.yoffset)
						end
						--convert the cropped pixel row/column back to absolute map x,z
						if not pixels[-down] then pixels[-down] = {} end
						pixels[-down][right] = value
					end-- firstline test
				end--end for enumeration line
				--now we have to build the heightmap from the pixel table
				for z=z0, z1 do
					for x=x0,x1 do
					
						if not heightmap[z] then heightmap[z] = {} end
						if not heightmap[z][x] then heightmap[z][x] = {} end
						--here is the tricky part, requesting the correct pixel for this x,z map coordinate
						local newz = math.floor(z/zscale+zoffset+0.5)-scaled_z1 + empty_rows
						local newx = math.floor(x/xscale+xoffset+0.5)-scaled_x0 - empty_cols +1 --@todo should 1 be scaled?
						if pixels[newz] and pixels[newz][newx] then
							if rastername == "input" and mode.get_input_color then
								heightmap[z][x]["input"] = pixels[newz][newx].r
								heightmap[z][x]["input2"] = pixels[newz][newx].g
								heightmap[z][x]["input3"] = pixels[newz][newx].b
							else
								heightmap[z][x][rastername] = pixels[newz][newx]
							end
						end
					end
				end
				if entries > 0 then
					--print(rastername.." result range: x:"..mincol..","..maxcol.."; z:"..minrow..","..maxrow)
				end
				--print(rastername.." result entries: "..entries)
			
			else --processors that require pixel-access instead of enumeration parsing
				--local colstart, colend, rowstart, rowend = scaled_x0,scaled_x1,scaled_z0,scaled_z1
				local colstart, colend, rowstart, rowend = x0,x1,z0,z1
				for z=rowstart,rowend do
					if not heightmap[z] then heightmap[z] = {} end
					for x=colstart,colend do
						local scaled_x = math.floor(x/xscale+xoffset+0.5)
						local scaled_z = math.floor(z/zscale+zoffset+0.5)
						if not heightmap[z][x] then heightmap[z][x] = {} end
						if rastername == "input" and mode.get_input_color then
							heightmap[z][x]["input"], heightmap[z][x]["input2"], heightmap[z][x]["input3"]
								= get_raw_pixel(scaled_x,scaled_z, "input")
						else
							if rastername == "elev" or (modename == "elevchange" and rastername == "input") then
								local value = get_raw_pixel(scaled_x,scaled_z, "elev")
								if value then
									heightmap[z][x][rastername] = math.floor(value*yscale+yoffset+0.5)
								end
							else
								heightmap[z][x][rastername] = get_raw_pixel(scaled_x,scaled_z, rastername)
							end
						end
					end
				end
			end --end processor decisions
		end	--end for rasternames
	elseif mode.computed then
		for z=z0,z1 do
			if not heightmap[z] then heightmap[z] = {} end
			for x=x0,x1 do
				if not heightmap[z][x] then heightmap[z][x] = {} end
				if modename == "mandelbrot" then
					heightmap[z][x]["elev"] = get_brot_pixel(x,z)
				elseif modename == "polynomial" then
					heightmap[z][x]["elev"] = polynomial(x,z)
				end
			end
		end
	end --end if computed
	return heightmap
end

--after the mapgen has run, this gets the surface level
function realterrain.get_surface(x,z)
	local heightmap = realterrain.build_heightmap(x,x,z,z)
	if heightmap[z] and heightmap[z][x] and heightmap[z][x]["elev"] then
		return heightmap[z][x]["elev"]
	end
end
