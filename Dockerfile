FROM snowdreamtech/alpine:3.20.2

LABEL maintainer="snowdream <sn0wdr1am@qq.com>"

# keep the docker container running
ENV KEEPALIVE=1

ENV POSTGRESQL_VERSION=14.12-r0

RUN apk add --no-cache postgresql14=${POSTGRESQL_VERSION}  \
    postgresql14-client=${POSTGRESQL_VERSION} \
    postgresql14-contrib=${POSTGRESQL_VERSION} 
    
COPY --chown=postgres:postgres docker-entrypoint.sh /usr/local/bin/

ENTRYPOINT ["docker-entrypoint.sh"]