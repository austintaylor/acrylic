class BorderGenerator < ImageGenerator
  attr_accessor :size
  
  def self.preview(image = :border, *args)
    super
  end
  
  def self.suite(prefix, *args)
    super
    self.new.write_css(prefix)
  end
  
  def draw(image, *args)
    @args = args
    super
  end
  
  def set_source
    unless @source
      draw_border(*(@args || []))
      @border = @surface
      @source = Cairo::SurfacePattern.new(@border)
    end
  end
  
  def sass(class_name)
    %{table.#{class_name}
  border-collapse: collapse
  padding: 0
  margin: 0
.#{class_name}
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
    background: url(/images/#{class_name}_tl.png)
  &.tr
    background: url(/images/#{class_name}_tr.png)
  &.bl
    background: url(/images/#{class_name}_bl.png)
  &.br
    background: url(/images/#{class_name}_br.png)
  &.cl
    background: url(/images/#{class_name}_cl.png)
  &.tc
    background: url(/images/#{class_name}_tc.png)
  &.cr
    background: url(/images/#{class_name}_cr.png)
  &.bc
    background: url(/images/#{class_name}_bc.png)
  &.content
    background-color: ##{background_color.to_css}
}
  end
  
  def write_css(name)
    set_source
    path = File.join(File.dirname($0), "../public/stylesheets/sass/#{name}.sass")
    File.open(path, 'w') {|f| f << sass(name)}
  end
  
  def background_color
    set_source
    @border.get_pixel(@border.width/2, @border.height/2)
  end
  
  def self.inherited(c)
    c.image :tl do
      set_source
      slice(size, size, 0, 0)
    end

    c.image :tc do
      set_source
      slice(1, size, size + 1, 0)
    end

    c.image :tr do
      set_source
      slice(size, size, @border.width - size, 0)
    end

    c.image :cl do
      set_source
      slice(size, 1, 0, size + 1)
    end

    c.image :cr do
      set_source
      slice(size, 1, @border.width - size, size + 1)
    end

    c.image :bl do
      set_source
      slice(size, size, 0, @border.height - size)
    end

    c.image :bc do
      set_source
      slice(1, size, size + 1, @border.height - size)
    end

    c.image :br do
      set_source
      slice(size, size, @border.width - size, @border.height - size)
    end
    
    c.image :border, :suite => false do
      draw_border
    end
  end
  
  def slice(sizeX, sizeY, offsetX, offsetY)
    dimensions sizeX, sizeY
    cr.set_source(@source)
    cr.source.matrix = Cairo::Matrix.identity.translate(offsetX, offsetY)
    cr.paint
  end
end
