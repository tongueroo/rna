module Rna
  class Task
    def self.init(project_root=".",options={})
      puts "Settin up rna project" unless options[:quiet]
      FileUtils.mkdir("#{project_root}/config") unless File.exist?("#{project_root}/config")
      %w/rna.rb s3.yml Guardfile/.each do |name|
        source = File.expand_path("../../files/#{name}", __FILE__)
        dest = "#{project_root}/config/#{File.basename(source)}"
        dest = "#{project_root}/#{File.basename(source)}" if name == 'Guardfile'
        if File.exist?(dest)
          puts "already exists: #{dest}" unless options[:quiet]
        else
          puts "creating: #{dest}" unless options[:quiet]
          FileUtils.cp(source, dest)
        end
      end
    end
    def self.generate(options)
      new(options).generate
    end

    def initialize(options={})
      @options = options
      @dsl = options[:config_path] ? DSL.new(options) : DSL.new
    end
    def generate
      @dsl.run
    end
  end
end