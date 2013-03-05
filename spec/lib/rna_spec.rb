require File.expand_path("../../spec_helper", __FILE__)

describe Rna do
  before(:each) do
    @project = File.expand_path("../../project", __FILE__)
    FileUtils.mkdir(@project) unless File.exist?(@project)
    execute("./bin/rna init -f -q --project-root #{@project}")
  end

  after(:each) do
    FileUtils.rm_rf("#{@project}/output")
  end

  describe "cli specs" do
    it "should generate templates" do
      out = execute("./bin/rna generate -c --project-root #{@project}")
      out.should match /Generating rna files/
    end
  end

  describe "ruby specs" do
    before(:each) do
      @dsl = Rna::DSL.new(
        :quiet => true,
        :project_root => @project
      ) 
    end

    it "should build attributes" do
      @dsl.evaluate
      @dsl.build
      pp @dsl.data
      @dsl.process
      pp @dsl.jsons
    end if ENV['DEBUG']

    it "should write json files to outputs folder" do
      @dsl.run
      Dir.glob("#{@project}/output/*").size.should > 0
    end

    # complete end to end tests
    it "base.json should contain correct attributes" do
      @dsl.run
      base = JSON.load(IO.read("#{@project}/output/base.json"))
      base['role'].should == 'base'
      base['run_list'].should == ["role[base]"]
    end

    it "base.json should not contain settings attributes" do
      @dsl.run
      base = JSON.load(IO.read("#{@project}/output/base.json"))
      base['framework_env'].should be_nil
      base['deploy_code'].should be_nil
    end

    it "prod-api-redis.json should contain base and settings attributes" do
      @dsl.run
      json = JSON.load(IO.read("#{@project}/output/prod-api-redis.json"))
      json['role'].should == 'prod-api-redis'
      json['run_list'].should == ["role[base]", "role[api_redis]"]
      json['framework_env'].should == 'production'
      json['deploy_code'].should == nil
    end

    it "prod-api-resque should contain inherited attributes" do
      @dsl.run
      json = JSON.load(IO.read("#{@project}/output/prod-api-resque.json"))
      json['role'].should == 'prod-api-resque'
      json['run_list'].should == ["role[base]","role[api_resque]"]
      json['deploy_code'].should == true
      json['framework_env'].should == 'production'
      json['scout'].should be_a(Hash)
      json['database']['adapter'].should == "mysql"
      json['scout'].should be_a(Hash)
    end

    it "stag-api-redis.json should contain base and settings attributes and apply rules" do
      @dsl.run
      json = JSON.load(IO.read("#{@project}/output/stag-api-redis.json"))
      json['role'].should == 'stag-api-redis'
      json['run_list'].should == ["role[base]", "role[api_redis]"]
      json['deploy_code'].should == nil
      json['framework_env'].should == 'staging' # this is tests the rule
    end

    it "prod-api-app.json should contain base and settings attributes" do
      @dsl.run
      json = JSON.load(IO.read("#{@project}/output/prod-api-app.json"))
      json['role'].should == 'prod-api-app'
      json['run_list'].should == ["role[base]","role[api_app]"]
      json['deploy_code'].should == true
      json['framework_env'].should == 'production'
      json['scout'].should be_a(Hash)
    end

    it "prod-api-app.json should contain attributes from node" do
      @dsl.run
      json = JSON.load(IO.read("#{@project}/output/prod-api-app.json"))
      json['database']['user'].should == 'user'
      json['database']['pass'].should == 'pass'
      json['database']['host'].should == '127.0.0.1'
    end

    it "prod-api-app.json should contain pre and post rules" do
      @dsl.run
      json = JSON.load(IO.read("#{@project}/output/prod-api-app.json"))
      json['role'].should == 'prod-api-app'
      json['run_list'].should == ["role[base]","role[api_app]"]
      json['deploy_code'].should == true
      json['framework_env'].should == 'production'
      json['scout'].should be_a(Hash)
      json['pre_rule'].should == 1
      json['post_rule'].should == 2
    end

    it "masta-app should not generate output file" do
      @dsl.run
      File.exist?("#{@project}/output/masta-app.json").should be_false
      File.exist?("#{@project}/output/prod-masta-android.json").should be_true
      json = JSON.load(IO.read("#{@project}/output/prod-masta-android.json"))
      json['masta_app'].should == 123
    end

    it "should be able to read shared settings" do
      @dsl.run
      File.exist?("#{@project}/output/masta-app.json").should be_false
      File.exist?("#{@project}/output/prod-masta-android.json").should be_true
      json = JSON.load(IO.read("#{@project}/output/prod-masta-android.json"))
      json['relayhost'].should == "smtp.sendgrid.net"
      json = JSON.load(IO.read("#{@project}/output/prod-api-app.json"))
      json['relayhost'].should == "smtp.sendgrid.net"
    end
    ###################

    # only run when S3=1, will need to setup spec/project/config/s3.yml
    it "should upload to s3" do
      @dsl = Rna::DSL.new(
        :output => 's3', 
        :s3_config_path => "#{@project}/config/s3.yml",
        :project_root => @project
      )
      outputer = @dsl.run

      config = outputer.config
      s3 = outputer.s3
      bucket = s3.buckets[config['bucket']]
      raw = bucket.objects["#{config['folder']}/prod-api-app.json"].read

      json = JSON.load(raw)
      json['role'].should == 'prod-api-app'
      json['run_list'].should == ["role[base]","role[api_app]"]
      json['deploy_code'].should == true
      json['framework_env'].should == 'production'
      json['scout'].should be_a(Hash)
      # clean up
      tree = bucket.as_tree(:prefix => config['folder'])
      tree.children.select(&:leaf?).each do |leaf|
        leaf.object.delete
      end 
    end if ENV['S3'] == '1'

    it "task init should set up project" do
      File.exist?("#{@project}/config/s3.example.yml").should be_true
      File.exist?("#{@project}/config/rna.rb").should be_true
    end

    it "task build should generate node.json files" do
      Rna::Task.generate(
        :quiet => true,
        :project_root => @project
      )
      json = JSON.load(IO.read("#{@project}/output/prod-api-app.json"))
      json['role'].should == 'prod-api-app'
      json['run_list'].should == ["role[base]","role[api_app]"]
      json['deploy_code'].should == true
      json['framework_env'].should == 'production'
      json['scout'].should be_a(Hash)
    end
  end

end

describe Node do
  before(:each) do
    @node = Node.new
  end

  it "should be able to set multiple levels deep even" do
    @node[:a][:b][:c] = 2
    @node[:a][:b][:c].should == 2
  end

  it "should convert to a hash with symbols as keys" do
    @node[:a][:b][:c] = 2
    @node[:a][:b][:c].should == 2
    hash = @node.to_hash
    # uncomment to see hash structure
    # pp hash
    # pp hash[:a][:b]
    hash[:a][:b][:c].should == 2
  end

  it "should convert to a mash" do
    @node[:a][:b][:c] = 2
    @node[:a][:b][:c].should == 2
    hash = @node.to_mash
    # uncomment to see hash structure
    # pp hash
    # pp hash[:a][:b]
    hash[:a][:b][:c].should == 2
    hash['a'][:b]['c'].should == 2
  end

  it "should raise error if namespace is a non-node value and you try to access a value below that" do
    @node[:a][:b] = 4
    # this errors because it will run: 4[:c]
    expect { @node[:a][:b][:c].class.should be_a(Node) }.to raise_error(TypeError)
  end

  it "should not adjust values set in other namespaces" do
    @node[:a][:b][:c] = 2
    @node[:a][:b][:c].should == 2
    @node[:a][:b2] = 3
    @node[:a][:b2].should == 3
    @node[:a][:b][:c].should == 2
    @node[:a][:b2].should == 3
    @node[:a][:b3][:c] = 5
    @node[:a][:b3][:c].should == 5
  end

  it "should behave like a mash" do
    @node[:a][:b] = 4
    @node[:a][:b].should == 4
    @node[:a]['b'].should == 4

    @node[:a]['c'] = 5
    @node[:a][:c].should == 5
    @node[:a]['c'].should == 5
  end

  it "should default to an empty Node object if never been set" do
    @node[:one].should be_a(Node)
    @node[:all][:roads][:lead][:to][:nothing].should be_a(Node)
  end

  it "should be able to set nil" do
    @node[:a][:b4][:c] = nil
    @node[:a][:b4][:c].should == nil
  end

  it "should be able to set false" do
    @node[:a][:b4][:c] = false
    @node[:a][:b4][:c].should == false
  end
end