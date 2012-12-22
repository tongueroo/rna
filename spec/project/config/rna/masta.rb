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
