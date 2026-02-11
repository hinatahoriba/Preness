FROM ruby:3.3.10-bookworm
WORKDIR /app
RUN apt-get update -qq && apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    postgresql-client \
  && rm -rf /var/lib/apt/lists/*
COPY Gemfile Gemfile.lock ./
RUN bundle install
COPY . .
