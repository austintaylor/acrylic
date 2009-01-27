require '../acrylic'
class Courtyard < ImageGenerator
  color :lighter, [0.29, 0.9, 0.9]
  color :light, [0.29, 0.9, 0.8]
  color :dark,  [0.29, 0.9, 0.63]
  
  color :orange, [0.1, 1, 0.6]
  color :lighter_orange, [0.1, 1, 0.75]
  
  image :map do
    dimensions 400, 300
    margin 4
    curl = 6
    cr.move_to 0, 0
    cr.line_to width, 0
    cr.line_to width + 1, height
    curve = Curve.new(cr)
    curve.point(width + 1, height, 150.deg, 0)
    curve.point(width/2, height - curl, 180.deg, 50)
    curve.point(-1, height, 210.deg, 0)
    curve.draw_control_points(curve)
    cr.line_to 0, 0
    black! 0.4
    cr.fill
    
    @surface.blur 10
    
    cr.rectangle(0, 0, width, height - curl)
    white!
    cr.fill
    
    load_image 'map.png'
    cr.rectangle(4, 4, width - 8, height - curl - 8)
    # cr.rectangle(0, 0, width, height - curl)
    cr.fill
  end
  
  shape :gate, 130, 90 do
    def draw_bar(x, y)
      cr.move_to x, y
      cr.line_to x - 3, y + 5
      cr.line_to x - 1, y + 7
      cr.line_to x - 1, height
      cr.line_to x + 1, height
      cr.line_to x + 1, y + 7
      cr.line_to x + 3, y + 5
      cr.close_path
      cr.fill
    end
    
    def draw_side
      curve_height = 30
      gate_top = 10
      cr.line_width = 2

      curve = Curve.new(cr)
      curve.point(3, curve_height, 0.deg, 20)
      curve.point(width/2 - 1, gate_top, 0.deg, 30)
      curve.draw_control_points(curve)
      cr.stroke

      curve.each { |p| p.y += 30 }
      curve.draw_control_points(curve)
      cr.stroke

      cr.move_to width/2 - 4, gate_top - 0.5
      cr.line_to width/2 - 4, height
      cr.line_width = 6
      cr.stroke

      cr.move_to width/2 - 1, height
      cr.line_to 2, height
      cr.line_width = 4
      cr.stroke

      draw_bar(3, 19)
      draw_bar(11, 18)
      draw_bar(19, 15)
      draw_bar(27, 11)
      draw_bar(35, 7)
      draw_bar(43, 4)
      draw_bar(52, 1.5)
      draw_bar(61, 0)
    end
    
    draw_side
    transform cr.matrix.translate(width, 0).scale(-1, 1) do
      draw_side
    end
  end
  
  image :header do
    dimensions 900, 120
    margin 4
    linear_gradient 0, 0, 0, height + bottom_margin, light, dark
    rounded_rectangle 0, 0, width, height * 2, 40
    cr.fill_preserve
    cr.clip
    
    linear_gradient 0, height/3, 0, height + bottom_margin + 10, dark, light
    # rounded_rectangle 0, height/2 - 10, width, height, 70
    curve = Curve.new(cr)
    curve.point -80, height + bottom_margin, 45.deg, 5
    curve.point width/2, height/3, 0.deg, 500
    curve.point width + 80, height + bottom_margin, -45.deg, 5
    curve.draw_control_points(curve)
    cr.close_path
    cr.fill
    
    # @surface.blur 2
    # rounded_rectangle 0, 0, width, height * 2, 40
    # clip!
    
    
    white!
    draw_gate 16, 8
    
    draw_text_box 160, 16 do |tb|
      tb.line("Courtyard", :face => "Georgia", :size => 80)
    end
    
    shadow 5, 0.5
  end
  
  image :organizations_bar do
    dimensions 900, 40
    margin 0, 4
    cr.rectangle 0, 0, width, height
    linear_gradient 0, 0, 0, height, orange, lighter_orange
    cr.fill
    
    cr.rectangle 0, 0, width, 3
    linear_gradient 0, 0, 0, 3, black.a(0.15), black.a(0.1), black.a(0)
    cr.fill

    cr.rectangle 0, height-1, width, 1
    white! 0.4
    # linear_gradient 0, height-1, 0, height, white.a(0), white.a(0.3), white.a(0.5)
    cr.fill
    
    shadow 5, 0.5
  end
  
  image :page do
    dimensions 920, 200
    margin 10
    draw_image :header, 0, 0
    draw_image :organizations_bar, 0, 120
  end
  
  color :frame_light, [0, 0, 0.3]
  color :frame_dark, [0, 0, 0.2]
  image :frame do
    dimensions 400, 300
    margin 8
    
    border = 40
    
    # bottom
    draw_frame_side 0, height - border, 0, height, frame_light, frame_dark do
      cr.move_to 0, height
      cr.line_to width, height
      cr.line_to width - border, height - border
      cr.line_to border, height - border
      cr.close_path
    end
    
    # left
    draw_frame_side 0, 0, border, 0, frame_dark, frame_light do
      cr.move_to 0, 0
      cr.line_to 0, height
      cr.line_to border, height - border
      cr.line_to border, border
      cr.close_path
    end
    
    # right
    draw_frame_side width - border, 0, width, 0, frame_light, frame_dark do
      cr.move_to width, 0
      cr.line_to width, height
      cr.line_to width - border, height - border
      cr.line_to width - border, border
      cr.close_path
    end

    # top
    draw_frame_side 0, 0, 0, border, frame_light, frame_dark do
      cr.move_to 0, 0
      cr.line_to width, 0
      cr.line_to width - border + 1, border
      cr.line_to border, border
      cr.close_path
    end
    
    2.times {shadow 10, 0.7}
    
    frame = layer!
    load_image_and_scale 'church.jpg', width - border*2, height - border*2
    cr.source.matrix = Cairo::Matrix.identity.translate(-border, -border)
    cr.rectangle(border, border, width - border*2, height - border*2)
    cr.fill
    cr.paint
    
    linear_gradient 0, 0, 0, 180, white.a(0.6), white.a(0)
    cr.move_to 0, 0
    cr.line_to 0, 120
    cr.line_to width, 160
    cr.line_to width, 0
    cr.close_path
    cr.fill
    
    margin 0
    cr.set_source(Cairo::SurfacePattern.new(frame))
    cr.paint
  end
  
  def draw_frame_side(*gradient_args, &block)
    original = layer!
    original_margins = [@top_margin, @right_margin, @bottom_margin, @left_margin]
    yield
    path = cr.copy_path
    black!
    cr.fill
    mask = layer!
    cr.append_path path
    black!
    cr.fill
    @surface.blur 10
    height_map = layer!
    @surface.bump_map(height_map, width.to_i/2 + @left_margin, -80, 800, 10, 5)
    bump = layer!
    margin 0
    cr.set_source(Cairo::SurfacePattern.new(original))
    cr.paint

    margin *original_margins
    cr.append_path path
    linear_gradient *gradient_args
    cr.fill
    margin 0
    cr.set_source(Cairo::SurfacePattern.new(bump))
    cr.mask(Cairo::SurfacePattern.new(mask))
    margin *original_margins
  end
  
  def draw_cork_board_side(side, *gradient_args, &block)
    original = layer!
    yield
    path = cr.copy_path
    black!
    cr.fill
    mask = layer!
    cr.append_path path
    black!
    cr.fill
    @surface.blur 4
    height_map = layer!
    @surface.bump_map(height_map, width.to_i/2 + @left_margin, -320, 3200, 1, 3)
    bump = layer!

    cr.append_path path
    grain! 0.4
    fill_with_noise
    if [:top, :bottom].include?(side)
      @surface.horizontal_blur 10
      @surface.horizontal_blur 10
      @surface.horizontal_blur 10
    else
      @surface.vertical_blur 10
      @surface.vertical_blur 10
      @surface.vertical_blur 10
    end
    grain = layer!

    paint_layer original

    cr.append_path path
    linear_gradient *gradient_args
    cr.fill

    transform Cairo::Matrix.identity do
      cr.set_source(Cairo::SurfacePattern.new(grain))
      cr.mask(Cairo::SurfacePattern.new(mask))
      cr.set_source(Cairo::SurfacePattern.new(bump))
      cr.mask(Cairo::SurfacePattern.new(mask))
    end
  end
  
  def load_image_and_scale(path, width, height)
    image = Gdk::Pixbuf.new(File.join(File.dirname($0), path))
    tmp_surface = Cairo::ImageSurface.new(image.width, image.height)
    tmp_cr = Cairo::Context.new(tmp_surface)
    tmp_cr.set_source_pixbuf(image)
    tmp_cr.paint
    smaller = tmp_surface.downsample((image.width/width).ceil)
    cr.set_source(Cairo::SurfacePattern.new(smaller))
  end
  
  def layer!
    surface = @surface
    dimensions @canvas_width, @canvas_height
    margin @top_margin, @right_margin, @bottom_margin, @left_margin
    surface
  end
  
  color :cork_board_light, [0.11, 0.5, 0.8]
  color :cork_board_dark, [0.11, 0.5, 0.7]
  color :cork, [0.08, 0.5, 0.4]
  color :grain, [0.08, 0.5, 0.2]
  image :cork_board do
    dimensions 400, 300
    margin 8
    border = 20
    
    draw_cork_board_side :bottom, 0, height - border, 0, height, cork_board_light, cork_board_dark do
      cr.move_to 0, height
      cr.line_to width, height
      cr.line_to width - border, height - border
      cr.line_to border, height - border
      cr.close_path
    end
    
    draw_cork_board_side :left, 0, 0, border, 0, cork_board_dark, cork_board_light do
      cr.move_to 0, 0
      cr.line_to 0, height
      cr.line_to border, height - border
      cr.line_to border, border
      cr.close_path
    end
    
    draw_cork_board_side :right, width - border, 0, width, 0, cork_board_light, cork_board_dark do
      cr.move_to width, 0
      cr.line_to width, height
      cr.line_to width - border, height - border
      cr.line_to width - border, border
      cr.close_path
    end

    draw_cork_board_side :top, 0, 0, 0, border, cork_board_light, cork_board_dark do
      cr.move_to 0, 0
      cr.line_to width, 0
      cr.line_to width - border + 1, border
      cr.line_to border, border
      cr.close_path
    end
    
    2.times {shadow 10, 0.7}
    
    frame = layer!
    
    cork!
    cr.rectangle border, border, width - border*2, height - border*2
    cr.fill_preserve
    black!(0.2)
    fill_with_noise
    
    paint_layer frame
    
    draw_photo 'beach.jpg', 120, 160, 0.deg, :right
    draw_photo 'party.jpg', 205, 195, 5.deg, :left
    draw_photo 'game.jpg', 250, 70, -4.deg, :right
    draw_photo 'restaurant.jpg', -10, 160, 8.deg, :right
    draw_photo 'picnic.jpg', 20, 10, -8.deg, :left
    draw_photo 'park.jpg', 100, 90, 10.deg, :left
    draw_photo 'outside_church.jpg', 210, 10, -2.deg, :left
  end
  
  def draw_photo(path, x, y, theta, curl_side = :right)
    background = layer!
    load_image_and_scale(path, 130, 130)
    cr.source.matrix = Cairo::Matrix.identity.translate(-x, -y)
    w, h = cr.source.surface.width, cr.source.surface.height
    transform cr.matrix.rotate(-theta) do
      curl = 6
      cr.move_to x, y
      cr.line_to x + w, y
      if curl_side == :right
        cr.line_to x + w + 2, y + h + curl
        cr.line_to x - 2, y + h + 2
      else
        cr.line_to x + w + 2, y + h + 2
        cr.line_to x - 2, y + h + curl
      end
      cr.close_path
      picture = cr.source
      black! 0.6
      cr.fill
      @surface.blur 10
      
      cr.move_to x, y
      cr.line_to x + w, y
      cr.line_to x + w, y + h
      cr.line_to x, y + h
      cr.close_path
      
      cr.set_source(picture)
      cr.fill_preserve
      
      white!
      cr.stroke
    end
    photo = layer!
    
    transform cr.matrix.rotate(-theta) do
      black!
      cr.circle x + w/2 + 3, y + 13, 5
      cr.fill
      @surface.blur 10
      

      white! 0.1
      cr.circle x + w/2 + 0.5, y + 10.5, 5
      cr.fill

      linear_gradient 0, y, 0, y + 15, hsl(0, 0, 0.2), hsl(0, 0, 0.0)
      cr.circle x + w/2, y + 10, 5
      cr.fill
    
      white! 0.1
      cr.circle x + w/2 - 2.5, y + 8.5, 4
      cr.fill
    
      linear_gradient 0, y, 0, y + 15, hsl(0, 0, 0.2), hsl(0, 0, 0.0)
      cr.circle x + w/2 - 3, y + 8, 4
      cr.fill
    end
    thumbtack = layer!
    
    paint_layer background
    paint_layer photo
    paint_layer thumbtack
  end
  
  def paint_layer(layer)
    transform Cairo::Matrix.identity do
      cr.set_source(Cairo::SurfacePattern.new(layer))
      cr.paint
    end
  end
  
  def fill_with_noise
    cr.clip
    noise = Cairo::ImageSurface.new(Cairo::FORMAT_A8, @canvas_width, @canvas_height)
    noise.render_noise
    cr.mask(Cairo::SurfacePattern.new(noise))
    cr.reset_clip
  end
end
# Courtyard.preview(:page)
# Courtyard.preview(:organizations_bar)
# Courtyard.preview(:header)
# Courtyard.preview(:map)
# Courtyard.preview(:frame)
Courtyard.preview(:cork_board)
