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

<pre>
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
</pre>

<pre>
$ rna build
</pre>

If you're using the starter config/rna.rb, this should build:

* nodejson/base.json
* nodejson/prod-api-app.json
* nodejson/prod-api-redis.json
* nodejson/prod-api-resque.json
* nodejson/stag-api-app.json
* nodejson/stag-api-redis.json
* nodejson/stag-api-resque.json

<pre>
$ rna build -o s3 # saves s3 based on config/s3.yml settings
</pre>

The config/s3.yml should look like this:

access_key_id: hocuspocus
secret_access_key: opensesame
bucket: my-bucket
folder: chef/nodejson
