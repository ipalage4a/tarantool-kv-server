FROM ubuntu:latest

ENV PATH=$PWD/.rocks/bin/:$PATH
ENV DEBIAN_FRONTEND='noninteractive'
RUN apt-get update -q; apt-get install curl git unzip cmake -y

RUN curl -L https://tarantool.io/installer.sh | bash -s -- --repo-only
RUN apt-get install -y tarantool tarantool-dev

RUN tarantoolctl rocks install http
RUN tarantoolctl rocks install luatest

COPY app/*.lua /opt/tarantool/app/
COPY test/*.lua /opt/tarantool/test/

WORKDIR /opt/tarantool/app
CMD tarantool init.lua
