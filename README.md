# Rna gem

[![Build History][2]][1]

[1]: http://travis-ci.org/tongueroo/rna
[2]: https://secure.travis-ci.org/tongueroo/rna.png?branch=master

Rna is a ruby gem that provides simple DSL for generating node.json files required by chef-solo.

## Requirements

<pre>
$ gem install rna
</pre>

## Usage

<pre>
$ mkdir rna_project
$ cd rna_project
$ rna init
</pre>

This will sets starter config/rna.rb and config/s3.yml files.

### Example:

#### config/rna.rb file

```ruby
# This is starter example rna template.
# This is meant be be modified to your needs.
###################################
# Settings
default_inherits 'base'
global(:except => 'base') do
  set 'framework_env', 'production'
end

###################################
pre_rule do
  set 'chef_branch', 'prod' if role =~ /^prod/
  set 'chef_branch', 'master' if role =~ /^stag/
end

###################################
# Roles
# base
role 'base' do
  run_list ['base']
end
# api
role 'prod-api-redis', 'stag-api-redis' do
  run_list ['base','api_redis']
end
role 'prod-api-app', 'stag-api-app' do
  run_list ['base','api_app']
  set 'application', 'api'
  set 'deploy_code', true
  set 'repository', 'git@github.com:br/api.git'
end
role 'prod-api-resque', 'stag-api-resque' do
  inherits 'prod-api-app'
  run_list ['base','api_resque']
  set 'workers', 8
end

###################################
# Post processing rules that run at the end
post_rule do
  set 'framework_env', 'production' if role =~ /^prod/
  set 'framework_env', 'staging' if role =~ /^stag/
end
```

<pre>
$ rna generate
</pre>

Here's the example of the output looks like:

output/base.json:

```json
{
  "role": "base",
  "run_list": [
    "base"
  ]
}
```

output/prod-api-app.json:

```json
{
  "framework_env": "production",
  "role": "prod-api-app",
  "run_list": [
    "base",
    "api_app"
  ],
  "application": "api",
  "deploy_code": true,
  "repository": "git@github.com:br/api.git"
}
```

output/prod-api-redis.json:

```json
{
  "framework_env": "production",
  "role": "prod-api-redis",
  "run_list": [
    "base",
    "api_redis"
  ]
}
```

output/prod-api-resque.json:

```json
{
  "framework_env": "production",
  "role": "prod-api-resque",
  "run_list": [
    "base",
    "api_resque"
  ],
  "application": "api",
  "deploy_code": true,
  "repository": "git@github.com:br/api.git",
  "workers": 8
}
```

output/stag-api-app.json:

```json
{
  "framework_env": "staging",
  "role": "stag-api-app",
  "run_list": [
    "base",
    "api_app"
  ],
  "application": "api",
  "deploy_code": true,
  "repository": "git@github.com:br/api.git"
}
```

output/stag-api-redis.json:

```json
{
  "framework_env": "staging",
  "role": "stag-api-redis",
  "run_list": [
    "base",
    "api_redis"
  ]
}
```

output/stag-api-resque.json:

```json
{
  "framework_env": "staging",
  "role": "stag-api-resque",
  "run_list": [
    "base",
    "api_resque"
  ],
  "application": "api",
  "deploy_code": true,
  "repository": "git@github.com:br/api.git",
  "workers": 8
}
```

#### Uploading to S3

<pre>
$ rna build -o s3 # saves s3 based on config/s3.yml settings
</pre>

The config/s3.yml should look like this:

```yaml
access_key_id: hocuspocus
secret_access_key: opensesame
bucket: my-bucket
folder: chef/rna
```

#### Breaking up config/rna.rb

If you have a lot of roles, the config/rna.rb file can get unwieldy long.  You can break up the rna.rb file and put role defintions in the config/rna directory.  Any file in this directory will be automatically loaded. 

An example is in the spec/project folder:

* config/rna/api.rb
* config/rna/masta.rb