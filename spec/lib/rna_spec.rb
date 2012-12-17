require 'rna'
require 'rspec'
require 'pp'

describe Rna do
  before(:each) do
    @project_root = File.expand_path("../../project", __FILE__)
    @project2_root = File.expand_path("../../project2", __FILE__)
    @dsl = Rna::DSL.new(
      :config_path => "#{@project_root}/config/rna.rb",
      :output_path => "#{@project_root}/output"
    )
  end

  after(:each) do
    FileUtils.rm_rf("#{@project_root}/output")
  end

  # it "should build attributes" do
  #   @dsl.evaluate
  #   @dsl.build
  #   pp @dsl.data
  #   @dsl.process
  #   pp @dsl.jsons
  # end

  it "should write json files to outputs folder" do
    @dsl.run
    Dir.glob("#{@project_root}/output/*").size.should > 0
  end

  # complete end to end tests
  it "base.json should contain correct attributes" do
    @dsl.run
    base = JSON.load(IO.read("#{@project_root}/output/base.json"))
    base['role'].should == 'base'
    base['run_list'].should == ["role[base]"]
  end

  it "base.json should not contain global attributes" do
    @dsl.run
    base = JSON.load(IO.read("#{@project_root}/output/base.json"))
    base['framework_env'].should be_nil
    base['deploy_code'].should be_nil
  end

  it "prod-api-redis.json should contain base and global attributes" do
    @dsl.run
    json = JSON.load(IO.read("#{@project_root}/output/prod-api-redis.json"))
    json['role'].should == 'prod-api-redis'
    json['run_list'].should == ["role[base]", "role[api_redis]"]
    json['framework_env'].should == 'production'
    json['deploy_code'].should == false
  end

  it "stag-api-redis.json should contain base and global attributes and apply rules" do
    @dsl.run
    json = JSON.load(IO.read("#{@project_root}/output/stag-api-redis.json"))
    json['role'].should == 'stag-api-redis'
    json['run_list'].should == ["role[base]", "role[api_redis]"]
    json['deploy_code'].should == false
    json['framework_env'].should == 'staging' # this is tests the rule
  end

  it "prod-api-app.json should contain base and global attributes" do
    @dsl.run
    json = JSON.load(IO.read("#{@project_root}/output/prod-api-app.json"))
    json['role'].should == 'prod-api-app'
    json['run_list'].should == ["role[base]","role[api_app]"]
    json['deploy_code'].should == true
    json['framework_env'].should == 'production'
    json['scout'].should be_a(Hash)
  end

  it "prod-api-app.json should contain pre and post rules" do
    @dsl.run
    json = JSON.load(IO.read("#{@project_root}/output/prod-api-app.json"))
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
    File.exist?("#{@project_root}/output/masta-app.json").should be_false
    File.exist?("#{@project_root}/output/prod-masta-android.json").should be_true
    json = JSON.load(IO.read("#{@project_root}/output/prod-masta-android.json"))
    json['masta_app'].should == 123
  end

  ###################

  # only run when S3=1, will need to setup spec/project/config/s3.yml
  it "should upload to s3" do
    @dsl = Rna::DSL.new(
      :output => 's3', 
      :s3_config_path => "#{@project_root}/config/s3.yml",
      :config_path => "#{@project_root}/config/rna.rb"
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
    File.exist?("#{@project2_root}/config/s3.yml").should be_false
    File.exist?("#{@project2_root}/config/rna.rb").should be_false
    Rna::Task.init(@project2_root, :quiet => true)
    File.exist?("#{@project2_root}/config/s3.yml").should be_true
    File.exist?("#{@project2_root}/config/rna.rb").should be_true
    FileUtils.rm_rf("#{@project2_root}/config")
  end

  it "task build should generate node.json files" do
    Rna::Task.generate(
      :config_path => "#{@project_root}/config/rna.rb", 
      :output_path => "#{@project_root}/output"
    )
    json = JSON.load(IO.read("#{@project_root}/output/prod-api-app.json"))
    json['role'].should == 'prod-api-app'
    json['run_list'].should == ["role[base]","role[api_app]"]
    json['deploy_code'].should == true
    json['framework_env'].should == 'production'
    json['scout'].should be_a(Hash)
  end
end