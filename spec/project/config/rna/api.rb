# api
role 'prod-api-redis', 'stag-api-redis'
role 'prod-api-resque', 'stag-api-resque' do
  includes 'prod-api-app'
  node[:workers] = 8
end
role 'prod-api-app', 'stag-api-app' do
  role_list ['base','api_app']
  node[:application] = 'api'
  node[:deploy_code] = true
  node[:repository] = 'git@github.com:owner/repo.git/api.git'
  node[:database][:adapter] = "mysql"
  node[:database][:host] = "127.0.0.1"
  node[:database][:user] = "user"
  node[:database][:pass] = "pass"
  node[:scout][:key] = 'abc'
  node[:scout][:gems] = {'redis' => nil}
  node[:relayhost] = settings[:sendgrid][:relayhost]
end