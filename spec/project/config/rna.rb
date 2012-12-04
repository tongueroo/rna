###################################
# Settings
default_inherits 'base'
global_attributes(:except => 'base') do
  set 'application', nil
  set 'deploy_code', false
  set 'framework_env', 'production'
  set 'repository', nil
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
role 'prod-api-resque', 'stag-api-resque' do
  inherits 'prod-api-app'
  set 'workers', 8
end
role 'prod-api-app', 'stag-api-app' do
  run_list ['base','api_app']
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
role 'prod-masta-redis', 'stag-masta-redis'
role 'prod-masta-android', 'stag-masta-android' do
  set 'application', 'masta'
  set 'deploy_code', true
  set 'repository', 'git@github.com:arockwell/masta_blasta.git'
end