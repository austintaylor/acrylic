class TextBox
  attr_reader :generator, :lines, :x, :y, :valign, :width
  attr_writer :x, :y, :valign, :width
  def initialize(generator, x, y, width, height, valign)
    @generator, @x, @y, @width, @height, @valign = generator, x, y, width, height, valign
    @lines = []
  end

  def cr
    generator.cr
  end

  def split_lines(text, options)
    text.split(/\r?\n/).each do |line|
      line(line, options)
    end
  end

  def line(text, options={})
    return if text.empty?
    return split_lines(text, options) if text.include?("\n")
    set_options(options)
    extents = cr.text_extents(text)
    options[:line_height] ||= cr.font_extents.height
    if @width && extents.width > width
      lines.push(*wrap(text).map {|line| [line, options]})
    else
      lines << [text, options]
    end
  end

  def set_options(options)
    cr.select_font_face(options[:face] || "Arial", 
      options[:italic] ? Cairo::FontSlant::ITALIC : Cairo::FontSlant::NORMAL, 
      options[:bold] ? Cairo::FontWeight::BOLD : Cairo::FontWeight::NORMAL)
    cr.set_font_size(options[:size]) if options[:size]
  end

  def wrap(text)
    split = text.split(' ')
    lines = []
    line = []
    until split.empty?
      until cr.text_extents(line.join(' ')).width > width || split.empty?
        line << split.shift
      end
      split.unshift(line.pop) if cr.text_extents(line.join(' ')).width > width && line.size > 1
      lines << line.join(' ')
      line = []
    end
    lines
  end

  def draw
    line_y = valign == :center ? y + (@height - height)/2 : y
    cr.line_width = 1
    # cr.rectangle(x, line_y, width, height)
    # cr.stroke
    lines.each do |(line, options)|
      set_options(options)
      baseline = line_y + cr.font_extents.ascent# - cr.font_extents.descent
      draw_line(x, baseline, line, options)
      # cr.move_to(x, baseline); cr.line_to(x+cr.text_extents(line).width, baseline)
      # cr.stroke
      line_y += options[:line_height]
    end
  end

  def draw_line(x, y, text, options)
    start = options[:align] == :center ? (x + width/2 - cr.text_extents(text).width/2) : x
    cr.move_to(start, y)
    cr.show_text(text)
    cr.fill
    if options[:underline]
      cr.line_width = 1
      underline = y + 3
      cr.move_to(start, underline)
      cr.line_to(start + cr.text_extents(text).width, underline)
      cr.stroke
    end
  end

  def move(x, y)
    @x, @y = x, y
  end

  def width
    @width || lines.map {|(text, options)| set_options(options); cr.text_extents(text).width}.max
  end

  def height
    lines.sum do |(line, options)|
      options[:line_height]
    end
  end
end
