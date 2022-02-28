-- ASalvail's GCMP Mapping Script
-- Based off of Jor'Mox's Generic Map Script
-- the script self-updates, changing this value will bring an update to all installations
-- make sure versions.lua has the latest version in it
-- local version = "2.0.24"

    -- look into options for non-standard door usage for speedwalk
    -- come up with aliases to set translations and custom exits, add appropriate help info

mudlet = mudlet or {}
mudlet.mapper_script = true
map = map or {}

local oldstring = string
local string = utf8
string.format = oldstring.format
string.trim = oldstring.trim
string.starts = oldstring.starts
string.split = oldstring.split
string.ends = oldstring.ends


local profile_path = getMudletHomeDir()
profile_path = profile_path:gsub("\\","/")

local downloading, walking
local mt = getmetatable(map) or {}

local exit_map = {
    n = 'north',    ne = 'northeast',   nw = 'northwest',   e = 'east',
    w = 'west',     s = 'south',        se = 'southeast',   sw = 'southwest',
    u = 'up',       d = 'down',         ["in"] = 'in',      out = 'out',
    l = 'look',
    ed = 'eastdown',    eu = 'eastup',  nd = 'northdown',   nu = 'northup',
    sd = 'southdown',   su = 'southup', wd = 'westdown',    wu = 'westup',
}

local short = {}
for k,v in pairs(exit_map) do
    short[v] = k
end

local stub_map = {
    north = 1,      northeast = 2,      northwest = 3,      east = 4,
    west = 5,       south = 6,          southeast = 7,      southwest = 8,
    up = 9,         down = 10,          ["in"] = 11,        out = 12,
    northup = 13,   southdown = 14,     southup = 15,       northdown = 16,
    eastup = 17,    westdown = 18,      westup = 19,        eastdown = 20,
    [1] = "north",  [2] = "northeast",  [3] = "northwest",  [4] = "east",
    [5] = "west",   [6] = "south",      [7] = "southeast",  [8] = "southwest",
    [9] = "up",     [10] = "down",      [11] = "in",        [12] = "out",
    [13] = "northup", [14] = "southdown", [15] = "southup", [16] = "northdown",
    [17] = "eastup", [18] = "westdown", [19] = "westup",    [20] = "eastdown",
}

local coord_map = {
    [1] = {0,1,0},      [2] = {1,1,0},      [3] = {-1,1,0},     [4] = {1,0,0},
    [5] = {-1,0,0},     [6] = {0,-1,0},     [7] = {1,-1,0},     [8] = {-1,-1,0},
    [9] = {0,0,1},      [10] = {0,0,-1},    [11] = {0,0,0},     [12] = {0,0,0},
    [13] = {0,1,1},     [14] = {0,-1,-1},   [15] = {0,-1,1},    [16] = {0,1,-1},
    [17] = {1,0,1},     [18] = {-1,0,-1},   [19] = {-1,0,1},    [20] = {1,0,-1},
}

local reverse_dirs = {
    north = "south", south = "north", west = "east", east = "west", up = "down",
    down = "up", northwest = "southeast", northeast = "southwest", southwest = "northeast",
    southeast = "northwest", ["in"] = "out", out = "in",
    northup = "southdown", southdown = "northup", southup = "northdown", northdown = "southup",
    eastup = "westdown", westdown = "eastup", westup = "eastdown", eastdown = "westup",
}

local wait_echo = {}
local mapper_tag = "<112,229,0>(<73,149,0>mapper<112,229,0>): <255,255,255>"
local debug_tag = "<255,165,0>(<200,120,0>debug<255,165,0>): <255,255,255>"
local err_tag = "<255,0,0>(<178,34,34>error<255,0,0>): <255,255,255>"

--------------------------
-- Configuration functions
--------------------------
map.defaults = {
    mode = "normal", -- can be normal, or complex
    stretch_map = true,
    speedwalk_delay = 0.2,
    speedwalk_wait = true,
    speedwalk_random = true,
    map_window = {
        x = 0,
        y = 0,
        w = "30%",
        h = "40%",
        origin = "topright",
        shown = false,
    },
    custom_exits = {},  -- format: short_exit = {long_exit, reverse_exit, x_dif, y_dif, z_dif}
                        -- ex: { us = {"upsouth", "downnorth", 0, -1, 1}, dn = {"downnorth", "upsouth", 0, 1, -1} }
    use_translation = true,
    lang_dirs = {n = 'n', ne = 'ne', nw = 'nw', e = 'e', w = 'w', s = 's', se = 'se', sw = 'sw',
        u = 'u', d = 'd', ["in"] = 'in', out = 'out', north = 'north', northeast = 'northeast',
        east = 'east', west = 'west', south = 'south', southeast = 'southeast', southwest = 'southwest',
        northwest = 'northwest', up = 'up', down = 'down', l = 'l', look = 'look',
        ed = 'ed', eu = 'eu', eastdown = 'eastdown', eastup = 'eastup',
        nd = 'nd', nu = 'nu', northdown = 'northdown', northup = 'northup',
        sd = 'sd', su = 'su', southdown = 'southdown', southup = 'southup',
        wd = 'wd', wu = 'wu', westdown = 'westdown', westup = 'westup',
    },
    debug = false,
    --download_path = "https://raw.githubusercontent.com/Mudlet/Mudlet/development/src/mudlet-lua/lua/generic-mapper",
}

local function config()
    local defaults = map.defaults
    local configs = map.configs or {}
    local path = profile_path.."/map downloads"
    if not io.exists(path) then lfs.mkdir(path) end
    -- load stored configs from file if it exists
    if io.exists(path.."/configs.lua") then
        table.load(path.."/configs.lua",configs)
    end
    -- overwrite default values with stored config values
    configs = table.update(defaults, configs)
    map.configs = configs
    map.configs.translate = {}
    for k, v in pairs(map.configs.lang_dirs) do
        map.configs.translate[v] = k
    end
    -- incorporate custom exits
    for k,v in pairs(map.configs.custom_exits) do
        exit_map[k] = v[1]
        reverse_dirs[v[1]] = v[2]
        short[v[1]] = k
        local count = #coord_map + 1
        coord_map[count] = {v[3],v[4],v[5]}
        stub_map[count] = v[1]
        stub_map[v[1]] = count
    end
    -- update to the current download path
    --[[
    if map.configs.download_path == "https://raw.githubusercontent.com/JorMox/Mudlet/development/src/mudlet-lua/lua/generic-mapper" then
        map.configs.download_path = "https://raw.githubusercontent.com/Mudlet/Mudlet/development/src/mudlet-lua/lua/generic-mapper"
    end
    --]]

    -- setup metatable to store sensitive values
    local protected = {"mapping", "current_room_id", "current_room_name", "current_room_exits", "current_room_area_id",
        "prev_room_id", "prev_room_name", "prev_room_exits", "prev_room_area_id", "mode", "version", "disconnected_area"}
    mt = getmetatable(map) or {}
    mt.__index = mt
    mt.__newindex = function(tbl, key, value)
            if not table.contains(protected, key) then
                rawset(tbl, key, value)
            else
                error("Protected Map Table Value")
            end
        end
    mt.set = function(key, value)
            if table.contains(protected, key) then
                mt[key] = value
            end
        end
    setmetatable(map, mt)
    map.set("mode", configs.mode)
    -- map.set("version", version)

    if map.configs.map_window.shown then
        map.show_map(true)
    end
end

local bool_configs = {'stretch_map', 'speedwalk_wait', 'speedwalk_random',
    'debug', 'use_translation'}
-- function intended to be used by an alias to change config values and save them to a file for later
function map.set_configs(key, val, sub_key)
    if val == "off" or val == "false" then
        val = false
    elseif val == "on" or val == "true" then
        val = true
    end
    local toggle = false
    if val == nil or val == "" then toggle = true end
    key = key:gsub(" ","_")
    if tonumber(val) then val = tonumber(val) end
    if not toggle then
        if key == "map_window" then
            if map.configs.map_window[sub_key] then
                map.configs.map_window[sub_key] = val
                map.echo(string.format("Map config %s set to: %s", sub_key, tostring(val)))
            else
                map.echo("Unknown map config.",false, true)
            end
        elseif key =="lang_dirs" then
            sub_key = exit_map[sub_key] or sub_key
            if map.configs.lang_dirs[sub_key] then
                local long_dir, short_dir = val[1],val[2]
                if #long_dir < #short_dir then long_dir, short_dir = short_dir, long_dir end
                map.configs.lang_dirs[sub_key] = long_dir
                map.configs.lang_dirs[short[sub_key]] = short_dir
                map.echo(string.format("Direction/command %s, abbreviated as %s, now interpreted as %s.", long_dir, short_dir, sub_key))
                map.configs.translate = {}
                for k, v in pairs(map.configs.lang_dirs) do
                    map.configs.translate[v] = k
                end
            else
                map.echo("Invalid direction/command.", false, true)
            end
        elseif key == "custom_exits" then
            if type(val) == "table" then
                for k, v in pairs(val) do
                    map.configs.custom_exits[k] = v
                    map.echo(string.format("Custom Exit short direction %s, long direction %s",k,v[1]))
                    map.echo(string.format("    set to: x: %s, y: %s, z: %s, reverse: %s",v[3],v[4],v[5],v[2]))
                end
            else
                map.echo("Custom Exit config must be in the form of a table.", false, true)
            end
        elseif map.configs[key] ~= nil then
            map.configs[key] = val
            map.echo(string.format("Config %s set to: %s", key, tostring(val)))
        else
            map.echo("Unknown configuration.",false,true)
            return
        end
    elseif toggle then
        if (type(map.configs[key]) == "boolean" and table.contains(bool_configs, key)) then
            map.configs[key] = not map.configs[key]
            map.echo(string.format("Config %s set to: %s", key, tostring(map.configs[key])))
        elseif key == "map_window" and sub_key == "shown" then
            map.configs.map_window.shown = not map.configs.map_window.shown
            map.echo(string.format("Map config %s set to: %s", "shown", tostring(map.configs.map_window.shown)))
        else
            map.echo("Unknown configuration.",false,true)
            return
        end
    end
    table.save(profile_path.."/map downloads/configs.lua",map.configs)
    config()
end

function map.loadMap(address)
    local path = profile_path .. "/map downloads/map.dat"
    if not address then
        loadMap(path)
        map.echo("Map reloaded from local copy.")
    else
        if not string.match(address,"/[%a_]+%.dat$") then
            address = address .. "/map.dat"
        end
        downloading = true
        downloadFile(path, address)
        map.echo(string.format("Downloading map file from: %s.",address))
    end
end

---------------------
-- Printing Functions
---------------------
local function show_err(msg, debug)
    map.echo(msg, debug, true)
    error(msg, 2)
end

local function print_echoes(what, debug, err)
    moveCursorEnd("main")
    local curline = getCurrentLine()
    if curline ~= "" then echo("\n") end
    decho(mapper_tag)
    if debug then decho(debug_tag) end
    if err then decho(err_tag) end
    cecho(what)
    echo("\n")
end

local function print_wait_echoes()
    for k, v in ipairs(wait_echo) do
        print_echoes(v[1], v[2], v[3])
    end
    wait_echo = {}
end

function map.echo(what, debug, err, wait)
    if debug and not map.configs.debug then return end
    what = tostring(what) or ""
    if wait then
        table.insert(wait_echo, {what, debug, err})
        return
    end
    print_wait_echoes()
    print_echoes(what, debug, err)
end

local function get_area_id_by_match(area_name, exact)
    area_name = area_name:lower()
    local list = getAreaTable()

    -- iterate over the list of areas, matching them with substring match.
    -- if we get match a single area, then return its ID, otherwise return
    -- 'false' and a message that there are than one are matches
    local return_id, full_area_name, multiple_areas = nil, nil, {}
    for area, id in pairs(list) do
        if (not exact and area:lower():find(area_name, 1, true)) or (exact and area_name == area:lower()) then
            return_id = id
            full_area_name = area
            multiple_areas[#multiple_areas+1] = area
        end
    end

    if #multiple_areas == 1 then
        return return_id, full_area_name
    else
        return nil, nil, multiple_areas
    end
end

function map.echo_room_list(area_name, exact)
    local area_id, msg, multiples
    local list_color, other_color = "DarkSlateGrey","LightSlateGray"
    if tonumber(area_name) then
        area_id = tonumber(area_name)
        msg = getAreaTableSwap()[area_id]
    else
        area_id, msg, multiples = get_area_id_by_match(area_name, exact)
    end
    if area_id then
        local room_list, end_result = getAreaRooms(area_id) or {}, {}

        -- obtain a room list for each of the room IDs we got
        local get_room_name = getRoomName
        for _, id in pairs(room_list) do
            end_result[id] = get_room_name(id)
        end
        room_list[#room_list+1], room_list[0] = room_list[0], nil
        -- sort room IDs so we can display them in order
        table.sort(room_list)

        local echoLink, format, fg, echo = echoLink, string.format, fg, cecho
        -- now display something half-decent looking
        cecho(format("<%s>List of all rooms in <%s>%s<%s> (areaID <%s>%s<%s> - <%s>%d<%s> rooms):\n",
            list_color, other_color, msg, list_color, other_color, area_id, list_color, other_color, #room_list, list_color))
        -- use pairs, as we can have gaps between room IDs
        for _, room_id in pairs(room_list) do
            local room_name = end_result[room_id]
            cechoLink(format("<%s>%7s",other_color,room_id), 'map.speedwalk('..room_id..')',
                format("Go to %s (%s)", room_id, tostring(room_name)), true)
            cecho(format("<%s>: <%s>%s<%s>.\n", list_color, other_color, room_name, list_color))
        end
    elseif not area_id and #multiples > 0 then
        local all_areas, format = getAreaTable(), string.format
        local function count_rooms(areaname)
            local area_id = all_areas[areaname]
            local all_rooms = getAreaRooms(area_id) or {}
            local areac = (#all_rooms or 0) + (all_rooms[0] and 1 or 0)
            return areac
        end
        map.echo("For which area would you want to list rooms for?")
        for _, area_name in ipairs(multiples) do
            echo("  ")
            setUnderline(true)
            cechoLink(format("<%s>%-40s (%d rooms)", other_color, area_name, count_rooms(area_name)),
                'map.echoRoomList("'..area_name..'", true)', "Click to view the room list for "..area_name, true)
            setUnderline(false)
            echo("\n")
        end
    else
        map.echo(string.format("Don't know of any area named '%s'.", area_name),false,true)
    end
    resetFormat()
end

function map.echo_area_list()
    local total_room_count = 0
    local rlist = getAreaTableSwap()
    local list_color, other_color = "DarkSlateGrey","LightSlateGray"

    -- count the amount of rooms in an area, taking care to count the room in the 0th
    -- index as well if there is one
    -- saves the total room count on the side as well
    local function count_rooms(areaid)
        local all_rooms = getAreaRooms(areaid) or {}
        local areac = (#all_rooms or 0) + (all_rooms[0] and 1 or 0)
        total_room_count = total_room_count + areac
        return areac
    end

    local getAreaRooms, cecho, fg, echoLink, format = getAreaRooms, cecho, fg, echoLink, string.format
    cecho(format("<%s>List of all areas we know of (click to view room list):\n",list_color))
    for id = 1,table.maxn(rlist) do
        if rlist[id] then
            cecho(format("<%s>%7d ", other_color, id))
            fg(list_color)
            echoLink(format("%-40s (%d rooms)",rlist[id],count_rooms(id)), 'map.echoRoomList("'..id..'", true)',
                "View the room list for "..rlist[id], true)
            echo("\n")
        end
    end
    cecho(string.format("<%s>Total amount of rooms in this map: %s\n", list_color, total_room_count))
end


------------------
-- Room Management
------------------

local function add_door(room_id, dir, status)
    -- create or remove a door in the designated direction
    -- consider options for adding pickable and passable information
    dir = exit_map[dir] or dir
    if not table.contains(exit_map,dir) then
        error("Add Door: invalid direction.",2)
    end
    if type(status) ~= "number" then
        status = assert(table.index_of({"none","open","closed","locked"},status),
            "Add Door: Invalid status, must be none, open, closed, or locked") - 1
    end
    local exits = getRoomExits(room_id)
    -- check handling of custom exits here
    if not exits[dir] then
        setExitStub(room_id,stub_map[dir],true)
    end
    -- check handling of custom exits here
    if not table.contains({'u','d'},short[dir]) then
        setDoor(room_id,short[dir],status)
    else
        setDoor(room_id,dir,status)
    end
end

local function check_doors(room_id,exits)
    -- looks to see if there are doors in designated directions
    -- used for room comparison, can also be used for pathing purposes
    if type(exits) == "string" then exits = {exits} end
    local statuses = {}
    local doors = getDoors(room_id)
    local dir
    for k, v in pairs(exits) do
        dir = short[k] or short[v]
        if table.contains({'u','d'},dir) then
            dir = exit_map[dir]
        end
        if not doors[dir] or doors[dir] == 0 then
            return false
        else
            statuses[dir] = doors[dir]
        end
    end
    return statuses
end

local function find_room(name_or_id, area)
    -- looks for rooms with a particular name, and if given, in a specific area
    local rooms = searchRoom(name_or_id)  -- {room_id: room_name}
    local area_id
    if type(area) == "string" then
        local areas = getAreaTable() or {} -- {a_name: a_ID}
        for k,v in pairs(areas) do
            if string.lower(k) == string.lower(area) then
                area_id = v
                break
            end
        end
    end
    -- filter on name and area
    for k,v in pairs(rooms) do
        if string.lower(v) ~= string.lower(name_or_id) or k ~= name_or_id then
            rooms[k] = nil
        elseif area and getRoomArea(k) ~= area_id then
            rooms[k] = nil
        end
    end
    return rooms
end

local function get_room_stubs(room_id)
    -- turns stub info into table similar to exit table
    local stubs = getExitStubs(room_id)
    if type(stubs) ~= "table" then stubs = {} end
    -- check handling of custom exits here
    local tmp
    for i = 13,#stub_map do
        tmp = tonumber(getRoomUserData(room_id,"stub "..stub_map[i]))
        if tmp then table.insert(stubs,tmp) end
    end

    local exits = {}
    for k,v in pairs(stubs) do
        exits[stub_map[v]] = 0
    end
    return exits
end

local function connect_rooms(ID1, ID2, dir1)
    -- makes a connection between rooms
    local dir2 = reverse_dirs[dir1]
    -- check handling of custom exits here
    if stub_map[dir1] <= 12 then
        setExit(ID1,ID2,stub_map[dir1])
    else
        addSpecialExit(ID1, ID2, dir1)
        setRoomUserData(ID1,"exit " .. dir1,ID2)
        -- check handling of custom exits here
        setRoomUserData(ID1,"stub "..dir1, stub_map[dir1])
    end
    local doors1, doors2 = getDoors(ID1), getDoors(ID2)
    local dstatus1, dstatus2 = doors1[short[dir1]] or doors1[dir1], doors2[short[dir2]] or doors2[dir2]
    if dstatus1 ~= dstatus2 then
        if not dstatus1 then
            add_door(ID1,dir1,dstatus2)
        elseif not dstatus2 then
            add_door(ID2,dir2,dstatus1)
        end
    end
    if map.mode ~= "complex" then
        local stubs = get_room_stubs(ID2)
        if (stubs[dir2]) then
            -- check handling of custom exits here
            if stub_map[dir2] <= 12 then
                setExit(ID2,ID1,stub_map[dir2])
            else
                addSpecialExit(ID2, ID1, dir2)
                setRoomUserData(ID2,"exit " .. dir2,ID1)
                -- check handling of custom exits here
                setRoomUserData(ID2,"stub " .. dir2, stub_map[dir2])
            end
        end
    end
end

local function reconnect_rooms(base_room_id, disconnected_room_id)
    map.echo("Reconnecting rooms...")
    local base_area_id = getRoomArea(base_room_id)
    local disconnected_area_id = getRoomArea(disconnected_room_id)
    local rooms_to_process = getAreaRooms(disconnected_area_id)
    local room_exits = {}

    for _, id in pairs(rooms_to_process) do
        room_exits[id] = getRoomExits(id)
    end
    room_exits[base_room_id] = getRoomExits(base_room_id)

    -- Make sure the directions go both ways
    for id, exits in pairs(room_exits) do
        for dir, dest in pairs(exits) do
            if room_exits[dest] then
                room_exits[dest][reverse_dirs[dir]] = id
            end
        end
    end

    local to_reconnect = {base_room_id}
    local cur_id
    local x, y, z, dx, dy, dz

    -- Walk the rooms connected to baseRoomID and change their area.
    while not table.is_empty(to_reconnect) do
        cur_id = table.remove(to_reconnect)
        setRoomArea(cur_id, base_area_id)
        x, y, z = getRoomCoordinates(cur_id)
        -- Reconnect all its exits
        for dir, dest in pairs(room_exits[cur_id]) do
            if getRoomArea(dest) == disconnected_area_id then
                table.insert(to_reconnect, dest)
                dx, dy, dz = unpack(coord_map[stub_map[dir]])
                setRoomCoordinates(dest, x+dx, y+dy, z+dz)
            end
        end
        room_exits[cur_id] = nil
    end
    if table.is_empty(getAreaRooms(disconnected_area_id)) then
        deleteArea(disconnected_area_id)
    end
end

local function stretch_map(dir,x,y,z)
    -- stretches a map to make room for just added room that would overlap with existing room
    local dx, dy, dz
    if not dir then return end
    for k, v in pairs(getAreaRooms(map.current_room_area_id)) do
        if v ~= map.current_room_id then
            dx, dy, dz = getRoomCoordinates(v)
            if dx >= x and string.find(dir,"east") then
                dx = dx + 1
            elseif dx <= x and string.find(dir,"west") then
                dx = dx - 1
            end
            if dy >= y and string.find(dir,"north") then
                dy = dy + 1
            elseif dy <= y and string.find(dir,"south") then
                dy = dy - 1
            end
            if dz >= z and string.find(dir,"up") then
                dz = dz + 1
            elseif dz <= z and string.find(dir,"down") then
                dz = dz - 1
            end
            setRoomCoordinates(v, dx, dy, dz)
        end
    end
end

local function create_room(dir, coords)
    -- makes a new room with captured name and exits
    -- links with other rooms as appropriate
    if map.mapping then
        map.echo("New Room: " .. map.current_room_name,false,false,dir and true or false)

        addRoom(map.current_room_id)
        setRoomArea(map.current_room_id, map.current_room_area_id)
        setRoomName(map.current_room_id, map.current_room_name)
        setRoomCoordinates(map.current_room_id, unpack(coords))

        for k, _ in pairs(map.current_room_exits) do
            if stub_map[k] then
                if stub_map[k] <= 12 then
                    setExitStub(map.current_room_id, stub_map[k], true)
                else
                    -- add special char to prompt special exit
                    if string.find(k, "up") or string.find(k, "down") then
                        setRoomChar(map.current_room_id, "◎")
                    end
                    -- check handling of custom exits here
                    setRoomUserData(map.current_room_id, "stub "..k,stub_map[k])
                end
            end
        end

        local pos_rooms = getRoomsByPosition(map.current_room_area_id, unpack(coords))
        if map.configs.stretch_map and table.size(pos_rooms) > 1 then
            stretch_map(dir,unpack(coords))
        end
    end
end

local function find_area_id(name)
    -- searches for the named area, and creates it if necessary
    local areas = getAreaTable()
    local area_id
    for k,v in pairs(areas) do
        if string.lower(name) == string.lower(k) then
            area_id = v
            break
        end
    end
    if not area_id then area_id = addAreaName(name) end
    if not area_id then
        show_err("Invalid Area. No such area found, and area could not be added.",true)
    end
    return area_id
end

---------------
-- Speedwalking
---------------

function map.find_path(roomName,area_name)
    area_name = (area_name ~= "" and area_name) or nil
    local rooms = find_room(roomName,area_name)
    local found,dirs = false,{}

    for k, _ in pairs(rooms) do
        found = getPath(map.current_room_id,k)
        if found and (#dirs == 0 or #dirs > #speedWalkDir) then
            dirs = speedWalkDir
        end
    end
    if #dirs > 0 then
        map.echo("Path to " .. roomName .. ((area_name and " in " .. area_name) or "") .. ": " .. table.concat(dirs,", "))
    else
        map.echo("No path found to " .. roomName .. ((area_name and " in " .. area_name) or "") .. ".",false,true)
    end
end

local continue_walk, timerID
continue_walk = function(new_room)
    if not walking then return end
    -- calculate wait time until next command, with randomness
    local wait = map.configs.speedwalk_delay or 0
    if wait > 0 and map.configs.speedwalk_random then
        wait = wait * (1 + math.random(0,100)/100)
    end
    -- if no wait after new room, move immediately
    if new_room and map.configs.speedwalk_wait and wait == 0 then
        new_room = false
    end
    -- send command if we don't need to wait
    if not new_room then
        send(table.remove(map.walk_dirs,1))
        -- check to see if we are done
        if #map.walk_dirs == 0 then
            walking = false
            speedWalkPath, speedWalkWeight = {}, {}
            raiseEvent("sysSpeedwalkFinished")
        end
    end
    -- make tempTimer to send next command if necessary
    if walking and (not map.configs.speedwalk_wait or (map.configs.speedwalk_wait and wait > 0)) then
        if timerID then killTimer(timerID) end
        timerID = tempTimer(wait, function() continue_walk() end)
    end
end

function map.speed_walk(room_id, walk_path, walk_dirs)
    room_id = room_id or speedWalkPath[#speedWalkPath]
    getPath(map.current_room_id, room_id)
    walk_path = speedWalkPath
    walk_dirs = speedWalkDir
    if #speedWalkPath == 0 then
        map.echo("No path to chosen room found.", false, true)
        return
    end
    table.insert(walk_path, 1, map.current_room_id)
    -- go through dirs to find doors that need opened, etc
    -- add in necessary extra commands to walkDirs table
    local k = 1
    repeat
        local id, dir = walk_path[k], walk_dirs[k]
        if exit_map[dir] or short[dir] then
            local door = check_doors(id, exit_map[dir] or dir)
            local status = door and door[dir]
            if status and status > 1 then
                -- if locked, unlock door
                if status == 3 then
                    table.insert(walk_path, k, id)
                    table.insert(walk_dirs, k, "unlock " .. (exit_map[dir] or dir))
                    k = k + 1
                end
                -- if closed, open door
                table.insert(walk_path, k, id)
                table.insert(walk_dirs, k, "open " .. (exit_map[dir] or dir))
                k = k + 1
            end
        end
        k = k + 1
    until k > #walk_dirs
    if map.configs.use_translation then
        for k, v in ipairs(walk_dirs) do
            walk_dirs[k] = map.configs.lang_dirs[v] or v
        end
    end
    -- perform walk
    walking = true
    if map.configs.speedwalk_wait or map.configs.speedwalk_delay > 0 then
        map.walk_dirs = walk_dirs
        continue_walk()
    else
        for _,dir in ipairs(walk_dirs) do
            send(dir)
        end
        walking = false
        raiseEvent("sysSpeedwalkFinished")
    end
end

function doSpeedWalk()
    if #speedWalkPath ~= 0 then
        raiseEvent("sysSpeedwalkStarted")
        map.speed_walk(nil, speedWalkPath, speedWalkDir)
    else
        map.echo("No path to chosen room found.",false,true)
    end
end

function map.pause_speed_walk()
    if #speedWalkDir ~= 0 then
        walking = false
        raiseEvent("sysSpeedwalkPaused")
        map.echo("Speedwalking paused.")
    else
        map.echo("Not currently speedwalking.")
    end
end

function map.resume_speed_walk(delay)
    if #speedWalkDir ~= 0 then
        centerview(map.current_room_id)
        raiseEvent("sysSpeedwalkResumed")
        map.echo("Speedwalking resumed.")
        tempTimer(delay or 0, function() map.speed_walk(nil, speedWalkPath, speedWalkDir) end)
    else
        map.echo("Not currently speedwalking.")
    end
end

function map.stop_speed_walk()
    if #speedWalkDir ~= 0 then
        walking = false
        map.walk_dirs, speedWalkDir, speedWalkPath, speedWalkWeight = {}, {}, {}, {}
        raiseEvent("sysSpeedwalkStopped")
        map.echo("Speedwalking stopped.")
    else
        map.echo("Not currently speedwalking.")
    end
end

function map.toggle_speed_walk(what)
    assert(what == nil or what == "on" or what == "off", "map.toggleSpeedwalk wants 'on', 'off' or nothing as an argument")

    if what == "on" or (what == nil and walking) then
        map.pause_speed_walk()
    elseif what == "off" or (what == nil and not walking) then
        map.resume_speed_walk()
    end
end

-------------
-- Versioning
-------------
--[[
local function check_version()
    downloading = false
    local path = profilePath .. "/map downloads/versions.lua"
    local versions = {}
    table.load(path, versions)
    local pos = table.index_of(versions, map.version) or 0
    if pos ~= #versions then
        enableAlias("Map Update Alias")
        map.echo(string.format("The Generic Mapping Script is currently <red>%d<reset> versions behind.",#versions - pos))
        map.echo("To update now, please type: <yellow>map update<reset>")
    end
    map.update_timer = tempTimer(3600, [ [map.checkVersion()] ])
end

function map.checkVersion()
    if map.update_timer then
        killTimer(map.update_timer)
        map.update_timer = nil
    end
    if not map.update_waiting and map.configs.download_path ~= "" then
        local path, file = profilePath .. "/map downloads", "/versions.lua"
        downloading = true
        downloadFile(path .. file, map.configs.download_path .. file)
        map.update_waiting = true
    end
end

local function update_version()
    downloading = false
    local path = profilePath .. "/map downloads/generic_mapper.xml"
    disableAlias("Map Update Alias")
    map.updatingMapper = true
    uninstallPackage("generic_mapper")
    installPackage(path)
    map.updatingMapper = nil
    map.echo("Generic Mapping Script updated successfully.")
end

function map.updateVersion()
    local path, file = profilePath .. "/map downloads", "/generic_mapper.xml"
    downloading = true
    downloadFile(path .. file, map.configs.download_path .. file)
end
--]]


---------------
-- Map Commands
---------------

function map.set_exit(dir,room_id)
    -- used to set unusual exits from the room you are standing in
    if map.mapping then
        room_id = tonumber(room_id)
        if not room_id then
            show_err("Set Exit: Invalid Room ID")
        end
        if not table.contains(exit_map, dir) and not string.starts(dir, "-p ") then
            show_err("Set Exit: Invalid Direction")
        end

        if not string.starts(dir, "-p ") then
            local exit
            if stub_map[exit_map[dir] or dir] <= 12 then
                exit = short[exit_map[dir] or dir]
                setExit(map.current_room_id, room_id, exit)
            else
                -- check handling of custom exits here
                exit = exit_map[dir] or dir
                exit = "exit " .. exit
                setRoomUserData(map.current_room_id, exit, room_id)
            end
            map.echo("Exit " .. dir .. " now goes to roomID " .. room_id)
        else
            dir = string.gsub(dir, "^-p ", "")
            addSpecialExit(map.current_room_id, room_id, dir)
            map.echo("Special exit '" .. dir .. "' now goes to roomID " .. room_id)
        end
    else
        map.echo("Not mapping",false,true)
    end
end

function map.set_portal(command)
    -- creates a new portal going from the last room to the current one
    if map.mapping then
        map.echo("Adding portal destination, linking rooms")
        addSpecialExit(map.prev_room_id, map.current_room_id, command)
        local portals = getRoomUserData(map.current_room_id, "portals") or ""
        portals = portals .. "," .. tostring(map.prev_room_id)..":"..command
        setRoomUserData(map.current_room_id,"portals",portals)
        centerview(map.current_room_id)
    else
        map.echo("Not mapping",false,true)
    end
end

function map.fix_portals()
    -- used to clear and update data for portal back-referencing
    local rooms = getRooms()
    local portals
    for k, _ in pairs(rooms) do
        setRoomUserData(k, "portals", "")
    end
    for k, _ in pairs(rooms) do
        for cmd, room in pairs(getSpecialExitsSwap(k)) do
            portals = getRoomUserData(room, "portals") or ""
            if portals ~= "" then portals = portals .. "," end
            portals = portals .. tostring(k) .. ":" .. cmd
            setRoomUserData(room, "portals", portals)
        end
    end
    map.echo("Portals Fixed")
end

function map.set_mode(mode)
    -- switches mapping modes
    if not table.contains({"normal","complex"},mode) then
        show_err("Invalid Map Mode, must be 'normal' or 'complex'.")
    end
    map.set("mode", mode)
    map.echo("Current mode set to: " .. mode)
end

function map.start_mapping()
    -- starts mapping, and sets the current area to the given one, or uses the current one
    if not map.current_room_id then
        show_err("Room detection not yet working, try looking or moving.")
        return
    end

    map.set("mapping", true)
    if not roomExists(map.current_room_id) then
        local gmcp_area = string.trim(gmcp.room.info.area)
        local area_id = find_area_id(gmcp_area)
        if table.is_empty(getAreaRooms(area_id)) then
            -- New area
            map.set("current_room_area_id", area_id)
        else
            -- Area already exists, start in a sub-area
            local sub_area_name = f"{gmcp_area}/{map.current_room_name}({map.current_room_id})"
            map.set("current_room_area_id", find_area_id(sub_area_name))
            map.set("disconnected_area", true)
        end
        create_room(nil, {0,0,0})
    else
        map.set("current_room_area_id", getRoomArea(map.current_room_id))
        map.set("disconnected_area", getRoomAreaName(map.current_room_area_id) ~= gmcp.room.info.area)
    end
    centerview(map.current_room_id)
end

function map.stop_mapping()
    map.set("mapping", false)
    map.echo("Mapping off.")
end

function map.set_area(name)
    -- assigns the current room to the area given, creates the area if necessary
    if map.mapping then
        local area_id = find_area_id(name)
        if map.current_room_id and getRoomArea(map.current_room_id) ~= area_id then
            setRoomArea(map.current_room_id, area_id)
            map.set("current_room_area_id", area_id)
            map.echo(f"Moved {map.current_room_name} to {get_room_area_name(map.current_room_area_id)}")
            centerview(map.current_room_id)
        end
    else
        map.echo("Not mapping",false,true)
    end
end

function map.set_door(dir, status, one_way)
    -- adds a door on a given exit
    if map.mapping then
        if not map.current_room_id then
            show_err("Make Door: No room found.")
        end
        dir = exit_map[dir] or dir
        if not stub_map[dir] then
            show_err("Make Door: Invalid direction.")
        end
        status = (status ~= "" and status) or "closed"
        one_way = (one_way ~= "" and one_way) or "no"
        if not table.contains({"yes","no"}, one_way) then
            show_err("Make Door: Invalid one-way status, must be yes or no.")
        end

        local exits = getRoomExits(map.current_room_id)
        local exit
        -- check handling of custom exits here
        for i = 13,#stub_map do
            exit = "exit " .. stub_map[i]
            exits[stub_map[i]] = tonumber(getRoomUserData(map.current_room_id, exit))
        end
        local target_room = exits[dir]
        if target_room then
            exits = getRoomExits(target_room)
            -- check handling of custom exits here
            for i = 13,#stub_map do
                exit = "exit " .. stub_map[i]
                exits[stub_map[i]] = tonumber(getRoomUserData(target_room, exit))
            end
        end
        if one_way == "no" and (target_room and exits[reverse_dirs[dir]] == map.current_room_id) then
            add_door(target_room,reverse_dirs[dir],status)
        end
        add_door(map.current_room_id, dir, status)
        map.echo(string.format("Adding %s door to the %s", status, dir))
    else
        map.echo("Not mapping", false, true)
    end
end

function map.shift_room(dir)
    -- shifts a room around on the map
    if map.mapping then
        dir = exit_map[dir] or (table.contains(exit_map,dir) and dir)
        if not dir then
            show_err("Shift Room: Exit not found")
        end
        local x, y, z = getRoomCoordinates(map.current_room_id)
        dir = stub_map[dir]
        local coords = coord_map[dir]
        x = x + coords[1]
        y = y + coords[2]
        z = z + coords[3]
        setRoomCoordinates(map.current_room_id, x, y, z)
        centerview(map.current_room_id)
        map.echo("Shifting room", true)
    else
        map.echo("Not mapping", false, true)
    end
end

function map.merge_rooms()
    -- used to combine essentially identical rooms with the same coordinates
    -- typically, these are generated due to mapping errors
    if map.mapping then
        map.echo("Merging rooms")
        local x, y, z = getRoomCoordinates(map.current_room_id)
        local rooms = getRoomsByPosition(map.current_room_area_id, x, y, z)
        local exits, portals, room, cmd, cur_portals
        local room_count = 1
        for k,v in pairs(rooms) do
            if v ~= map.current_room_id then
                if getRoomName(v) == getRoomName(map.current_room_id) then
                    room_count = room_count + 1
                    for k1,v1 in pairs(getRoomExits(v)) do
                        setExit(map.current_room_id, v1, stub_map[k1])
                        exits = getRoomExits(v1)
                        if exits[reverse_dirs[k1]] == v then
                            setExit(v1, map.current_room_id, stub_map[reverse_dirs[k1]])
                        end
                    end
                    for k1, v1 in pairs(getDoors(v)) do
                        setDoor(map.current_room_id, k1, v1)
                    end
                    for k1, v1 in pairs(getSpecialExitsSwap(v)) do
                        addSpecialExit(map.current_room_id, v1, k1)
                    end
                    portals = getRoomUserData(v, "portals") or ""
                    if portals ~= "" then
                        portals = string.split(portals, ",")
                        for _,v1 in ipairs(portals) do
                            room,cmd = unpack(string.split(v1,":"))
                            addSpecialExit(tonumber(room), map.current_room_id, cmd)
                            cur_portals = getRoomUserData(map.current_room_id, "portals") or ""
                            if not string.find(cur_portals, room) then
                                cur_portals = cur_portals .. "," .. room .. ":" .. cmd
                                setRoomUserData(map.current_room_id, "portals", cur_portals)
                            end
                        end
                    end
                    -- check handling of custom exits here for doors and exits, and reverse exits
                    for i = 13,#stub_map do
                        local door = "door " .. stub_map[i]
                        local tmp = tonumber(getRoomUserData(v, door))
                        if tmp then
                            setRoomUserData(map.current_room_id, door, tmp)
                        end
                        local exit = "exit " .. stub_map[i]
                        tmp = tonumber(getRoomUserData(v, exit))
                        if tmp then
                            setRoomUserData(map.current_room_id, exit, tmp)
                            if tonumber(getRoomUserData(tmp, "exit " .. reverse_dirs[stub_map[i]])) == v then
                                setRoomUserData(tmp, exit, map.current_room_id)
                            end
                        end
                    end
                    deleteRoom(v)
                end
            end
        end
        if room_count > 1 then
            map.echo(room_count .. " rooms merged", true)
        end
    else
        map.echo("Not mapping", false, true)
    end
end

function map.show_map(shown)
    local configs = map.configs.map_window
    shown = shown or not configs.shown
    map.configs.map_window.shown = shown
    local x, y, w, h, origin = configs.x, configs.y, configs.w, configs.h, configs.origin
    if string.find(origin, "bottom") then
        if y == 0 or y == "0%" then
            y = h
        end
        if type(y) == "number" then
            y = -y
        else
            y = "-"..y
        end
    end
    if string.find(origin, "right") then
        if x == 0 or x == "0%" then
            x = w
        end
        if type(x) == "number" then
            x = -x
        else
            x = "-"..x
        end
    end
    local mapper = Geyser.Mapper:new({name = "my_mapper", x = x, y = y, w = w, h = h})
    mapper:resize(w, h)
    mapper:move(x, y)
    if shown then
        mapper:show()
    else
        mapper:hide()
    end
end

function map.export_area(name)
    -- used to export a single area to a file
    local areas = getAreaTable()
    name = string.lower(name)
    for k, _ in pairs(areas) do
        if name == string.lower(k) then name = k end
    end
    if not areas[name] then
        show_err("No such area.")
    end
    local rooms = getAreaRooms(areas[name])
    local tmp = {}
    for _, v in pairs(rooms) do
        tmp[v] = v
    end
    rooms = tmp
    local tbl = {}
    tbl.name = name
    tbl.rooms = {}
    tbl.exits = {}
    tbl.special = {}
    local rname, exits, stubs, doors, special, portals, door_up, door_down
    local door_in, door_out, coords, id
    for _, v in pairs(rooms) do
        rname = getRoomName(v)
        exits = getRoomExits(v)
        stubs = getExitStubs(v)
        doors = getDoors(v)
        special = getSpecialExitsSwap(v)
        portals = getRoomUserData(v, "portals") or ""
        coords = {getRoomCoordinates(v)}
        tbl.rooms[v] = {id = v, name = rname, coords = coords, exits = exits, stubs = stubs, doors = doors, door_up = door_up,
            door_down = door_down, door_in = door_in, door_out = door_out, special = special, portals = portals}
        tmp = {}
        for k1, v1 in pairs(exits) do
            if not table.contains(rooms, v1) then
                tmp[k1] = {v1, getRoomName(v1)}
            end
        end
        if not table.is_empty(tmp) then
            tbl.exits[v] = tmp
        end
        tmp = {}
        for k1, v1 in pairs(special) do
            if not table.contains(rooms, v1) then
                tmp[k1] = {v1, getRoomName(v1)}
            end
        end
        if not table.is_empty(tmp) then
            tbl.special[v] = tmp
        end
    end
    local path = profile_path .. "/" .. string.gsub(string.lower(name), "%s", "_") .. ".dat"
    table.save(path, tbl)
    map.echo("Area " .. name .. " exported to " .. path)
end

function map.import_area(name)
    local file_name = profile_path .. "/" .. string.gsub(string.lower(name), "%s", "_") .. ".dat"
    local tbl = {}
    table.load(file_name,tbl)
    if table.is_empty(tbl) then
        show_err("No file found")
    end
    local areas = getAreaTable()
    local area_id = areas[tbl.name] or addAreaName(tbl.name)
    local rooms = {}
    local id
    for k, v in pairs(tbl.rooms) do
        id = v.id
        rooms[k] = id
        addRoom(id)
        setRoomName(id, v.name)
        setRoomArea(id, area_id)
        setRoomCoordinates(id, unpack(v.coords))
        if type(v.stubs) == "table" then
            for _, j in pairs(v.stubs) do
                setExitStub(id, j, true)
            end
        end
        for i,j in pairs(v.doors) do
            setDoor(id,i,j)
        end
        setRoomUserData(id,"portals",v.portals)
    end
    for k,v in pairs(tbl.rooms) do
        for i,j in pairs(v.exits) do
            if rooms[j] then
                connect_rooms(rooms[k], rooms[j], i)
            end
        end
        for i,j in pairs(v.special) do
            if rooms[j] then
                addSpecialExit(rooms[k], rooms[j], i)
            end
        end
    end
    for k,v in pairs(tbl.exits) do
        for i,j in pairs(v) do
            if getRoomName(j[1]) == j[2] then
                connect_rooms(rooms[k], j[1], i)
            end
        end
    end
    for k,v in pairs(tbl.special) do
        for i,j in pairs(v) do
            addSpecialExit(k, j[1], i)
        end
    end
    map.fix_portals()
    map.echo("Area " .. tbl.name .. " imported from " .. name)
end

-----------------
-- Mapping Events
-----------------

map.registered_events = {
    registerAnonymousEventHandler("gmcp.room.info", "map.eventHandler"),
    --registerAnonymousEventHandler("sysDataSendRequest", "map.eventHandler"),
    registerAnonymousEventHandler("sysDownloadDone", "map.eventHandler"),
    --registerAnonymousEventHandler("sysDownloadError", "map.eventHandler"),
    registerAnonymousEventHandler("sysLoadEvent", "map.eventHandler"),
    registerAnonymousEventHandler("sysInstall", "map.eventHandler"),
    registerAnonymousEventHandler("mapStop", "map.eventHandler"),
    registerAnonymousEventHandler("sysManualLocationSetEvent", "map.eventHandler"),
    registerAnonymousEventHandler("sysUninstallPackage", "map.eventHandler")
    }

function map.eventHandler(event, ...)
    if event == "gmcp.room.info" then
        if map.configs.debug then
            echo("GMCP ")
            display(gmcp.room.info)
        end

        local room_id = tonumber(gmcp.room.info.num)
        if room_id == map.current_room_id and #map.current_room_exits == #gmcp.room.info.exits then
            map.echo("Room hasn't changed.", true)
            return
        end
        local room_exists = roomExists(room_id)

        -- save current info as previous' room info
        map.set("prev_room_id", map.current_room_id)
        map.set("prev_room_name", map.current_room_name)
        map.set("prev_room_exits", map.current_room_exits)
        map.set("prev_room_area_id", map.current_room_area_id)

        -- populate current room's info
        map.set("current_room_id", room_id)

        local parsed_exits = {}
        for k, v in pairs(gmcp.room.info.exits) do
            k = exit_map[k] or k  -- The script assumes that directions are longform
            parsed_exits[k] = tonumber(v)
        end
        table.update(parsed_exits, getRoomExits(map.current_room_id) or {})  -- Adds already mapped exits.
        map.set("current_room_exits", parsed_exits)

        if room_exists then
            map.set("current_room_name", getRoomName(map.current_room_id))
            -- check handling of custom exits here
            for i = 13,#stub_map do
                map.current_room_exits[stub_map[i]] = tonumber(getRoomUserData(map.current_room_id,"exit " .. stub_map[i]))
            end
        else
            map.set("current_room_name", string.trim(gmcp.room.info.name))
        end

        if map.mapping then
            -- find the connection direction
            local dir, unconnected_dir
            if map.prev_room_id then 
                for k, v in pairs(map.prev_room_exits) do
                    if v == map.current_room_id then
                        if stub_map[k] <= 10  then -- avoid 'in' and 'out' that don't have a direction.
                            dir = k
                            break
                        else
                            unconnected_dir = k
                        end
                    end
                end
            end
                
            if not room_exists then
                -- Need to create room
                local gmcp_area = string.trim(gmcp.room.info.area)
                local prev_area_name = map.prev_room_area_id and getRoomAreaName(map.prev_room_area_id) or ""

                if dir then
                    -- Can share the same [sub]area as the previous room
                    if string.starts(prev_area_name, gmcp_area) then
                        -- Have not changed base area
                        map.set("current_room_area_id", map.prev_room_area_id)
                    else
                        map.set("current_room_area_id", find_area_id(gmcp_area))
                    end
                    local x,y,z = getRoomCoordinates(map.prev_room_id)
                    local dx,dy,dz = unpack(coord_map[stub_map[dir]])
                    map.echo("Creating room " .. map.current_room_name.. "[".. tostring(map.current_room_id).. "] from "..dir.." "..
                            tostring(map.prev_room_id) .. " in area " .. getRoomAreaName(map.current_room_area_id), true)
                    create_room(dir, {x+dx,y+dy,z+dz})
                else
                    -- Can't share same area
                    local udir = unconnected_dir and f"[{unconnected_dir}]" or ""
                    if string.starts(prev_area_name, gmcp_area) then
                        -- Have not changed base area
                        map.set("disconnected_area", true)
                        local subAreaName = f"{prev_area_name}/{map.prev_room_name}({map.prev_room_id}){udir}"
                        map.set("current_room_area_id", find_area_id(subAreaName))
                        display("Creating room " .. map.current_room_name.. "[".. tostring(map.current_room_id).. "] in the sub-area ".. subAreaName)
                    else
                        -- Need to change area anyway
                        local area_id = find_area_id(gmcp_area)
                        if table.is_empty(getAreaRooms(area_id)) then
                            map.set("current_room_area_id", area_id)
                        else
                            -- Need to create a subarea of the other area
                            map.set("disconnected_area", true)
                            local subAreaName = f"{gmcp_area}/{map.prev_room_name or map.current_room_name}({map.prev_room_id or map.current_room_id}){udir}"
                            map.set("current_room_area_id", find_area_id(subAreaName))
                            display("Creating room " .. map.current_room_name.. "[".. tostring(map.current_room_id).. "] in the sub-area ".. subAreaName)
                        end
                    end
                    if not unconnected_dir then
                        -- Notify the player of the break and offer to make a portal
                        map.echo(
                            "This room doesn't connect to the precedent through a cardinal " ..
                            "exit or a recognized special direction. To enable speedwalking " ..
                            "through that exit, please `add portal <entry command>`. " ..
                            "This will link the previous room to this one using the command.")
                    end
                    create_room(nil, {0,0,0})
                end
            else
                map.set("current_room_area_id", getRoomArea(map.current_room_id))
                local areaName = getRoomAreaName(map.current_room_area_id)
                if areaName == gmcp.room.info.area then
                    if map.disconnected_area and dir then
                        -- Enters a base area from a disconnected area. Reconnect
                        display("Reconnecting area...")
                        reconnect_rooms(map.current_room_id, map.prev_room_id)
                    end
                    map.set("disconnected_area", false)
                else
                    if not map.disconnected_area and dir then
                        -- Enters a disconnected area from a base area. Reconnect
                        reconnect_rooms(map.prev_room_id, map.current_room_id)
                        map.set("disconnected_area", false)
                    else
                        -- If one enters the disconnected area from a non-card dir.
                        map.set("disconnected_area", true)
                    end
                end
            end

            if dir or unconnected_dir then
                connect_rooms(map.prev_room_id, map.current_room_id, dir or unconnected_dir)
            end

            -- link rooms without needing to use every exits
            for dir, dest in pairs(map.current_room_exits) do
                if roomExists(dest) then
                    connect_rooms(map.current_room_id, dest, dir)
                end
            end
        end
        centerview(map.current_room_id)
        if walking and map.configs.speedwalk_wait then
            continue_walk(true)
        end
        print_wait_echoes()
    --[[
    elseif event == "sysDataSendRequest" then
        -- check to prevent multiple version checks in a row without user intervention
        if map.update_waiting and map.update_timer then
            map.update_waiting = nil
        -- check to ensure version check cycle is started
        elseif not map.update_waiting and not map.update_timer then
            map.checkVersion()
        end
    --]]
    elseif event == "sysDownloadDone" and downloading then
        local file = arg[1]
        if string.ends(file,"/map.dat") then
            loadMap(file)
            downloading = false
            map.echo("Map File Loaded.")
        --[[
        elseif string.ends(file,"/versions.lua") then
            check_version()
        elseif string.ends(file,"/generic_mapper.xml") then
            update_version()
        --]]
        end
    --[[
    elseif event == "sysDownloadError" and downloading then
        local file = arg[1]
        if string.ends(file,"/versions.lua") and mudlet.translations.interfacelanguage == "zh_CN" then
            -- update to the current download path for chinese user
            if map.configs.download_path == "https://raw.githubusercontent.com/Mudlet/Mudlet/development/src/mudlet-lua/lua/generic-mapper" then
                map.configs.download_path = "https://gitee.com/mudlet/Mudlet/raw/development/src/mudlet-lua/lua/generic-mapper"
                map.checkVersion()
            end
        end
    --]]
    elseif event == "sysLoadEvent" or event == "sysInstall" then
        config()
    elseif event == "mapStop" then
        map.set("mapping", false)
        walking = false
        map.echo("Mapping and speedwalking stopped.")
    elseif event == "sysManualLocationSetEvent" then
        -- TODO: Add the loading of old info before centerview (prevRoom)
        centerview(arg[1])
    elseif event == "sysUninstallPackage" and not map.updating_mapper and arg[1] == "gmcp_generic_mapper" then
        for _,id in ipairs(map.registered_events) do
            killAnonymousEventHandler(id)
        end
    end
end

-- TODO: Remove this, for debug only
send('look')
map.eventHandler("sysInstall")