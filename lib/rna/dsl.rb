module Rna
  class DSL
    attr_reader :data, :jsons
    def initialize(options={})
      @options = options.dup
      @project_root = options[:project_root] || '.'
      @path = "#{@project_root}/config/rna.rb"
      @options[:output_path] = "#{@project_root}/output"

      @before = nil
      @after = nil
      @roles = []
    end

    def evaluate
      instance_eval(File.read(@path), @path)
      load_roles
    end

    # load any roles defined in project/config/rna/*
    def load_roles
      Dir.glob("#{File.dirname(@path)}/rna/*").each do |path|
        instance_eval(File.read(path), path)
      end
    end

    def settings
      @settings ||= Node.new
    end
    alias_method :set, :settings
    alias_method :node, :settings
    alias_method :default, :settings

    def default_includes(role)
      Role.default_includes = role
    end

    def before(&block)
      @before = {:block => block}
    end

    def after(&block)
      @after = {:block => block}
    end

    def role(*names, &block)
      names.flatten.each {|name| each_role(name, &block) }
    end

    def each_role(name, &block)
      @roles << {:name => name, :block => block}
    end

    def run
      puts "Generating rna files" unless @options[:quiet]
      evaluate
      build
      process
      @options.empty? ? output : output(@options)
    end

    def build
      @data = {:roles => []}
      # build roles
      @roles.each do |r|
        @data[:roles] << Role.new(r[:name], r[:block], @options).build
      end
      @data
    end

    def process
      @jsons = {}
      roles = @data[:roles].collect{|h| h[:name]}
      roles.each do |role|
        @jsons[role] = process_role(role)
      end
      @jsons
    end

    # builds node.json hash
    # 1. pre rule
    # 2. role, going up the includes chain
    # 3. post rule
    def process_role(role, depth=1)
      role_data = @data[:roles].find {|h| h[:name] == role}
      includes = role_data[:includes]
      if includes
        json = process_role(includes, depth+1)
      else
        json = {}
        if @before
          pre_data = Rule.new(role, @before[:block]).build
          json.deep_merge!(pre_data[:attributes])
        end
      end

      attributes = role_data[:attributes] || {}
      json.deep_merge!(attributes)
      # only process post rule at the very last step
      if @after and depth == 1
        post_data = Rule.new(role, @after[:block]).build
        json.deep_merge!(post_data[:attributes])
      end
      json
    end

    def output(options={})
      jsons = {}
      @jsons.each do |role,data|
        role_data = @data[:roles].find {|h| h[:name] == role}
        if role_data[:output]
          jsons[role] = JSON.pretty_generate(data)
        end
      end

      outputer = options[:output] || 'filesystem'
      outputer_class = Rna.const_get(outputer.capitalize)
      puts "Building node.json files:" if options[:verbose]
      outputer_class.new(options).run(jsons)
    end

    class Builder
      def build
        if @block
          @dsl = eval "self", @block.binding
          instance_eval(&@block)
        end        
        @data[:attributes].deep_merge!(set.to_mash)
        @data
      end

      # http://www.dan-manges.com/blog/ruby-dsls-instance-eval-with-delegation
      def settings
        @dsl.settings.to_mash
      end

      def node
        @node ||= Node.new
      end
      alias_method :set, :node

      def role_list(list)
        list = list.collect {|i| "role[#{i}]"}
        run_list(list)
      end

      def run_list(list)
        node[:run_list] = list
      end
    end

    # rules get processed scoed to a specific role
    class Rule < Builder
      attr_reader :role
      def initialize(role, block)
        @role = role
        @block = block
        @data = {
          :attributes => {}
        }
      end

      def name
        @role
      end
    end

    class Role < Builder
      attr_reader :name
      def initialize(name, block, options)
        @name = name
        @block = block
        @options = options

        @data = {
          :name => name,
          :attributes => {},
          :includes => @@default_includes != name ? @@default_includes : nil,
          :output => true
        }
      end

      def self.default_includes=(includes)
        @@default_includes = includes
      end
        
      def role
        @name
      end

      def output(val)
        @data[:output] = val
      end

      def includes(role)
        role = nil if role == @name # can't include itself
        @data[:includes] = role
      end
    end

  end
end