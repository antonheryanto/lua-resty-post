lua-resty-post
==============

Openresty utility for HTTP post

Table of Contents
=================
* [Status](#status)
* [Description](#description)
* [Installation](#installation)
* [How to use](#how-to-use)
* [Copyright and License](#copyright-and-license)
* [See Also](#see-also)

Status
======

This library beta tested and used in production.

Description
===========

This library processed HTTP using [lua-resty-upload](https://github.com/openresty/lua-resty-upload) which very fast and low memory used, it handles multiple type of HTTP POST and converted into lua table:
* application/x-www-form-urlencoded
* application/json
* multipart/form-data
  * [FormData](https://developer.mozilla.org/en-US/docs/Web/API/FormData)
  * [File Upload](#file-upload)
  * [Array Input](#array-input)

[Back to TOC](#table-of-contents)

Installation
============

* Download or clone this repo
* copy or link to openresty/lualib/resty/ or to any your lua_package_path

[Back to TOC](#table-of-contents)

How to use
==========

```lua
local resty_post = require 'resty.post'
local post = resty_post:new()
local m = post:read()
-- return table with all form value and file
```

[Back to TOC](#table-of-contents)

File Upload
===========

* Support multiple file upload
* files uploaded into logs directory (ngx.config.prefix() + 'logs' as default)
* files info stored in files property using field name as key


Array Input
===========

Support multiple input of similar name
--------------------------------------
It is useful for thing like HTML input checkboxes or select in multiple mode
```html
<input type="checkbox" name="check_multi" value="1">
<input type="checkbox" name="check_multi" value="2">
<select name="select_multi" multiple>
 <option value="">Please select</option>
 <option value="1">One</option>
 <option value="2">Two</option>
</select>
```
converted into
``` lua
{
 check_multi = { 1, 2 }
 select_multi = { 1, 2 }
}
```

Support array input with name
--------------------------------------
This is like supporting input which mimic class and property, which can be uses to handle dynamic input
support PHP style (dynamic language) and ASP.NET MVC binding style (static language which uses class)
```html
<div class="user-single">
 <input name="user.title" value="Mr.">
 <input name="user[name]" value="Foo Bar">
</div>
<div class="user-static">
 <input name="users[0].title" value="Mr.">
 <input name="users[0].name" value="John Do">
</div>
<div class="user-dynamic">
 <input name="users[0][title]" value="Ms.">
 <input name="users[0][name]" value="Jane Do">
</div>
```
converted into
```lua
{
 user = {
  title = "Mr.",
  name = "Foo Bar"
 },
 users = {
  {
   title = "Mr.",
   name = "John Do"
  },
  {
   title = "Ms.",
   name = "Jane Do"
  }
 }
}
```

[Back to TOC](#table-of-contents)

Copyright and License
=====================

This module is licensed under the BSD license.

Copyright (C) 2015, by Anton Heryanto Hasan.

All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

[Back to TOC](#table-of-contents)

See Also
========
* [lua-resty-stack](https://github.com/antonheryanto/lua-resty-stack) 
* [lua-resty-upload](https://github.com/openresty/lua-resty-upload)
* [lua-nginx-module](https://github.com/openresty/lua-nginx-module)

[Back to TOC](#table-of-contents)
