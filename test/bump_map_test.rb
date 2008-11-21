require File.dirname(__FILE__) + '/test_helper'

class BumpMapTest < Nitrous::Test
  test "bump map" do
    dimensions 1, 1
    tb = create_text_box(10, 10)
    tb.line("Austin & Saki", :size => 160, :face => 'Savoye LET')
    dimensions tb.width + 40, tb.height
    black!
    # cr.paint
    # cr.operator = Cairo::OPERATOR_CLEAR
    tb.draw
    
    mask = @surface
    dimensions width, height
    cr.set_source(Cairo::SurfacePattern.new(mask))
    cr.paint
    @surface.blur(2)
    # 8.times {@surface.blur(10)}
    
    height_map = @surface
    dimensions width, height
    @surface.bump_map(height_map, width.to_i/2, -80, 800, 100)
    
    bump = @surface
    dimensions width, height
    # cr.set_source_rgb(0.6, 0.6, 0.6)
    # cr.mask(Cairo::SurfacePattern.new(mask))
    cr.set_source(Cairo::SurfacePattern.new(bump))
    cr.mask(Cairo::SurfacePattern.new(mask))
    # cr.paint
    
    
    preview
  end
  
  ztest "bump map3" do
    dimensions 100, 100
    load_image '../test/surface.png'
    cr.paint
    height_map = @surface
    dimensions 100, 100
    @surface.bump_map(height_map, -10, -30, 200, 30)
    preview
  end
  
  ztest "bump map2" do
    dimensions 5, 5
    cr.circle(width.to_f/2, height.to_f/2, width/2 - 1)
    black!
    cr.fill
    
    height_map = @surface
    
    dimensions 5, 5
    @surface.bump_map(height_map, -1, -1, 10, 2)
    
    preview
  end
end