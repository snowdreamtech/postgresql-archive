FROM snowdreamtech/alpine:3.20.2

LABEL maintainer="snowdream <sn0wdr1am@qq.com>"

# keep the docker container running
ENV KEEPALIVE=1

ENV POSTGRES_VERSION=15.10-r0 \
    POSTGRES_PORT=5432 \
    POSTGRES_MAX_CONNECTIONS=100 \
    POSTGRES_ROOT_PASSWORD="" \
    POSTGRES_USER='' \
    POSTGRES_PASSWORD='' \
    POSTGRES_DB='' \
    POSTGRES_HOST_AUTH_METHOD='scram-sha-256'  \
    POSTGRES_DISALLOW_USER_LOGIN_REMOTELY=1

RUN apk add --no-cache postgresql15=${POSTGRES_VERSION}  \
    postgresql15-client=${POSTGRES_VERSION} \
    postgresql15-contrib=${POSTGRES_VERSION} 

COPY --chown=postgres:postgres docker-entrypoint.sh /usr/local/bin/

ENTRYPOINT ["docker-entrypoint.sh"]