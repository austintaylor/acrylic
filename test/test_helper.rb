$: << File.dirname(__FILE__) + "/../../nitrous/plugin/lib/" << File.dirname(__FILE__) + "/../ext/image_surface_extensions/"
require 'nitrous'
require 'cairo_tools'

class Nitrous::Test
  include CairoTools
  
  def preview
    return unless Nitrous::TestContext.textmate?
    path = File.join(File.dirname($0), "generated.png")
    cr.target.write_to_png(path)
    `open #{path}`
    sleep 1
    File.unlink(path)
  end
end