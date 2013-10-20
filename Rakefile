require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = ["spec/spec_helper"] + FileList['spec/**/*_spec.rb']
end
