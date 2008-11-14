require File.dirname(__FILE__) + '/test_helper'

class CairoToolsTest < Nitrous::Test
  test "get_pixel" do
    dimensions 3, 3
    assert_equal rgb(0, 0, 0, 0), get_pixel(1, 3)

    cr.set_source_rgb(0, 1, 0)
    cr.paint
    assert_equal rgb(0, 1, 0), get_pixel(0, 0)
    
    set_color rgb(1, 0, 0)
    cr.paint
    assert_equal rgb(1, 0, 0), get_pixel(0, 0)

    set_color rgb(0, 0, 1)
    cr.paint
    assert_equal rgb(0, 0, 1), get_pixel(0, 0)
    
    dimensions 10, 10
    cr.rectangle 0.5, 0.5, 9, 9
    cr.line_width = 1
    cr.stroke
    assert_equal black.to_rgb, get_pixel(0, 0)
    assert_equal black.a(0).to_rgb, get_pixel(1, 1)
  end
  
  test "blur shouldn't wrap around" do
    dimensions 3, 2
    cr.rectangle 2, 0, 1, 2
    black!
    cr.fill
    @surface.blur(1)
    assert_equal rgb(0, 0, 0, 0), @surface.get_pixel(0, 1)
  end
end