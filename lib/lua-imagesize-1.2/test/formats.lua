require "lunit"

module("test.formats", lunit.testcase, package.seeall)

local ImageSize = require "imagesize"

-- Attempt to load my MemoryFile module, but don't bitch if it's not installed.
local MemFile
do
    local ok, r = pcall(require, "memoryfile")
    if ok then MemFile = r end
end

local function _test_format (filename, exp_format, exp_width, exp_height, opt)
    -- Test with the filename.
    local x, y, id = ImageSize.imgsize(filename, opt)
    assert_equal(exp_format, id, "filename, format")
    assert_equal(exp_width, x, "filename, width")
    assert_equal(exp_height, y, "filename, height")

    -- Test with a file handle.
    local file = assert(io.open(filename, "rb"))
    x, y, id = ImageSize.imgsize(file, opt)
    assert_equal(exp_format, id, "file handle, format")
    assert_equal(exp_width, x, "file handle, width")
    assert_equal(exp_height, y, "file handle, height")
    assert_equal(0, file:seek(), "file handle left in original position")
    file:close()

    -- Test with a string as input.
    local file = assert(io.open(filename, "rb"))
    local data = file:read("*a")
    file:close()
    x, y, id = ImageSize.imgsize_string(data, opt)
    assert_equal(exp_format, id, "string, format")
    assert_equal(exp_width, x, "string, width")
    assert_equal(exp_height, y, "string, height")

    -- If my 'memoryfile' module is installed, test using that as the file
    -- handle.
    if MemFile then
        local file = MemFile.open(data)
        x, y, id = ImageSize.imgsize(file, opt)
        assert_equal(exp_format, id, "memoryfile, format")
        assert_equal(exp_width, x, "memoryfile, width")
        assert_equal(exp_height, y, "memoryfile, height")
        file:size(0)
    end
end

function test_bmp ()
    -- BITMAPINFOHEADER:
    _test_format("test/data/xterm.bmp", "image/x-ms-bmp", 64, 38)
    -- BITMAPCOREHEADER:
    _test_format("test/data/old-os2.bmp", "image/x-ms-bmp", 1500, 1000)
end

function test_jpeg ()
    _test_format("test/data/letter_T.jpg", "image/jpeg", 52, 54)
end

function test_png ()
    -- Test PNG image supplied by Tom Metro.
    _test_format("test/data/pass-1_s.png", "image/png", 90, 60)
end

function test_mng ()
    -- The test image is Copyright © G. Juyn, and was downloaded from here:
    --    http://www.libmng.com/MNGsuite/basic_img.html
    _test_format("test/data/DUTCH1.mng", "video/x-mng", 160, 120)
end

function test_tiff_little_endian ()
    _test_format("test/data/lexjdic.tif", "image/tiff", 35, 32)
end

function test_tiff_big_endian ()
    _test_format("test/data/bexjdic.tif", "image/tiff", 35, 32)
end

function test_gif_87a ()
    _test_format("test/data/test.gif", "image/gif", 60, 40)
end

function test_gif_89a_wrong_extension ()
    _test_format("test/data/pak38.jpg", "image/gif", 333, 194)
end

function test_ppm ()
    _test_format("test/data/letter_N.ppm", "image/x-portable-pixmap", 66, 57)
end

function test_pgm ()
    _test_format("test/data/letter_N.pgm", "image/x-portable-graymap", 66, 57)
end

function test_pbm ()
    _test_format("test/data/letter_N.pbm", "image/x-portable-bitmap", 66, 57)
end

function test_xv_thumbnail ()
    _test_format("test/data/xv-thumbnail", "image/x-xv-thumbnail", 16, 16)
end

function test_psd ()
    _test_format("test/data/468x60.psd", "image/x-photoshop", 468, 60)
end

function test_swf ()
    _test_format("test/data/yasp.swf", "application/x-shockwave-flash", 85, 36)
end

function test_swf_compressed ()
    _test_format("test/data/8.swf", "application/x-shockwave-flash", 280, 140)
end

function test_xbm ()
    _test_format("test/data/spacer50.xbm", "image/x-xbitmap", 50, 10)
end

function test_xpm ()
    _test_format("test/data/xterm.xpm", "image/x-xpixmap", 64, 38)
end

function test_xcf ()
    _test_format("test/data/anim.xcf", "application/x-xcf", 123, 45)
end

function test_nonexistant_file ()
    local x, y, err = ImageSize.imgsize("some non-existant file")
    assert_match("error opening", err, "error message")
    assert_nil(x, "width")
    assert_nil(y, "height")
end

function test_restore_offset_on_error ()
    -- Open a file which won't be successfully identified as an image, and
    -- make sure that the file handle isn't left at a different offset.
    local file = assert(io.open("test/formats.lua", "rb"))
    assert(file:seek("set", 123))
    local x, y, err = ImageSize.imgsize(file)
    assert_nil(x, "width")
    assert_nil(y, "height")
    assert_match("file format not recognized", err, "error message")
    assert_equal(123, file:seek())
    file:close()
end

function test_gif_behavior ()
    -- This test image has three frames of different sizes.
    local filename = "test/data/anim.gif"
    _test_format(filename, "image/gif", 123, 45, {})  -- default 'screen' option
    _test_format(filename, "image/gif", 123, 45, { gif_behavior = "screen" })
    _test_format(filename, "image/gif", 54, 23, { gif_behavior = "first" })
    _test_format(filename, "image/gif", 66, 30, { gif_behavior = "largest" })
    assert_error("bad 'gif_behavior' option", function ()
        ImageSize.imgsize(filename, { gif_behavior = "foobar" })
    end)

    -- This original test images have only one frame, so the behaviour
    -- option makes no difference.
    filename = "test/data/test.gif"
    _test_format(filename, "image/gif", 60, 40, { gif_behavior = "screen" })
    _test_format(filename, "image/gif", 60, 40, { gif_behavior = "first" })
    _test_format(filename, "image/gif", 60, 40, { gif_behavior = "largest" })
    filename = "test/data/pak38.jpg"
    _test_format(filename, "image/gif", 333, 194, { gif_behavior = "screen" })
    _test_format(filename, "image/gif", 333, 194, { gif_behavior = "first" })
    _test_format(filename, "image/gif", 333, 194, { gif_behavior = "largest" })
end

-- vi:ts=4 sw=4 expandtab
