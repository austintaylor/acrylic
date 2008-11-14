require 'cairo_tools'
class Generator
  include CairoTools
  
  def self.generate_image(path, *options)
    new.generate_image(path, options)
  end

  def self.generate(name, *options)
    generate_image(File.join(File.dirname(__FILE__), "../public/images", name), *options)
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
  
  def self.image(suffix, &block)
    suite_images[suffix] = block
  end

  def self.suite_images
    @suite_images ||= {}
  end

  def self.suite(prefix, *args)
    suite_images.each do |suffix, block|
      generate("#{prefix}_#{suffix}.png", suffix, *args)
    end
  end

  def draw(suffix, *args)
    instance_eval(*args, &self.class.suite_images[suffix])
  end
end
