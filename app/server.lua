local json = require('json')

local app = {}

local function root_handler(req)
  return req:render{ json = { ['Your-IP-Is'] = req:peer().host } }
end

function get_handler(req)
  local key = req:stash('key')
  local kv = app.space:get(key)
  if kv == nil then 
    return {status = 404 }
  end

  return { status = 200, body = json.encode({
    key=kv.key,
    value=kv.value
  })}
end

local function create_handler(req)
  local key = req:post_param('key')
  local value = req:post_param('value')

  local ok, err = pcall(json.decode, value) 

  if key == nil or value == nil or not ok then
    return { status = 400 }
  end

  local exist = app.space:get(key)

  if exist ~= nil then 
    return { status = 409 }
  end

  local ok, ret = pcall(app.space.insert, app.space, {key, value})

  if not ok then
    return { status = 500, body=ret }
  end

  return { status = 200, body = json.encode({
    key=ret.key,
    value=ret.value
  })}

end

local function delete_handler(req)
  local key = req:stash('key')
  local deleted_kv = app.space:delete(key)
  if deleted_kv == nil then
    return {status = 404 }
  end
  return { status = 200 }
end

local function update_handler(req)
  local key = req:stash('key')
  local value = req:post_param('value')

  local ok, err = pcall(json.decode, value) 

  if key == nil or value == nil or not ok then
    return { status = 400 }
  end

  local exist = app.space:get(key)

  if exist == nil then 
    return { status = 404 }
  end

  local ok, ret = pcall(app.space.put, app.space, {key, value})
  if not ok then
    return { status = 500, body=ret }
  end

  return { status = 200, body = json.encode({
    key=ret.key,
    value=ret.value
  })}
end

local function start(self)
  self.server:start()
end

local function new(space_name, port)
  local s = require('http.server').new(nil, port)
  local r = require('http.router').new({charset = "utf8"})

  s:set_router(r)
  r:route({ path = '/' }, root_handler)
  r:route({ method='GET', path = '/kv/:key' }, get_handler)
  r:route({ method='POST', path = '/kv' }, create_handler)
  r:route({ method='PUT', path = '/kv/:key' }, update_handler)
  r:route({ method='DELETE', path = '/kv/:key' }, delete_handler) 

  box.once("init", function()
    local db = box.schema.space.create(space_name)
    db:format({{ name = 'key', type = 'string'}, { name = 'value', type = 'string'}})
    db:create_index('pk', { parts = { { field = 'key', type = 'string'}}})
  end)

  app.space = box.space[space_name]

  local self = {
    server = s,
    start = start,
  }


  return self
end

return { new = new }
