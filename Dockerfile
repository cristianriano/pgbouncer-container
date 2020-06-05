FROM alpine:3.9

FROM alpine:3.9 AS build_stage

LABEL maintainer "robert@aztek.io"

# hadolint ignore=DL3018
RUN apk --update --no-cache add \
        autoconf \
        autoconf-doc \
        automake \
        c-ares \
        c-ares-dev \
        curl \
        gcc \
        libc-dev \
        libevent \
        libevent-dev \
        libtool \
        make \
        libressl-dev \
        file \
        pkgconf

ARG PGBOUNCER_VERSION

RUN curl -Lso  "/tmp/pgbouncer.tar.gz" "https://pgbouncer.github.io/downloads/files/${PGBOUNCER_VERSION}/pgbouncer-${PGBOUNCER_VERSION}.tar.gz" && \
        file "/tmp/pgbouncer.tar.gz"

WORKDIR /tmp

RUN mkdir /tmp/pgbouncer && \
        tar -zxvf pgbouncer.tar.gz -C /tmp/pgbouncer --strip-components 1

WORKDIR /tmp/pgbouncer

RUN ./configure --prefix=/usr && \
        make

FROM alpine:3.9

# hadolint ignore=DL3018
RUN apk --update --no-cache add \
        libevent \
        libressl \
        ca-certificates \
        c-ares

WORKDIR /etc/pgbouncer
WORKDIR /var/log/pgbouncer

RUN chown -R 1000:1000 \
        /etc/pgbouncer \
        /var/log/pgbouncer

USER 1000

COPY --from=build_stage --chown=1000 ["/tmp/pgbouncer", "/opt/pgbouncer"]
COPY --chown=1000 ["entrypoint.sh", "/opt/pgbouncer"]

WORKDIR /opt/pgbouncer
ENTRYPOINT ["/opt/pgbouncer/entrypoint.sh"]

