#include "ruby.h"
#include <stdlib.h>
#include <cairo.h>
#include <rb_cairo.h>
#include <intern.h>

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

// cr.blur(radius)
static VALUE method_blur(VALUE self, VALUE _radius) {
  int radius = FIX2INT(_radius);

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
  return Qnil;
}

// cr.vertical_blur(radius)
static VALUE method_vertical_blur(VALUE self, VALUE _radius) {
  int radius = FIX2INT(_radius);

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
  return Qnil;
}

// cr.horizontal_blur(radius)
static VALUE method_horizontal_blur(VALUE self, VALUE _radius) {
  int radius = FIX2INT(_radius);

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
  return Qnil;
}

int abs(int x) {
  return x < 0 ? -x : x;
}

// cr.bump_map(height_map, light_x, light_y, light_radius, specular_radius, normal_coefficient=1.0)
static VALUE method_bump_map(int argc, VALUE *argv, VALUE self) {
  VALUE height_map;
  VALUE _light_x;
  VALUE _light_y;
  VALUE _light_radius;
  VALUE _specular_radius;
  VALUE _normal_coefficient;
  
  rb_scan_args(argc, argv, "51", &height_map, &_light_x, &_light_y, &_light_radius, &_specular_radius, &_normal_coefficient);
  if(NIL_P(_normal_coefficient)) _normal_coefficient = DBL2NUM(1.0);

  int light_x = FIX2INT(rb_Integer(_light_x));
  int light_y = FIX2INT(rb_Integer(_light_y));
  int light_radius = FIX2INT(rb_Integer(_light_radius));
  int specular_radius = FIX2INT(rb_Integer(_specular_radius));
  double normal_coefficient = NUM2DBL(rb_Float(_normal_coefficient));

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
      } else {
        int alpha = (magnitude - specular_radius)*255/(light_radius - specular_radius);
        if (alpha > 255) alpha = 255;
        if (alpha < 0) alpha = 0;
        color = 0xFF000000 & (alpha << 24);
      }
      data[y * width + x] = color;
    }
  }
  return Qnil;
}

// cr.downsample(scale)
static VALUE method_downsample(VALUE self, VALUE _scale) {
  int scale = FIX2INT(_scale);

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
  return (CRSURFACE2RVAL(output_surface));
}

//  cr.render_noise
static VALUE method_render_noise(VALUE self) {
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
  return Qnil;
}

// cr.get_values(x, y)
static VALUE method_get_values(VALUE self, VALUE _x, VALUE _y) {
  int x = FIX2INT(_x);
  int y = FIX2INT(_y);

  cairo_surface_t *surface = RVAL2CRSURFACE(self);
  unsigned char *data = cairo_image_surface_get_data(surface);
  int width = cairo_image_surface_get_width(surface);
  int height = cairo_image_surface_get_height(surface);
  if (x > width || y > height || x < 0 || y < 0) return Qnil;
  unsigned int *pixel = (unsigned int *) (data + (y*width + x)*4);
  return UINT2NUM(*pixel);
}

void Init_native_image_surface_extensions() {
  VALUE cKlass = rb_cObject;
  cKlass = rb_const_get(cKlass,rb_intern("Cairo"));
  cKlass = rb_const_get(cKlass,rb_intern("ImageSurface"));
  rb_define_method(cKlass, "blur", (VALUE(*)(ANYARGS))method_blur, 1);
  rb_define_method(cKlass, "vertical_blur", (VALUE(*)(ANYARGS))method_vertical_blur, 1);
  rb_define_method(cKlass, "horizontal_blur", (VALUE(*)(ANYARGS))method_horizontal_blur, 1);
  rb_define_method(cKlass, "bump_map", (VALUE(*)(ANYARGS))method_bump_map, 5);
  rb_define_method(cKlass, "downsample", (VALUE(*)(ANYARGS))method_downsample, 1);
  rb_define_method(cKlass, "render_noise", (VALUE(*)(ANYARGS))method_render_noise, 0);
  rb_define_method(cKlass, "get_values", (VALUE(*)(ANYARGS))method_get_values, 2);
}
