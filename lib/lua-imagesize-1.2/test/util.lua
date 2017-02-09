require "lunit"

module("test.util", lunit.testcase, package.seeall)

local Util = require "imagesize.util"

function test_get_uint16_le ()
    assert_equal(0x1234, Util.get_uint16_le(" \52\18 ", 2))
    assert_equal(0xFEDC, Util.get_uint16_le(" \220\254 ", 2))
end

function test_get_uint16_be ()
    assert_equal(0x1234, Util.get_uint16_be(" \18\52 ", 2))
    assert_equal(0xFEDC, Util.get_uint16_be(" \254\220 ", 2))
end

function test_get_uint32_le ()
    assert_equal(0x12345678, Util.get_uint32_le(" \120\86\52\18 ", 2))
    assert_equal(0xFEDCBA98, Util.get_uint32_le(" \152\186\220\254 ", 2))
end

function test_get_uint32_be ()
    assert_equal(0x12345678, Util.get_uint32_be(" \18\52\86\120 ", 2))
    assert_equal(0xFEDCBA98, Util.get_uint32_be(" \254\220\186\152 ", 2))
end

-- vi:ts=4 sw=4 expandtab
