require 'rna'
require 'rspec'
require 'pp'

describe Rna do
  before(:each) do
    @project_root = File.expand_path("../../project", __FILE__)
    @project2_root = File.expand_path("../../project2", __FILE__)
    @dsl = Rna::DSL.new("#{@project_root}/config/rna.rb")
    @dsl.evaluate
  end

  after(:each) do
    FileUtils.rm_rf("#{@project_root}/nodejson")
  end

  it "evaluate global attributes data to be used later to merge the nodejson structures together" do
    attributes = @dsl.attributes
    attributes.should be_a(Hash)
    # pp attributes
    attributes['global']['attributes']['application'].should be_nil
    attributes['global']['attributes']['deploy_code'].should be_false
    attributes['global']['attributes']['framework_env'].should == 'production'
    attributes['global']['attributes']['repository'].should be_nil
  end

  it "evaluate base attributes data that does not include the global attributes" do
    attributes = @dsl.attributes
    attributes.should be_a(Hash)
    attributes['base']['attributes'].keys.should_not include('application')
    attributes['base']['attributes']['run_list'].should == ["role[base]"]
  end

  it "evaluate base attributes data should not inherit itself" do
    attributes = @dsl.attributes
    attributes.should be_a(Hash)
    attributes['base']['inherits'].should be_nil
  end

  it "roles without blocks should run the default block" do
    attributes = @dsl.attributes
    # running the default block will set inherits attribute
    attributes['prod-api-redis']['inherits'].should == 'base'
  end

  it "roles with blocks should run the default block and then their own block" do
    attributes = @dsl.attributes
    # hard to read test, but after the default block runs, the passed in role block rusn and overrides the default_blocks inherits attribuute
    attributes['prod-api-resque']['inherits'].should == 'prod-api-app'
  end

  it "roles with blocks should override the global attributes" do
    attributes = @dsl.attributes
    attributes['prod-masta-android']['attributes']['application'].should == 'masta'
    attributes['prod-masta-android']['attributes']['deploy_code'].should be_true
    attributes['prod-masta-android']['attributes']['repository'].should == 'git@github.com:arockwell/masta_blasta.git'
  end

  it "base node.json should not include global attributes" do
    @dsl.build
    @dsl.nodejsons['base']['run_list'].should == ["role[base]"]
    @dsl.nodejsons['base']['role'].should == 'base'
    @dsl.nodejsons['base'].keys.should_not include('application')
    @dsl.nodejsons['base'].keys.should_not include('repository')
  end

  it "prod-api-redis node.json should include base plus global attributes" do
    @dsl.build
    @dsl.nodejsons['prod-api-redis']['run_list'].should == ["role[base]"]
    @dsl.nodejsons['prod-api-redis']['deploy_code'].should be_false
  end

  it "prod-api-app node.json should include global attributes plus additional attributes" do
    @dsl.build
    @dsl.nodejsons['prod-api-app']['run_list'].should == ["role[base]", "role[api_app]"]
    @dsl.nodejsons['prod-api-app']['deploy_code'].should be_true
    @dsl.nodejsons['prod-api-app'].keys.should include('scout')
  end

  it "prod-api-resque node.json inherit attributes from prod-api-app" do
    @dsl.build
    @dsl.nodejsons['prod-api-resque']['run_list'].should == @dsl.nodejsons['prod-api-app']['run_list']
    @dsl.nodejsons['prod-api-resque']['deploy_code'].should == @dsl.nodejsons['prod-api-app']['deploy_code']
  end

  it "should respect rules and change framework_env" do
    @dsl.build
    @dsl.nodejsons['stag-masta-android']['application'].should == 'masta'
    @dsl.nodejsons['stag-masta-android']['framework_env'].should == 'staging'
    @dsl.nodejsons['prod-masta-android']['framework_env'].should == 'production'
    @dsl.nodejsons
  end

  it "should write json files to outputs folder" do
    @dsl.build
    @dsl.output(:output => 'filesystem', :output_path => "#{@project_root}/nodejson")
    Dir.glob("#{@project_root}/nodejson/*").size.should > 0
  end

  # complete end to end tests
  it "base.json should contain correct attributes" do
    @dsl.build
    @dsl.output(:output => 'filesystem', :output_path => "#{@project_root}/nodejson")
    base = JSON.load(IO.read("#{@project_root}/nodejson/base.json"))
    base['role'].should == 'base'
    base['run_list'].should == ["role[base]"]
  end

  it "base.json should not contain global attributes" do
    @dsl.build
    @dsl.output(:output => 'filesystem', :output_path => "#{@project_root}/nodejson")
    base = JSON.load(IO.read("#{@project_root}/nodejson/base.json"))
    base['framework_env'].should be_nil
    base['deploy_code'].should be_nil
  end

  it "prod-api-redis.json should contain base and global attributes" do
    @dsl.build
    @dsl.output(:output => 'filesystem', :output_path => "#{@project_root}/nodejson")
    json = JSON.load(IO.read("#{@project_root}/nodejson/prod-api-redis.json"))
    json['role'].should == 'prod-api-redis'
    json['run_list'].should == ["role[base]"]
    json['framework_env'].should == 'production'
    json['deploy_code'].should == false
  end

  it "stag-api-redis.json should contain base and global attributes and apply rules" do
    @dsl.build
    @dsl.output(:output => 'filesystem', :output_path => "#{@project_root}/nodejson")
    json = JSON.load(IO.read("#{@project_root}/nodejson/stag-api-redis.json"))
    json['role'].should == 'stag-api-redis'
    json['run_list'].should == ["role[base]"]
    json['deploy_code'].should == false
    json['framework_env'].should == 'staging' # this is tests the rule
  end

  it "prod-api-app.json should contain base and global attributes" do
    @dsl.build
    @dsl.output(:output => 'filesystem', :output_path => "#{@project_root}/nodejson")
    json = JSON.load(IO.read("#{@project_root}/nodejson/prod-api-app.json"))
    json['role'].should == 'prod-api-app'
    json['run_list'].should == ["role[base]","role[api_app]"]
    json['deploy_code'].should == true
    json['framework_env'].should == 'production'
    json['scout'].should be_a(Hash)
  end

  # only run when S3=1, will need to setup spec/project/config/s3.yml
  it "should upload to s3" do
    @dsl.build
    outputer = @dsl.output(:output => 's3', :s3_config_path => "#{@project_root}/config/s3.yml")

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
    File.exist?("#{@project2_root}/config/s3.yml").should be_false
    File.exist?("#{@project2_root}/config/rna.rb").should be_false
    Rna::Tasks.init(@project2_root, :quiet => true)
    File.exist?("#{@project2_root}/config/s3.yml").should be_true
    File.exist?("#{@project2_root}/config/rna.rb").should be_true
    FileUtils.rm_rf("#{@project2_root}/config")
  end

  it "task build should generate node.json files" do
    Rna::Tasks.build(
      :config_path => "#{@project_root}/config/rna.rb", 
      :output_path => "#{@project_root}/nodejson"
    )
    json = JSON.load(IO.read("#{@project_root}/nodejson/prod-api-app.json"))
    json['role'].should == 'prod-api-app'
    json['run_list'].should == ["role[base]","role[api_app]"]
    json['deploy_code'].should == true
    json['framework_env'].should == 'production'
    json['scout'].should be_a(Hash)
  end
end