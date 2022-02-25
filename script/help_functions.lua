
map.help = {[[
    <cyan>Generic Map Script<reset>

    This script allows for semi-automatic mapping using the included triggers.
    While different games can have dramatically different ways of displaying
    information, some effort has been put into giving the script a wide range of
    potential patterns to look for, so that it can work with minimal effort in
    many cases. The script locates the room name by searching up from the
    detected exits line until a prompt is found or it runs out of text to
    search, clearing saved text each time a prompt is detected or a movement
    command is sent, with the room name being set to the last line of text
    found. An accurate prompt pattern is necessary for this to work well, and
    sometimes other text can end up being shown between the prompt and the room
    name, or on the same line as the room name, which can be handled by
    providing appropriate patterns telling the script to ignore that text. Below
    is an overview of the included commands and important events that this
    script uses to work. Additional information on each command or event is
    available in individual help files.

    <cyan>Fundamental Commands:<reset>
        These are commands used to get the mapper functional on a basic level

        <link: show>map show</link> - Displays or hides a map window
        <link: quick start>map basics</link> - Shows a quick-start guide with some basic information to
            help get the script working
        <link: 1>map help <optional command name></link> - Shows either this help file or the
            help file for the command given
        <link: find prompt>find prompt</link> - Instructs the script to look for a prompt that matches
            a known pattern
        <link: prompt>map prompt</link> - Provides a specific pattern to the script that matches
            your prompt, uses Lua string-library patterns
        <link: ignore>map ignore</link> - Provides a specific pattern for the script to ignore,
            uses Lua string-library patterns
        <link: debug>map debug</link> - Toggles on debug mode, in which extra messages are shown
            with the intent of assisting in troubleshooting getting the
            script setup
        <link: me>map me</link> - Locates the user on the map, if possible
        <link: path>map path <room name> <; optional area name></link> - Finds a walking path to
            the named room, in the named area if specified
        <link: character>map character <name></link> - Sets a given name as the current character for
            the purposes of the script, used for different prompt patterns
            and recall locations
        <link: recall>map recall</link> - Sets the current room as the recall location of the
            current character
        <link: config>map config <configuration> <optional value></link> - Sets or toggles the
            given configuration either turning it on or off, if no value is
            given, or sets it to the given value
        <link: window>map window <configuration> <value></link> - Sets the given configuration for
            the map window to the given value
        <link: translate>map translate <english direction> <translated long direction></link>
            <link: translate><translated short direction></link> - Sets the provided translations for
            the given english direction word.

    <cyan>Mapping Commands:<reset>
        These are commands used in the process of actually creating a map

        <link: start mapping>start mapping <optional area name></link> - Starts adding content to the
            map, using either the area of the room the user is currently in,
            or the area name provided
        <link: stop mapping>stop mapping</link> - Stops adding content to the map
        <link: set area>set area <area name></link> - Moves the current room to the named area
        <link: mode>map mode <lazy, simple, normal or complex></link> - Sets the mapping mode, which
            defines how new rooms are added to the map.
        <link: add door>add door <direction> <optional door status> <optional one way></link> -
            Creates a door in the given direction, with the given status
            (default closed), in both directions, unless a one-direction door
            is specified
        <link: add portal>add portal <entry command></link> - Creates a portal in the current room,
            using the given command for entry
        <link: shift>shift <direction></link> - Moves the current room on the map in the given
            direction
        <link: merge rooms>merge rooms</link> - Combines overlapping rooms that have the same name into
            a single room
        <link: clear moves>clear moves</link> - Clears the list of movement commands maintained by the
            script
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

    <cyan>Mapping Events:<reset>
        These events are used by triggers to direct the script's behavior

        <link: onNewRoom>onNewRoom</link> - Signals that a room has been detected, optional exits
            argument
        <link: onMoveFail>onMoveFail</link> - Signals that an attempted move failed
        <link: onForcedMove>onForcedMove</link> - Signals that the character moved without a command
            being entered, required direction argument
        <link: onRandomMove>onRandomMove</link> - Signals that the character moved in an unknown
            direction without a command being entered
        <link: onVisionFail>onVisionFail</link> - Signals that the character moved but some or all of
            the room information was not able to be gathered

    <cyan>Key Variables:<reset>
        These variables are used by the script to keep track of important
            information

        <yellow>map.prompt.room<reset> - Can be set to specify the room name
        <yellow>map.prompt.exits<reset> - Can be set to specify the room exits
        <yellow>map.prompt.hash<reset> - Can be set to specify the room hash
            Notice: if you set this, mapper will only find room by
            getRoomIDbyHash(hash)
        <yellow>map.character<reset> - Contains the current character name
        <yellow>map.save.recall<reset> - Contains a table of recall roomIDs for all
            characters
        <yellow>map.save.prompt_pattern<reset> - Contains a table of prompt patterns for all
            characters
        <yellow>map.save.ignore_patterns<reset> - Contains a table of patterns of text the
            script ignores
        <yellow>map.configs<reset> - Contains a number of different options that can be set
            to modify script behavior
        <yellow>map.currentRoom<reset> - Contains the roomID of the room your character is
            in, according to the script
        <yellow>map.currentName<reset> - Contains the name of the room your character is in,
            according to the script
        <yellow>map.currentExits<reset> - Contains a table of the exits of the room your
            character is in, according to the script
        <yellow>map.currentArea<reset> - Contains the areaID of the area your character is
            in, according to the script
]]}
map.help.save = [[
    <cyan>Map Save<reset>
        syntax: <yellow>map save<reset>

        This command creates a copy of the current map and stores it in the
        profile folder as map.dat. This can be useful for creating a backup
        before adding new content, in case of problems, and as a way to share an
        entire map at once.
]]
map.help.load = [[
    <cyan>Map Load<reset>
        syntax: <yellow>map load <optional download address><reset>

        This command replaces the current map with the map stored as map.dat in
        the profile folder. Alternatively, if a download address is provided, a
        map is downloaded from that location and loaded to replace the current
        map. If no filename is given with the download address, the script tries
        to download map.dat. If a filename is given it MUST end with .dat.
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
        in all lower case, with spaces replaced with underscores, and a .dat
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
        syntax: <yellow>start mapping <optional area name><reset>

        This command instructs the script to add new content to the map when it
        is seen. When first used, an area name is mandatory, so that an area is
        created for new rooms to be placed in. If used with an area name while
        the map shows the character within a room on the map, that room will be
        moved to be in the named area, if it is not already in it. If used
        without an area name, the room is not moved, and mapping begins in the
        area the character is currently located in.
]]
map.help.stop_mapping = [[
    <cyan>Stop Mapping<reset>
        syntax: <yellow>stop mapping<reset>

        This command instructs the script to stop adding new content until
        mapping is resumed at a later time. The map will continue to perform
        other functions.
]]
map.help.find_prompt = [[
    <cyan>Find Prompt<reset>
        syntax: <yellow>find prompt<reset>

        This command instructs the script to begin searching newly arriving text
        for something that matches one of its known prompt patterns. If one is
        found, that pattern will be set as the current prompt pattern. This
        should typically be the first command used to set up this script with a
        new profile. If your prompt appears after using this command, but there
        is no message saying that the prompt has been found, it will be
        necessary to use the map prompt command to manually set a pattern.
]]
map.help.prompt = [[
    <cyan>Map Prompt<reset>
        syntax: <yellow>map prompt <prompt pattern><reset>

        This command manually sets a prompt pattern for the script to use.
        Because of the way this script works, the prompt pattern should match
        the entire prompt, so that if the text matching the pattern were
        removed, the line with the prompt would be blank. The patterns must be
        of the type used by the Lua string library. If you are unsure about what
        pattern to use, seek assistance on the Mudlet Forums or the Mudlet
        Discord channel.
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
map.help.ignore = [[
    <cyan>Map Ignore<reset>
        syntax: <yellow>map ignore <ignore pattern><reset>

        This command adds the given pattern to a list the script maintains to
        help it locate the room name. Any text that might appear after a command
        is sent to move and before the room name appears, or after the prompt
        and before the room name if several movement commands are sent at once,
        should have an ignore pattern added for it.

        If the given pattern is already in the list of ignore patterns, that
        pattern will be removed from the list.
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
        syntax: <yellow>map mode <lazy, simple, normal, or complex><reset>

        This command changes the current mapping mode, which determines what
        happens when new rooms are added to the map.

        In lazy mode, connecting exits aren't checked and a room is only added if
        there isn't an adjacent room with the same name.

        In simple mode, if an adjacent room has an exit stub pointing toward the
        newly created room, and the new room has an exit in that direction,
        those stubs are connected in both directions.

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
        syntax: <yellow>add portal <optional -f> <entry command><reset>

        This command creates a special exit in the current room that is entered
        by using the given entry command. The given entry command is then sent,
        moving to the destination room. If the destination room matches an
        existing room, the special exit will link to that room, and if not a new
        room will be created. If the optional "-f" argument is given, a new room
        will be created for the destination regardless of if an existing room
        matches the room seen when arriving at the destination.
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
map.help.clear_moves = [[
    <cyan>Clear Moves<reset>
        syntax: <yellow>clear moves<reset>

        This command clears the script's queue of movement commands, and is
        intended to be used after you attempt to move while mapping but the
        movement is prevented in some way that is not caught and handled by a
        trigger that raises the onMoveFail event.
]]
map.help.set_exit = [[
    <cyan>Set Exit<reset>
        syntax: <yellow>set exit <direction> <destination roomID><reset>

        This command sets the exit in the current room in the given direction to
        connect to the target room, as specified by the roomID. This is a
        one-way connection.
]]
map.help.onnewroom = [[
    <cyan>onNewRoom Event<reset>

        This event is raised to inform the script that a room has been detected.
        When raised, a string containing the exits from the detected room should
        be passed as a second argument to the raiseEvent function, unless those
        exits have previously been stored in map.prompt.exits.
]]
map.help.onmovefail = [[
    <cyan>onMoveFail Event<reset>

        This event is raised to inform the script that a move was attempted but
        the character was unable to move in the given direction, causing that
        movement command to be removed from the script's movement queue.
]]
map.help.onforcedmove = [[
    <cyan>onForcedMove Event<reset>

        This event is raised to inform the script that the character moved in a
        specified direction without a command being entered. When raised, a
        string containing the movement direction must be passed as a second
        argument to the raiseEvent function.

        The most common reason for this event to be raised is when a character
        is following someone else.
]]
map.help.onrandommove = [[
    <cyan>onRandomMove Event<reset>

        This event is raised to inform the script that the character has moved
        in an unknown direction. The script will compare the next room seen with
        rooms that are adjacent to the current room to try to determine the best
        match for where the character has gone.

        In some situations, multiple options are equally viable, so mistakes may
        result. The script will automatically keep verifying positioning with
        each step, and automatically correct the shown location on the map when
        possible.
]]
map.help.onvisionfail = [[
    <cyan>onVisionFail Event<reset>

        This event is raised to inform the script that some or all of the room
        information was not able to be gathered, but the character still
        successfully moved between rooms in the intended direction.
]]
map.help.onprompt = [[
    <cyan>onPrompt Event<reset>

        This event can be raised when using a non-conventional setup to trigger
        waiting messages from the script to be displayed. Additionally, if
        map.prompt.exits exists and isn't simply an empty string, raising this
        event will cause the onNewRoom event to be raised as well. This
        functionality is intended to allow people who have used the older
        version of this script to use this script instead, without having to
        modify the triggers they created for it.
]]
map.help.me = [[
    <cyan>Map Me<reset>
        syntax: <yellow>map me<reset>

        This command forces the script to look at the currently captured room
        name and exits, and search for a potentially matching room, moving the
        map if applicable. Note that this command is generally never needed, as
        the script performs a similar search any time the room name and exits
        don't match expectations.
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
map.help.character = [[
    <cyan>Map Character<reset>
        syntax: <yellow>map character <name><reset>

        This command tells the script what character is currently being used.
        Setting a character is optional, but recall locations and prompt
        patterns are stored by character name, so using this command allows for
        easy switching between different setups. The name given is stored in
        map.character. The name is a case sensitive exact match. The value of
        map.character is not saved between sessions, so this must be set again
        if needed each time the profile is opened.
]]
map.help.recall = [[
    <cyan>Map Recall<reset>
        syntax: <yellow>map recall<reset>

        This command tells the script that the current room is the recall point
        for the current character, as stored in map.character. This information
        is stored in map.save.recall[map.character], and is remembered between
        sessions.
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

        <yellow>max_search_distance<reset> - When mapping, this is the maximum number of
            rooms that the script will search in the movement direction for a
            matching room before deciding to create a new room. This may be
            false, or any positive whole number. This can also be set to 0,
            which is the same as setting it to false.

        <yellow>search_on_look<reset> - When this is set, using the "look" command causes
            the map to verify your position using the room name and exits
            seen following using the command. This may be true or false.

        <yellow>clear_lines_on_send<reset> - When this is set, any time a command is sent,
            any lines stored from the game used to search for the room name
            are cleared. This may be true or false.

        <yellow>mode<reset> - This is the default mapping mode on startup, and defines how
            new rooms are added to the map. May be "lazy", "simple",
            "normal" or "complex".

        <yellow>download_path<reset> - This is the path that updates are downloaded from.
            This may be any web address where the versions.lua and
            generic_mapper.xml files can be downloaded from.

        <yellow>prompt_test_patterns<reset> - This is a table of default patterns checked
            when using the "find prompt" command. The patterns in this table
            should start with a '^', and be written to be used with the Lua
            string library. Most importantly, '%' is used as the escape
            character instead of '\' as in trigger regex patterns.

        <yellow>custom_exits<reset> - This is a table of custom exit directions and their
            relevant extra pieces of info. Each entry should have the short
            direction as the keyword for a table containing first the long
            direction, then the long direction of the reverse of this
            direction, and then the x, y, and z change in map position
            corresponding to the movement. As an example: us = {'upsouth',
            'downnorth', 0, -1, 1}

        <yellow>custom_name_search<reset> - When this is set, instead of running the default
            function name_search, a user-defined function called
            'mudlet.custom_name_search' is used instead. This may be true or false.

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

    Mudlet Mapper works in tandem with a script, and this generic mapper script needs
    to know 2 things to work:
      - <dim_grey>room name<reset> $ROOM_NAME_STATUS ($ROOM_NAME)
      - <dim_grey>exits<reset>     $ROOM_EXITS_STATUS ($ROOM_EXITS)

    1. <link: start mapping>start mapping <optional area name></link>
       If both room name and exits are good, you can start mapping! Give it the
       area name you're currently in, usually optional but required for the first one.
    2. <link: find prompt>find prompt</link>
       Room name or exits aren't recognised? Try this command then. It will make
       the script start looking for a prompt using several standard prompt
       patterns. If a prompt is found, you will be notified, if not, you will
       need to set a prompt pattern yourself using <link: prompt>map prompt</link>.
       Reach out to the <urllink: https://discord.gg/kuYvMQ9>Mudlet community</urllink> for help, we'd be happy to help
       you figure it out!
    3. <link: debug>map debug</link>
       This toggles debug mode. When on, messages will be displayed showing what
       information is captured and a few additional error messages that can help
       with getting the script fully compatible with your game.
    4. <link: 1>map help</link>
       This will bring up a more detailed help file, starting with the available
       help topics.
]]

