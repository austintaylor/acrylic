class Shape
  include CairoTools
  attr_reader :name, :width, :height, :cr, :proc
  def initialize(name, width, height, proc)
    @name, @width, @height, @proc = name, width, height, proc
  end
  
  def draw(cr, x, y)
    @cr = cr
    transform cr.matrix.translate(x, y) do
      instance_eval(&proc)
    end
  end
end