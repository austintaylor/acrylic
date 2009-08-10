require '../lib/acrylic'

class Texture
  def initialize(proc)
    @proc = proc
  end
  
  def generate_surface(w, h)
    @surface = Cairo::ImageSurface.new(w, h)
    0.upto(h) do |y|
      0.upto(w) do |x|
        @surface.set_pixel(x, y, color_for(pixel(x, y)))
      end
    end
  end
  
  def pixel(x, y)
    @proc.call(x.to_f, y.to_f)
  end
  
  def color_for(return_value)
    case return_value
    when Color::Base
      return_value
    end
  end
  
  def surface(w, h)
    generate_surface(w, h) if !@surface
    @surface
  end
end

class NoiseTexture < Texture
  def initialize
    @p = (0..255).to_a.sort_by {rand}
    @g2 = (0..255).map do |i|
      normalize2(random_component, random_component)
    end
  end
  
  def random_component
    (rand(512) - 256).to_f / 256
  end
  
  def normalize2(x, y)
    s = Math.sqrt(x * x + y * y)
    [x/s, y/s]
  end
  
  def gradients_for(x, y)
    bx0, by0 = x.floor & 255, y.floor & 255
    bx1, by1 = (bx0 + 1) & 255, (by0 + 1) & 255
    i, j = @p[bx0], @p[bx1]
    [i + by0, j + by0, i + by1, j + by1].map {|i| @g2[@p[i & 255]]}
  end
  
  def at2(x, y, gradient)
    x * gradient[0] + y * gradient[1]
  end
  
  def s_curve(t)
    t * t * (3.0 - 2.0 * t)
  end
  
  def lerp(t, a, b)
    a + t * (b - a)
  end
  
  def noise(x, y)
    g00, g10, g01, g11 = gradients_for(x, y)
    rx0, ry0 = x - x.floor, y - y.floor
    rx1, ry1 = rx0 - 1, ry0 - 1
    sx, sy = s_curve(rx0), s_curve(ry0)
    
    u = at2(rx0, ry0, g00)
    v = at2(rx1, ry0, g10)
    a = lerp(sx, u, v)
    
    u = at2(rx0, ry1, g01)
    v = at2(rx1, ry1, g11)
    b = lerp(sx, u, v)
    
    lerp(sy, a, b)
  end
  
  def fractal_noise(x, y, iterations)
    power = 0
    result = 0
    iterations.times do
      coefficient = 2 ** power
      result += (1.0 / coefficient) * noise(x * coefficient, y * coefficient)
      power += 1
    end
    result
  end
  
  def pixel(x, y)
    x, y = x.to_f/100, y.to_f/100
    value = fractal_noise(x, y, 6)
    # @gradient ||= Gradient.new([0.6, 0.6, 0.7], [0.6, 0, 1])
    @gradient ||= Gradient.new('#E2D9C0', '#7E5D40')
    z = x * 50
    y = y * 200
    distance = Math.sqrt((50 - z) ** 2 + (50 - y) ** 2)
    p distance
    @gradient.at((Math.sin(distance - value) + 1) / 2)
  end
end

class Gradient
  def initialize(one, two)
    @one = Color::HSL.new(one)
    @two = Color::HSL.new(two)
  end
  
  def at(t)
    components = %w(h s l a).map do |c|
      @one.send(c) + (@two.send(c) - @one.send(c)) * t
    end
    Color::HSL.new(components)
  end
end

class Noise < ImageGenerator
  def self.texture(name, texture=nil, &block)
    define_method(name) do
      texture || Texture.new(block)
    end
  end
  
  texture :noise, NoiseTexture.new
  
  def fill_with(texture)
    cr.set_source Cairo::SurfacePattern.new(texture.surface(@canvas_width, @canvas_height))
    cr.fill
  end
  
  image :test do
    dimensions 100, 100
    cr.rectangle 0, 0, width, height
    # black!
    # cr.fill
    fill_with noise
  end
  preview :test
end
