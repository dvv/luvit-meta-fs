Usage
-----

    -- import augmented 'fs' module
    local Fs = require('meta-fs')

    -- print everything under /etc
    Fs.find('/etc', {
      match_fn = function(path, stat, depth, cb)
        print('FOUND', path)
        -- you can stop walking by passing an error to `cb`
        cb(depth > 3 and true or nil)
      end
    }, function(err)
      print('DONE', err)
    end)


    -- remove /home/foo completely
    Fs.rm_rf('/home/foo', print)


    -- make nested directories
    Fs.mkdir_p('/home/foo/bar/baz', print)


    -- copy source file/directory
    Fs.cp_a('/home/foo/bar/baz', '/tmp/wow', print)


License
-------

Copyright (c) 2011 Vladimir Dronnikov <dronnikov@gmail.com>

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
