-- Jor'Mox's Generic Map Script
-- the script self-updates, changing this value will bring an update to all installations
-- make sure versions.lua has the latest version in it
local version = "2.0.24"

    -- look into options for non-standard door usage for speedwalk
    -- come up with aliases to set translations and custom exits, add appropriate help info

mudlet = mudlet or {}
mudlet.mapper_script = true
map = map or {}


map.character = map.character or ""
map.prompt = map.prompt or {}
map.save = map.save or {}
map.save.recall = map.save.recall or {}
map.save.prompt_pattern = map.save.prompt_pattern or {}
map.save.ignore_patterns = map.save.ignore_patterns or {}

local oldstring = string
local string = utf8
string.format = oldstring.format
string.trim = oldstring.trim
string.starts = oldstring.starts
string.split = oldstring.split
string.ends = oldstring.ends


local profilePath = getMudletHomeDir()
profilePath = profilePath:gsub("\\","/")

local move_queue, lines = {}, {}
local find_portal, vision_fail, room_detected, random_move, force_portal, find_prompt, downloading, walking, help_shown
local mt = getmetatable(map) or {}

local exitmap = {
    n = 'north',    ne = 'northeast',   nw = 'northwest',   e = 'east',
    w = 'west',     s = 'south',        se = 'southeast',   sw = 'southwest',
    u = 'up',       d = 'down',         ["in"] = 'in',      out = 'out',
    l = 'look',
    ed = 'eastdown',    eu = 'eastup',  nd = 'northdown',   nu = 'northup',
    sd = 'southdown',   su = 'southup', wd = 'westdown',    wu = 'westup',
}

local short = {}
for k,v in pairs(exitmap) do
    short[v] = k
end

local stubmap = {
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

local coordmap = {
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

-----------------
-- Mapping Events
-----------------

map.registeredEvents = {
    registerAnonymousEventHandler("gmcp.room.info", "map.eventHandler"),
    registerAnonymousEventHandler("sysDownloadDone", "map.eventHandler"),
    registerAnonymousEventHandler("sysDownloadError", "map.eventHandler"),
    registerAnonymousEventHandler("sysLoadEvent", "map.eventHandler"),
    registerAnonymousEventHandler("sysConnectionEvent", "map.eventHandler"),
    registerAnonymousEventHandler("sysInstall", "map.eventHandler"),
    registerAnonymousEventHandler("sysDataSendRequest", "map.eventHandler"),
    registerAnonymousEventHandler("onMoveFail", "map.eventHandler"),
    registerAnonymousEventHandler("onVisionFail", "map.eventHandler"),
    registerAnonymousEventHandler("onRandomMove", "map.eventHandler"),
    registerAnonymousEventHandler("onForcedMove", "map.eventHandler"),
    registerAnonymousEventHandler("onNewRoom", "map.eventHandler"),
    registerAnonymousEventHandler("onNewLine", "map.eventHandler"),
    registerAnonymousEventHandler("mapOpenEvent", "map.eventHandler"),
    registerAnonymousEventHandler("mapStop", "map.eventHandler"),
    registerAnonymousEventHandler("onPrompt", "map.eventHandler"),
    registerAnonymousEventHandler("sysManualLocationSetEvent", "map.eventHandler"),
    registerAnonymousEventHandler("sysUninstallPackage", "map.eventHandler")
    }

function map.eventHandler(event, ...)
    if event == "gmcp.room.info" then
        local roomID = tonumber(gmcp.room.info.num)
        if roomID == map.currentRoomID and #map.currentExits == #gmcp.room.info.exits then
            map.echo("Room hasn't changed.", true)
            return
        end
        map.set("prevRoomID", map.currentRoomID)
        map.set("currentRoomID", roomID)

        map.set("prevRoomName", map.currentRoomName)
        map.set("prevRoomArea", map.currentRoomArea)
        map.set("prevRoomExits", map.currentRoomExits)

        -- find the connection direction
        local dir
        for k, v in map.prevRoomExits do
            if v == map.currentRoomID then
                dir = k 
                break 
            end 
        end

        if roomExists(map.currentRoomID) then
            map.set("currentRoomName", getRoomName(map.currentRoomID)))
            map.set("currentRoomArea", getRoomArea(map.currentRoomID))
            map.set("currentRoomExits", getRoomExits(map.currentRoomID))
            -- check handling of custom exits here
            for i = 13,#stubmap do
                map.currentRoomExits[stubmap[i]] = tonumber(getRoomUserData(map.currentRoomID,"exit " .. stubmap[i]))
            end

        else
            map.set("currentRoomName", string.trim(gmcp.room.info.name))
            map.set("currentRoomArea", string.trim(gmcp.room.info.area))

            local parsed_exits = {}
            for k, v in gmcp.room.info.exits do
                k = exitmap[k] or k  -- The script assumes that directions are longform
                parsed_exits[k] = tonumber(v)
            end
            map.set("currentRoomExits", parsed_exits)

            local x,y,z = getRoomCoordinates(map.prevRoomID)
            local dx,dy,dz = unpack(coordmap[stubmap[dir]])
            create_room(dir, {x+dx,y+dy,z+dz})
        end

        connect_rooms(map.prevRoomID, map.currentRoomID, dir)
        centerview(map.currentRoomID)

    elseif event == "onNewRoom" then
        if walking and map.configs.speedwalk_wait then
            continue_walk(true)
        end
    elseif event == "onForcedMove" then
        map.echo("onForcedMove",true)
        capture_move_cmd(arg[1],arg[2]=="true")
    elseif event == "onNewLine" then
        grab_line()
    elseif event == "sysDataSendRequest" then
        capture_move_cmd(arg[1])
        -- check to prevent multiple version checks in a row without user intervention
        if map.update_waiting and map.update_timer then
            map.update_waiting = nil
        -- check to ensure version check cycle is started
        elseif not map.update_waiting and not map.update_timer then
            map.checkVersion()
        end
    elseif event == "sysDownloadDone" and downloading then
        local file = arg[1]
        if string.ends(file,"/map.dat") then
            loadMap(file)
            downloading = false
            map.echo("Map File Loaded.")
        elseif string.ends(file,"/versions.lua") then
            check_version()
        elseif string.ends(file,"/generic_mapper.xml") then
            update_version()
        end
    elseif event == "sysDownloadError" and downloading then
        local file = arg[1]
        if string.ends(file,"/versions.lua") and mudlet.translations.interfacelanguage == "zh_CN" then
            -- update to the current download path for chinese user
            if map.configs.download_path == "https://raw.githubusercontent.com/Mudlet/Mudlet/development/src/mudlet-lua/lua/generic-mapper" then
                map.configs.download_path = "https://gitee.com/mudlet/Mudlet/raw/development/src/mudlet-lua/lua/generic-mapper"
                map.checkVersion()
            end
        end
    elseif event == "sysLoadEvent" or event == "sysInstall" then
        config()
    elseif event == "mapOpenEvent" then
        if not help_shown and not map.save.prompt_pattern[map.character or ""] then
            map.find_prompt()
            send(map.configs.lang_dirs['look'], true)
            tempTimer(3, function() map.show_help("quick_start"); help_shown = true end)
        end
    elseif event == "mapStop" then
        map.set("mapping", false)
        walking = false
        map.echo("Mapping and speedwalking stopped.")
    elseif event == "sysManualLocationSetEvent" then
        -- TODO: Add the loading of old info before centerview (prevRoom)
        centerview(arg[1])
    elseif event == "sysUninstallPackage" and not map.updatingMapper and arg[1] == "generic_mapper" then
        for _,id in ipairs(map.registeredEvents) do
            killAnonymousEventHandler(id)
        end
    end
end

--------------------------
-- Configuration functions
--------------------------
map.defaults = {
    mode = "normal", -- can be lazy, simple, normal, or complex
    stretch_map = true,
    search_on_look = true,
    speedwalk_delay = 1,
    speedwalk_wait = true,
    speedwalk_random = true,
    max_search_distance = 1,
    clear_lines_on_send = true,
    map_window = {
        x = 0,
        y = 0,
        w = "30%",
        h = "40%",
        origin = "topright",
        shown = false,
    },
    prompt_test_patterns = {"^%[?%a*%]?<.*>", "^%[.*%]%s*>", "^%w*[%.?!:]*>", "^%[.*%]", "^[Hh][Pp]:.*>"},
    custom_exits = {},  -- format: short_exit = {long_exit, reverse_exit, x_dif, y_dif, z_dif}
                        -- ex: { us = {"upsouth", "downnorth", 0, -1, 1}, dn = {"downnorth", "upsouth", 0, 1, -1} }
    custom_name_search = true,
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
    download_path = "https://raw.githubusercontent.com/Mudlet/Mudlet/development/src/mudlet-lua/lua/generic-mapper",
}

local function config()
    local defaults = map.defaults
    local configs = map.configs or {}
    local path = profilePath.."/map downloads"
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
        exitmap[k] = v[1]
        reverse_dirs[v[1]] = v[2]
        short[v[1]] = k
        local count = #coordmap + 1
        coordmap[count] = {v[3],v[4],v[5]}
        stubmap[count] = v[1]
        stubmap[v[1]] = count
    end
    -- update to the current download path
    if map.configs.download_path == "https://raw.githubusercontent.com/JorMox/Mudlet/development/src/mudlet-lua/lua/generic-mapper" then
        map.configs.download_path = "https://raw.githubusercontent.com/Mudlet/Mudlet/development/src/mudlet-lua/lua/generic-mapper"
    end

    -- setup metatable to store sensitive values
    local protected = {"mapping", "currentRoom", "currentName", "currentExits", "currentArea",
        "prevRoom", "prevName", "prevExits", "mode", "version"}
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
    map.set("version", version)

    local saves = {}
    if io.exists(path.."/map_save.dat") then
        table.load(path.."/map_save.dat",saves)
    end
    saves.prompt_pattern = saves.prompt_pattern or {}
    saves.ignore_patterns = saves.ignore_patterns or {}
    saves.recall = saves.recall or {}
    map.save = saves

    if map.configs.map_window.shown then
        map.showMap(true)
    end
end

local bool_configs = {'stretch_map', 'search_on_look', 'speedwalk_wait', 'speedwalk_random',
    'clear_lines_on_send', 'debug', 'custom_name_search', 'use_translation'}
-- function intended to be used by an alias to change config values and save them to a file for later
function map.setConfigs(key, val, sub_key)
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
            sub_key = exitmap[sub_key] or sub_key
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
        elseif key == "prompt_test_patterns" then
            if not table.contains(map.configs.prompt_test_patterns) then
                table.insert(map.configs.prompt_test_patterns, val)
                map.echo("Prompt pattern added to list: " .. val)
            else
                table.remove(map.configs.prompt_test_patterns, table.index_of(map.configs.prompt_test_patterns, val))
                map.echo("Prompt pattern removed from list: " .. val)
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
    table.save(profilePath.."/map downloads/configs.lua",map.configs)
    config()
end

function map.load_map(address)
    local path = profilePath .. "/map downloads/map.dat"
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
local function show_err(msg,debug)
    map.echo(msg,debug,true)
    error(msg,2)
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
    for k,v in ipairs(wait_echo) do
        print_echoes(v[1],v[2],v[3])
    end
    wait_echo = {}
end

function map.echo(what, debug, err, wait)
    if debug and not map.configs.debug then return end
    what = tostring(what) or ""
    if wait then
        table.insert(wait_echo,{what, debug, err})
        return
    end
    print_wait_echoes()
    print_echoes(what, debug, err)
end

function map.export_area(name)
    -- used to export a single area to a file
    local areas = getAreaTable()
    name = string.lower(name)
    for k,v in pairs(areas) do
        if name == string.lower(k) then name = k end
    end
    if not areas[name] then
        show_err("No such area.")
    end
    local rooms = getAreaRooms(areas[name])
    local tmp = {}
    for k,v in pairs(rooms) do
        tmp[v] = v
    end
    rooms = tmp
    local tbl = {}
    tbl.name = name
    tbl.rooms = {}
    tbl.exits = {}
    tbl.special = {}
    local rname, exits, stubs, doors, special, portals, door_up, door_down, coords
    for k,v in pairs(rooms) do
        rname = getRoomName(v)
        exits = getRoomExits(v)
        stubs = getExitStubs(v)
        doors = getDoors(v)
        special = getSpecialExitsSwap(v)
        portals = getRoomUserData(v,"portals") or ""
        coords = {getRoomCoordinates(v)}
        tbl.rooms[v] = {name = rname, coords = coords, exits = exits, stubs = stubs, doors = doors, door_up = door_up,
            door_down = door_down, door_in = door_in, door_out = door_out, special = special, portals = portals}
        tmp = {}
        for k1,v1 in pairs(exits) do
            if not table.contains(rooms,v1) then
                tmp[k1] = {v1, getRoomName(v1)}
            end
        end
        if not table.is_empty(tmp) then
            tbl.exits[v] = tmp
        end
        tmp = {}
        for k1,v1 in pairs(special) do
            if not table.contains(rooms,v1) then
                tmp[k1] = {v1, getRoomName(v1)}
            end
        end
        if not table.is_empty(tmp) then
            tbl.special[v] = tmp
        end
    end
    local path = profilePath.."/"..string.gsub(string.lower(name),"%s","_")..".dat"
    table.save(path,tbl)
    map.echo("Area " .. name .. " exported to " .. path)
end

function map.import_area(name)
    name = profilePath .. "/" .. string.gsub(string.lower(name),"%s","_") .. ".dat"
    local tbl = {}
    table.load(name,tbl)
    if table.is_empty(tbl) then
        show_err("No file found")
    end
    local areas = getAreaTable()
    local areaID = areas[tbl.name] or addAreaName(tbl.name)
    local rooms = {}
    local ID
    for k,v in pairs(tbl.rooms) do
        ID = createRoomID()
        rooms[k] = ID
        addRoom(ID)
        setRoomName(ID,v.name)
        setRoomArea(ID,areaID)
        setRoomCoordinates(ID,unpack(v.coords))
        if type(v.stubs) == "table" then
            for i,j in pairs(v.stubs) do
                setExitStub(ID,j,true)
            end
        end
        for i,j in pairs(v.doors) do
            setDoor(ID,i,j)
        end
        setRoomUserData(ID,"portals",v.portals)
    end
    for k,v in pairs(tbl.rooms) do
        for i,j in pairs(v.exits) do
            if rooms[j] then
                connect_rooms(rooms[k],rooms[j],i)
            end
        end
        for i,j in pairs(v.special) do
            if rooms[j] then
                addSpecialExit(rooms[k],rooms[j],i)
            end
        end
    end
    for k,v in pairs(tbl.exits) do
        for i,j in pairs(v) do
            if getRoomName(j[1]) == j[2] then
                connect_rooms(rooms[k],j[1],i)
            end
        end
    end
    for k,v in pairs(tbl.special) do
        for i,j in pairs(v) do
            addSpecialExit(k,j[1],i)
        end
    end
    map.fix_portals()
    map.echo("Area " .. tbl.name .. " imported from " .. name)
end

function map.echoRoomList(areaname, exact)
    local areaid, msg, multiples
    local listcolor, othercolor = "DarkSlateGrey","LightSlateGray"
    if tonumber(areaname) then
        areaid = tonumber(areaname)
        msg = getAreaTableSwap()[areaid]
    else
        areaid, msg, multiples = map.findAreaID(areaname, exact)
    end
    if areaid then
        local roomlist, endresult = getAreaRooms(areaid) or {}, {}

        -- obtain a room list for each of the room IDs we got
        local getRoomName = getRoomName
        for _, id in pairs(roomlist) do
            endresult[id] = getRoomName(id)
        end
        roomlist[#roomlist+1], roomlist[0] = roomlist[0], nil
        -- sort room IDs so we can display them in order
        table.sort(roomlist)

        local echoLink, format, fg, echo = echoLink, string.format, fg, cecho
        -- now display something half-decent looking
        cecho(format("<%s>List of all rooms in <%s>%s<%s> (areaID <%s>%s<%s> - <%s>%d<%s> rooms):\n",
            listcolor, othercolor, msg, listcolor, othercolor, areaid, listcolor, othercolor, #roomlist, listcolor))
        -- use pairs, as we can have gaps between room IDs
        for _, roomid in pairs(roomlist) do
            local roomname = endresult[roomid]
            cechoLink(format("<%s>%7s",othercolor,roomid), 'map.speedwalk('..roomid..')',
                format("Go to %s (%s)", roomid, tostring(roomname)), true)
            cecho(format("<%s>: <%s>%s<%s>.\n", listcolor, othercolor, roomname, listcolor))
        end
    elseif not areaid and #multiples > 0 then
        local allareas, format = getAreaTable(), string.format
        local function countrooms(areaname)
            local areaid = allareas[areaname]
            local allrooms = getAreaRooms(areaid) or {}
            local areac = (#allrooms or 0) + (allrooms[0] and 1 or 0)
            return areac
        end
        map.echo("For which area would you want to list rooms for?")
        for _, areaname in ipairs(multiples) do
            echo("  ")
            setUnderline(true)
            cechoLink(format("<%s>%-40s (%d rooms)", othercolor, areaname, countrooms(areaname)),
                'map.echoRoomList("'..areaname..'", true)', "Click to view the room list for "..areaname, true)
            setUnderline(false)
            echo("\n")
        end
    else
        map.echo(string.format("Don't know of any area named '%s'.", areaname),false,true)
    end
    resetFormat()
end

function map.echoAreaList()
    local totalroomcount = 0
    local rlist = getAreaTableSwap()
    local listcolor, othercolor = "DarkSlateGrey","LightSlateGray"

    -- count the amount of rooms in an area, taking care to count the room in the 0th
    -- index as well if there is one
    -- saves the total room count on the side as well
    local function countrooms(areaid)
        local allrooms = getAreaRooms(areaid) or {}
        local areac = (#allrooms or 0) + (allrooms[0] and 1 or 0)
        totalroomcount = totalroomcount + areac
        return areac
    end

    local getAreaRooms, cecho, fg, echoLink, format = getAreaRooms, cecho, fg, echoLink, string.format
    cecho(format("<%s>List of all areas we know of (click to view room list):\n",listcolor))
    for id = 1,table.maxn(rlist) do
        if rlist[id] then
            cecho(format("<%s>%7d ", othercolor, id))
            fg(listcolor)
            echoLink(format("%-40s (%d rooms)",rlist[id],countrooms(id)), 'map.echoRoomList("'..id..'", true)',
                "View the room list for "..rlist[id], true)
            echo("\n")
        end
    end
    cecho(string.format("<%s>Total amount of rooms in this map: %s\n", listcolor, totalroomcount))
end

---------------
-- Map Commands
---------------
function map.set_exit(dir,roomID)
    -- used to set unusual exits from the room you are standing in
    if map.mapping then
        roomID = tonumber(roomID)
        if not roomID then
            show_err("Set Exit: Invalid Room ID")
        end
        if not table.contains(exitmap,dir) and not string.starts(dir, "-p ") then
            show_err("Set Exit: Invalid Direction")
        end

        if not string.starts(dir, "-p ") then
            local exit
            if stubmap[exitmap[dir] or dir] <= 12 then
                exit = short[exitmap[dir] or dir]
                setExit(map.currentRoom,roomID,exit)
            else
                -- check handling of custom exits here
                exit = exitmap[dir] or dir
                exit = "exit " .. exit
                setRoomUserData(map.currentRoom,exit,roomID)
            end
            map.echo("Exit " .. dir .. " now goes to roomID " .. roomID)
        else
            dir = string.gsub(dir,"^-p ","")
            addSpecialExit(map.currentRoom,roomID,dir)
            map.echo("Special exit '" .. dir .. "' now goes to roomID " .. roomID)
        end
    else
        map.echo("Not mapping",false,true)
    end
end

function map.set_recall()
    -- assigned the current room to be recall for the current character
    map.save.recall[map.character] = map.currentRoom
    table.save(profilePath .. "/map downloads/map_save.dat",map.save)
    map.echo("Recall room set to: " .. getRoomName(map.currentRoom) .. ".")
end

function map.set_portal(name, is_auto)
    -- creates a new portal in the room
    if map.mapping then
        if not string.starts(name,"-f ") then
            find_portal = name
        else
            name = string.gsub(name,"^-f ","")
            force_portal = name
        end
        move_queue = {name}
        if not is_auto then
            send(name)
        end
    else
        map.echo("Not mapping",false,true)
    end
end

function map.set_mode(mode)
    -- switches mapping modes
    if not table.contains({"lazy","simple","normal","complex"},mode) then
        show_err("Invalid Map Mode, must be 'lazy', 'simple', 'normal' or 'complex'.")
    end
    map.set("mode", mode)
    map.echo("Current mode set to: " .. mode)
end

function map.start_mapping(area_name)
    -- starts mapping, and sets the current area to the given one, or uses the current one
    if not map.currentName then
        show_err("Room detection not yet working, see <yellow>map basics<reset> for guidance.")
    end
    local rooms
    move_queue = {}
    area_name = area_name ~= "" and area_name or nil
    if map.currentArea and not area_name then
        local areas = getAreaTableSwap()
        area_name = areas[map.currentArea]
    end
    if not area_name then
        show_err("You haven't started mapping yet, how should the first area be called? Set it with: <yellow>start mapping <area name><reset>")
    end
    map.echo("Now mapping in area: " .. area_name)
    map.set("mapping", true)
    find_area(area_name)
    rooms = find_room(map.currentName, map.currentArea)
    if table.is_empty(rooms) then
        if map.currentRoom and getRoomName(map.currentRoom) == map.currentName then
            map.set_area(area_name)
        else
            create_room(map.currentName, map.currentExits, nil, {0,0,0})
        end
    elseif map.currentRoom and map.currentArea ~= getRoomArea(map.currentRoom) then
        map.set_area(area_name)
    end
end

function map.stop_mapping()
    map.set("mapping", false)
    map.echo("Mapping off.")
end

function map.clear_moves()
    local commands_in_queue = #move_queue
    move_queue = {}
    map.echo("Move queue cleared, "..commands_in_queue.." commands removed.")
end

function map.show_moves()
    map.echo("Moves: "..(move_queue and table.concat(move_queue, ', ') or '(queue empty)'))
end

function map.set_area(name)
    -- assigns the current room to the area given, creates the area if necessary
    if map.mapping then
        find_area(name)
        if map.currentRoom and getRoomArea(map.currentRoom) ~= map.currentArea then
            setRoomArea(map.currentRoom,map.currentArea)
            centerview(map.currentRoom)
        end
    else
        map.echo("Not mapping",false,true)
    end
end

function map.set_door(dir,status,one_way)
    -- adds a door on a given exit
    if map.mapping then
        if not map.currentRoom then
            show_err("Make Door: No room found.")
        end
        dir = exitmap[dir] or dir
        if not stubmap[dir] then
            show_err("Make Door: Invalid direction.")
        end
        status = (status ~= "" and status) or "closed"
        one_way = (one_way ~= "" and one_way) or "no"
        if not table.contains({"yes","no"},one_way) then
            show_err("Make Door: Invalid one-way status, must be yes or no.")
        end

        local exits = getRoomExits(map.currentRoom)
        local exit
        -- check handling of custom exits here
        for i = 13,#stubmap do
            exit = "exit " .. stubmap[i]
            exits[stubmap[i]] = tonumber(getRoomUserData(map.currentRoom,exit))
        end
        local target_room = exits[dir]
        if target_room then
            exits = getRoomExits(target_room)
            -- check handling of custom exits here
            for i = 13,#stubmap do
                exit = "exit " .. stubmap[i]
                exits[stubmap[i]] = tonumber(getRoomUserData(target_room,exit))
            end
        end
        if one_way == "no" and (target_room and exits[reverse_dirs[dir]] == map.currentRoom) then
            add_door(target_room,reverse_dirs[dir],status)
        end
        add_door(map.currentRoom,dir,status)
        map.echo(string.format("Adding %s door to the %s", status, dir))
    else
        map.echo("Not mapping",false,true)
    end
end

function map.shift_room(dir)
    -- shifts a room around on the map
    if map.mapping then
        dir = exitmap[dir] or (table.contains(exitmap,dir) and dir)
        if not dir then
            show_err("Shift Room: Exit not found")
        end
        local x,y,z = getRoomCoordinates(map.currentRoom)
        dir = stubmap[dir]
        local coords = coordmap[dir]
        x = x + coords[1]
        y = y + coords[2]
        z = z + coords[3]
        setRoomCoordinates(map.currentRoom,x,y,z)
        centerview(map.currentRoom)
        map.echo("Shifting room",true)
    else
        map.echo("Not mapping",false,true)
    end
end

function map.fix_portals()
    if map.mapping then
        -- used to clear and update data for portal back-referencing
        local rooms = getRooms()
        local portals
        for k,v in pairs(rooms) do
            setRoomUserData(k,"portals","")
        end
        for k,v in pairs(rooms) do
            for cmd,room in pairs(getSpecialExitsSwap(k)) do
                portals = getRoomUserData(room,"portals") or ""
                if portals ~= "" then portals = portals .. "," end
                portals = portals .. tostring(k) .. ":" .. cmd
                setRoomUserData(room,"portals",portals)
            end
        end
        map.echo("Portals Fixed")
    else
        map.echo("Not mapping",false,true)
    end
end

function map.merge_rooms()
    -- used to combine essentially identical rooms with the same coordinates
    -- typically, these are generated due to mapping errors
    if map.mapping then
        map.echo("Merging rooms")
        local x,y,z = getRoomCoordinates(map.currentRoom)
        local rooms = getRoomsByPosition(map.currentArea,x,y,z)
        local exits, portals, room, cmd, curportals
        local room_count = 1
        for k,v in pairs(rooms) do
            if v ~= map.currentRoom then
                if getRoomName(v) == getRoomName(map.currentRoom) then
                    room_count = room_count + 1
                    for k1,v1 in pairs(getRoomExits(v)) do
                        setExit(map.currentRoom,v1,stubmap[k1])
                        exits = getRoomExits(v1)
                        if exits[reverse_dirs[k1]] == v then
                            setExit(v1,map.currentRoom,stubmap[reverse_dirs[k1]])
                        end
                    end
                    for k1,v1 in pairs(getDoors(v)) do
                        setDoor(map.currentRoom,k1,v1)
                    end
                    for k1,v1 in pairs(getSpecialExitsSwap(v)) do
                        addSpecialExit(map.currentRoom,v1,k1)
                    end
                    portals = getRoomUserData(v,"portals") or ""
                    if portals ~= "" then
                        portals = string.split(portals,",")
                        for k1,v1 in ipairs(portals) do
                            room,cmd = unpack(string.split(v1,":"))
                            addSpecialExit(tonumber(room),map.currentRoom,cmd)
                            curportals = getRoomUserData(map.currentRoom,"portals") or ""
                            if not string.find(curportals,room) then
                                curportals = curportals .. "," .. room .. ":" .. cmd
                                setRoomUserData(map.currentRoom,"portals",curportals)
                            end
                        end
                    end
                    -- check handling of custom exits here for doors and exits, and reverse exits
                    for i = 13,#stubmap do
                        local door = "door " .. stubmap[i]
                        local tmp = tonumber(getRoomUserData(v,door))
                        if tmp then
                            setRoomUserData(map.currentRoom,door,tmp)
                        end
                        local exit = "exit " .. stubmap[i]
                        tmp = tonumber(getRoomUserData(v,exit))
                        if tmp then
                            setRoomUserData(map.currentRoom,exit,tmp)
                            if tonumber(getRoomUserData(tmp, "exit " .. reverse_dirs[stubmap[i]])) == v then
                                setRoomUserData(tmp, exit, map.currentRoom)
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
        map.echo("Not mapping",false,true)
    end
end

function map.showMap(shown)
    local configs = map.configs.map_window
    shown = shown or not configs.shown
    map.configs.map_window.shown = shown
    local x, y, w, h, origin = configs.x, configs.y, configs.w, configs.h, configs.origin
    if string.find(origin,"bottom") then
        if y == 0 or y == "0%" then
            y = h
        end
        if type(y) == "number" then
            y = -y
        else
            y = "-"..y
        end
    end
    if string.find(origin,"right") then
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
    mapper:resize(w,h)
    mapper:move(x,y)
    if shown then
        mapper:show()
    else
        mapper:hide()
    end
end

------------------
-- Room Management
------------------
local function add_door(roomID, dir, status)
    -- create or remove a door in the designated direction
    -- consider options for adding pickable and passable information
    dir = exitmap[dir] or dir
    if not table.contains(exitmap,dir) then
        error("Add Door: invalid direction.",2)
    end
    if type(status) ~= "number" then
        status = assert(table.index_of({"none","open","closed","locked"},status),
            "Add Door: Invalid status, must be none, open, closed, or locked") - 1
    end
    local exits = getRoomExits(roomID)
    -- check handling of custom exits here
    if not exits[dir] then
        setExitStub(roomID,stubmap[dir],true)
    end
    -- check handling of custom exits here
    if not table.contains({'u','d'},short[dir]) then
        setDoor(roomID,short[dir],status)
    else
        setDoor(roomID,dir,status)
    end
end

local function check_doors(roomID,exits)
    -- looks to see if there are doors in designated directions
    -- used for room comparison, can also be used for pathing purposes
    if type(exits) == "string" then exits = {exits} end
    local statuses = {}
    local doors = getDoors(roomID)
    local dir
    for k,v in pairs(exits) do
        dir = short[k] or short[v]
        if table.contains({'u','d'},dir) then
            dir = exitmap[dir]
        end
        if not doors[dir] or doors[dir] == 0 then
            return false
        else
            statuses[dir] = doors[dir]
        end
    end
    return statuses
end

local function find_room(name, area)
    -- looks for rooms with a particular name, and if given, in a specific area
    local rooms = searchRoom(name)  -- {room_id: room_name}
    if type(area) == "string" then
        local areas = getAreaTable() or {}
        for k,v in pairs(areas) do
            if string.lower(k) == string.lower(area) then
                area = v
                break
            end
        end
        area = areas[area] or nil
    end
    -- filter on name and area
    for k,v in pairs(rooms) do
        if string.lower(v) ~= string.lower(name) then
            rooms[k] = nil
        elseif area and getRoomArea(k) ~= area then
            rooms[k] = nil
        end
    end
    return rooms
end

local function getRoomStubs(roomID)
    -- turns stub info into table similar to exit table
    local stubs = getExitStubs(roomID)
    if type(stubs) ~= "table" then stubs = {} end
    -- check handling of custom exits here
    local tmp
    for i = 13,#stubmap do
        tmp = tonumber(getRoomUserData(roomID,"stub "..stubmap[i])) or tonumber(getRoomUserData(roomID,"stub"..stubmap[i])) -- for old version
        if tmp then table.insert(stubs,tmp) end
    end

    local exits = {}
    for k,v in pairs(stubs) do
        exits[stubmap[v]] = 0
    end
    return exits
end

local function connect_rooms(ID1, ID2, dir1, dir2, no_check)
    -- makes a connection between rooms
    -- can make backwards connection without a check
    local match = false
    if not ID1 and ID2 and dir1 then
        error("Connect Rooms: Missing Required Arguments.",2)
    end
    dir2 = dir2 or reverse_dirs[dir1]
    -- check handling of custom exits here
    if stubmap[dir1] <= 12 then
        setExit(ID1,ID2,stubmap[dir1])
    else
        addSpecialExit(ID1, ID2, dir1)
        setRoomUserData(ID1,"exit " .. dir1,ID2)
    end
    if stubmap[dir1] > 12 then
        -- check handling of custom exits here
        setRoomUserData(ID1,"stub "..dir1, stubmap[dir1])
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
        local stubs = getRoomStubs(ID2)
        if stubs[dir2] then match = true end
        if (match or no_check) then
            -- check handling of custom exits here
            if stubmap[dir1] <= 12 then
                setExit(ID2,ID1,stubmap[dir2])
            else
                addSpecialExit(ID2, ID1, dir2)
                setRoomUserData(ID2,"exit " .. dir2,ID1)
            end
            if stubmap[dir2] > 12 then
                -- check handling of custom exits here
                setRoomUserData(ID2,"stub "..dir2, stubmap[dir2])
            end
        end
    end
end

local function stretch_map(dir,x,y,z)
    -- stretches a map to make room for just added room that would overlap with existing room
    local dx,dy,dz
    if not dir then return end
    for k,v in pairs(getAreaRooms(map.currentRoomArea)) do
        if v ~= map.currentRoomID then
            dx,dy,dz = getRoomCoordinates(v)
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
            setRoomCoordinates(v,dx,dy,dz)
        end
    end
end

local function create_room(dir, coords)
    -- makes a new room with captured name and exits
    -- links with other rooms as appropriate
    -- links to adjacent rooms in direction of exits if in simple mode
    if map.mapping then
        map.echo("New Room: " .. name,false,false,(dir or find_portal or force_portal) and true or false)

        addRoom(map.currentRoomID)
        setRoomArea(map.currentRoomID, map.currentRoomArea)
        setRoomName(map.currentRoomID, map.currentRoomName)
        setRoomCoordinates(map.currentRoomID, unpack(coords))

        for k,v in ipairs(map.currentRoomExits) do
            if stubmap[k] then
                if stubmap[k] <= 12 then
                    setExitStub(map.currentRoomID, stubmap[k], true)
                else
                    -- add special char to prompt special exit
                    if string.find(k, "up") or string.find(k, "down") then
                        setRoomChar(map.currentRoomID, "◎")
                    end
                    -- check handling of custom exits here
                    setRoomUserData(map.currentRoomID, "stub "..k,stubmap[k])
                end
            end
        end
        if find_portal or force_portal then
            addSpecialExit(map.prevRoomID, map.currentRoomID, (find_portal or force_portal))
            setRoomUserData(map.currentRoomID,"portals",tostring(map.prevRoomID)..":"..(find_portal or force_portal))
        end
        
        local pos_rooms = getRoomsByPosition(map.currentRoomArea, unpack(coords))
        if not (find_portal or force_portal) and map.configs.stretch_map and table.size(pos_rooms) > 1 then
            stretch_map(dir,unpack(coords))
        end
    end
end

local function find_area(name)
    -- searches for the named area, and creates it if necessary
    local areas = getAreaTable()
    local areaID
    for k,v in pairs(areas) do
        if string.lower(name) == string.lower(k) then
            areaID = v
            break
        end
    end
    if not areaID then areaID = addAreaName(name) end
    if not areaID then
        show_err("Invalid Area. No such area found, and area could not be added.",true)
    end
    map.set("currentArea", areaID)
end

function map.findAreaID(areaname, exact)
    local areaname = areaname:lower()
    local list = getAreaTable()

    -- iterate over the list of areas, matching them with substring match.
    -- if we get match a single area, then return its ID, otherwise return
    -- 'false' and a message that there are than one are matches
    local returnid, fullareaname, multipleareas = nil, nil, {}
    for area, id in pairs(list) do
        if (not exact and area:lower():find(areaname, 1, true)) or (exact and areaname == area:lower()) then
            returnid = id
            fullareaname = area
            multipleareas[#multipleareas+1] = area
        end
    end

    if #multipleareas == 1 then
        return returnid, fullareaname
    else
        return nil, nil, multipleareas
    end
end

-------------------
-- Movement Capture
-------------------
local function move_map()
    -- tries to move the map to the next room

    if find_portal then
        map.find_portal()
    elseif force_portal then
        find_portal = false
        map.echo("Creating portal destination")
        create_room(nil, {getRoomCoordinates(map.currentRoom)})
        force_portal = false
    elseif move == "recall" and map.save.recall[map.character] then
        centerview(map.save.recall[map.character])
    end
end

local function capture_move_cmd(dir,priority)
    -- captures valid movement commands
    local configs = map.configs
    if configs.clear_lines_on_send then
        lines = {}
    end
    dir = string.lower(dir)
    if dir == "/" then dir = "recall" end
    if dir == configs.lang_dirs['l'] then dir = configs.lang_dirs['look'] end
    if configs.use_translation then
        dir = configs.translate[dir] or dir
    end
    local door = string.match(dir,"open (%a+)")
    if map.mapping and door and (exitmap[door] or short[door]) then
        local doors = getDoors(map.currentRoom)
        if not doors[door] and not doors[short[door]] then
            map.set_door(door,"","")
        end
    end
    local portal = string.match(dir,"enter (%a+)")
    if map.mapping and portal then
        local portals = getSpecialExitsSwap(map.currentRoom)
        if not portals[dir] then
            map.set_portal(dir, true)
        end
    end
    if table.contains(exitmap,dir) or string.starts(dir,"enter ") or dir == "recall" then
        if priority then
            table.insert(move_queue,1,exitmap[dir] or dir)
        else
            table.insert(move_queue,exitmap[dir] or dir)
        end
    elseif configs.search_on_look and dir == configs.lang_dirs['look'] then
        table.insert(move_queue, dir)
    elseif map.currentRoom then
        local special = getSpecialExitsSwap(map.currentRoom) or {}
        if special[dir] then
            if priority then
                table.insert(move_queue,1,dir)
            else
                table.insert(move_queue,dir)
            end
        end
    end
end

function map.find_portal()
    map.echo("Found portal destination, linking rooms",false,false,true)
    addSpecialExit(map.prevRoomID, map.currentRoomID, find_portal)
    local portals = getRoomUserData(map.currentRoomID, "portals") or ""
    portals = portals .. "," .. tostring(map.prevRoomID)..":"..find_portal
    setRoomUserData(map.currentRoomID,"portals",portals)
    centerview(map.currentRoomID)
    map.echo("Room found, ID: " .. map.currentRoomID, true)
    find_portal = false    
end

function map.search_timer_check()
    if find_prompt then
        map.echo("Prompt not auto-detected, use 'map prompt' to set a prompt pattern.",false,true)
        find_prompt = false
    end
end

function map.find_prompt()
    find_prompt = true
    map.echo("Searching for prompt.")
    send("\n", false)
    tempTimer(5, "map.search_timer_check()")
end

function map.make_prompt_pattern(str)
    if not str:starts("^") then str = "^"..str end
    map.save.prompt_pattern[map.character] = str
    find_prompt = false
    table.save(profilePath .. "/map downloads/map_save.dat",map.save)
    map.echo("Prompt pattern set: " .. str)
end

function map.make_ignore_pattern(str)
    map.save.ignore_patterns = map.save.ignore_patterns or {}
    if not table.contains(map.save.ignore_patterns,str) then
        table.insert(map.save.ignore_patterns,str)
        map.echo("Ignore pattern added: " .. str)
    else
        table.remove(map.save.ignore_patterns, table.index_of(map.save.ignore_patterns, str))
        map.echo("Ignore pattern removed: " .. str)
    end
    table.save(profilePath .. "/map downloads/map_save.dat",map.save)
end

local function grab_line()
    table.insert(lines,line)
    if map.save.prompt_pattern[map.character] and string.match(line, map.save.prompt_pattern[map.character]) then
        if map.prompt.exits and map.prompt.exits ~= "" then
            raiseEvent("onNewRoom")
        end
        print_wait_echoes()
        map.echo("Prompt captured",true)
    end
    if find_prompt then
        for k,v in ipairs(map.configs.prompt_test_patterns) do
            if string.match(line,v) then
                map.save.prompt_pattern[map.character] = v
                table.save(profilePath .. "/map downloads/map_save.dat",map.save)
                find_prompt = false
                map.echo("Prompt found")
                break
            end
        end
    end
end

local function name_search()
    local room_name
    if map.configs.custom_name_search then
        room_name = mudlet.custom_name_search(lines)
    else
        local line_count = #lines + 1
        local cur_line, last_line
        local prompt_pattern = map.save.prompt_pattern[map.character]
        if not prompt_pattern then return end
        while not room_name do
            line_count = line_count - 1
            if not lines[line_count] then break end
            cur_line = lines[line_count]
            for k,v in ipairs(map.save.ignore_patterns) do
                cur_line = string.trim(string.gsub(cur_line,v,""))
            end
            if string.find(cur_line,prompt_pattern) then
                cur_line = string.trim(string.gsub(cur_line,prompt_pattern,""))
                if cur_line ~= "" then
                    room_name = cur_line
                else
                    room_name = last_line
                end
            elseif line_count == 1 then
                cur_line = string.trim(cur_line)
                if cur_line ~= "" then
                    room_name = cur_line
                else
                    room_name = last_line
                end
            elseif not string.match(cur_line,"^%s*$") then
                last_line = cur_line
            end
        end
        lines = {}
        room_name = room_name:sub(1,100)
    end
    return room_name
end

---------------
-- Speedwalking
---------------

function map.find_path(roomName,areaName,return_tables)
    areaName = (areaName ~= "" and areaName) or nil
    local rooms = find_room(roomName,areaName)
    local found,dirs = false,{}
    local path = {}
    for k,v in pairs(rooms) do
        found = getPath(map.currentRoom,k)
        if found and (#dirs == 0 or #dirs > #speedWalkDir) then
            dirs = speedWalkDir
            path = speedWalkPath
        end
    end
    if return_tables then
        if table.is_empty(path) then
            path, dirs = nil, nil
        end
        return path, dirs
    else
        if #dirs > 0 then
            map.echo("Path to " .. roomName .. ((areaName and " in " .. areaName) or "") .. ": " .. table.concat(dirs,", "))
        else
            map.echo("No path found to " .. roomName .. ((areaName and " in " .. areaName) or "") .. ".",false,true)
        end
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
        send(table.remove(map.walkDirs,1))
        -- check to see if we are done
        if #map.walkDirs == 0 then
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

function map.speedwalk(roomID, walkPath, walkDirs)
    roomID = roomID or speedWalkPath[#speedWalkPath]
    getPath(map.currentRoom, roomID)
    walkPath = speedWalkPath
    walkDirs = speedWalkDir
    if #speedWalkPath == 0 then
        map.echo("No path to chosen room found.",false,true)
        return
    end
    table.insert(walkPath, 1, map.currentRoom)
    -- go through dirs to find doors that need opened, etc
    -- add in necessary extra commands to walkDirs table
    local k = 1
    repeat
        local id, dir = walkPath[k], walkDirs[k]
        if exitmap[dir] or short[dir] then
            local door = check_doors(id, exitmap[dir] or dir)
            local status = door and door[dir]
            if status and status > 1 then
                -- if locked, unlock door
                if status == 3 then
                    table.insert(walkPath,k,id)
                    table.insert(walkDirs,k,"unlock " .. (exitmap[dir] or dir))
                    k = k + 1
                end
                -- if closed, open door
                table.insert(walkPath,k,id)
                table.insert(walkDirs,k,"open " .. (exitmap[dir] or dir))
                k = k + 1
            end
        end
        k = k + 1
    until k > #walkDirs
    if map.configs.use_translation then
        for k, v in ipairs(walkDirs) do
            walkDirs[k] = map.configs.lang_dirs[v] or v
        end
    end
    -- perform walk
    walking = true
    if map.configs.speedwalk_wait or map.configs.speedwalk_delay > 0 then
        map.walkDirs = walkDirs
        continue_walk()
    else
        for _,dir in ipairs(walkDirs) do
            send(dir)
        end
        walking = false
        raiseEvent("sysSpeedwalkFinished")
    end
end

function doSpeedWalk()
    if #speedWalkPath ~= 0 then
        raiseEvent("sysSpeedwalkStarted")
        map.speedwalk(nil, speedWalkPath, speedWalkDir)
    else
        map.echo("No path to chosen room found.",false,true)
    end
end

function map.pauseSpeedwalk()
    if #speedWalkDir ~= 0 then
        walking = false
        raiseEvent("sysSpeedwalkPaused")
        map.echo("Speedwalking paused.")
    else
        map.echo("Not currently speedwalking.")
    end
end

function map.resumeSpeedwalk(delay)
    if #speedWalkDir ~= 0 then
        centerview(map.currentRoomID)
        raiseEvent("sysSpeedwalkResumed")
        map.echo("Speedwalking resumed.")
        tempTimer(delay or 0, function() map.speedwalk(nil, speedWalkPath, speedWalkDir) end)
    else
        map.echo("Not currently speedwalking.")
    end
end

function map.stopSpeedwalk()
    if #speedWalkDir ~= 0 then
        walking = false
        map.walkDirs, speedWalkDir, speedWalkPath, speedWalkWeight = {}, {}, {}, {}
        raiseEvent("sysSpeedwalkStopped")
        map.echo("Speedwalking stopped.")
    else
        map.echo("Not currently speedwalking.")
    end
end

function map.toggleSpeedwalk(what)
    assert(what == nil or what == "on" or what == "off", "map.toggleSpeedwalk wants 'on', 'off' or nothing as an argument")

    if what == "on" or (what == nil and walking) then
        map.pauseSpeedwalk()
    elseif what == "off" or (what == nil and not walking) then
        map.resumeSpeedwalk()
    end
end

-------------
-- Versioning
-------------
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
    map.update_timer = tempTimer(3600, [[map.checkVersion()]])
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
