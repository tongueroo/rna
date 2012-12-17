module Rna
  class DSL
    attr_reader :data, :jsons
    def initialize(options={})
      @options = options

      @path = options[:config_path] || 'config/rna.rb'
      @global_attributes = nil
      @pre_rule = nil
      @post_rule = nil
      @roles = []
    end

    def evaluate
      instance_eval(File.read(@path), @path)
    end

    def global(options={},&block)
      @global = {:options => options, :block => block}
    end

    def default_inherits(role)
      Role.default_inherits = role
    end

    def pre_rule(&block)
      @pre_rule = {:block => block}
    end

    def post_rule(&block)
      @post_rule = {:block => block}
    end

    def role(*names, &block)
      names.each {|name| each_role(name, &block) }
    end

    def each_role(name, &block)
      @roles << {:name => name, :block => block}
    end

    def run
      evaluate
      build
      process
      @options.empty? ? output : output(@options)
    end

    def build
      @data = {
        'global' => nil,
        'roles' => []
      }
      # build global attributes
      @data['global'] = Global.new(@global[:options], @global[:block]).build

      # build roles
      @roles.each do |r|
        @data['roles'] << Role.new(r[:name], r[:block], @options).build
      end

      @data
    end

    def process
      @jsons = {}
      roles = @data['roles'].collect{|h| h['name']}
      roles.each do |role|
        @jsons[role] = process_role(role)
      end
      @jsons
    end

    # builds node.json hash
    # 1. global attributes
    # 2. pre rule
    # 3. role, going up the inherits chain
    # 4. post rule
    def process_role(role, exclude_global=nil, depth=1)
      # only compute exclude_global on on top level call and continue passing down recursive stack call
      if exclude_global.nil?
        exclude_global = @data['global']['except'].include?(role)
      end

      role_data = @data['roles'].find {|h| h['name'] == role}
      inherits = role_data['inherits']
      if inherits
        json = process_role(inherits, exclude_global, depth+1)
      else
        json = exclude_global ? {} : @data['global']['attributes'].clone
        if @pre_rule
          pre_data = Rule.new(role, @pre_rule[:block]).build
          json.merge!(pre_data['attributes'])
        end
      end

      attributes = role_data['attributes'] || {}
      json.merge!(attributes)
      # only process post rule at the very last step
      if @post_rule and depth == 1
        post_data = Rule.new(role, @post_rule[:block]).build
        json.merge!(post_data['attributes'])
      end
      json
    end

    def output(options={})
      jsons = {}
      @jsons.each do |role,data|
        role_data = @data['roles'].find {|h| h['name'] == role}
        if role_data['output']
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
        instance_eval(&@block) if @block
        @data
      end

      def set(key, value)
        @data['attributes'][key] = value
      end
    end

    # rules get processed scoed to a specific role
    class Rule < Builder
      attr_reader :role
      def initialize(role, block)
        @role = role
        @block = block
        @data = {
          'attributes' => {}
        }
      end

      def name
        @role
      end

      def role_list(list)
        list = list.collect {|i| "role[#{i}]"}
        set('run_list', list)
      end

      def run_list(list)
        set('run_list', list)
      end
    end

    class Global < Builder
      def initialize(options, block)
        @options = options
        @block = block
        @data = {
          'except' => [options[:except]].compact,
          'attributes' => {}
        }
      end
    end

    class Role < Builder
      attr_reader :name
      def initialize(name, block, options)
        @name = name
        @block = block
        @options = options

        @data = {
          'name' => name,
          'attributes' => {
            'role' => name
          },
          'inherits' => @@default_inherits != name ? @@default_inherits : nil,
          'output' => true
        }
      end

      def self.default_inherits=(inherits)
        @@default_inherits = inherits
      end
        
      def role
        @name
      end

      def output(val)
        @data['output'] = val
      end

      def inherits(role)
        role = nil if role == @name # can't inherit itself
        @data['inherits'] = role
      end

      def role_list(list)
        list = list.collect {|i| "role[#{i}]"}
        set('run_list', list)
      end

      def run_list(list)
        set('run_list', list)
      end
    end

  end
end