module Rna
  class CLI < Thor

    desc "init", "Setup rna project"
    long_desc "Sets up config/rna.rb"
    def init
      Rna::Tasks.init
    end

    desc "build", "Builds node.json files"
    long_desc <<EOL
Examples:

1. rna build 

Builds the node.json files based on config/rna.rb and writes them to the ouput folder on the filesystem.

2. rna build -o s3 

Builds the node.json files based on config/rna.rb and writes them to s3 based on the s3 settings in config/s3.yml.  
EOL
    method_option :output, :aliases => '-o', :desc => "specify where to output the generated files to", :default => 'filesystem'
    def build
      Rna::Tasks.build(options.dup.merge(:verbose => true))
    end
  end
  
end