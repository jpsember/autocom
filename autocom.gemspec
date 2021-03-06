require 'rake'

Gem::Specification.new do |s|
  s.name        = 'autocom'
  s.version     = '0.0.1'
  s.date        = '2013-12-04'
  s.summary     = "Autocompletion"
  s.description =<<-EOS
Introducing a Prediction Tree, a data structure that efficiently suggests the most
probable n completions for a word.
EOS
  s.authors     = ["Jeff Sember"]
  s.email       = 'jpsember@gmail.com'
  s.files = FileList['lib/**/*.rb',
                      'bin/*',
                      '[A-Z]*',
                      'test/**/*',
                      ]
  s.executables << 'autocom'
  s.add_runtime_dependency 'js_base'
  s.add_runtime_dependency 'tokn',[">= 1.0.0"]

  s.homepage    = 'http://www.cs.ubc.ca/~jpsember'
  s.test_files  = Dir.glob('test/*.rb')
  s.license     = 'MIT'
end
