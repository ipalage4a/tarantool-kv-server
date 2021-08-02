#!/bin/bash
docker-compose run --rm -w /opt/tarantool tarantool luatest -v -c;
