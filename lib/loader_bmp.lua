
-- Original file is part of Allegro 4.4.
-- BMP loader by Seymour Shlien.
-- OS/2 BMP support and BMP save function by Jonas Petersen.
-- Translated to Lua by Diego Martínez <lkaezadl3@gmail.com>

local BI_RGB = 0

local OS2INFOHEADERSIZE = 12
local WININFOHEADERSIZE = 40

local figetw = ioh.read_int16_le
local figetl = ioh.read_int32_le
local function fgetc(f) return (f:read(1) or " "):byte() end

--[[ read_bmfileheader:
  |  Reads a BMP file header and check that it has the BMP magic number.
  ]]
local function read_bmfileheader(f, fileheader)

	fileheader.bfType = figetw(f)
	fileheader.bfSize = figetl(f)
	fileheader.bfReserved1 = figetw(f)
	fileheader.bfReserved2 = figetw(f)
	fileheader.bfOffBits = figetl(f)

	if fileheader.bfType ~= 19778 then return false end

	return true

end

--[[ read_win_bminfoheader:
  |  Reads information from a BMP file header.
  ]]
local function read_win_bminfoheader(f, infoheader)

	local win_infoheader

	local win_infoheader = { }
	win_infoheader.biWidth = figetl(f)
	win_infoheader.biHeight = figetl(f)
	win_infoheader.biPlanes = figetw(f)
	win_infoheader.biBitCount = figetw(f)
	win_infoheader.biCompression = figetl(f)
	win_infoheader.biSizeImage = figetl(f)
	win_infoheader.biXPelsPerMeter = figetl(f)
	win_infoheader.biYPelsPerMeter = figetl(f)
	win_infoheader.biClrUsed = figetl(f)
	win_infoheader.biClrImportant = figetl(f)

	infoheader.biWidth = win_infoheader.biWidth
	infoheader.biHeight = win_infoheader.biHeight
	infoheader.biBitCount = win_infoheader.biBitCount
	infoheader.biCompression = win_infoheader.biCompression

	return true

end

--[[ read_os2_bminfoheader:
  |  Reads information from an OS/2 format BMP file header.
  ]]
local function read_os2_bminfoheader(f, infoheader)

	local os2_infoheader = { }

	os2_infoheader.biWidth = figetw(f)
	os2_infoheader.biHeight = figetw(f)
	os2_infoheader.biPlanes = figetw(f)
	os2_infoheader.biBitCount = figetw(f)

	infoheader.biWidth = os2_infoheader.biWidth
	infoheader.biHeight = os2_infoheader.biHeight
	infoheader.biBitCount = os2_infoheader.biBitCount
	infoheader.biCompression = 0

	return true

end

--[[ read_24bit_line:
  |  Support function for reading the 24 bit bitmap file format, doing
  |  our best to convert it down to a 256 color palette.
  ]]
local function read_24bit_line(length, f, line)

	local ii = 0

	for i = 1, length do
		local c = { }
		c.b = fgetc(f)
		c.g = fgetc(f)
		c.r = fgetc(f)
		c.a = 255
		line[i] = c
		ii = ii + 1
	end

	-- padding
	ii = (ii * 3) % 4
	if ii ~= 0 then
		while ii < 4 do
			fgetc(f)
			ii = ii + 1
		end
	end

end

--[[ read_32bit_line:
  |  Support function for reading the 32 bit bitmap file format, doing
  |  our best to convert it down to a 256 color palette.
  ]]
local function read_32bit_line(length, f, line)

	for i = 1, length do
		local c = { }
		c.b = fgetc(f)
		c.g = fgetc(f)
		c.r = fgetc(f)
		c.a = fgetc(f)
		line[i] = c
	end

end

--[[ read_image:
  |  For reading the noncompressed BMP image format.
  ]]
local function read_image(f, bmp, infoheader)

	local i, line, height, dir

	height = infoheader.biHeight
	line = (height < 0) and 1 or height
	dir = (height < 0) and 1 or -1
	height = math.abs(height)

	print(("[imageloader.bmp] size=%dx%d bpp=%d"):format(
		infoheader.biWidth,
		infoheader.biHeight,
		infoheader.biBitCount
	))

	bmp.pixels = { }

	for i = 1, height do
		local row = { }
		bmp.pixels[line] = row
		if infoheader.biBitCount == 24 then
			read_24bit_line(infoheader.biWidth, f, row)
		elseif infoheader.biBitCount == 32 then
			read_32bit_line(infoheader.biWidth, f, row)
		else
			return false
		end
		line = line + dir
	end

	return true

end

local function get_bmp_infoheader(f)

	local fileheader = { }
	local infoheader = { }
	local bmp, biSize
	local bpp, dest_depth

	if not read_bmfileheader(f, fileheader) then
		return nil, "loader_bmp: failed to read file header"
	end

	biSize = figetl(f)

	if biSize == WININFOHEADERSIZE then
		if not read_win_bminfoheader(f, infoheader) then
			return nil, "loader_bmp: failed to read info header"
		end
	elseif biSize == OS2INFOHEADERSIZE then
		if not read_os2_bminfoheader(f, infoheader) then
			return nil, "loader_bmp: failed to read info header"
		end
	else
		return nil, "loader_bmp: unsupported file format"
	end

	if --[[(infoheader.biBitCount == 8) or (infoheader.biBitCount == 16)
		or --]](infoheader.biBitCount == 24) or (infoheader.biBitCount == 32) then
		bpp = infoheader.biBitCount
	else
		return nil, "loader_bmp: unsupported color depth "..infoheader.biBitCount
	end

	if infoheader.biCompression ~= BI_RGB then
		return nil, "loader_bmp: unsupported compression scheme: "..infoheader.biCompression
	end

	return infoheader

end

--[[ load_bmp_pf:
  |  Like load_bmp, but starts loading from the current place in the PACKFILE
  |  specified. If successful the offset into the file will be left just after
  |  the image data. If unsuccessful the offset into the file is unspecified,
  |  i.e. you must either reset the offset to some known place or close the
  |  packfile. The packfile is not closed by this function.
  ]]
local function load_bmp_pf(f)

	local infoheader, e = get_bmp_infoheader(f)

	if not infoheader then return nil, e end

	local bmp = {
		bpp = bpp,
		w = infoheader.biWidth,
		h = math.abs(infoheader.biHeight),
	}

	read_image(f, bmp, infoheader)

	return bmp

end

local function check_bmp(filename)
	local f, e = io.open(filename, "rb")
	if not f then return nil, e end
	local r, e = get_bmp_infoheader(f)
	if e then print(e) end
	f:close()
	return r, e
end

local function load_bmp(filename)
	local f, e = io.open(filename, "rb")
	if not f then return nil, e end
	local r, e = load_bmp_pf(f)
	f:close()
	return r, e
end

imageloader.register_type({
	description = "Windows or OS/2 Bitmap",
	load = load_bmp,
	check = check_bmp,
})
