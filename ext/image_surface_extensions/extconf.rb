require 'mkmf'
require 'rbconfig'

have_header 'stdlib.h'
have_header 'ruby.h'
have_header 'intern.h'
have_library 'cairo'
find_header 'cairo.h', "#{Config::expand(CONFIG['includedir'])}/cairo"
find_header 'rb_cairo.h', Config::expand(CONFIG['sitearchdir'])

create_makefile('native_image_surface_extensions')
