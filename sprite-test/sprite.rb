require '../lib/acrylic'
class Sprite < ImageGenerator
  image :sprite do
    frames 30 do |i|
      dimensions 30, 30
      margin 2
      cr.circle(width/2, height/2, i.to_f/3 + 2)
      black!
      cr.fill
    end
  end
  
  color :background, '999'
  image :spinner do
    # Spinner from Proventys: 8.7KB (256 colors, optimized)
    # PNG version: 20.1KB (32bit color, no frame-based optimization)
    # Arguably, the PNG wins based on color depth
    # I think this approach is entirely justified in cases where the improved quality is desired.
    # Benefits: framerate, color depth, and alpha channel
    frames 12 do |time|
      dimensions 240, 124
      background!
      cr.paint

      12.times do |i|
        cr.matrix = Cairo::Matrix.identity.translate(width/2, height/2 - 12).rotate((i*30).deg)
        rounded_rectangle(20/2, -3/2, 26/2, 6/2, 4, 4)
        brightness = (12 - (i < time ? i + 12 - time : i - time))
        cr.set_source_rgba(1, 1, 1, [1.0 - (brightness.to_f/8), 0.1].max)
        cr.fill
      end
      cr.matrix = Cairo::Matrix.identity
      tb = create_text_box(0, height - 40, width, 20, :center)
      tb.line("Calculating Risk Score", :face => 'Helvetica', :size => 20, :align => :center)
      white!
      tb.draw
    end
  end
  
  image :dummy do
    dimensions 1, 1
  end
  
  def frames(count, &block)
    frames = (0..count).collect do |i|
      yield i
      @surface
    end
    dimensions frames.first.width * count, frames.first.height
    frames.each_with_index do |frame, i|
      cr.set_source(Cairo::SurfacePattern.new(frame))
      cr.source.matrix = Cairo::Matrix.identity.translate(-frames.first.width * i, 0)
      cr.paint
    end
  end
  
  preview :spinner
  # generate_image './sprite_frames.png', :sprite
  # generate_image './dummy.png', :dummy
end
