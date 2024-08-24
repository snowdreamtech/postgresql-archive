# PostgreSQL

[![PostgreSQL](http://dockeri.co/image/snowdreamtech/postgresql)](https://hub.docker.com/r/snowdreamtech/postgresql)

Docker Image packaging for PostgreSQL. (amd64, arm32v6, arm32v7, arm64v8, i386, ppc64le,riscv64, s390x)

# Usage

To help you get started creating a container from this image you can either use docker-compose or the docker cli.

## Docker Cli

### Simple

```bash
docker run -d \
  --name=postgresql \
  -e TZ=Asia/Shanghai \
  -e POSTGRES_DISALLOW_USER_LOGIN_REMOTELY=0 \
  -p 5432:5432 \
  --restart unless-stopped \
  snowdreamtech/postgresql:latest
```

### Advance

```bash
docker run -d \
  --name=postgresql \
  -e TZ=Asia/Shanghai \
  -e POSTGRES_ROOT_PASSWORD='root password' \
  -e POSTGRES_PORT=5432 \
  -e POSTGRES_USER='user name' \
  -e POSTGRES_PASSWORD='user password' \
  -e POSTGRES_DB='db name' \
  -e POSTGRES_DISALLOW_USER_LOGIN_REMOTELY=0 \
  -e POSTGRES_MAX_CONNECTIONS=500 \
  -p 5432:5432 \
  -v /path/to/data:/var/lib/postgresql/14(pg-version)/data \
  --restart unless-stopped \
  snowdreamtech/postgresql:latest
```

## Docker Compose

### Simple

```bash
version: "3"

services:
  postgresql:
    image: snowdreamtech/postgresql:latest
    container_name: postgresql
    environment:
      - TZ=Asia/Shanghai
      - POSTGRES_DISALLOW_USER_LOGIN_REMOTELY=0
    ports:
      - 5432:5432  
    restart: unless-stopped
```

### Advance

```bash
version: "3"

services:
  postgresql:
    image: snowdreamtech/postgresql:latest
    container_name: postgresql
    environment:
      - TZ=Asia/Shanghai
      - POSTGRES_ROOT_PASSWORD='root password'
      - POSTGRES_PORT=5432
      - POSTGRES_USER='user name'
      - POSTGRES_PASSWORD='user password'
      - POSTGRES_DB='db name'
      - POSTGRES_DISALLOW_USER_LOGIN_REMOTELY=0
      - POSTGRES_MAX_CONNECTIONS=500
    volumes:
      - /path/to/data:/var/lib/postgresql/14(pg-version)/data
    ports:
      - 5432:5432   
    restart: unless-stopped
```

# Development

```bash
docker buildx create --use --name build --node build --driver-opt network=host
docker buildx build -t snowdreamtech/postgresql --platform=linux/386,linux/amd64,linux/arm/v6,linux/arm/v7,linux/arm64,linux/ppc64le,linux/riscv64,linux/s390x . --push
```

## Reference

1. [使用 buildx 构建多平台 Docker 镜像](https://icloudnative.io/posts/multiarch-docker-with-buildx/)
1. [使用 buildx 构建多平台 Docker 镜像](https://blog.bwcxtech.com/posts/43dd6afb/)
1. [如何使用 docker buildx 构建跨平台 Go 镜像](https://waynerv.com/posts/building-multi-architecture-images-with-docker-buildx/#buildx-%E7%9A%84%E8%B7%A8%E5%B9%B3%E5%8F%B0%E6%9E%84%E5%BB%BA%E7%AD%96%E7%95%A5)
1. [Building Multi-Arch Images for Arm and x86 with Docker Desktop](https://www.docker.com/blog/multi-arch-images/)
1. [How to Rapidly Build Multi-Architecture Images with Buildx](https://www.docker.com/blog/how-to-rapidly-build-multi-architecture-images-with-buildx/)
1. [Faster Multi-Platform Builds: Dockerfile Cross-Compilation Guide](https://www.docker.com/blog/faster-multi-platform-builds-dockerfile-cross-compilation-guide/)
1. [docker/buildx](https://github.com/docker/buildx)

## Contact (备注：postgresql)

* Email: sn0wdr1am@qq.com
* QQ: 3217680847
* QQ群: 949022145
* WeChat/微信群: sn0wdr1am

## License

MIT
