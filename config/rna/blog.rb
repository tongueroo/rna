# blog
role 'blog-app' do
  output false
  node[:blog_app] = 123
end
role 'prod-blog-redis', 'stag-blog-redis'
role 'prod-blog-app', 'stag-blog-app' do
  includes 'blog-app'
  node[:application] = 'blog'
  node[:deploy_code] = true
  node[:repository] = 'git@github.com:arockwell/blog_blasta.git'
  node[:relayhost] = settings[:sendgrid][:relayhost]
end