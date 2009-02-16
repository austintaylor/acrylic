Gem::Specification.new do |s|
  s.name = %q{acrylic}
  s.version = "0.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Austin Taylor", "Paul Nicholson"]
  s.date = %q{2009-02-16}
  s.description = %q{A set of image manipulation tools built on top of Cairo}
  s.extensions = ["ext/image_surface_extensions/extconf.rb"]
  s.files = ["Rakefile", "README", "TODO", "VERSION.yml", "lib/acrylic.rb", "lib/border_generator.rb", "lib/cairo_tools.rb", "lib/color.rb", "lib/core_ext.rb", "lib/curve.rb", "lib/image_generator.rb", "lib/image_surface_extensions.rb", "lib/pascal.rb", "lib/shape.rb", "lib/text_box.rb", "test/bump_map_test.rb", "test/cairo_tools_test.rb", "test/color_test.rb", "test/surface.png", "test/test_helper.rb", "ext/image_surface_extensions/native_image_surface_extensions.c", "ext/image_surface_extensions/extconf.rb"]
  s.has_rdoc = true
  s.homepage = %q{http://github.com/dotjerky/acrylic}
  s.rdoc_options = ["--inline-source", "--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.2.0}
  s.summary = %q{Photoshop for cool people.}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if current_version >= 3 then
      s.add_runtime_dependency(%q<activesupport>, [">= 0"])
    else
      s.add_dependency(%q<activesupport>, [">= 0"])
    end
  else
    s.add_dependency(%q<activesupport>, [">= 0"])
  end
end
