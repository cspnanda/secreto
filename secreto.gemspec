Gem::Specification.new do |s|
  s.name        = 'secreto'
  s.version     = '0.0.4'
  s.date        = '2016-04-29'
  s.summary     = "Secreto is a gem to interact with Thycotic Secret Server"
  s.description = "Supported operations are create Folder, add Secret, Retrieve a secret"
  s.authors     = ["C S P Nanda"]
  s.email       = 'cspnanda@gmail.com'
  s.files       = ["lib/secreto.rb"]
  s.homepage    = 'https://github.com/cspnanda/secreto'
  s.license     = 'MIT'
  s.required_ruby_version = '>= 1.9.3'
  s.add_runtime_dependency 'savon', '~> 2.8'
  s.add_runtime_dependency 'nokogiri', '~> 1.6'
  s.add_runtime_dependency 'crack', '~> 0.4'
  s.add_runtime_dependency 'json', '~> 1.8'
end
