require 'cairo_tools'
require 'shape'
class ImageGenerator
  include Color
  include CairoTools
  attr_accessor :preview, :suite, :suite_options

  def self.colors
    @@colors ||= {}
  end

  def self.color(name, color)
    color = color.respond_to?(:to_hsl) ? color.to_hsl : Color::HSL.new(color)
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
    generate_image(rails_path(name), *options)
  end
  
  def self.rails_path(name)
    File.join(File.dirname($0), "../public/images", name)
  end

  def self.preview(*options)
    return unless $0.match(/#{name.underscore}.rb$/)
    # path = File.join(File.dirname($0), "generated.png")
    path = File.expand_path("~/generated.png")
    options = Array(yield) if block_given?
    instance = self.new
    instance.preview = true
    instance.generate_image(path, options)
    `open #{path}`
    # sleep 1
    # File.unlink(path)
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

  def self.suite(options={}, *args)
    options = {:prefix => options} if options.is_a?(String)
    instance = self.new
    instance.suite = true
    instance.suite_options = options
    suite_images.each do |name|
      filename = [options[:prefix], name, options[:suffix]].compact.join('_')
      instance.generate_image(rails_path("#{filename}.png"), name, *args)
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
          instance_variable_set("@#{ivar}", false)
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
          block = self.class.templates[:#{name}]
          args += Array.new(block.arity - args.length, {}) if block.arity > args.length
          instance_exec(*args, &block)
        end
      end
    end;
  end
  
  def self.namespace(name, &block)
    Namespace.new(self, name).instance_eval(&block)
  end
  
  def self.border(*args, &block)
    name = args.shift if args.first.is_a?(Symbol)
    size = args.shift
    image_name = name || :border
    image(image_name, :suite => false) do
      instance_eval(&block)
      if @suite
        background_color = @surface.get_pixel(@surface.width/2, @surface.height/2)
        write_sass([@suite_options[:prefix], name].compact.join('_'), size, background_color)
      end
    end
    
    namespace(name) do
      image :tl do border_slice(image_name, size, size, 0, 0); end
      image :tc do border_slice(image_name, 1, size, size + 1, 0); end
      image :tr do border_slice(image_name, size, size, -size, 0); end
      image :cl do border_slice(image_name, size, 1, 0, size + 1); end
      image :cr do border_slice(image_name, size, 1, -size, size + 1); end
      image :bl do border_slice(image_name, size, size, 0, -size); end
      image :bc do border_slice(image_name, 1, size, size + 1, -size); end
      image :br do border_slice(image_name, size, size, -size, -size); end
    end
  end
  
  def surface_for(image)
    @cached_surfaces ||= {}
    unless @cached_surfaces[image]
      draw(image)
      @cached_surfaces[image] = @surface
    end
    @cached_surfaces[image]
  end
  
  def border_slice(image, sx, sy, dx, dy)
    surface = surface_for(image)
    dimensions sx, sy
    cr.set_source(Cairo::SurfacePattern.new(surface))
    dx = surface.width + dx if dx < 0
    dy = surface.height + dy if dy < 0
    cr.source.matrix = Cairo::Matrix.identity.translate(dx, dy)
    cr.paint
  end
  
  def sass(prefix, size, background_color)
    %{table.#{prefix}
  border-collapse: collapse
  padding: 0
  margin: 0
.#{prefix}
  &.tl, &.tr, &.bl, &.br, &.tc, &.bc
    height: #{size}px !important
    padding: 0 !important
    border: 0
    margin: 0
  &.tl, &.bl, &.tr, &.br, &.cl, &.cr
    width: #{size}px !important
    padding: 0 !important
    border: 0
    margin: 0
  &.tl
    background: url(/images/#{prefix}_tl.png)
  &.tr
    background: url(/images/#{prefix}_tr.png)
  &.bl
    background: url(/images/#{prefix}_bl.png)
  &.br
    background: url(/images/#{prefix}_br.png)
  &.cl
    background: url(/images/#{prefix}_cl.png)
  &.tc
    background: url(/images/#{prefix}_tc.png)
  &.cr
    background: url(/images/#{prefix}_cr.png)
  &.bc
    background: url(/images/#{prefix}_bc.png)
  &.content
    background-color: ##{background_color.to_css}
}
  end

  def write_sass(prefix, size, background_color)
    path = File.join(File.dirname($0), "../public/stylesheets/sass/#{prefix}.sass")
    File.open(path, 'w') {|f| f << sass(prefix, size, background_color)}
  end
end

class Namespace
  def initialize(target, prefix)
    @target, @prefix = target, prefix
  end
  
  def method_missing(method, *args, &block)
    args[0] = [@prefix, args[0]].compact.join("_").to_sym if args[0] && args[0].is_a?(Symbol)
    @target.send(method, *args, &block)
  end
end
