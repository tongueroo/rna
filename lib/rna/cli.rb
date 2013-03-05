module Rna
  class CLI < Thor

    desc "init", "Setup rna project"
    long_desc "Sets up config/rna.rb"
    method_option :force, :type => :boolean, :aliases => "-f", :desc => "override existing starter files"
    method_option :project_root, :default => ".", :aliases => "-r", :desc => "project root"
    method_option :quiet, :type => :boolean, :aliases => "-q", :desc => "silence the output"
    def init
      Rna::Task.init(options)
    end

    desc "generate", "Builds node.json files"
    long_desc <<EOL
Examples:

1. rna generate
2. rna g -c  # shortcut

Builds the node.json files based on config/rna.rb and writes them to the ouput folder on the filesystem.

3. rna generate -o s3 

Builds the node.json files based on config/rna.rb and writes them to s3 based on the s3 settings in config/s3.yml.  
EOL
    method_option :output, :aliases => '-o', :desc => "specify where to output the generated files to", :default => 'filesystem'
    method_option :clean, :type => :boolean, :aliases => "-c", :desc => "remove all output files before generating"
    method_option :verbose, :type => :boolean, :aliases => "-v", :desc => "show files being generated"
    method_option :project_root, :default => ".", :aliases => "-r", :desc => "project root"
    def generate
      Rna::Task.generate(options)
      puts "Rna files generated"
    end
  end
  
end