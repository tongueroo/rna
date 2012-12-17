###################################
# Settings
default_inherits 'base'
global(:except => 'base') do
  set 'application', nil
  set 'deploy_code', false
  set 'framework_env', 'production'
  set 'repository', nil
end

###################################
pre_rule do
  set 'pre_rule', 1
  set 'chef_branch', 'prod' if role =~ /^prod/
  set 'chef_branch', 'master' if role =~ /^stag/
end

###################################
# Roles
# base
role 'base' do
  role_list ['base']
end
# api
role 'prod-api-redis', 'stag-api-redis'
role 'prod-api-resque', 'stag-api-resque' do
  inherits 'prod-api-app'
  set 'workers', 8
end
role 'prod-api-app', 'stag-api-app' do
  role_list ['base','api_app']
  set 'application', 'api'
  set 'deploy_code', true
  set 'repository', 'git@github.com:br/api.git'
  set 'scout', {
        'key' => 'abc',
        'gems' => {
          'redis' => nil
        }
      }
end
# masta
role 'masta-app' do
  output false
  set 'masta_app', 123
end
role 'prod-masta-redis', 'stag-masta-redis'
role 'prod-masta-android', 'stag-masta-android' do
  inherits 'masta-app'
  set 'application', 'masta'
  set 'deploy_code', true
  set 'repository', 'git@github.com:arockwell/masta_blasta.git'
end

###################################
# Post processing rules that run at the end
post_rule do
  set 'post_rule', 2
  set 'framework_env', 'production' if role =~ /^prod/
  set 'framework_env', 'staging' if role =~ /^stag/

  list = role.split('-')
  if list.size == 3
    env, repo, role = list
    role_list ['base', "#{repo}_#{role}"]
    set 'application', repo
  end
end