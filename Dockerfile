FROM alpine-base:latest

#
# Nginx
#
ADD nginx/app.conf /etc/nginx/sites-enable/

#
# App
#
WORKDIR /app

ADD entrypoint.sh .

RUN chmod +x entrypoint.sh && \
    bundle exec rails new . -O --skip-bundle --skip-turbolinks --skip-test --skip-gemfile && \
    bundle exec rails g controller test index

ADD rails .

ENTRYPOINT /app/entrypoint.sh
