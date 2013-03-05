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

settings[:sendgrid][:relayhost] = "smtp.sendgrid.net"

# Roles
role 'base' do
  role_list ['base']
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