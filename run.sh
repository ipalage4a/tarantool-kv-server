#!/bin/bash
docker run -it --rm \
  -v $PWD/init.lua:/app/init.lua \
  -p 80:80 \
  trntl

