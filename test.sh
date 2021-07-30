#!/bin/bash
docker run -it --rm \
  -v $PWD:/app/ \
  trntl luatest
