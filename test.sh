#!/bin/bash
docker run -it \
  -v $PWD:/app \
  trntl luatest -v
