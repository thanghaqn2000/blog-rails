FROM ruby:3.0.0

RUN curl -sL https://deb.nodesource.com/setup_18.x | bash -

RUN apt-get update -qq && apt-get install -y \
  build-essential \
  libpq-dev \
  nodejs

WORKDIR /myapp

COPY Gemfile Gemfile.lock ./

RUN gem install bundler:2.3.21 && bundle install

COPY . .

COPY docker/entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]

CMD ["bash", "-c", "rm -f tmp/pids/server.pid && rails server -b 0.0.0.0"]
