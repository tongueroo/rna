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