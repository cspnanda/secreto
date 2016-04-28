Gem::Specification.new do |s|
  s.name        = 'secreto'
  s.version     = '0.0.3'
  s.date        = '2016-04-28'
  s.summary     = "Secreto"
  s.description = "Secreto is a gem to lookup username and password from Thycotic Secret Server"
  s.authors     = ["C S P Nanda"]
  s.email       = 'cspnanda@gmail.com'
  s.files       = ["lib/secreto.rb"]
  s.homepage    = 'https://github.com/cspnanda/secreto'
  s.license     = 'MIT'
  s.add_runtime_dependency 'savon', '~> 2.8'
  s.add_runtime_dependency 'nokogiri', '~> 1.6'
  s.add_runtime_dependency 'crack', '~> 0.4'
  s.add_runtime_dependency 'json', '~> 1.8'
end
