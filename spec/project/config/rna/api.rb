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
  node[:repository] = 'git@github.com:br/api.git'
  node[:scout][:key] = 'abc'
  node[:scout][:gems] = {'redis' => nil}
  node[:relayhost] = settings[:sendgrid][:relayhost]

  node[:database][:user] = 'user'
  node[:database][:pass] = 'pass'
  node[:database][:host] = 'host'
end