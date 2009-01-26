require 'native_image_surface_extensions'
require 'color'

class Cairo::ImageSurface
  def get_pixel(x, y)
    integer = get_values(x, y)
    a = integer >> 24 & 0xFF
    r = integer >> 16 & 0xFF
    g = integer >> 8  & 0xFF
    b = integer       & 0xFF
    Color::RGB.new([r, g, b, a].map {|v| v.to_f/255})
  end
end