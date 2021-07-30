local t = require('luatest')
local g = t.group()
local app = require('app')

local http_client = require('http.client')
local json = require('json')

base_uri = 'localhost'
port = '8080'

main(port)

g.test_root = function()
    local r = http_client.get(base_uri .. ':' .. port  .. '/')
    t.assert_equals(r.status, 200)
end

g.test_get = function()
    local r = http_client.get(base_uri .. ':' .. port  .. '/kv/1')
    t.assert_equals(r.status, 404)
end

g.test_post = function()
    local r = http_client.post(base_uri .. ':' .. port  .. '/kv')
    t.assert_equals(r.status, 400)
end
