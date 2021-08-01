#!/usr/bin/env tarantool
local server = require('server')

box.cfg{
  -- by convention, Tarantool in a container uses this directory to persist data
  work_dir = '/var/lib/tarantool',
}

server.new('kvs', 80):start()
