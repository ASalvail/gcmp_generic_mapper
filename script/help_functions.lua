map = map or {}

map.help = {[[
    <cyan>Generic GMCP Map Script<reset>

    This script allows for semi-automatic mapping using the GMCP protocol.
    Below is an overview of the included commands and important events that 
    this script uses to work. Additional information on each command or 
    event is available in individual help files.

    <cyan>Fundamental Commands:<reset>
        These are commands used to get the mapper functional on a basic level

        <link: show>map show</link> - Displays or hides a map window
        <link: quick start>map basics</link> - Shows a quick-start guide with some basic information to
            help get the script working
        <link: 1>map help <optional command name></link> - Shows either this help file or the
            help file for the command given
        <link: debug>map debug</link> - Toggles on debug mode, in which extra messages are shown
            with the intent of assisting in troubleshooting getting the
            script setup
        <link: path>map path <room name> <; optional area name></link> - Finds a walking path to
            the named room, in the named area if specified
        <link: config>map config <configuration> <optional value></link> - Sets or toggles the
            given configuration either turning it on or off, if no value is
            given, or sets it to the given value
        <link: window>map window <configuration> <value></link> - Sets the given configuration for
            the map window to the given value
        <link: translate>map translate <english direction> <translated long direction></link>
            <link: translate><translated short direction></link> - Sets the provided translations for
            the given english direction word. (Not implemented entirely)

    <cyan>Mapping Commands:<reset>
        These are commands used in the process of actually creating a map

        <link: start mapping>start mapping <optional area name></link> - Starts adding content to the
            map, using either the area of the room the user is currently in,
            or the area name provided
        <link: stop mapping>stop mapping</link> - Stops adding content to the map
        <link: set area>set area <area name></link> - Moves the current room to the named area
        <link: mode>map mode <normal or complex></link> - Sets the mapping mode, which
            defines how new rooms are added to the map.
        <link: add door>add door <direction> <optional door status> <optional one way></link> -
            Creates a door in the given direction, with the given status
            (default closed), in both directions, unless a one-direction door
            is specified
        <link: add portal>add portal <entry command></link> - Creates a portal leading to the current 
            room, using the given command for entry
        <link: shift>shift <direction></link> - Moves the current room on the map in the given
            direction
        <link: merge rooms>merge rooms</link> - Combines overlapping rooms that have the same name into
            a single room
        <link: set exit>set exit <direction> <roomID></link> - Creates a one-way exit in the given
            direction to the room with the specified roomID, can also be used
            with portals
        <link: areas>map areas</link> - Shows a list of all area, with links to show a list of
            rooms in the area
        <link: rooms>map rooms <area name></link> - Shows a list of rooms in the named area

    <cyan>Sharing and Backup Commands:<reset>

        <link: save>map save</link> - Creates a backup of the map
        <link: load>map load <remote address></link> - Loads a map backup, or a map file from a
            remote address
        <link: export>map export <area name></link> - Creates a file from the named area that can
            be shared
        <link: import>map import <area name></link> - Loads an area from a file

    <cyan>Key Variables:<reset>
        These variables are used by the script to keep track of important
            information and can be displayed using `lua [variable_name]`

        <yellow>map.configs<reset> - Contains a number of different options that can be set
            to modify script behavior
        <yellow>map.current_room_id<reset> - Contains the roomID of the room your character is
            in, according to the script
        <yellow>map.current_room_name<reset> - Contains the name of the room your character is in,
            according to the script
        <yellow>map.current_room_exits<reset> - Contains a table of the exits of the room your
            character is in, according to the script
        <yellow>map.current_room_area_id<reset> - Contains the areaID of the area your character is
            in, according to the script
]]}
map.help.save = [[
    <cyan>Map Save<reset>
        syntax: <yellow>map save<reset>

        This command creates a copy of the current map and stores it in the
        profile folder as `map.dat`. This can be useful for creating a backup
        before adding new content, in case of problems, and as a way to share an
        entire map at once.
]]
map.help.load = [[
    <cyan>Map Load<reset>
        syntax: <yellow>map load <optional download address><reset>

        This command replaces the current map with the map stored as `map.dat` in
        the profile folder. Alternatively, if a download address is provided, a
        map is downloaded from that location and loaded to replace the current
        map. If no filename is given with the download address, the script tries
        to download `map.dat`. If a filename is given it MUST end with `.dat`.
]]
map.help.show = [[
    <cyan>Map Show<reset>
        syntax: <yellow>map show<reset>

        This command shows a map window, as specified by the window configs set
        via the <link: window>map window command</link>. It isn't necessary to use this method to
        show a map window to use this script, any map window will work.
]]
map.help.export = [[
    <cyan>Map Export<reset>
        syntax: <yellow>map export <area name><reset>

        This command creates a file containing all the informatino about the
        named area and stores it in the profile folder, with a file name based
        on the area name. This file can then be imported, allowing for easy
        sharing of single map areas. The file name will be the name of the area
        in all lower case, with spaces replaced with underscores, and a `.dat`
        file extension.
]]
map.help.import = [[
    <cyan>Map Import<reset>
        syntax: <yellow>map import <area name><reset>

        This command imports a file from the profile folder with a name matching
        the name of the file, and uses it to create an area on the map. The area
        name used can be capitalized or not, and may have either spaces or
        underscores between words. The actual area name is stored within the
        file, and is not set by the area name used in this command.
]]
map.help.start_mapping = [[
    <cyan>Start Mapping<reset>
        syntax: <yellow>start mapping<reset>

        This command instructs the script to add new content to the map when it
        is seen.
]]
map.help.stop_mapping = [[
    <cyan>Stop Mapping<reset>
        syntax: <yellow>stop mapping<reset>

        This command instructs the script to stop adding new content until
        mapping is resumed at a later time. The map will continue to perform
        other functions.
]]
map.help.debug = [[
    <cyan>Map Debug<reset>
        syntax: <yellow>map debug<reset>

        This command toggles the map script's debug mode on or off when it is
        used. Debug mode provides some extra messages to help with setting up
        the script and identifying problems to help with troubleshooting. If you
        are getting assistance with setting up this script, using debug mode may
        make the process faster and easier.
]]
map.help.areas = [[
    <cyan>Map Areas<reset>
        syntax: <yellow>map areas<reset>

        This command displays a linked list of all areas in the map. When
        clicked, the rooms in the selected area will be displayed, as if the
        'map rooms' command had been used with that area as an argument.
]]
map.help.rooms = [[
    <cyan>Map Rooms<reset>
        syntax: <yellow>map rooms <area name><reset>

        This command shows a list of all rooms in the area, with the roomID and
        the room name, as well as a count of how many rooms are in the area
        total. Note that the area name argument is not case sensitive.
]]
map.help.set_area = [[
    <cyan>Set Area<reset>
        syntax: <yellow>set area <area name><reset>

        This command move the current room into the named area, creating the
        area if needed.
]]
map.help.mode = [[
    <cyan>Map Mode<reset>
        syntax: <yellow>map mode <normal, or complex><reset>

        This command changes the current mapping mode, which determines what
        happens when new rooms are added to the map.

        In normal mode (default), the newly created room is connected to the room you left
        from, so long as it has an exit leading in that direction.

        In complex mode, none of the exits of the newly connected room are
        connected automatically when it is created.
]]
map.help.add_door = [[
    <cyan>Add Door<reset>
        syntax: <yellow>add door <direction> <optional none, open, closed, or locked>
        <optional yes or no><reset>

        This command places a door on the exit in the given direction, or
        removes it if "none" is given as the second argument. The door status is
        set as given by the second argument, default "closed". The third
        argument determines if the door is a one-way door, default "no".
]]
map.help.add_portal = [[
    <cyan>Add Portal<reset>
        syntax: <yellow>add portal <entry command><reset>

        This command creates a special exit in the previous room leading to the
        current room that is entered by using the given entry command.
]]
map.help.shift = [[
    <cyan>Shift<reset>
        syntax: <yellow>shift <direction><reset>

        This command moves the current room one step in the direction given, on
        the map.
]]
map.help.merge_rooms = [[
    <cyan>Merge Rooms<reset>
        syntax: <yellow>merge rooms<reset>

        This command combines all rooms that share the same coordinates and the
        same room name into a single room, with all of the exits preserved and
        combined.
]]
map.help.set_exit = [[
    <cyan>Set Exit<reset>
        syntax: <yellow>set exit <direction> <destination roomID><reset>

        This command sets the exit in the current room in the given direction to
        connect to the target room, as specified by the roomID. This is a
        one-way connection.
]]
map.help.path = [[
    <cyan>Map Path<reset>
        syntax: <yellow>map path <room name> <; optional area name><reset>

        This command tries to find a walking path from the current room to the
        named room. If an area name is given, only rooms within that area that
        is given are checked. Neither the room name nor the area name are case
        sensitive, but otherwise an exact match is required. Note that a
        semicolon is required between the room name and area name, if an area
        name is given, but spaces before or after the semicolon are optional.

        Example: <yellow>map path main street ; newbie town<reset>
]]
map.help.config = [[
    <cyan>Map Config<reset>
        syntax: <yellow>map config <setting> <optional value><reset>

        This command changes any of the available configurations listed below.
        If no value is given, and the setting is either 'on' or 'off', then the
        value is switched. When naming a setting, spaces can be used in place of
        underscores. Details of what options are available and what each one
        does are provided.

        <yellow>speedwalk_delay<reset> - When using the speedwalk function of the script,
            this is the amount of time the script waits after either sending
            a command or, if speedwalk_wait is set, after arriving in a new
            room, before the next command is sent. This may be any number 0
            or higher.

        <yellow>speedwalk_wait<reset> - When using the speedwalk function of the script,
            this indicates if the script waits for your character to move
            into a new room before sending the next command. This may be true
            or false.

        <yellow>speedwalk_random<reset> - When using the speedwalk function of the script
            with a speedwalk_delay value, introduces a randomness to the wait
            time by adding some amount up to the speedwalk_delay value. This
            may be true or false.

        <yellow>stretch_map<reset> - When adding a new room that would overlap an existing
            room, if this is set the map will stretch out to prevent the
            overlap, with all rooms further in the direction moved getting
            pushed one further in that direction. This may be true or false.

        <yellow>mode<reset> - This is the default mapping mode on startup, and defines how
            new rooms are added to the map. May be "normal" or "complex".

        <yellow>download_path<reset> - This is the path that updates are downloaded from.
            This may be any web address where the versions.lua and
            generic_mapper.xml files can be downloaded from.

        <yellow>custom_exits<reset> - This is a table of custom exit directions and their
            relevant extra pieces of info. Each entry should have the short
            direction as the keyword for a table containing first the long
            direction, then the long direction of the reverse of this
            direction, and then the x, y, and z change in map position
            corresponding to the movement. As an example: us = {'upsouth',
            'downnorth', 0, -1, 1}

        <yellow>use_translation<reset> - When this is set, the lang_dirs table is used to
            translate movement and status commands in some other language
            into the English used by the script. This may be true or false.

        <yellow>debug<reset> - When this is set, the script will start in debug mode. This
            may be true or false.
]]
map.help.window = [[
    <yellow>Map Window<reset>
        syntax: <yellow>map window <setting> <value><reset>

        This command changes any of the available configurations listed below,
        which determine the appearance and positioning of the map window when
        the 'map show' command is used. Details of what options are available
        and what each one does are provided.

        <yellow>x<reset> - This is the x position of the map window, and should be a
            positive number of pixels or a percentage of the screen width.

        <yellow>y<reset> - This is the y position of the map window, and should be a
            positive number of pixels or a percentage of the screen height.

        <yellow>w<reset> - This is the width of the map window, and should be a positive
            number of pixels or a percentage of the screen width.

        <yellow>h<reset> - This is the height of the map window, and should be a positive
            number of pixels or a percentage of the screen height.

        <yellow>origin<reset> - This is the corner from which the window position is
            measured, and may be 'topright', 'topleft', 'bottomright', or
            'bottomleft'.

        <yellow>shown<reset> - This determines if the map window is shown immediately upon
            connecting to the game. This may be true or false. If you intend
            to have some other script control the map window, this should be
            set to false.
]]
map.help.translate = [[
    <yellow>Map Translate<reset>
        syntax: <yellow>map translate <english direction> <translated long direction>
            <translated short direction><reset>

        This command sets direction translations for the script to use, either
        for commands entered to move around, or listed exits the game shows when
        you enter a room. Available directions: north, south, east, west,
        northwest, northeast, southwest, southeast, up, down, in, and out.
        Also you can customize special commands sent to mud like 'look'.
]]
map.help.quick_start = [[
    <link: quick_start>map basics</link> (quick start guide)
    ----------------------------------------

    1. <link: start mapping>start mapping</link>
       Use this command to start mapping. The first time an area is encountered,
       it will be considered the "base" area. Everytime the character is teleported
       but stays within the same area according to the server data (e.g. you moved 
       'in' a building or you 'enter'ed a portal), a new sub-area
       is created named using the room where the move happened. You can change the
       area name created using the `set area` command, however make sure to keep the
       base area name at the start of the new area name. If the character
       eventually reaches back the base area via other means, the mapper will attempt
       to reconnect the disconnected area to the base area, transferring all connected
       rooms.
    2. <link: debug>map debug</link>
       This toggles debug mode. When on, messages will be displayed showing what
       information is captured and a few additional error messages that can help
       with getting the script fully compatible with your game.
    3. <link: 1>map help</link>
       This will bring up a more detailed help file, starting with the available
       help topics.
]]

function map.show_help(cmd)
    if cmd and cmd ~= "" then
        if cmd:starts("map ") then cmd = cmd:sub(5) end
        cmd = cmd:lower():gsub(" ","_")
        if not map.help[cmd] then
            map.echo("No help file on that command.")
        end
    else
        cmd = 1
    end

    for w in map.help[cmd]:gmatch("[^\n]*\n") do
        local url, target = rex.match(w, [[<(url)?link: ([^>]+)>]])
        -- lrexlib returns a non-capture as 'false', so determine which variable the capture went into
        if target == nil then target = url end
        if target then
            local before, linktext, _, link, _, after, ok = rex.match(w,
                          [[(.*)<((url)?link): [^>]+>(.*)<\/(url)?link>(.*)]], 0, 'm')
            -- could not get rex.match to capture the newline - fallback to string.match
            local _, _, after = w:match("(.*)<u?r?l?link: [^>]+>(.*)</u?r?l?link>(.*)")

            cecho(before)
            fg("yellow")
            setUnderline(true)
            if linktext == "urllink" then
                echoLink(link, [[openWebPage("]]..target..[[")]], "Open Mudlet Discord", true)
            elseif target ~= "1" then
                echoLink(link,[[map.show_help("]]..target..[[")]],"View: map help " .. target,true)
            else
                echoLink(link,[[map.show_help()]],"View: map help",true)
            end
            setUnderline(false)
            resetFormat()
            if after then cecho(after) end
        else
            cecho(w)
        end
    end
    echo("\n")
end