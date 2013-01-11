module Rna
  class CLI < Thor

    desc "init", "Setup rna project"
    long_desc "Sets up config/rna.rb"
    def init
      Rna::Task.init
    end

    desc "generate", "Builds node.json files"
    long_desc <<EOL
Examples:

1. rna generate

Builds the node.json files based on config/rna.rb and writes them to the ouput folder on the filesystem.

2. rna generate -o s3 

Builds the node.json files based on config/rna.rb and writes them to s3 based on the s3 settings in config/s3.yml.  
EOL
    method_option :output, :aliases => '-o', :desc => "specify where to output the generated files to", :default => 'filesystem'
    method_option :clean, :type => :boolean, :aliases => "-c", :desc => "remove all output files before generating"
    def generate
      Rna::Task.generate(options.dup.merge(:verbose => true))
    end
  end
  
end