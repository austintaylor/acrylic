require 'inline'
require 'color'

class Cairo::ImageSurface
  inline(:C) do |builder|
    builder.include '<stdlib.h>'
    builder.include '<cairo.h>'
    builder.include '<rb_cairo.h>'
    builder.include '<intern.h>'
    builder.add_compile_flags '`pkg-config --cflags cairo`'
    builder.add_compile_flags '-I/opt/local/lib/ruby/site_ruby/1.8/i686-darwin9/'
    builder.add_compile_flags '-I/opt/local/lib/ruby/gems/1.8/gems/cairo-1.6.2/src'
    builder.prefix %{
      int zero[1]       = {1};
      int one[3]        = {1, 2, 1};
      int two[5]        = {1, 4, 6, 4, 1};
      int three[7]      = {1, 6, 15, 20, 15, 6, 1};
      int four[9]       = {1, 8, 28, 56, 70, 56, 28, 8, 1};
      int five[11]      = {1, 10, 45, 120, 210, 252, 210, 120, 45, 10, 1};
      int six[13]       = {1, 12, 66, 220, 495, 792, 924, 792, 495, 220, 66, 12, 1};
      int seven[15]     = {1, 14, 91, 364, 1001, 2002, 3003, 3432, 3003, 2002, 1001, 364, 91, 14, 1};
      int eight[17]     = {1, 16, 120, 560, 1820, 4368, 8008, 11440, 12870, 11440, 8008, 4368, 1820, 560, 120, 16, 1};
      int nine[19]      = {1, 18, 153, 816, 3060, 8568, 18564, 31824, 43758, 48620, 43758, 31824, 18564, 8568, 3060, 816, 153, 18, 1};
      int ten[21]       = {1, 20, 190, 1140, 4845, 15504, 38760, 77520, 125970, 167960, 184756, 167960, 125970, 77520, 38760, 15504, 4845, 1140, 190, 20, 1};
      int *triangle[11] = {zero, one, two, three, four, five, six, seven, eight, nine, ten};
      int sums[11]      = {1, 4, 16, 64, 256, 1024, 4096, 16384, 65536, 262144, 1048576};
    }
    builder.c %{
      void blur(int radius) {
        cairo_surface_t *surface = RVAL2CRSURFACE(self);
        unsigned char *data = cairo_image_surface_get_data(surface);
        int width = cairo_image_surface_get_width(surface);
        int height = cairo_image_surface_get_height(surface);
        int stride = cairo_image_surface_get_stride(surface);
        int length = height*stride;

        cairo_surface_t *tmp_surface = cairo_image_surface_create(CAIRO_FORMAT_ARGB32, width, height);
        unsigned char *tmp_data = cairo_image_surface_get_data(tmp_surface);
        
        unsigned char *color;
        double sumr, sumg, sumb, suma;
        int gauss_w = radius*2 + 1;
        int *mask = triangle[radius];
        int gauss_sum = sums[radius];
        int i, j, k, x, y;
        for (i = 0; i < height; i++) {
          for (j = 0; j < width; j++) {
            sumr = sumg = sumb = suma = 0;
            for (k = 0; k < gauss_w; k++) {
              y = i-radius+k;
              if (y > height || y < 0) continue;
              color = data + y*stride + j*4;
              if (color < data || color > data + length) continue;
              suma += color[0]*mask[k];
              sumr += color[1]*mask[k];
              sumg += color[2]*mask[k];
              sumb += color[3]*mask[k];
            }
            color = tmp_data + i*stride + j*4;
            color[0] = suma/gauss_sum;
            color[1] = sumr/gauss_sum;
            color[2] = sumg/gauss_sum;
            color[3] = sumb/gauss_sum;
          }
        }
        for (i = 0; i < height; i++) {
          for (j = 0; j < width; j++) {
            sumr = sumg = sumb = suma = 0;
            for (k = 0; k < gauss_w; k++) {
              int x = j-radius+k;
              if (x > width || x < 0) continue;
              color = tmp_data + i*stride + x*4;
              if (color < tmp_data || color > tmp_data + length) continue;
              suma += color[0]*mask[k];
              sumr += color[1]*mask[k];
              sumg += color[2]*mask[k];
              sumb += color[3]*mask[k];
            }
            color = data + i*stride + j*4;
            color[0] = suma/gauss_sum;
            color[1] = sumr/gauss_sum;
            color[2] = sumg/gauss_sum;
            color[3] = sumb/gauss_sum;
          }
        }
      }
    }
    builder.c %{
      unsigned int get_values(int x, int y) {
        cairo_surface_t *surface = RVAL2CRSURFACE(self);
        unsigned char *data = cairo_image_surface_get_data(surface);
        int width = cairo_image_surface_get_width(surface);
        int height = cairo_image_surface_get_height(surface);
        if (x > width || y > height || x < 0 || y < 0) return Qnil;
        unsigned int *pixel = (unsigned int *) (data + (y*width + x)*4);
        return *pixel;
      }
    }
  end
  
  def get_pixel(x, y)
    integer = get_values(x, y)
    a = integer >> 24 & 0xFF
    r = integer >> 16 & 0xFF
    g = integer >> 8  & 0xFF
    b = integer       & 0xFF
    Color::RGB.new([r, g, b, a].map {|v| v.to_f/255})
  end
end
