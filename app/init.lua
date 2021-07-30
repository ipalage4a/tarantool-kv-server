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

function create_handler(req)
  local key = req:post_param('key')
  local value = req:post_param('value')

  if key == nil then 
    return { status = 400 }
  end

  local exist = box.space.kvs:get(key)

  if exist ~= nil then 
    return { status = 409 }
  end

  local ok, ret = pcall(box.space.kvs.insert, box.space.kvs,{key, value})

  if not ok then
    return { status = 500, body=ret }
  end

  return { status = 200, body = json.encode({
    key=ret.key,
    value=ret.value
  })}

end

function delete_handler(req)
  local key = req:stash('key')
  local deleted_kv = box.space.kvs:delete(key)
  if deleted_kv == nil then
    return {status = 404, json = nil }
  end
  return { status = 200 }
end

function update_handler(req)
  local key = req:stash('key')
  local value = req:post_param('value')

  local ok, ret = pcall(box.space.kvs.put, box.space.kvs,{key, value})
  if not ok then
    return { status = 500, body=ret }
  end

  return { status = 200, body = json.encode({
    key=ret.key,
    value=ret.value
  })}
end
  
function main(port) 
  local server = require('http.server').new(nil, port)
  local router = require('http.router').new({charset = "utf8"})
  server:set_router(router)

  router:route({ path = '/' }, handler)

  router:route({ method='GET', path = '/kv/:key' }, get_handler)
  router:route({ method='POST', path = '/kv' }, create_handler)
  router:route({ method='PUT', path = '/kv/:key' }, update_handler)
  router:route({ method='DELETE', path = '/kv/:key' }, delete_handler) 

  server:start()
end

main()

