require("lunit")

module("test border", lunit.testcase, package.seeall)
local imlib2 = require("imlib2")

function setup()
  border = imlib2.border.new(1,2,3,4)
end

function test_left_top_right_bottom()
  local b = border
  assert_equal(1, b.left)
  assert_equal(2, b.top)
  assert_equal(3, b.right)
  assert_equal(4, b.bottom)
  b.left = 5
  b.top = 6
  b.right = 7
  b.bottom = 8
  assert_equal(5, b.left)
  assert_equal(6, b.top)
  assert_equal(7, b.right)
  assert_equal(8, b.bottom)
end

function test__tostring()
  assert_string(border:__tostring())
end

-- Test border creation
function test_create_fails_with_missing_sides()
  assert_error(nil, function() border.new(1,2,3,nil) end)
end
