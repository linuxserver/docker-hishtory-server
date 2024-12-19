# syntax=docker/dockerfile:1

FROM golang:1.23-alpine AS builder

ARG HISHTORY_RELEASE

RUN \
  apk add --no-cache \
    build-base \
    curl && \
  if [ -z ${HISHTORY_RELEASE+x} ]; then \
    HISHTORY_RELEASE=$(curl -sX GET "https://api.github.com/repos/ddworken/hishtory/releases/latest" \
    | awk '/tag_name/{print $4;exit}' FS='[""]'); \
  fi && \
  curl -s -o \
    /tmp/hishtory.tar.gz -L \
    "https://github.com/ddworken/hishtory/archive/${HISHTORY_RELEASE}.tar.gz" && \
  mkdir -p /build/hishtory && \
  tar xf \
    /tmp/hishtory.tar.gz -C \
    /build/hishtory/ --strip-components=1 && \
  cd /build/hishtory && \
  unset GOPATH; go mod download && \
  unset GOPATH; go build -o /server -ldflags "-X main.ReleaseVersion=v0.`cat VERSION`" backend/server/server.go

FROM ghcr.io/linuxserver/baseimage-alpine:3.21

# set version label
ARG BUILD_DATE
ARG VERSION
ARG HISHTORY_RELEASE
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="thespad"

RUN \
  apk add --no-cache \
    postgresql16-client && \
  printf "Linuxserver.io version: ${VERSION}\nBuild-date: ${BUILD_DATE}" > /build_version

COPY --from=builder /server /app/server

COPY /root /

EXPOSE 8080
