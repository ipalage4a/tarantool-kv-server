#!/usr/bin/env tarantool
local json = require('json')

box.cfg{listen = 3301}
box.schema.user.passwd('pass')

kvs = box.schema.create_space('kvs', { if_not_exists = true })
kvs:format({{ name = 'key', type = 'string'}, { name = 'value', type = 'string'}})
kvs:create_index('pk', { parts = { { field = 'key', type = 'string'}}, if_not_exists = true})


function handler(req)
  return req:render{ json = { ['Your-IP-Is'] = req:peer().host } }
end

function debug_handler(req)
  return req:render{ json = { ['debug'] = 'debug' } }
end
  
function get_handler(req)
  local key = req:stash('key')
  local kv = box.space.kvs:get(key)
  if kv == nil then 
    return {status = 404 }
  end

  return { status = 200, body = json.encode({
    key=kv.key,
    value=kv.value
  })}
end

function post_handler(req)
  local key = req:post_param('key')
  local value = req:post_param('value')
  box.space.kvs:insert({key, value})
  return { status=201 }
end

function delete_handler(req)
  local key = req:stash('key')
  local deleted_kv = box.space.kvs:delete(key)
  if deleted_kv == nil then
    return {status = 404, json = nil }
  end
  return { status = 200 }
end
  


local server = require('http.server').new(nil, 80)
local router = require('http.router').new({charset = "utf8"})
server:set_router(router)

router:route({ path = '/' }, handler)
router:route({ method='GET', path = '/debug' }, debug_handler)

router:route({ method='GET', path = '/kv/:key' }, get_handler)
router:route({ method='POST', path = '/kv' }, post_handler)
router:route({ method='PUT', path = '/kv/:key' }, handler)
router:route({ method='DELETE', path = '/kv/:key' }, delete_handler) 

server:start()

