Rna gem
===========

Rna is a ruby gem that provides simple DSL for generating node.json files required by chef-solo.

Requirements
------------

<pre>
$ gem install rna
</pre>

Usage
------------

<pre>
$ mkdir rna_project
$ cd rna_project
$ rna init
</pre>

This will sets starter config/rna.rb and config/s3.yml files.

Example rna.rb file
------------

```ruby
# This is starter example rna template.
# This is meant be be modified to your needs.
###################################
# Settings
default_inherits 'base'
global_attributes(:except => ['base']) do
  set 'framework_env', 'production'
end

###################################
# Post processing rules that run at the end
rule do
  set 'framework_env', 'production' if name =~ /^prod/
  set 'framework_env', 'staging' if name =~ /^stag/
end

###################################
# Roles
# base
role 'base' do
  run_list ['base']
end
# api
role 'prod-api-redis', 'stag-api-redis'
role 'prod-api-app', 'stag-api-app' do
  run_list ['base','api_app']
  set 'application', 'api'
  set 'deploy_code', true
  set 'repository', 'git@github.com:br/api.git'
end
role 'prod-api-resque', 'stag-api-resque' do
  inherits 'prod-api-app'
  set 'workers', 8
end
```

<pre>
$ rna generate
</pre>

If you're using the starter config/rna.rb, this should output:

* output/base.json
* output/prod-api-redis.json
* output/stag-api-redis.json
* output/prod-api-resque.json

<pre>
$ rna --output s3 config/rna.rb # will save to s3 based on s3 settings
</pre>

# Settings
s3_credentials 'config/s3.yml'
s3_bucket 'br-ops'
s3_output_path 'chef/nodejson'

The config/s3.yml should look like this:

credentials:
  access_key_id: abc
  secret_access_key: abc