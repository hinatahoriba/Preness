FROM ruby:3.3.10-bookworm
WORKDIR /app
RUN apt-get update -qq && apt-get install -y \
    build-essential \
    libpq-dev
COPY Gemfile Gemfile.lock ./
RUN bundle install
COPY . .