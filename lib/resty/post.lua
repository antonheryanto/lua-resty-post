-- Copyright (C) Anton heryanto.

local cjson = require "cjson"
local upload = require "resty.upload"
local table_new_ok, new_tab = pcall(require, "table.new")


local open = io.open
local sub  = string.sub
local find = string.find
local byte = string.byte
local type = type
local tonumber = tonumber
local setmetatable = setmetatable
local random = math.random
local re_find = ngx.re.find
local read_body = ngx.req.read_body
local get_post_args = ngx.req.get_post_args
local var = ngx.var
local log = ngx.log
local WARN = ngx.WARN
local prefix = ngx.config.prefix()..'logs/'
local now = ngx.now


if not table_new_ok then
    new_tab = function(narr, nrec) return {} end
end


local _M = new_tab(0, 3)
local mt = { __index = _M }
_M.VERSION = '0.2.2'


local function tmp()
    return now() + random()
end


local function original(name)
    return name
end


function _M.new(self, opts)
    local ot = type(opts)
    opts = ot == 'string' and {path = opts} or ot == 'table' and opts or {}
    opts.path = type(opts.path) == 'string' and opts.path or prefix
    opts.chunk_size = tonumber(opts.chunk_size, 10) or 8192
    opts.name = type(opts.name) == 'function' and opts.name or opts.no_tmp
        and original or tmp
    return setmetatable(opts, mt)
end


local function decode_disposition(self, data)
    local needle = 'filename="'
    local needle_len = 10 -- #needle
    local name_pos = 18 -- #'form-data; name="'
    local last_quote_pos = #data - 1
    local filename_pos = find(data, needle)

    if not filename_pos then
        return sub(data,name_pos,last_quote_pos)
    end

    local field = sub(data,name_pos,filename_pos - 4)
    local name = sub(data,filename_pos + needle_len, last_quote_pos)
    if not name or name == '' then
        return
    end

    local fn = self.name
    local path = self.path
    local tmp_name = fn(name, field)
    local filename = path .. tmp_name
    local handler = open(filename, 'w+b')

    if not handler then
        log(WARN, 'failed to open file ', filename)
    end

    return field, name, handler, tmp_name
end


local function multipart(self)
    local chunk_size = self.chunk_size
    local form, e = upload:new(chunk_size)
    if not form then
        log(WARN, 'failed to new upload: ', e)
        return
    end

    local m = { files = {} }
    local files = {}
    local handler, key, value
    while true do
        local ctype, res, er = form:read()

        if not ctype then
            log(WARN, 'failed to read: ', er)
            return
        end

        if ctype == 'header' then
            local header, data = res[1], res[2]

            if header == 'Content-Disposition' then
                local tmp_name
                key, value, handler, tmp_name = decode_disposition(self, data)

                if handler then
                    files[key] = { name = value, tmp_name = tmp_name }
                end
            end

            if handler and header == 'Content-Type' then
                files[key].type = data
            end
        end

        if ctype == 'body' then
            if handler then
                handler:write(res)
            elseif res ~= '' then
                value = value and value .. res or res
            end
        end

        if ctype == 'part_end' then
            if handler then
                files[key].size = handler:seek('end')
                handler:close()
                if m.files[key] then
                    local nf = #m.files[key]
                    if nf > 0 then
                        m.files[key][nf + 1] = files[key]
                    else
                        m.files[key] = { m.files[key], files[key] }
                    end
                else
                    m.files[key] = files[key]
                end

            elseif key then
                -- handle array input, checkboxes
                -- handle one dimension array input
                -- name[0]
                -- user.name and user[name]
                -- user[0].name and user[0][name]
                -- TODO [0].name ?
                -- FIXME track mk
                local from, to = re_find(key, '(\\[\\w+\\])|(\\.)','jo')
                if from then
                    -- check 46(.)
                    local index = byte(key, from) == 46 and '' or
                        sub(key, from + 1, to - 1)
                    local name = sub(key, 0, from - 1)
                    local field
                    if #key == to then -- parse input[name]
                        local ix = tonumber(index, 10)
                        field = ix and ix + 1 or index
                        index = ''
                    else
                        -- parse input[index].field or input[index][field]
                        local ns = index == '' and 1 or 2
                        local ne = #key
                        if index ~= '' and byte(key, to + 1) ~= 46 then
                            ne = ne - 1
                        end
                        field = sub(key, to + ns, ne)
                        index = index == '' and index or (index + 1)
                    end

                    if type(m[name]) ~= 'table' then
                        m[name] = {}
                    end

                    if index ~= '' and type(m[name][index]) ~= 'table' then
                        m[name][index] = {}
                    end

                    if index ~= '' and m[name][index] then
                        m[name][index][field] = value -- input[0].name
                    else
                        m[name][field] = value
                    end

                elseif m[key] then
                    local mk = m[key]
                    if type(mk) == 'table' then
                        m[key][#mk + 1] = value
                    else
                        m[key] = { mk, value }
                    end
                else
                    m[key] = value
                end
                key = nil
                value = nil
            end
        end

        if ctype == 'eof' then break end

    end
    return m
end


-- proses post based on content type
function _M.read(self)
    local ctype = var.content_type

    if ctype and find(ctype, 'multipart') then
        return multipart(self)
    end

    read_body()

    if ctype and find(ctype, 'json') then
        local body = var.request_body
        return body and cjson.decode(body) or {}
    end

    return get_post_args()
end


return _M
