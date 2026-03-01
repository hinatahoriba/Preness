FROM ruby:3.3.10-bookworm
WORKDIR /app
RUN apt-get update -qq && apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    postgresql-client \
    nodejs \
  && rm -rf /var/lib/apt/lists/*
COPY Gemfile Gemfile.lock ./
RUN bundle install
COPY . .
ENV RAILS_ENV=production
RUN SECRET_KEY_BASE=placeholder DATABASE_URL="postgresql://dummy:dummy@localhost/dummy" bundle exec rails assets:precompile
CMD ["bash", "-c", "rm -f tmp/pids/server.pid && bin/rails db:setup && bin/rails server -b 0.0.0.0 -p ${PORT:-8080}"]
