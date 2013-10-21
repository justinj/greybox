require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = ["spec/spec_helper"] + FileList['spec/**/*_spec.rb']
end

task :gem do
  sh "yes | gem uninstall greybox; true"
  sh "gem build greybox.gemspec"
  sh "gem install *.gem"
end
