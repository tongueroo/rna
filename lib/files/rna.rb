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
  node[:repository] = 'git@github.com:owner/repo.git/api.git'
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
end