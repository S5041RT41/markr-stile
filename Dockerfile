FROM ruby:3.3.5

ENV BUNDLER_VERSION=2.5.18

# RUN gem install bundler -v 2.0.2

WORKDIR /app

COPY Gemfile Gemfile.lock ./

# RUN bundle config --local path .bundle

# RUN bundle config build.nokogiri --use-system-libraries

RUN bundle install

COPY . ./

# Set the entrypoint command
CMD ["bundle", "exec", "rackup"]

# ENTRYPOINT ["./entrypoints/docker-markr-app-entrypoint.sh"]
