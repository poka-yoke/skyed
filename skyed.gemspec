# rubocop:disable Style/SpaceAroundOperators
Gem::Specification.new do |s|
  s.name                   = 'skyed'
  s.version                = '0.2.0.dev'
  s.date                   = '2016-02-04'
  s.summary                = 'Are you surrounded by sky?'
  s.description            = 'A cloudy gem'
  s.authors                = ['Ignasi Fosch']
  s.email                  = 'natx@y10k.ws'
  s.files                  =  Dir['{bin/*,lib/**/*,templates/*}']
  s.executables            << 'skyed'
  s.homepage               = 'http://rubygems.org/gems/skyed'
  s.add_runtime_dependency 'git', ['= 1.2.8']
  s.add_runtime_dependency 'aws-sdk', ['~> 2.0.0']
  s.add_runtime_dependency 'thor', ['= 0.19.1']
  s.license                = 'MIT'
end
