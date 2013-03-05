# masta
role 'masta-app' do
  output false
  node[:masta_app] = 123
end
role 'prod-masta-redis', 'stag-masta-redis'
role 'prod-masta-android', 'stag-masta-android' do
  includes 'masta-app'
  node[:application] = 'masta'
  node[:deploy_code] = true
  node[:repository] = 'git@github.com:arockwell/masta_blasta.git'
  node[:relayhost] = settings[:sendgrid][:relayhost]
end