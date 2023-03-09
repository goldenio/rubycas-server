# base stage
# FROM ruby:3.0.0-alpine3.13 AS ruby_base
# FROM ruby:2.7.2-alpine3.13 AS ruby_base
# FROM ruby:2.6.6-alpine3.13 AS ruby_base
ARG registry_uri=""

FROM ${registry_uri}ruby:2.5.8-alpine3.13 AS ruby_base

ARG tz="Asia/Taipei"

ENV TZ=${tz} \
    LC_ALL=C.UTF-8 \
    LANG=C.UTF-8 \
    LANGUAGE=C.UTF-8

RUN apk add --no-cache tzdata=~2022 \
    && ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime \
    && echo ${TZ} > /etc/timezone \
    && date \
    && apk add --no-cache \
        openssl=~1.1.1 \
        libxml2=~2.9 \
        libxslt=~1.1 \
    && rm -f /var/cache/apk/*


# package stage
FROM ruby_base AS ruby_packer

RUN apk add --no-cache --virtual .gem-builddeps \
        build-base=~0.5 \
        # sqlite-dev=~3.34 \
        mysql-dev=~10.5 \
        # nokogiri requires libxml2 libxslt
        libxml2-dev=~2.9 \
        libxslt-dev=~1.1 \
    && apk add --no-cache --virtual .ruby-app-devdeps \
        git=~2 \
        # sqlite=~3.34 \
        mysql-client=~10.5 \
    && rm -f /var/cache/apk/*

ARG extra_packages=""
# hadolint ignore= DL3018
RUN apk add --no-cache ${extra_packages} && rm -f /var/cache/apk/*


# build stage
FROM ruby_packer AS ruby_builder

ARG user="deployer"
ARG bundler_version="1.17.3"
ARG bundle_without="development:test"

ENV BUNDLER_VERSION=${bundler_version} \
    BUNDLE_JOBS=4 \
    BUNDLE_WITHOUT=${bundle_without} \
    EDITOR=vi \
    RELEASE_PATH=/srv/cas

WORKDIR ${RELEASE_PATH}

RUN if ! id "${user}" >/dev/null 2>&1; then \
      adduser -D ${user}; \
    fi \
    && chown ${user}:${user} ${RELEASE_PATH}

USER ${user}

# COPY --chown=${user}:${user} docker/.gitconfig docker/.git-credentials /home/${user}/
# RUN if [ -f ~/.git-credentials ]; then \
#       git config --global credential.helper 'store --file ~/.git-credentials'; \
#     else \
#       git config --global credential.helper 'cache --timeout 900'; \
#     fi

COPY --chown=${user}:${user} Gemfile Gemfile.lock ./
RUN gem install bundler -v ${BUNDLER_VERSION} \
    && bundle config --global force_ruby_platform true \
    && bundle config --global build.nokogiri --use-system-libraries \
    # && echo "gem 'sqlite3', '~> 1.3.6'" >> Gemfile \
    && bundle install \
    && find "${GEM_HOME}/gems/" -name "*.c" -delete \
    && find "${GEM_HOME}/gems/" -name "*.o" -delete \
    && rm -rf "${GEM_HOME}/cache"/*.gem

COPY --chown=${user}:${user} . ${RELEASE_PATH}
COPY --chown=${user}:${user} docker/config.yml ${RELEASE_PATH}/config/config.yml

ARG files_to_remove=""
RUN rm -rf ${files_to_remove}


# alone stage
FROM ruby_packer AS ruby_alone
LABEL maintainer="tsechingho@goldenio.com"

ENV RELEASE_PATH=/srv/cas

WORKDIR ${RELEASE_PATH}

EXPOSE 3000

CMD ["bundle", "exec", "bin/rubycas-server", "-c", "config/config.yml"]


# develop stage
FROM ruby_builder AS ruby_develop
LABEL maintainer="tsechingho@goldenio.com"

USER root

RUN wget -q -O /usr/local/bin/wait-for https://raw.githubusercontent.com/eficode/wait-for/master/wait-for \
    && chmod +x /usr/local/bin/wait-for

COPY docker/docker-entrypoint.sh /usr/local/bin/docker-entrypoint
RUN chmod +x /usr/local/bin/docker-entrypoint && rm -rf docker

USER ${user}

ENTRYPOINT ["docker-entrypoint"]

EXPOSE 3000

CMD ["bundle", "exec", "bin/rubycas-server", "-c", "config/config.yml"]


# service stage
FROM ruby_base AS ruby_service
LABEL maintainer="tsechingho@goldenio.com"

ARG extra_packages="mysql-dev=~10.5 mysql-client=~10.5"
# hadolint ignore= DL3018
RUN apk add --no-cache ${extra_packages} && rm -f /var/cache/apk/*

ENV RELEASE_PATH=/srv/cas

WORKDIR ${RELEASE_PATH}

ARG user="deployer"
RUN if ! id "${user}" >/dev/null 2>&1; then \
      adduser -D ${user}; \
    fi \
    && chown ${user}:${user} ${RELEASE_PATH}

COPY --from=ruby_builder --chown=${user}:${user} ${GEM_HOME} ${GEM_HOME}
COPY --from=ruby_builder --chown=${user}:${user} ${RELEASE_PATH} ${RELEASE_PATH}

RUN wget -q -O /usr/local/bin/wait-for https://raw.githubusercontent.com/eficode/wait-for/master/wait-for \
    && chmod +x /usr/local/bin/wait-for

COPY docker/docker-entrypoint.sh /usr/local/bin/docker-entrypoint
RUN chmod +x /usr/local/bin/docker-entrypoint && rm -rf docker

USER ${user}

ENTRYPOINT ["docker-entrypoint"]

EXPOSE 3000

CMD ["bundle", "exec", "bin/rubycas-server", "-c", "config/config.yml"]
