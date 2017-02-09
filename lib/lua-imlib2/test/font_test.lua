require("lunit")

local imlib2 = require("imlib2")
local font = imlib2.font
local module = module

module("manipulating the font paths/listing fonts", lunit.testcase)
do
  function test_list_paths()
    assert_table(font.list_paths())
  end

  function test_add_path()
    font.add_path("foo")
    assert_equal("foo", font.list_paths()[1])
    assert_error(nil, function() font.add_path(nil) end)
  end

  function test_remove_path()
    font.add_path("foo")
    font.remove_path("foo")
    assert_equal(0, #font.list_paths())
    assert_error(nil, function() font.remove_path(nil) end)
  end

  function test_list_fonts()
    assert_table(font.list_fonts())
  end
end

module("getting and setting the cache size", lunit.testcase)
do

  function test_get_cache_size()
    assert_number(font.get_cache_size())
  end

  function test_set_cache_size()
    local orig = font.get_cache_size()
    font.set_cache_size(1337)
    assert_equal(1337, font.get_cache_size())
    font.set_cache_size(orig)
  end
end

module("loading a font", lunit.testcase)
do
  function test_failing_to_load_a_font()
    local s, msg = font.load("notfound")
    assert_nil(s)
    assert_string(msg)
  end
end


module("a loaded font instance", lunit.testcase)
do
  function setup()
    font.add_path("resources")
    local msg
    a_font, msg = font.load("Vera/10")
    assert(a_font, msg)
  end

  function teardown()
    font.remove_path("resources")
  end

  function test__tostring()
    assert_string(a_font:__tostring())
  end

  function test_get_size()
    local w, h = a_font:get_size("this is a test of a test of a test")
    assert_number(w)
    assert_number(h)
    assert(w >= h)
  end

  function test_get_advance()
    local h,v = a_font:get_advance("this is a test")
    assert_number(h)
    assert_number(v)
    assert(h > v)
  end

  function test_get_inset() assert_number(a_font:get_inset("foo")) end
  function test_get_ascent() assert_number(a_font:get_ascent()) end
  function test_get_maximum_ascent() assert_number(a_font:get_maximum_ascent()) end
  function test_get_descent() assert_number(a_font:get_descent()) end
  function test_get_maximum_descent() assert_number(a_font:get_maximum_descent()) end
end

module("setting/getting the text direction", lunit.testcase)
do
  function test_set_direction()
    assert_pass(nil, function() font.set_direction("up") end)
    assert_equal("up", font.get_direction())
    assert_error(nil, function() font.set_direction("invalid") end)
  end

  function test_set_direction_to_angle()
    assert_error(nil, function() font.set_direction("angle", "bleh") end)
    assert_pass(nil, function() font.set_direction("angle", 21.1) end)
    local dir, angle = font.get_direction()
    assert_equal("angle", dir)
    assert_equal(21.1, angle)
  end
end
