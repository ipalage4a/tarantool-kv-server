#!/bin/bash
docker run -it --rm \
  -v $PWD:/app \
  -p 80:80 \
  trntl bash

