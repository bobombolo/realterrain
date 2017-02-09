require("lunit")

local imlib2 = require("imlib2")
local module = module

module("Anti alias setting", lunit.testcase)
do
  function test_get_antialias()
    assert_true(imlib2.get_anti_alias()) -- want to be true by default
  end

  function test_set_anti_alias()
    assert_error(nil, function() imlib2.set_anti_alias() end)
    imlib2.set_anti_alias(false)
    assert_false(imlib2.get_anti_alias())
    imlib2.set_anti_alias(true)
    assert_true(imlib2.get_anti_alias())
  end
end

module("Cache functions", lunit.testcase)
do
  function test_get_cache_size()
    assert_number(imlib2.get_cache_size())
  end

  function test_set_cache_size()
    local orig = imlib2.get_cache_size()
    imlib2.set_cache_size(50000)
    assert_equal(50000, imlib2.get_cache_size())
    imlib2.set_cache_size(orig)
    assert_equal(orig, imlib2.get_cache_size())
  end

  function test_flush_cache()
    local orig = imlib2.get_cache_size()
    imlib2.flush_cache() -- should restore original cache size
    assert_equal(orig, imlib2.get_cache_size())
  end
end
