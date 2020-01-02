Gem::Specification.new do |s|
  s.name = 'myasteriskconf'
  s.version = '0.1.1'
  s.summary = 'Generates basic Asterisk configurations from a high level config in Markdown format.'
  s.authors = ['James Robertson']
  s.files = Dir['lib/myasteriskconf.rb']
  s.add_runtime_dependency('polyrex-headings', '~> 0.2', '>=0.2.0') 
  s.signing_key = '../privatekeys/myasteriskconf.pem'
  s.cert_chain  = ['gem-public_cert.pem']
  s.license = 'MIT'
  s.email = 'james@jamesrobertson.eu'
  s.homepage = 'https://github.com/jrobertson/myasteriskconf'
end
