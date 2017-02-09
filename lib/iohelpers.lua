
ioh = { }

local function read_bytes(f, c, d)

	local s = (d < 0) and c or 1
	local e = (d < 0) and 1 or c

	local buf = f:read(c)
	if (not buf) or (buf:len() ~= c) then return nil end

	local r = 0

	for x = s, e, d do
		r = r * 256
		r = r + buf:byte(x)
	end

	return r

end

local function write_bytes(f, n, c, d)

	local s = (d < 0) and c or 1
	local e = (d < 0) and 1 or c

	local buf = ""

	for x = s, e, d do
		local ch = (n % 256)
		buf = buf..string.char(ch)
		n = (n - ch) / 256
	end

	f:write(buf)

end


function ioh.read_int16_le(f) return read_bytes(f, 2, -1) end
function ioh.read_int32_le(f) return read_bytes(f, 4, -1) end
function ioh.read_int16_be(f) return read_bytes(f, 2,  1) end
function ioh.read_int32_be(f) return read_bytes(f, 4,  1) end

function ioh.write_int16_le(f, n) write_bytes(f, n, 2, -1) end
function ioh.write_int32_le(f, n) write_bytes(f, n, 4, -1) end
function ioh.write_int16_be(f, n) write_bytes(f, n, 2,  1) end
function ioh.write_int32_be(f, n) write_bytes(f, n, 4,  1) end
