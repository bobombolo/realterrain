-- Fun little algorithm from the first chapter of The New Turing Omnibus by 
-- A.K. Dewdney. Try playing with different parameters

require("imlib2")
local corner_a, corner_b, side = ...
assert(corner_a and corner_b and side, "Please provide 3 integer parameters")

local side_length = 500

im = imlib2.image.new(side_length, side_length)
local colors = {imlib2.color.YELLOW, imlib2.color.BLACK, imlib2.color.RED}

for x=0, side_length-1 do
  for y=0, side_length-1 do
    local a = corner_a + x*(side/side_length)
    local b = corner_b + y*(side/side_length)
    local c = math.floor(a^2 + b^2)
    local color_index = 1 + c % #colors
    im:draw_pixel(x, y, colors[color_index])
  end
end

im:save("wallpaper.png")
