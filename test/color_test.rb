require File.dirname(__FILE__) + '/test_helper'
require 'color'

class ColorTest < Nitrous::Test
  include Color
  
  test "new with three components" do
    assert_equal 0.5, rgb(0.4, 0.5, 0.6).g
  end
  
  test "new with alpha" do
    assert_equal 0.5, rgb(0.2, 0.3, 0.4, 0.5).a
  end
  
  test "new with css" do
    assert_equal rgb(0.25, 0.5, 1.0), rgb("4080FF")
    assert_equal rgb(1.0, 2.0/3.0, 0.8), rgb("FAC")
    assert_equal rgb(1.0, 2.0/3.0, 0.8), rgb("#FAC")
  end
  
  test "alpha should default to 1.0" do
    assert_equal 1.0, rgb(1, 1, 1).a
    assert_equal 1.0, hsl(1, 1, 1).a
  end
  
  test "to_css" do
    assert_equal '3F7FFF', rgb(0.25, 0.5, 1.0).to_css
    assert_equal '010101', rgb(1.0/255.0, 1.0/255.0, 1.0/255.0).to_css
    assert_equal '000000', rgb(0, 0, 0).to_css
    assert_equal 'FFAACC', rgb(1.0, 2.0/3.0, 0.8).to_css
    assert_equal 'FF5BFE', hsl(5.0/6.0, 1.0, 0.68).to_css
  end
  
  test "equals" do
    assert_equal rgb(0.1, 0.1, 0.1), rgb(0.1, 0.1, 0.1)
    assert_not_equal rgb(0.1, 0.1, 0.1), rgb(0.1, 0.1, 0.2)
    assert_not_equal rgb(0.1, 0.1, 0.1), hsl(0.1, 0.1, 0.1)
  end
  
  test "addition and subtraction" do
    assert_equal rgb(0.5, 0.4, 0.3), rgb(0.3, 0.3, 0.3) + rgb(0.2, 0.1, 0.0)
    # TODO: is this the right behavior for alpha?
    assert_equal rgb(0.1, 0.2, 0.3, 0.0), rgb(0.3, 0.3, 0.3) - rgb(0.2, 0.1, 0.0)
    assert_equal rgb(0.5, 0.4, 0.3), rgb(0.3, 0.3, 0.3) + [0.2, 0.1, 0.0]
    assert_equal rgb(0.1, 0.2, 0.3), rgb(0.3, 0.3, 0.3) - [0.2, 0.1, 0.0]
  end
  
  test "to_hsl" do
    assert_equal hsl(0.0, 1.0, 0.5), rgb(1.0, 0.0, 0.0).to_hsl
    assert_equal hsl(1.0/3.0, 1.0, 0.5), rgb(0.0, 1.0, 0.0).to_hsl
    assert_equal hsl(2.0/3.0, 1.0, 0.5), rgb(0.0, 0.0, 1.0).to_hsl
    assert_equal hsl(7.0/12.0, 1.0, 0.25), rgb(0.0, 0.25, 0.5).to_hsl
    assert_equal hsl(5.0/6.0, 1.0, 0.679), rgb("FF5BFF").to_hsl
    assert_equal hsl(7.0/12.0, 1.0, 0.25, 0.5), rgb(0.0, 0.25, 0.5, 0.5).to_hsl
  end
  
  test "to_rgb" do
    assert_equal rgb(1.0, 0.0, 0.0), hsl(0.0, 1.0, 0.5).to_rgb
    assert_equal rgb(0.0, 1.0, 0.0), hsl(1.0/3.0, 1.0, 0.5).to_rgb
    assert_equal rgb(0.0, 0.0, 1.0), hsl(2.0/3.0, 1.0, 0.5).to_rgb
    assert_equal rgb(0.0, 0.25, 0.5), hsl(7.0/12.0, 1.0, 0.25).to_rgb
    assert_equal rgb(0.0, 0.25, 0.5, 0.5), hsl(7.0/12.0, 1.0, 0.25, 0.5).to_rgb
    assert_equal rgb(1, 1, 1, 0), hsl(0, 0, 1, 0).to_rgb
  end
  
  test "non-destructive setters" do
    white = rgb(1, 1, 1)
    assert_equal rgb(1, 1, 1, 0.5), white.a(0.5)
    assert_equal rgb(1, 1, 1), white
  end
end
