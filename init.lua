local Fs = require('fs')
local Path = require('path')

-- TODO: make Fs.* take both number and string?
local function mode(x)
  return ('%o'):format(x)
end

--
-- mimick mkdir -p
--
local function mkdir_p(path, perm, callback)
  path = Path.resolve(process.cwd(), path)
  Fs.mkdir(path, perm, function(err)
    if not err then callback() ; return end
    if err.code == 'ENOENT' then
      mkdir_p(Path.dirname(path), perm, function(err)
        if err then
          callback(err)
        else
          mkdir_p(path, perm, callback)
        end
      end)
    elseif err.code == 'EEXIST' then
      Fs.stat(path, function(sterr, stat)
        if sterr or not stat.is_directory then
          callback(sterr)
        elseif tostring(stat.mode):sub(-#perm) ~= perm then
          Fs.chmod(path, perm, callback)
        else
          callback()
        end
      end)
    else
      callback(err)
    end
  end)
end

--
-- mimick find
--
local function find(path, options, callback)

  -- defaults
  options = options or {}
  match_fn = options.match_fn or function(path, stat, depth, cb) cb() end
  dir_fn = options.dir_fn or function(path, stat, depth, cb) cb() end

  -- cache highly used functions
  local normalize = Path.normalize
  local join = Path.join
  local stat = options.follow and Fs.stat or Fs.lstat
  local readdir = Fs.readdir

  -- base path
  local base = Path.resolve(process.cwd(), path)

  -- collect seen inodes
  local inos = {}

  -- recursive walk helper
  local function walk(path, depth, cb)
    -- stat, resolving symlinks
    stat(path, function(err, st)
      -- stat failed? step out.
      if err then cb(err) ; return end
      -- inode seen? step out
      -- N.B. this is to cope with symlinks pointing to '.'
      local inode = st.ino
      if inos[inode] then cb() ; return end
      -- mark inode as seen
      -- FIXME: each allocation causes table rewrite?
      inos[inode] = true
      -- call matcher
      match_fn(path, st, depth, function(err)
        -- `true` error means stop going deeper
        if err and err ~= true then cb(err) ; return end
        -- path is not directory? we re done.
        if not st.is_directory then cb() ; return end
        -- path is directory. read files
        readdir(path, function(err, files)
          if err then cb(err) ; return end
          -- recursively iterate thru files
          local len = #files
          local i = 1
          local function _w()
            if i > len then
              -- notify of directory is processed
              dir_fn(path, st, depth, cb)
            else
              walk(join(path, files[i]), depth + 1, _w)
              i = i + 1
            end
          end
          _w()
        end)
      end)
    end)
  end

  -- walk the tree
  walk(base, 0, callback)

end

--
-- mimick rm -fr
--
local function rm_rf(path, callback)

  -- cache highly used functions
  local unlink = Fs.unlink
  local rmdir = Fs.rmdir

  path = Path.resolve(process.cwd(), path)
  find(path, {
    --follow = false,
    match_fn = function(path, stat, depth, cb)
      if not stat.is_directory then
        unlink(path, cb)
      else
        cb()
      end
    end,
    dir_fn = function(path, stat, depth, cb)
      rmdir(path, cb)
    end,
  }, callback)

end

--
-- mimick cp -a
--
local function cp_a(src, dst, callback)

  -- cache highly used functions
  local join = Path.join
  local dirname = Path.dirname
  local basename = Path.basename
  local read = Fs.read_file
  local write = Fs.write_file
  local readlink = Fs.readlink
  local symlink = Fs.symlink
  local chmod = Fs.chmod
  local chown = Fs.chown
  local sub = require('string').sub

  -- expand paths
  local src_orig = Path.normalize(src)
  src = Path.resolve(process.cwd(), src)
  dst = Path.resolve(process.cwd(), dst)

  -- dots are special cases. E.g. cp_a . /foo should copy content of current directory
  -- while cp_a ../foo /bar should copy file/directory ../foo as whole
  local skip_len = #dirname(src) + 2
  if src_orig == '.' then
    skip_len = #src + 2
  end

  -- walk over the source
  find(src, {
    -- for each source file
    match_fn = function(path, stat, depth, cb)
      -- compose target path
      local new_path = join(dst, sub(path, skip_len))
      --print('?'..path)
      --print('!'..new_path)
      --p(path, stat)
      -- helper to set target owner and mode to source's ones
      local function perms(err)
        if err then cb(err) ; return end
        chmod(new_path, mode(stat.mode), function(err)
          if err then cb(err) ; return end
          chown(new_path, stat.uid, stat.gid, function(err)
            -- FIXME: err is unknown is there were no rights to chown
            --if err then cb(err) ; return end
            cb()
          end)
        end)
      end
      -- create target
      -- directory
      if stat.is_directory then
        mkdir_p(new_path, mode(stat.mode), perms)
      -- file
      elseif stat.is_file then
        -- TODO: stream it
        read(path, function(err, data)
          write(new_path, data, perms)
        end)
      -- symlink
      elseif stat.is_symbolic_link then
        readlink(path, function(err, realpath)
          if err then cb(err) ; return end
          symlink(realpath, new_path, 'r', perms)
        end)
      -- special nodes not supported
      -- Fs.mknod() is missing
      -- FIXME: ^^^
      else
        cb({path = path, code = 'ENOTSUPP'})
      end
    end,
  }, callback)

end

-- export
return setmetatable({
  mkdir_p = mkdir_p,
  find = find,
  rm_rf = rm_rf,
  cp_a = cp_a,
}, { __index = Fs })
