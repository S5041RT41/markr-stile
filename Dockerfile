FROM ruby:3.3.5

ENV BUNDLER_VERSION=2.5.18

WORKDIR /app

COPY Gemfile Gemfile.lock ./

RUN bundle install

COPY . ./

EXPOSE 9292

CMD ["bundle", "exec", "rackup", "-p", "9292"]
