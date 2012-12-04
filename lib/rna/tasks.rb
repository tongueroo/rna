module Rna
  class Tasks
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
    def self.build(options)
      new(options).build
    end

    def initialize(options={})
      @options = options
      if options[:config_path]
        @dsl = DSL.new(options[:config_path])
      else
        @dsl = DSL.new
      end
    end
    def build
      @dsl.evaluate
      @dsl.build
      @dsl.output(@options)
    end
  end
end