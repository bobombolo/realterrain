require("lunit")

local imlib2 = require("imlib2")
local module = module

module("creating a new color", lunit.testcase)

function test_too_few_colors()
  assert_error(nil, function() imlib2.color.new(255, 255, nil, nil) end)
  assert_error(nil, function() imlib2.color.new(nil, nil, nil, 255) end)
end

function test_allow_missing_alpha()
  assert_pass(nil, function() imlib2.color.new(255, 255, 255) end)
end

function test_allowed_range()
  assert_error(nil, function() imlib2.color.new(255, 255, 255, 256) end)
  assert_error(nil, function() imlib2.color.new(256, 255, 255, 255) end)
  assert_error(nil, function() imlib2.color.new(0, 0, -1, 0) end)
  assert_error(nil, function() imlib2.color.new(0, -1, -1, 0) end)
end

module("querying and modifying an existing color", lunit.testcase)

function setup()
  col = imlib2.color.new(0, 0, 0, 255)
end

function test__tostring()
  assert_string(col:__tostring())
end

function test_get_rgba()
  assert_equal(0, col.red)
  assert_equal(0, col.green)
  assert_equal(0, col.blue)
  assert_equal(255, col.alpha)
end

function test_set_rgba()
  col.red=255
  col.green=255
  col.blue=255
  col.alpha=0
  assert_equal(255, col.red)
  assert_equal(255, col.green)
  assert_equal(255, col.blue)
  assert_equal(0, col.alpha)
end

function test_set_rgba_out_of_range()
  assert_error(nil, function() col.red=256 end)
  assert_error(nil, function() col.alpha=-1 end)
end
