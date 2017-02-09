-- Draw the Sierpinski triangle, basically really not very different to the 
-- lua-gd example it was copied from

require "imlib2"

local size = 250
img = imlib2.image.new(size, size)
img:fill_rectangle(0, 0, size, size, imlib2.color.WHITE)

local m = {}
m[math.floor(size/2)]=true

for i=1, size do
  local n={}
  for j=1, size do
    if m[j] then
      img:draw_pixel(j, i, imlib2.color.BLACK)
      n[j+1] = not n[j+1]
      n[j-1] = not n[j-1]
    end
  end
  m=n
end

img:save("sierpinski.png")
