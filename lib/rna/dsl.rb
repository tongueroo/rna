module Rna
  class DSL
    @@default_inherits = nil
    attr_reader :attributes, :rules, :nodejsons
    def initialize(config_path='config/rna.rb')
      @path = config_path
      @scope = nil
      @rules = []
      @roles = []
      @attributes = {}
      @nodejsons = {}
    end

    def evaluate
      instance_eval(File.read(@path), @path)
    end

    def build
      # process roles
      @roles.each do |role|
        @nodejsons[role] = process_role(role)
      end
      @nodejsons
    end
          
    # builds node.json
    # 1. global attributes
    # 2. parent inherited attributes all the way up the inheritance chain
    #    each descendent role overrides it's parent role
    # 3. final attributes from the desired role is built last
    def process_role(role, exclude_global=nil)
      # only compute exclude_global on on top level call and continue passing down recursive stack call
      if exclude_global.nil?
        exclude_global = @attributes['global']['except'].include?(role)
      end

      inherits = @attributes[role]['inherits']
      if inherits
        nodejson = process_role(inherits, exclude_global)
      else
        if exclude_global
          nodejson = {}
        else
          attributes = @attributes['global']['attributes'] || {}
          nodejson = attributes.clone
        end
      end

      # apply each rule to each role's attributes before we do the merge
      @rules.each do |block|
        set_scope(role)
        self.instance_eval(&block)
      end

      attributes = @attributes[role]['attributes'] || {}
      nodejson.merge!(attributes)
      nodejson
    end

    def output(options={})
      jsons = {}
      nodejsons.each do |role,data|
        jsons[role] = JSON.pretty_generate(data)
      end

      outputer = options[:output] || 'filesystem'
      outputer_class = Rna.const_get(outputer.capitalize)
      puts "Building node.json files" if options[:verbose]
      outputer_class.new(options).run(jsons)
    end

    # must be called before every instance_eval of the dsl to set the @scope
    def set_scope(scope,type=Hash)
      @scope = scope
      @attributes[@scope] ||= type.new
    end

    def global_attributes(options={},&block)
      set_scope('global')
      @attributes['global']['except'] = [options[:except]].flatten
      self.instance_eval(&block)
    end
    def default_inherits(role)
      @@default_inherits = role
    end
    # rules are stored in a different place than attributes
    def rule(name=nil,&block)
      @rules << block
    end
    def role(*names,&block)
      names.each do |name|
        evaluate_role(name,&block)
      end
    end
    def evaluate_role(name,&block)
      @roles << name
      set_scope(name)
      instance_eval(&default_block)
      instance_eval(&block) if block_given?
    end

    def default_block
      Proc.new do
        @attributes[@scope]['name'] = @scope
        set 'role', name
        inherits @@default_inherits
      end
    end

    # methods in blocks, right now I'm mixing all the methods from role, rule, global_attributes together, because there's not a lot and its simple this way
    # methods rely on @scope being already via set_scope method
    def name
      @attributes[@scope]['name']
    end
    def set(key, value)
      # puts "%%% @scope #{@scope.inspect}"
      # pp @attributes
      @attributes[@scope]['attributes'] ||= {}
      @attributes[@scope]['attributes'][key] = value
    end
    def inherits(role)
      role = nil if role == @scope # can't inherit itself
      @attributes[@scope]['inherits'] = role
    end
    def run_list(list)
      list = list.collect {|i| "role[#{i}]"}
      set('run_list', list)
    end
  end
end