FROM ubuntu:latest

ENV PATH=$PWD/.rocks/bin/:$PATH
ENV DEBIAN_FRONTEND='noninteractive'
RUN apt-get update -q; apt-get install curl vim git unzip cmake -y

RUN curl -L https://tarantool.io/installer.sh | bash -s -- --repo-only
RUN apt-get install -y tarantool tarantool-dev

RUN tarantoolctl rocks install http
RUN tarantoolctl rocks install luatest

WORKDIR /app

CMD tarantool app/init.lua

