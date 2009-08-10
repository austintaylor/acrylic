require 'cairo_tools'
require 'shape'
class PdfGenerator
  include Color
  include CairoTools
  attr_accessor :preview

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
  
  def self.generate_pdf(path, *options)
    new.generate_pdf(path, options)
  end

  def self.generate_png(path, size, *options)
    new.generate_png(path, size, *options)
  end
  
  def self.preview(*options)
    return unless $0.match(/#{name.underscore}.rb$/)
    path = File.join(File.dirname($0), "generated.pdf")
    options = Array(yield) if block_given?
    instance = self.new
    instance.preview = true
    instance.generate_pdf(path, *options)
    `open #{path}`
  end
  
  
  def self.standard_preview
    preview(&method(:load_most_interesting_organization))
  end
  
  def self.load_most_interesting_organization
    ENV["RAILS_ENV"] = "development"
    require File.expand_path(File.dirname($0) + '/../../config/environment')
    Organization.find(Organization.connection.select_value("select organization_id, count(id) from families where address != '' group by organization_id order by count(id) desc limit 1"))
  end
  
  def initialize
    @hard_references = []
  end
  
  def generate_pdf(path, options)
    @canvas_width, @canvas_height = paper_size.map(&:in)
    @page_number = 1
    @surface = Cairo::PDFSurface.new(path, canvas_width, canvas_height)
    @cr = Cairo::Context.new(surface)
    margin 0
    paint_background
    draw(*options)
    cr.target.finish
  end
  
  def generate_png(path, size, options)
    @one_page = true
    png_width, png_height = size
    @paper_width, @paper_height = paper_size.map(&:in)
    initialize_margins
    @surface = Cairo::ImageSurface.new(png_width, png_height)
    @cr = Cairo::Context.new(surface)
    @cr.scale(png_width.to_f/paper_width, png_height.to_f/paper_height)
    paint_background
    draw(*options)
    cr.target.write_to_png(path)
  end
  
  def paper_size
    [8.5, 11]
  end
  
  def paint_background
    white!
    cr.paint
  end
  
  def include_pdf(name, *args)
    "#{name.to_s}_pdf".classify.constantize.new.draw_on(self, *args)
  end
  
  def end_page(numbered=true)
    show_page_number && @page_number += 1 if numbered
    cr.show_page
  end
  
  def show_page_number
    draw_text_box(left_margin, top_margin + height, width) do |tb|
      tb.line(@page_number.to_s, :face => 'Times New Roman', :size => 12, :align => :center)
    end
  end
  
  def draw_on(pdf, *args)
    @paper_width, @paper_height, @surface, @cr, @page_number = pdf.paper_width, pdf.paper_height, pdf.surface, pdf.cr, pdf.page_number
    @hard_references = pdf.hard_references
    initialize_margins
    paint_background
    draw(*args)
    pdf.page_number = @page_number
  end
end

class Numeric
  def in
    self * 72
  end
end

