require 'rubygems'
require 'active_support'
require 'cairo'
require 'gdk_pixbuf2'
require 'color'
require 'text_box'
require 'image_surface_extensions'
require 'inline'

module CairoTools
  attr_reader :surface, :cr, :canvas_height, :canvas_width, :top_margin, :right_margin, :bottom_margin, :left_margin

  def generate_image(path, options)
    # dummy context is useful sometimes
    @surface = Cairo::ImageSurface.new(1, 1)
    @cr = Cairo::Context.new(surface)
    draw(*options)
    cr.target.write_to_png(path)
  end

  def dimensions(width, height)
    @canvas_width, @canvas_height = width, height
    @surface = Cairo::ImageSurface.new(width, height)
    @cr = Cairo::Context.new(surface)
    margin(0)
  end
  
  # Set margins on the image
  # If you pass one argument, that is set as the margin on all sides.
  # If you pass two arguments, the first one is set on the top and bottom, and the second one is set on the sides.
  # If you pass four arguments, the order is top, right, bottom, left.
  def margin(*rect)
    rect = rect + rect if rect.length == 1
    rect = rect + rect if rect.length == 2
    @top_margin, @right_margin, @bottom_margin, @left_margin = rect
    cr.matrix = Cairo::Matrix.identity.translate(left_margin, top_margin)
  end
  
  # Returns the width of the canvas inside the margins
  def width
    canvas_width - right_margin - left_margin
  end
  
  # Returns the height of the canvas inside the margins
  def height
    canvas_height - top_margin - bottom_margin
  end
  
  # Set a different matrix for the duration of the block. The old matrix is reset afterward.
  def transform(matrix, &block)
    old_matrix = cr.matrix
    cr.matrix = matrix
    yield
    cr.matrix = old_matrix
  end

  # http://www.cairographics.org/cookbook/roundedrectangles/
  def rounded_rectangle(x, y, w, h, radius_x=5, radius_y=radius_x)
    arc_to_bezier = 0.55228475
    radius_x = w / 2 if radius_x > w - radius_x
    radius_y = h / 2 if radius_y > h - radius_y
    c1 = arc_to_bezier * radius_x
    c2 = arc_to_bezier * radius_y

    cr.new_path
    cr.move_to(x + radius_x, y)
    cr.rel_line_to(w - 2 * radius_x, 0.0)
    cr.rel_curve_to(c1, 0.0, radius_x, c2, radius_x, radius_y)
    cr.rel_line_to(0, h - 2 * radius_y)
    cr.rel_curve_to(0.0, c2, c1 - radius_x, radius_y, -radius_x, radius_y)
    cr.rel_line_to(-w + 2 * radius_x, 0)
    cr.rel_curve_to(-c1, 0, -radius_x, -c2, -radius_x, -radius_y)
    cr.rel_line_to(0, -h + 2 * radius_y)
    cr.rel_curve_to(0.0, -c2, radius_x - c1, -radius_y, radius_x, -radius_y)
    cr.close_path
  end

  # Draw text on a circular path.
  def circular_text(x, y, radius, font_size, text)
    radians = proc {|text| cr.set_font_size(font_size); cr.text_extents(text).x_advance/radius}
    blank = (2*Math::PI - radians[text])/2
    start = blank + Math::PI/2
    partial = ''
    text.split(//).each do |letter|
      theta = start + radians[partial]
      cr.move_to(x+radius*Math.cos(theta), y+radius*Math.sin(theta))
      cr.set_font_matrix Cairo::Matrix.identity.rotate(theta + Math::PI/2).scale(font_size, font_size)
      cr.show_text letter
      theta += radians[letter]
      partial << letter
    end
  end

  def create_text_box(x, y, width=nil, height=nil, valign=:top)
    TextBox.new(self, x, y, width, height, valign)
  end

  def draw_text_box(x, y, width=nil, height=nil, valign=:top)
    tb = create_text_box(x, y, width, height, valign)
    yield tb
    tb.draw
  end

  # Set the current source using a color object.
  def set_color(color)
    cr.set_source_rgba(*color.to_rgb.to_a)
  end

  def linear_gradient(x0, y0, x1, y1, *colors)
    gradient(Cairo::LinearPattern.new(x0, y0, x1, y1), *colors)
  end

  def radial_gradient(cx0, cy0, r0, cx1, cy1, r1, *colors)
    gradient(Cairo::RadialPattern.new(cx0, cy0, r0, cx1, cy1, r1), *colors)
  end

  def gradient(gradient, *colors)
    colors.each_with_index do |color, i|
      array = color.respond_to?(:to_rgb) ? color.to_rgb.to_a : color.to_a
      gradient.add_color_stop(i.to_f/(colors.length - 1), *array)
    end
    cr.set_source(gradient)
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
  
  # Create a new canvas and return the old one.
  def layer!
    surface = @surface
    t, r, b, l = @top_margin, @right_margin, @bottom_margin, @left_margin
    dimensions @canvas_width, @canvas_height
    margin t, r, b, l
    surface
  end
  
  # Paint a canvas on top of the current one.
  def paint_layer(layer, a=1)
    transform Cairo::Matrix.identity do
      cr.set_source(Cairo::SurfacePattern.new(layer))
      cr.paint_with_alpha(a)
    end
  end
  
  # Fill each pixel in the current path with the current source at random opacity.
  def fill_with_noise
    cr.clip
    noise = Cairo::ImageSurface.new(Cairo::FORMAT_A8, @canvas_width, @canvas_height)
    noise.render_noise
    cr.mask(Cairo::SurfacePattern.new(noise))
    cr.reset_clip
  end
  
  # Call another image block and paint it on the current canvas.
  # Image: Reference to a block in this file (e.g. :image_name) or in another file in the same directory (e.g. file/image).
  # X & Y: Offset of the image when drawn.
  # Alpha: Alpha value of the image when drawn.
  # Scale: Scale of the image when drawn.
  def draw_image(image, x=0, y=0, a=1, scale=1)
    if image.to_s.include?('/')
      klass, image = image.to_s.split('/')
      require File.dirname(__FILE__) + '/' + klass
      i = klass.capitalize.constantize.new
    else
      i = self.class.new
    end
    i.instance_eval do
      draw(image.to_sym)
    end
    cr.set_source(Cairo::SurfacePattern.new(i.surface))
    cr.source.matrix = Cairo::Matrix.identity.scale(1/scale, 1/scale).translate(-x, -y)
    cr.paint_with_alpha(a)
  end
  
  # Erase everything outside of the current path.
  def clip!
    clip = cr.copy_path
    original = layer!
    cr.append_path clip
    cr.clip
    paint_layer original
    cr.reset_clip
  end
  
  # Set transparency on the contents of the entire canvas.
  def transparent!(a)
    original = layer!
    paint_layer original, a
  end
  
  # Rotate the contents of the canvas around a point.
  def rotate!(theta, x=0, y=0)
    layer = layer!
    cr.set_source(Cairo::SurfacePattern.new(layer))
    cr.source.matrix = Cairo::Matrix.identity.translate(x, y).rotate(theta)
    cr.matrix = Cairo::Matrix.identity
    cr.paint
  end
  
  # Flip the contents of the canvas. Direction can be :horizontal, :vertical, or :both
  def flip!(direction)
    case direction
    when :horizontal
      x, y = true, false
    when :vertical
      x, y = false, true
    when :both
      x, y = true, true
    end
    layer = layer!
    cr.set_source(Cairo::SurfacePattern.new(layer))
    cr.source.matrix = Cairo::Matrix.identity.scale(x ? -1 : 1, y ? -1 : 1).translate(x ? -width : 0, y ? -height : 0)
    cr.matrix = Cairo::Matrix.identity
    cr.paint
  end
  
  # Resize the canvas from the top left corner, preserving the content that fits.
  def crop!(w, h)
    s = @surface
    t, l, b, r = @top_margin, @left_margin, @bottom_margin, @right_margin
    dimensions w, h
    transform Cairo::Matrix.identity do
      paint_layer s
    end
    margin t, l, b, r
  end
  
  # A convenience method for drawing a single line of text.
  def draw_text(x, y, text, options={})
    draw_text_box x, y do |tb|
      tb.line(text, options)
    end
  end
  
  # Draw a shadow behind either the current image, or of whatever is drawn in the provided block.
  # Radius: The blur radius for the shadow. Defaults to 3. Max value is 10.
  # Alpha/color: If a number is passed, this is set as the alpha value on the black shadow.
  #              If a color is passed, this is used instead of black.
  def shadow(radius=3, alpha=1)
    if block_given?
      bg = layer!
      yield
    end
    
    color = alpha.respond_to?(:to_rgb) ? alpha : black.a(alpha)
    original = layer!
    set_color color
    transform Cairo::Matrix.identity do
      cr.mask(Cairo::SurfacePattern.new(original))
    end
    @surface.blur(radius)
    paint_layer original
    
    if block_given?
      fg = layer!
      paint_layer bg
      paint_layer fg
    end
  end
  
  # Inner shadow clipped to the current path.
  def inner_shadow(line_width=5, blur_radius=5, alpha=1)
    color = alpha.respond_to?(:to_rgb) ? alpha : black.a(alpha)
    path = cr.copy_path
    original = layer!
    cr.append_path path
    cr.line_width = line_width
    set_color color
    cr.stroke_preserve
    @surface.blur blur_radius
    clip!
    shadow = layer!
    paint_layer original
    paint_layer shadow
  end
  
  # Return the color value at a pixel.
  def get_pixel(x, y)
    @surface.get_pixel(x, y)
  end
  
  def load_image(path, x=0, y=0)
    image = Gdk::Pixbuf.new(File.join(File.dirname($0), path))
    cr.set_source_pixbuf(image)
    cr.source.matrix = Cairo::Matrix.identity.translate(x, y)
  end
  
  def clouds
    Cairo::ImageSurface.new(129, 129)
  end
end

class Cairo::Context
  inline(:C) do |builder|
    builder.include '<stdlib.h>'
    builder.include '<cairo.h>'
    builder.include '<rb_cairo.h>'
    builder.include '<intern.h>'
    builder.add_compile_flags '`/opt/local/bin/pkg-config --cflags cairo`'
    builder.add_compile_flags '-I/opt/local/lib/ruby/site_ruby/1.8/i686-darwin9/'
    builder.add_compile_flags '-I/opt/local/lib/ruby/gems/1.8/gems/cairo-1.6.2/src'
    builder.c %{
      void paint_with_alpha(double alpha) {
        cairo_t *cr = RVAL2CRCONTEXT(self);
        cairo_paint_with_alpha(cr, alpha);
      }
    }
  end
end