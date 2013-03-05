module Rna
  class Outputer
    attr_reader :options
    def initialize(options={})
      @options = options
    end
  end
  
  class Filesystem < Outputer
    def run(jsons)
      output_path = options[:output_path] || "output"
      FileUtils.rm_rf(output_path) if options[:clean]
      FileUtils.mkdir(output_path) unless File.exist?(output_path)
      jsons.each do |role,json|
        puts "  #{role}.json" if options[:verbose]
        File.open("#{output_path}/#{role}.json", 'w') {|f| f.write(json) }
      end
    end
  end

  class S3 < Outputer
    attr_reader :config, :s3
    def run(jsons)
      # options[:config] only used for specs
      s3_config_path = options[:s3_config_path] || 'config/s3.yml'
      @config ||= YAML.load(File.read(s3_config_path))
      AWS.config(@config)
      @s3 = AWS::S3.new
      bucket = @s3.buckets[@config['bucket']]
      jsons.each do |role,json|
        puts "  #{role}.json" if options[:verbose]
        bucket.objects.create("#{@config['folder']}/#{role}.json", json)
      end
      self # return outputer object for specs
    end
  end

  class Stdout < Outputer
    def run(jsons)
      jsons.each do |role,json|
        puts "-" * 60
        puts "#{role}:"
        puts json
      end
    end
  end
end