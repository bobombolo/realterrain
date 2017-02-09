package.path = (MODPATH.."/lib/pngLua/?.lua;"
		..MODPATH.."/lib/pngLua/?/init.lua;"
		..package.path)

require "png"

local function get_png(filename)
	local ok, r = pcall(pngImage, filename)
	if not ok then return nil, r end  -- NOTE: r == error message
	return r
end

local function load_png(filename)
	local img, e = get_png(filename)
	if not img then return nil, e end
	local pixels = { }
	local bmp = {
		w = img.width, h = img.height,
		pixels = pixels,
	}
	for y = 1, bmp.h do
		local oline = { }
		local iline = img.scanLines[y]
		pixels[y] = oline
		for x = 1, bmp.w do
			local pixel = iline.pixels[x]
			oline[x] = { r=pixel.R, g=pixel.G, b=pixel.B }
		end
	end
	return bmp
end

imageloader.register_type({
	description = "Portable Network Graphics",
	load = load_png,
	check = get_png,
})
