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
Builds the node.json files based on config/rna.rb and writes them to the output.

2. rna --output s3 build
Builds the node.json files based on config/rna.rb and writes them to s3 based on the s3 settings in config/s3.yml.  

The s3.yml should look like this:
credentials:
  access_key_id: abc
  secret_access_key: abc
  bucket: test-bucket
  folder: chef/nodejsons

3. rna  --config config/appcluster.rb build
Builds the node.json files based on config/appcluster.rb instead and writes to the output folder.  
EOL
    method_option :output, :aliases => '-o', :desc => "specify where to output the generated files to", :default => 'filesystem'
    def build
      Rna::Tasks.build(options.dup)
    end
  end
  
end