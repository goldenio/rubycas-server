# base stage
ARG registry_uri=""

FROM ${registry_uri}ruby:3.0.0-alpine3.13 AS ruby_base

ARG tz="Asia/Taipei"

ENV TZ=${tz} \
    LC_ALL=C.UTF-8 \
    LANG=C.UTF-8 \
    LANGUAGE=C.UTF-8

RUN apk add --no-cache tzdata=~2021 \
    && ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime \
    && echo ${TZ} > /etc/timezone \
    && date \
    && apk add --no-cache \
        openssl=~1.1.1 \
        git=~2.30 \
    && rm -f /var/cache/apk/*

# ruby_runner stage
FROM ruby_base AS ruby_runner
LABEL maintainer="tsechingho@goldenio.com"

ENV BUNDLER_VERSION=2.2.20 \
    RELEASE_PATH=/docker_capistrano

WORKDIR ${RELEASE_PATH}

COPY Gemfile Gemfile.lock ./
RUN gem install bundler -v ${BUNDLER_VERSION} \
    && bundle config --global force_ruby_platform true \
    && bundle install \
    && find "${GEM_HOME}/gems/" -name "*.c" -delete \
    && find "${GEM_HOME}/gems/" -name "*.o" -delete \
    && rm -rf "${GEM_HOME}/cache"/*.gem

COPY . ${RELEASE_PATH}

CMD ["sh"]
