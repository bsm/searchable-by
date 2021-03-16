Gem::Specification.new do |s|
  s.name        = 'searchable-by'
  s.version     = '0.5.8'
  s.authors     = ['Dimitrij Denissenko']
  s.email       = ['dimitrij@blacksquaremedia.com']
  s.summary     = 'Generate search scopes'
  s.description = 'ActiveRecord plugin'
  s.homepage    = 'https://github.com/bsm/sortable-by'
  s.license     = 'Apache-2.0'

  s.files         = `git ls-files -z`.split("\x0").reject {|f| f.start_with?('spec/') }
  s.test_files    = `git ls-files -z -- spec/*`.split("\x0")
  s.require_paths = ['lib']
  s.required_ruby_version = '>= 2.6'

  s.add_dependency 'activerecord'
  s.add_dependency 'activesupport'

  s.add_development_dependency 'bundler'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'rubocop'
  s.add_development_dependency 'rubocop-bsm'
  s.add_development_dependency 'sqlite3'
end
