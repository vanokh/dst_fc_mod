name = "File commands"

version = "1.1.0"
russian = name.utf8len and (russian or language == "ru")
description = (
	russian
	
	and "Мод добавляет огонька в игру - читает команды из файла.".."\nВерсия "..version
	
	or "Add interactions to your game - execute commands from file.".."\nVersion "..version
	)
author = "vanokh"

forumthread = ""

api_version = 10
priority = 0.4729487239

all_clients_require_mod = false
client_only_mod = true
dst_compatible = true

--icon_atlas = "fc_mod_icon.xml"
--icon = "fc_mod_icon.tex"

server_filter_tags = { "interaction" }

configuration_options =
{
    {
        name = "file_path",
        label = "Path to command file",
        options =
        {            
            {description = "C:\\Temp\\cmd.txt", data = 1},
            {description = "DST\\cmd.txt", data = 2},
            {description = "D:\\cmd.txt", data = 3},
            {description = "Custom", data = 0}
        },
        default = 0
    },
    {
        name = "speed_timer",
        label = "Speed command timer",
        options =
        {            
            {description = "30s", data = 30},
            {description = "60s", data = 60},
            {description = "1.5m", data = 90},
            {description = "2m", data = 120},
            {description = "2.5m", data = 150},
            {description = "3m", data = 180},
            {description = "4m", data = 240},
            {description = "5m", data = 320},
        },
        default = 60
    },
    {
        name = "damage_timer",
        label = "Damage command timer",
        options =
        {            
            {description = "30s", data = 30},
            {description = "60s", data = 60},
            {description = "1.5m", data = 90},
            {description = "2m", data = 120},
            {description = "2.5m", data = 150},
            {description = "3m", data = 180},
            {description = "4m", data = 240},
            {description = "5m", data = 320},
        },
        default = 60
    },
    {
        name = "charge_timer",
        label = "Charge command timer",
        options =
        {            
            {description = "30s", data = 30},
            {description = "60s", data = 60},
            {description = "1.5m", data = 90},
            {description = "2m", data = 120},
            {description = "2.5m", data = 150},
            {description = "3m", data = 180},
            {description = "4m", data = 240},
            {description = "5m", data = 320},
        },
        default = 60
    },
    {
        name = "giveall_timer",
        label = "Give all recipes timer",
        options =
        {            
            {description = "5s", data = 5},
            {description = "7s", data = 7},
            {description = "10s", data = 10},
            {description = "15s", data = 15},
            {description = "30s", data = 30},
        },
        default = 7
    },
    {
        name = "near_distance",
        label = "Spawn command distance",
        options =
        {            
            {description = "1", data = 1},
            {description = "2", data = 2},
            {description = "3", data = 3},
            {description = "4", data = 4},
            {description = "5", data = 5},
            {description = "6", data = 6},
            {description = "7", data = 7},
            {description = "8", data = 8}
        },
        default = 6
    }
}
