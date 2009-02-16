require 'cairo_tools'
require 'shape'
class ImageGenerator
  include CairoTools
  
  def self.colors
    @@colors ||= {}
  end

  def self.color(name, color)
    color = Color::HSL.new(color)
    colors[name] = color
    self.class_eval <<-"end;"
      def #{name}
        self.class.colors[:#{name}]
      end
      def #{name}!(a=nil)
        set_color(a ? #{name}.a(a) : #{name})
      end
    end;
  end
  
  color :black, '000'
  color :white, 'FFF'
  
  def self.shapes
    @@shapes ||= {}
  end
  
  def self.shape(name, width, height, &block)
    shapes[name] = shape = Shape.new(name, width, height, block)
    define_method("draw_#{name}") do |x, y|
      shape.draw(cr, x, y)
    end
  end
  
  def self.generate_image(path, *options)
    new.generate_image(path, options)
  end

  def self.generate(name, *options)
    generate_image(File.join(File.dirname($0), "../public/images", name), *options)
  end

  def self.preview(*options)
    return unless $0.match(/#{name.underscore}.rb$/)
    path = File.join(File.dirname($0), "generated.png")
    options = Array(yield) if block_given?
    instance = self.new
    instance.preview = true
    instance.generate_image(path, options)
    `open #{path}`
    sleep 1
    File.unlink(path)
  end
  
  def self.image(name, options={:suite => true}, &block)
    images[name] = block
    suite_images << name if options[:suite]
  end
  
  def self.suite_images
    @suite_images ||= []
  end

  def self.images
    @images ||= {}
  end

  def self.suite(options, *args)
    options = {:prefix => options} if options.is_a?(String)
    suite_images.each do |name|
      filename = [options[:prefix], name, options[:suffix]].compact.join('_')
      generate("#{filename}.png", name, *args)
    end
  end

  def draw(suffix, *args)
    instance_eval(*args, &self.class.images[suffix])
  end
  
  def self.variant(*args)
    variants = {}
    options = args.extract_options!
    options[:suite] ||= true
    args.each do |ivar|
      images.each do |name, block|
        proc = lambda do
          instance_variable_set("@#{ivar}", true)
          instance_eval(&block)
        end
        variants[:"#{name}_#{ivar}"] = proc
      end
    end
    images.merge!(variants)
    suite_images.push(*variants.keys) if options[:suite]
  end
  
  def self.templates
    @templates ||= {}
  end
  
  def self.template(name, &block)
    templates[name] = block
    class_eval <<-"end;"
      def self.#{name}(name, *args)
        image name do
          instance_exec(*args, &self.class.templates[:#{name}])
        end
      end
    end;
  end
end
