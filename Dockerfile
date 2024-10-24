FROM ruby:3.3.5-alpine

ENV BUNDLER_VERSION=2.5.18

# Create a non-root user and switch to it
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app

# Install dependencies for bundler and other gems
RUN apk add --no-cache build-base

# Copy the Gemfile and Gemfile.lock first to leverage Docker cache
COPY Gemfile Gemfile.lock ./

# Install the bundler and gems
RUN gem install bundler -v $BUNDLER_VERSION && \
    bundle install && \
    apk del build-base  # Remove build dependencies to reduce image size

# Copy the rest of the application code
COPY . ./

# Set the ownership of the application files
RUN chown -R appuser:appgroup /app

# Switch to the non-root user
USER appuser

EXPOSE 9292

CMD ["bundle", "exec", "rackup", "-p", "9292", "-o", "0.0.0.0"]
