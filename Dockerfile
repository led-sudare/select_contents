FROM ruby:2.5-alpine

RUN apk add --no-cache \
    ca-certificates

RUN gem install bundler -v 1.16.5

EXPOSE 8080
WORKDIR /work/
COPY . .
RUN bundle install

ENTRYPOINT ["bundle", "exec", "rackup"]
