guard 'bundler' do
  watch('Gemfile')
end

guard 'rspec' do
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^lib/rna/(.+)\.rb$}) { |m| "spec/lib/rna_spec.rb" }
  watch(%r{^lib/(.+)\.rb$})     { |m| "spec/lib/rna_spec.rb" }
  # watch('spec/spec_helper.rb')  { "spec" }
end