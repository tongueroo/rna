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
default_includes 'base'
# Pre processing rules that run at the beginning
pre_rule do
  if role != 'base'
    node[:application] = nil
    node[:deploy_code] = false
    node[:framework_env] = 'production'
    node[:repository] = nil
  end

  node[:pre_rule] = 1
  node[:chef_branch] = 'prod' if role =~ /^prod/
  node[:chef_branch] = 'master' if role =~ /^stag/
end

settings do
  node[:sendgrid][:relayhost] = "smtp.sendgrid.net"
end

# Roles
role 'base' do
  role_list ['base']
end

# api
role 'prod-api-redis', 'stag-api-redis' do
  run_list ['base','api_redis']
end
role 'prod-api-app', 'stag-api-app' do
  run_list ['base','api_app']
  node[:application] = 'api'
  node[:deploy_code] = true
  node[:repository] = 'git@github.com:br/api.git'
end
role 'prod-api-resque', 'stag-api-resque' do
  includes 'prod-api-app'
  run_list ['base','api_resque']
  node[:workers] = 8
end


# Post processing rules that run at the end
post_rule do
  node[:post_rule] = 2
  node[:framework_env] = 'production' if role =~ /^prod/
  node[:framework_env] = 'staging' if role =~ /^stag/

  list = role.split('-')
  if list.size == 3
    env, repo, role = list
    role_list ['base', "#{repo}_#{role}"]
    node[:application] = repo
  end
end```

<pre>
$ rna generate
</pre>

Here is the example of the output looks like:

output/base.json:

```json
{
  "pre_rule": 1,
  "role": "base",
  "run_list": [
    "role[base]"
  ],
  "post_rule": 2
}
```

output/prod-api-app.json:

```json
{
  "pre_rule": 1,
  "role": "prod-api-app",
  "run_list": [
    "role[base]",
    "role[api_app]"
  ],
  "application": "api",
  "deploy_code": true,
  "repository": "git@github.com:br/api.git",
  "post_rule": 2,
  "framework_env": "production"
}
```

output/prod-api-redis.json:

```json
{
  "pre_rule": 1,
  "role": "prod-api-redis",
  "run_list": [
    "role[base]",
    "role[api_redis]"
  ],
  "post_rule": 2,
  "framework_env": "production",
  "application": "api"
}
```

output/prod-api-resque.json:

```json
{
  "pre_rule": 1,
  "role": "prod-api-resque",
  "run_list": [
    "role[base]",
    "role[api_resque]"
  ],
  "application": "api",
  "deploy_code": true,
  "repository": "git@github.com:br/api.git",
  "workers": 8,
  "post_rule": 2,
  "framework_env": "production"
}
```

output/stag-api-app.json:

```json
{
  "pre_rule": 1,
  "role": "stag-api-app",
  "run_list": [
    "role[base]",
    "role[api_app]"
  ],
  "application": "api",
  "deploy_code": true,
  "repository": "git@github.com:br/api.git",
  "post_rule": 2,
  "framework_env": "staging"
}
```

output/stag-api-redis.json:

```json
{
  "pre_rule": 1,
  "role": "stag-api-redis",
  "run_list": [
    "role[base]",
    "role[api_redis]"
  ],
  "post_rule": 2,
  "framework_env": "staging",
  "application": "api"
}
```

output/stag-api-resque.json:

```json
{
  "pre_rule": 1,
  "role": "stag-api-resque",
  "run_list": [
    "role[base]",
    "role[api_resque]"
  ],
  "application": "api",
  "deploy_code": true,
  "repository": "git@github.com:br/api.git",
  "workers": 8,
  "post_rule": 2,
  "framework_env": "staging"
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

#### Shared Settings

You might want a shared settings hash that you can use in only some of your roles.  

```ruby
settings do
  node[:foo] = 1
end
```

You can use this any where in your roles.

```ruby
role 'role1' do
  node[:foo] = settings[:foo]
end

role 'role2' do
  node[:foo] = settings[:foo]
end

role 'role3' do
  # dont set foo here
end
```