require 'rubygems'
require 'active_support'
require 'core_ext'

module Color
  def rgb(*args)
    RGB.new(*args)
  end

  def hsl(*args)
    HSL.new(*args)
  end

  class Base
    def self.inherited(subclass)
      components = subclass.name.sub('Color::', '').downcase.split(//).map(&:to_sym)
      components << :a
      components.each_with_index do |component, i|
        subclass.class_eval <<-"end;"
          def #{component}(value=nil)
            if value
              result = self.class.new(@components)
              result.#{component} = value
              result
            else
              @components[#{i}]
            end
          end
          def #{component}=(x)
            @components[#{i}] = constrain(x)
          end
        end;
      end
    end

    def initialize(*components)
      if components[0].is_a?(String)
        @components = []
        self.css = components[0]
      else
        @components = components.flatten.map(&method(:constrain))
      end
      @components << 1.0 if @components.size == 3
    end
    
    def primary_components
      @components[0..-2]
    end
    
    def to_a
      @components
    end

    def -(other)
      self + other.to_a.map(&:-@)
    end

    def +(other)
      other_array = other.to_a
      array = component_indicies.map {|i| @components[i] + (other_array[i] || 0)}
      self.class.new(*array)
    end

    def ==(other)
      other.class == self.class && component_indicies.all? {|i| epsilon(@components[i] - other.to_a[i])}
    end
    
    def to_s
      "<#{self.class.name}: #{@components.join(", ")}>"
    end

    protected
    def component_indicies
      (0..@components.size - 1).to_a
    end

    def epsilon(x)
      x.abs <= 0.01
    end

    def constrain(x)
      x > 1.0 ? 1.0 : x < 0.0 ? 0.0 : x
    end
  end

  class RGB < Base
    def css=(string)
      string.gsub!('#', '')
      self.r, self.g, self.b = string.split(//).in_groups_of(string.length/3).map {|a| a.join.to_i(16).to_f / (16 ** (string.length/3) - 1).to_f}
    end

    def to_hsl
      max = primary_components.max
      min = primary_components.min
      compute_hue = proc do |numerator, degrees|
        degrees(60) * (numerator / (max - min)) + degrees(degrees)
      end
      l = (max + min)/2.0
      s = (epsilon(l) || epsilon(max - min)) ? 0 :
        l <= 0.5 ? (max - min) / (max + min) :
          (max - min) / (2 - (max + min))
      h = epsilon(max - min) ? 0 :
          max == r ? compute_hue[g - b, g >= b ? 0 : 360] :
          max == g ? compute_hue[b - r, 120] :
                     compute_hue[r - g, 240]
      HSL.new(h, s, l, a)
    end

    def to_css
      "%02X" * 3 % @components.map {|c| c * 255}
    end
    
    def to_rgb
      self
    end

    protected
    def degrees(x)
      x.to_f/360.0
    end
  end

  class HSL < Base
    def to_rgb
      return RGB.new(l, l, l, a) if epsilon(s)
      q = l < 0.5 ? l * (1.0 + s) : (l + s) - l * s
      p = 2 * l - q
      tc = [h + 1.0/3.0, h, h - 1.0/3.0]
      tc.map! do |x|
        x < 0 ? x + 1.0 :
          x > 1.0 ? x - 1.0 : x
      end
      rgb = tc.map do |tc|
        tc < 1.0/6.0 ? p + ((q - p) * 6.0 * tc) :
        tc < 3.0/6.0 ? q :
        tc < 4.0/6.0 ? p + ((q - p) * 6.0 * (2.0/3.0 - tc)) : p
      end
      RGB.new(rgb + [a])
    end
    
    def to_hsl
      self
    end

    def to_css
      to_rgb.to_css
    end
    
    def css=(string)
      self.h, self.s, self.l = RGB.new(string).to_hsl.to_a
    end
  end
end
