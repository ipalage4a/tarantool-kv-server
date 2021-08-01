local t = require('luatest')
local g = t.group()
local server = require('app.server')

local http_client = require('http.client')
local json = require('json')

box.cfg{
  work_dir="/tmp",
}

base_uri = 'localhost'
port = '8080'
name = 'test_kvs'

local s = server.new(name,  port)
s:start()

kvs = box.space[name]

g.after_each(function()
 for k, v in kvs:pairs() do
   kvs:delete(v[1])
 end
end)

g.test_root = function()
    local r = http_client.get(base_uri .. ':' .. port  .. '/')
    t.assert_equals(r.status, 200)
end

g.test_get_not_found = function()
    local r = http_client.get(base_uri .. ':' .. port  .. '/kv/1')
    t.assert_equals(r.status, 404)
end

g.test_get_success = function()
    kvs:insert{'1', "{'priv': 'world'}"}

    local r = http_client.get(base_uri .. ':' .. port  .. '/kv/1')
    t.assert_equals(r.status, 200)
    t.assert_equals(json.decode(r.body).key, '1')
end

g.test_post_success = function()
    local r = http_client.post(base_uri .. ':' .. port  .. '/kv', 'key=1&value={"test": "value"}')
    t.assert_equals(r.status, 200)

    local kv = kvs:get('1')
    t.assert_equals(kv[0], nil)
end

g.test_post_exist = function()
    kvs:insert{'1', "{'priv': 'world'}"}

    local r = http_client.post(base_uri .. ':' .. port  .. '/kv', 'key=1&value={"test": "value"}')
    t.assert_equals(r.status, 409)
end


g.test_post_empty_request = function()
    local r = http_client.post(base_uri .. ':' .. port  .. '/kv')
    t.assert_equals(r.status, 400)
end

g.test_post_bad_request = function()
    local r = http_client.post(base_uri .. ':' .. port  .. '/kv', 'key=1&value=test')
    t.assert_equals(r.status, 400)
end


g.test_put_success = function()
    local kv  = kvs:insert{'1', "{'priv': 'world'}"}
    local body = {test = "value"}
    local r = http_client.put(base_uri .. ':' .. port  .. '/kv/1', 'value=' .. json.encode(body))

    t.assert_equals(r.status, 200)
    t.assert_equals(json.decode(r.body).value, json.encode(body))
end

g.test_put_not_found = function()
    local kv = {test = "value"}
    local r = http_client.put(base_uri .. ':' .. port  .. '/kv/1', 'value=' .. json.encode(kv))
    t.assert_equals(r.status, 404)
end

g.test_put_bad_request = function()
    local r = http_client.put(base_uri .. ':' .. port  .. '/kv/1', 'value={"tes"t": "value"}')
    t.assert_equals(r.status, 400)
end


g.test_delete_success = function ()
  kvs:insert{'1', "{'priv': 'world'}"}

  local r = http_client.delete(base_uri .. ':' .. port .. '/kv/1')
  t.assert_equals(r.status, 200)

  local kv = kvs:get('1')
  t.assert_equals(kv,  nil)
end

g.test_delete_not_found = function ()
  local r= http_client.delete(base_uri .. ':' .. port .. '/kv/1')
  t.assert_equals(r.status, 404)
  t.assert_equals(kvs:get('1'), nil)
end
