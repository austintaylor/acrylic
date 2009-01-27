# require 'native_image_surface_extensions'
require 'color'

class Cairo::ImageSurface
  inline(:C) do |builder|
    builder.include '<stdlib.h>'
    builder.include '<math.h>'
    builder.include '<cairo.h>'
    builder.include '<rb_cairo.h>'
    builder.include '<intern.h>'
    builder.add_compile_flags '`pkg-config --cflags cairo`'
    builder.add_compile_flags '-I/opt/local/lib/ruby/site_ruby/1.8/i686-darwin9/'
    builder.add_compile_flags '-I/opt/local/lib/ruby/gems/1.8/gems/cairo-1.6.2/src'
    builder.c %{
      void vertical_blur(int radius) {
        cairo_surface_t *surface = RVAL2CRSURFACE(self);
        unsigned char *data = cairo_image_surface_get_data(surface);
        int width = cairo_image_surface_get_width(surface);
        int height = cairo_image_surface_get_height(surface);
        int stride = cairo_image_surface_get_stride(surface);
        int length = height*stride;

        cairo_surface_t *tmp_surface = cairo_image_surface_create(CAIRO_FORMAT_ARGB32, width, height);
        unsigned char *tmp_data = cairo_image_surface_get_data(tmp_surface);
        
        unsigned char *color;
        unsigned char *color2;
        double sumr, sumg, sumb, suma;
        int gauss_w = radius*2 + 1;
        int *mask = triangle[radius];
        int gauss_sum = sums[radius];
        int i, j, k, x, y;
        for (i = 0; i < height; i++) {
          for (j = 0; j < width; j++) {
            color = data + i*stride + j*4;
            if (color < data || color > data + length) continue;
            color2 = tmp_data + i*stride + j*4;
            color2[0] = color[0];
            color2[1] = color[1];
            color2[2] = color[2];
            color2[3] = color[3];
          }
        }
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
      void horizontal_blur(int radius) {
        cairo_surface_t *surface = RVAL2CRSURFACE(self);
        unsigned char *data = cairo_image_surface_get_data(surface);
        int width = cairo_image_surface_get_width(surface);
        int height = cairo_image_surface_get_height(surface);
        int stride = cairo_image_surface_get_stride(surface);
        int length = height*stride;

        cairo_surface_t *tmp_surface = cairo_image_surface_create(CAIRO_FORMAT_ARGB32, width, height);
        unsigned char *tmp_data = cairo_image_surface_get_data(tmp_surface);
        
        unsigned char *color;
        unsigned char *color2;
        double sumr, sumg, sumb, suma;
        int gauss_w = radius*2 + 1;
        int *mask = triangle[radius];
        int gauss_sum = sums[radius];
        int i, j, k, x, y;
        for (i = 0; i < height; i++) {
          for (j = 0; j < width; j++) {
            color = data + i*stride + j*4;
            if (color < data || color > data + length) continue;
            color2 = tmp_data + i*stride + j*4;
            color2[0] = color[0];
            color2[1] = color[1];
            color2[2] = color[2];
            color2[3] = color[3];
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
    builder.prefix %{
      int abs(int x) {
        return x < 0 ? -x : x;
      }
    }
    builder.c %{
      void render_bump_map(VALUE height_map, int light_x, int light_y, int light_radius, int specular_radius, double normal_coefficient) {
        cairo_surface_t *surface = RVAL2CRSURFACE(self);
        unsigned int *data = (unsigned int *) cairo_image_surface_get_data(surface);
        int width = cairo_image_surface_get_width(surface);
        int height = cairo_image_surface_get_height(surface);
        int stride = cairo_image_surface_get_stride(surface);
        int length = height * stride;
        
        cairo_surface_t *height_surface = RVAL2CRSURFACE(height_map);
        unsigned char *height_data = cairo_image_surface_get_data(height_surface);
        
        int x, y;
        for (y = 0; y < height; y++) {
          for (x = 0; x < width; x++) {
            int xnext = y * stride + (x + 1) * 4 - 1;
            int xprev = y * stride + (x - 1) * 4 - 1;
            int xn = (xnext > length || xprev < 0) ? 0 : (height_data[xnext] - height_data[xprev]);
            int ynext = (y + 1) * stride + x * 4 - 1;
            int yprev = (y - 1) * stride + x * 4 - 1;
            int yn = (ynext > length || yprev < 0) ? 0 : (height_data[ynext] - height_data[yprev]);
            int ex = abs(xn*normal_coefficient - x + light_x);
            int ey = abs(yn*normal_coefficient - y + light_y);
            
            if (ex > light_radius - 1) ex = light_radius - 1;
            if (ey > light_radius - 1) ey = light_radius - 1;
            
            unsigned int color;
            int magnitude = (int) sqrtf((float)ex*ex+ey*ey);
            if (magnitude < specular_radius) {
              int alpha = 255 - magnitude*255/specular_radius;
              if (alpha > 255) alpha = 255;
              if (alpha < 0) alpha = 0;
              color = (alpha << 24) + (alpha << 16) + (alpha << 8) + alpha;
              //printf("specular %x\\n", color);
            } else {
              int alpha = (magnitude - specular_radius)*255/(light_radius - specular_radius);
              if (alpha > 255) alpha = 255;
              if (alpha < 0) alpha = 0;
              color = 0xFF000000 & (alpha << 24);
              //printf("diffuse %i\\n", xn);
            }
            data[y * width + x] = color;
          }
        }
      }
    }
    builder.c %{
      VALUE downsample(int scale) {
        cairo_surface_t *surface = RVAL2CRSURFACE(self);
        unsigned int *data = (unsigned int *) cairo_image_surface_get_data(surface);
        int width = cairo_image_surface_get_width(surface);
        int height = cairo_image_surface_get_height(surface);
        
        int w = width / scale;
        int h = height / scale;
        cairo_surface_t *output_surface = cairo_image_surface_create(CAIRO_FORMAT_ARGB32, w, h);
        unsigned int *output_data = (unsigned int *) cairo_image_surface_get_data(output_surface);
        int denominator = scale * scale;
        
        unsigned char * pixel;
        int i, j, k, l;
        int r, g, b, a;
        
        for (i=0; i<w+1; i++) {
          for (j=0; j<h+1; j++) {
            r = g = b = a = 0;
            for (k=0; k<scale; k++) {
              for (l=0; l<scale; l++) {
                pixel = (unsigned char *) (data + (j*scale + l)*width + i*scale + k);
                if (pixel < (unsigned char *) data || pixel > (unsigned char *) (data + width * height)) continue;
                r += pixel[0];
                g += pixel[1];
                b += pixel[2];
                a += pixel[3];
              }
            }
            pixel = (unsigned char *) (output_data + j*w + i);
            if (pixel < (unsigned char *) output_data || pixel > (unsigned char *) (output_data + h*w)) continue;
            pixel[0] = r/denominator;
            pixel[1] = g/denominator;
            pixel[2] = b/denominator;
            pixel[3] = a/denominator;
          }
        }
        return CRSURFACE2RVAL(output_surface);
      }
    }
    builder.c %{
      void render_noise() {
        cairo_surface_t *surface = RVAL2CRSURFACE(self);
        unsigned char *data = cairo_image_surface_get_data(surface);
        int height = cairo_image_surface_get_height(surface);
        int stride = cairo_image_surface_get_stride(surface);
        int length = height * stride;
        
        unsigned char * pixel;
        unsigned char x;
        for (pixel = data; pixel < data + length; pixel++) {
          pixel[0] = (unsigned char) rand() % 255;
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
  
  def bump_map(height_map, light_x, light_y, light_radius, specular_radius, normal_coefficient=1.0)
    render_bump_map(height_map, light_x.to_i, light_y.to_i, light_radius.to_i, specular_radius.to_i, normal_coefficient.to_f)
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