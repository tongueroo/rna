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
  set 'relayhost', settings['sendgrid']['relayhost']
end
