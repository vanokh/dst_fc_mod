name = "File commands"

version = "1.0.0"
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

all_clients_require_mod = true
client_only_mod = false
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
            {description = "Temp\\cmd.txt", data = 1},
            {description = "DST\\cmd.txt", data = 2},
            {description = "Custom", data = 0}
        },
        default = 0
    }
}
