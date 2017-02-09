local WORLDPATH = realterrain.worldpath

realterrain.settings = {}
local validate = {}
--defaults
realterrain.settings.output = "normal"
realterrain.settings.yscale = 1
validate.yscale = "number"
realterrain.settings.xscale = 1
validate.xscale = "number"
realterrain.settings.zscale = 1
validate.zscale = "number"
realterrain.settings.yoffset = 0
validate.yoffset = "number"
realterrain.settings.xoffset = 0
validate.xoffset = "number"
realterrain.settings.zoffset = 0
validate.zoffset = "number"
realterrain.settings.waterlevel = 0
validate.waterlevel = "number"
realterrain.settings.alpinelevel = 1000
validate.alpinelevel = "number"

realterrain.settings.fileelev = 'dem.bmp'
realterrain.settings.elevbits = 8
validate.elevbits = "number"
realterrain.settings.filecover = 'biomes.bmp'
realterrain.settings.coverbits = 8
validate.coverbits = "number"

realterrain.settings.fileinput = ''
realterrain.settings.inputbits = 8
validate.inputbits = "number"
realterrain.settings.fileinput2 = ''
realterrain.settings.input2bits = 8
validate.input2bits = "number"
realterrain.settings.fileinput3 = ''
realterrain.settings.input3bits = 8
validate.input3bits = "number"

realterrain.settings.dist_lim = 40
validate.dist_lim = "number"
realterrain.settings.dist_mode = "3D" --3D or 3Dp
realterrain.settings.dist_to_min = 1
validate.dist_to_min = "number"
realterrain.settings.dist_to_max = 255
validate.dist_to_max = "number"


realterrain.settings.polya = 0.00001
validate.polya = "number"
realterrain.settings.polyb = 0.001
validate.polyb = "number"
realterrain.settings.polyc = 0.001
validate.polyc = "number"
realterrain.settings.polyd = 0.01
validate.polyd = "number"
realterrain.settings.polye = 0.01
validate.polye = "number"
realterrain.settings.polyf = 0
validate.polyf = "number"
realterrain.settings.polyg = 0
validate.polyg = "number"
realterrain.settings.polyh = 0
validate.polyh = "number"

--default cover (no cover)
realterrain.settings.b0ground = "default:dirt_with_dry_grass"
realterrain.settings.b0ground2 = "default:sand"
realterrain.settings.b0gprob = 10
validate.b0gprob = "number"
realterrain.settings.b0tree = "tree"
realterrain.settings.b0tprob = 0.1
validate.b0tprob = "number"
realterrain.settings.b0tree2 = "jungletree"
realterrain.settings.b0tprob2 = 30
validate.v0tprob2 = "number"
realterrain.settings.b0shrub = "default:dry_grass_1"
realterrain.settings.b0sprob = 3
validate.b0sprob = "number"
realterrain.settings.b0shrub2 = "default:dry_shrub"
realterrain.settings.b0sprob2 = 20
validate.b0sprob2 = "number"

--USGS tier 1 landcover: 1 - URBAN or BUILT-UP
realterrain.settings.b1ground = "default:cobble"
realterrain.settings.b1ground2 = "default:cobble"
realterrain.settings.b1gprob = 0
validate.b1gprob = "number"
realterrain.settings.b1tree = ""
realterrain.settings.b1tprob = 0
validate.b1tprob = "number"
realterrain.settings.b1tree2 = ""
realterrain.settings.b1tprob2 = 0
validate.b1tprob2 = "number"
realterrain.settings.b1shrub = "default:grass_1"
realterrain.settings.b1sprob = 0
validate.b1sprob = "number"
realterrain.settings.b1shrub2 = "default:grass_1"
realterrain.settings.b1sprob2 = 0
validate.b1sprob2 = "number"

--USGS tier 1 landcover: 2 - AGRICULTURAL
realterrain.settings.b2ground = "default:dirt_with_grass"
realterrain.settings.b2ground2 = "default:dirt_with_dry_grass"
realterrain.settings.b2gprob = 10
validate.b2gprob = "number"
realterrain.settings.b2tree = ""
realterrain.settings.b2tprob = 0
validate.b2tprob = "number"
realterrain.settings.b2tree2 = ""
realterrain.settings.b2tprob2 = 0
validate.b2tprob = "number"
realterrain.settings.b2shrub = "default:grass_1"
realterrain.settings.b2sprob = 10
validate.b2sprob = "number"
realterrain.settings.b2shrub2 = "default:dry_grass_1"
realterrain.settings.b2sprob2 = 50
validate.b2sprob2 = "number"

--USGS tier 1 landcover: 3 - RANGELAND
realterrain.settings.b3ground = "default:dirt_with_grass"
realterrain.settings.b3ground2 = "default:dirt_with_dry_grass"
realterrain.settings.b3gprob = 30
validate.b3gprob = "number"
realterrain.settings.b3tree = "tree"
realterrain.settings.b3tprob = 0.1
validate.b3tprob = "number"
realterrain.settings.b3tree2 = "cactus"
realterrain.settings.b3tprob2 = 30
validate.b3tprob2 = "number"
realterrain.settings.b3shrub = "default:dry_grass_1"
realterrain.settings.b3sprob = 5
validate.b3sprob = "number"
realterrain.settings.b3shrub2 = "default:dry_shrub"
realterrain.settings.b3sprob2 = 50
validate.b3sprob2 = "number"

--USGS tier 1 landcover: 4 - FOREST
realterrain.settings.b4ground = "default:dirt_with_grass"
realterrain.settings.b4ground2 = "default:gravel"
realterrain.settings.b4gprob = 10
validate.b4gprob = "number"
realterrain.settings.b4tree = "jungletree"
realterrain.settings.b4tprob = 0.5
validate.b4tprob = "number"
realterrain.settings.b4tree2 = "tree"
realterrain.settings.b4tprob2 = 30
validate.b4tprob2 = "number"
realterrain.settings.b4shrub = "default:junglegrass"
realterrain.settings.b4sprob = 5
validate.b4sprob = "number"
realterrain.settings.b4shrub2 = "default:grass_1"
realterrain.settings.b4sprob2 = 50
validate.b4sprob2 = "number"

--USGS tier 1 landcover: 5 - WATER
realterrain.settings.b5ground = "realterrain:water_static" --not normal minetest water, too messy
realterrain.settings.b5ground2 = "realterrain:water_static"
realterrain.settings.b5gprob = 0
validate.b5gprob = "number"
realterrain.settings.b5tree = ""
realterrain.settings.b5tprob = 0
validate.b5tprob = "number"
realterrain.settings.b5tree2 = ""
realterrain.settings.b5tprob2 = 0
validate.b5tprob2 = "number"
realterrain.settings.b5shrub = "default:grass_1"
realterrain.settings.b5sprob = 0
validate.b5sprob = "number"
realterrain.settings.b5shrub2 = "default:grass_1"
realterrain.settings.b5sprob2 = 0
validate.b5sprob2 = "number"

--USGS tier 1 landcover: 6 - WETLAND
realterrain.settings.b6ground = "default:dirt_with_grass" --@todo add a wetland node
realterrain.settings.b6ground2 = "realterrain:water_static"
realterrain.settings.b6gprob = 10
validate.b6gprob = "number"
realterrain.settings.b6tree = ""
realterrain.settings.b6tprob = 0
validate.b6tprob = "number"
realterrain.settings.b6tree2 = ""
realterrain.settings.b6tprob2 = 0
validate.b6tprob2 = "number"
realterrain.settings.b6shrub = "default:junglegrass"
realterrain.settings.b6sprob = 20
validate.b6sprob = "number"
realterrain.settings.b6shrub2 = "default:grass_1"
realterrain.settings.b6sprob2 = 40
validate.b6sprob2 = "number"

--USGS tier 1 landcover: 7 - BARREN
realterrain.settings.b7ground = "default:sand"
realterrain.settings.b7ground2 = "default:dirt_with_dry_grass"
realterrain.settings.b7gprob = 10
validate.b7gprob = "number"
realterrain.settings.b7tree = "cactus"
realterrain.settings.b7tprob = 0.2
validate.b7tprob = "number"
realterrain.settings.b7tree2 = "tree"
realterrain.settings.b7tprob2 = 5
validate.b7tprob2 = "number"
realterrain.settings.b7shrub = "default:dry_shrub"
realterrain.settings.b7sprob = 5
validate.b7sprob = "number"
realterrain.settings.b7shrub2 = "default:dry_grass_1"
realterrain.settings.b7sprob2 = 50
validate.b7sprob2 = "number"

--USGS tier 1 landcover: 8 - TUNDRA
realterrain.settings.b8ground = "default:gravel"
realterrain.settings.b8ground2 = "default:dirt_with_snow"
realterrain.settings.b8gprob = 10
validate.b8gprob = "number"
realterrain.settings.b8tree = "snowtree"
realterrain.settings.b8tprob = 0.1
validate.b8tprob = "number"
realterrain.settings.b8tree2 = "tree"
realterrain.settings.b8tprob2 = 5
validate.b8tprob2 = "number"
realterrain.settings.b8shrub = "default:dry_grass_1"
realterrain.settings.b8sprob = 5
validate.b8sprob = "number"
realterrain.settings.b8shrub2 = "default:dry_shrub"
realterrain.settings.b8sprob2 = 50
validate.b8sprob2 = "number"

--USGS tier 1 landcover: PERENNIAL SNOW OR ICE
realterrain.settings.b9ground = "default:dirt_with_snow"
realterrain.settings.b9ground2 = "default:ice"
realterrain.settings.b9gprob = 10
validate.b9gprob = "number"
realterrain.settings.b9tree = ""
realterrain.settings.b9tprob = 0
validate.b9tprob = "number"
realterrain.settings.b9tree2 = ""
realterrain.settings.b9tprob2 = 0
validate.b9tprob2 = "number"
realterrain.settings.b9shrub = "default:dry_grass_1"
realterrain.settings.b9sprob = 2
validate.b9sprob = "number"
realterrain.settings.b9shrub2 = "default:dry_shrub"
realterrain.settings.b9sprob2 = 50
validate.b9sprob2 = "number"

--Slope symbols
realterrain.settings.rastsymbol1 = "realterrain:slope1"
realterrain.settings.rastsymbol2 = "realterrain:slope2"
realterrain.settings.rastsymbol3 = "realterrain:slope3"
realterrain.settings.rastsymbol4 = "realterrain:slope4"
realterrain.settings.rastsymbol5 = "realterrain:slope5"
realterrain.settings.rastsymbol6 = "realterrain:slope6"
realterrain.settings.rastsymbol7 = "realterrain:slope7"
realterrain.settings.rastsymbol8 = "realterrain:slope8"
realterrain.settings.rastsymbol9 = "realterrain:slope9"
realterrain.settings.rastsymbol10 = "realterrain:slope10"

local function alphabetical_sorter(a, b)
	return a.key < b.key
end

--called at each form submission
function realterrain.save_settings()
	local file = io.open(WORLDPATH.."/realterrain_settings", "w")
	if file then
		local list = {}
		for k, v in pairs(realterrain.settings) do
			table.insert(list, {key=k, values=v})
		end

		table.sort(list, alphabetical_sorter) -- Sort alphabetically

		for _, line in ipairs(list) do
			file:write(minetest.serialize(line).."\n")
		end
		file:close()
	end
end

function realterrain.validate_and_save(fields)
	local errors
	for k, v in pairs(fields) do
		if validate[k] then
			--print("field, "..k.." has a validation rule")
			local rule = validate[k]
			if rule == "number" then
				if tonumber(v) then
					realterrain.settings[k] = tonumber(v)
				else
					if not errors then errors = {} end
					table.insert(errors, k)
				end
			end
		else
			realterrain.settings[k] = v
		end
		
	end
	--save to file
	realterrain.save_settings()
	if errors then
		--print(dump(errors))
		return errors
	else
		return false
	end
end

-- load settings run at EOF at mod start
local function load_settings()
	local file = io.open(WORLDPATH.."/realterrain_settings", "r")
	if file then
		for line in file:lines() do
			if line ~= "" then
				local tline = minetest.deserialize(line)
				realterrain.settings[tline.key] = tline.values
			end
		end
		file:close()
	end
end

--retrieve individual form field --@todo haven't been using this much, been accesing the settings table directly
function realterrain.get_setting(setting)
	if next(realterrain.settings) ~= nil then
		if realterrain.settings[setting] then
			if realterrain.settings[setting] ~= "" then
				return realterrain.settings[setting]
			else
				return false
			end
		else
			return false
		end
	else
		return false
	end
end

--read from file, various persisted settings
load_settings()
