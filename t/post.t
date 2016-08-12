use Test::Nginx::Socket::Lua;
use Cwd qw(cwd);

repeat_each(2);

plan tests => repeat_each() * (blocks() * 2);

my $pwd = cwd();

our $HttpConfig = <<"_EOC_";
  lua_package_path "$pwd/lib/?.lua;;";
_EOC_

no_long_string();
no_diff();
run_tests();

__DATA__

=== TEST 1: simple post
--- http_config eval: $::HttpConfig
--- config
    location /t {
      content_by_lua_block {
        local cjson = require 'cjson'
        local post = require 'resty.post':new()
        local m = post:read()
        ngx.say(cjson.encode(m))
      }
    }
--- request
POST /t
a=3&b=4&c
--- response_body
{"b":"4","a":"3","c":true}


=== TEST 2: array post
--- http_config eval: $::HttpConfig
--- config
    location /t {
      content_by_lua_block {
        local cjson = require 'cjson'
        local post = require 'resty.post':new()
        local m = post:read()
        ngx.say(cjson.encode(m))
      }
    }
--- request
POST /t
a=1&a=2&b=1&c=1&c=2
--- response_body
{"b":"1","a":["1","2"],"c":["1","2"]}


=== TEST 3: json
--- http_config eval: $::HttpConfig
--- config
    location /t {
      content_by_lua_block {
        local cjson = require "cjson"
        local post = require "resty.post":new()
        local m = post:read()
        ngx.say(cjson.encode(m))
      }
    }
--- more_headers
Content-Type: application/json
--- request
POST /t
{"a":3,"b":4,"c":true}
--- response_body
{"b":4,"a":3,"c":true}
--- error_log


=== TEST 4: post with formdata file
--- http_config eval: $::HttpConfig
--- config
    location /t {
      content_by_lua_block {
        local cjson = require 'cjson'
        local post = require 'resty.post':new()
        local m = post:read()
        m.files.file1.tmp_name = nil
        ngx.say(cjson.encode(m))
      }
    }
--- more_headers
Content-Type: multipart/form-data; boundary=---------------------------820127721219505131303151179
--- request eval
qq{POST /t\n-----------------------------820127721219505131303151179\r
Content-Disposition: form-data; name="file1"; filename="a.txt"\r
Content-Type: text/plain\r
\r
Hello, world\r\n-----------------------------820127721219505131303151179\r
Content-Disposition: form-data; name="test"\r
\r
value\r
\r\n-----------------------------820127721219505131303151179--\r
}
--- response_body
{"files":{"file1":{"type":"text\/plain","size":12,"name":"a.txt"}},"test":"value\r\n"}

