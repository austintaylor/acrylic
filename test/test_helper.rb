$: << File.dirname(__FILE__) + "/../../nitrous/plugin/lib/"
require 'nitrous'
require 'cairo_tools'

class Nitrous::Test
  include CairoTools
  
  def preview
    path = File.join(File.dirname($0), "generated.png")
    cr.target.write_to_png(path)
    `open #{path}`
    sleep 1
    File.unlink(path)
  end
end