-- Copyright (C) Anton heryanto.

local cjson = require "cjson"
local upload = require "resty.upload"
local new_tab = require "table.new"
local open = io.open
local sub  = string.sub
local len = string.len
local find = string.find
local type = type
local read_body = ngx.req.read_body
local get_post_args = ngx.req.get_post_args
local var = ngx.var
local log = ngx.log
local WARN = ngx.WARN
local upload_path = ngx.config.prefix() ..'files/'

local _M = new_tab(0,1)
local needle = 'filename="'
local needle_len = len(needle)
local name_pos = 18 -- 'form-data; name="':len()

local function decode_disposition(self, data)
    local last_quote_pos = len(data) - 1
    local filename_pos = find(data, needle)

    if not filename_pos then return sub(data,name_pos,last_quote_pos) end

    local field = sub(data,name_pos,filename_pos - 4) 
    local name = sub(data,filename_pos + needle_len, last_quote_pos)

    if name == '' then return end
    local path = upload_path 
    if self.get_path then
        path, name = self.get_path(self, name, field)
    end

    local filename = path .. name
    local handler = open(filename, 'w+')

    if not handler then log(nWARN, 'failed to open file ', filename) end

    return field, name, handler
end


local function multipart(self)  
    local chunk_size = 8192
    local form,err = upload:new(chunk_size)

    if not form then
        log(WARN, 'failed to new upload: ', err)
        return 
    end

    local m = { files = {} }
    local files = {}
    local handler, key, value

    while true do
        local ctype, res, err = form:read()

        if not ctype then 
            log(WARN, 'failed to read: ', err) 
            return 
        end

        if ctype == 'header' then
            local header, data = res[1], res[2]

            if header == 'Content-Disposition' then
                key, value, handler = decode_disposition(self, data)
                
                if handler then files[key] = { name = value } end
            end

            if handler and header == 'Content-Type' then 
                files[key].mime = data 
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
                if m[key] then
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
function _M.get(self)
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

