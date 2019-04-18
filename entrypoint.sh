#/bin/sh

nginx -c /etc/nginx/nginx.conf
bundle exec unicorn -c config/unicorn.rb

# tail -f /dev/null
