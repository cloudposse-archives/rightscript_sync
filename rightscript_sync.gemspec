# -*- encoding: utf-8 -*-
require File.expand_path('../lib/rightscript_sync/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Erik Osterman"]
  gem.email         = ["e@osterman.com"]
  gem.description   = %q{RightScript Sync is a utility to synchronize all scripts in a RightScale account with the local filesystem. It will download all versions and all attachments. It will not redownload files which have identical md5 checksums.}
  gem.summary       = %q{RightScript Sync is a utilty for synchronizizing RightScripts to a local filesystem.}
  gem.homepage      = "https://github.com/osterman/rightscript_sync"
  gem.license       = "GPL3"
  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "rightscript_sync"
  gem.require_paths = ["lib"]
  gem.version       = RightScriptSync::VERSION
  gem.add_runtime_dependency "nokogiri", ">= 1.5.2"
  gem.add_runtime_dependency "mechanize", ">= 2.5.1"
  gem.add_runtime_dependency "json", ">= 1.5.3"
end
