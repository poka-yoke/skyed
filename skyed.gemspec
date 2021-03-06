Gem::Specification.new do |s|
  s.name        = 'skyed'
  s.version     = '0.1.16'
  s.date        = '2016-07-05'
  s.summary     = 'Are you surrounded by sky?'
  s.description = 'A cloudy gem'
  s.authors     = ['Ignasi Fosch']
  s.email       = 'natx@y10k.ws'
  s.files       =  Dir['{bin/*,lib/**/*,templates/*}']
  s.executables << 'skyed'
  s.homepage    = 'http://rubygems.org/gems/skyed'
  s.add_runtime_dependency 'git', ['= 1.2.8']
  s.add_runtime_dependency 'aws-sdk', ['= 2.0.33']
  s.add_runtime_dependency 'gli', ['= 2.12.2']
  s.add_runtime_dependency 'highline', ['= 1.6.21']
  s.license     = 'MIT'
end
