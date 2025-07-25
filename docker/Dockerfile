FROM ruby:3.3.0

RUN curl -sL https://deb.nodesource.com/setup_18.x | bash -

RUN apt-get update -qq && apt-get install -y \
  build-essential \
  libpq-dev \
  nodejs

WORKDIR /myapp

COPY Gemfile Gemfile.lock ./

RUN gem install bundler:2.3.21 && bundle install

COPY . .

ARG RAILS_ENV
ENV RAILS_ENV=$RAILS_ENV

COPY docker/entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]
