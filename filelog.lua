--[[

  Copyright (C) 2017 Masatoshi Teruya

  filelog.lua
  lua-resty-filelog

  Created by Masatoshi Teruya on 17/03/30.

--]]
--- modules
local inspect = require('util').inspect;
local getinfo = debug.getinfo;
local concat = table.concat;
local STDOUT = io.stdout;
local STDERR = io.stderr;
local FILE = io.stderr;
-- constants
local INSPECT_OPT = {
    depth = 0,
    padding = 0
};
local DELIMITER = '\x1f';
local ACLF;


--- format
-- @param ...
-- @return msg
local function format( ... )
    local argv = {...};
    local strv = {};

    -- convert to string
    for i = 1, select( '#', ... ) do
        local v = argv[i];
        local t = type( v );

        if t == 'string' then
            strv[i] = v;
        elseif t == 'table' then
            strv[i] = inspect( v, INSPECT_OPT );
        else
            strv[i] = tostring( v );
        end
    end

    return concat( strv, DELIMITER );
end


--- logger
-- @param _
-- @param label
-- @return fn
local function logger( _, label )
    return function( ... )

        if label == 'debug' then
            local info = getinfo( 2, 'nSl' );

            info = inspect( info, INSPECT_OPT );
            FILE:write( format( label, ... ), DELIMITER, info, '\n' );
        else
            FILE:write( format( label, ... ), '\n' );
        end
    end
end


--- accesslog
-- @param prefix
local function accesslog( prefix )
    if ACLF then
        local arr = ACLF.arr;
        local map = ACLF.map;

        for i = 1, #map do
            local field, idx = map[i][1], map[i][2];
            local val = ngx.var[field];
            local t = type( val );

            if t == 'string' then
                arr[idx] = val;
            elseif t == 'table' then
                arr[idx] = inspect( val, INSPECT_OPT );
            elseif t == 'nil' then
                arr[idx] = '';
            else
                arr[idx] = tostring( val );
            end
        end

        if prefix ~= nil then
            assert( type( prefix ) == 'string', 'prefix must be string' );
            FILE:write( prefix, DELIMITER, concat( arr ), '\n' );
        else
            FILE:write( concat( arr ), '\n' );
        end
    end
end


--- setConfig
-- @param cfg
--  .delimiter string
--  .file file handle(default io.stdout)
--  .aclfmt access log format
local function setConfig( cfg )
    assert( type( cfg ) == 'table', 'cfg must be table' );

    -- separater/delimiter
    if cfg.delimiter ~= nil then
        assert(
            type( cfg.delimiter ) == 'string',
            'cfg.delimiter must be string'
        );
        DELIMITER = cfg.delimiter;
    end

    -- output file handle
    if cfg.file then
        assert(
            cfg.file == STDOUT or cfg.file == STDERR,
            'cfg.file must be io.stdout or io.stderr'
        );
        FILE = cfg.file;
    end

    -- access log format
    if cfg.aclfmt then
        local fmt = cfg.aclfmt;
        local arr = {};
        local map = {};
        local cur = 1;
        local head, tail;

        assert(
            type( fmt ) == 'string', 'cfg.aclfmt must be string'
        );

        -- parse format
        head, tail = fmt:find( '$', cur, true );
        while head do
            local name;

            -- extract prev text
            if head > cur then
                arr[#arr+1] = fmt:sub( cur, head - 1 );
            end

            -- extract variable name
            cur = fmt:find( '[^%l%u_]', tail + 1 );
            name = fmt:sub( head + 1, cur - 1 );

            -- maintain mapping info
            arr[#arr+1] = '';
            map[#map + 1] = { name, #arr }

            -- find next
            head, tail = fmt:find( '$', cur, true );
        end

        arr[#arr + 1] = fmt:sub( cur );

        -- empty mapping info
        if #map == 0 then
            ACLF = nil;
        else
            ACLF = {
                arr = arr,
                map = map;
            };
        end
    end
end


return {
    setConfig = setConfig,
    accesslog = accesslog,
    logger = setmetatable({}, {
        __index = logger
    })
};
