# This was used to generate the coefficients for the gaussian blur. It would be better to make it dynamic.

class PascalTriangle
  def pascal_triangle(levels)
    values = [[1]]
    (levels - 1).times do
      level = [1]
      values.last[1..-1].each_with_index do |x, i|
        level << x + values.last[i]
      end
      level << 1
      values << level
    end
    values
  end
  
  def sums(max_radius)
    sums = []
    (max_radius + 1).times do |i|
      sums << 2**(i*2)
    end
    sums
  end
  
  def generate_c(max_radius=10)
    values = pascal_triangle(max_radius*2 + 1).reject {|a| a.size % 2 == 0}
    puts values.inspect.gsub('[', '{').gsub(']', '}')
    puts sums(max_radius).inspect.gsub('[', '{').gsub(']', '}')
  end
end

PascalTriangle.new.generate_c
