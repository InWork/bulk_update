# -*- encoding: utf-8 -*-
require File.expand_path('../lib/bulk_update/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Philip Kurmann"]
  gem.email         = ["philip@kman.ch"]
  gem.description   = %q{Updates a large amount of Records in a highly efficient way}
  gem.summary       = %q{Enhances Active Record with a method for bulk inserts and a method for bulk updates. Both merthods are used for inserting or updating large amount of Records.}
  gem.homepage      = ""

  gem.add_dependency "activerecord"
  gem.add_development_dependency "rspec"
  gem.add_development_dependency "sqlite3"
  gem.add_development_dependency "pry"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "bulk_update"
  gem.require_paths = ["lib"]
  gem.version       = BulkUpdate::VERSION
end
