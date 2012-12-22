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