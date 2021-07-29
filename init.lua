#!/usr/bin/env tarantool

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
  local kv = box.space.kvs:select(key)
  if kv == nil then 
    return {
      status = 404
    }
  end
  return req:render {
    status = 200,
    json = kv
  }
end

function post_handler(req)
  local key = req:post_param('key')
  local body = req:post_param('body')
  return req:render{json = {['key'] = key, ['body']=body}}
end


local server = require('http.server').new(nil, 80)
local router = require('http.router').new({charset = "utf8"})
server:set_router(router)

router:route({ path = '/' }, handler)
router:route({ method='GET', path = '/debug' }, debug_handler)

router:route({ method='GET', path = '/kv/:key' }, get_handler)
router:route({ method='POST', path = '/kv' }, post_handler)
router:route({ method='PUT', path = '/kv/:key' }, handler)
router:route({ method='DELETE', path = '/kv/:key' }, handler)

server:start()

