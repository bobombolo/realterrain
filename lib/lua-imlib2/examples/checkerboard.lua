-- Draw a checkerboard
-- Basically a translation of the imlib2-ruby example (c) 2002 Paul Duncan

require("imlib2")
local color = imlib2.color

local w, h, bw, bh = 10, 10, 48, 48 -- #squares across, #squares down, square width, square height

local fg_gradient = imlib2.gradient.new()
fg_gradient:add_color(0, color.DARKGREY) 
fg_gradient:add_color(1, color.LIGHTGREY)

local im = imlib2.image.new(w * bw, h * bh)
im:fill_rectangle(0, 0, w*bw, h*bh, color.BLACK) -- Fill background

local function is_white(across, down)
  return (across%2 == 0 and down%2 == 0) or (across%2 == 1 and down%2 == 1)
end

print("Generating checkerboard")
for across=0, 9 do
  for down=0, 9 do
    if (is_white(across,down)) then
      im:fill_gradient(fg_gradient, across*bw, down*bh, bw, bh, 135)
    end
  end
end

print("Generating pieces")
for across=0, 9 do
  for down=0, 9 do
    local ellipse_args = {across*bw + bw/2, down*bh + bh/2, bw*2/5, bh*2/5}
    if not (is_white(across,down)) then
      -- Draw 3 rows of red checkers at the top, 3 rows of black at the bottom
      if (down < 3) then
        ellipse_args[#ellipse_args+1]=color.RED
        im:fill_ellipse(unpack(ellipse_args))
      elseif (down >= h-3) then
        ellipse_args[#ellipse_args+1]=color.BLUE
        im:fill_ellipse(unpack(ellipse_args))
      end
    end
  end
end

im:save("checkerboard.png")
