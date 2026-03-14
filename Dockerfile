FROM ruby:3.3.10-slim-bookworm

RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
      build-essential \
      libpq-dev \
      postgresql-client \
      libyaml-dev \
      curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /rails

# Gemをインストール（development/testを除く）
COPY Gemfile Gemfile.lock ./
RUN bundle config set --local without 'development test' && \
    bundle install && \
    bundle exec bootsnap precompile --gemfile

# アプリケーションコードをコピー
COPY . .

# bootsnapキャッシュをプリコンパイル
RUN bundle exec bootsnap precompile app/ lib/

# アセットをプリコンパイル
RUN SECRET_KEY_BASE_DUMMY=1 RESEND_API_KEY=dummy RAILS_ENV=production ./bin/rails assets:precompile

EXPOSE 3000

ENTRYPOINT ["./bin/docker-entrypoint"]
CMD ["./bin/thrust", "./bin/rails", "server", "-b", "0.0.0.0"]
