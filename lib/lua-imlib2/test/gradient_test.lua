require("lunit")

local imlib2 = require "imlib2"

module("a newly created gradient", lunit.testcase)
do
  function setup()
    a_gradient = imlib2.gradient.new()
  end

  function test__tostring()
    assert_string(a_gradient:__tostring())
  end

  function test_add_color()
    assert_error(nil, function() a_gradient:add_color() end)
    assert_error(nil, function() a_gradient:add_color(1, {}) end)
    assert_pass(nil, function() a_gradient:add_color(1, imlib2.color.new(1,1,1)) end)
  end
end
