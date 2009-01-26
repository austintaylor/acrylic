require 'rubygems'
require 'active_support'
require 'cairo'
require 'gdk_pixbuf2'
require 'color'
require 'text_box'
require 'image_surface_extensions'

module CairoTools
  include Color
  attr_reader :surface, :cr, :canvas_height, :canvas_width, :top_margin, :right_margin, :bottom_margin, :left_margin
  attr_accessor :preview

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
  end
  
  def margin(*rect)
    rect = rect + rect if rect.length == 1
    rect = rect + rect if rect.length == 2
    @top_margin, @right_margin, @bottom_margin, @left_margin = rect
    cr.matrix = Cairo::Matrix.identity.translate(left_margin, top_margin)
  end
  
  def width
    canvas_width - right_margin - left_margin
  end
  
  def height
    canvas_height - top_margin - bottom_margin
  end
  
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

  def shadow(radius=3, alpha=1)
    shadow_surface = Cairo::ImageSurface.new(@canvas_width, @canvas_height)
    shadow_cr = Cairo::Context.new(shadow_surface)
    shadow_cr.set_source_rgba(0, 0, 0, alpha)
    shadow_cr.mask(Cairo::SurfacePattern.new(surface))
    shadow_surface.blur(radius)
    shadow_cr.set_source(Cairo::SurfacePattern.new(surface))
    shadow_cr.paint
    @surface = shadow_surface
    @cr = shadow_cr
  end
  
  def get_pixel(x, y)
    @surface.get_pixel(x, y)
  end
  
  def load_image(path, x=0, y=0)
    image = Gdk::Pixbuf.new(File.join(File.dirname($0), path))
    cr.set_source_pixbuf(image)
    cr.source.matrix = Cairo::Matrix.identity.translate(x, y)
  end
  
  def clip!
    i = self.class.new
    w, h = @canvas_width, @canvas_height
    pattern = Cairo::SurfacePattern.new(@surface)
    clip = cr.copy_path
    i.instance_eval do
      dimensions w, h
      cr.append_path clip
      cr.clip
      cr.set_source(pattern)
      cr.paint
    end
    dimensions w, h
    cr.set_source(Cairo::SurfacePattern.new(i.surface))
    cr.paint
  end
  
  def transparent!(alpha)
    i = self.class.new
    w, h = @canvas_width, @canvas_height
    pattern = Cairo::SurfacePattern.new(@surface)
    i.instance_eval do
      dimensions w, h
      cr.set_source(pattern)
      cr.paint_with_alpha(alpha)
    end
    @surface = i.surface
    @cr = i.cr
  end
  
  def draw_image(image, x=0, y=0, a=1)
    i = self.class.new
    i.instance_eval do
      draw(image)
    end
    cr.set_source(Cairo::SurfacePattern.new(i.surface))
    cr.source.matrix = Cairo::Matrix.identity.translate(-x, -y)
    cr.paint_with_alpha(a)
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