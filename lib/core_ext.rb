class Symbol
  def self.pattern(name, pattern, &formation)
    define_method(name) {to_s.match(pattern) ? self : formation.call(self).to_sym}
    define_method(name.question) {to_s.match(pattern)}
  end
  pattern(:question, /\?$/) {|s| "#{s}?"}
  pattern(:bang, /!$/) {|s| "#{s}!"}
  pattern(:writer, /=$/) {|s| "#{s}="}
  pattern(:iv, /^@[^@]/) {|s| "@#{s}"}
end

class Numeric
  def deg
    self / 180.0 * Math::PI
  end
end
